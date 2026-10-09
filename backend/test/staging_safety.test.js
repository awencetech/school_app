const test = require('node:test');
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');

const {
  createMongoReadinessHandler,
  createMongoConnector,
  describeMongoConnectionFailure,
  readBackendConfig,
  runStartupDatabaseSetup,
  uploadGroupPhotoToGridFS,
  validateBackendConfig,
  validateMongoUri,
  validateStagingMongoTarget,
} = require('../staging_safety');

test('backend configuration reads Render variables and preserves compatibility defaults', () => {
  const productionConfig = readBackendConfig({
    NODE_ENV: 'production',
    PORT: '10000',
    MONGODB_URI: 'mongodb+srv://test.invalid',
    MONGODB_DATABASE: 'mmhs_staging',
    RUN_STARTUP_MIGRATIONS: 'false',
  });
  assert.deepEqual(productionConfig, {
    nodeEnv: 'production',
    port: 10000,
    mongoUri: 'mongodb+srv://test.invalid',
    mongoDatabase: 'mmhs_staging',
    hasExplicitMongoDatabase: true,
    runStartupMigrations: 'false',
  });
  assert.doesNotThrow(() => validateBackendConfig(productionConfig));

  assert.deepEqual(readBackendConfig({}), {
    nodeEnv: 'development',
    port: 3001,
    mongoUri: undefined,
    mongoDatabase: 'mainpage',
    hasExplicitMongoDatabase: false,
    runStartupMigrations: undefined,
  });
});

test('production config cannot silently fall back to the mainpage database', () => {
  const config = readBackendConfig({ NODE_ENV: 'production' });
  assert.equal(config.mongoDatabase, '');
  assert.throws(() => validateBackendConfig(config), /MONGODB_DATABASE/);
});

test('staging config requires startup migrations to be explicitly disabled', () => {
  for (const setting of [undefined, 'true', 'FALSE', '0']) {
    const config = readBackendConfig({
      NODE_ENV: 'production',
      MONGODB_DATABASE: 'mmhs_staging',
      RUN_STARTUP_MIGRATIONS: setting,
    });
    assert.throws(() => validateBackendConfig(config), /RUN_STARTUP_MIGRATIONS/);
  }
});

test('MongoDB URI validation checks scheme, hostname, and SRV port rules', () => {
  assert.equal(
    validateMongoUri('mongodb+srv://user:encoded%40password@cluster.example.net/').hostname,
    'cluster.example.net',
  );
  assert.throws(() => validateMongoUri('https://cluster.example.net'), /MongoDB scheme/);
  assert.throws(() => validateMongoUri('not-a-uri'), /malformed/);
  assert.throws(() => validateMongoUri('mongodb+srv://cluster.example.net:27017'), /must not specify a port/);
});

test('staging diagnostic refuses any database or cluster except the expected staging target', () => {
  const uri = 'mongodb+srv://user:encoded%40password@schoolapp1.gwlwksp.mongodb.net/';
  assert.equal(validateStagingMongoTarget({
    mongoUri: uri,
    mongoDatabase: 'mmhs_staging',
  }), uri);
  assert.throws(() => validateStagingMongoTarget({
    mongoUri: uri,
    mongoDatabase: 'mainpage',
  }), /MONGODB_DATABASE=mmhs_staging/);
  assert.throws(() => validateStagingMongoTarget({
    mongoUri: 'mongodb+srv://cluster.example.net',
    mongoDatabase: 'mmhs_staging',
  }), /unexpected cluster hostname/);
});

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

test('MongoDB connection failure resets cached connection state and permits retry', async () => {
  let attempts = 0;
  let failures = 0;
  const connect = createMongoConnector({
    getUri: () => 'mongodb://localhost:27017',
    initialize: async () => {
      attempts += 1;
      if (attempts === 1) throw Object.assign(new Error('authentication failed'), { code: 18 });
      return 'initialized';
    },
    onFailure: () => { failures += 1; },
  });

  await assert.rejects(connect(), /authentication failed/);
  assert.equal(failures, 1);
  assert.equal(await connect(), 'initialized');
  assert.equal(attempts, 2);
});

test('MongoDB connection failure logs exclude URI, password, and raw error text', () => {
  const password = 'test-only-password-marker';
  const uri = `mongodb+srv://user:${password}@cluster.invalid`;
  const message = describeMongoConnectionFailure({
    code: 18,
    codeName: 'AuthenticationFailed',
    message: `bad auth ${password}; URI ${uri}`,
  });

  assert.match(message, /authentication was rejected/i);
  assert.match(message, /auth database/i);
  assert.doesNotMatch(message, new RegExp(password));
  assert.doesNotMatch(message, /cluster\.invalid|mongodb\+srv/i);
});

test('MongoDB failures are categorized without exposing raw error details', () => {
  const cases = [
    [{ code: 'ENOTFOUND', message: 'secret-host.example could not resolve' }, /DNS/],
    [{ code: 'ECONNRESET', message: 'socket reset' }, /network/i],
    [{ code: 'CERT_HAS_EXPIRED', message: 'secret certificate detail' }, /TLS/],
    [{ code: 'ETIMEDOUT', message: 'operation timed out' }, /timed out/i],
  ];

  for (const [error, expected] of cases) {
    const message = describeMongoConnectionFailure(error);
    assert.match(message, expected);
    assert.doesNotMatch(message, /secret-host|secret certificate detail/);
  }
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
