const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// These tests intentionally do not import server.js: it starts the production
// listener and connects to MongoDB as a side effect. The harness below mirrors
// the current inbox contract using only in-memory fixtures, so this change has
// no runtime or database effect.

const PROJECTION_FIELDS = new Set([
  '_id',
  'id',
  'subject',
  'title',
  'message',
  'content',
  'messageType',
  'category',
  'senderId',
  'studentId',
  'senderName',
  'senderEmail',
  'senderRole',
  'studentName',
  'recipientId',
  'recipientLabel',
  'groupId',
  'groupName',
  'isViewed',
  'read',
  'createdAt',
  'updatedAt'
]);

function sanitizeStudentMessageForResponse(doc) {
  if (!doc) return null;
  return {
    id: doc._id ? doc._id.toString() : doc.id || '',
    subject: doc.subject || doc.title || '',
    title: doc.title || doc.subject || '',
    message: doc.message || doc.content || '',
    content: doc.content || doc.message || '',
    messageType: doc.messageType || doc.category || 'General',
    category: doc.category || doc.messageType || 'General',
    senderId: doc.senderId || doc.studentId || '',
    senderName: doc.senderName || 'Student',
    senderEmail: doc.senderEmail || '',
    senderRole: doc.senderRole || 'student',
    studentId: doc.studentId || doc.senderId || '',
    studentName: doc.studentName || doc.senderName || 'Student',
    recipientId: doc.recipientId || '',
    recipientLabel: doc.recipientLabel || doc.groupName || '',
    groupId: doc.groupId || '',
    groupName: doc.groupName || '',
    isViewed: doc.isViewed === true || doc.read === true,
    read: doc.read === true || doc.isViewed === true,
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || doc.createdAt || null
  };
}

function normalizedMessageRole(role) {
  const value = String(role || '').trim().toLowerCase();
  if (value === 'administrator') return 'admin';
  if (value === 'teacher') return 'staff';
  return value;
}

function roleValues(role) {
  if (role === 'admin') return ['admin', 'administrator', ''];
  if (role === 'staff') return ['staff', 'teacher', ''];
  return ['student', 'students', ''];
}

function hasField(doc, field) {
  return Object.prototype.hasOwnProperty.call(doc, field);
}

function mongoNullMatches(doc, field) {
  return !hasField(doc, field) || doc[field] === null;
}

function recipientMatches(doc, userId, role) {
  const roleMatch = hasField(doc, 'recipientRole') && roleValues(role).includes(doc.recipientRole);
  return doc.recipientId === userId ||
    doc.recipientUsername === userId ||
    ((doc.recipientId === '' || mongoNullMatches(doc, 'recipientId')) && roleMatch);
}

function inboxTargetMatches(doc, userId, groupValues) {
  return doc.recipientId === userId ||
    doc.recipientUsername === userId ||
    doc.senderId === userId ||
    mongoNullMatches(doc, 'groupId') ||
    doc.groupId === '' ||
    mongoNullMatches(doc, 'groupName') ||
    doc.groupName === '' ||
    groupValues.includes(doc.groupId) ||
    groupValues.includes(doc.groupName);
}

function project(doc) {
  return Object.fromEntries(Object.entries(doc).filter(([key]) => PROJECTION_FIELDS.has(key)));
}

function buildInboxResponse({ role, userId, profile = {}, studentMessages = [], groupMessages = [] }) {
  const normalizedRole = normalizedMessageRole(role);
  const isStudent = normalizedRole === 'student';
  const groupValues = [
    profile.groupId,
    profile.groupName,
    profile.className,
    profile.class,
    [profile.className, profile.section].filter(Boolean).join('-')
  ]
    .filter(Boolean)
    .map(String);

  const direct = studentMessages.filter((doc) => {
    const recipientScope = recipientMatches(doc, userId, normalizedRole) ||
      (isStudent && doc.senderId === String(userId || '').trim());
    return recipientScope && inboxTargetMatches(doc, String(userId || '').trim(), groupValues);
  });

  const recipientField = isStudent ? 'sendToStudents' : 'sendToStaff';
  const legacy = groupMessages.filter((doc) => {
    const senderRole = String(doc.senderRole || '').toLowerCase();
    const senderAllowed = ['admin', 'staff', 'teacher'].includes(senderRole);
    const recipientAllowed = doc[recipientField] === true;
    const groupMatch = mongoNullMatches(doc, 'groupId') ||
      doc.groupId === '' ||
      groupValues.includes(String(doc.groupId)) ||
      groupValues.includes(String(doc.groupName));
    return senderAllowed && recipientAllowed && groupMatch;
  });

  return {
    success: true,
    data: [...direct, ...legacy]
      .map(sanitizeStudentMessageForResponse)
      .sort((a, b) => String(b.createdAt || '').localeCompare(String(a.createdAt || '')))
  };
}

function authResult(authHeader, role) {
  if (!authHeader || !/^Bearer\s+\S+$/.test(authHeader)) return { status: 401 };
  // This is deliberately a simulated authorization check, not the live
  // authenticateUser/requireRecipientRole middleware.
  const normalizedRole = normalizedMessageRole(role);
  return ['admin', 'staff', 'student'].includes(normalizedRole)
    ? { status: 200, role: normalizedRole }
    : { status: 403 };
}

