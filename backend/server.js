const express = require('express');
const crypto = require('crypto');
const compression = require('compression');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { Readable } = require('stream');
const { MongoClient, ObjectId, GridFSBucket } = require('mongodb');
const bcrypt = require('bcrypt');

dotenv.config({ path: path.join(__dirname, 'env.development') });

const app = express();
app.set('trust proxy', true);
const port = Number(process.env.PORT) || 3001;
const mongoUri = process.env.MONGODB_URI;
const uploadDirectory = path.join(__dirname, 'uploads');
const authSecret = process.env.AUTH_SECRET || mongoUri || 'development-only-auth-secret';

fs.mkdirSync(uploadDirectory, { recursive: true });

app.use(express.json({ limit: '10mb' }));
app.use(compression());
app.use((req, res, next) => {
  const origin = req.headers.origin || '*';
  res.setHeader('Access-Control-Allow-Origin', origin === '*' ? '*' : origin);
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  res.setHeader('Access-Control-Allow-Credentials', 'true');

  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }

  return next();
});
app.use('/uploads', express.static(uploadDirectory, {
  maxAge: '7d',
  immutable: true,
}));
app.use('/api/mainpage-info', (req, res, next) => {
  if (req.method === 'GET') {
    res.setHeader('Cache-Control', 'public, max-age=30, stale-while-revalidate=120');
  }
  next();
});
app.use('/api/groups', (req, res, next) => {
  if (req.method === 'GET') {
    res.setHeader('Cache-Control', 'private, max-age=15, stale-while-revalidate=60');
  }
  next();
});

function readAuthToken(req) {
  const header = req.headers.authorization || '';
  return header.startsWith('Bearer ') ? header.substring(7) : '';
}

function signAuthPayload(payload) {
  const encoded = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signature = crypto.createHmac('sha256', authSecret).update(encoded).digest('base64url');
  return `${encoded}.${signature}`;
}

function verifyAuthToken(token) {
  const [encoded, signature] = token.split('.');
  if (!encoded || !signature) return null;
  const expected = crypto.createHmac('sha256', authSecret).update(encoded).digest('base64url');
  if (signature.length !== expected.length || !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) return null;
  const payload = JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8'));
  return payload.exp > Math.floor(Date.now() / 1000) ? payload : null;
}

function requireTeacherMutation(req, res, next) {
  const isGroupMenuMutation = req.method !== 'GET' && /\/(events|class-timetable|lesson-plans|homework|today-in-class|messages|photos|news)(\/|$)/.test(req.path);
  if (!isGroupMenuMutation) return next();
  try {
    const auth = verifyAuthToken(readAuthToken(req));
    const role = (auth?.role || '').toLowerCase();
    if (role !== 'staff' && role !== 'teacher') {
      return res.status(auth ? 403 : 401).json({ message: auth ? 'Only teachers may modify Group Menu data.' : 'Authentication required.' });
    }
    req.auth = auth;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Authentication required.' });
  }
}

function requireTeacher(req, res, next) {
  try {
    const auth = verifyAuthToken(readAuthToken(req));
    const role = (auth?.role || '').toLowerCase();
    if (role !== 'staff' && role !== 'teacher') {
      return res.status(auth ? 403 : 401).json({ message: auth ? 'Only teachers may modify class resources.' : 'Authentication required.' });
    }
    req.auth = auth;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Authentication required.' });
  }
}

function requireDiaryAccess(req, res, next) {
  try {
    const auth = verifyAuthToken(readAuthToken(req));
    const role = (auth?.role || '').toLowerCase();
    if (role !== 'staff' && role !== 'teacher' && role !== 'admin') {
      return res.status(auth ? 403 : 401).json({
        message: auth ? 'Only staff, teachers, or admins may access diary observations.' : 'Authentication required.',
      });
    }
    req.auth = auth;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Authentication required.' });
  }
}

function requireAdmin(req, res, next) {
  try {
    const auth = verifyAuthToken(readAuthToken(req));
    const role = (auth?.role || '').toLowerCase();
    if (role !== 'admin') {
      return res.status(auth ? 403 : 401).json({ message: auth ? 'Admin access required.' : 'Authentication required.' });
    }
    req.auth = auth;
    return next();
  } catch (_) {
    return res.status(401).json({ message: 'Authentication required.' });
  }
}

function requireRecipientRole(role) {
  return (req, res, next) => {
    try {
      const auth = verifyAuthToken(readAuthToken(req));
      if ((auth?.role || '').toLowerCase() !== role) {
        return res.status(auth ? 403 : 401).json({ message: 'Authentication required.' });
      }
      req.auth = auth;
      return next();
    } catch (_) {
      return res.status(401).json({ message: 'Authentication required.' });
    }
  };
}

app.use('/api/groups', requireTeacherMutation);

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});
app.post('/api/messages/admin', requireAdmin, async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const subject = String(body.subject || '').trim();
    const message = String(body.message || '').trim();
    const messageType = String(body.messageType || '').trim();
    const sendToStudents = body.sendToStudents === true;
    const sendToStaff = body.sendToStaff === true;
    if (!subject || !message || !messageType) {
      return res.status(422).json({ message: 'Subject, message, and message type are required.' });
    }
    if (!sendToStudents && !sendToStaff) {
      return res.status(422).json({ message: 'At least one recipient is required.' });
    }
    const senderId = String(req.auth.userId || '').trim();
    const admin = await usersCollection.findOne({ userId: senderId });
    const senderName = String(admin?.name || admin?.fullName || admin?.email || 'Admin').split('@')[0];
    const now = new Date().toISOString();
    const document = {
      subject,
      title: subject,
      message,
      content: message,
      messageType,
      category: messageType,
      senderId,
      senderName,
      senderRole: 'admin',
      sendToStudents,
      sendToStaff,
      groupId: body.groupId ? String(body.groupId).trim() : null,
      groupName: String(body.groupName || 'All Groups').trim() || 'All Groups',
      createdAt: now,
      updatedAt: now,
    };
    const result = await groupMessagesCollection.insertOne(document);
    const saved = await groupMessagesCollection.findOne({ _id: result.insertedId });
    return res.status(201).json({ success: true, message: 'Message sent successfully.', data: sanitizeAdminMessageForResponse(saved) });
  } catch (error) {
    console.error('POST /api/messages/admin failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to send message.' });
  }
});

async function getAdminMessagesForRecipient(req, res, role) {
  try {
    await connectMongo();
    const user = await usersCollection.findOne({ userId: req.auth.userId });
    const profile = role === 'student'
      ? await studentInfoCollection.findOne({ studentId: req.auth.userId })
      : await employeeInfoCollection.findOne({ $or: [{ employeeId: req.auth.userId }, { staffId: req.auth.userId }] });
    const groupValues = [
      user?.groupId, user?.groupName, user?.className, user?.class,
      profile?.groupId, profile?.groupName, profile?.className, profile?.class,
    ].filter((value) => value).map((value) => String(value));
    const groupFilter = groupValues.length
      ? { $or: [{ groupId: null }, { groupId: '' }, { groupId: { $in: groupValues } }] }
      : { $or: [{ groupId: null }, { groupId: '' }] };
    const recipientField = role === 'student' ? 'sendToStudents' : 'sendToStaff';
    const messages = await groupMessagesCollection.find({
      senderRole: 'admin',
      [recipientField]: true,
      ...groupFilter,
    }).sort({ createdAt: -1 }).toArray();
    return res.json({ success: true, data: messages.map(sanitizeAdminMessageForResponse) });
  } catch (error) {
    console.error(`GET /api/messages/${role} failed:`, error);
    return res.status(500).json({ success: false, message: 'Unable to load messages.' });
  }
}

app.get('/api/messages/student', requireRecipientRole('student'), (req, res) => getAdminMessagesForRecipient(req, res, 'student'));
app.get('/api/messages/staff', requireRecipientRole('staff'), (req, res) => getAdminMessagesForRecipient(req, res, 'staff'));
app.get('/api/messages/group/:groupId', requireRecipientRole('student'), async (req, res) => {
  try {
    await connectMongo();
    const groupId = String(req.params.groupId || '').trim();
    const messages = await groupMessagesCollection.find({ senderRole: 'admin', groupId: { $in: [groupId, null, ''] }, sendToStudents: true }).sort({ createdAt: -1 }).toArray();
    return res.json({ success: true, data: messages.map(sanitizeAdminMessageForResponse) });
  } catch (_) {
    return res.status(500).json({ success: false, message: 'Unable to load group messages.' });
  }
});

function sanitizeDiaryForResponse(doc) {
  if (!doc) return null;
  return {
    _id: doc._id ? doc._id.toString() : '',
    id: doc._id ? doc._id.toString() : '',
    studentId: doc.studentId || '',
    studentName: doc.studentName || '',
    diaryId: doc.diaryId || '',
    groupId: doc.groupId || '',
    classId: doc.classId || doc.groupId || '',
    date: doc.date || '',
    parentObservation: {
      wentToBedAt: doc.parentObservation?.wentToBedAt || '',
      gotUpAt: doc.parentObservation?.gotUpAt || '',
      brushedTeeth: doc.parentObservation?.brushedTeeth || '',
      didYoga: doc.parentObservation?.didYoga || '',
      breakfast: doc.parentObservation?.breakfast || '',
      homework: doc.parentObservation?.homework || '',
      assignmentCompletion: doc.parentObservation?.assignmentCompletion || '',
      helpfulAtHome: doc.parentObservation?.helpfulAtHome || '',
      respectfulToElders: doc.parentObservation?.respectfulToElders || '',
      parentsRemark: doc.parentObservation?.parentsRemark || '',
    },
    studentObservation: {
      mood: doc.studentObservation?.mood || '',
    },
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function diaryStudentMatch(student, studentId) {
  const values = [student?.id, student?._id, student?.studentId, student?.admissionNo, student?.admissionNumber]
    .filter((value) => value != null && String(value).trim())
    .map((value) => String(value).trim());
  return values.includes(studentId);
}

app.get('/api/diary', requireDiaryAccess, async (req, res) => {
  try {
    const groupId = String(req.query.groupId || '').trim();
    const date = String(req.query.date || '').trim();
    if (!groupId || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(422).json({ message: 'groupId and a valid date are required.' });
    }
    await connectMongo();
    const records = await diaryCollection.find({ groupId, date }).sort({ studentName: 1 }).toArray();
    return res.json({ success: true, data: records.map(sanitizeDiaryForResponse) });
  } catch (error) {
    console.error('GET /api/diary failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to load diary observations.' });
  }
});

app.get('/api/diary/student-observation/:id', requireDiaryAccess, async (req, res) => {
  try {
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid diary record ID.' });
    }
    await connectMongo();
    const record = await diaryCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!record) return res.status(404).json({ message: 'Student observation not found.' });
    return res.json({ success: true, data: sanitizeDiaryForResponse(record) });
  } catch (error) {
    console.error('GET /api/diary/student-observation/:id failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to load student observation.' });
  }
});

app.get('/api/diary/:id', requireDiaryAccess, async (req, res) => {
  try {
    if (!ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid diary record ID.' });
    }
    await connectMongo();
    const record = await diaryCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!record) return res.status(404).json({ message: 'Diary observation not found.' });
    return res.json({ success: true, data: sanitizeDiaryForResponse(record) });
  } catch (error) {
    console.error('GET /api/diary/:id failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to load diary observation.' });
  }
});

app.post('/api/diary', requireDiaryAccess, async (req, res) => {
  try {
    const body = req.body || {};
    const studentId = String(body.studentId || '').trim();
    const groupId = String(body.groupId || body.classId || '').trim();
    const date = String(body.date || '').trim();
    const observation = body.parentObservation || {};
    const required = [
      ['studentId', studentId],
      ['groupId', groupId],
      ['date', date],
      ['wentToBedAt', observation.wentToBedAt],
      ['gotUpAt', observation.gotUpAt],
      ['brushedTeeth', observation.brushedTeeth],
      ['didYoga', observation.didYoga],
      ['breakfast', observation.breakfast],
      ['homework', observation.homework],
      ['assignmentCompletion', observation.assignmentCompletion],
      ['helpfulAtHome', observation.helpfulAtHome],
      ['respectfulToElders', observation.respectfulToElders],
    ];
    if (required.some(([, value]) => !String(value || '').trim()) || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(422).json({ message: 'All required parent observation fields must be provided.' });
    }

    const allowed = {
      brushedTeeth: ['once', 'twice'],
      didYoga: ['yes', 'no'],
      breakfast: ['had_breakfast', 'refused'],
      homework: ['completed', 'did_not_do'],
      assignmentCompletion: ['worked_independently', 'did_under_supervision', 'failed_to_do'],
      helpfulAtHome: ['very_much', 'sometimes', 'never'],
      respectfulToElders: ['very_much', 'sometimes', 'never'],
    };
    for (const [field, values] of Object.entries(allowed)) {
      if (!values.includes(String(observation[field] || '').trim())) {
        return res.status(422).json({ message: `Invalid value for ${field}.` });
      }
    }

    await connectMongo();
    const group = await findGroupByReference(groupId);
    if (!group) return res.status(404).json({ message: 'Group not found.' });
    const groupStudent = (Array.isArray(group.students) ? group.students : [])
      .find((student) => diaryStudentMatch(student, studentId));
    if (!groupStudent) return res.status(403).json({ message: 'Student is not a member of this group.' });

    const now = new Date().toISOString();
    const diaryId = String(body.diaryId || `${groupId}:${studentId}:${date}`).trim();
    const document = {
      studentId,
      studentName: String(groupStudent.name || body.studentName || '').trim(),
      diaryId,
      groupId,
      classId: groupId,
      date,
      parentObservation: {
        wentToBedAt: String(observation.wentToBedAt).trim(),
        gotUpAt: String(observation.gotUpAt).trim(),
        brushedTeeth: String(observation.brushedTeeth).trim(),
        didYoga: String(observation.didYoga).trim(),
        breakfast: String(observation.breakfast).trim(),
        homework: String(observation.homework).trim(),
        assignmentCompletion: String(observation.assignmentCompletion).trim(),
        helpfulAtHome: String(observation.helpfulAtHome).trim(),
        respectfulToElders: String(observation.respectfulToElders).trim(),
        parentsRemark: String(observation.parentsRemark || '').trim(),
      },
      updatedAt: now,
    };
    await diaryCollection.updateOne(
      { studentId, groupId, date },
      { $set: document, $setOnInsert: { createdAt: now } },
      { upsert: true },
    );
    const saved = await diaryCollection.findOne({ studentId, groupId, date });
    return res.status(200).json({ success: true, message: 'Parent observations saved successfully.', data: sanitizeDiaryForResponse(saved) });
  } catch (error) {
    console.error('POST /api/diary failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to save parent observations.' });
  }
});

app.post('/api/diary/student-observation', requireDiaryAccess, async (req, res) => {
  try {
    const body = req.body || {};
    const studentId = String(body.studentId || '').trim();
    const groupId = String(body.groupId || body.classId || '').trim();
    const classId = String(body.classId || groupId).trim();
    const diaryId = String(body.diaryId || '').trim();
    const date = String(body.date || '').trim();
    const mood = String(body.mood || '').trim();
    const moods = ['exciting', 'happy', 'lazy', 'sad', 'angry'];
    if (!studentId || !groupId || !classId || !diaryId ||
        !/^\d{4}-\d{2}-\d{2}$/.test(date) || !moods.includes(mood)) {
      return res.status(422).json({ message: 'studentId, diaryId, groupId, date, and a valid mood are required.' });
    }

    await connectMongo();
    const group = await findGroupByReference(groupId);
    if (!group) return res.status(404).json({ message: 'Group not found.' });
    const groupStudent = (Array.isArray(group.students) ? group.students : [])
      .find((student) => diaryStudentMatch(student, studentId));
    if (!groupStudent) return res.status(403).json({ message: 'Student is not a member of this group.' });

    const now = new Date().toISOString();
    await diaryCollection.updateOne(
      { studentId, diaryId },
      {
        $set: {
          studentId,
          studentName: String(groupStudent.name || body.studentName || '').trim(),
          diaryId,
          classId,
          groupId,
          date,
          studentObservation: { mood },
          updatedAt: now,
        },
        $setOnInsert: { createdAt: now },
      },
      { upsert: true },
    );
    const saved = await diaryCollection.findOne({ studentId, diaryId });
    return res.status(200).json({ success: true, message: 'Student observation saved.', data: sanitizeDiaryForResponse(saved) });
  } catch (error) {
    console.error('POST /api/diary/student-observation failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to save student observation.' });
  }
});

let client;
let mainPageInfoCollection;
let imageBucket;
let usersCollection;
let employeeInfoCollection;
let legacyStaffInfoCollection;
let groupsCollection;
let eventsCollection;
let legacyEventsCollection;
let todayInClassCollection;
let homeworkCollection;
let diaryCollection;
let groupMessagesCollection;
let groupMessageCommentsCollection;
let classTimetableCollection;
let legacyClassTimetableCollection;
let studentInfoCollection;
let schoolHandbookCollection;
let eventCelebrationCollection;
let schoolResourcesCollection;
let classResourcesCollection;
let newsLetterCollection;
let announcementCollection;
let demographyCollection;
let libraryCollection;
let socialUrlCollection;
let classPhotosCollection;
let classNewsCollection;
let lessonPlansCollection;
let schoolNewsCollection;
let medicalEventCollection;
let staffLeaveCollection;
let staffLeaveEntitlementsCollection;
let busGpsCollection;
let oneOnOneMeetingsCollection;
let gateRegisterCollection;
let employeeAttendanceCollection;
let staffResourcesCollection;

async function safeCreateIndex(collection, spec, options = {}) {
  try {
    await collection.createIndex(spec, options);
  } catch (error) {
    const message = error && error.message ? error.message : String(error);
    const isDuplicateIndex = /already exists|same name as the requested index/i.test(message);
    if (!isDuplicateIndex) {
      throw error;
    }
  }
}

async function ensureIndexes(db) {
  await Promise.all([
    safeCreateIndex(groupsCollection, { id: 1 }, { sparse: true }),
    safeCreateIndex(usersCollection, { userId: 1 }, { sparse: true }),
    safeCreateIndex(usersCollection, { email: 1 }, { sparse: true }),
    safeCreateIndex(eventsCollection, { groupId: 1, startDate: 1 }),
    safeCreateIndex(todayInClassCollection, { groupId: 1, date: 1 }),
    safeCreateIndex(homeworkCollection, { groupId: 1, date: 1 }),
    safeCreateIndex(diaryCollection, { studentId: 1, groupId: 1, date: 1 }, { unique: true }),
    safeCreateIndex(groupMessagesCollection, { groupId: 1, createdAt: -1 }),
    safeCreateIndex(groupMessageCommentsCollection, { groupId: 1, messageId: 1, createdAt: 1 }),
    safeCreateIndex(classTimetableCollection, { groupId: 1, day: 1, startTime: 1 }),
    safeCreateIndex(
      studentInfoCollection,
      { studentId: 1 },
      { unique: true, sparse: true, collation: { locale: 'en', strength: 2 } },
    ),
    safeCreateIndex(studentInfoCollection, { admissionNumber: 1 }, { sparse: true }),
    safeCreateIndex(schoolHandbookCollection, { schoolId: 1, handbookId: 1 }, { unique: true }),
    safeCreateIndex(eventCelebrationCollection, { schoolId: 1, eventDate: 1 }),
    safeCreateIndex(schoolResourcesCollection, { schoolId: 1, date: -1, createdAt: -1 }),
    safeCreateIndex(classResourcesCollection, { groupId: 1, createdAt: -1 }),
    safeCreateIndex(newsLetterCollection, { schoolId: 1, createdAt: -1 }),
    safeCreateIndex(announcementCollection, { createdAt: -1 }),
    safeCreateIndex(demographyCollection, { groupId: 1 }, { unique: false }),
    safeCreateIndex(libraryCollection, { bookId: 1 }, { unique: false }),
    safeCreateIndex(socialUrlCollection, { platform: 1 }, { unique: true }),
    safeCreateIndex(classPhotosCollection, { groupId: 1, uploadedAt: -1 }),
    safeCreateIndex(classNewsCollection, { groupId: 1, publishedAt: -1 }),
    safeCreateIndex(schoolNewsCollection, { isPublished: 1, date: -1, createdAt: -1 }),
    safeCreateIndex(staffLeaveCollection, { staffId: 1, createdAt: -1 }),
    safeCreateIndex(staffLeaveEntitlementsCollection, { staffId: 1, year: 1, leaveType: 1 }),
    safeCreateIndex(busGpsCollection, { busRouteCode: 1 }),
    safeCreateIndex(oneOnOneMeetingsCollection, { staffId: 1, startDateTime: -1 }),
    safeCreateIndex(gateRegisterCollection, { personType: 1, entryDate: -1 }),
    safeCreateIndex(employeeAttendanceCollection, { employeeId: 1, attendanceDate: 1 }, { unique: true }),
    safeCreateIndex(employeeAttendanceCollection, { attendanceDate: 1, status: 1 }),
    safeCreateIndex(staffResourcesCollection, { staffId: 1, createdAt: -1 }),
  ]);
}

const legacyGroupSeed = [
  { name: 'NCC2022', id: 'NCC2022', type: 'Other', description: 'NCC2022', code: 'NCC2022', status: 'Active', year: '2022' },
  { name: 'Second_Language_Tamil_Gr4_2026_27 - A', id: 'Second_Language_Tamil_Gr4_2026_27 - A', type: 'Other', description: 'Second_Language_Tamil_Gr4_2026_27 - A', code: 'Second_Language_Tamil_Gr4_2026_27 - A', status: 'Active', year: '2026-27' },
  { name: 'USS - NSS G11', id: 'USS - NSS G11', type: 'Other', description: 'USS - NSS G11', code: 'USS - NSS G11', status: 'Active', year: '2026-27' },
  { name: 'JRC - GRADE 6_TO_9', id: 'JRC - GRADE 6_TO_9', type: 'Other', description: 'JRC - GRADE 6_TO_9', code: 'JRC - GRADE 6_TO_9', status: 'Active', year: '2026-27' },
  { name: 'SCOUTS AND GUIDES - GRADE 6_TO_9', id: 'SCOUTS AND GUIDES - GRADE 6_TO_9', type: 'Other', description: 'SCOUTS AND GUIDES - GRADE 6_TO_9', code: 'SCOUTS AND GUIDES - GRADE 6_TO_9', status: 'Active', year: '2026-27' },
];

async function connectMongo() {
  if (!mongoUri) {
    throw new Error('MongoDB URI is not configured');
  }

  if (!client) {
    client = new MongoClient(mongoUri);
    await client.connect();
    const db = client.db('mainpage');
    mainPageInfoCollection = db.collection('mainPageInfo');
    usersCollection = db.collection('users');
    employeeInfoCollection = db.collection('employee-info');
    legacyStaffInfoCollection = db.collection('staff-info');
    groupsCollection = db.collection('groups');
    eventsCollection = db.collection('future-events-calender');
    legacyEventsCollection = db.collection('events');
    todayInClassCollection = db.collection('todayInClass');
    homeworkCollection = db.collection('home-work');
    diaryCollection = db.collection('diary');
    groupMessagesCollection = db.collection('groupMessages');
    groupMessageCommentsCollection = db.collection('groupMessageComments');
    classTimetableCollection = db.collection('class-timetables');
    legacyClassTimetableCollection = db.collection('class-timetable');
    studentInfoCollection = db.collection('stud-in');
    schoolHandbookCollection = db.collection('school-handbook');
    eventCelebrationCollection = db.collection('event-celebration');
    schoolResourcesCollection = db.collection('school-resources');
    classResourcesCollection = db.collection('class-resources');
    newsLetterCollection = db.collection('news-letter');
    announcementCollection = db.collection('announcement');
    demographyCollection = db.collection('demography');
    libraryCollection = db.collection('lib');
    socialUrlCollection = db.collection('social-url');
    classPhotosCollection = db.collection('class-photos');
    classNewsCollection = db.collection('class-news');
    lessonPlansCollection = db.collection('lesson-plans');
    schoolNewsCollection = db.collection('schoolnews');
    medicalEventCollection = db.collection('medical-event');
    staffLeaveCollection = db.collection('emp-leave');
    staffLeaveEntitlementsCollection = db.collection('staff-leave-entitlements');
    busGpsCollection = db.collection('bus gps');
    oneOnOneMeetingsCollection = db.collection('one-on-one-meetings');
    gateRegisterCollection = db.collection('gate-reg');
    employeeAttendanceCollection = db.collection('employee-attendance');
    staffResourcesCollection = db.collection('staff-resources');
    imageBucket = new GridFSBucket(db, { bucketName: 'images' });
    await ensureIndexes(db);
    await migrateLegacyStaffInfo();
    await migrateLegacyEvents();
    await migrateLegacyClassTimetable();
  }

  return mainPageInfoCollection;
}

