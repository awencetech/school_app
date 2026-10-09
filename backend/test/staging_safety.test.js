const test = require('node:test');
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');

const {
  createMongoReadinessHandler,
  runStartupDatabaseSetup,
  uploadGroupPhotoToGridFS,
} = require('../staging_safety');

test('startup database setup is skipped unless the setting is exactly true', async () => {
  for (const setting of [undefined, '', 'false', 'FALSE', 'True', '1']) {
    const calls = [];
    const enabled = await runStartupDatabaseSetup(setting, {
      ensureIndexes: async () => calls.push('indexes'),
      migrations: [async () => calls.push('migration')],
    });

    assert.equal(enabled, false, `setting ${String(setting)}`);
    assert.deepEqual(calls, [], `setting ${String(setting)}`);
  }
});

test('startup database setup runs index setup and migrations only for exact true', async () => {
  const calls = [];
  const enabled = await runStartupDatabaseSetup('true', {
    ensureIndexes: async () => calls.push('indexes'),
    migrations: [
      async () => calls.push('credentials'),
      async () => calls.push('legacy-data'),
    ],
  });

  assert.equal(enabled, true);
  assert.deepEqual(calls, ['indexes', 'credentials', 'legacy-data']);
});

function createResponse() {
  return {
    statusCode: 200,
    body: undefined,
    status(statusCode) {
      this.statusCode = statusCode;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
}

test('readiness returns 503 when MongoDB is not initialized', async () => {
  const handler = createMongoReadinessHandler(() => null, 'test-db');
  const response = createResponse();

  await handler({}, response);

  assert.equal(response.statusCode, 503);
  assert.deepEqual(response.body, { status: 'not_ready' });
});

test('readiness returns 503 when MongoDB ping fails', async () => {
  const handler = createMongoReadinessHandler(() => ({
    db: () => ({ command: async () => { throw new Error('unavailable'); } }),
  }), 'test-db');
  const response = createResponse();

  await handler({}, response);

  assert.equal(response.statusCode, 503);
  assert.deepEqual(response.body, { status: 'not_ready' });
});

test('readiness returns 200 after a successful MongoDB ping', async () => {
  let ping;
  const handler = createMongoReadinessHandler(() => ({
    db: (name) => ({
      command: async (command) => { ping = { name, command }; },
    }),
  }), 'test-db');
  const response = createResponse();

  await handler({}, response);

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, { status: 'ready' });
  assert.deepEqual(ping, { name: 'test-db', command: { ping: 1 } });
});

test('failed group-photo GridFS upload does not produce a URL', async () => {
  const uploadStream = new EventEmitter();
  uploadStream.id = 'unsaved-file';
  uploadStream.end = () => {
    queueMicrotask(() => uploadStream.emit('error', new Error('GridFS unavailable')));
  };
  const bucket = { openUploadStream: () => uploadStream };
  let generatedUrl = false;

  await assert.rejects(
    uploadGroupPhotoToGridFS(
      bucket,
      { originalname: 'photo.png', mimetype: 'image/png', buffer: Buffer.from('test') },
      () => {
        generatedUrl = true;
        return '/uploads/unsaved-photo.png';
      },
    ),
    /GridFS unavailable/,
  );

  assert.equal(generatedUrl, false);
});
