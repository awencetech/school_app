const assert = require('node:assert/strict');
const cors = require('cors');
const express = require('express');
const http = require('node:http');
const test = require('node:test');
const { createCorsMiddleware, parseAllowedOrigins } = require('../cors_middleware');

async function withServer(allowedOrigins, onRejectedOrigin, run) {
  const app = express();
  app.use(createCorsMiddleware({ cors, allowedOrigins, onRejectedOrigin }));
  app.post('/api/login', (_req, res) => {
    res.status(401).json({ message: 'Invalid email or password' });
  });
  app.get('/api/health', (_req, res) => res.sendStatus(200));

  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();

  try {
    await run(`http://127.0.0.1:${address.port}`);
  } finally {
    await new Promise((resolve, reject) => {
      server.close((error) => error ? reject(error) : resolve());
    });
  }
}

function request(baseUrl, path, method, headers) {
  return new Promise((resolve, reject) => {
    const req = http.request(new URL(path, baseUrl), { method, headers }, (res) => {
      res.resume();
      res.on('end', () => resolve(res));
    });
    req.on('error', reject);
    req.end();
  });
}

for (const origin of ['http://localhost:8000', 'http://127.0.0.1:8000']) {
  test(`allows preflight from ${origin}`, async () => {
    await withServer([], undefined, async (baseUrl) => {
      const response = await request(baseUrl, '/api/login', 'OPTIONS', {
        Origin: origin,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'content-type,authorization',
      });

      assert.equal(response.statusCode, 204);
      assert.equal(response.headers['access-control-allow-origin'], origin);
      for (const method of ['POST', 'GET', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']) {
        assert.match(response.headers['access-control-allow-methods'], new RegExp(`\\b${method}\\b`));
      }
      assert.match(response.headers['access-control-allow-headers'], /Content-Type/i);
      assert.match(response.headers['access-control-allow-headers'], /Authorization/i);
      assert.equal(response.headers['access-control-allow-credentials'], 'true');
    });
  });
}

test('allows an explicitly configured production origin', async () => {
  const productionOrigin = 'https://frontend.example.invalid';
  await withServer([productionOrigin], undefined, async (baseUrl) => {
    const response = await request(baseUrl, '/api/health', 'GET', {
      Origin: productionOrigin,
    });

    assert.equal(response.statusCode, 200);
    assert.equal(response.headers['access-control-allow-origin'], productionOrigin);
  });
});

test('rejects an unconfigured origin and logs only its origin and method', async () => {
  const logEntries = [];
  await withServer([], (...entry) => logEntries.push(entry), async (baseUrl) => {
    const response = await request(baseUrl, '/api/login', 'OPTIONS', {
      Origin: 'https://untrusted.example.invalid',
      'Access-Control-Request-Method': 'POST',
    });

    assert.equal(response.statusCode, 403);
    assert.equal(response.headers['access-control-allow-origin'], undefined);
    assert.deepEqual(logEntries, [['https://untrusted.example.invalid', 'OPTIONS']]);
  });
});

test('normalizes env-style CORS origins with a leading dash and whitespace', () => {
  const origins = parseAllowedOrigins('- http://localhost:8000, http://127.0.0.1:8000, https://example.com ');

  assert.deepEqual(origins, [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'https://example.com',
  ]);
});

test('does not use a wildcard origin when the request has no Origin header', async () => {
  await withServer([], undefined, async (baseUrl) => {
    const response = await request(baseUrl, '/api/health', 'GET', {});

    assert.equal(response.statusCode, 200);
    assert.equal(response.headers['access-control-allow-origin'], undefined);
  });
});

test('invalid credentials remain an authentication failure with CORS headers', async () => {
  await withServer(['http://localhost:8000'], undefined, async (baseUrl) => {
    const response = await request(baseUrl, '/api/login', 'POST', {
      Origin: 'http://localhost:8000',
      'Content-Type': 'application/json',
    });

    assert.equal(response.statusCode, 401);
    assert.equal(response.headers['access-control-allow-origin'], 'http://localhost:8000');
  });
});