async function migrateLegacyStaffInfo() {
  const employeeCount = await employeeInfoCollection.countDocuments();
  if (employeeCount > 0) return;

  const legacyStaff = await legacyStaffInfoCollection.find({}).toArray();
  if (legacyStaff.length > 0) await employeeInfoCollection.insertMany(legacyStaff);
}

async function migrateLegacyEvents() {
  const legacyEvents = await legacyEventsCollection.find({}).toArray();
  for (const event of legacyEvents) {
    const exists = await eventsCollection.findOne({ _id: event._id });
    if (!exists) await eventsCollection.insertOne(event);
  }
}

async function migrateLegacyClassTimetable() {
  const legacyEntries = await legacyClassTimetableCollection.find({}).toArray();
  for (const entry of legacyEntries) {
    const exists = await classTimetableCollection.findOne({ _id: entry._id });
    if (!exists) await classTimetableCollection.insertOne(entry);
  }
}

async function ensureLegacyGroupsSeeded() {
  if (!groupsCollection) {
    return false;
  }

  const existingCount = await groupsCollection.countDocuments();
  if (existingCount > 0) {
    return false;
  }

  const now = new Date().toISOString();
  const documents = legacyGroupSeed.map((group, index) => ({
    ...group,
    order: index + 1,
    createdAt: now,
    updatedAt: now,
  }));

  await groupsCollection.insertMany(documents);
  return true;
}

function sanitizeUserForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    userId: doc.userId || doc.userID || '',
    email: doc.email || '',
    role: doc.role || 'student',
  };
}

function sanitizeBusGpsForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    busRouteCode: doc.busRouteCode || '',
    busRouteStatus: doc.busRouteStatus || 'Active',
    year: doc.year || '',
    busRouteDescription: doc.busRouteDescription || '',
    busRouteDriver: doc.busRouteDriver || '',
    busNo: doc.busNo || '',
    hasGpsDevice: doc.hasGpsDevice || 'No',
    gpsStatus: doc.gpsStatus || 'Offline',
    engineStatus: doc.engineStatus || 'OFF',
    isActive: doc.isActive !== false,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeGateRegisterForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    gateNo: doc.gateNo || '',
    customGateNo: doc.customGateNo || '',
    personType: doc.personType || '',
    entryDate: doc.entryDate || null,
    status: doc.status || 'Registered',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeEmployeeAttendanceForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    employeeId: doc.employeeId || '',
    teacherId: doc.teacherId || doc.employeeId || '',
    employeeName: doc.employeeName || '',
    attendanceDate: doc.attendanceDate || '',
    timeRecorded: doc.timeRecorded || null,
    attendanceType: doc.attendanceType || 'OnSite',
    distance: doc.distance ?? null,
    status: doc.status || 'Pending Approval',
    approved: doc.approved === true,
    present: doc.present !== false,
    selfAttendance: doc.selfAttendance !== false,
    isLate: doc.isLate === true,
    approvedBy: doc.approvedBy || null,
    approvedAt: doc.approvedAt || null,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeOneOnOneMeetingForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    staffId: doc.staffId || '',
    staffName: doc.staffName || '',
    startDateTime: doc.startDateTime || null,
    endDateTime: doc.endDateTime || null,
    meetingTime: doc.meetingTime || '',
    meetingInfo: doc.meetingInfo || '',
    meetingUrl: doc.meetingUrl || '',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}
function sanitizeStaffResourceForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    staffId: doc.staffId || '',
    staffName: doc.staffName || '',
    description: doc.description || '',
    link: doc.link || '',
    slipReportImageUrl: doc.slipReportImageUrl || '',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeStaffForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    name: doc.name || '',
    designation: doc.designation || '',
    employeeCategory: doc.employeeCategory || '',
    employeeId: doc.employeeId || '',
    teaches: doc.teaches || '',
    about: doc.about || '',
    hobbiesAndInterest: doc.hobbiesAndInterest || '',
    role: doc.role || '',
    imageUrl: doc.imageUrl || '',
    mobileNo: doc.mobileNo || '',
    shareableContactNo: doc.shareableContactNo || '',
    mailId: doc.mailId || '',
    address: doc.address || '',
    briefIntroduction: doc.briefIntroduction || '',
    sports: doc.sports || '',
    sportsTrainingDetails: doc.sportsTrainingDetails || '',
    sportsTeamClub: doc.sportsTeamClub || '',
    achievements: doc.achievements || '',
    extraCurricularActivities: doc.extraCurricularActivities || '',
    extraCurricularTeamClub: doc.extraCurricularTeamClub || '',
    professionalBodyAssociation: doc.professionalBodyAssociation || '',
    whatYouDo: doc.whatYouDo || '',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeStudentForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    name: doc.name || '',
    className: doc.className || '',
    section: doc.section || '',
    studentId: doc.studentId || '',
    admissionNumber: doc.admissionNumber || '',
    parentName: doc.parentName || '',
    mobileNumber: doc.mobileNumber || '',
    address: doc.address || '',
    about: doc.about || '',
    hobbies: doc.hobbies || '',
    role: doc.role || '',
    imageUrl: doc.imageUrl || '',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeStaffLeaveForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    staffId: doc.staffId || '',
    staffName: doc.staffName || '',
    leaveType: doc.leaveType || '',
    applicableYear: doc.applicableYear || null,
    startDate: doc.startDate || null,
    endDate: doc.endDate || null,
    beginHalfDay: doc.beginHalfDay === true,
    endHalfDay: doc.endHalfDay === true,
    effectiveDays: Number(doc.effectiveDays || 0),
    reason: doc.reason || '',
    status: doc.status || 'Pending',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeStaffLeaveEntitlementForResponse(doc) {
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    staffId: doc.staffId || '',
    leaveType: doc.leaveType || '',
    year: Number(doc.year || 0),
    totalLeaves: Number(doc.totalLeaves || 0),
    adjustment: Number(doc.adjustment || 0),
    leaveTaken: Number(doc.leaveTaken || 0),
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeMedicalEventForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    studentId: doc.studentId || '',
    studentName: doc.studentName || '',
    className: doc.className || '',
    description: doc.description || '',
    firstObservations: {
      symptomReported: doc.firstObservations?.symptomReported || '',
      specialNeedsKnown: doc.firstObservations?.specialNeedsKnown || '',
    },
    reportImage: doc.reportImage || '',
    reportedBy: doc.reportedBy || { userId: '', name: '' },
    lastModifiedBy: doc.lastModifiedBy || { userId: '', name: '' },
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
    lastModifiedAt: doc.lastModifiedAt || null,
  };
}

function sanitizeHandbookForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    schoolId: doc.schoolId || 'default-school',
    handbookId: doc.handbookId || 'staff-handbook',
    title: doc.title || 'Staff Handbook',
    shortDescription: doc.shortDescription || '',
    category: doc.category || 'Staff Handbook',
    displayOrder: doc.displayOrder || 1,
    overview: doc.overview || '',
    sections: Array.isArray(doc.sections) ? doc.sections : [],
    contacts: Array.isArray(doc.contacts) ? doc.contacts : [],
    documentUrl: doc.documentUrl || '',
    documentName: doc.documentName || '',
    isActive: doc.isActive !== false,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function formatStudentIdSequence(value) {
  const numeric = Number.parseInt(String(value), 10);
  if (!Number.isFinite(numeric) || numeric < 1) return 'STU0001';
  return `STU${String(numeric).padStart(4, '0')}`;
}

async function generateNextStudentId() {
  if (!studentInfoCollection) return 'STU0001';

  const docs = await studentInfoCollection
    .find({ studentId: { $regex: /^STU\d+$/i } }, { projection: { studentId: 1, _id: 0 } })
    .toArray();

  let max = 0;
  for (const document of docs) {
    const match = String(document.studentId || '').match(/^STU(\d+)$/i);
    if (!match) continue;
    const numeric = Number.parseInt(match[1], 10);
    if (Number.isFinite(numeric) && numeric > max) max = numeric;
  }

  return formatStudentIdSequence(max + 1);
}

function sanitizeGroupForResponse(doc) {
  if (!doc) return null;
  return {
    _id: doc._id ? doc._id.toString() : null,
    databaseId: doc._id ? doc._id.toString() : null,
    id: doc.id || '',
    name: doc.name || '',
    code: doc.code || doc.description || '',
    description: doc.description || doc.code || '',
    type: doc.type || 'Other',
    status: doc.status || 'Active',
    year: doc.year || '',
    order: Number.isFinite(doc.order) ? Number(doc.order) : 0,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
    students: Array.isArray(doc.students) ? doc.students : [],
    teachers: Array.isArray(doc.teachers) ? doc.teachers : [],
  };
}

