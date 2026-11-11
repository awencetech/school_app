'use strict';

const assert = require('node:assert/strict');
const http = require('node:http');
const test = require('node:test');
const express = require('express');
const {
  createMainPageInfoCacheMiddleware,
  filterMainPageInfoForUser,
} = require('../main_page_info_security');

function normalizeRole(value) {
  const role = String(value ?? '').trim().toLowerCase();
  if (role === 'teacher' || role === 'teachers') return 'staff';
  if (role === 'admins') return 'admin';
  if (role === 'students') return 'student';
  return role;
}

function startApp() {
  const app = express();
  app.use('/api/mainpage-info', createMainPageInfoCacheMiddleware());
  app.get('/api/mainpage-info', (req, res) => res.json({ ok: true }));

  const server = http.createServer(app);
  return new Promise((resolve) => server.listen(0, '127.0.0.1', () => resolve(server)));
}

function request(server, headers = {}) {
  const address = server.address();
  return new Promise((resolve, reject) => {
    const req = http.request({
      host: address.address,
      port: address.port,
      path: '/api/mainpage-info',
      method: 'GET',
      headers,
    }, (res) => {
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, body }));
    });
    req.on('error', reject);
    req.end();
  });
}

test('unauthenticated, admin, staff, and student responses are private and non-cacheable', async (t) => {
  const server = await startApp();
  t.after(() => server.close());

  for (const headers of [{}, { Authorization: 'Bearer synthetic-admin' }, { Authorization: 'Bearer synthetic-staff' }, { Authorization: 'Bearer synthetic-student' }]) {
    const response = await request(server, headers);
    assert.equal(response.statusCode, 200);
    assert.equal(response.headers['cache-control'], 'private, no-store');
    assert.equal(response.headers.etag, undefined);
  }
});

test('conditional requests do not return a role-dependent 304 response', async (t) => {
  const server = await startApp();
  t.after(() => server.close());

  const first = await request(server);
  assert.equal(first.statusCode, 200);
  assert.equal(first.headers.etag, undefined);

  const conditional = await request(server, { 'If-None-Match': 'W/"synthetic-validator"' });
  assert.equal(conditional.statusCode, 200);
  assert.equal(conditional.headers['cache-control'], 'private, no-store');
  assert.equal(conditional.headers.etag, undefined);
});

test('role filtering remains unchanged for unauthenticated and non-admin users', () => {
  const document = {
    title: 'Synthetic',
    gradePage: { adminOnly: true },
    schoolContent: { homeContent: [], gradePage: { adminOnly: true } },
  };

  const admin = filterMainPageInfoForUser(document, { role: 'admin' }, normalizeRole);
  assert.strictEqual(admin, document);
  assert.deepEqual(admin, document);

  for (const role of [undefined, 'staff', 'student']) {
    const visible = filterMainPageInfoForUser(document, role ? { role } : undefined, normalizeRole);
    assert.equal(visible.gradePage, undefined);
    assert.equal(visible.schoolContent.gradePage, undefined);
    assert.deepEqual(visible.schoolContent.homeContent, []);
    assert.equal(visible.title, 'Synthetic');
  }
});
