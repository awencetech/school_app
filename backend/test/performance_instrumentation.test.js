const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const http = require('node:http');
const fs = require('node:fs');
const test = require('node:test');
const express = require('express');
const { createPerformanceInstrumentation, isEnabled } = require('../performance_instrumentation');

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function withServer(routeFactory, callback) {
  const client = new EventEmitter();
  const instrumentation = createPerformanceInstrumentation({
    env: {
      PERFORMANCE_INSTRUMENTATION: 'true',
      PERFORMANCE_INSTRUMENTATION_ENV: 'staging',
    },
  });
  instrumentation.attachMongoClient(client);

  const app = express();
  app.use(instrumentation.middleware);
  routeFactory(app, client);
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  try {
    return await callback(server.address().port, client);
  } finally {
    await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  }
}

function getJson(port, path) {
  return new Promise((resolve, reject) => {
    const request = http.get({ host: '127.0.0.1', port, path }, (response) => {
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve({
        status: response.statusCode,
        headers: response.headers,
        body: Buffer.concat(chunks).toString('utf8'),
      }));
    });
    request.on('error', reject);
  });
}

test('staging gate enables instrumentation and production stays disabled', () => {
  assert.equal(isEnabled({ PERFORMANCE_INSTRUMENTATION: 'true', PERFORMANCE_INSTRUMENTATION_ENV: 'staging' }), true);
  assert.equal(isEnabled({ PERFORMANCE_INSTRUMENTATION: 'false', PERFORMANCE_INSTRUMENTATION_ENV: 'staging' }), false);
  assert.equal(isEnabled({ PERFORMANCE_INSTRUMENTATION: 'true', PERFORMANCE_INSTRUMENTATION_ENV: 'production' }), false);
  assert.equal(isEnabled({ PERFORMANCE_INSTRUMENTATION: 'true' }), false);
});

test('MongoClient construction enables command monitoring', () => {
  const source = fs.readFileSync(require.resolve('../server'), 'utf8');
  assert.match(source, /new MongoClient\(mongoUri,\s*\{\s*monitorCommands:\s*true\s*,?\s*\}\)/s);
});

test('counts ping, find, and aggregate operations with duration', async () => {
  await withServer((app, client) => {
    app.get('/probe', async (_request, response) => {
      for (const [commandName, requestId] of [['ping', 1], ['find', 2], ['aggregate', 3]]) {
        client.emit('commandStarted', { commandName, requestId });
        await delay(3);
        client.emit('commandSucceeded', { requestId });
      }
      response.json({ ok: true });
    });
  }, async (port) => {
    const result = await getJson(port, '/probe');
    assert.equal(result.status, 200);
    assert.equal(result.headers['x-performance-db-operations'], '3');
    assert.ok(Number(result.headers['x-performance-db-time-ms']) > 0);
    assert.match(result.headers['server-timing'], /db;dur=/);
  });
});

test('failed command context is removed and does not count a later completion', async () => {
  await withServer((app, client) => {
    app.get('/probe', async (_request, response) => {
      client.emit('commandStarted', { commandName: 'ping', requestId: 10 });
      await delay(3);
      client.emit('commandFailed', { requestId: 10 });
      const beforeLateCompletion = Number(process.hrtime.bigint());
      client.emit('commandSucceeded', { requestId: 10 });
      await delay(1);
      response.json({ beforeLateCompletion });
    });
  }, async (port) => {
    const result = await getJson(port, '/probe');
    assert.equal(result.status, 200);
    assert.equal(result.headers['x-performance-db-operations'], '1');
    assert.ok(Number(result.headers['x-performance-db-time-ms']) > 0);
  });
});

test('concurrent requests keep MongoDB timing state isolated', async () => {
  await withServer((app, client) => {
    app.get('/probe/:milliseconds', async (request, response) => {
      const requestId = Number(request.params.milliseconds);
      client.emit('commandStarted', { commandName: 'ping', requestId });
      await delay(requestId);
      client.emit('commandSucceeded', { requestId });
      response.json({ requestId });
    });
  }, async (port) => {
    const [shortRequest, longRequest] = await Promise.all([
      getJson(port, '/probe/5'),
      getJson(port, '/probe/25'),
    ]);
    assert.equal(shortRequest.headers['x-performance-db-operations'], '1');
    assert.equal(longRequest.headers['x-performance-db-operations'], '1');
    const shortDbMs = Number(shortRequest.headers['x-performance-db-time-ms']);
    const longDbMs = Number(longRequest.headers['x-performance-db-time-ms']);
    assert.ok(shortDbMs > 0);
    assert.ok(longDbMs > shortDbMs);
    assert.notEqual(shortRequest.headers['x-performance-request-id'], longRequest.headers['x-performance-request-id']);
  });
});

test('request ID is consistent across response timing headers', async () => {
  await withServer((app) => {
    app.get('/probe', (_request, response) => response.json({ ok: true }));
  }, async (port) => {
    const result = await getJson(port, '/probe');
    assert.equal(result.status, 200);
    assert.match(result.headers['x-performance-request-id'], /^[0-9a-f-]{36}$/);
    assert.ok(Number(result.headers['x-performance-total-ms']) >= 0);
    assert.match(result.headers['server-timing'], /^app;dur=[0-9.]+, db;dur=[0-9.]+$/);
  });
});

test('readiness-style ping completes before response headers are finalized', async () => {
  await withServer((app, client) => {
    app.get('/ready', async (_request, response) => {
      client.emit('commandStarted', { commandName: 'ping', requestId: 99 });
      await delay(5);
      client.emit('commandSucceeded', { requestId: 99 });
      response.status(200).json({ status: 'ready' });
    });
  }, async (port) => {
    const result = await getJson(port, '/ready');
    assert.equal(result.status, 200);
    assert.equal(result.body, JSON.stringify({ status: 'ready' }));
    assert.equal(result.headers['x-performance-db-operations'], '1');
    assert.ok(Number(result.headers['x-performance-db-time-ms']) > 0);
  });
});
