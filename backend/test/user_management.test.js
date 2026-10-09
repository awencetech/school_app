const test = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcrypt');
const express = require('express');
const { randomBytes, randomUUID } = require('node:crypto');

const {
  createAuthenticate,
  createUserManagementRouter,
  signAuthPayload,
} = require('../user_management');

const secret = randomBytes(32).toString('hex');
const accounts = {
  admin: { userId: randomUUID(), email: `${randomUUID()}@example.invalid` },
  student: { userId: randomUUID(), email: `${randomUUID()}@example.invalid` },
  otherStudent: {
    userId: randomUUID(),
    email: `${randomUUID()}@example.invalid`,
  },
};
const passwords = {
  existing: makeTestPassword(),
  provision: makeTestPassword(),
  changed: makeTestPassword(),
  old: makeTestPassword(),
  next: makeTestPassword(),
};

function makeTestPassword() {
  return `${randomBytes(24).toString('hex')}A1!`;
}

async function createHarness() {
  const existingPasswordHash = await bcrypt.hash(passwords.existing, 10);
  const schoolRecords = new Map([
    [accounts.admin.userId, { studentOrStaffProfile: true }],
    [accounts.student.userId, { studentOrStaffProfile: true }],
    [accounts.otherStudent.userId, { studentOrStaffProfile: true }],
  ]);
  const users = new Map([
    [
      accounts.admin.userId,
      {
        _id: randomUUID(),
        ...accounts.admin,
        role: 'admin',
        password: existingPasswordHash,
      },
    ],
    [
      accounts.student.userId,
      {
        _id: randomUUID(),
        ...accounts.student,
        role: 'student',
        password: existingPasswordHash,
      },
    ],
    [
      accounts.otherStudent.userId,
      {
        _id: randomUUID(),
        ...accounts.otherStudent,
        role: 'student',
        password: existingPasswordHash,
      },
    ],
  ]);
  let sequence = 1;
  const repository = {
    async list(role) {
      return [...users.values()].filter((user) => !role || user.role === role);
    },
    async findById(id) {
      const user = users.get(id) || [...users.values()].find((entry) => entry._id === id);
      return user ? { credential: user, collection: 'credentials', legacy: false } : null;
    },
    async findByIdentity(userId, role) {
      return [...users.values()].find((user) => user.userId === userId && user.role === role) || null;
    },
    async findConflict(filter) {
      return [...users.values()].find((user) =>
        Object.entries(filter).every(([key, value]) => user[key] === value)) || null;
    },
    async create(user) {
      const created = { ...user, _id: `db-created-${sequence++}` };
      users.set(created.userId, created);
      return created;
    },
    async update(found, updates) {
      Object.assign(found.credential, updates);
      return found.credential;
    },
    async remove(found) {
      users.delete(found.credential.userId);
    },
  };
  const authenticate = createAuthenticate({ secret, loadUser: repository.findByIdentity });
  const app = express();
  app.use(express.json());
  app.use('/api/users', createUserManagementRouter({
    express,
    authenticate,
    repository,
    bcrypt,
  }));
  app.use((error, _req, res, _next) => {
    res.status(500).json({ message: 'Unexpected test error.' });
  });

  return { app, repository, users, schoolRecords };
}

async function withServer(app, callback) {
  const server = app.listen(0);
  try {
    const address = server.address();
    await callback(`http://127.0.0.1:${address.port}`);
  } finally {
    await new Promise((resolve, reject) =>
      server.close((error) => error ? reject(error) : resolve()));
  }
}

function token(userId, role, expiresAt = Math.floor(Date.now() / 1000) + 3600) {
  return signAuthPayload({ userId, role, exp: expiresAt }, secret);
}

function headers(userId, role) {
  return { Authorization: `Bearer ${token(userId, role)}`, 'Content-Type': 'application/json' };
}

test('user management denies unauthenticated CRUD and invalid or expired tokens', async () => {
  const { app } = await createHarness();
  await withServer(app, async (baseUrl) => {
    for (const [method, path] of [
      ['GET', '/api/users'],
      ['POST', '/api/users'],
      ['PUT', `/api/users/${accounts.student.userId}`],
      ['DELETE', `/api/users/${accounts.student.userId}`],
    ]) {
      const response = await fetch(`${baseUrl}${path}`, { method });
      assert.equal(response.status, 401, `${method} ${path}`);
    }

    for (const authorization of [
      'Bearer invalid-token',
      `Bearer ${token('student-1', 'student', Math.floor(Date.now() / 1000) - 1)}`,
    ]) {
      const response = await fetch(`${baseUrl}/api/users`, {
        headers: { Authorization: authorization },
      });
      assert.equal(response.status, 401);
    }
  });
});