function sanitizeEventForResponse(doc) {
  if (!doc) return null;
  return {
    _id: doc._id ? doc._id.toString() : null,
    id: doc.id || (doc._id ? doc._id.toString() : ''),
    groupId: doc.groupId || '',
    title: doc.title || '',
    startDate: doc.startDate || '',
    endDate: doc.endDate || null,
    startTime: doc.startTime || null,
    endTime: doc.endTime || null,
    description: doc.description || '',
    createdBy: doc.createdBy || '',
    color: doc.color || '#FF9800',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeEventCelebrationForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    _id: id,
    schoolId: doc.schoolId || 'default-school',
    heading: doc.heading || '',
    imageUrl: doc.imageUrl || '',
    subHeading: doc.subHeading || '',
    content: doc.content || '',
    eventDate: doc.eventDate || null,
    category: doc.category || 'Event',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeSchoolResourceForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    _id: id,
    schoolId: doc.schoolId || 'default-school',
    heading: doc.heading || '',
    date: doc.date || '',
    resourceName: doc.resourceName || '',
    imageUrl: doc.imageUrl || '',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeClassResourceForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    groupId: doc.groupId || '',
    heading: doc.title || doc.heading || '',
    date: doc.createdAt || doc.date || '',
    resourceName: doc.description || doc.resourceName || '',
    imageUrl: doc.fileUrl || doc.imageUrl || '',
    resourceType: doc.resourceType || '',
    fileName: doc.fileName || '',
    fileSize: Number.isFinite(doc.fileSize) ? doc.fileSize : null,
    mimeType: doc.mimeType || '',
    createdBy: doc.createdBy || '',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeNewsLetterForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    _id: id,
    schoolId: doc.schoolId || 'default-school',
    heading: doc.heading || '',
    imageUrl: doc.imageUrl || '',
    introduction: doc.introduction || '',
    sections: Array.isArray(doc.sections) ? doc.sections.map((section) => ({
      subHeading: section && section.subHeading ? String(section.subHeading) : '',
      content: section && section.content ? String(section.content) : '',
    })) : [],
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeSchoolNewsForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    _id: id,
    title: doc.title || '',
    date: doc.date instanceof Date ? doc.date.toISOString() : (doc.date ? String(doc.date) : null),
    news: doc.news || '',
    isPublished: Boolean(doc.isPublished),
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeAnnouncementForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    _id: id,
    subject: doc.subject || '',
    from: doc.from || doc.fromName || '',
    to: Array.isArray(doc.to) ? doc.to.map((value) => String(value)) : [],
    createdOn: doc.createdOn || '',
    content: doc.content || '',
    likes: Array.isArray(doc.likes) ? doc.likes.map((value) => String(value)) : [],
    comments: Array.isArray(doc.comments) ? doc.comments.map((comment) => ({
      id: comment && comment.id ? String(comment.id) : null,
      name: comment && comment.name ? String(comment.name) : 'Student',
      text: comment && comment.text ? String(comment.text) : '',
      createdAt: comment && comment.createdAt ? String(comment.createdAt) : null,
    })) : [],
    reminders: Array.isArray(doc.reminders) ? doc.reminders.map((value) => String(value)) : [],
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeDemographyForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    _id: id,
    groupId: doc.groupId || '',
    groupName: doc.groupName || '',
    teachers: Array.isArray(doc.teachers) ? doc.teachers.map((member) => ({
      name: member && member.name ? String(member.name) : '',
      staffId: member && member.staffId ? String(member.staffId) : '',
    })) : [],
    otherTeachers: Array.isArray(doc.otherTeachers) ? doc.otherTeachers.map((member) => ({
      name: member && member.name ? String(member.name) : '',
      staffId: member && member.staffId ? String(member.staffId) : '',
    })) : [],
    students: Array.isArray(doc.students) ? doc.students.map((member) => ({
      name: member && member.name ? String(member.name) : '',
      studentId: member && member.studentId ? String(member.studentId) : '',
    })) : [],
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeLibraryBookForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    _id: id,
    bookName: doc.bookName || '',
    author: doc.author || '',
    bookId: doc.bookId || '',
    publisher: doc.publisher || '',
    availability: doc.availability === 'reserved' ? 'reserved' : 'available',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeSocialUrlForResponse(doc) {
  if (!doc) return null;
  return { platform: 'facebook', url: doc.url || '' };
}

function sanitizeWhatsAppForResponse(doc) {
  if (!doc) return null;
  return { platform: 'whatsapp', phoneNumber: doc.phoneNumber || '', text: doc.text || '' };
}

function sanitizeTodayInClassForResponse(doc) {
  if (!doc) return null;
  return {
    _id: doc._id ? doc._id.toString() : null,
    id: doc.id || (doc._id ? doc._id.toString() : ''),
    groupId: doc.groupId || '',
    date: doc.date || '',
    subject: doc.subject || '',
    message: doc.message || '',
    sendToStudents: doc.sendToStudents === true,
    sendToTeachers: doc.sendToTeachers === true,
    commentsAllowed: doc.commentsAllowed !== false,
    isHomework: doc.isHomework === true,
    attachments: Array.isArray(doc.attachments) ? doc.attachments : [],
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeGroupMessageForResponse(doc) {
  if (!doc) return null;
  return {
    _id: doc._id ? doc._id.toString() : null,
    id: doc.id || (doc._id ? doc._id.toString() : ''),
    groupId: doc.groupId || '',
    groupName: doc.groupName || '',
    title: doc.title || '',
    content: doc.content || doc.message || '',
    message: doc.content || doc.message || '',
    authorId: doc.authorId || '',
    authorRole: doc.authorRole || '',
    senderName: doc.senderName || '',
    senderEmail: doc.senderEmail || '',
    category: doc.category || '',
    messageType: doc.messageType || doc.category || '',
    priority: doc.priority || 'Normal',
    audience: Array.isArray(doc.audience) ? doc.audience : [],
    target: doc.target || '',
    approved: doc.approved === true,
    approvedById: doc.approvedById || '',
    imageUrl: doc.imageUrl || null,
    expiryDate: doc.expiryDate || null,
    createdBy: doc.createdBy || doc.authorId || '',
    commentsAllowed: doc.commentsAllowed !== false,
    likedBy: Array.isArray(doc.likedBy) ? doc.likedBy : [],
    comments: Array.isArray(doc.comments) ? doc.comments.map((comment) => ({
      id: comment.id || comment._id || null,
      studentId: comment.studentId || comment.userId || '',
      studentName: comment.studentName || comment.name || 'Student',
      text: comment.text || comment.comment || '',
      createdAt: comment.createdAt || new Date().toISOString(),
    })) : [],
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function sanitizeAdminMessageForResponse(doc) {
  if (!doc) return null;
  const id = doc._id ? doc._id.toString() : doc.id || '';
  return {
    id,
    subject: doc.subject || doc.title || '',
    message: doc.message || doc.content || '',
    messageType: doc.messageType || doc.category || 'General',
    senderId: doc.senderId || '',
    senderName: doc.senderName || 'Admin',
    senderRole: 'admin',
    sendToStudents: doc.sendToStudents === true,
    sendToStaff: doc.sendToStaff === true,
    groupId: doc.groupId || null,
    groupName: doc.groupName || 'All Groups',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function groupIdVariants(groupId) {
  const variants = [groupId];
  const doubleSeparatorId = groupId.replace(/^SAMUNI-2022-/i, 'SAMUNI-2022--');
  if (!variants.includes(doubleSeparatorId)) {
    variants.push(doubleSeparatorId);
  }
  const singleSeparatorId = groupId.replace(/^SAMUNI-2022--/i, 'SAMUNI-2022-');
  if (!variants.includes(singleSeparatorId)) {
    variants.push(singleSeparatorId);
  }
  if (groupId.startsWith('SAMUNI-2022-')) {
    variants.push(groupId.substring('SAMUNI-2022-'.length));
    if (singleSeparatorId !== groupId) {
      variants.push(singleSeparatorId.substring('SAMUNI-2022-'.length));
    }
  }
  return [...new Set(variants)];
}

function recordIdSelector(recordId) {
  try {
    return { $or: [{ _id: new ObjectId(recordId) }, { id: recordId }] };
  } catch (_) {
    return { id: recordId };
  }
}

function groupReferenceSlug(value) {
  return value.toString().toLowerCase().replace(/[^a-z0-9]/g, '');
}

async function findGroupByReference(groupId) {
  const variants = groupIdVariants(groupId);
  const exact = await groupsCollection.findOne({ id: { $in: variants } });
  if (exact) return exact;

  const requestedSlug = groupReferenceSlug(groupId.replace(/^SAMUNI-2022-/i, ''));
  const groups = await groupsCollection.find({}).toArray();
  return groups.find((group) => [group.id, group.name]
    .some((value) => groupReferenceSlug(value) === requestedSlug)) || null;
}

async function renumberGroups() {
  if (!groupsCollection) return;
  const groups = await groupsCollection.find({}).sort({ order: 1, createdAt: 1, _id: 1 }).toArray();
  for (let index = 0; index < groups.length; index += 1) {
    const group = groups[index];
    await groupsCollection.updateOne(
      { _id: group._id },
      { $set: { order: index + 1, updatedAt: new Date().toISOString() } }
    );
  }
}

// Employee Attendance CRUD
function employeeAttendancePayload(body) {
  const employeeId = String(body.employeeId || '').trim();
  const attendanceDate = String(body.attendanceDate || '').trim();
  const datePattern = /^\d{4}-\d{2}-\d{2}$/;
  if (!employeeId || !attendanceDate) return { error: 'Employee ID and attendance date are required.' };
  if (!datePattern.test(attendanceDate) || Number.isNaN(new Date(`${attendanceDate}T00:00:00Z`).getTime())) return { error: 'Attendance date must use YYYY-MM-DD format.' };
  const timeRecorded = body.timeRecorded ? new Date(body.timeRecorded) : new Date();
  if (Number.isNaN(timeRecorded.getTime())) return { error: 'Recorded time is invalid.' };
  const attendanceType = String(body.attendanceType || 'OnSite').trim();
  const distance = body.distance == null || body.distance === '' ? null : Number(body.distance);
  if (distance !== null && !Number.isFinite(distance)) return { error: 'Distance must be a valid number.' };
  return {
    values: {
      employeeId,
      attendanceDate,
      timeRecorded,
      attendanceType,
      distance,
      present: body.present !== false,
      selfAttendance: body.selfAttendance !== false,
      isLate: body.isLate === true,
    },
  };
}

function employeeAttendanceObjectId(id) {
  return ObjectId.isValid(id) ? new ObjectId(id) : null;
}

async function findEmployeeForAttendance(employeeId) {
  return employeeInfoCollection.findOne({ employeeId });
}

app.get('/api/employee-attendance', async (req, res) => {
  try {
    await connectMongo();
    const filter = {};
    if (req.query.date) filter.attendanceDate = String(req.query.date).trim();
    if (req.query.employeeId) filter.employeeId = String(req.query.employeeId).trim();
    const records = await employeeAttendanceCollection.find(filter).sort({ attendanceDate: -1, timeRecorded: -1, _id: -1 }).toArray();
    return res.json(records.map(sanitizeEmployeeAttendanceForResponse));
  } catch (error) {
    console.error('GET /api/employee-attendance failed:', error);
    return res.status(500).json({ message: 'Unable to load employee attendance.' });
  }
});

app.get('/api/employee-attendance/summary', async (req, res) => {
  try {
    await connectMongo();
    const date = String(req.query.date || '').trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return res.status(422).json({ message: 'A valid date in YYYY-MM-DD format is required.' });
    const [total, records] = await Promise.all([
      employeeInfoCollection.countDocuments(),
      employeeAttendanceCollection.find({ attendanceDate: date }).toArray(),
    ]);
    const present = records.filter((record) => record.present !== false && record.approved === true).length;
    const pending = records.filter((record) => record.status === 'Pending Approval' || record.approved !== true).length;
    return res.json({ date, total, present, absent: Math.max(total - present, 0), pending, recorded: records.length, late: records.filter((record) => record.isLate === true).length });
  } catch (error) {
    console.error('GET /api/employee-attendance/summary failed:', error);
    return res.status(500).json({ message: 'Unable to calculate attendance summary.' });
  }
});

app.get('/api/employee-attendance/pending', async (req, res) => {
  try {
    await connectMongo();
    const filter = { status: 'Pending Approval' };
    if (req.query.date) filter.attendanceDate = String(req.query.date).trim();
    const records = await employeeAttendanceCollection.find(filter).sort({ timeRecorded: 1, _id: 1 }).toArray();
    return res.json({ data: records.map(sanitizeEmployeeAttendanceForResponse) });
  } catch (error) {
    console.error('GET /api/employee-attendance/pending failed:', error);
    return res.status(500).json({ message: 'Unable to load pending attendance.' });
  }
});

app.get('/api/employee-attendance/late', async (req, res) => {
  try {
    await connectMongo();
    const filter = { isLate: true };
    if (req.query.date) filter.attendanceDate = String(req.query.date).trim();
    const records = await employeeAttendanceCollection.find(filter).sort({ timeRecorded: -1, _id: -1 }).toArray();
    return res.json({ data: records.map(sanitizeEmployeeAttendanceForResponse) });
  } catch (error) {
    console.error('GET /api/employee-attendance/late failed:', error);
    return res.status(500).json({ message: 'Unable to load late attendance.' });
  }
});

app.get('/api/employee-attendance/:id', async (req, res) => {
  try {
    const id = employeeAttendanceObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid attendance ID.' });
    await connectMongo();
    const record = await employeeAttendanceCollection.findOne({ _id: id });
    if (!record) return res.status(404).json({ message: 'Attendance record not found.' });
    return res.json(sanitizeEmployeeAttendanceForResponse(record));
  } catch (error) {
    console.error('GET /api/employee-attendance/:id failed:', error);
    return res.status(500).json({ message: 'Unable to load the attendance record.' });
  }
});

app.post('/api/employee-attendance', async (req, res) => {
  try {
    const { values, error } = employeeAttendancePayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const employee = await findEmployeeForAttendance(values.employeeId);
    if (!employee) return res.status(422).json({ message: 'Employee ID does not exist.' });
    const now = new Date();
    const document = { ...values, teacherId: employee.employeeId, employeeName: employee.name, status: 'Pending Approval', approved: false, approvedBy: null, approvedAt: null, createdAt: now, updatedAt: now };
    const result = await employeeAttendanceCollection.insertOne(document);
    return res.status(201).json(sanitizeEmployeeAttendanceForResponse(await employeeAttendanceCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    if (error?.code === 11000) return res.status(409).json({ message: 'Attendance is already recorded for this employee and date.' });
    console.error('POST /api/employee-attendance failed:', error);
    return res.status(500).json({ message: 'Unable to create employee attendance.' });
  }
});

app.put('/api/employee-attendance/:id', async (req, res) => {
  try {
    const id = employeeAttendanceObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid attendance ID.' });
    const { values, error } = employeeAttendancePayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const employee = await findEmployeeForAttendance(values.employeeId);
    if (!employee) return res.status(422).json({ message: 'Employee ID does not exist.' });
    const result = await employeeAttendanceCollection.updateOne({ _id: id }, { $set: { ...values, teacherId: employee.employeeId, employeeName: employee.name, updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Attendance record not found.' });
    return res.json(sanitizeEmployeeAttendanceForResponse(await employeeAttendanceCollection.findOne({ _id: id })));
  } catch (error) {
    if (error?.code === 11000) return res.status(409).json({ message: 'Attendance is already recorded for this employee and date.' });
    console.error('PUT /api/employee-attendance/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update employee attendance.' });
  }
});

app.patch('/api/employee-attendance/:id/approve', async (req, res) => {
  try {
    const id = employeeAttendanceObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid attendance ID.' });
    await connectMongo();
    const result = await employeeAttendanceCollection.updateOne({ _id: id }, { $set: { approved: true, status: 'Approved', approvedBy: req.auth?.userId || 'admin', approvedAt: new Date(), updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Attendance record not found.' });
    return res.json(sanitizeEmployeeAttendanceForResponse(await employeeAttendanceCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PATCH /api/employee-attendance/:id/approve failed:', error);
    return res.status(500).json({ message: 'Unable to approve attendance.' });
  }
});

app.patch('/api/employee-attendance/:id/late', async (req, res) => {
  try {
    const id = employeeAttendanceObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid attendance ID.' });
    await connectMongo();
    const isLate = req.body?.isLate === true;
    const result = await employeeAttendanceCollection.updateOne({ _id: id }, { $set: { isLate, updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Attendance record not found.' });
    return res.json(sanitizeEmployeeAttendanceForResponse(await employeeAttendanceCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PATCH /api/employee-attendance/:id/late failed:', error);
    return res.status(500).json({ message: 'Unable to update late attendance.' });
  }
});

// Gate Register CRUD
function gateRegisterPayload(body) {
  const gateNo = String(body.gateNo || '').trim();
  const customGateNo = String(body.customGateNo || '').trim();
  const personType = String(body.personType || '').trim();
  const allowedGates = ['1', '2', '3', 'Other'];
  const allowedPeople = ['Student', 'Staff', 'Parent', 'Others'];
  if (!allowedGates.includes(gateNo)) return { error: 'Gate number must be 1, 2, 3, or Other.' };
  if (gateNo === 'Other' && !customGateNo) return { error: 'Custom gate number is required for Other.' };
  if (!allowedPeople.includes(personType)) return { error: 'Person type must be Student, Staff, Parent, or Others.' };
  const entryDate = body.entryDate ? new Date(body.entryDate) : new Date();
  if (Number.isNaN(entryDate.getTime())) return { error: 'Entry date is invalid.' };
  return { values: { gateNo, customGateNo: gateNo === 'Other' ? customGateNo : '', personType, entryDate } };
}

function gateRegisterObjectId(id) {
  return ObjectId.isValid(id) ? new ObjectId(id) : null;
}

app.get('/api/gate-register', async (req, res) => {
  try {
    await connectMongo();
    const filter = {};
    if (req.query.personType) filter.personType = String(req.query.personType).trim();
    const records = await gateRegisterCollection.find(filter).sort({ entryDate: -1, _id: -1 }).toArray();
    return res.json(records.map(sanitizeGateRegisterForResponse));
  } catch (error) {
    console.error('GET /api/gate-register failed:', error);
    return res.status(500).json({ message: 'Unable to load gate register records.' });
  }
});

app.get('/api/gate-register/:id', async (req, res) => {
  try {
    const id = gateRegisterObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid gate register ID.' });
    await connectMongo();
    const record = await gateRegisterCollection.findOne({ _id: id });
    if (!record) return res.status(404).json({ message: 'Gate register record not found.' });
    return res.json(sanitizeGateRegisterForResponse(record));
  } catch (error) {
    console.error('GET /api/gate-register/:id failed:', error);
    return res.status(500).json({ message: 'Unable to load the gate register record.' });
  }
});

app.post('/api/gate-register', async (req, res) => {
  try {
    const { values, error } = gateRegisterPayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const now = new Date();
    const result = await gateRegisterCollection.insertOne({ ...values, status: 'Registered', createdAt: now, updatedAt: now });
    return res.status(201).json(sanitizeGateRegisterForResponse(await gateRegisterCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST /api/gate-register failed:', error);
    return res.status(500).json({ message: 'Unable to create the gate register record.' });
  }
});

app.put('/api/gate-register/:id', async (req, res) => {
  try {
    const id = gateRegisterObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid gate register ID.' });
    const { values, error } = gateRegisterPayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const result = await gateRegisterCollection.updateOne({ _id: id }, { $set: { ...values, updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Gate register record not found.' });
    return res.json(sanitizeGateRegisterForResponse(await gateRegisterCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PUT /api/gate-register/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update the gate register record.' });
  }
});

app.delete('/api/gate-register/:id', async (req, res) => {
  try {
    const id = gateRegisterObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid gate register ID.' });
    await connectMongo();
    const result = await gateRegisterCollection.deleteOne({ _id: id });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Gate register record not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/gate-register/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete the gate register record.' });
  }
});

// Bus GPS CRUD
function busGpsPayload(body) {
  const values = {
    busRouteCode: String(body.busRouteCode || '').trim(),
    busRouteStatus: String(body.busRouteStatus || '').trim(),
    year: String(body.year || '').trim(),
    busRouteDescription: String(body.busRouteDescription || '').trim(),
    busRouteDriver: String(body.busRouteDriver || '').trim(),
    busNo: String(body.busNo || '').trim(),
    hasGpsDevice: String(body.hasGpsDevice || '').trim(),
  };
  const missing = Object.entries(values).filter(([, value]) => !value).map(([key]) => key);
  if (missing.length > 0) return { error: `Required fields missing: ${missing.join(', ')}.` };
  if (!['Active', 'Inactive'].includes(values.busRouteStatus)) return { error: 'Bus route status must be Active or Inactive.' };
  if (!['Yes', 'No'].includes(values.hasGpsDevice)) return { error: 'hasGpsDevice must be Yes or No.' };
  return { values };
}

function busGpsObjectId(id) {
  return ObjectId.isValid(id) ? new ObjectId(id) : null;
}

app.get('/api/bus-gps', async (req, res) => {
  try {
    await connectMongo();
    const routes = await busGpsCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(routes.map(sanitizeBusGpsForResponse));
  } catch (error) {
    console.error('GET /api/bus-gps failed:', error);
    return res.status(500).json({ message: 'Unable to load bus routes.' });
  }
});

app.get('/api/bus-gps/:id', async (req, res) => {
  try {
    const id = busGpsObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid bus route ID.' });
    await connectMongo();
    const route = await busGpsCollection.findOne({ _id: id });
    if (!route) return res.status(404).json({ message: 'Bus route not found.' });
    return res.json(sanitizeBusGpsForResponse(route));
  } catch (error) {
    console.error('GET /api/bus-gps/:id failed:', error);
    return res.status(500).json({ message: 'Unable to load the bus route.' });
  }
});

app.post('/api/bus-gps', async (req, res) => {
  try {
    const { values, error } = busGpsPayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const now = new Date().toISOString();
    const payload = { ...values, gpsStatus: values.hasGpsDevice === 'Yes' ? 'Online' : 'Offline', engineStatus: 'OFF', isActive: values.busRouteStatus === 'Active', createdAt: now, updatedAt: now };
    const result = await busGpsCollection.insertOne(payload);
    return res.status(201).json(sanitizeBusGpsForResponse(await busGpsCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST /api/bus-gps failed:', error);
    return res.status(500).json({ message: 'Unable to create the bus route.' });
  }
});

app.put('/api/bus-gps/:id', async (req, res) => {
  try {
    const id = busGpsObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid bus route ID.' });
    const { values, error } = busGpsPayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const result = await busGpsCollection.updateOne({ _id: id }, { $set: { ...values, isActive: values.busRouteStatus === 'Active', updatedAt: new Date().toISOString() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Bus route not found.' });
    return res.json(sanitizeBusGpsForResponse(await busGpsCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PUT /api/bus-gps/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update the bus route.' });
  }
});

app.delete('/api/bus-gps/:id', async (req, res) => {
  try {
    const id = busGpsObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid bus route ID.' });
    await connectMongo();
    const result = await busGpsCollection.deleteOne({ _id: id });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Bus route not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/bus-gps/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete the bus route.' });
  }
});

app.patch('/api/bus-gps/:id/gps-status', async (req, res) => {
  try {
    const id = busGpsObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid bus route ID.' });
    const gpsStatus = String(req.body?.gpsStatus || '').trim();
    if (!['Online', 'Offline'].includes(gpsStatus)) return res.status(422).json({ message: 'GPS status must be Online or Offline.' });
    await connectMongo();
    const result = await busGpsCollection.updateOne({ _id: id }, { $set: { gpsStatus, updatedAt: new Date().toISOString() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Bus route not found.' });
    return res.json(sanitizeBusGpsForResponse(await busGpsCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PATCH /api/bus-gps/:id/gps-status failed:', error);
    return res.status(500).json({ message: 'Unable to update GPS status.' });
  }
});

// Groups CRUD
app.get('/api/groups', async (req, res) => {
  try {
    await connectMongo();
    await ensureLegacyGroupsSeeded();
    const groups = await groupsCollection.find({}).sort({ order: 1, createdAt: 1, _id: 1 }).toArray();
    return res.json(groups.map(sanitizeGroupForResponse));
  } catch (error) {
    console.error('GET /api/groups failed:', error);
    return res.status(500).json({ message: 'Unable to load groups.' });
  }
});

app.get('/api/groups/:groupId', async (req, res) => {
  try {
    await connectMongo();
    const requestedId = (req.params.groupId || '').trim();
    let group = null;
    try {
      group = await groupsCollection.findOne({ _id: new ObjectId(requestedId) });
    } catch (_) {
      group = await groupsCollection.findOne({ id: requestedId });
    }
    if (!group) return res.status(404).json({ message: 'Group not found.' });
    return res.json(sanitizeGroupForResponse(group));
  } catch (error) {
    console.error('GET /api/groups/:groupId failed:', error);
    return res.status(500).json({ message: 'Unable to load group details.' });
  }
});

app.get('/api/groups/:groupId/events', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const events = await eventsCollection
      .find({ groupId: { $in: groupIdVariants(groupId) } })
      .sort({ startDate: 1, startTime: 1, createdAt: 1 })
      .toArray();
    return res.json(events.map(sanitizeEventForResponse));
  } catch (error) {
    console.error('GET /api/groups/:groupId/events failed:', error);
    return res.status(500).json({ message: 'Unable to load group events.' });
  }
});

app.post('/api/groups/:groupId/events', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const body = req.body || {};
    const title = (body.title || '').toString().trim();
    const startDate = (body.startDate || '').toString().trim();
    const endDate = (body.endDate || startDate).toString().trim();

    if (!groupId || !title || !startDate || Number.isNaN(Date.parse(startDate))) {
      return res.status(422).json({ message: 'groupId, title, and a valid startDate are required.' });
    }

    const group = await findGroupByReference(groupId);
    if (!group) return res.status(404).json({ message: 'Group not found.' });

    const now = new Date().toISOString();
    const event = {
      groupId,
      title,
      startDate,
      endDate: Number.isNaN(Date.parse(endDate)) ? startDate : endDate,
      startTime: body.startTime ? body.startTime.toString().trim() : null,
      endTime: body.endTime ? body.endTime.toString().trim() : null,
      description: body.description ? body.description.toString().trim() : '',
      createdBy: body.createdBy ? body.createdBy.toString().trim() : '',
      color: body.color ? body.color.toString().trim() : '#FF9800',
      createdAt: now,
      updatedAt: now,
    };

    const result = await eventsCollection.insertOne(event);
    const saved = await eventsCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeEventForResponse(saved));
  } catch (error) {
    console.error('POST /api/groups/:groupId/events failed:', error);
    return res.status(500).json({ message: 'Unable to create group event.' });
  }
});

app.put('/api/groups/:groupId/events/:eventId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const eventId = (req.params.eventId || '').trim();
    const body = req.body || {};
    const title = (body.title || '').toString().trim();
    const startDate = (body.startDate || '').toString().trim();
    if (!groupId || !eventId || !title || !startDate || Number.isNaN(Date.parse(startDate))) {
      return res.status(422).json({ message: 'groupId, title, and a valid startDate are required.' });
    }

    const selector = { groupId: { $in: groupIdVariants(groupId) } };
    try {
      selector._id = new ObjectId(eventId);
    } catch (_) {
      selector.id = eventId;
    }
    const now = new Date().toISOString();
    const update = {
      title,
      startDate,
      endDate: body.endDate ? body.endDate.toString().trim() : startDate,
      startTime: body.startTime ? body.startTime.toString().trim() : null,
      endTime: body.endTime ? body.endTime.toString().trim() : null,
      description: body.description ? body.description.toString().trim() : '',
      color: body.color ? body.color.toString().trim() : '#FF9800',
      updatedAt: now,
    };
    const result = await eventsCollection.updateOne(selector, { $set: update });
    if (!result.matchedCount) return res.status(404).json({ message: 'Event not found.' });
    const saved = await eventsCollection.findOne(selector);
    return res.json(sanitizeEventForResponse(saved));
  } catch (error) {
    console.error('PUT /api/groups/:groupId/events/:eventId failed:', error);
    return res.status(500).json({ message: 'Unable to update group event.' });
  }
});

app.delete('/api/groups/:groupId/events/:eventId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const eventId = (req.params.eventId || '').trim();
    const selector = { groupId: { $in: groupIdVariants(groupId) } };
    try {
      selector._id = new ObjectId(eventId);
    } catch (_) {
      selector.id = eventId;
    }
    const result = await eventsCollection.deleteOne(selector);
    if (!result.deletedCount) return res.status(404).json({ message: 'Event not found.' });
    return res.sendStatus(204);
  } catch (error) {
    console.error('DELETE /api/groups/:groupId/events/:eventId failed:', error);
    return res.status(500).json({ message: 'Unable to delete group event.' });
  }
});

app.get('/api/groups/:groupId/today-in-class', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const records = await todayInClassCollection
      .find({ groupId: { $in: groupIdVariants(groupId) } })
      .sort({ date: -1, createdAt: -1 })
      .toArray();
    return res.json(records.map(sanitizeTodayInClassForResponse));
  } catch (error) {
    console.error('GET /api/groups/:groupId/today-in-class failed:', error);
    return res.status(500).json({ message: 'Unable to load Today in Class.' });
  }
});

app.get('/api/groups/:groupId/homework', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const records = await homeworkCollection
      .find({ groupId: { $in: groupIdVariants(groupId) } })
      .sort({ date: -1, createdAt: -1 })
      .toArray();
    return res.json(records.map((record) => ({
      ...sanitizeTodayInClassForResponse(record),
      isHomework: true,
    })));
  } catch (error) {
    console.error('GET /api/groups/:groupId/homework failed:', error);
    return res.status(500).json({ message: 'Unable to load Homework.' });
  }
});

function sanitizeClassTimetableForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    groupId: doc.groupId || '', day: doc.day || '', startTime: doc.startTime || '', endTime: doc.endTime || '',
    subject: doc.subject || '', teacher: doc.teacher || '', room: doc.room || '', notes: doc.notes || '',
    createdAt: doc.createdAt || '', updatedAt: doc.updatedAt || '',
  };
}

function sanitizeLessonPlanForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || null,
    groupId: doc.groupId || '',
    date: doc.date || '',
    subject: doc.subject || '',
    topic: doc.topic || '',
    startTime: doc.startTime || '',
    endTime: doc.endTime || '',
    learningObjectives: doc.learningObjectives || '',
    notes: doc.notes || '',
    room: doc.room || '',
    status: doc.status || 'Planned',
    attachments: Array.isArray(doc.attachments) ? doc.attachments : [],
    completionNotes: doc.completionNotes || '',
    createdAt: doc.createdAt || '',
    updatedAt: doc.updatedAt || '',
  };
}

function timetableSelector(groupId, entryId) {
  return { groupId: { $in: groupIdVariants(groupId) }, ...recordIdSelector(entryId) };
}

app.get('/api/groups/:groupId/class-timetable', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const entries = await classTimetableCollection.find({ groupId: { $in: groupIdVariants(groupId) } }).toArray();
    return res.json(entries.map(sanitizeClassTimetableForResponse));
  } catch (error) {
    console.error('GET class timetable failed:', error);
    return res.status(500).json({ message: 'Unable to load class timetable.' });
  }
});

app.post('/api/groups/:groupId/class-timetable', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const body = req.body || {};
    const values = ['day', 'startTime', 'endTime', 'subject', 'teacher'];
    const entry = Object.fromEntries([...values, 'room', 'notes'].map((field) => [field, (body[field] || '').toString().trim()]));
    if (!groupId || values.some((field) => !entry[field])) return res.status(422).json({ message: 'Day, start time, end time, subject, and teacher are required.' });
    const now = new Date().toISOString();
    const result = await classTimetableCollection.insertOne({ groupId, ...entry, createdAt: now, updatedAt: now });
    return res.status(201).json(sanitizeClassTimetableForResponse(await classTimetableCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST class timetable failed:', error);
    return res.status(500).json({ message: 'Unable to save class timetable.' });
  }
});

app.put('/api/groups/:groupId/class-timetable/:entryId', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const values = ['day', 'startTime', 'endTime', 'subject', 'teacher'];
    const update = Object.fromEntries([...values, 'room', 'notes'].map((field) => [field, (body[field] || '').toString().trim()]));
    if (values.some((field) => !update[field])) return res.status(422).json({ message: 'Day, start time, end time, subject, and teacher are required.' });
    update.updatedAt = new Date().toISOString();
    const selector = timetableSelector((req.params.groupId || '').trim(), req.params.entryId);
    const result = await classTimetableCollection.updateOne(selector, { $set: update });
    if (!result.matchedCount) return res.status(404).json({ message: 'Timetable entry not found.' });
    return res.json(sanitizeClassTimetableForResponse(await classTimetableCollection.findOne(selector)));
  } catch (error) {
    console.error('PUT class timetable failed:', error);
    return res.status(500).json({ message: 'Unable to update class timetable.' });
  }
});

app.delete('/api/groups/:groupId/class-timetable/:entryId', async (req, res) => {
  try {
    await connectMongo();
    const selector = timetableSelector((req.params.groupId || '').trim(), req.params.entryId);
    const result = await classTimetableCollection.deleteOne(selector);
    if (!result.deletedCount) return res.status(404).json({ message: 'Timetable entry not found.' });
    return res.sendStatus(204);
  } catch (error) {
    console.error('DELETE class timetable failed:', error);
    return res.status(500).json({ message: 'Unable to delete class timetable.' });
  }
});

// Lesson Plans API Endpoints
app.get('/api/groups/:groupId/lesson-plans', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const date = (req.query.date || '').toString().trim();
    
    let query = { groupId: { $in: groupIdVariants(groupId) } };
    if (date && !Number.isNaN(Date.parse(date))) {
      const startDate = new Date(date);
      const endDate = new Date(date);
      endDate.setDate(endDate.getDate() + 1);
      query.date = { $gte: startDate.toISOString(), $lt: endDate.toISOString() };
    }
    
    const plans = await lessonPlansCollection.find(query).sort({ date: -1, startTime: -1 }).toArray();
    return res.json(plans.map(sanitizeLessonPlanForResponse));
  } catch (error) {
    console.error('GET lesson plans failed:', error);
    return res.status(500).json({ message: 'Unable to load lesson plans.' });
  }
});

app.post('/api/groups/:groupId/lesson-plans', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const body = req.body || {};
    const values = ['date', 'subject', 'topic', 'startTime', 'endTime'];
    const plan = Object.fromEntries([...values, 'learningObjectives', 'notes', 'room', 'status', 'attachments', 'completionNotes'].map((field) => [field, (body[field] || '').toString().trim()]));
    
    if (!groupId || values.some((field) => !plan[field])) {
      return res.status(422).json({ message: 'Date, subject, topic, start time, and end time are required.' });
    }
    
    if (Number.isNaN(Date.parse(plan.date))) {
      return res.status(422).json({ message: 'Invalid date format.' });
    }
    
    const now = new Date().toISOString();
    const result = await lessonPlansCollection.insertOne({ 
      groupId, 
      ...plan, 
      date: plan.date,
      status: plan.status || 'Planned',
      attachments: Array.isArray(body.attachments) ? body.attachments.map((item) => item.toString()) : [],
      createdAt: now, 
      updatedAt: now 
    });
    return res.status(201).json(sanitizeLessonPlanForResponse(await lessonPlansCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST lesson plan failed:', error);
    return res.status(500).json({ message: 'Unable to save lesson plan.' });
  }
});

app.put('/api/groups/:groupId/lesson-plans/:planId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const planId = (req.params.planId || '').trim();
    const body = req.body || {};
    const values = ['date', 'subject', 'topic', 'startTime', 'endTime'];
    const plan = Object.fromEntries([...values, 'learningObjectives', 'notes', 'room', 'status', 'attachments', 'completionNotes'].map((field) => [field, (body[field] || '').toString().trim()]));
    
    if (values.some((field) => !plan[field])) {
      return res.status(422).json({ message: 'Date, subject, topic, start time, and end time are required.' });
    }
    
    if (Number.isNaN(Date.parse(plan.date))) {
      return res.status(422).json({ message: 'Invalid date format.' });
    }
    
    const selector = { groupId: { $in: groupIdVariants(groupId) }, ...recordIdSelector(planId) };
    const update = {
      date: plan.date,
      subject: plan.subject,
      topic: plan.topic,
      startTime: plan.startTime,
      endTime: plan.endTime,
      learningObjectives: plan.learningObjectives,
      notes: plan.notes,
      room: plan.room,
      status: plan.status || 'Planned',
      attachments: Array.isArray(body.attachments) ? body.attachments.map((item) => item.toString()) : [],
      completionNotes: plan.completionNotes,
      updatedAt: new Date().toISOString(),
    };
    const result = await lessonPlansCollection.updateOne(selector, { $set: update });
    if (!result.matchedCount) return res.status(404).json({ message: 'Lesson plan not found.' });
    return res.json(sanitizeLessonPlanForResponse(await lessonPlansCollection.findOne(selector)));
  } catch (error) {
    console.error('PUT lesson plan failed:', error);
    return res.status(500).json({ message: 'Unable to update lesson plan.' });
  }
});

app.delete('/api/groups/:groupId/lesson-plans/:planId', async (req, res) => {
  try {
    await connectMongo();
    const selector = { groupId: { $in: groupIdVariants((req.params.groupId || '').trim()) }, ...recordIdSelector(req.params.planId) };
    const result = await lessonPlansCollection.deleteOne(selector);
    if (!result.deletedCount) return res.status(404).json({ message: 'Lesson plan not found.' });
    return res.sendStatus(204);
  } catch (error) {
    console.error('DELETE lesson plan failed:', error);
    return res.status(500).json({ message: 'Unable to delete lesson plan.' });
  }
});

app.post('/api/groups/:groupId/homework', async (req, res) => {
  try {
    await connectMongo();
    const requestedGroupId = (req.params.groupId || '').trim();
    const group = await findGroupByReference(requestedGroupId);
    if (!group) return res.status(404).json({ message: 'Group not found.' });
    const body = req.body || {};
    const subject = (body.subject || '').toString().trim();
    const message = (body.message || '').toString().trim();
    const date = (body.date || '').toString().trim();
    if (!subject || !message || !date || Number.isNaN(Date.parse(date))) {
      return res.status(422).json({ message: 'Date, subject, and message are required.' });
    }
    const now = new Date().toISOString();
    const record = {
      groupId: requestedGroupId,
      date,
      subject,
      message,
      sendToStudents: body.sendToStudents === true,
      sendToTeachers: body.sendToTeachers === true,
      commentsAllowed: body.commentsAllowed !== false,
      attachments: Array.isArray(body.attachments) ? body.attachments.map((item) => item.toString()) : [],
      createdAt: now,
      updatedAt: now,
    };
    const result = await homeworkCollection.insertOne(record);
    const saved = await homeworkCollection.findOne({ _id: result.insertedId });
    return res.status(201).json({ ...sanitizeTodayInClassForResponse(saved), isHomework: true });
  } catch (error) {
    console.error('POST /api/groups/:groupId/homework failed:', error);
    return res.status(500).json({ message: 'Unable to save Homework.' });
  }
});

app.put('/api/groups/:groupId/homework/:recordId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const recordId = (req.params.recordId || '').trim();
    const body = req.body || {};
    const date = (body.date || '').toString().trim();
    const subject = (body.subject || '').toString().trim();
    const message = (body.message || '').toString().trim();
    if (!groupId || !recordId || !date || Number.isNaN(Date.parse(date)) || !subject || !message) {
      return res.status(422).json({ message: 'Date, subject, and message are required.' });
    }
    const selector = {
      groupId: { $in: groupIdVariants(groupId) },
      ...recordIdSelector(recordId),
    };
    const update = {
      date,
      subject,
      message,
      sendToStudents: body.sendToStudents === true,
      sendToTeachers: body.sendToTeachers === true,
      commentsAllowed: body.commentsAllowed !== false,
      attachments: Array.isArray(body.attachments) ? body.attachments.map((item) => item.toString()) : [],
      updatedAt: new Date().toISOString(),
    };
    const result = await homeworkCollection.updateOne(selector, { $set: update });
    if (!result.matchedCount) return res.status(404).json({ message: 'Homework record not found.' });
    const saved = await homeworkCollection.findOne(selector);
    return res.json({ ...sanitizeTodayInClassForResponse(saved), isHomework: true });
  } catch (error) {
    console.error('PUT /api/groups/:groupId/homework/:recordId failed:', error);
    return res.status(500).json({ message: 'Unable to update Homework.' });
  }
});

app.delete('/api/groups/:groupId/homework/:recordId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const selector = {
      groupId: { $in: groupIdVariants(groupId) },
      ...recordIdSelector(req.params.recordId),
    };
    const result = await homeworkCollection.deleteOne(selector);
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Homework record not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/groups/:groupId/homework/:recordId failed:', error);
    return res.status(500).json({ message: 'Unable to delete Homework.' });
  }
});

app.post('/api/groups/:groupId/today-in-class', async (req, res) => {
  try {
    await connectMongo();
    const requestedGroupId = (req.params.groupId || '').trim();
    const group = await findGroupByReference(requestedGroupId);
    if (!group) return res.status(404).json({ message: 'Group not found.' });

    const body = req.body || {};
    const subject = (body.subject || '').toString().trim();
    const message = (body.message || '').toString().trim();
    const date = (body.date || '').toString().trim();
    if (!subject || !message || !date || Number.isNaN(Date.parse(date))) {
      return res.status(422).json({ message: 'Date, subject, and message are required.' });
    }

    const now = new Date().toISOString();
    const record = {
      groupId: requestedGroupId,
      date,
      subject,
      message,
      sendToStudents: body.sendToStudents === true,
      sendToTeachers: body.sendToTeachers === true,
      commentsAllowed: body.commentsAllowed !== false,
      isHomework: body.isHomework === true,
      attachments: Array.isArray(body.attachments) ? body.attachments.map((item) => item.toString()) : [],
      createdAt: now,
      updatedAt: now,
    };
    const result = await todayInClassCollection.insertOne(record);
    const saved = await todayInClassCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeTodayInClassForResponse(saved));
  } catch (error) {
    console.error('POST /api/groups/:groupId/today-in-class failed:', error);
    return res.status(500).json({ message: 'Unable to save Today in Class.' });
  }
});

app.put('/api/groups/:groupId/today-in-class/:recordId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const recordId = (req.params.recordId || '').trim();
    const body = req.body || {};
    const date = (body.date || '').toString().trim();
    const subject = (body.subject || '').toString().trim();
    const message = (body.message || '').toString().trim();
    if (!groupId || !recordId || !date || Number.isNaN(Date.parse(date)) || !subject || !message) {
      return res.status(422).json({ message: 'Date, subject, and message are required.' });
    }

    const selector = {
      groupId: { $in: groupIdVariants(groupId) },
      ...recordIdSelector(recordId),
    };
    const update = {
      date,
      subject,
      message,
      sendToStudents: body.sendToStudents === true,
      sendToTeachers: body.sendToTeachers === true,
      commentsAllowed: body.commentsAllowed !== false,
      isHomework: body.isHomework === true,
      attachments: Array.isArray(body.attachments) ? body.attachments.map((item) => item.toString()) : [],
      updatedAt: new Date().toISOString(),
    };
    const result = await todayInClassCollection.updateOne(selector, { $set: update });
    if (!result.matchedCount) return res.status(404).json({ message: 'Today in Class record not found.' });
    const saved = await todayInClassCollection.findOne(selector);
    return res.json(sanitizeTodayInClassForResponse(saved));
  } catch (error) {
    console.error('PUT /api/groups/:groupId/today-in-class/:recordId failed:', error);
    return res.status(500).json({ message: 'Unable to update Today in Class.' });
  }
});

app.delete('/api/groups/:groupId/today-in-class/:recordId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const result = await todayInClassCollection.deleteOne({
      groupId: { $in: groupIdVariants(groupId) },
      ...recordIdSelector(req.params.recordId),
    });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Today in Class record not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/groups/:groupId/today-in-class/:recordId failed:', error);
    return res.status(500).json({ message: 'Unable to delete Today in Class.' });
  }
});

app.get('/api/groups/:groupId/messages', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const messages = await groupMessagesCollection
      .find({ groupId: { $in: groupIdVariants(groupId) } })
      .sort({ createdAt: -1 })
      .toArray();

    const hydrated = await Promise.all(messages.map(async (message) => {
      const messageKey = message.id || (message._id ? message._id.toString() : '');
      const comments = await groupMessageCommentsCollection
        .find({ groupId: { $in: groupIdVariants(groupId) }, messageId: messageKey || (message._id ? message._id.toString() : '') })
        .sort({ createdAt: 1 })
        .toArray();

      return {
        ...message,
        likedBy: Array.isArray(message.likedBy) ? message.likedBy : [],
        comments: comments.map((comment) => ({
          id: comment._id ? comment._id.toString() : comment.id || null,
          studentId: comment.studentId || '',
          studentName: comment.studentName || 'Student',
          text: comment.text || comment.comment || '',
          createdAt: comment.createdAt || new Date().toISOString(),
        })),
      };
    }));

    return res.json(hydrated.map(sanitizeGroupMessageForResponse));
  } catch (error) {
    console.error('GET /api/groups/:groupId/messages failed:', error);
    return res.status(500).json({ message: 'Unable to load messages.' });
  }
});

app.post('/api/groups/:groupId/messages/:messageId/like', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const messageId = (req.params.messageId || '').trim();
    const userId = (req.body.userId || '').toString().trim();

    if (!groupId || !messageId || !userId) {
      return res.status(422).json({ message: 'groupId, messageId, and userId are required.' });
    }

    let selector;
    try {
      selector = { _id: new ObjectId(messageId), groupId: { $in: groupIdVariants(groupId) } };
    } catch (_) {
      selector = { id: messageId, groupId: { $in: groupIdVariants(groupId) } };
    }

    const message = await groupMessagesCollection.findOne(selector);
    if (!message) {
      return res.status(404).json({ message: 'Message not found.' });
    }

    const likedBy = Array.isArray(message.likedBy) ? message.likedBy.filter((entry) => entry && entry.toString().trim()) : [];
    const alreadyLiked = likedBy.some((entry) => entry.toString() === userId);
    const nextLikedBy = alreadyLiked
      ? likedBy.filter((entry) => entry.toString() !== userId)
      : [...new Set([...likedBy, userId])];

    const result = await groupMessagesCollection.updateOne(selector, {
      $set: { likedBy: nextLikedBy, updatedAt: new Date().toISOString() },
    });

    if (!result.matchedCount) {
      return res.status(404).json({ message: 'Message not found.' });
    }

    return res.json({
      liked: !alreadyLiked,
      likeCount: nextLikedBy.length,
      likedBy: nextLikedBy,
    });
  } catch (error) {
    console.error('POST /api/groups/:groupId/messages/:messageId/like failed:', error);
    return res.status(500).json({ message: 'Unable to toggle like.' });
  }
});

