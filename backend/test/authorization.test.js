const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { randomBytes } = require('node:crypto');

const { authorizeRequestRole, isRecordOwner } = require('../authorization');
const { createAuthenticate, signAuthPayload } = require('../user_management');

const secret = randomBytes(32).toString('hex');
const users = new Map([
  ['student-1', { userId: 'student-1', role: 'student' }],
  ['staff-1', { userId: 'staff-1', role: 'staff' }],
  ['admin-1', { userId: 'admin-1', role: 'admin' }],
]);
const records = new Map([
  ['record-1', { studentId: 'student-1' }],
  ['record-2', { studentId: 'student-2' }],
]);
const employeeAttendance = new Map([
  ['attendance-1', { employeeId: 'staff-1' }],
  ['attendance-2', { employeeId: 'staff-2' }],
]);

function authToken(userId, role, expiresAt = Math.floor(Date.now() / 1000) + 3600) {
  return signAuthPayload({ userId, role, exp: expiresAt }, secret);
}

function bearerHeaders(userId, role) {
  return { Authorization: ['Bearer', authToken(userId, role)].join(' ') };
}

const authenticate = createAuthenticate({
  secret,
  loadUser: async (userId) => users.get(userId),
});

function requireRole(allowedRoles) {
  return (req, res, next) => authorizeRequestRole({
    req,
    res,
    next,
    authenticate,
    allowedRoles,
    normalizeRole: (role) => String(role || '').trim().toLowerCase(),
  });
}

async function createHarness() {
  const app = express();
  app.use(express.json());
  app.post('/admin-operation', requireRole(['admin']), (_req, res) => {
    res.status(204).end();
  });
  app.get('/records/:id', requireRole(['student', 'admin']), (req, res) => {
    const record = records.get(req.params.id);
    if (!record) return res.status(404).end();
    if (req.auth.role !== 'admin' && !isRecordOwner(req.auth, record, ['studentId'])) {
      return res.status(403).json({ message: 'Record access denied.' });
    }
    return res.json({ id: req.params.id });
  });
  app.get('/api/students/:id', requireRole(['admin', 'staff', 'student']), (req, res) => {
    const record = records.get(req.params.id);
    if (!record) return res.status(404).end();
    if (req.auth.role === 'student' &&
        !isRecordOwner(req.auth, record, ['studentId'])) {
      return res.status(403).json({ message: 'Student access denied.' });
    }
    return res.json({ id: req.params.id });
  });
  app.post('/api/students', requireRole(['admin']), (_req, res) => res.sendStatus(201));
  app.put('/api/students/:id', requireRole(['admin']), (_req, res) => res.sendStatus(200));
  app.delete('/api/students/:id', requireRole(['admin']), (_req, res) => res.sendStatus(200));
  app.get('/api/medical-events', requireRole(['admin']), (_req, res) => res.json([]));
  app.get('/api/medical-events/:id', requireRole(['admin']), (_req, res) => res.json({ id: 'event-1' }));
  app.post('/api/medical-events', requireRole(['admin']), (_req, res) => res.sendStatus(201));
  app.put('/api/medical-events/:id', requireRole(['admin']), (_req, res) => res.sendStatus(200));
  app.delete('/api/medical-events/:id', requireRole(['admin']), (_req, res) => res.sendStatus(200));
  app.get('/api/employee-attendance', requireRole(['admin', 'staff']), (req, res) => {
    const entries = [...employeeAttendance.entries()]
      .filter(([, record]) => req.auth.role === 'admin' || record.employeeId === req.auth.userId)
      .map(([id]) => ({ id }));
    return res.json(entries);
  });
  app.get('/api/employee-attendance/:id', requireRole(['admin', 'staff']), (req, res) => {
    const record = employeeAttendance.get(req.params.id);
    if (!record) return res.status(404).end();
    if (req.auth.role !== 'admin' &&
        record.employeeId !== req.auth.userId) {
      return res.status(403).json({ message: 'Attendance access denied.' });
    }
    return res.json({ id: req.params.id });
  });
  app.post('/api/employee-attendance', requireRole(['admin', 'staff']), (req, res) => {
    const employeeId = req.auth.role === 'admin' ? req.body?.employeeId : req.auth.userId;
    return res.status(201).json({ employeeId });
  });
  app.put('/api/employee-attendance/:id', requireRole(['admin', 'staff']), (req, res) => {
    const record = employeeAttendance.get(req.params.id);
    if (!record) return res.status(404).end();
    if (req.auth.role !== 'admin' &&
        (record.employeeId !== req.auth.userId ||
         req.body?.employeeId !== req.auth.userId)) {
      return res.status(403).json({ message: 'Attendance update denied.' });
    }
    return res.json({ id: req.params.id });
  });
  app.delete('/api/employee-attendance/:id', requireRole(['admin', 'staff']), (req, res) => {
    const record = employeeAttendance.get(req.params.id);
    if (!record) return res.status(404).end();
    if (req.auth.role !== 'admin' && record.employeeId !== req.auth.userId) {
      return res.status(403).json({ message: 'Attendance deletion denied.' });
    }
    return res.sendStatus(200);
  });
  app.patch('/api/employee-attendance/:id/approve', requireRole(['admin']), (_req, res) => res.sendStatus(204));
  app.patch('/api/employee-attendance/:id/late', requireRole(['admin']), (_req, res) => res.sendStatus(204));
  const server = app.listen(0);
  const address = server.address();
  return {
    baseUrl: `http://127.0.0.1:${address.port}`,
    close: () => new Promise((resolve, reject) =>
      server.close((error) => error ? reject(error) : resolve())),
  };
}

