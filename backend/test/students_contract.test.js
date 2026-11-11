const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// server.js starts the production listener and initializes MongoDB on import.
// These tests therefore use synthetic in-memory data plus source assertions;
// they do not claim live Express or MongoDB route coverage.

const STUDENT_LIST_FIELDS = [
  '_id', 'id', 'name', 'className', 'section', 'studentId',
  'admissionNumber', 'admissionNo', 'parentName', 'mobileNumber', 'address',
  'about', 'hobbies', 'specialNeeds', 'special_needs', 'role', 'imageUrl',
  'createdAt', 'updatedAt',
];

const STUDENT_LIST_PROJECTION = new Set(STUDENT_LIST_FIELDS);

function projectStudent(document) {
  return Object.fromEntries(
    Object.entries(document).filter(([field]) => STUDENT_LIST_PROJECTION.has(field)),
  );
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
    specialNeeds: doc.specialNeeds || doc.special_needs || '',
    role: doc.role || '',
    imageUrl: doc.imageUrl || '',
    createdAt: doc.createdAt || null,
    updatedAt: doc.updatedAt || null,
  };
}

function studentIsInAssignedGroups(student, identifiers) {
  return [
    student?.id,
    student?._id,
    student?.studentId,
    student?.admissionNo,
    student?.admissionNumber,
  ].some((value) => value != null && identifiers.has(String(value).trim()));
}

function databaseSort(left, right) {
  const createdAt = String(right.createdAt || '').localeCompare(String(left.createdAt || ''));
  if (createdAt !== 0) return createdAt;
  return String(right._id || '').localeCompare(String(left._id || ''));
}

function buildStudentsResponse({ role, documents, allowedStudentIds = [], databaseError = false }) {
  if (!['admin', 'staff'].includes(role)) {
    return { status: 403, body: { message: 'You are not authorized.' } };
  }
  if (databaseError) {
    return { status: 500, body: { message: 'Unable to load student information.' } };
  }

  let students = documents
    .map(projectStudent)
    .sort(databaseSort);
  if (role === 'staff') {
    const allowed = new Set(allowedStudentIds);
    students = students.filter((student) => studentIsInAssignedGroups(student, allowed));
  }
  return { status: 200, body: students.map(sanitizeStudentForResponse) };
}

const fullStudent = {
  _id: { toString: () => 'bson-student-1' },
  id: 'legacy-id-1',
  name: 'Synthetic Student',
  className: 'Class A',
  section: 'B',
  studentId: 'STU0001',
  admissionNumber: 'ADM0001',
  admissionNo: 'ADM0001',
  parentName: 'Synthetic Parent',
  mobileNumber: '0000000000',
  address: 'Synthetic Address',
  about: 'Synthetic About',
  hobbies: 'Synthetic Hobbies',
  specialNeeds: 'Preferred value',
  special_needs: 'Legacy value',
  role: 'student',
  imageUrl: 'https://example.invalid/student.png',
  createdAt: '2026-01-03T00:00:00.000Z',
  updatedAt: '2026-01-04T00:00:00.000Z',
  ignoredPrivateField: 'must not be transferred',
};

test('projection contains all 19 required fields including _id', () => {
  assert.equal(STUDENT_LIST_FIELDS.length, 19);
  assert.ok(STUDENT_LIST_PROJECTION.has('_id'));
  assert.deepEqual([...STUDENT_LIST_PROJECTION].sort(), [...STUDENT_LIST_FIELDS].sort());
});

test('live source uses the shared projection on the students collection read', () => {
  const serverSource = fs.readFileSync(path.resolve(__dirname, '..', 'server.js'), 'utf8');
  assert.match(
    serverSource,
    /studentInfoCollection\.find\(\{\}, \{ projection: STUDENT_LIST_PROJECTION \}\)\.sort\(\{ createdAt: -1, _id: -1 \}\)\.toArray\(\)/,
  );
  for (const field of STUDENT_LIST_FIELDS) {
    assert.match(serverSource, new RegExp(`\\b${field.replace('_', '\\_')}: 1`));
  }
});