app.get('/api/groups/:groupId/messages/:messageId/comments', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const messageId = (req.params.messageId || '').trim();

    const comments = await groupMessageCommentsCollection
      .find({ groupId: { $in: groupIdVariants(groupId) }, messageId })
      .sort({ createdAt: 1 })
      .toArray();

    return res.json(comments.map((comment) => ({
      id: comment._id ? comment._id.toString() : comment.id || null,
      messageId: comment.messageId || messageId,
      groupId: comment.groupId || groupId,
      studentId: comment.studentId || '',
      studentName: comment.studentName || 'Student',
      comment: comment.comment || '',
      text: comment.comment || comment.text || '',
      createdAt: comment.createdAt || null,
      updatedAt: comment.updatedAt || comment.createdAt || null,
    })));
  } catch (error) {
    console.error('GET /api/groups/:groupId/messages/:messageId/comments failed:', error);
    return res.status(500).json({ message: 'Unable to load comments.' });
  }
});

app.post('/api/groups/:groupId/messages/:messageId/comments', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const messageId = (req.params.messageId || '').trim();
    const userRole = (req.body.userRole || '').toString().trim().toLowerCase();
    const userId = (req.body.userId || req.body.studentId || '').toString().trim();
    const studentName = (req.body.studentName || '').toString().trim();
    const text = (req.body.comment || req.body.text || '').toString().trim();

    if (!groupId || !messageId || !userId || !text) {
      return res.status(422).json({ message: 'messageId, userId, and comment text are required.' });
    }
    if (userRole !== 'student') {
      return res.status(403).json({ message: 'Only students can comment on group messages.' });
    }

    const saved = await groupMessageCommentsCollection.insertOne({
      messageId,
      groupId,
      studentId: userId,
      studentName: studentName || 'Student',
      comment: text,
      text,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    const created = await groupMessageCommentsCollection.findOne({ _id: saved.insertedId });
    return res.status(201).json({
      id: created?._id ? created._id.toString() : null,
      messageId,
      groupId,
      studentId: userId,
      studentName: created?.studentName || studentName || 'Student',
      comment: created?.comment || text,
      text: created?.comment || text,
      createdAt: created?.createdAt || null,
      updatedAt: created?.updatedAt || null,
    });
  } catch (error) {
    console.error('POST /api/groups/:groupId/messages/:messageId/comments failed:', error);
    return res.status(500).json({ message: 'Unable to add comment.' });
  }
});

app.put('/api/groups/:groupId/messages/:messageId/comments/:commentId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const messageId = (req.params.messageId || '').trim();
    const commentId = (req.params.commentId || '').trim();
    const userId = (req.body.userId || '').toString().trim();
    const userRole = (req.body.userRole || '').toString().trim().toLowerCase();
    const text = (req.body.comment || req.body.text || '').toString().trim();

    if (!userId || !text) {
      return res.status(422).json({ message: 'userId and comment text are required.' });
    }
    if (userRole !== 'student') {
      return res.status(403).json({ message: 'Only students can edit comments.' });
    }

    let selector;
    try {
      selector = { _id: new ObjectId(commentId), groupId: { $in: groupIdVariants(groupId) }, messageId, studentId: userId };
    } catch (_) {
      selector = { id: commentId, groupId: { $in: groupIdVariants(groupId) }, messageId, studentId: userId };
    }

    const result = await groupMessageCommentsCollection.updateOne(selector, {
      $set: { comment: text, text, updatedAt: new Date().toISOString() },
    });
    if (!result.matchedCount) return res.status(404).json({ message: 'Comment not found.' });

    const updated = await groupMessageCommentsCollection.findOne(selector);
    return res.json({
      id: updated?._id ? updated._id.toString() : updated?.id || null,
      messageId: updated?.messageId || messageId,
      groupId: updated?.groupId || groupId,
      studentId: updated?.studentId || userId,
      studentName: updated?.studentName || 'Student',
      comment: updated?.comment || text,
      text: updated?.comment || text,
      createdAt: updated?.createdAt || null,
      updatedAt: updated?.updatedAt || null,
    });
  } catch (error) {
    console.error('PUT /api/groups/:groupId/messages/:messageId/comments/:commentId failed:', error);
    return res.status(500).json({ message: 'Unable to update comment.' });
  }
});

app.delete('/api/groups/:groupId/messages/:messageId/comments/:commentId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const messageId = (req.params.messageId || '').trim();
    const commentId = (req.params.commentId || '').trim();
    const userId = (req.body.userId || '').toString().trim();
    const userRole = (req.body.userRole || '').toString().trim().toLowerCase();

    if (!userId) {
      return res.status(422).json({ message: 'userId is required.' });
    }
    if (userRole !== 'student') {
      return res.status(403).json({ message: 'Only students can delete comments.' });
    }

    let selector;
    try {
      selector = { _id: new ObjectId(commentId), groupId: { $in: groupIdVariants(groupId) }, messageId, studentId: userId };
    } catch (_) {
      selector = { id: commentId, groupId: { $in: groupIdVariants(groupId) }, messageId, studentId: userId };
    }

    const result = await groupMessageCommentsCollection.deleteOne(selector);
    if (!result.deletedCount) return res.status(404).json({ message: 'Comment not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/groups/:groupId/messages/:messageId/comments/:commentId failed:', error);
    return res.status(500).json({ message: 'Unable to delete comment.' });
  }
});

app.post('/api/groups/:groupId/messages', async (req, res) => {
  try {
    await connectMongo();
    const requestedGroupId = (req.params.groupId || '').trim();
    if (!requestedGroupId) {
      return res.status(422).json({ message: 'Current group ID is required.' });
    }

    const group = await findGroupByReference(requestedGroupId);
    if (!group) return res.status(404).json({ message: 'Group not found.' });

    const body = req.body || {};
    const content = (body.content || body.message || '').toString().trim();
    const title = (body.title || '').toString().trim();
    const category = (body.category || body.messageType || '').toString().trim();
    if (!content || !title || !category) {
      return res.status(422).json({ message: 'Title, message, and message type are required.' });
    }

    const senderId = (body.senderId || body.authorId || body.userId || '').toString().trim();
    const senderRole = (body.senderRole || body.authorRole || '').toString().trim().toLowerCase();
    if (!senderId) {
      return res.status(422).json({ message: 'Logged-in student is required.' });
    }
    if (senderRole !== 'student') {
      return res.status(403).json({ message: 'Only student accounts can create group messages.' });
    }

    const verifiedUser = await usersCollection.findOne({ userId: senderId, role: { $in: ['student', 'students'] } });
    if (!verifiedUser) {
      return res.status(403).json({ message: 'Student account not found.' });
    }

    const studentRecord = await studentInfoCollection.findOne({ studentId: senderId });
    const senderName = (body.senderName || studentRecord?.name || '').toString().trim() || verifiedUser.email?.split('@')[0] || 'Student';
    const senderEmail = (body.senderEmail || verifiedUser.email || '').toString().trim();
    const allowComments = body.allowComments !== undefined ? body.allowComments !== false : body.commentsAllowed !== false;
    const now = new Date().toISOString();
    const message = {
      groupId: requestedGroupId,
      groupName: (body.groupName || group.name || '').toString().trim(),
      title,
      content,
      message: content,
      authorId: senderId,
      createdBy: senderId,
      authorRole: 'student',
      senderId,
      senderRole: 'student',
      senderName,
      senderEmail,
      category,
      messageType: category,
      priority: (body.priority || 'Normal').toString().trim(),
      audience: Array.isArray(body.audience) ? body.audience : [],
      target: (body.target || '').toString().trim(),
      imageUrl: (body.imageUrl || null),
      expiryDate: (body.expiryDate || null),
      approved: body.approved === true,
      approvedById: (body.approvedById || '').toString().trim(),
      commentsAllowed: allowComments,
      allowComments,
      likedBy: [],
      comments: [],
      createdAt: now,
      updatedAt: now,
    };
    const result = await groupMessagesCollection.insertOne(message);
    const saved = await groupMessagesCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeGroupMessageForResponse(saved));
  } catch (error) {
    console.error('POST /api/groups/:groupId/messages failed:', error);
    return res.status(500).json({ message: 'Unable to save message.' });
  }
});

app.put('/api/groups/:groupId/messages/:messageId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const messageId = (req.params.messageId || '').trim();
    const body = req.body || {};
    
    const content = (body.content || body.message || '').toString().trim();
    const title = (body.title || '').toString().trim();
    const category = (body.category || body.messageType || '').toString().trim();
    if (!content || !title || !category) {
      return res.status(422).json({ message: 'Title, message, and message type are required.' });
    }

    const allowComments = body.allowComments !== undefined ? body.allowComments !== false : body.commentsAllowed !== false;
    const selector = { groupId: { $in: groupIdVariants(groupId) } };
    try {
      selector._id = new ObjectId(messageId);
    } catch (_) {
      selector.id = messageId;
    }

    const now = new Date().toISOString();
    const update = {
      title,
      content,
      message: content,
      category,
      messageType: category,
      priority: (body.priority || 'Normal').toString().trim(),
      audience: Array.isArray(body.audience) ? body.audience : [],
      target: (body.target || '').toString().trim(),
      imageUrl: (body.imageUrl || null),
      expiryDate: (body.expiryDate || null),
      commentsAllowed: allowComments,
      allowComments,
      updatedAt: now,
    };
    
    const result = await groupMessagesCollection.updateOne(selector, { $set: update });
    if (!result.matchedCount) return res.status(404).json({ message: 'Message not found.' });
    
    const saved = await groupMessagesCollection.findOne(selector);
    return res.json(sanitizeGroupMessageForResponse(saved));
  } catch (error) {
    console.error('PUT /api/groups/:groupId/messages/:messageId failed:', error);
    return res.status(500).json({ message: 'Unable to update message.' });
  }
});

app.delete('/api/groups/:groupId/messages/:messageId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    let result;
    try {
      result = await groupMessagesCollection.deleteOne({
        _id: new ObjectId(req.params.messageId),
        groupId: { $in: groupIdVariants(groupId) },
      });
    } catch (_) {
      result = await groupMessagesCollection.deleteOne({
        id: req.params.messageId,
        groupId: { $in: groupIdVariants(groupId) },
      });
    }
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Message not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/groups/:groupId/messages/:messageId failed:', error);
    return res.status(500).json({ message: 'Unable to delete message.' });
  }
});

app.post('/api/groups', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const name = (body.name || '').toString().trim();
    const groupId = (body.id || body.groupId || '').toString().trim();
    const type = (body.type || 'Other').toString().trim();
    const description = (body.description || body.code || '').toString().trim();
    const status = (body.status || 'Active').toString().trim();
    const year = (body.year || '').toString().trim();

    if (!name || !groupId || !type || !description || !year) {
      return res.status(422).json({ message: 'All fields are required.' });
    }

    const exists = await groupsCollection.findOne({ id: groupId });
    if (exists) {
      return res.status(409).json({ message: 'Group ID already exists' });
    }

    const totalCount = await groupsCollection.countDocuments();
    const createdAt = new Date().toISOString();
    const toSave = {
      name,
      id: groupId,
      type,
      description,
      code: description,
      status,
      year,
      order: totalCount + 1,
      createdAt,
      updatedAt: createdAt,
      students: [],
      teachers: [],
    };

    const result = await groupsCollection.insertOne(toSave);
    const saved = await groupsCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeGroupForResponse(saved));
  } catch (error) {
    console.error('POST /api/groups failed:', error);
    return res.status(500).json({ message: 'Unable to create group.' });
  }
});

app.put('/api/groups/:id', async (req, res) => {
  try {
    await connectMongo();
    const idParam = req.params.id;
    const body = req.body || {};
    const name = (body.name || '').toString().trim();
    const groupId = (body.id || body.groupId || '').toString().trim();
    const type = (body.type || 'Other').toString().trim();
    const description = (body.description || body.code || '').toString().trim();
    const status = (body.status || 'Active').toString().trim();
    const year = (body.year || '').toString().trim();

    if (!name || !groupId || !type || !description || !year) {
      return res.status(422).json({ message: 'All fields are required.' });
    }

    let existing;
    try {
      existing = await groupsCollection.findOne({ _id: new ObjectId(idParam) });
    } catch (_) {
      existing = await groupsCollection.findOne({ id: idParam });
    }

    if (!existing) {
      return res.status(404).json({ message: 'Group not found.' });
    }

    const duplicate = await groupsCollection.findOne({ id: groupId, _id: { $ne: existing._id } });
    if (duplicate) {
      return res.status(409).json({ message: 'Group ID already exists' });
    }

    const updatedAt = new Date().toISOString();
    const updatedDoc = {
      name,
      id: groupId,
      type,
      description,
      code: description,
      status,
      year,
      updatedAt,
      students: Array.isArray(body.students)
        ? body.students
        : (Array.isArray(existing.students) ? existing.students : []),
      teachers: Array.isArray(body.teachers)
        ? body.teachers
        : (Array.isArray(existing.teachers) ? existing.teachers : []),
    };

    await groupsCollection.updateOne({ _id: existing._id }, { $set: updatedDoc });
    const saved = await groupsCollection.findOne({ _id: existing._id });
    return res.json(sanitizeGroupForResponse(saved));
  } catch (error) {
    console.error('PUT /api/groups/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update group.' });
  }
});

app.delete('/api/groups/:id', async (req, res) => {
  try {
    await connectMongo();
    const idParam = req.params.id;
    let existing;
    try {
      existing = await groupsCollection.findOne({ _id: new ObjectId(idParam) });
    } catch (_) {
      existing = await groupsCollection.findOne({ id: idParam });
    }

    if (!existing) {
      return res.status(404).json({ message: 'Group not found.' });
    }

    await groupsCollection.deleteOne({ _id: existing._id });
    await renumberGroups();
    return res.json({ success: true, message: 'Group deleted successfully' });
  } catch (error) {
    console.error('DELETE /api/groups/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete group.' });
  }
});

// Users CRUD
app.get('/api/users', async (req, res) => {
  try {
    const role = req.query.role;
    const filter = {};
    if (role) filter.role = role;
    const users = await usersCollection.find(filter).toArray();
    return res.json(users.map(sanitizeUserForResponse));
  } catch (error) {
    console.error('GET /api/users failed:', error);
    return res.status(500).json({ message: 'Unable to load users.' });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const body = req.body || {};
    const userId = (body.userId || '').toString().trim();
    const email = (body.email || '').toString().trim().toLowerCase();
    const role = body.role || 'student';

    if (!userId || !email) {
      return res.status(422).json({ message: 'userId and email are required.' });
    }

    // uniqueness checks - check separately to give specific errors
    const existUserId = await usersCollection.findOne({ userId });
    if (existUserId) {
      return res.status(409).json({ message: 'User ID already exists.' });
    }
    const existEmail = await usersCollection.findOne({ email });
    if (existEmail) {
      return res.status(409).json({ message: 'Email already exists.' });
    }

    // Hash password before saving
    const plainPassword = body.password || '';
    const hashed = plainPassword ? await bcrypt.hash(plainPassword, 10) : '';

    const toSave = {
      userId,
      email,
      password: hashed,
      role,
      createdAt: new Date().toISOString(),
    };

    const result = await usersCollection.insertOne(toSave);
    const saved = await usersCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeUserForResponse(saved));
  } catch (error) {
    console.error('POST /api/users failed:', error);
    return res.status(500).json({ message: 'Unable to create user.' });
  }
});

app.get('/api/users/:id', async (req, res) => {
  try {
    const id = req.params.id;
    let doc;
    try {
      doc = await usersCollection.findOne({ _id: new ObjectId(id) });
    } catch (e) {
      // fallback to lookup by userId string (e.g. "testlocal123")
      doc = await usersCollection.findOne({ userId: id });
    }
    if (!doc) return res.status(404).json({ message: 'User not found.' });
    return res.json(sanitizeUserForResponse(doc));
  } catch (error) {
    console.error('GET /api/users/:id failed:', error);
    return res.status(500).json({ message: 'Unable to load user.' });
  }
});

