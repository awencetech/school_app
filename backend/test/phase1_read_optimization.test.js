const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const serverSource = fs.readFileSync(path.resolve(__dirname, '..', 'server.js'), 'utf8');

function routeSource(start, end) {
  const startIndex = serverSource.indexOf(start);
  const endIndex = serverSource.indexOf(end, startIndex);
  assert.notEqual(startIndex, -1, `Missing route start: ${start}`);
  assert.notEqual(endIndex, -1, `Missing route end: ${end}`);
  return serverSource.slice(startIndex, endIndex);
}

function project(document, fields) {
  return Object.fromEntries(
    Object.entries(document).filter(([field]) => fields.includes(field)),
  );
}

test('student attendance projection preserves fields used by the Flutter model and route', () => {
  const fields = [
    '_id', 'id', 'studentId', 'studentName', 'admissionNumber', 'className',
    'section', 'attendanceDate', 'subject', 'classType', 'reason', 'status',
    'present', 'markedBy', 'createdAt', 'updatedAt',
  ];
  assert.match(serverSource, /const STUDENT_ATTENDANCE_PROJECTION = Object\.freeze\(\{/);
  const declaration = serverSource.match(
    /const STUDENT_ATTENDANCE_PROJECTION = Object\.freeze\(\{([\s\S]*?)\}\);/,
  );
  assert.ok(declaration);
  const projectedFields = [...declaration[1].matchAll(/^\s*([A-Za-z_$][\w$]*): 1,?$/gm)]
    .map((match) => match[1]);
  assert.deepEqual(projectedFields.sort(), [...fields].sort());

  const route = routeSource(
    "app.get('/api/student-attendance',",
    "app.post('/api/student-attendance',",
  );
  assert.match(
    route,
    /\.find\(filter, \{ projection: STUDENT_ATTENDANCE_PROJECTION \}\)\s*\.sort\(\{ attendanceDate: -1, createdAt: -1 \}\)\s*\.toArray\(\)/,
  );
  assert.match(route, /if \(req\.query\.date\)/);
  assert.match(route, /if \(req\.query\.fromDate \|\| req\.query\.toDate\)/);
  assert.match(route, /if \(req\.query\.className\)/);
  assert.match(route, /if \(req\.query\.status\)/);
  assert.match(route, /return res\.json\(\{ success: true, data \}\)/);
  assert.doesNotMatch(route, /\.limit\(/);
});

test('student attendance projection preserves legacy IDs and standard record values', () => {
  const fields = [
    '_id', 'id', 'studentId', 'studentName', 'admissionNumber', 'className',
    'section', 'attendanceDate', 'subject', 'classType', 'reason', 'status',
    'present', 'markedBy', 'createdAt', 'updatedAt',
  ];
  const legacyRecord = {
    _id: { toString: () => 'attendance-object-id' },
    id: 'legacy-attendance-id',
    studentId: 'STU-1',
    studentName: 'Student One',
    admissionNumber: 'ADM-1',
    className: 'Class A-B',
    section: 'B',
    attendanceDate: '2026-03-05',
    subject: 'Mathematics',
    classType: 'Classroom',
    reason: '',
    status: 'Present',
    present: true,
    markedBy: 'staff-1',
    createdAt: '2026-03-05T08:00:00.000Z',
    updatedAt: '2026-03-05T08:00:00.000Z',
    internalNote: 'not part of the attendance record contract',
  };
  const projected = project(legacyRecord, fields);
  const expected = Object.fromEntries(
    Object.entries(legacyRecord).filter(([key]) => key !== 'internalNote'),
  );
  expected._id = legacyRecord._id.toString();
  assert.deepEqual(
    { ...projected, _id: projected._id.toString() },
    expected,
  );
});

test('group message projections include every field used by their response sanitizers', () => {
  const projectionFields = (name) => {
    const declaration = serverSource.match(
      new RegExp(`const ${name} = Object\\.freeze\\(\\{([\\s\\S]*?)\\}\\);`),
    );
    assert.ok(declaration, `Missing ${name}`);
    return new Set(
      [...declaration[1].matchAll(/^\s*([A-Za-z_$][\w$]*): 1,?$/gm)]
        .map((match) => match[1]),
    );
  };
  const sanitizerFields = (name, end) => {
    const source = routeSource(`function ${name}(`, end);
    return new Set([...source.matchAll(/\bdoc(?:\?\.|\.)((?:[A-Za-z_$][\w$]*))/g)]
      .map((match) => match[1]));
  };

  const adminFields = projectionFields('ADMIN_MESSAGE_PROJECTION');
  for (const field of sanitizerFields('sanitizeAdminMessageForResponse', 'const ADMIN_MESSAGE_PROJECTION')) {
    assert.ok(adminFields.has(field), `ADMIN_MESSAGE_PROJECTION omits ${field}`);
  }
  const groupFields = projectionFields('GROUP_MESSAGE_PROJECTION');
  for (const field of sanitizerFields('sanitizeGroupMessageForResponse', 'const GROUP_MESSAGE_PROJECTION')) {
    assert.ok(groupFields.has(field), `GROUP_MESSAGE_PROJECTION omits ${field}`);
  }

  const commentFields = projectionFields('GROUP_MESSAGE_COMMENT_PROJECTION');
  for (const field of [
    '_id', 'id', 'messageId', 'groupId', 'studentId', 'userId',
    'studentName', 'name', 'comment', 'text', 'createdAt', 'updatedAt',
  ]) {
    assert.ok(commentFields.has(field), `GROUP_MESSAGE_COMMENT_PROJECTION omits ${field}`);
  }
});

test('group message and comment reads preserve filters, ordering, and response construction', () => {
  const recipientHelper = routeSource(
    'async function getAdminMessagesForRecipient',
    'app.get(\'/api/messages/student\'',
  );
  assert.match(recipientHelper, /const profileProjection = \{ groupId: 1, groupName: 1, className: 1, class: 1 \}/);
  assert.match(recipientHelper, /findCredentialByUserId\(req\.auth\.userId, role, \{[\s\S]*?projection: profileProjection/);
  assert.match(recipientHelper, /studentInfoCollection\.findOne\([\s\S]*?projection: profileProjection/);
  assert.match(recipientHelper, /employeeInfoCollection\.findOne\([\s\S]*?projection: profileProjection/);
  assert.match(recipientHelper, /senderRole: 'admin'/);
  assert.match(recipientHelper, /\[recipientField\]: true/);
  assert.match(recipientHelper, /\.\.\.groupFilter/);
  assert.match(recipientHelper, /projection: ADMIN_MESSAGE_PROJECTION/);
  assert.match(recipientHelper, /\.sort\(\{ createdAt: -1 \}\)/);
  assert.match(recipientHelper, /messages\.map\(sanitizeAdminMessageForResponse\)/);

  const studentGroupRoute = routeSource(
    "app.get('/api/messages/group/:groupId',",
    'function sanitizeDiaryForResponse',
  );
  assert.match(studentGroupRoute, /requireRecipientRole\('student'\)/);
  assert.match(studentGroupRoute, /senderRole: 'admin'/);
  assert.match(studentGroupRoute, /groupId: \{ \$in: \[groupId, null, ''\] \}/);
  assert.match(studentGroupRoute, /sendToStudents: true/);
  assert.match(studentGroupRoute, /projection: ADMIN_MESSAGE_PROJECTION/);
  assert.match(studentGroupRoute, /\.sort\(\{ createdAt: -1 \}\)/);
  assert.match(studentGroupRoute, /messages\.map\(sanitizeAdminMessageForResponse\)/);

  const groupRoute = routeSource(
    "app.get('/api/groups/:groupId/messages',",
    "app.post('/api/groups/:groupId/messages/:messageId/like',",
  );
  assert.match(groupRoute, /groupId: \{ \$in: groupIdVariants\(groupId\) \}/);
  assert.match(groupRoute, /projection: GROUP_MESSAGE_PROJECTION/);
  assert.match(groupRoute, /\.sort\(\{ createdAt: -1 \}\)/);
  assert.match(groupRoute, /messageId: \{ \$in: messageKeys \}/);
  assert.match(groupRoute, /projection: GROUP_MESSAGE_COMMENT_PROJECTION/);
  assert.match(groupRoute, /\.sort\(\{ createdAt: 1 \}\)/);
  assert.match(groupRoute, /return res\.json\(hydrated\.map\(sanitizeGroupMessageForResponse\)\)/);

  const commentsRoute = routeSource(
    "app.get('/api/groups/:groupId/messages/:messageId/comments',",
    "app.post('/api/groups/:groupId/messages/:messageId/comments',",
  );
  assert.match(commentsRoute, /messageId \},\s*\{ projection: GROUP_MESSAGE_COMMENT_PROJECTION \}/);
  assert.match(commentsRoute, /\.sort\(\{ createdAt: 1 \}\)/);
  for (const field of ['id:', 'messageId:', 'groupId:', 'studentId:', 'studentName:', 'comment:', 'text:', 'createdAt:', 'updatedAt:']) {
    assert.ok(commentsRoute.includes(field), `Comment response omits ${field}`);
  }
  assert.doesNotMatch(groupRoute, /\.limit\(/);
});

test('campaign route keeps its one compatible read and delegates to the single-pass calculation', () => {
  const campaignRoute = routeSource(
    "app.get('/api/campaign-performance',",
    "function sanitizeStudentRequestForResponse",
  );
  assert.match(campaignRoute, /requireRecipientRole\('staff'\)/);
  assert.match(campaignRoute, /studentInfoCollection\.find\(\{ role: \{ \$in: \['student', 'Student', ''\] \} \}\)\.toArray\(\)/);
  assert.equal((campaignRoute.match(/studentInfoCollection\.find\(/g) || []).length, 1);
  assert.match(campaignRoute, /res\.json\(buildCampaignPerformance\(students\)\)/);
  assert.match(campaignRoute, /Unable to load class performance\./);
  assert.doesNotMatch(campaignRoute, /projection:|\.limit\(/);
});

test('diary projections retain sanitizer, merge, sorting, and access-check fields', () => {
  const declaration = serverSource.match(
    /const DIARY_PROJECTION = Object\.freeze\(\{([\s\S]*?)\}\);/,
  );
  assert.ok(declaration);
  const projectedFields = new Set(
    [...declaration[1].matchAll(/^\s*(['"]?)([A-Za-z_$][\w$.]*)\1: 1,?$/gm)]
      .map((match) => match[2]),
  );
  for (const field of [
    '_id', 'studentId', 'studentName', 'diaryId', 'groupId', 'classId',
    'diaryDate', 'date', 'parentObservation.wentToBedAt',
    'parentObservation.gotUpAt', 'parentObservation.brushedTeeth',
    'parentObservation.didYoga', 'parentObservation.breakfast',
    'parentObservation.homework', 'parentObservation.assignmentCompletion',
    'parentObservation.helpfulAtHome', 'parentObservation.respectfulToElders',
    'parentObservation.parentsRemark', 'studentObservation.mood',
    'teacherObservation.punctuality', 'teacherObservation.food',
    'subjectFeedback.subject', 'subjectFeedback.completionOfDueAssignment',
    'subjectFeedback.performanceInClassToday', 'subjectFeedback.note',
    'gkScore', 'area', 'status', 'diaryDetails', 'createdAt', 'updatedAt',
  ]) {
    assert.ok(projectedFields.has(field), `DIARY_PROJECTION omits ${field}`);
  }

  const diaryList = routeSource("app.get('/api/diary',", "app.get('/api/diary/student',");
  assert.match(diaryList, /requireDiaryRead/);
  assert.match(diaryList, /filter\.diaryDate = filter\.date/);
  assert.match(diaryList, /filter\.studentId = \{ \$in: identifiers \}/);
  assert.match(diaryList, /find\(filter, \{ projection: DIARY_PROJECTION \}\)/);
  assert.match(diaryList, /\.sort\(\{ studentName: 1 \}\)/);
  assert.match(diaryList, /data: records\.map\(sanitizeDiaryForResponse\)/);

  const studentDiary = routeSource("app.get('/api/diary/student',", "app.get('/api/diary/student-observation/:id',");
  assert.match(studentDiary, /requireDiaryRead/);
  assert.match(studentDiary, /studentDiaryCollection\.find\([\s\S]*?projection: DIARY_PROJECTION/);
  assert.match(studentDiary, /diaryCollection\.find\([\s\S]*?projection: DIARY_PROJECTION/);
  assert.match(studentDiary, /staffRecords\.map/);
  assert.match(studentDiary, /studentObservation: studentRecord\.studentObservation/);
  assert.match(studentDiary, /String\(right\.updatedAt \|\| ''\)\.localeCompare\(String\(left\.updatedAt \|\| ''\)\)/);
  assert.match(studentDiary, /data: records\.map\(sanitizeDiaryForResponse\)/);

  for (const [start, end] of [
    ["app.get('/api/diary/student-observation/:id',", "app.get('/api/diary/:id',"],
    ["app.get('/api/diary/:id',", "app.post('/api/diary',"],
  ]) {
    const detailRoute = routeSource(start, end);
    assert.match(detailRoute, /requireDiaryRead/);
    assert.match(detailRoute, /projection: DIARY_PROJECTION/);
    assert.match(detailRoute, /studentAttendanceIdentifiers\(req\.auth\)/);
    assert.match(detailRoute, /staffHasGroupAccess\(req\.auth/);
    assert.match(detailRoute, /data: sanitizeDiaryForResponse\(record\)/);
  }
});

test('school and class resource projections preserve API fields, filters, sorting, and access middleware', () => {
  const readProjectionFields = (name) => {
    const declaration = serverSource.match(
      new RegExp(`const ${name} = Object\\.freeze\\(\\{([\\s\\S]*?)\\}\\);`),
    );
    assert.ok(declaration, `Missing ${name}`);
    return new Set(
      [...declaration[1].matchAll(/^\s*([A-Za-z_$][\w$]*): 1,?$/gm)]
        .map((match) => match[1]),
    );
  };
  const sanitizerFields = (name, end) => {
    const source = routeSource(`function ${name}(`, end);
    return new Set([...source.matchAll(/\bdoc(?:\?\.|\.)((?:[A-Za-z_$][\w$]*))/g)]
      .map((match) => match[1]));
  };
  for (const [projection, sanitizer, end] of [
    ['SCHOOL_RESOURCE_PROJECTION', 'sanitizeSchoolResourceForResponse', 'const SCHOOL_RESOURCE_PROJECTION'],
    ['CLASS_RESOURCE_PROJECTION', 'sanitizeClassResourceForResponse', 'const CLASS_RESOURCE_PROJECTION'],
  ]) {
    const fields = readProjectionFields(projection);
    for (const field of sanitizerFields(sanitizer, end)) {
      assert.ok(fields.has(field), `${projection} omits ${field}`);
    }
  }

  const classResources = routeSource(
    "app.get('/api/class-resources/:groupId',",
    "app.delete('/api/class-resources/:groupId/:id',",
  );
  assert.match(classResources, /requireGroupAccess/);
  assert.match(classResources, /find\(\{ groupId \}, \{ projection: CLASS_RESOURCE_PROJECTION \}\)/);
  assert.match(classResources, /\.sort\(\{ createdAt: -1, _id: -1 \}\)/);
  assert.equal((classResources.match(/projection: CLASS_RESOURCE_PROJECTION/g) || []).length, 3);

  const schoolResources = routeSource(
    "app.get('/api/school-resources',",
    "app.delete('/api/school-resources/:id',",
  );
  assert.match(schoolResources, /requireRecipientRole\(\['admin', 'staff', 'student'\]\)/);
  assert.match(schoolResources, /\.find\(\{ schoolId \}, \{ projection: SCHOOL_RESOURCE_PROJECTION \}\)/);
  assert.match(schoolResources, /\.sort\(\{ date: -1, createdAt: -1, _id: -1 \}\)/);
  assert.equal((schoolResources.match(/projection: SCHOOL_RESOURCE_PROJECTION/g) || []).length, 4);
  assert.doesNotMatch(classResources + schoolResources, /\.limit\(/);
});

test('authentication projection retains every account field consumed by authentication', () => {
  const declaration = serverSource.match(
    /const AUTHENTICATED_CREDENTIAL_PROJECTION = Object\.freeze\(\{([\s\S]*?)\}\);/,
  );
  assert.ok(declaration);
  const fields = new Set(
    [...declaration[1].matchAll(/^\s*([A-Za-z_$][\w$]*): 1,?$/gm)]
      .map((match) => match[1]),
  );
  for (const field of [
    'userId', 'userID', 'role', 'status', 'accountStatus', 'State', 'state',
    'active', 'isActive', 'enabled', 'isEnabled', 'email', 'emailAddress',
    'userEmail',
  ]) {
    assert.ok(fields.has(field), `Authentication projection omits ${field}`);
  }
  const authenticationLookup = routeSource(
    'async function findCredentialForAuthentication',
    'function credentialLookupVariants',
  );
  assert.match(authenticationLookup, /findOne\(\{ userId \}, options\)/);
  assert.match(authenticationLookup, /entry\.collection\.findOne\(\{ userId \}, options\)/);
  assert.match(authenticationLookup, /usersCollection\.findOne\(\{ userId \}, options\)/);

  const repository = routeSource('const userManagementRepository = {', 'const authenticateUser =');
  assert.match(repository, /findByIdentity\(userId, role\)[\s\S]*?findCredentialForAuthentication\(userId, role\)/);
  assert.match(repository, /isCredentialDocumentAllowed\(user\)/);
  const authentication = routeSource('const authenticateUser =', 'function optionalAuthenticateUser');
  assert.match(authentication, /loadUser: \(userId, role\) => userManagementRepository\.findByIdentity\(userId, role\)/);
});

test('shared student and staff access reads are projected and reused request-locally', () => {
  const staffContext = routeSource('async function staffAssignedGroupData', 'async function staffAssignedStudentIds');
  assert.match(staffContext, /findStaffForAccess\(auth\?\.userId, \{[\s\S]*?STAFF_ACCESS_IDENTITY_PROJECTION/);
  assert.match(staffContext, /staffAccessCollection\.findOne\([\s\S]*?STAFF_GROUP_ACCESS_PROJECTION/);
  assert.match(staffContext, /groupsCollection\.find\(selector, \{ projection: STAFF_ASSIGNED_GROUP_PROJECTION \}\)/);
  assert.match(staffContext, /classesCollection\.find\(selector, \{ projection: STAFF_ASSIGNED_GROUP_PROJECTION \}\)/);
  assert.match(staffContext, /student\?\.id[\s\S]*?student\?\.admissionNumber/);

  const assignedClasses = routeSource('async function staffAssignedClassNames', 'async function staffHasAssignedClass');
  assert.match(assignedClasses, /staffAssignedGroupData\(auth\)/);
  assert.match(assignedClasses, /projection: \{ className: 1 \}/);
  assert.doesNotMatch(assignedClasses, /staffAssignedStudentIds\(auth\)|groupsCollection\.find|classesCollection\.find/);

  const attendanceIdentity = routeSource('async function studentAttendanceIdentifiers', "app.get('/api/student-attendance',");
  assert.match(attendanceIdentity, /projection: \{ studentId: 1, admissionNumber: 1 \}/);
  assert.match(attendanceIdentity, /userId,\s*profile\?\.studentId,\s*profile\?\.admissionNumber/);

  const groupAccess = routeSource('async function studentHasGroupAccess', 'async function findAccessGroupByReference');
  assert.match(groupAccess, /projection: \{ _id: 1, studentId: 1, admissionNumber: 1 \}/);
  assert.match(groupAccess, /student\.studentId[\s\S]*?student\.admissionNumber[\s\S]*?student\._id\?\.toString/);

  const groupLookup = routeSource('async function findAccessGroupByReference', 'function requireGroupAccess');
  assert.match(groupLookup, /const projection = \{ _id: 1, id: 1, name: 1, students: 1 \}/);
  assert.match(groupLookup, /findGroupByReference\(groupId, \{ projection \}\)/);
  assert.match(groupLookup, /classesCollection\.findOne[\s\S]*?\{ projection \}/);

  const generalGroupLookup = routeSource('async function findGroupByReference', 'async function renumberGroups');
  assert.match(generalGroupLookup, /options\s*\?\s*await groupsCollection\.findOne/);
  assert.match(generalGroupLookup, /options\s*\?\s*await groupsCollection\.find\(\{\}, options\)\.toArray\(\)/);
  assert.match(generalGroupLookup, /groupReferenceSlug\(value\)/);

  const campaignStudentRoute = routeSource(
    "app.get('/api/student-campaigns',",
    "app.post('/api/student-campaigns',",
  );
  assert.match(campaignStudentRoute, /projection: \{ className: 1, section: 1 \}/);
  assert.match(campaignStudentRoute, /filter\.\$or = \[\{ className: '' \}, \{ className: className \}\]/);
  const ptmStudentRoute = routeSource(
    "app.get('/api/student-ptm',",
    "app.post('/api/student-ptm',",
  );
  assert.match(ptmStudentRoute, /projection: \{ className: 1, section: 1 \}/);
  assert.match(ptmStudentRoute, /student\?\.className \|\| !student\?\.section/);
  assert.match(ptmStudentRoute, /section: String\(student\.section\)\.trim\(\)/);
});
