'use strict';

const { AsyncLocalStorage } = require('node:async_hooks');
const { appendFile } = require('node:fs/promises');
const { randomUUID } = require('node:crypto');

const DB_COMMANDS = new Set([
  'aggregate', 'bulkWrite', 'count', 'countDocuments', 'delete', 'distinct', 'ping',
  'find', 'findAndModify', 'getMore', 'insert', 'update', 'findOneAndUpdate',
]);

function isEnabled(env = process.env) {
  return env.PERFORMANCE_INSTRUMENTATION === 'true'
    && env.PERFORMANCE_INSTRUMENTATION_ENV === 'staging';
}

function elapsedMs(start) {
  return Number(process.hrtime.bigint() - start) / 1e6;
}

function byteLength(chunk, encoding) {
  if (chunk == null) return 0;
  if (Buffer.isBuffer(chunk)) return chunk.length;
  if (chunk instanceof Uint8Array) return chunk.byteLength;
  return Buffer.byteLength(String(chunk), encoding);
}

function safeEndpoint(req) {
  const routePath = req.route && req.route.path;
  return String(routePath ? `${req.baseUrl || ''}${routePath}` : req.path || '/');
}

function createPerformanceInstrumentation({ env = process.env, logPath = env.PERFORMANCE_INSTRUMENTATION_LOG } = {}) {
  const enabled = isEnabled(env);
  const requestContext = new AsyncLocalStorage();
  const commandContexts = new Map();

  async function writeRecord(record) {
    if (!logPath) return;
    try {
      await appendFile(logPath, `${JSON.stringify(record)}\n`, 'utf8');
    } catch (error) {
      console.warn(`Performance instrumentation log write failed: ${error && error.code ? error.code : 'unknown'}`);
    }
  }

  function buildRecord(req, res, state) {
    return {
      timestamp: new Date().toISOString(),
      requestId: state.requestId,
      endpoint: safeEndpoint(req),
      method: req.method,
      status: res.statusCode,
      totalResponseTimeMs: Number(elapsedMs(state.startedAt).toFixed(3)),
      responsePayloadBytes: state.responseBytes,
      mongoOperationCount: state.mongoOperationCount,
      mongoExecutionTimeMs: Number(state.mongoExecutionTimeMs.toFixed(3)),
    };
  }

  function setResponseHeaders(res, state) {
    if (res.headersSent) return;
    const totalMs = elapsedMs(state.startedAt);
    res.setHeader('X-Performance-Request-Id', state.requestId);
    res.setHeader('X-Performance-Total-Ms', totalMs.toFixed(3));
    res.setHeader('X-Performance-DB-Operations', String(state.mongoOperationCount));
    res.setHeader('X-Performance-DB-Time-Ms', state.mongoExecutionTimeMs.toFixed(3));
    res.setHeader('Server-Timing', `app;dur=${totalMs.toFixed(3)}, db;dur=${state.mongoExecutionTimeMs.toFixed(3)}`);
  }

  function middleware(req, res, next) {
    if (!enabled) return next();

    const state = {
      requestId: randomUUID(),
      startedAt: process.hrtime.bigint(),
      responseBytes: 0,
      mongoOperationCount: 0,
      mongoExecutionTimeMs: 0,
    };
    const originalWrite = res.write.bind(res);
    const originalEnd = res.end.bind(res);
    let recordWritten = false;

    res.write = (chunk, encoding, callback) => {
      state.responseBytes += byteLength(chunk, encoding);
      return originalWrite(chunk, encoding, callback);
    };
    res.end = (chunk, encoding, callback) => {
      state.responseBytes += byteLength(chunk, encoding);
      setResponseHeaders(res, state);
      return originalEnd(chunk, encoding, callback);
    };
    res.on('finish', () => {
      if (recordWritten) return;
      recordWritten = true;
      void writeRecord(buildRecord(req, res, state));
    });

    requestContext.run(state, () => next());
  }

  function attachMongoClient(client) {
    if (!enabled || !client || typeof client.on !== 'function') return;

    client.on('commandStarted', (event) => {
      if (!DB_COMMANDS.has(event.commandName)) return;
      const state = requestContext.getStore();
      if (!state) return;
      state.mongoOperationCount += 1;
      commandContexts.set(event.requestId, { state, startedAt: process.hrtime.bigint() });
    });

    const complete = (event) => {
      const context = commandContexts.get(event.requestId);
      if (!context) return;
      commandContexts.delete(event.requestId);
      context.state.mongoExecutionTimeMs += elapsedMs(context.startedAt);
    };
    client.on('commandSucceeded', complete);
    client.on('commandFailed', complete);
  }

  return {
    enabled,
    middleware,
    attachMongoClient,
    requestContext,
  };
}

module.exports = {
  createPerformanceInstrumentation,
  isEnabled,
};