test('ordinary users cannot create users, access other accounts, or change roles', async () => {
  const { app } = await createHarness();
  await withServer(app, async (baseUrl) => {
    const newUserId = randomUUID();
    const newUserEmail = `${randomUUID()}@example.invalid`;
    const create = await fetch(`${baseUrl}/api/users`, {
      method: 'POST',
      headers: headers(accounts.student.userId, 'student'),
      body: JSON.stringify({
        userId: newUserId,
        email: newUserEmail,
        password: passwords.provision,
        role: 'admin',
      }),
    });
    assert.equal(create.status, 403);

    const changeOtherPassword = await fetch(
      `${baseUrl}/api/users/${accounts.otherStudent.userId}`,
      {
      method: 'PUT',
      headers: headers(accounts.student.userId, 'student'),
      body: JSON.stringify({ password: passwords.changed }),
      },
    );
    assert.equal(changeOtherPassword.status, 403);

    const changeRole = await fetch(
      `${baseUrl}/api/users/${accounts.student.userId}`,
      {
      method: 'PUT',
      headers: headers(accounts.student.userId, 'student'),
      body: JSON.stringify({ role: 'admin' }),
      },
    );
    assert.equal(changeRole.status, 403);

    const deleteOther = await fetch(
      `${baseUrl}/api/users/${accounts.otherStudent.userId}`,
      {
      method: 'DELETE',
      headers: headers(accounts.student.userId, 'student'),
      },
    );
    assert.equal(deleteOther.status, 403);

    const deleteSelf = await fetch(
      `${baseUrl}/api/users/${accounts.student.userId}`,
      {
        method: 'DELETE',
        headers: headers(accounts.student.userId, 'student'),
      },
    );
    assert.equal(deleteSelf.status, 403);
  });
});

test('admins can provision and manage users without exposing password hashes', async () => {
  const { app, users } = await createHarness();
  await withServer(app, async (baseUrl) => {
    const newUserId = randomUUID();
    const newUserEmail = `${randomUUID()}@example.invalid`;
    const create = await fetch(`${baseUrl}/api/users`, {
      method: 'POST',
      headers: headers(accounts.admin.userId, 'admin'),
      body: JSON.stringify({
        userId: newUserId,
        email: newUserEmail,
        password: passwords.provision,
        role: 'student',
      }),
    });
    assert.equal(create.status, 201);
    const created = await create.json();
    assert.equal(created.userId, newUserId);
    assert.equal('password' in created, false);

    const stored = users.get(newUserId);
    assert.notEqual(stored.password, passwords.provision);
    assert.equal(await bcrypt.compare(passwords.provision, stored.password), true);

    const update = await fetch(
      `${baseUrl}/api/users/${accounts.otherStudent.userId}`,
      {
      method: 'PUT',
      headers: headers(accounts.admin.userId, 'admin'),
      body: JSON.stringify({ password: passwords.changed }),
      },
    );
    assert.equal(update.status, 200);
    assert.equal('password' in await update.json(), false);
    assert.equal(
      await bcrypt.compare(
        passwords.changed,
        users.get(accounts.otherStudent.userId).password,
      ),
      true,
    );

    const remove = await fetch(
      `${baseUrl}/api/users/${accounts.otherStudent.userId}`,
      {
      method: 'DELETE',
      headers: headers(accounts.admin.userId, 'admin'),
      },
    );
    assert.equal(remove.status, 200);
    const removalResult = await remove.json();
    assert.match(removalResult.message, /login credential deleted/i);
    assert.match(removalResult.message, /school records were not deleted/i);
    assert.equal(users.has(accounts.otherStudent.userId), false);
  });
});

test('admin deletion cannot remove own credential and deleted credentials invalidate tokens', async () => {
  const { app, users, schoolRecords } = await createHarness();
  await withServer(app, async (baseUrl) => {
    const selfDelete = await fetch(
      `${baseUrl}/api/users/${accounts.admin.userId}`,
      {
        method: 'DELETE',
        headers: headers(accounts.admin.userId, 'admin'),
      },
    );
    assert.equal(selfDelete.status, 409);
    assert.equal(users.has(accounts.admin.userId), true);

    const deleteOther = await fetch(
      `${baseUrl}/api/users/${accounts.otherStudent.userId}`,
      {
        method: 'DELETE',
        headers: headers(accounts.admin.userId, 'admin'),
      },
    );
    assert.equal(deleteOther.status, 200);

    const deletedCredentialToken = await fetch(
      `${baseUrl}/api/users/${accounts.otherStudent.userId}`,
      {
        headers: headers(accounts.otherStudent.userId, 'student'),
      },
    );
    assert.equal(deletedCredentialToken.status, 401);
    assert.equal(users.has(accounts.otherStudent.userId), false);
    assert.equal(schoolRecords.has(accounts.otherStudent.userId), true);
  });
});

test('ordinary users must verify their existing password to change it', async () => {
  const { app, users } = await createHarness();
  users.get(accounts.student.userId).password = await bcrypt.hash(
    passwords.old,
    10,
  );

  await withServer(app, async (baseUrl) => {
    const unauthorized = await fetch(
      `${baseUrl}/api/users/${accounts.student.userId}`,
      {
      method: 'PUT',
      headers: headers(accounts.student.userId, 'student'),
      body: JSON.stringify({ password: passwords.next }),
      },
    );
    assert.equal(unauthorized.status, 403);

    const authorized = await fetch(
      `${baseUrl}/api/users/${accounts.student.userId}`,
      {
      method: 'PUT',
      headers: headers(accounts.student.userId, 'student'),
      body: JSON.stringify({
        currentPassword: passwords.old,
        password: passwords.next,
      }),
      },
    );
    assert.equal(authorized.status, 200);
    assert.equal(
      await bcrypt.compare(
        passwords.next,
        users.get(accounts.student.userId).password,
      ),
      true,
    );
  });
});