test('sensitive operations reject unauthenticated and invalid-token requests', async () => {
  const harness = await createHarness();
  try {
    const missing = await fetch(`${harness.baseUrl}/records/record-1`);
    assert.equal(missing.status, 401);

    const invalid = await fetch(`${harness.baseUrl}/admin-operation`, {
      method: 'POST',
      headers: { Authorization: 'Bearer invalid' },
    });
    assert.equal(invalid.status, 401);

    const expired = await fetch(`${harness.baseUrl}/records/record-1`, {
      headers: {
        Authorization: `Bearer ${authToken('student-1', 'student', Math.floor(Date.now() / 1000) - 1)}`,
      },
    });
    assert.equal(expired.status, 401);
  } finally {
    await harness.close();
  }
});

test('client-supplied role cannot grant admin privileges', async () => {
  const harness = await createHarness();
  try {
    const response = await fetch(`${harness.baseUrl}/admin-operation`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${authToken('student-1', 'student')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ role: 'admin' }),
    });
    assert.equal(response.status, 403);
  } finally {
    await harness.close();
  }
});

test('record access is scoped to the authenticated owner', async () => {
  const harness = await createHarness();
  try {
    const ownRecord = await fetch(`${harness.baseUrl}/records/record-1`, {
      headers: { Authorization: `Bearer ${authToken('student-1', 'student')}` },
    });
    assert.equal(ownRecord.status, 200, await ownRecord.clone().text());

    const otherRecord = await fetch(`${harness.baseUrl}/records/record-2`, {
      headers: { Authorization: `Bearer ${authToken('student-1', 'student')}` },
    });
    assert.equal(otherRecord.status, 403);

    const adminAccess = await fetch(`${harness.baseUrl}/records/record-2`, {
      headers: { Authorization: `Bearer ${authToken('admin-1', 'admin')}` },
    });
    assert.equal(adminAccess.status, 200);
  } finally {
    await harness.close();
  }
});

test('student API requires authentication and limits student reads to the owner', async () => {
  const harness = await createHarness();
  try {
    assert.equal((await fetch(`${harness.baseUrl}/api/students/record-1`)).status, 401);
    assert.equal((await fetch(`${harness.baseUrl}/api/students`, { method: 'POST' })).status, 401);
    assert.equal((await fetch(`${harness.baseUrl}/api/students/record-1`, {
      method: 'PUT',
    })).status, 401);

    const ownRecord = await fetch(`${harness.baseUrl}/api/students/record-1`, {
      headers: bearerHeaders('student-1', 'student'),
    });
    assert.equal(ownRecord.status, 200, await ownRecord.clone().text());

    const crossRecord = await fetch(`${harness.baseUrl}/api/students/record-2`, {
      headers: bearerHeaders('student-1', 'student'),
    });
    assert.equal(crossRecord.status, 403);

    const forbiddenWrite = await fetch(`${harness.baseUrl}/api/students`, {
      method: 'POST',
      headers: bearerHeaders('staff-1', 'staff'),
    });
    assert.equal(forbiddenWrite.status, 403);
    assert.equal((await fetch(`${harness.baseUrl}/api/students/record-1`, {
      method: 'PUT',
      headers: {
        ...bearerHeaders('staff-1', 'staff'),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ role: 'admin' }),
    })).status, 403);
  } finally {
    await harness.close();
  }
});

