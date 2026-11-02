const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const { randomBytes } = require('node:crypto');

const { authorizeRequestRole } = require('../authorization');
const { createSplashRouter } = require('../splash_routes');
const { createAuthenticate, signAuthPayload } = require('../user_management');

const secret = randomBytes(32).toString('hex');
const users = new Map([
  ['student-1', { userId: 'student-1', role: 'student' }],
  ['admin-1', { userId: 'admin-1', role: 'admin' }],
]);
const authenticate = createAuthenticate({
  secret,
  loadUser: async (userId) => users.get(userId),
});

function authHeaders(userId, role) {
  const token = signAuthPayload({
    userId,
    role,
    exp: Math.floor(Date.now() / 1000) + 3600,
  }, secret);
  return { Authorization: `Bearer ${token}` };
}

function requireAdmin(req, res, next) {
  return authorizeRequestRole({
    req,
    res,
    next,
    authenticate,
    allowedRoles: ['admin'],
    normalizeRole: (role) => String(role || '').trim().toLowerCase(),
  });
}

async function createHarness() {
  const app = express();
  app.use(express.json());
  let document = {
    splashScreen: { title: 'Current title', image: 'current-image.png' },
    schoolSettings: { schoolName: 'School' },
  };
  const defaults = { splashScreen: { title: '', image: '' } };
  app.use('/api/mainpage-info/splash', createSplashRouter({
    express,
    requireAdmin,
    getMainPageDocument: async () => document,
    buildDefaultDocument: () => defaults,
    upsertMainPageDocument: async (updated) => {
      document = updated;
      return updated;
    },
  }));
  const server = app.listen(0);
  const address = server.address();
  return {
    baseUrl: `http://127.0.0.1:${address.port}`,
    close: () => new Promise((resolve, reject) =>
      server.close((error) => error ? reject(error) : resolve())),
  };
}

test('splash GET and PUT require an authenticated admin', async () => {
  const harness = await createHarness();
  try {
    const url = `${harness.baseUrl}/api/mainpage-info/splash`;
    assert.equal((await fetch(url)).status, 401);
    assert.equal((await fetch(url, { method: 'PUT' })).status, 401);

    const studentHeaders = authHeaders('student-1', 'student');
    assert.equal((await fetch(url, { headers: studentHeaders })).status, 403);
    assert.equal((await fetch(url, {
      method: 'PUT',
      headers: { ...studentHeaders, 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Unauthorized title' }),
    })).status, 403);

    const adminHeaders = authHeaders('admin-1', 'admin');
    const loaded = await fetch(url, { headers: adminHeaders });
    assert.equal(loaded.status, 200);
    assert.deepEqual(await loaded.json(), {
      splashScreen: { title: 'Current title', image: 'current-image.png' },
    });

    const updated = await fetch(url, {
      method: 'PUT',
      headers: { ...adminHeaders, 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'Updated title' }),
    });
    assert.equal(updated.status, 200);
    const payload = await updated.json();
    assert.equal(payload.splashScreen.title, 'Updated title');
    assert.equal(payload.splashScreen.image, 'current-image.png');
    assert.deepEqual(payload.schoolSettings, { schoolName: 'School' });
  } finally {
    await harness.close();
  }
});