app.put('/api/users/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const body = req.body || {};

    // find existing
    let existing;
    try {
      existing = await usersCollection.findOne({ _id: new ObjectId(id) });
    } catch (e) {
      // fallback to lookup by userId string
      existing = await usersCollection.findOne({ userId: id });
    }
    if (!existing) return res.status(404).json({ message: 'User not found.' });

    // prevent role changes unless explicitly provided
    const updates = {};
    if (body.email) updates.email = body.email.toString().trim().toLowerCase();
    if (body.password) {
      // hash password before storing
      updates.password = await bcrypt.hash(body.password, 10);
    }

    // check uniqueness for email change
    if (updates.email && updates.email !== (existing.email || '').toLowerCase()) {
      const conflict = await usersCollection.findOne({ email: updates.email, _id: { $ne: existing._id } });
      if (conflict) return res.status(409).json({ message: 'Email already in use.' });
    }

    if (Object.keys(updates).length === 0) return res.status(422).json({ message: 'No updatable fields provided.' });

    await usersCollection.updateOne({ _id: existing._id }, { $set: updates });
    const updated = await usersCollection.findOne({ _id: existing._id });
    return res.json(sanitizeUserForResponse(updated));
  } catch (error) {
    console.error('PUT /api/users/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update user.' });
  }
});

app.delete('/api/users/:id', async (req, res) => {
  try {
    const id = req.params.id;
    let result;
    try {
      result = await usersCollection.deleteOne({ _id: new ObjectId(id) });
    } catch (e) {
      // fallback to delete by userId string
      result = await usersCollection.deleteOne({ userId: id });
    }
    if (result.deletedCount === 0) return res.status(404).json({ success: false, message: 'User not found' });
    return res.json({ success: true, message: 'User deleted successfully' });
  } catch (error) {
    console.error('DELETE /api/users/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete user.' });
  }
});

// Staff handbook CRUD
app.get('/api/school-handbook/:schoolId', async (req, res) => {
  try {
    await connectMongo();
    const handbook = await schoolHandbookCollection.findOne({ schoolId: req.params.schoolId, handbookId: 'staff-handbook' });
    if (!handbook) {
      const now = new Date().toISOString();
      const result = await schoolHandbookCollection.insertOne({ schoolId: req.params.schoolId, handbookId: 'staff-handbook', title: 'Staff Handbook', shortDescription: 'Important information and policies for staff.', category: 'Staff Handbook', displayOrder: 1, overview: 'This handbook contains the information, expectations, and procedures that support staff in their day-to-day work at the school. Please read each section carefully and contact the school office when additional guidance is needed.', sections: [{ id: 'introduction', title: 'Introduction', content: '', order: 1 }, { id: 'responsibilities', title: 'Responsibilities', content: '', order: 2 }, { id: 'procedures', title: 'School Procedures', content: '', order: 3 }, { id: 'contacts', title: 'Useful Contacts', content: '', order: 4 }], contacts: [], documentUrl: '', documentName: '', isActive: true, createdAt: now, updatedAt: now });
      return res.json(sanitizeHandbookForResponse(await schoolHandbookCollection.findOne({ _id: result.insertedId })));
    }
    return res.json(sanitizeHandbookForResponse(handbook));
  } catch (error) {
    console.error('GET /api/school-handbook/:schoolId failed:', error);
    return res.status(500).json({ message: 'Unable to load the staff handbook.' });
  }
});

app.post('/api/school-handbook', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    if (!String(body.schoolId || '').trim()) return res.status(422).json({ message: 'schoolId is required.' });
    const now = new Date().toISOString();
    const document = {
      schoolId: String(body.schoolId).trim(), handbookId: 'staff-handbook',
      sections: Array.isArray(body.sections) ? body.sections : [], updatedAt: now, createdAt: now,
    };
    const result = await schoolHandbookCollection.insertOne(document);
    return res.status(201).json(sanitizeHandbookForResponse(await schoolHandbookCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST /api/school-handbook failed:', error);
    return res.status(500).json({ message: 'Unable to create the staff handbook.' });
  }
});

app.put('/api/school-handbook/:handbookId', async (req, res) => {
  try {
    await connectMongo();
    const id = new ObjectId(req.params.handbookId);
    const body = req.body || {};
    if (!String(body.schoolId || '').trim()) return res.status(422).json({ message: 'schoolId is required.' });
    const updates = {
      schoolId: String(body.schoolId).trim(), sections: Array.isArray(body.sections) ? body.sections : [], updatedAt: new Date().toISOString(),
    };
    const result = await schoolHandbookCollection.updateOne({ _id: id }, { $set: updates });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Staff handbook not found.' });
    return res.json(sanitizeHandbookForResponse(await schoolHandbookCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PUT /api/school-handbook/:handbookId failed:', error);
    return res.status(400).json({ message: 'Unable to update the staff handbook.' });
  }
});

app.delete('/api/school-handbook/:handbookId', async (req, res) => {
  try {
    await connectMongo();
    const result = await schoolHandbookCollection.deleteOne({ _id: new ObjectId(req.params.handbookId) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Staff handbook not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/school-handbook/:handbookId failed:', error);
    return res.status(400).json({ message: 'Unable to delete the staff handbook.' });
  }
});

// Demography CRUD
app.get('/api/demography', async (req, res) => {
  try {
    await connectMongo();
    const items = await demographyCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(items.map(sanitizeDemographyForResponse));
  } catch (error) {
    console.error('GET /api/demography failed:', error);
    return res.status(500).json({ message: 'Unable to load demography.' });
  }
});

app.get('/api/demography/group/:groupId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = String(req.params.groupId || '').trim();
    if (!groupId) return res.status(422).json({ message: 'Group ID is required.' });
    const items = await demographyCollection.find({ groupId }).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(items.map(sanitizeDemographyForResponse));
  } catch (error) {
    console.error('GET /api/demography/group/:groupId failed:', error);
    return res.status(500).json({ message: 'Unable to load group demography.' });
  }
});

app.post('/api/demography', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const groupId = String(body.groupId || '').trim();
    const groupName = String(body.groupName || '').trim();
    const teachers = Array.isArray(body.teachers) ? body.teachers : [];
    const otherTeachers = Array.isArray(body.otherTeachers) ? body.otherTeachers : [];
    const students = Array.isArray(body.students) ? body.students : [];

    if (!groupName) return res.status(422).json({ message: 'Group Name is required.' });
    if (students.length === 0 || !students.some((item) => String(item && item.name ? item.name : '').trim())) {
      return res.status(422).json({ message: 'At least one student is required.' });
    }

    const now = new Date().toISOString();
    const payload = {
      groupId: groupId || `group-${Date.now()}`,
      groupName,
      teachers: teachers.map((teacher) => ({
        name: String((teacher && teacher.name) || '').trim(),
        staffId: String((teacher && teacher.staffId) || '').trim(),
      })).filter((teacher) => teacher.name),
      otherTeachers: otherTeachers.map((teacher) => ({
        name: String((teacher && teacher.name) || '').trim(),
        staffId: String((teacher && teacher.staffId) || '').trim(),
      })).filter((teacher) => teacher.name),
      students: students.map((student) => ({
        name: String((student && student.name) || '').trim(),
        studentId: String((student && student.studentId) || '').trim(),
      })).filter((student) => student.name),
      createdAt: now,
      updatedAt: now,
    };

    const result = await demographyCollection.insertOne(payload);
    const saved = await demographyCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeDemographyForResponse(saved));
  } catch (error) {
    console.error('POST /api/demography failed:', error);
    return res.status(500).json({ message: 'Unable to create demography.' });
  }
});

app.put('/api/demography/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const groupId = String(body.groupId || '').trim();
    const groupName = String(body.groupName || '').trim();
    const teachers = Array.isArray(body.teachers) ? body.teachers : [];
    const otherTeachers = Array.isArray(body.otherTeachers) ? body.otherTeachers : [];
    const students = Array.isArray(body.students) ? body.students : [];

    if (!groupName) return res.status(422).json({ message: 'Group Name is required.' });
    if (students.length === 0 || !students.some((item) => String(item && item.name ? item.name : '').trim())) {
      return res.status(422).json({ message: 'At least one student is required.' });
    }

    const payload = {
      groupId: groupId || `group-${Date.now()}`,
      groupName,
      teachers: teachers.map((teacher) => ({
        name: String((teacher && teacher.name) || '').trim(),
        staffId: String((teacher && teacher.staffId) || '').trim(),
      })).filter((teacher) => teacher.name),
      otherTeachers: otherTeachers.map((teacher) => ({
        name: String((teacher && teacher.name) || '').trim(),
        staffId: String((teacher && teacher.staffId) || '').trim(),
      })).filter((teacher) => teacher.name),
      students: students.map((student) => ({
        name: String((student && student.name) || '').trim(),
        studentId: String((student && student.studentId) || '').trim(),
      })).filter((student) => student.name),
      updatedAt: new Date().toISOString(),
    };

    const result = await demographyCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: payload },
    );

    if (result.matchedCount === 0) return res.status(404).json({ message: 'Demography not found.' });
    const updated = await demographyCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeDemographyForResponse(updated));
  } catch (error) {
    console.error('PUT /api/demography/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update demography.' });
  }
});

app.delete('/api/demography/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await demographyCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Demography not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/demography/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete demography.' });
  }
});

// Library CRUD
app.get('/api/library', async (req, res) => {
  try {
    await connectMongo();
    const items = await libraryCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(items.map(sanitizeLibraryBookForResponse));
  } catch (error) {
    console.error('GET /api/library failed:', error);
    return res.status(500).json({ message: 'Unable to load library books.' });
  }
});

app.get('/api/library/:id', async (req, res) => {
  try {
    await connectMongo();
    const item = await libraryCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!item) return res.status(404).json({ message: 'Book not found.' });
    return res.json(sanitizeLibraryBookForResponse(item));
  } catch (error) {
    return res.status(404).json({ message: 'Book not found.' });
  }
});

app.post('/api/library', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const bookName = String(body.bookName || '').trim();
    const author = String(body.author || '').trim();
    const bookId = String(body.bookId || '').trim();
    const availability = body.availability === 'reserved' ? 'reserved' : 'available';
    if (!bookName || !author || !bookId) return res.status(422).json({ message: 'Book name, author, and book ID are required.' });
    const now = new Date().toISOString();
    const result = await libraryCollection.insertOne({
      bookName, author, bookId, publisher: String(body.publisher || '').trim(),
      availability, createdAt: now, updatedAt: now,
    });
    return res.status(201).json(sanitizeLibraryBookForResponse(await libraryCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST /api/library failed:', error);
    return res.status(500).json({ message: 'Unable to create the book.' });
  }
});

app.put('/api/library/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const bookName = String(body.bookName || '').trim();
    const author = String(body.author || '').trim();
    const bookId = String(body.bookId || '').trim();
    const availability = body.availability === 'reserved' ? 'reserved' : 'available';
    if (!bookName || !author || !bookId) return res.status(422).json({ message: 'Book name, author, and book ID are required.' });
    const result = await libraryCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: { bookName, author, bookId, publisher: String(body.publisher || '').trim(), availability, updatedAt: new Date().toISOString() } },
    );
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Book not found.' });
    return res.json(sanitizeLibraryBookForResponse(await libraryCollection.findOne({ _id: new ObjectId(req.params.id) })));
  } catch (error) {
    console.error('PUT /api/library/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update the book.' });
  }
});

app.delete('/api/library/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await libraryCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Book not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/library/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete the book.' });
  }
});

// Social URL management
app.get('/api/social-url/facebook', async (req, res) => {
  try {
    await connectMongo();
    const item = await socialUrlCollection.findOne({ platform: 'facebook' });
    return res.json(sanitizeSocialUrlForResponse(item) || { platform: 'facebook', url: '' });
  } catch (error) {
    console.error('GET /api/social-url/facebook failed:', error);
    return res.status(500).json({ message: 'Unable to load Facebook link.' });
  }
});

app.post('/api/social-url/facebook', async (req, res) => {
  try {
    await connectMongo();
    const url = String((req.body || {}).url || '').trim();
    let parsed;
    try { parsed = new URL(url); } catch (_) {}
    if (!parsed || !['http:', 'https:'].includes(parsed.protocol)) {
      return res.status(422).json({ message: 'Enter a valid http or https URL.' });
    }
    const now = new Date().toISOString();
    const saved = await socialUrlCollection.findOneAndUpdate(
      { platform: 'facebook' },
      { $set: { platform: 'facebook', url, updatedAt: now }, $setOnInsert: { createdAt: now } },
      { upsert: true, returnDocument: 'after' },
    );
    return res.json(sanitizeSocialUrlForResponse(saved));
  } catch (error) {
    console.error('POST /api/social-url/facebook failed:', error);
    return res.status(500).json({ message: 'Unable to save Facebook link.' });
  }
});

app.get('/api/social-url/youtube', async (req, res) => {
  try {
    await connectMongo();
    const item = await socialUrlCollection.findOne({ platform: 'youtube' });
    return res.json(sanitizeSocialUrlForResponse(item) || { platform: 'youtube', url: '' });
  } catch (error) {
    console.error('GET /api/social-url/youtube failed:', error);
    return res.status(500).json({ message: 'Unable to load YouTube link.' });
  }
});

app.post('/api/social-url/youtube', async (req, res) => {
  try {
    await connectMongo();
    const url = String((req.body || {}).url || '').trim();
    let parsed;
    try { parsed = new URL(url); } catch (_) {}
    if (!parsed || !['http:', 'https:'].includes(parsed.protocol)) {
      return res.status(422).json({ message: 'Enter a valid http or https URL.' });
    }
    const now = new Date().toISOString();
    const saved = await socialUrlCollection.findOneAndUpdate(
      { platform: 'youtube' },
      { $set: { platform: 'youtube', url, updatedAt: now }, $setOnInsert: { createdAt: now } },
      { upsert: true, returnDocument: 'after' },
    );
    return res.json(sanitizeSocialUrlForResponse(saved));
  } catch (error) {
    console.error('POST /api/social-url/youtube failed:', error);
    return res.status(500).json({ message: 'Unable to save YouTube link.' });
  }
});

app.get('/api/social-url/instagram', async (req, res) => {
  try {
    await connectMongo();
    const item = await socialUrlCollection.findOne({ platform: 'instagram' });
    return res.json(sanitizeSocialUrlForResponse(item) || { platform: 'instagram', url: '' });
  } catch (error) {
    console.error('GET /api/social-url/instagram failed:', error);
    return res.status(500).json({ message: 'Unable to load Instagram link.' });
  }
});

app.post('/api/social-url/instagram', async (req, res) => {
  try {
    await connectMongo();
    const url = String((req.body || {}).url || '').trim();
    let parsed;
    try { parsed = new URL(url); } catch (_) {}
    if (!parsed || !['http:', 'https:'].includes(parsed.protocol)) {
      return res.status(422).json({ message: 'Enter a valid http or https URL.' });
    }
    const now = new Date().toISOString();
    const saved = await socialUrlCollection.findOneAndUpdate(
      { platform: 'instagram' },
      { $set: { platform: 'instagram', url, updatedAt: now }, $setOnInsert: { createdAt: now } },
      { upsert: true, returnDocument: 'after' },
    );
    return res.json(sanitizeSocialUrlForResponse(saved));
  } catch (error) {
    console.error('POST /api/social-url/instagram failed:', error);
    return res.status(500).json({ message: 'Unable to save Instagram link.' });
  }
});

app.get('/api/social-url/whatsapp', async (req, res) => {
  try {
    await connectMongo();
    const item = await socialUrlCollection.findOne({ platform: 'whatsapp' });
    return res.json(sanitizeWhatsAppForResponse(item) || { platform: 'whatsapp', phoneNumber: '', text: '' });
  } catch (error) {
    console.error('GET /api/social-url/whatsapp failed:', error);
    return res.status(500).json({ message: 'Unable to load WhatsApp configuration.' });
  }
});

app.post('/api/social-url/whatsapp', async (req, res) => {
  try {
    await connectMongo();
    const phoneNumber = String((req.body || {}).phoneNumber || '').replace(/[^0-9]/g, '');
    const text = String((req.body || {}).text || '').trim();
    if (phoneNumber.length < 8 || phoneNumber.length > 15) return res.status(422).json({ message: 'Enter a valid international WhatsApp number.' });
    if (!text) return res.status(422).json({ message: 'Default message text is required.' });
    const now = new Date().toISOString();
    const saved = await socialUrlCollection.findOneAndUpdate(
      { platform: 'whatsapp' },
      { $set: { platform: 'whatsapp', phoneNumber, text, updatedAt: now }, $setOnInsert: { createdAt: now } },
      { upsert: true, returnDocument: 'after' },
    );
    return res.json(sanitizeWhatsAppForResponse(saved));
  } catch (error) {
    console.error('POST /api/social-url/whatsapp failed:', error);
    return res.status(500).json({ message: 'Unable to save WhatsApp configuration.' });
  }
});

// Event celebration CRUD
app.get('/api/events-celebration', async (req, res) => {
  try {
    await connectMongo();
    const schoolId = String(req.query.schoolId || 'default-school').trim() || 'default-school';
    const items = await eventCelebrationCollection
      .find({ schoolId })
      .sort({ eventDate: -1, createdAt: -1, _id: -1 })
      .toArray();
    return res.json(items.map(sanitizeEventCelebrationForResponse));
  } catch (error) {
    console.error('GET /api/events-celebration failed:', error);
    return res.status(500).json({ message: 'Unable to load events and celebrations.' });
  }
});

app.get('/api/events-celebration/:id', async (req, res) => {
  try {
    await connectMongo();
    const item = await eventCelebrationCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!item) return res.status(404).json({ message: 'Event or celebration not found.' });
    return res.json(sanitizeEventCelebrationForResponse(item));
  } catch (error) {
    console.error('GET /api/events-celebration/:id failed:', error);
    return res.status(404).json({ message: 'Event or celebration not found.' });
  }
});

app.post('/api/events-celebration', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const schoolId = String(body.schoolId || 'default-school').trim() || 'default-school';
    const heading = String(body.heading || '').trim();
    const subHeading = String(body.subHeading || '').trim();
    const content = String(body.content || '').trim();

    if (!heading || !subHeading || !content) {
      return res.status(422).json({ message: 'Heading, sub heading, and content are required.' });
    }

    const now = new Date().toISOString();
    const payload = {
      schoolId,
      heading,
      imageUrl: String(body.imageUrl || '').trim(),
      subHeading,
      content,
      eventDate: body.eventDate ? new Date(body.eventDate) : null,
      category: String(body.category || 'Event').trim() || 'Event',
      createdAt: now,
      updatedAt: now,
    };

    const result = await eventCelebrationCollection.insertOne(payload);
    const saved = await eventCelebrationCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeEventCelebrationForResponse(saved));
  } catch (error) {
    console.error('POST /api/events-celebration failed:', error);
    return res.status(500).json({ message: 'Unable to create the event.' });
  }
});

app.put('/api/events-celebration/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const schoolId = String(body.schoolId || 'default-school').trim() || 'default-school';
    const heading = String(body.heading || '').trim();
    const subHeading = String(body.subHeading || '').trim();
    const content = String(body.content || '').trim();

    if (!heading || !subHeading || !content) {
      return res.status(422).json({ message: 'Heading, sub heading, and content are required.' });
    }

    const payload = {
      schoolId,
      heading,
      imageUrl: String(body.imageUrl || '').trim(),
      subHeading,
      content,
      eventDate: body.eventDate ? new Date(body.eventDate) : null,
      category: String(body.category || 'Event').trim() || 'Event',
      updatedAt: new Date().toISOString(),
    };

    const result = await eventCelebrationCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: payload },
    );

    if (result.matchedCount === 0) return res.status(404).json({ message: 'Event not found.' });

    const updated = await eventCelebrationCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeEventCelebrationForResponse(updated));
  } catch (error) {
    console.error('PUT /api/events-celebration/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update the event.' });
  }
});

app.delete('/api/events-celebration/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await eventCelebrationCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Event not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/events-celebration/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete the event.' });
  }
});

// Group-scoped class resources CRUD
app.get('/api/class-resources/:groupId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const items = await classResourcesCollection.find({ groupId }).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(items.map(sanitizeClassResourceForResponse));
  } catch (error) {
    console.error('GET /api/class-resources/:groupId failed:', error);
    return res.status(500).json({ message: 'Unable to load class resources.' });
  }
});

app.post('/api/class-resources/:groupId', requireTeacher, upload.single('file'), async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const title = String(req.body.title || '').trim();
    const description = String(req.body.description || '').trim();
    const resourceType = String(req.body.resourceType || '').trim();
    if (!groupId || !title || !req.file) {
      return res.status(422).json({ message: 'Group, title, and file are required.' });
    }

    const savedFile = await saveFileToGridFS(req.file);
    const now = new Date().toISOString();
    const payload = {
      groupId,
      title,
      description,
      resourceType,
      fileName: req.file.originalname,
      fileUrl: `${req.protocol}://${req.get('host')}/api/images/${savedFile.id}`,
      filePath: savedFile.filename,
      fileSize: req.file.size,
      mimeType: req.file.mimetype || 'application/octet-stream',
      createdBy: req.auth.userId || '',
      createdAt: now,
      updatedAt: now,
    };
    const result = await classResourcesCollection.insertOne(payload);
    const saved = await classResourcesCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeClassResourceForResponse(saved));
  } catch (error) {
    console.error('POST /api/class-resources/:groupId failed:', error);
    return res.status(500).json({ message: 'Unable to save class resource.' });
  }
});

app.put('/api/class-resources/:groupId/:id', requireTeacher, async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const title = String(req.body.title || '').trim();
    const description = String(req.body.description || '').trim();
    const resourceType = String(req.body.resourceType || '').trim();
    const result = await classResourcesCollection.updateOne(
      { _id: new ObjectId(req.params.id), groupId },
      { $set: { title, description, resourceType, updatedAt: new Date().toISOString() } },
    );
    if (!result.matchedCount) return res.status(404).json({ message: 'Class resource not found.' });
    const saved = await classResourcesCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeClassResourceForResponse(saved));
  } catch (error) {
    console.error('PUT /api/class-resources/:groupId/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update class resource.' });
  }
});

app.delete('/api/class-resources/:groupId/:id', requireTeacher, async (req, res) => {
  try {
    await connectMongo();
    const result = await classResourcesCollection.deleteOne({
      _id: new ObjectId(req.params.id),
      groupId: (req.params.groupId || '').trim(),
    });
    if (!result.deletedCount) return res.status(404).json({ message: 'Class resource not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/class-resources/:groupId/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete class resource.' });
  }
});

// School resources CRUD
app.get('/api/school-resources', async (req, res) => {
  try {
    await connectMongo();
    const schoolId = String(req.query.schoolId || 'default-school').trim() || 'default-school';
    const items = await schoolResourcesCollection
      .find({ schoolId })
      .sort({ date: -1, createdAt: -1, _id: -1 })
      .toArray();
    return res.json(items.map(sanitizeSchoolResourceForResponse));
  } catch (error) {
    console.error('GET /api/school-resources failed:', error);
    return res.status(500).json({ message: 'Unable to load school resources.' });
  }
});

app.get('/api/school-resources/:id', async (req, res) => {
  try {
    await connectMongo();
    const item = await schoolResourcesCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!item) return res.status(404).json({ message: 'School resource not found.' });
    return res.json(sanitizeSchoolResourceForResponse(item));
  } catch (error) {
    console.error('GET /api/school-resources/:id failed:', error);
    return res.status(404).json({ message: 'School resource not found.' });
  }
});

app.post('/api/school-resources', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const schoolId = String(body.schoolId || 'default-school').trim() || 'default-school';
    const heading = String(body.heading || '').trim();
    const date = String(body.date || '').trim();
    const resourceName = String(body.resourceName || '').trim();

    if (!heading || !date || !resourceName) {
      return res.status(422).json({ message: 'Heading, date, and resource name are required.' });
    }

    const now = new Date().toISOString();
    const payload = {
      schoolId,
      heading,
      date,
      resourceName,
      imageUrl: String(body.imageUrl || '').trim(),
      createdAt: now,
      updatedAt: now,
    };

    const result = await schoolResourcesCollection.insertOne(payload);
    const saved = await schoolResourcesCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeSchoolResourceForResponse(saved));
  } catch (error) {
    console.error('POST /api/school-resources failed:', error);
    return res.status(500).json({ message: 'Unable to create the school resource.' });
  }
});