test('medical-event APIs require an authenticated administrator', async () => {
  const harness = await createHarness();
  try {
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events`)).status, 401);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events`, { method: 'POST' })).status, 401);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      method: 'PUT',
    })).status, 401);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      method: 'DELETE',
    })).status, 401);

    const forbiddenRead = await fetch(`${harness.baseUrl}/api/medical-events`, {
      headers: bearerHeaders('student-1', 'student'),
    });
    assert.equal(forbiddenRead.status, 403);
    const forbiddenRecordRead = await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      headers: bearerHeaders('student-1', 'student'),
    });
    assert.equal(forbiddenRecordRead.status, 403);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      method: 'PUT',
      headers: bearerHeaders('student-1', 'student'),
    })).status, 403);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      method: 'DELETE',
      headers: bearerHeaders('student-1', 'student'),
    })).status, 403);

    const authorizedRead = await fetch(`${harness.baseUrl}/api/medical-events`, {
      headers: bearerHeaders('admin-1', 'admin'),
    });
    assert.equal(authorizedRead.status, 200);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      headers: bearerHeaders('admin-1', 'admin'),
    })).status, 200);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      method: 'PUT',
      headers: bearerHeaders('admin-1', 'admin'),
    })).status, 200);
    assert.equal((await fetch(`${harness.baseUrl}/api/medical-events/event-1`, {
      method: 'DELETE',
      headers: bearerHeaders('admin-1', 'admin'),
    })).status, 200);

    const authorizedWrite = await fetch(`${harness.baseUrl}/api/medical-events`, {
      method: 'POST',
      headers: {
        ...bearerHeaders('admin-1', 'admin'),
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ studentId: 'student-2' }),
    });
    assert.equal(authorizedWrite.status, 201);
  } finally {
    await harness.close();
  }
});

test('employee attendance is owner-scoped and approval is administrator-only', async () => {
  const harness = await createHarness();
  try {
    assert.equal((await fetch(`${harness.baseUrl}/api/employee-attendance`)).status, 401);
    assert.equal((await fetch(`${harness.baseUrl}/api/employee-attendance/attendance-1`)).status, 401);
    assert.equal((await fetch(`${harness.baseUrl}/api/employee-attendance`, {
      method: 'POST',
    })).status, 401);

    const ownRecord = await fetch(`${harness.baseUrl}/api/employee-attendance/attendance-1`, {
      headers: bearerHeaders('staff-1', 'staff'),
    });
    assert.equal(ownRecord.status, 200);
    const list = await fetch(`${harness.baseUrl}/api/employee-attendance`, {
      headers: bearerHeaders('staff-1', 'staff'),
    });
    assert.deepEqual(await list.json(), [{ id: 'attendance-1' }]);

    const crossRecord = await fetch(`${harness.baseUrl}/api/employee-attendance/attendance-2`, {
      headers: bearerHeaders('staff-1', 'staff'),
    });
    assert.equal(crossRecord.status, 403);

    const crossEmployeeUpdate = await fetch(
      `${harness.baseUrl}/api/employee-attendance/attendance-2`,
      {
        method: 'PUT',
        headers: {
          ...bearerHeaders('staff-1', 'staff'),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ employeeId: 'staff-2' }),
      },
    );
    assert.equal(crossEmployeeUpdate.status, 403);
    const spoofedCreate = await fetch(
      `${harness.baseUrl}/api/employee-attendance`,
      {
        method: 'POST',
        headers: {
          ...bearerHeaders('staff-1', 'staff'),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ employeeId: 'staff-2', role: 'admin' }),
      },
    );
    assert.equal(spoofedCreate.status, 201);
    assert.equal((await spoofedCreate.json()).employeeId, 'staff-1');
    const crossEmployeeDelete = await fetch(
      `${harness.baseUrl}/api/employee-attendance/attendance-2`,
      {
        method: 'DELETE',
        headers: bearerHeaders('staff-1', 'staff'),
      },
    );
    assert.equal(crossEmployeeDelete.status, 403);

    const forbiddenApproval = await fetch(
      `${harness.baseUrl}/api/employee-attendance/attendance-1/approve`,
      {
        method: 'PATCH',
        headers: bearerHeaders('staff-1', 'staff'),
      },
    );
    assert.equal(forbiddenApproval.status, 403);
    assert.equal((await fetch(
      `${harness.baseUrl}/api/employee-attendance/attendance-1/late`,
      {
        method: 'PATCH',
        headers: bearerHeaders('staff-1', 'staff'),
      },
    )).status, 403);

    const authorizedApproval = await fetch(
      `${harness.baseUrl}/api/employee-attendance/attendance-1/approve`,
      {
        method: 'PATCH',
        headers: bearerHeaders('admin-1', 'admin'),
      },
    );
    assert.equal(authorizedApproval.status, 204);
    assert.equal((await fetch(
      `${harness.baseUrl}/api/employee-attendance/attendance-1/late`,
      {
        method: 'PATCH',
        headers: bearerHeaders('admin-1', 'admin'),
      },
    )).status, 204);
  } finally {
    await harness.close();
  }
});
