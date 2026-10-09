function readBackendConfig(environment) {
  const nodeEnv = environment.NODE_ENV || 'development';
  const configuredDatabase = environment.MONGODB_DATABASE;
  const configuredPort = environment.PORT;

  return {
    nodeEnv,
    port: configuredPort === undefined || configuredPort === ''
      ? 3001
      : Number(configuredPort),
    mongoUri: environment.MONGODB_URI,
    mongoDatabase: configuredDatabase || (nodeEnv === 'production' ? '' : 'mainpage'),
    hasExplicitMongoDatabase: Boolean(configuredDatabase),
    runStartupMigrations: environment.RUN_STARTUP_MIGRATIONS,
  };
}

function validateBackendConfig(config) {
  if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }
  if (config.nodeEnv === 'production' && !config.hasExplicitMongoDatabase) {
    throw new Error('MONGODB_DATABASE must be explicitly configured in production.');
  }
  if (config.mongoDatabase === 'mmhs_staging' &&
      config.runStartupMigrations !== 'false') {
    throw new Error('RUN_STARTUP_MIGRATIONS must be exactly false for mmhs_staging.');
  }
}

function validateMongoUri(uri) {
  if (typeof uri !== 'string' || !uri.trim()) {
    throw new Error('MongoDB URI is not configured');
  }

  let parsed;
  try {
    parsed = new URL(uri);
  } catch (_error) {
    throw new Error('MONGODB_URI is malformed.');
  }

  if (!['mongodb:', 'mongodb+srv:'].includes(parsed.protocol) || !parsed.hostname) {
    throw new Error('MONGODB_URI must contain a MongoDB scheme and hostname.');
  }
  if (parsed.protocol === 'mongodb+srv:' && parsed.port) {
    throw new Error('MONGODB_URI must not specify a port when using mongodb+srv.');
  }

  return parsed;
}

function validateStagingMongoTarget(config) {
  if (config.mongoDatabase !== 'mmhs_staging') {
    throw new Error('Staging MongoDB diagnostic requires MONGODB_DATABASE=mmhs_staging.');
  }

  const parsed = validateMongoUri(config.mongoUri);
  if (parsed.hostname.toLowerCase() !== 'schoolapp1.gwlwksp.mongodb.net') {
    throw new Error('Staging MongoDB diagnostic refuses an unexpected cluster hostname.');
  }

  return config.mongoUri;
}

async function runStartupDatabaseSetup(setting, { ensureIndexes, migrations }) {
  if (setting !== 'true') return false;

  await ensureIndexes();
  for (const migration of migrations) {
    await migration();
  }
  return true;
}

function createMongoConnector({ getUri, initialize, onFailure }) {
  let connectionPromise;

  return async function connectMongo() {
    validateMongoUri(getUri());

    if (connectionPromise) return connectionPromise;
    connectionPromise = Promise.resolve()
      .then(initialize)
      .catch((error) => {
        connectionPromise = null;
        onFailure();
        throw error;
      });
    return connectionPromise;
  };
}

function describeMongoConnectionFailure(error) {
  const diagnostics = [];
  const pending = [error];
  const visited = new Set();

  while (pending.length > 0) {
    const current = pending.pop();
    if (!current || typeof current !== 'object' || visited.has(current)) continue;
    visited.add(current);
    diagnostics.push({
      code: current.code,
      codeName: current.codeName,
      name: current.name,
      message: String(current.message || ''),
    });
    if (current.cause) pending.push(current.cause);
    if (current.originalError) pending.push(current.originalError);
    if (current.reason && typeof current.reason === 'object') {
      pending.push(current.reason);
      if (current.reason.servers instanceof Map) {
        pending.push(...Array.from(current.reason.servers.values()));
      }
    }
  }

  const hasCode = (...codes) => diagnostics.some((entry) => codes.includes(entry.code));
  const hasName = (...names) => diagnostics.some((entry) => names.includes(entry.name));
  const hasCodeName = (...names) => diagnostics.some((entry) => names.includes(entry.codeName));
  const hasMessage = (pattern) => diagnostics.some((entry) => pattern.test(entry.message));

  if (hasCode(18) || hasCodeName('AuthenticationFailed') ||
      hasMessage(/\bbad auth\b|authentication failed/i)) {
    return 'MongoDB authentication was rejected. Verify the Atlas database username, password, auth database, and URL-encoding of reserved password characters. URI and error details withheld.';
  }
  if (hasCode('ENOTFOUND', 'EAI_AGAIN') || hasMessage(/getaddrinfo|dns lookup/i)) {
    return 'MongoDB DNS resolution failed. Verify the Atlas hostname and DNS/network configuration. URI and error details withheld.';
  }
  if (hasCode('CERT_HAS_EXPIRED', 'ERR_TLS_CERT_ALTNAME_INVALID', 'DEPTH_ZERO_SELF_SIGNED_CERT') ||
      hasMessage(/TLS handshake|certificate verify|certificate has expired/i)) {
    return 'MongoDB TLS validation failed. Verify runtime certificate trust and TLS interception settings. URI and error details withheld.';
  }
  if (hasCode('ETIMEDOUT', 'ESOCKETTIMEDOUT') ||
      hasMessage(/timed?\s*out|server selection.*timeout/i)) {
    return 'MongoDB connection timed out. Verify Atlas network access and Render egress configuration. URI and error details withheld.';
  }
  if (hasCode('ECONNREFUSED', 'ECONNRESET', 'ENETUNREACH', 'EHOSTUNREACH') ||
      hasName('MongoNetworkError')) {
    return 'MongoDB network connection failed. Verify Atlas network access and Render egress configuration. URI and error details withheld.';
  }

  return 'MongoDB connection failed. Verify Render environment settings, Atlas network access, and MongoDB availability. URI and error details withheld.';
}

function createMongoReadinessHandler(getClient, databaseName) {
  return async (_req, res) => {
    const client = getClient();
    if (!client) {
      return res.status(503).json({ status: 'not_ready' });
    }

    try {
      await client.db(databaseName).command({ ping: 1 });
      return res.status(200).json({ status: 'ready' });
    } catch (_error) {
      console.warn('MongoDB readiness ping failed.');
      return res.status(503).json({ status: 'not_ready' });
    }
  };
}

async function uploadGroupPhotoToGridFS(imageBucket, file, createUrl) {
  if (!imageBucket) {
    throw new Error('GridFS bucket is not initialized');
  }

  const uploadStream = imageBucket.openUploadStream(file.originalname, {
    metadata: { contentType: file.mimetype },
  });

  await new Promise((resolve, reject) => {
    uploadStream.on('finish', resolve);
    uploadStream.on('error', reject);
    uploadStream.end(file.buffer);
  });

  return createUrl(uploadStream.id);
}

module.exports = {
  createMongoReadinessHandler,
  createMongoConnector,
  describeMongoConnectionFailure,
  readBackendConfig,
  runStartupDatabaseSetup,
  uploadGroupPhotoToGridFS,
  validateBackendConfig,
  validateMongoUri,
  validateStagingMongoTarget,
};