app.put('/api/school-resources/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const schoolId = String(body.schoolId || 'default-school').trim() || 'default-school';
    const heading = String(body.heading || '').trim();
    const date = String(body.date || '').trim();
    const resourceName = String(body.resourceName || '').trim();

    if (!heading || !date || !resourceName) {
      return res.status(422).json({ message: 'Heading, date, and resource name are required.' });
    }

    const payload = {
      schoolId,
      heading,
      date,
      resourceName,
      imageUrl: String(body.imageUrl || '').trim(),
      updatedAt: new Date().toISOString(),
    };

    const result = await schoolResourcesCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: payload },
    );

    if (result.matchedCount === 0) return res.status(404).json({ message: 'School resource not found.' });
    const updated = await schoolResourcesCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeSchoolResourceForResponse(updated));
  } catch (error) {
    console.error('PUT /api/school-resources/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update the school resource.' });
  }
});

app.delete('/api/school-resources/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await schoolResourcesCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'School resource not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/school-resources/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete the school resource.' });
  }
});

// Newsletter CRUD
app.get('/api/news-letter', async (req, res) => {
  try {
    await connectMongo();
    const schoolId = String(req.query.schoolId || 'default-school').trim() || 'default-school';
    const items = await newsLetterCollection
      .find({ schoolId })
      .sort({ createdAt: -1, _id: -1 })
      .toArray();
    return res.json(items.map(sanitizeNewsLetterForResponse));
  } catch (error) {
    console.error('GET /api/news-letter failed:', error);
    return res.status(500).json({ message: 'Unable to load newsletters.' });
  }
});

app.get('/api/news-letter/:id', async (req, res) => {
  try {
    await connectMongo();
    const item = await newsLetterCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!item) return res.status(404).json({ message: 'Newsletter not found.' });
    return res.json(sanitizeNewsLetterForResponse(item));
  } catch (error) {
    console.error('GET /api/news-letter/:id failed:', error);
    return res.status(404).json({ message: 'Newsletter not found.' });
  }
});

app.post('/api/news-letter', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const schoolId = String(body.schoolId || 'default-school').trim() || 'default-school';
    const heading = String(body.heading || '').trim();
    const introduction = String(body.introduction || '').trim();
    const sections = Array.isArray(body.sections) ? body.sections.map((section) => ({
      subHeading: String((section && section.subHeading) || '').trim(),
      content: String((section && section.content) || '').trim(),
    })) : [];

    if (!heading || !introduction) {
      return res.status(422).json({ message: 'Heading and introduction are required.' });
    }

    const now = new Date().toISOString();
    const payload = {
      schoolId,
      heading,
      imageUrl: String(body.imageUrl || '').trim(),
      introduction,
      sections,
      createdAt: now,
      updatedAt: now,
    };

    const result = await newsLetterCollection.insertOne(payload);
    const saved = await newsLetterCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeNewsLetterForResponse(saved));
  } catch (error) {
    console.error('POST /api/news-letter failed:', error);
    return res.status(500).json({ message: 'Unable to create the newsletter.' });
  }
});

app.put('/api/news-letter/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const schoolId = String(body.schoolId || 'default-school').trim() || 'default-school';
    const heading = String(body.heading || '').trim();
    const introduction = String(body.introduction || '').trim();
    const sections = Array.isArray(body.sections) ? body.sections.map((section) => ({
      subHeading: String((section && section.subHeading) || '').trim(),
      content: String((section && section.content) || '').trim(),
    })) : [];

    if (!heading || !introduction) {
      return res.status(422).json({ message: 'Heading and introduction are required.' });
    }

    const payload = {
      schoolId,
      heading,
      imageUrl: String(body.imageUrl || '').trim(),
      introduction,
      sections,
      updatedAt: new Date().toISOString(),
    };

    const result = await newsLetterCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: payload },
    );

    if (result.matchedCount === 0) return res.status(404).json({ message: 'Newsletter not found.' });
    const updated = await newsLetterCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeNewsLetterForResponse(updated));
  } catch (error) {
    console.error('PUT /api/news-letter/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update the newsletter.' });
  }
});

app.delete('/api/news-letter/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await newsLetterCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Newsletter not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/news-letter/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete the newsletter.' });
  }
});

app.get('/api/schoolnews', async (req, res) => {
  try {
    await connectMongo();
    const filter = String(req.query.published || '').toLowerCase() === 'true' ? { isPublished: true } : {};
    const items = await schoolNewsCollection
      .find(filter)
      .sort({ date: -1, isPublished: -1, createdAt: -1, _id: -1 })
      .toArray();
    return res.json(items.map(sanitizeSchoolNewsForResponse));
  } catch (error) {
    console.error('GET /api/schoolnews failed:', error);
    return res.status(500).json({ message: 'Unable to load school news.' });
  }
});

app.get('/api/schoolnews/:id', async (req, res) => {
  try {
    await connectMongo();
    const item = await schoolNewsCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!item) return res.status(404).json({ message: 'School news not found.' });
    return res.json(sanitizeSchoolNewsForResponse(item));
  } catch (error) {
    console.error('GET /api/schoolnews/:id failed:', error);
    return res.status(404).json({ message: 'School news not found.' });
  }
});

app.post('/api/schoolnews', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const title = String(body.title || '').trim();
    const news = String(body.news || '').trim();
    const rawDate = String(body.date || '').trim();
    const isPublished = body.isPublished === true;

    if (!title || !news || !rawDate) {
      return res.status(422).json({ message: 'Title, date, and news are required.' });
    }

    const date = new Date(rawDate);
    if (Number.isNaN(date.getTime())) {
      return res.status(422).json({ message: 'Please provide a valid date.' });
    }

    const now = new Date();
    const payload = {
      title,
      date,
      news,
      isPublished,
      createdAt: now,
      updatedAt: now,
    };

    const result = await schoolNewsCollection.insertOne(payload);
    const saved = await schoolNewsCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeSchoolNewsForResponse(saved));
  } catch (error) {
    console.error('POST /api/schoolnews failed:', error);
    return res.status(500).json({ message: 'Unable to create school news.' });
  }
});

app.put('/api/schoolnews/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const title = String(body.title || '').trim();
    const news = String(body.news || '').trim();
    const rawDate = String(body.date || '').trim();

    if (!title || !news || !rawDate) {
      return res.status(422).json({ message: 'Title, date, and news are required.' });
    }

    const date = new Date(rawDate);
    if (Number.isNaN(date.getTime())) {
      return res.status(422).json({ message: 'Please provide a valid date.' });
    }

    const payload = {
      title,
      date,
      news,
      updatedAt: new Date(),
    };

    const result = await schoolNewsCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: payload },
    );

    if (result.matchedCount === 0) return res.status(404).json({ message: 'School news not found.' });
    const updated = await schoolNewsCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeSchoolNewsForResponse(updated));
  } catch (error) {
    console.error('PUT /api/schoolnews/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update school news.' });
  }
});

app.patch('/api/schoolnews/:id/publish', async (req, res) => {
  try {
    await connectMongo();
    const isPublished = req.body && req.body.isPublished === true;
    const result = await schoolNewsCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: { isPublished, updatedAt: new Date() } },
    );

    if (result.matchedCount === 0) return res.status(404).json({ message: 'School news not found.' });
    const updated = await schoolNewsCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeSchoolNewsForResponse(updated));
  } catch (error) {
    console.error('PATCH /api/schoolnews/:id/publish failed:', error);
    return res.status(400).json({ message: 'Unable to update publish status.' });
  }
});

app.delete('/api/schoolnews/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await schoolNewsCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'School news not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/schoolnews/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete school news.' });
  }
});

// Announcement CRUD
app.get('/api/announcement', async (req, res) => {
  try {
    await connectMongo();
    const items = await announcementCollection
      .find({})
      .sort({ createdAt: -1, _id: -1 })
      .toArray();
    return res.json(items.map(sanitizeAnnouncementForResponse));
  } catch (error) {
    console.error('GET /api/announcement failed:', error);
    return res.status(500).json({ message: 'Unable to load announcements.' });
  }
});

app.get('/api/announcement/:id', async (req, res) => {
  try {
    await connectMongo();
    const item = await announcementCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!item) return res.status(404).json({ message: 'Announcement not found.' });
    return res.json(sanitizeAnnouncementForResponse(item));
  } catch (error) {
    console.error('GET /api/announcement/:id failed:', error);
    return res.status(404).json({ message: 'Announcement not found.' });
  }
});

app.get('/api/medical-events', async (req, res) => {
  try {
    await connectMongo();
    const items = await medicalEventCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json({ success: true, data: items.map(sanitizeMedicalEventForResponse) });
  } catch (error) {
    console.error('GET /api/medical-events failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to load medical events.' });
  }
});

app.get('/api/medical-events/:id', async (req, res) => {
  try {
    await connectMongo();
    const item = await medicalEventCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!item) return res.status(404).json({ success: false, message: 'Medical event not found.' });
    return res.json({ success: true, data: sanitizeMedicalEventForResponse(item) });
  } catch (error) {
    console.error('GET /api/medical-events/:id failed:', error);
    return res.status(404).json({ success: false, message: 'Medical event not found.' });
  }
});

app.post('/api/medical-events', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const observations = body.firstObservations || {};
    const payload = {
      studentId: String(body.studentId || '').trim(),
      studentName: String(body.studentName || '').trim(),
      className: String(body.className || '').trim(),
      description: String(body.description || '').trim(),
      firstObservations: {
        symptomReported: String(observations.symptomReported || body.symptomReported || '').trim(),
        specialNeedsKnown: String(observations.specialNeedsKnown || body.specialNeedsKnown || '').trim(),
      },
      reportImage: String(body.reportImage || '').trim(),
      reportedBy: body.reportedBy || {},
      lastModifiedBy: body.lastModifiedBy || {},
      createdAt: new Date(),
      updatedAt: new Date(),
      lastModifiedAt: new Date(),
    };
    if (!payload.studentId || !payload.studentName || !payload.className || !payload.description || !payload.firstObservations.symptomReported || !String(payload.reportedBy.userId || payload.reportedBy.name || '').trim()) {
      return res.status(422).json({ success: false, message: 'Student, class, description, symptom, and reported by are required.' });
    }
    const result = await medicalEventCollection.insertOne(payload);
    const saved = await medicalEventCollection.findOne({ _id: result.insertedId });
    return res.status(201).json({ success: true, message: 'Medical event saved successfully', data: sanitizeMedicalEventForResponse(saved) });
  } catch (error) {
    console.error('POST /api/medical-events failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to save medical event.' });
  }
});

app.put('/api/medical-events/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const observations = body.firstObservations || {};
    const payload = {
      studentId: String(body.studentId || '').trim(),
      studentName: String(body.studentName || '').trim(),
      className: String(body.className || '').trim(),
      description: String(body.description || '').trim(),
      firstObservations: {
        symptomReported: String(observations.symptomReported || body.symptomReported || '').trim(),
        specialNeedsKnown: String(observations.specialNeedsKnown || body.specialNeedsKnown || '').trim(),
      },
      reportImage: String(body.reportImage || '').trim(),
      reportedBy: body.reportedBy || {},
      lastModifiedBy: body.lastModifiedBy || {},
      updatedAt: new Date(),
      lastModifiedAt: new Date(),
    };
    if (!payload.studentId || !payload.studentName || !payload.className || !payload.description || !payload.firstObservations.symptomReported || !String(payload.reportedBy.userId || payload.reportedBy.name || '').trim()) {
      return res.status(422).json({ success: false, message: 'Student, class, description, symptom, and reported by are required.' });
    }
    const result = await medicalEventCollection.updateOne({ _id: new ObjectId(req.params.id) }, { $set: payload });
    if (result.matchedCount === 0) return res.status(404).json({ success: false, message: 'Medical event not found.' });
    const updated = await medicalEventCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json({ success: true, message: 'Medical event updated successfully', data: sanitizeMedicalEventForResponse(updated) });
  } catch (error) {
    console.error('PUT /api/medical-events/:id failed:', error);
    return res.status(400).json({ success: false, message: 'Unable to update medical event.' });
  }
});

app.delete('/api/medical-events/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await medicalEventCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ success: false, message: 'Medical event not found.' });
    return res.json({ success: true, message: 'Medical event deleted successfully' });
  } catch (error) {
    console.error('DELETE /api/medical-events/:id failed:', error);
    return res.status(400).json({ success: false, message: 'Unable to delete medical event.' });
  }
});

app.post('/api/announcement', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const subject = String(body.subject || '').trim();
    const fromName = String(body.from || body.fromName || '').trim();
    const to = Array.isArray(body.to) ? body.to.map((value) => String(value).trim()).filter(Boolean) : [];
    const createdOn = String(body.createdOn || '').trim();
    const content = String(body.content || '').trim();

    if (!subject || !fromName || !createdOn || !content || to.length === 0) {
      return res.status(422).json({ message: 'Subject, from, to, createdOn, and content are required.' });
    }

    const now = new Date().toISOString();
    const payload = {
      subject,
      from: fromName,
      to,
      createdOn,
      content,
      likes: [],
      comments: [],
      reminders: [],
      createdAt: now,
      updatedAt: now,
    };

    app.get('/api/medical-events', async (req, res) => {
      try {
        await connectMongo();
        const items = await medicalEventCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
        return res.json({ success: true, data: items.map(sanitizeMedicalEventForResponse) });
      } catch (error) {
        console.error('GET /api/medical-events failed:', error);
        return res.status(500).json({ success: false, message: 'Unable to load medical events.' });
      }
    });

    app.get('/api/medical-events/:id', async (req, res) => {
      try {
        await connectMongo();
        const item = await medicalEventCollection.findOne({ _id: new ObjectId(req.params.id) });
        if (!item) return res.status(404).json({ success: false, message: 'Medical event not found.' });
        return res.json({ success: true, data: sanitizeMedicalEventForResponse(item) });
      } catch (error) {
        console.error('GET /api/medical-events/:id failed:', error);
        return res.status(404).json({ success: false, message: 'Medical event not found.' });
      }
    });

    app.post('/api/medical-events', async (req, res) => {
      try {
        await connectMongo();
        const body = req.body || {};
        const observations = body.firstObservations || {};
        const required = {
          studentId: String(body.studentId || '').trim(),
          studentName: String(body.studentName || '').trim(),
          className: String(body.className || '').trim(),
          description: String(body.description || '').trim(),
          symptomReported: String(observations.symptomReported || body.symptomReported || '').trim(),
          reportedBy: body.reportedBy || {},
          lastModifiedBy: body.lastModifiedBy || {},
        };
        if (!required.studentId || !required.studentName || !required.className || !required.description ||
            !required.symptomReported || !String(required.reportedBy.userId || required.reportedBy.name || '').trim()) {
          return res.status(422).json({ success: false, message: 'Student, class, description, symptom, and reported by are required.' });
        }
        const now = new Date();
        const payload = {
          studentId: required.studentId,
          studentName: required.studentName,
          className: required.className,
          description: required.description,
          firstObservations: {
            symptomReported: required.symptomReported,
            specialNeedsKnown: String(observations.specialNeedsKnown || body.specialNeedsKnown || '').trim(),
          },
          reportImage: String(body.reportImage || '').trim(),
          reportedBy: required.reportedBy,
          lastModifiedBy: required.lastModifiedBy,
          createdAt: now,
          updatedAt: now,
          lastModifiedAt: now,
        };
        const result = await medicalEventCollection.insertOne(payload);
        const saved = await medicalEventCollection.findOne({ _id: result.insertedId });
        return res.status(201).json({ success: true, message: 'Medical event saved successfully', data: sanitizeMedicalEventForResponse(saved) });
      } catch (error) {
        console.error('POST /api/medical-events failed:', error);
        return res.status(500).json({ success: false, message: 'Unable to save medical event.' });
      }
    });

    app.put('/api/medical-events/:id', async (req, res) => {
      try {
        await connectMongo();
        const body = req.body || {};
        const observations = body.firstObservations || {};
        const payload = {
          studentId: String(body.studentId || '').trim(),
          studentName: String(body.studentName || '').trim(),
          className: String(body.className || '').trim(),
          description: String(body.description || '').trim(),
          firstObservations: {
            symptomReported: String(observations.symptomReported || body.symptomReported || '').trim(),
            specialNeedsKnown: String(observations.specialNeedsKnown || body.specialNeedsKnown || '').trim(),
          },
          reportImage: String(body.reportImage || '').trim(),
          reportedBy: body.reportedBy || {},
          lastModifiedBy: body.lastModifiedBy || {},
          updatedAt: new Date(),
          lastModifiedAt: new Date(),
        };
        if (!payload.studentId || !payload.studentName || !payload.className || !payload.description ||
            !payload.firstObservations.symptomReported || !String(payload.reportedBy.userId || payload.reportedBy.name || '').trim()) {
          return res.status(422).json({ success: false, message: 'Student, class, description, symptom, and reported by are required.' });
        }
        const result = await medicalEventCollection.updateOne({ _id: new ObjectId(req.params.id) }, { $set: payload });
        if (result.matchedCount === 0) return res.status(404).json({ success: false, message: 'Medical event not found.' });
        const updated = await medicalEventCollection.findOne({ _id: new ObjectId(req.params.id) });
        return res.json({ success: true, message: 'Medical event updated successfully', data: sanitizeMedicalEventForResponse(updated) });
      } catch (error) {
        console.error('PUT /api/medical-events/:id failed:', error);
        return res.status(400).json({ success: false, message: 'Unable to update medical event.' });
      }
    });

    app.delete('/api/medical-events/:id', async (req, res) => {
      try {
        await connectMongo();
        const result = await medicalEventCollection.deleteOne({ _id: new ObjectId(req.params.id) });
        if (result.deletedCount === 0) return res.status(404).json({ success: false, message: 'Medical event not found.' });
        return res.json({ success: true, message: 'Medical event deleted successfully' });
      } catch (error) {
        console.error('DELETE /api/medical-events/:id failed:', error);
        return res.status(400).json({ success: false, message: 'Unable to delete medical event.' });
      }
    });

    const result = await announcementCollection.insertOne(payload);
    const saved = await announcementCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeAnnouncementForResponse(saved));
  } catch (error) {
    console.error('POST /api/announcement failed:', error);
    return res.status(500).json({ message: 'Unable to create the announcement.' });
  }
});

app.put('/api/announcement/:id', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const subject = String(body.subject || '').trim();
    const fromName = String(body.from || body.fromName || '').trim();
    const to = Array.isArray(body.to) ? body.to.map((value) => String(value).trim()).filter(Boolean) : [];
    const createdOn = String(body.createdOn || '').trim();
    const content = String(body.content || '').trim();

    if (!subject || !fromName || !createdOn || !content || to.length === 0) {
      return res.status(422).json({ message: 'Subject, from, to, createdOn, and content are required.' });
    }

    const payload = {
      subject,
      from: fromName,
      to,
      createdOn,
      content,
      updatedAt: new Date().toISOString(),
    };

    const result = await announcementCollection.updateOne(
      { _id: new ObjectId(req.params.id) },
      { $set: payload },
    );

    if (result.matchedCount === 0) return res.status(404).json({ message: 'Announcement not found.' });
    const updated = await announcementCollection.findOne({ _id: new ObjectId(req.params.id) });
    return res.json(sanitizeAnnouncementForResponse(updated));
  } catch (error) {
    console.error('PUT /api/announcement/:id failed:', error);
    return res.status(400).json({ message: 'Unable to update the announcement.' });
  }
});

app.delete('/api/announcement/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await announcementCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Announcement not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/announcement/:id failed:', error);
    return res.status(400).json({ message: 'Unable to delete the announcement.' });
  }
});

app.post('/api/announcement/:id/like', async (req, res) => {
  try {
    await connectMongo();
    const announcementId = req.params.id;
    const userId = String(req.body.userId || '').trim();
    if (!userId) return res.status(422).json({ message: 'userId is required.' });

    const item = await announcementCollection.findOne({ _id: new ObjectId(announcementId) });
    if (!item) return res.status(404).json({ message: 'Announcement not found.' });

    const likes = Array.isArray(item.likes) ? item.likes.map((value) => String(value)) : [];
    const alreadyLiked = likes.includes(userId);
    const nextLikes = alreadyLiked ? likes.filter((value) => value !== userId) : [...new Set([...likes, userId])];

    await announcementCollection.updateOne(
      { _id: new ObjectId(announcementId) },
      { $set: { likes: nextLikes, updatedAt: new Date().toISOString() } },
    );

    return res.json({ liked: !alreadyLiked, likeCount: nextLikes.length, likes: nextLikes });
  } catch (error) {
    console.error('POST /api/announcement/:id/like failed:', error);
    return res.status(500).json({ message: 'Unable to update like.' });
  }
});

app.post('/api/announcement/:id/comments', async (req, res) => {
  try {
    await connectMongo();
    const announcementId = req.params.id;
    const userId = String(req.body.userId || '').trim();
    const userName = String(req.body.userName || '').trim() || 'Student';
    const text = String(req.body.text || req.body.comment || '').trim();

    if (!userId || !text) return res.status(422).json({ message: 'userId and comment text are required.' });

    const item = await announcementCollection.findOne({ _id: new ObjectId(announcementId) });
    if (!item) return res.status(404).json({ message: 'Announcement not found.' });

    const comments = Array.isArray(item.comments) ? item.comments : [];
    const nextComment = {
      id: new ObjectId().toString(),
      name: userName,
      text,
      createdAt: new Date().toISOString(),
    };

    comments.push(nextComment);
    await announcementCollection.updateOne(
      { _id: new ObjectId(announcementId) },
      { $set: { comments, updatedAt: new Date().toISOString() } },
    );

    return res.status(201).json({ id: nextComment.id, userName: nextComment.name, text: nextComment.text, createdAt: nextComment.createdAt });
  } catch (error) {
    console.error('POST /api/announcement/:id/comments failed:', error);
    return res.status(500).json({ message: 'Unable to add comment.' });
  }
});

app.post('/api/announcement/:id/remind', async (req, res) => {
  try {
    await connectMongo();
    const announcementId = req.params.id;
    const userId = String(req.body.userId || '').trim();
    if (!userId) return res.status(422).json({ message: 'userId is required.' });

    const item = await announcementCollection.findOne({ _id: new ObjectId(announcementId) });
    if (!item) return res.status(404).json({ message: 'Announcement not found.' });

    const reminders = Array.isArray(item.reminders) ? item.reminders.map((value) => String(value)) : [];
    const nextReminders = reminders.includes(userId) ? reminders : [...new Set([...reminders, userId])];
    await announcementCollection.updateOne(
      { _id: new ObjectId(announcementId) },
      { $set: { reminders: nextReminders, updatedAt: new Date().toISOString() } },
    );

    return res.json({ reminded: true, reminders: nextReminders });
  } catch (error) {
    console.error('POST /api/announcement/:id/remind failed:', error);
    return res.status(500).json({ message: 'Unable to save reminder.' });
  }
});