const fixtures = {
  student: {
    _id: 'student-direct-1',
    subject: 'Current subject',
    message: 'Current message',
    messageType: 'Notice',
    senderId: 'admin-fixture',
    senderName: 'Admin Fixture',
    senderRole: 'admin',
    recipientId: 'student-fixture',
    createdAt: '2026-01-02T00:00:00.000Z',
    updatedAt: '2026-01-02T00:00:00.000Z'
  },
  legacy: {
    _id: 'legacy-group-1',
    title: 'Legacy title',
    content: 'Legacy content',
    category: 'Announcement',
    senderRole: 'admin',
    senderName: 'Admin Fixture',
    sendToStudents: true,
    createdAt: '2026-01-01T00:00:00.000Z'
  },
  mixed: {
    _id: 'mixed-1',
    title: 'Fallback title',
    content: 'Fallback content',
    senderId: 'student-fixture',
    createdAt: '2025-12-31T00:00:00.000Z'
  }
};

test('student inbox preserves current, legacy, and student-sent messages', () => {
  const response = buildInboxResponse({
    role: 'student',
    userId: 'student-fixture',
    profile: { groupId: 'group-fixture', groupName: 'Group Fixture' },
    studentMessages: [fixtures.student, fixtures.mixed],
    groupMessages: [fixtures.legacy]
  });

  assert.equal(response.success, true);
  assert.equal(response.data.length, 3);
  assert.deepEqual(Object.keys(response.data[0]).sort(), [
    'category', 'content', 'createdAt', 'groupId', 'groupName', 'id',
    'isViewed', 'message', 'messageType', 'read', 'recipientId',
    'recipientLabel', 'senderEmail', 'senderId', 'senderName', 'senderRole',
    'studentId', 'studentName', 'subject', 'title', 'updatedAt'
  ].sort());
});

test('admin and staff roles plus administrator and teacher aliases receive role-scoped legacy messages', () => {
  for (const role of ['admin', 'administrator', 'staff', 'teacher']) {
    const response = buildInboxResponse({
      role,
      userId: `${role}-fixture`,
      groupMessages: [{
        _id: `${role}-legacy`,
        title: 'Role message',
        senderRole: role === 'administrator' ? 'admin' : role === 'teacher' ? 'teacher' : role,
        // The current inbox route uses sendToStudents only for students and
        // sendToStaff for every non-student role, including admin aliases.
        sendToStudents: false,
        sendToStaff: true,
        createdAt: '2026-01-03T00:00:00.000Z'
      }]
    });
    assert.equal(response.data.length, 1, role);
  }

  const excluded = buildInboxResponse({
    role: 'admin',
    userId: 'admin-fixture',
    groupMessages: [{
      _id: 'legacy-administrator-source-role',
      senderRole: 'administrator',
      sendToStaff: true,
      title: 'Excluded by current legacy filter'
    }]
  });
  assert.equal(excluded.data.length, 0);
});

test('direct-recipient and group-recipient scope is preserved', () => {
  const response = buildInboxResponse({
    role: 'staff',
    userId: 'staff-fixture',
    profile: { groupId: 'group-fixture', groupName: 'Group Fixture', className: 'Class A', section: 'B' },
    studentMessages: [
      { _id: 'direct', recipientId: 'staff-fixture', title: 'Direct', createdAt: '2026-01-03' },
      { _id: 'group', recipientId: '', recipientRole: 'staff', groupId: 'group-fixture', title: 'Group', createdAt: '2026-01-02' },
      { _id: 'other', recipientId: 'other-staff', title: 'Other', createdAt: '2026-01-04' }
    ]
  });
  assert.deepEqual(response.data.map((item) => item.id), ['direct', 'group']);
});

test('recipient role, username, empty/null recipient, and class fallback branches match the current filters', () => {
  const response = buildInboxResponse({
    role: 'teacher',
    userId: 'staff-fixture',
    profile: { className: 'Class A', section: 'B' },
    studentMessages: [
      { _id: 'username', recipientUsername: 'staff-fixture', title: 'Username' },
      { _id: 'null-role-match', recipientId: null, recipientRole: 'teacher', groupName: 'Class A-B', title: 'Null role match' },
      { _id: 'empty-role-match', recipientId: '', recipientRole: '', groupId: 'Class A-B', title: 'Empty role match' },
      { _id: 'null-role-miss', recipientId: null, recipientRole: 'student', groupName: 'Class A-B', title: 'Wrong role' },
      { _id: 'missing-role-miss', groupId: 'Class A-B', title: 'Missing role' },
      { _id: 'class-fallback', recipientId: '', recipientRole: 'staff', groupId: 'Class A-B', title: 'Class fallback' }
    ]
  });
  assert.deepEqual(response.data.map((item) => item.id), [
    'username', 'null-role-match', 'empty-role-match', 'class-fallback'
  ]);
});