test('admin receives the same sanitized records after projection', () => {
  const before = fullStudent;
  const after = projectStudent(fullStudent);
  assert.deepEqual(
    buildStudentsResponse({ role: 'admin', documents: [before] }).body,
    buildStudentsResponse({ role: 'admin', documents: [after] }).body,
  );
});

test('staff receives exactly the same authorized students for all five identifier variants', () => {
  const variants = [
    ['id', { id: 'variant-id' }],
    ['_id', { _id: 'variant-object-id' }],
    ['studentId', { studentId: 'variant-student-id' }],
    ['admissionNo', { admissionNo: 'variant-admission-no' }],
    ['admissionNumber', { admissionNumber: 'variant-admission-number' }],
  ];
  for (const [field, identity] of variants) {
    const document = { ...fullStudent, _id: undefined, id: undefined, ...identity };
    const response = buildStudentsResponse({
      role: 'staff',
      documents: [document, { ...fullStudent, studentId: `other-${field}` }],
      allowedStudentIds: [identity[field]],
    });
    assert.equal(response.status, 200, field);
    assert.equal(response.body.length, 1, field);
  }
});

test('legacy special_needs fallback and missing optional defaults remain unchanged', () => {
  const legacy = projectStudent({ _id: 'legacy', special_needs: 'Legacy need' });
  const missing = projectStudent({ _id: 'missing' });
  assert.equal(sanitizeStudentForResponse(legacy).specialNeeds, 'Legacy need');
  assert.deepEqual(sanitizeStudentForResponse(missing), {
    id: 'missing', name: '', className: '', section: '', studentId: '',
    admissionNumber: '', parentName: '', mobileNumber: '', address: '', about: '',
    hobbies: '', specialNeeds: '', role: '', imageUrl: '', createdAt: null, updatedAt: null,
  });
});

test('ID fallback and BSON conversion remain unchanged', () => {
  assert.equal(sanitizeStudentForResponse({ _id: { toString: () => 'object-id' }, id: 'legacy-id' }).id, 'object-id');
  assert.equal(sanitizeStudentForResponse({ id: 'legacy-id' }).id, 'legacy-id');
  assert.equal(sanitizeStudentForResponse({}).id, null);
});

test('sort and tie-breaking remain unchanged after projection', () => {
  const documents = [
    { ...fullStudent, _id: 'a', createdAt: '2026-01-01' },
    { ...fullStudent, _id: 'c', createdAt: '2026-01-01' },
    { ...fullStudent, _id: 'b', createdAt: '2026-01-02' },
  ];
  const before = documents.map(projectStudent).sort(databaseSort).map((item) => item._id);
  const after = documents.map(projectStudent).sort(databaseSort).map((item) => item._id);
  assert.deepEqual(after, before);
  assert.deepEqual(after, ['b', 'c', 'a']);
});

test('empty collection and route errors preserve the existing response shape', () => {
  assert.deepEqual(buildStudentsResponse({ role: 'admin', documents: [] }), { status: 200, body: [] });
  assert.deepEqual(buildStudentsResponse({ role: 'admin', documents: [], databaseError: true }), {
    status: 500,
    body: { message: 'Unable to load student information.' },
  });
  assert.ok(Array.isArray(buildStudentsResponse({ role: 'admin', documents: [fullStudent] }).body));
});

test('student role remains denied by the route authorization contract', () => {
  const response = buildStudentsResponse({ role: 'student', documents: [fullStudent] });
  assert.equal(response.status, 403);
});

test('projection does not add pagination, limits, or query filters to the route', () => {
  const serverSource = fs.readFileSync(path.resolve(__dirname, '..', 'server.js'), 'utf8');
  const route = serverSource.slice(serverSource.indexOf("app.get('/api/students',"), serverSource.indexOf("app.get('/api/students/profile',"));
  assert.match(route, /find\(\{\}, \{ projection: STUDENT_LIST_PROJECTION \}\)/);
  assert.match(route, /sort\(\{ createdAt: -1, _id: -1 \}\)/);
  assert.doesNotMatch(route, /\.limit\(|\.skip\(|page|cursor/);
});