// One-on-one meetings CRUD
function oneOnOneMeetingPayload(body) {
  const staffId = String(body.staffId || '').trim();
  const staffName = String(body.staffName || '').trim();
  const meetingTime = String(body.meetingTime || '').trim();
  const meetingInfo = String(body.meetingInfo || '').trim();
  const meetingUrl = String(body.meetingUrl || '').trim();
  const startDateTime = new Date(body.startDateTime);
  const endDateTime = new Date(body.endDateTime);
  if (!staffId || !staffName || !meetingTime || !meetingInfo) {
    return { error: 'Staff, meeting time, meeting info, start date/time, and end date/time are required.' };
  }
  if (Number.isNaN(startDateTime.getTime()) || Number.isNaN(endDateTime.getTime())) {
    return { error: 'Please provide valid meeting dates.' };
  }
  if (endDateTime <= startDateTime) return { error: 'End date/time must be later than start date/time.' };
  if (meetingUrl && !/^https?:\/\//i.test(meetingUrl)) return { error: 'Meeting URL must be a valid HTTP or HTTPS URL.' };
  return { values: { staffId, staffName, startDateTime, endDateTime, meetingTime, meetingInfo, meetingUrl } };
}

function meetingObjectId(id) {
  return ObjectId.isValid(id) ? new ObjectId(id) : null;
}

app.get('/api/one-on-one-meetings', async (req, res) => {
  try {
    await connectMongo();
    const meetings = await oneOnOneMeetingsCollection.find({}).sort({ startDateTime: -1, _id: -1 }).toArray();
    return res.json(meetings.map(sanitizeOneOnOneMeetingForResponse));
  } catch (error) {
    console.error('GET /api/one-on-one-meetings failed:', error);
    return res.status(500).json({ message: 'Unable to load meetings.' });
  }
});

app.get('/api/one-on-one-meetings/my-meetings', requireRecipientRole('staff'), async (req, res) => {
  try {
    await connectMongo();
    const staffId = String(req.auth.userId || '').trim();
    const meetings = await oneOnOneMeetingsCollection
      .find({ staffId })
      .sort({ startDateTime: -1, _id: -1 })
      .toArray();
    return res.json({ data: meetings.map(sanitizeOneOnOneMeetingForResponse) });
  } catch (error) {
    console.error('GET /api/one-on-one-meetings/my-meetings failed:', error);
    return res.status(500).json({ message: 'Unable to load your meeting information.' });
  }
});

app.get('/api/one-on-one-meetings/staff/:staffId', async (req, res) => {
  try {
    await connectMongo();
    const staffId = String(req.params.staffId || '').trim();
    if (!staffId) return res.status(400).json({ message: 'Staff ID is required.' });
    const meetings = await oneOnOneMeetingsCollection.find({ staffId }).sort({ startDateTime: -1, _id: -1 }).toArray();
    return res.json({ data: meetings.map(sanitizeOneOnOneMeetingForResponse) });
  } catch (error) {
    console.error('GET /api/one-on-one-meetings/staff/:staffId failed:', error);
    return res.status(500).json({ message: 'Unable to load staff meeting history.' });
  }
});

app.get('/api/one-on-one-meetings/:id', async (req, res) => {
  try {
    const id = meetingObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid meeting ID.' });
    await connectMongo();
    const meeting = await oneOnOneMeetingsCollection.findOne({ _id: id });
    if (!meeting) return res.status(404).json({ message: 'Meeting not found.' });
    return res.json(sanitizeOneOnOneMeetingForResponse(meeting));
  } catch (error) {
    console.error('GET /api/one-on-one-meetings/:id failed:', error);
    return res.status(500).json({ message: 'Unable to load the meeting.' });
  }
});

app.post('/api/one-on-one-meetings', async (req, res) => {
  try {
    const { values, error } = oneOnOneMeetingPayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const staff = await employeeInfoCollection.findOne({ employeeId: values.staffId });
    if (!staff) return res.status(422).json({ message: 'The selected staff member no longer exists.' });
    const now = new Date();
    const result = await oneOnOneMeetingsCollection.insertOne({ ...values, staffName: staff.name, createdAt: now, updatedAt: now });
    return res.status(201).json(sanitizeOneOnOneMeetingForResponse(await oneOnOneMeetingsCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST /api/one-on-one-meetings failed:', error);
    return res.status(500).json({ message: 'Unable to create the meeting.' });
  }
});

app.put('/api/one-on-one-meetings/:id', async (req, res) => {
  try {
    const id = meetingObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid meeting ID.' });
    const { values, error } = oneOnOneMeetingPayload(req.body || {});
    if (error) return res.status(422).json({ message: error });
    await connectMongo();
    const staff = await employeeInfoCollection.findOne({ employeeId: values.staffId });
    if (!staff) return res.status(422).json({ message: 'The selected staff member no longer exists.' });
    const result = await oneOnOneMeetingsCollection.updateOne({ _id: id }, { $set: { ...values, staffName: staff.name, updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Meeting not found.' });
    return res.json(sanitizeOneOnOneMeetingForResponse(await oneOnOneMeetingsCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PUT /api/one-on-one-meetings/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update the meeting.' });
  }
});

app.delete('/api/one-on-one-meetings/:id', async (req, res) => {
  try {
    const id = meetingObjectId(req.params.id);
    if (!id) return res.status(400).json({ message: 'Invalid meeting ID.' });
    await connectMongo();
    const result = await oneOnOneMeetingsCollection.deleteOne({ _id: id });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Meeting not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/one-on-one-meetings/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete the meeting.' });
  }
});

// Staff information CRUD
app.post('/api/emp-leave', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const required = ['staffId', 'leaveType', 'applicableYear', 'startDate', 'endDate', 'reason'];
    const missing = required.find((key) => !String(body[key] || '').trim());
    if (missing) return res.status(422).json({ message: `${missing} is required.` });
    const startDate = new Date(body.startDate);
    const endDate = new Date(body.endDate);
    const effectiveDays = Number(body.effectiveDays);
    if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime()) || endDate < startDate || !Number.isFinite(effectiveDays) || effectiveDays <= 0) {
      return res.status(422).json({ message: 'Please provide valid leave dates and effective days.' });
    }
    const now = new Date();
    const document = {
      staffId: String(body.staffId).trim(),
      staffName: String(body.staffName || '').trim(),
      leaveType: String(body.leaveType).trim(),
      applicableYear: Number(body.applicableYear),
      startDate,
      endDate,
      beginHalfDay: body.beginHalfDay === true,
      endHalfDay: body.endHalfDay === true,
      effectiveDays,
      reason: String(body.reason).trim(),
      status: 'Pending',
      createdAt: now,
      updatedAt: now,
    };
    const result = await staffLeaveCollection.insertOne(document);
    return res.status(201).json({ success: true, message: 'Leave request submitted successfully', data: sanitizeStaffLeaveForResponse(await staffLeaveCollection.findOne({ _id: result.insertedId })) });
  } catch (error) {
    console.error('POST /api/emp-leave failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to submit leave request.' });
  }
});

app.get('/api/emp-leave/:staffId/entitlements', async (req, res) => {
  try {
    await connectMongo();
    const year = Number(req.query.year);
    const filter = { staffId: String(req.params.staffId) };
    if (Number.isFinite(year) && year > 0) filter.year = year;
    const items = await staffLeaveEntitlementsCollection.find(filter).sort({ year: -1, leaveType: 1 }).toArray();
    return res.json({ success: true, data: items.map(sanitizeStaffLeaveEntitlementForResponse) });
  } catch (error) {
    console.error('GET staff leave entitlements failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to load leave entitlements.' });
  }
});

app.get('/api/emp-leave/employee/:staffId', async (req, res) => {
  try {
    await connectMongo();
    const items = await staffLeaveCollection.find({ staffId: String(req.params.staffId) }).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json({ success: true, data: items.map(sanitizeStaffLeaveForResponse) });
  } catch (error) {
    console.error('GET /api/emp-leave/employee/:staffId failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to load leave requests.' });
  }
});

app.post('/api/emp-leave/adjust', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const staffId = String(body.staffId || '').trim();
    const leaveType = String(body.leaveType || '').trim();
    const year = Number(body.year);
    const days = Number(body.days);
    if (!staffId || !leaveType || !Number.isFinite(year) || !Number.isFinite(days) || days <= 0) return res.status(422).json({ message: 'Staff, leave type, year, and positive days are required.' });
    const updated = await staffLeaveEntitlementsCollection.findOneAndUpdate(
      { staffId, leaveType, year },
      { $inc: { adjustment: days }, $set: { updatedAt: new Date() }, $setOnInsert: { totalLeaves: 0, leaveTaken: 0 } },
      { upsert: true, returnDocument: 'after' },
    );
    return res.json({ success: true, message: 'Leave adjusted successfully', data: sanitizeStaffLeaveEntitlementForResponse(updated) });
  } catch (error) {
    console.error('POST /api/staff-leave/adjust failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to adjust leave.' });
  }
});

app.put('/api/emp-leave/:id/cancel', async (req, res) => {
  try {
    await connectMongo();
    const result = await staffLeaveCollection.updateOne({ _id: new ObjectId(req.params.id), status: 'Pending' }, { $set: { status: 'Cancelled', updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Pending leave request not found.' });
    return res.json({ success: true, message: 'Leave request cancelled successfully' });
  } catch (error) {
    console.error('PUT /api/staff-leave/:id/cancel failed:', error);
    return res.status(400).json({ message: 'Unable to cancel leave request.' });
  }
});

app.get('/api/emp-leave', async (req, res) => {
  try {
    await connectMongo();
    const items = await staffLeaveCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json({ success: true, data: items.map(sanitizeStaffLeaveForResponse) });
  } catch (error) {
    console.error('GET /api/emp-leave failed:', error);
    return res.status(500).json({ success: false, message: 'Unable to load leave requests.' });
  }
});

app.get('/api/emp-leave/history', async (req, res) => {
  try {
    await connectMongo();
    const items = await staffLeaveCollection.find({ status: { $in: ['Approved', 'Rejected'] } }).sort({ updatedAt: -1, _id: -1 }).toArray();
    return res.json({ success: true, data: items.map(sanitizeStaffLeaveForResponse) });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Unable to load leave history.' });
  }
});

app.put('/api/emp-leave/:id/approve', async (req, res) => {
  try {
    await connectMongo();
    const result = await staffLeaveCollection.updateOne({ _id: new ObjectId(req.params.id), status: 'Pending' }, { $set: { status: 'Approved', approvedBy: req.body?.approvedBy || null, approvedOn: new Date(), updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ success: false, message: 'Pending leave request not found.' });
    return res.json({ success: true, message: 'Leave approved successfully', data: sanitizeStaffLeaveForResponse(await staffLeaveCollection.findOne({ _id: new ObjectId(req.params.id) })) });
  } catch (error) { return res.status(400).json({ success: false, message: 'Unable to approve leave request.' }); }
});

app.put('/api/emp-leave/:id/reject', async (req, res) => {
  try {
    await connectMongo();
    const result = await staffLeaveCollection.updateOne({ _id: new ObjectId(req.params.id), status: 'Pending' }, { $set: { status: 'Rejected', rejectedBy: req.body?.rejectedBy || null, rejectedOn: new Date(), rejectionReason: String(req.body?.reason || '').trim(), updatedAt: new Date() } });
    if (result.matchedCount === 0) return res.status(404).json({ success: false, message: 'Pending leave request not found.' });
    return res.json({ success: true, message: 'Leave rejected successfully', data: sanitizeStaffLeaveForResponse(await staffLeaveCollection.findOne({ _id: new ObjectId(req.params.id) })) });
  } catch (error) { return res.status(400).json({ success: false, message: 'Unable to reject leave request.' }); }
});

function isHttpUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === 'http:' || url.protocol === 'https:';
  } catch (_) {
    return false;
  }
}

function staffResourcePayload(body) {
  return {
    staffId: String(body.staffId || '').trim(),
    description: String(body.description || '').trim(),
    link: String(body.link || '').trim(),
    slipReportImageUrl: String(body.slipReportImageUrl || '').trim(),
  };
}

async function findStaffResourceStaff(staffId) {
  const normalizedId = String(staffId || '').trim();
  if (!normalizedId) return null;
  return employeeInfoCollection.findOne({
    $or: [{ employeeId: normalizedId }, { staffId: normalizedId }],
  });
}

app.get('/api/staff-resources/my-resources', requireRecipientRole('staff'), async (req, res) => {
  try {
    await connectMongo();
    const staffId = String(req.auth.userId || '').trim();
    const resources = await staffResourcesCollection.find({ staffId }).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(resources.map(sanitizeStaffResourceForResponse));
  } catch (error) {
    console.error('GET /api/staff-resources/my-resources failed:', error);
    return res.status(500).json({ message: 'Unable to load your staff resources.' });
  }
});

app.get('/api/staff-resources', requireAdmin, async (req, res) => {
  try {
    await connectMongo();
    const filter = String(req.query.staffId || '').trim();
    const resources = await staffResourcesCollection.find(filter ? { staffId: filter } : {}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(resources.map(sanitizeStaffResourceForResponse));
  } catch (error) {
    console.error('GET /api/staff-resources failed:', error);
    return res.status(500).json({ message: 'Unable to load staff resources.' });
  }
});

app.get('/api/staff-resources/:id', requireAdmin, async (req, res) => {
  try {
    await connectMongo();
    if (!ObjectId.isValid(req.params.id)) return res.status(404).json({ message: 'Staff resource not found.' });
    const resource = await staffResourcesCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!resource) return res.status(404).json({ message: 'Staff resource not found.' });
    return res.json(sanitizeStaffResourceForResponse(resource));
  } catch (error) {
    return res.status(404).json({ message: 'Staff resource not found.' });
  }
});

app.post('/api/staff-resources', requireAdmin, async (req, res) => {
  try {
    await connectMongo();
    const payload = staffResourcePayload(req.body || {});
    if (!payload.staffId) return res.status(422).json({ message: 'Staff name is required.' });
    if (!payload.description) return res.status(422).json({ message: 'Description is required.' });
    if (payload.link && !isHttpUrl(payload.link)) return res.status(422).json({ message: 'Enter a valid resource URL.' });
    const staff = await findStaffResourceStaff(payload.staffId);
    if (!staff) return res.status(422).json({ message: 'Selected staff member was not found.' });
    const now = new Date().toISOString();
    const document = { ...payload, staffId: staff.employeeId || payload.staffId, staffName: staff.name || '', createdAt: now, updatedAt: now };
    const result = await staffResourcesCollection.insertOne(document);
    return res.status(201).json(sanitizeStaffResourceForResponse(await staffResourcesCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST /api/staff-resources failed:', error);
    return res.status(500).json({ message: 'Unable to save staff resource.' });
  }
});

app.put('/api/staff-resources/:id', requireAdmin, async (req, res) => {
  try {
    await connectMongo();
    if (!ObjectId.isValid(req.params.id)) return res.status(404).json({ message: 'Staff resource not found.' });
    const payload = staffResourcePayload(req.body || {});
    if (!payload.staffId) return res.status(422).json({ message: 'Staff name is required.' });
    if (!payload.description) return res.status(422).json({ message: 'Description is required.' });
    if (payload.link && !isHttpUrl(payload.link)) return res.status(422).json({ message: 'Enter a valid resource URL.' });
    const staff = await findStaffResourceStaff(payload.staffId);
    if (!staff) return res.status(422).json({ message: 'Selected staff member was not found.' });
    const updates = { ...payload, staffId: staff.employeeId || payload.staffId, staffName: staff.name || '', updatedAt: new Date().toISOString() };
    const result = await staffResourcesCollection.updateOne({ _id: new ObjectId(req.params.id) }, { $set: updates });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Staff resource not found.' });
    return res.json(sanitizeStaffResourceForResponse(await staffResourcesCollection.findOne({ _id: new ObjectId(req.params.id) })));
  } catch (error) {
    console.error('PUT /api/staff-resources/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update staff resource.' });
  }
});

app.delete('/api/staff-resources/:id', requireAdmin, async (req, res) => {
  try {
    await connectMongo();
    if (!ObjectId.isValid(req.params.id)) return res.status(404).json({ message: 'Staff resource not found.' });
    const result = await staffResourcesCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Staff resource not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/staff-resources/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete staff resource.' });
  }
});

app.get('/api/staff', async (req, res) => {
  try {
    await connectMongo();
    const staff = await employeeInfoCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(staff.map(sanitizeStaffForResponse));
  } catch (error) {
    console.error('GET /api/staff failed:', error);
    return res.status(500).json({ message: 'Unable to load staff information.' });
  }
});

app.get('/api/staff/profile', requireRecipientRole('staff'), async (req, res) => {
  try {
    await connectMongo();
    const staff = await employeeInfoCollection.findOne({
      $or: [
        { employeeId: String(req.auth.userId || '').trim() },
        { staffId: String(req.auth.userId || '').trim() },
      ],
    });
    if (!staff) return res.status(404).json({ message: 'Staff profile not found.' });
    return res.json(sanitizeStaffForResponse(staff));
  } catch (error) {
    console.error('GET /api/staff/profile failed:', error);
    return res.status(500).json({ message: 'Unable to load the staff profile.' });
  }
});

app.get('/api/staff/:id', async (req, res) => {
  try {
    await connectMongo();
    const staff = await employeeInfoCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!staff) return res.status(404).json({ message: 'Staff member not found.' });
    return res.json(sanitizeStaffForResponse(staff));
  } catch (error) {
    console.error('GET /api/staff/:id failed:', error);
    return res.status(404).json({ message: 'Staff member not found.' });
  }
});

app.post('/api/staff', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const required = ['name', 'designation', 'employeeCategory', 'employeeId', 'teaches', 'role'];
    const missing = required.find((field) => !String(body[field] || '').trim());
    if (missing) return res.status(422).json({ message: `${missing} is required.` });
    const employeeId = String(body.employeeId).trim();
    const staffUser = await usersCollection.findOne({ userId: employeeId, role: 'staff' });
    if (!staffUser) return res.status(422).json({ message: 'Employee ID must belong to a staff user.' });
    const existingStaff = await employeeInfoCollection.findOne({ employeeId });
    if (existingStaff) return res.status(409).json({ message: 'This Employee ID is already assigned.' });

    const now = new Date().toISOString();
    const document = {
      name: String(body.name).trim(),
      designation: String(body.designation).trim(),
      employeeCategory: String(body.employeeCategory).trim(),
      employeeId,
      teaches: String(body.teaches).trim(),
      about: String(body.about || '').trim(),
      hobbiesAndInterest: String(body.hobbiesAndInterest || '').trim(),
      role: String(body.role).trim(),
      imageUrl: String(body.imageUrl || '').trim(),
      mobileNo: String(body.mobileNo || '').trim(),
      shareableContactNo: String(body.shareableContactNo || '').trim(),
      mailId: String(body.mailId || '').trim(),
      address: String(body.address || '').trim(),
      briefIntroduction: String(body.briefIntroduction || '').trim(),
      sports: String(body.sports || '').trim(),
      sportsTrainingDetails: String(body.sportsTrainingDetails || '').trim(),
      sportsTeamClub: String(body.sportsTeamClub || '').trim(),
      achievements: String(body.achievements || '').trim(),
      extraCurricularActivities: String(body.extraCurricularActivities || '').trim(),
      extraCurricularTeamClub: String(body.extraCurricularTeamClub || '').trim(),
      professionalBodyAssociation: String(body.professionalBodyAssociation || '').trim(),
      whatYouDo: String(body.whatYouDo || '').trim(),
      createdAt: now,
      updatedAt: now,
    };
    const result = await employeeInfoCollection.insertOne(document);
    return res.status(201).json(sanitizeStaffForResponse(await employeeInfoCollection.findOne({ _id: result.insertedId })));
  } catch (error) {
    console.error('POST /api/staff failed:', error);
    return res.status(500).json({ message: 'Unable to save staff information.' });
  }
});

app.put('/api/staff/:id', async (req, res) => {
  try {
    await connectMongo();
    const id = new ObjectId(req.params.id);
    const body = req.body || {};
    const required = ['name', 'designation', 'employeeCategory', 'employeeId', 'teaches', 'role'];
    const missing = required.find((field) => !String(body[field] || '').trim());
    if (missing) return res.status(422).json({ message: `${missing} is required.` });
    const employeeId = String(body.employeeId).trim();
    const staffUser = await usersCollection.findOne({ userId: employeeId, role: 'staff' });
    if (!staffUser) return res.status(422).json({ message: 'Employee ID must belong to a staff user.' });
    const existingStaff = await employeeInfoCollection.findOne({ employeeId, _id: { $ne: id } });
    if (existingStaff) return res.status(409).json({ message: 'This Employee ID is already assigned.' });
    const updates = {
      name: String(body.name).trim(),
      designation: String(body.designation).trim(),
      employeeCategory: String(body.employeeCategory).trim(),
      employeeId,
      teaches: String(body.teaches).trim(),
      about: String(body.about || '').trim(),
      hobbiesAndInterest: String(body.hobbiesAndInterest || '').trim(),
      role: String(body.role).trim(),
      imageUrl: String(body.imageUrl || '').trim(),
      mobileNo: String(body.mobileNo || '').trim(),
      shareableContactNo: String(body.shareableContactNo || '').trim(),
      mailId: String(body.mailId || '').trim(),
      address: String(body.address || '').trim(),
      briefIntroduction: String(body.briefIntroduction || '').trim(),
      sports: String(body.sports || '').trim(),
      sportsTrainingDetails: String(body.sportsTrainingDetails || '').trim(),
      sportsTeamClub: String(body.sportsTeamClub || '').trim(),
      achievements: String(body.achievements || '').trim(),
      extraCurricularActivities: String(body.extraCurricularActivities || '').trim(),
      extraCurricularTeamClub: String(body.extraCurricularTeamClub || '').trim(),
      professionalBodyAssociation: String(body.professionalBodyAssociation || '').trim(),
      whatYouDo: String(body.whatYouDo || '').trim(),
      updatedAt: new Date().toISOString(),
    };
    const result = await employeeInfoCollection.updateOne({ _id: id }, { $set: updates });
    if (result.matchedCount === 0) return res.status(404).json({ message: 'Staff member not found.' });
    return res.json(sanitizeStaffForResponse(await employeeInfoCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PUT /api/staff/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update staff information.' });
  }
});

app.delete('/api/staff/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await employeeInfoCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Staff member not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/staff/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete staff information.' });
  }
});

app.get('/api/students', async (req, res) => {
  try {
    await connectMongo();
    const students = await studentInfoCollection.find({}).sort({ createdAt: -1, _id: -1 }).toArray();
    return res.json(students.map(sanitizeStudentForResponse));
  } catch (error) {
    console.error('GET /api/students failed:', error);
    return res.status(500).json({ message: 'Unable to load student information.' });
  }
});

app.get('/api/students/profile', requireRecipientRole('student'), async (req, res) => {
  try {
    await connectMongo();
    const userId = String(req.auth.userId || '').trim();
    const student = await studentInfoCollection.findOne({
      $or: [{ studentId: userId }, { admissionNumber: userId }],
    });
    if (!student) return res.status(404).json({ message: 'Student profile not found.' });
    return res.json(sanitizeStudentForResponse(student));
  } catch (error) {
    console.error('GET /api/students/profile failed:', error);
    return res.status(500).json({ message: 'Unable to load the student profile.' });
  }
});

app.get('/api/students/next-id', async (req, res) => {
  try {
    await connectMongo();
    const studentId = await generateNextStudentId();
    return res.json({ studentId });
  } catch (error) {
    console.error('GET /api/students/next-id failed:', error);
    return res.status(500).json({ message: 'Unable to generate student ID.' });
  }
});

app.get('/api/students/:id', async (req, res) => {
  try {
    await connectMongo();
    const student = await studentInfoCollection.findOne({ _id: new ObjectId(req.params.id) });
    if (!student) return res.status(404).json({ message: 'Student not found.' });
    return res.json(sanitizeStudentForResponse(student));
  } catch (error) {
    console.error('GET /api/students/:id failed:', error);
    return res.status(404).json({ message: 'Student not found.' });
  }
});

app.post('/api/students', async (req, res) => {
  try {
    await connectMongo();
    const body = req.body || {};
    const required = ['name', 'className', 'studentId'];
    const missing = required.find((field) => !String(body[field] || '').trim());
    if (missing) return res.status(422).json({ message: `${missing} is required.` });

    const studentId = String(body.studentId).trim();
    const existing = await studentInfoCollection.findOne({
      studentId: { $regex: `^${escapeRegex(studentId)}$`, $options: 'i' }
    });
    if (existing) return res.status(409).json({ message: 'This student ID is already assigned.' });

    const now = new Date().toISOString();
    const document = {
      name: String(body.name || '').trim(),
      className: String(body.className || '').trim(),
      section: String(body.section || '').trim(),
      studentId,
      admissionNumber: String(body.admissionNumber || '').trim(),
      parentName: String(body.parentName || '').trim(),
      mobileNumber: String(body.mobileNumber || '').trim(),
      address: String(body.address || '').trim(),
      about: String(body.about || '').trim(),
      hobbies: String(body.hobbies || '').trim(),
      role: String(body.role || '').trim(),
      imageUrl: String(body.imageUrl || '').trim(),
      createdAt: now,
      updatedAt: now,
    };

    let result;
    try {
      result = await studentInfoCollection.insertOne(document);
    } catch (error) {
      if (error && (error.code === 11000 || /duplicate key|duplicate/i.test(error.message))) {
        return res.status(409).json({ message: 'This student ID is already assigned.' });
      }
      throw error;
    }

    const saved = await studentInfoCollection.findOne({ _id: result.insertedId });
    return res.status(201).json(sanitizeStudentForResponse(saved));
  } catch (error) {
    console.error('POST /api/students failed:', error);
    return res.status(500).json({ message: 'Unable to save student information.' });
  }
});