test('mixed missing optional fields use current sanitizer defaults', () => {
  const result = sanitizeStudentMessageForResponse(fixtures.mixed);
  assert.equal(result.subject, 'Fallback title');
  assert.equal(result.title, 'Fallback title');
  assert.equal(result.message, 'Fallback content');
  assert.equal(result.content, 'Fallback content');
  assert.equal(result.messageType, 'General');
  assert.equal(result.category, 'General');
  assert.equal(result.senderName, 'Student');
  assert.equal(result.senderRole, 'student');
  assert.equal(result.studentId, 'student-fixture');
  assert.equal(result.updatedAt, result.createdAt);
  assert.equal(result.isViewed, false);
  assert.equal(result.read, false);
});

test('sanitizer handles null documents, BSON-like IDs, and id fallback precedence', () => {
  assert.equal(sanitizeStudentMessageForResponse(null), null);
  assert.equal(sanitizeStudentMessageForResponse({ _id: { toString: () => 'bson-id' }, id: 'fallback-id' }).id, 'bson-id');
  assert.equal(sanitizeStudentMessageForResponse({ id: 'fallback-id' }).id, 'fallback-id');
  assert.equal(sanitizeStudentMessageForResponse({ _id: { toString: () => '' }, id: 'fallback-id' }).id, '');
});

test('sorting uses descending string timestamps and preserves stable order for equal/missing timestamps', () => {
  const response = buildInboxResponse({
    role: 'student',
    userId: 'student-fixture',
    studentMessages: [
      { _id: 'equal-first', senderId: 'student-fixture', createdAt: '2026-01-01' },
      { _id: 'newest', senderId: 'student-fixture', createdAt: '2026-01-03' },
      { _id: 'equal-second', senderId: 'student-fixture', createdAt: '2026-01-01' },
      { _id: 'missing-time', senderId: 'student-fixture' }
    ]
  });
  assert.deepEqual(response.data.map((item) => item.id), [
    'newest', 'equal-first', 'equal-second', 'missing-time'
  ]);
});

test('empty inbox preserves the existing envelope', () => {
  assert.deepEqual(buildInboxResponse({ role: 'student', userId: 'student-fixture' }), { success: true, data: [] });
});

test('missing and invalid authentication are rejected without fixture access', () => {
  assert.deepEqual(authResult(undefined, 'student'), { status: 401 });
  assert.deepEqual(authResult('Basic not-bearer', 'student'), { status: 401 });
  assert.deepEqual(authResult('Bearer synthetic', 'unknown'), { status: 403 });
  assert.deepEqual(authResult('Bearer synthetic', 'student'), { status: 200, role: 'student' });
});

test('projection contains every source field used by the sanitizer', () => {
  const projectionFixtures = [fixtures.student, fixtures.legacy, fixtures.mixed];
  for (const fixture of projectionFixtures) {
    assert.deepEqual(
      sanitizeStudentMessageForResponse(project(fixture)),
      sanitizeStudentMessageForResponse(fixture),
      fixture._id
    );
  }
  assert.deepEqual([...PROJECTION_FIELDS].sort(), [
    '_id', 'category', 'content', 'createdAt', 'groupId', 'groupName', 'id',
    'isViewed', 'message', 'messageType', 'read', 'recipientId',
    'recipientLabel', 'senderEmail', 'senderId', 'senderName', 'senderRole',
    'studentId', 'studentName', 'subject', 'title', 'updatedAt'
  ].sort());
});

test('live source applies the same complete projection to both inbox reads', () => {
  const serverSource = fs.readFileSync(path.resolve(__dirname, '..', 'server.js'), 'utf8');
  const projectionUseCount = (serverSource.match(/projection: INBOX_MESSAGE_PROJECTION/g) || []).length;

  assert.equal(projectionUseCount, 2);
  assert.match(
    serverSource,
    /studentMessagesCollection\.find\([\s\S]*?\}, \{ projection: INBOX_MESSAGE_PROJECTION \}\)\.toArray\(\),/
  );
  assert.match(
    serverSource,
    /groupMessagesCollection\.find\(legacyFilter, \{ projection: INBOX_MESSAGE_PROJECTION \}\)\.toArray\(\),/
  );
  for (const field of PROJECTION_FIELDS) {
    assert.match(serverSource, new RegExp(`\\b${field.replace('_', '\\_')}: 1`));
  }
});

test('projection preserves fallback precedence and viewed/read aliases', () => {
  const full = {
    _id: 'fallbacks', subject: 'Subject', title: 'Title', message: 'Message', content: 'Content',
    messageType: 'Type', category: 'Category', senderId: 'sender', studentId: 'student',
    senderName: 'Sender', senderEmail: 'sender@example.invalid', senderRole: 'staff', studentName: 'Student',
    recipientId: 'recipient', recipientLabel: 'Label', groupId: 'group', groupName: 'Group',
    isViewed: true, read: false, createdAt: '2026-01-01', updatedAt: '2026-01-02', ignored: 'not needed'
  };
  assert.deepEqual(sanitizeStudentMessageForResponse(project(full)), sanitizeStudentMessageForResponse(full));
});