app.put('/api/students/:id', async (req, res) => {
  try {
    await connectMongo();
    const id = new ObjectId(req.params.id);
    const body = req.body || {};
    const required = ['name', 'className', 'studentId'];
    const missing = required.find((field) => !String(body[field] || '').trim());
    if (missing) return res.status(422).json({ message: `${missing} is required.` });

    const nextStudentId = String(body.studentId).trim();
    const existing = await studentInfoCollection.findOne({
      studentId: { $regex: `^${escapeRegex(nextStudentId)}$`, $options: 'i' },
      _id: { $ne: id },
    });
    if (existing) return res.status(409).json({ message: 'This student ID is already assigned.' });

    const updates = {
      name: String(body.name || '').trim(),
      className: String(body.className || '').trim(),
      section: String(body.section || '').trim(),
      studentId: nextStudentId,
      admissionNumber: String(body.admissionNumber || '').trim(),
      parentName: String(body.parentName || '').trim(),
      mobileNumber: String(body.mobileNumber || '').trim(),
      address: String(body.address || '').trim(),
      about: String(body.about || '').trim(),
      hobbies: String(body.hobbies || '').trim(),
      role: String(body.role || '').trim(),
      imageUrl: String(body.imageUrl || '').trim(),
      updatedAt: new Date().toISOString(),
    };

    let result;
    try {
      result = await studentInfoCollection.updateOne({ _id: id }, { $set: updates });
    } catch (error) {
      if (error && (error.code === 11000 || /duplicate key|duplicate/i.test(error.message))) {
        return res.status(409).json({ message: 'This student ID is already assigned.' });
      }
      throw error;
    }

    if (result.matchedCount === 0) return res.status(404).json({ message: 'Student not found.' });
    return res.json(sanitizeStudentForResponse(await studentInfoCollection.findOne({ _id: id })));
  } catch (error) {
    console.error('PUT /api/students/:id failed:', error);
    return res.status(500).json({ message: 'Unable to update student information.' });
  }
});

app.delete('/api/students/:id', async (req, res) => {
  try {
    await connectMongo();
    const result = await studentInfoCollection.deleteOne({ _id: new ObjectId(req.params.id) });
    if (result.deletedCount === 0) return res.status(404).json({ message: 'Student not found.' });
    return res.json({ success: true });
  } catch (error) {
    console.error('DELETE /api/students/:id failed:', error);
    return res.status(500).json({ message: 'Unable to delete student information.' });
  }
});

function safeUploadFilename(originalName) {
  const safeName = originalName.replace(/\s+/g, '_');
  return `${Date.now()}-${safeName}`;
}

async function saveFileToGridFS(file) {
  if (!imageBucket) {
    throw new Error('GridFS bucket is not initialized');
  }

  const filename = safeUploadFilename(file.originalname);
  const uploadStream = imageBucket.openUploadStream(filename, {
    metadata: { contentType: file.mimetype || 'application/octet-stream' },
  });

  const readable = Readable.from(file.buffer);
  return new Promise((resolve, reject) => {
    readable.pipe(uploadStream)
      .on('error', reject)
      .on('finish', () => resolve({ id: uploadStream.id, filename }));
  });
}

function buildDefaultDocument() {
  return {
    splashScreen: {
      title: '',
      subtitle: '',
      image: '',
      sinceYear: '',
      enabled: true,
    },
    schoolSettings: {
      schoolName: '',
      schoolQuote: '',
      welcomeText: '',
      schoolWebsite: '',
      runningContent: [],
      schoolLogo: '',
      schoolPoster: '',
      selectedLanguage: '',
      themeColor: '',
    },
    // Home-specific content (editable from Content Edit). Kept separate from
    // schoolContent so the Home page can show its own items without affecting
    // the School page staff content.
    homeContent: [],
    schoolContent: {
      founder: {
        photo: '',
        name: '',
        designation: '',
        visionTitle: '',
        visionDescription: '',
      },
      secretary: {
        photo: '',
        name: '',
        designation: '',
        welcomeTitle: '',
        welcomeMessage: '',
      },
      headmaster: {
        photo: '',
        name: '',
        designation: '',
        messageTitle: '',
        message: '',
      },
      members: [],
    },
    gradePage: {
      grade10: { students: [] },
      grade12: { students: [] },
      sportsAchievements: [],
    },
    updatedAt: new Date().toISOString(),
  };
}

async function getMainPageDocument() {
  const collection = await connectMongo();
  return collection.findOne({});
}

async function upsertMainPageDocument(payload) {
  const collection = await connectMongo();
  const now = new Date().toISOString();
  const normalized = {
    ...buildDefaultDocument(),
    ...payload,
    updatedAt: now,
  };

  const result = await collection.findOneAndUpdate(
    {},
    { $set: normalized },
    { upsert: true, returnDocument: 'after' }
  );

  return result.value || normalized;
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Authentication - login
app.post('/api/login', async (req, res) => {
  try {
    const body = req.body || {};
    const identifier = (body.identifier || body.email || body.userId || '').toString().trim();
    const password = (body.password || '').toString();

    if (!identifier || !password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    // Attempt lookup by email (case-insensitive) then by userId
    const lowered = identifier.toLowerCase();
    let user = await usersCollection.findOne({ email: lowered });
    if (!user) {
      user = await usersCollection.findOne({ userId: identifier });
    }

    // Do not reveal whether user exists
    if (!user || !user.password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ message: 'Invalid email or password' });

    const token = signAuthPayload({
      userId: user.userId,
      role: user.role,
      exp: Math.floor(Date.now() / 1000) + (8 * 60 * 60),
    });
    return res.json({ success: true, token, user: sanitizeUserForResponse(user) });
  } catch (error) {
    console.error('POST /api/login failed:', error);
    return res.status(500).json({ message: 'Unable to authenticate user.' });
  }
});
app.post('/api/upload/school-poster', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No poster file was uploaded.' });
  }

  try {
    const saved = await saveFileToGridFS(req.file);
    const url = `${req.protocol}://${req.get('host')}/api/images/${saved.id}`;
    return res.status(200).json({
      url,
      filename: saved.filename,
      originalName: req.file.originalname,
    });
  } catch (error) {
    console.error('POST /api/upload/school-poster failed:', error);
    return res.status(500).json({ message: 'Unable to save the poster image.' });
  }
});

app.post('/api/upload/staff-image', upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No staff image was uploaded.' });
  try {
    const saved = await saveFileToGridFS(req.file);
    return res.json({
      url: `${req.protocol}://${req.get('host')}/api/images/${saved.id}`,
      filename: saved.filename,
      originalName: req.file.originalname,
    });
  } catch (error) {
    console.error('POST /api/upload/staff-image failed:', error);
    return res.status(500).json({ message: 'Unable to save the staff image.' });
  }
});

app.post('/api/upload/attachment', upload.single('file'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No attachment file was uploaded.' });
  }

  try {
    const saved = await saveFileToGridFS(req.file);
    const url = `${req.protocol}://${req.get('host')}/api/images/${saved.id}`;
    return res.status(200).json({
      url,
      filename: saved.filename,
      originalName: req.file.originalname,
    });
  } catch (error) {
    console.error('POST /api/upload/attachment failed:', error);
    return res.status(500).json({ message: 'Unable to save the attachment.' });
  }
});

app.get('/api/mainpage-info', async (req, res) => {
  try {
    const doc = await getMainPageDocument();
    if (!doc) {
      const created = buildDefaultDocument();
      const collection = await connectMongo();
      const result = await collection.findOneAndUpdate(
        {},
        { $set: created },
        { upsert: true, returnDocument: 'after' }
      );
      return res.json(result.value || created);
    }

    const hasTopLevelHomeContent = Array.isArray(doc.homeContent) && doc.homeContent.length > 0;
    const legacyHomeContent = doc.schoolContent && Array.isArray(doc.schoolContent.homeContent) ? doc.schoolContent.homeContent : [];
    let selectedHomeContent = doc.homeContent;
    if (!hasTopLevelHomeContent && legacyHomeContent.length > 0) {
      selectedHomeContent = legacyHomeContent;
      console.log('GET /api/mainpage-info: promoting legacy schoolContent.homeContent to homeContent', {
        topLevelCount: (doc.homeContent || []).length,
        legacyCount: legacyHomeContent.length,
      });
    } else if (Array.isArray(doc.homeContent) && legacyHomeContent.length > doc.homeContent.length) {
      selectedHomeContent = legacyHomeContent;
      console.log('GET /api/mainpage-info: using longer legacy schoolContent.homeContent over top-level homeContent', {
        topLevelCount: doc.homeContent.length,
        legacyCount: legacyHomeContent.length,
      });
    }
    doc.homeContent = selectedHomeContent;

    console.log('GET /api/mainpage-info: returning document with homeContent count', (doc.homeContent || []).length);
    return res.json(doc);
  } catch (error) {
    console.error('GET /api/mainpage-info failed:', error);
    return res.status(500).json({ message: 'Unable to load the school configuration.' });
  }
});

app.put('/api/mainpage-info', async (req, res) => {
  try {
    const updated = await upsertMainPageDocument(req.body || {});
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/splash', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const updated = await upsertMainPageDocument({
      ...current,
      splashScreen: {
        ...(current.splashScreen || {}),
        ...(req.body || {}),
      },
    });
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info/splash failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/settings', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const updated = await upsertMainPageDocument({
      ...current,
      schoolSettings: req.body || current.schoolSettings,
    });
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info/settings failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/content', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const body = req.body || {};

    // If payload explicitly provides homeContent, treat it as an update to the
    // separate homeContent array (used by the app Home page). Otherwise treat
    // the payload as the schoolContent object to preserve existing behavior.
    let updatedDoc;
    if (Object.prototype.hasOwnProperty.call(body, 'homeContent')) {
      const homeContent = Array.isArray(body.homeContent) ? body.homeContent : [];
      console.log('PUT /api/mainpage-info/content: saving top-level homeContent count', homeContent.length);
      updatedDoc = await upsertMainPageDocument({
        ...current,
        homeContent,
        schoolContent: {
          ...current.schoolContent,
          homeContent,
        },
      });
    } else {
      const nextSchoolContent = body || current.schoolContent;
      const legacyHomeContent = nextSchoolContent && Array.isArray(nextSchoolContent.homeContent)
        ? nextSchoolContent.homeContent
        : current.homeContent;
      console.log('PUT /api/mainpage-info/content: saving schoolContent with homeContent count', legacyHomeContent.length);

      updatedDoc = await upsertMainPageDocument({
        ...current,
        schoolContent: nextSchoolContent,
        homeContent: legacyHomeContent,
      });
    }

    console.log('PUT /api/mainpage-info/content: stored document with homeContent count', (updatedDoc.homeContent || []).length);
    return res.json(updatedDoc);
  } catch (error) {
    console.error('PUT /api/mainpage-info/content failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.put('/api/mainpage-info/grades', async (req, res) => {
  try {
    const current = (await getMainPageDocument()) || buildDefaultDocument();
    const updated = await upsertMainPageDocument({
      ...current,
      gradePage: req.body || current.gradePage,
    });
    return res.json(updated);
  } catch (error) {
    console.error('PUT /api/mainpage-info/grades failed:', error);
    return res.status(500).json({ message: 'Unable to save changes. Please try again.' });
  }
});

app.get('/api/images/:id', async (req, res) => {
  if (!imageBucket) {
    return res.status(503).json({ message: 'Image storage is not initialized.' });
  }

  const idParam = req.params.id;

  // Try to treat the param as an ObjectId first. If that fails, fall back to
  // searching by filename. This makes the endpoint tolerant to both direct
  // ObjectId URLs and older filename-based references.
  try {
    let downloadStream;
    let fileFound = false;

    try {
      const fileId = new ObjectId(idParam);
      downloadStream = imageBucket.openDownloadStream(fileId);
    } catch (err) {
      // Not a valid ObjectId; attempt to find by filename
      const files = await imageBucket.find({ filename: idParam }).toArray();
      if (!files || files.length === 0) {
        return res.status(404).json({ message: 'Image not found.' });
      }
      const fileDoc = files[0];
      const contentType = fileDoc.metadata?.contentType || fileDoc.contentType || 'application/octet-stream';
      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Length', fileDoc.length);
      const streamByName = imageBucket.openDownloadStream(fileDoc._id);
      return streamByName.pipe(res);
    }

    downloadStream.on('file', (file) => {
      fileFound = true;
      const contentType = file.metadata?.contentType || 'application/octet-stream';
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
      const uploadedAt = file.uploadDate ? file.uploadDate.getTime() : 0;
      res.setHeader('ETag', `"${file._id.toString()}-${file.length}-${uploadedAt}"`);
      res.setHeader('Content-Type', contentType);
      res.setHeader('Content-Length', file.length);
    });

    downloadStream.on('error', (error) => {
      console.error('GET /api/images/:id failed:', error);
      if (error.code === 'ENOENT' || error.message?.includes('FileNotFound')) {
        return res.status(404).json({ message: 'Image not found.' });
      }
      return res.status(500).json({ message: 'Unable to load the image.' });
    });

    downloadStream.on('end', () => {
      if (!fileFound) {
        res.status(404).json({ message: 'Image not found.' });
      }
    });

    return downloadStream.pipe(res);
  } catch (e) {
    console.error('GET /api/images/:id unexpected error:', e);
    return res.status(500).json({ message: 'Unable to load the image.' });
  }
});

app.get('/uploads/:filename', async (req, res) => {
  if (!imageBucket) {
    return res.status(503).json({ message: 'Image storage is not initialized.' });
  }

  try {
    const files = await imageBucket.find({ filename: req.params.filename }).toArray();
    if (!files || files.length === 0) {
      return res.status(404).json({ message: 'Image not found.' });
    }

    const fileDoc = files[0];
    const downloadStream = imageBucket.openDownloadStream(fileDoc._id);
    const contentType = fileDoc.metadata?.contentType || fileDoc.contentType || 'application/octet-stream';
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    const uploadedAt = fileDoc.uploadDate ? fileDoc.uploadDate.getTime() : 0;
    res.setHeader('ETag', `"${fileDoc._id.toString()}-${fileDoc.length}-${uploadedAt}"`);
    res.setHeader('Content-Length', fileDoc.length);
    downloadStream.pipe(res);
  } catch (error) {
    console.error('GET /uploads/:filename fallback failed:', error);
    return res.status(500).json({ message: 'Unable to load the image.' });
  }
});

// ============= CLASS PHOTOS ENDPOINTS =============

app.get('/api/groups/:groupId/photos', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    if (!groupId) {
      return res.status(400).json({ message: 'Group ID is required.' });
    }
    
    const photos = await classPhotosCollection
      .find({ groupId: { $in: groupIdVariants(groupId) } })
      .sort({ uploadedAt: -1 })
      .toArray();
    return res.json(photos.map(photo => ({
      id: photo._id ? photo._id.toString() : photo.id,
      groupId: photo.groupId,
      imageUrl: photo.imageUrl,
      caption: photo.caption || '',
      uploadedAt: photo.uploadedAt,
      uploadedBy: photo.uploadedBy || '',
    })));
  } catch (error) {
    console.error('GET /api/groups/:groupId/photos failed:', error);
    return res.status(500).json({ message: 'Unable to load photos.' });
  }
});

app.post('/api/groups/:groupId/photos', upload.single('file'), async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const caption = (req.body.caption || '').trim();
    
    if (!req.file) {
      return res.status(400).json({ message: 'No photo file provided.' });
    }

    const now = new Date();
    let imageUrl = '';
    
    // Try to upload to GridFS
    try {
      if (imageBucket) {
        const uploadStream = imageBucket.openUploadStream(req.file.originalname, {
          metadata: { contentType: req.file.mimetype }
        });
        
        await new Promise((resolve, reject) => {
          uploadStream.on('finish', resolve);
          uploadStream.on('error', reject);
          uploadStream.end(req.file.buffer);
        });
        
        imageUrl = `${req.protocol}://${req.get('host')}/api/images/${uploadStream.id}`;
      } else {
        throw new Error('ImageBucket not initialized');
      }
    } catch (e) {
      console.warn('GridFS upload failed:', e.message);
      imageUrl = `/uploads/${Date.now()}-${req.file.originalname}`;
    }

    const photo = {
      groupId,
      imageUrl,
      caption,
      uploadedAt: now.toISOString(),
      uploadedBy: req.body.uploadedBy || 'Teacher',
    };

    const result = await classPhotosCollection.insertOne(photo);
    return res.status(201).json({
      id: result.insertedId.toString(),
      ...photo,
    });
  } catch (error) {
    console.error('POST /api/groups/:groupId/photos failed:', error);
    return res.status(500).json({ message: 'Unable to upload photo.' });
  }
});

app.put('/api/groups/:groupId/photos/:photoId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const photoId = (req.params.photoId || '').trim();
    const caption = (req.body.caption || '').trim();

    let selector;
    try {
      selector = { _id: new ObjectId(photoId), groupId: { $in: groupIdVariants(groupId) } };
    } catch (_) {
      selector = { id: photoId, groupId: { $in: groupIdVariants(groupId) } };
    }

    const result = await classPhotosCollection.findOneAndUpdate(
      selector,
      { $set: { caption } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      return res.status(404).json({ message: 'Photo not found.' });
    }

    const photo = result.value;
    return res.json({
      id: photo._id ? photo._id.toString() : photo.id,
      groupId: photo.groupId,
      imageUrl: photo.imageUrl,
      caption: photo.caption || '',
      uploadedAt: photo.uploadedAt,
      uploadedBy: photo.uploadedBy || '',
    });
  } catch (error) {
    console.error('PUT /api/groups/:groupId/photos/:photoId failed:', error);
    return res.status(500).json({ message: 'Unable to update photo.' });
  }
});

app.delete('/api/groups/:groupId/photos/:photoId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const photoId = (req.params.photoId || '').trim();

    let selector;
    try {
      selector = { _id: new ObjectId(photoId), groupId: { $in: groupIdVariants(groupId) } };
    } catch (_) {
      selector = { id: photoId, groupId: { $in: groupIdVariants(groupId) } };
    }

    const result = await classPhotosCollection.deleteOne(selector);
    if (!result.deletedCount) {
      return res.status(404).json({ message: 'Photo not found.' });
    }
    return res.status(204).send();
  } catch (error) {
    console.error('DELETE /api/groups/:groupId/photos/:photoId failed:', error);
    return res.status(500).json({ message: 'Unable to delete photo.' });
  }
});

// ============= CLASS NEWS ENDPOINTS =============

app.get('/api/groups/:groupId/news', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const news = await classNewsCollection
      .find({ groupId: { $in: groupIdVariants(groupId) } })
      .sort({ publishedAt: -1 })
      .toArray();
    return res.json(news.map(item => ({
      id: item._id ? item._id.toString() : item.id,
      groupId: item.groupId,
      title: item.title,
      description: item.description || '',
      imageUrl: item.imageUrl || '',
      publishedAt: item.publishedAt,
      publishedBy: item.publishedBy || '',
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    })));
  } catch (error) {
    console.error('GET /api/groups/:groupId/news failed:', error);
    return res.status(500).json({ message: 'Unable to load news.' });
  }
});

app.post('/api/groups/:groupId/news', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const title = (req.body.title || '').trim();
    const description = (req.body.description || '').trim();
    const imageUrl = (req.body.imageUrl || '').trim();
    const publishedAt = req.body.publishedAt || new Date().toISOString();

    if (!title) {
      return res.status(422).json({ message: 'News title is required.' });
    }

    const now = new Date().toISOString();
    const newsItem = {
      groupId,
      title,
      description,
      imageUrl,
      publishedAt,
      publishedBy: req.body.publishedBy || 'Teacher',
      createdAt: now,
      updatedAt: now,
    };

    const result = await classNewsCollection.insertOne(newsItem);
    return res.status(201).json({
      id: result.insertedId.toString(),
      ...newsItem,
    });
  } catch (error) {
    console.error('POST /api/groups/:groupId/news failed:', error);
    return res.status(500).json({ message: 'Unable to create news.' });
  }
});

app.put('/api/groups/:groupId/news/:newsId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const newsId = (req.params.newsId || '').trim();
    const title = (req.body.title || '').trim();
    const description = (req.body.description || '').trim();
    const imageUrl = (req.body.imageUrl || '').trim();
    const publishedAt = req.body.publishedAt || new Date().toISOString();

    if (!title) {
      return res.status(422).json({ message: 'News title is required.' });
    }

    let selector;
    try {
      selector = { _id: new ObjectId(newsId), groupId: { $in: groupIdVariants(groupId) } };
    } catch (_) {
      selector = { id: newsId, groupId: { $in: groupIdVariants(groupId) } };
    }

    const result = await classNewsCollection.findOneAndUpdate(
      selector,
      { $set: { title, description, imageUrl, publishedAt, updatedAt: new Date().toISOString() } },
      { returnDocument: 'after' }
    );

    if (!result.value) {
      return res.status(404).json({ message: 'News not found.' });
    }

    const item = result.value;
    return res.json({
      id: item._id ? item._id.toString() : item.id,
      groupId: item.groupId,
      title: item.title,
      description: item.description || '',
      imageUrl: item.imageUrl || '',
      publishedAt: item.publishedAt,
      publishedBy: item.publishedBy || '',
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    });
  } catch (error) {
    console.error('PUT /api/groups/:groupId/news/:newsId failed:', error);
    return res.status(500).json({ message: 'Unable to update news.' });
  }
});

app.delete('/api/groups/:groupId/news/:newsId', async (req, res) => {
  try {
    await connectMongo();
    const groupId = (req.params.groupId || '').trim();
    const newsId = (req.params.newsId || '').trim();

    let selector;
    try {
      selector = { _id: new ObjectId(newsId), groupId: { $in: groupIdVariants(groupId) } };
    } catch (_) {
      selector = { id: newsId, groupId: { $in: groupIdVariants(groupId) } };
    }

    const result = await classNewsCollection.deleteOne(selector);
    if (!result.deletedCount) {
      return res.status(404).json({ message: 'News not found.' });
    }
    return res.status(204).send();
  } catch (error) {
    console.error('DELETE /api/groups/:groupId/news/:newsId failed:', error);
    return res.status(500).json({ message: 'Unable to delete news.' });
  }
});

app.get('/', (req, res) => {
  res.json({
    message: 'Backend is running',
    mongodbUri: process.env.MONGODB_URI ? 'configured' : 'not configured'
  });
});

// Debug-only route: list registered routes when explicitly enabled.
// Enable by setting SHOW_REGISTERED_ROUTES=true in the environment (do not enable in permanent production).
if (process.env.SHOW_REGISTERED_ROUTES === 'true') {
  app.get('/api/_routes', (req, res) => {
    try {
      const routes = [];
      if (app && app._router && Array.isArray(app._router.stack)) {
        app._router.stack.forEach((layer) => {
          if (layer.route && layer.route.path) {
            const methods = Object.keys(layer.route.methods).map((m) => m.toUpperCase()).join(',');
            routes.push({ path: layer.route.path, methods });
          }
        });
      }
      return res.json({ success: true, routes });
    } catch (e) {
      console.error('Error listing routes:', e);
      return res.status(500).json({ success: false });
    }
  });
}

async function startServer() {
  try {
    await connectMongo();
    console.log('Connected to MongoDB');
  } catch (error) {
    console.warn('MongoDB connection unavailable:', error.message);
  }

  // If requested via environment, log the registered routes to help diagnose
  // deployment problems (e.g., missing routes in the deployed instance).
  if (process.env.SHOW_REGISTERED_ROUTES === 'true') {
    try {
      const routeList = [];
      if (app && app._router && Array.isArray(app._router.stack)) {
        app._router.stack.forEach((layer) => {
          if (layer.route && layer.route.path) {
            const methods = Object.keys(layer.route.methods).map((m) => m.toUpperCase()).join(',');
            routeList.push(`${methods} ${layer.route.path}`);
          }
        });
      }
      console.log('REGISTERED ROUTES:', routeList.join(' | '));
    } catch (e) {
      console.warn('Failed to list registered routes:', e && e.message);
    }
  }

  app.listen(port, () => {
    console.log(`Backend running on http://localhost:${port}`);
  });
}

startServer();
