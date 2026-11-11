'use strict';

// Safe Phase 0 benchmark runner. It never writes to MongoDB and refuses the
// configured production host unless the caller explicitly changes the guard.
const fs = require('node:fs/promises');
const path = require('node:path');
const { performance } = require('node:perf_hooks');

const ROOT = path.resolve(__dirname, '..');
const BASE_URL = (process.env.BASELINE_BASE_URL || 'https://school-backend-staging.onrender.com').replace(/\/$/, '');
const TIMEOUT_MS = Number(process.env.BASELINE_TIMEOUT_MS || 30000);
const WARM_REQUESTS = Number(process.env.BASELINE_WARM_REQUESTS || 20);
const REQUEST_HEADERS = { Accept: 'application/json' };

const CASES = [
  { name: 'health', method: 'GET', path: '/health', auth: null, cacheable: true },
  { name: 'readiness', method: 'GET', path: '/ready', auth: null, cacheable: true },
  { name: 'login', method: 'POST', path: '/api/login', auth: 'login', cacheable: false },
  { name: 'admin-dashboard', method: 'GET', path: '/api/mainpage-info', auth: 'admin', cacheable: true },
  { name: 'staff-dashboard', method: 'GET', path: '/api/staff/profile', auth: 'staff', cacheable: false },
  { name: 'student-dashboard', method: 'GET', path: '/api/students/profile', auth: 'student', cacheable: false },
  { name: 'messages', method: 'GET', path: '/api/messages/inbox', auth: 'student', cacheable: false },
  { name: 'attendance', method: 'GET', path: '/api/student-attendance', auth: 'student', cacheable: false },
  { name: 'diary', method: 'GET', path: '/api/diary/student', auth: 'student', cacheable: false },
  { name: 'groups', method: 'GET', path: '/api/groups', auth: 'student', cacheable: true },
  { name: 'classes', method: 'GET', path: '/api/classes', auth: 'staff', cacheable: false },
  { name: 'resources', method: 'GET', path: '/api/school-resources', auth: 'student', cacheable: false },
  { name: 'image', method: 'GET', path: process.env.BASELINE_IMAGE_PATH || '', auth: null, cacheable: true },
];

function assertSafeTarget() {
  const hostname = new URL(BASE_URL).hostname.toLowerCase();
  const explicitlyDesignatedStagingHost = process.env.BASELINE_TARGET_ENV === 'staging'
    && hostname === String(process.env.BASELINE_STAGING_HOST || '').toLowerCase();
  const allowed = explicitlyDesignatedStagingHost
    || hostname === 'localhost'
    || hostname === '127.0.0.1'
    || hostname === '::1'
    || hostname.includes('staging');
  if (!allowed && process.env.ALLOW_PRODUCTION_BENCHMARK !== 'true') {
    throw new Error(`Refusing benchmark target ${hostname}. Use a staging/local URL and designate it with BASELINE_TARGET_ENV=staging plus BASELINE_STAGING_HOST.`);
  }
}

function percentile(values, p) {
  if (!values.length) return null;
  const ordered = [...values].sort((a, b) => a - b);
  const rank = Math.max(0, Math.ceil((p / 100) * ordered.length) - 1);
  return ordered[rank];
}

function round(value) {
  return value == null ? null : Number(value.toFixed(3));
}

function parseServerTiming(value) {
  const result = {};
  for (const item of String(value || '').split(',')) {
    const match = item.trim().match(/^([\w-]+);dur=([\d.]+)/);
    if (match) result[match[1]] = Number(match[2]);
  }
  return result;
}

function tokenFor(auth) {
  if (!auth) return null;
  if (auth === 'admin') return process.env.BASELINE_ADMIN_TOKEN || null;
  if (auth === 'staff') return process.env.BASELINE_STAFF_TOKEN || null;
  if (auth === 'student') return process.env.BASELINE_STUDENT_TOKEN || null;
  return null;
}

function loginPayload() {
  const identifier = process.env.BASELINE_LOGIN_IDENTIFIER;
  const password = process.env.BASELINE_LOGIN_PASSWORD;
  if (!identifier || !password) return null;
  return { identifier, email: identifier, username: identifier, password };
}

function skipReason(testCase) {
  if (!testCase.path) return 'No BASELINE_IMAGE_PATH supplied.';
  if (testCase.auth === 'login' && !loginPayload()) return 'Set BASELINE_LOGIN_IDENTIFIER and BASELINE_LOGIN_PASSWORD.';
  if (testCase.auth && !tokenFor(testCase.auth)) return `Set BASELINE_${testCase.auth.toUpperCase()}_TOKEN.`;
  return null;
}

async function request(testCase, conditionalTag) {
  const headers = { ...REQUEST_HEADERS, 'X-Baseline-Run': 'phase-0' };
  const token = tokenFor(testCase.auth);
  if (token) headers.Authorization = `Bearer ${token}`;
  if (conditionalTag) headers['If-None-Match'] = conditionalTag;

  const options = { method: testCase.method, headers, signal: AbortSignal.timeout(TIMEOUT_MS) };
  if (testCase.auth === 'login') {
    headers['Content-Type'] = 'application/json';
    options.body = JSON.stringify(loginPayload());
  }

  const started = performance.now();
  try {
    const response = await fetch(`${BASE_URL}${testCase.path}`, options);
    const payload = await response.arrayBuffer();
    const elapsed = performance.now() - started;
    const timing = parseServerTiming(response.headers.get('server-timing'));
    const backendMs = Number(response.headers.get('x-performance-total-ms')) || timing.app || null;
    const dbMs = Number(response.headers.get('x-performance-db-time-ms')) || timing.db || null;
    return {
      ok: response.status >= 200 && response.status < 400,
      status: response.status,
      clientTotalMs: round(elapsed),
      backendTotalMs: round(backendMs),
      networkOverheadMs: backendMs == null ? null : round(Math.max(0, elapsed - backendMs)),
      databaseMs: round(dbMs),
      applicationNonDatabaseMs: backendMs == null || dbMs == null ? null : round(Math.max(0, backendMs - dbMs)),
      databaseOperationCount: Number(response.headers.get('x-performance-db-operations')) || null,
      payloadBytes: payload.byteLength,
      requestId: response.headers.get('x-performance-request-id'),
      cacheControl: response.headers.get('cache-control'),
      etag: response.headers.get('etag'),
    };
  } catch (error) {
    return {
      ok: false,
      status: null,
      clientTotalMs: round(performance.now() - started),
      backendTotalMs: null,
      networkOverheadMs: null,
      databaseMs: null,
      applicationNonDatabaseMs: null,
      databaseOperationCount: null,
      payloadBytes: 0,
      requestId: null,
      error: error && error.name === 'TimeoutError' ? 'timeout' : (error && error.code) || 'request_failed',
    };
  }
}

function summarize(samples) {
  const successful = samples.filter((sample) => Number.isFinite(sample.clientTotalMs));
  const values = successful.map((sample) => sample.clientTotalMs);
  const errors = samples.filter((sample) => !sample.ok || (sample.status != null && sample.status >= 400)).length;
  const mean = values.length ? values.reduce((sum, value) => sum + value, 0) / values.length : null;
  const avgPayload = samples.length ? samples.reduce((sum, sample) => sum + (sample.payloadBytes || 0), 0) / samples.length : null;
  return {
    sampleCount: samples.length,
    httpErrors: errors,
    averageResponseMs: round(mean),
    p50ResponseMs: round(percentile(values, 50)),
    p95ResponseMs: round(percentile(values, 95)),
    p99ResponseMs: round(percentile(values, 99)),
    maximumResponseMs: values.length ? round(Math.max(...values)) : null,
    averagePayloadBytes: avgPayload == null ? null : Math.round(avgPayload),
  };
}

function csvEscape(value) {
  const text = value == null ? '' : String(value);
  return /[",\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function buildReport(result) {
  const lines = [
    '# Phase 0 Performance Baseline Report',
    '',
    `Generated: ${result.generatedAt}`,
    `Target: ${result.target}`,
    '',
    'This report contains measurements collected by the safe baseline runner. It does not claim a true cold start unless the first observed request happened after a service restart. Protected cases without an explicitly supplied staging token are skipped. No production endpoint was benchmarked by default.',
    '',
    '## Measurement status',
    '',
    `- Instrumented backend timing: ${result.instrumentedBackendTiming ? 'available' : 'not observed; response timing is client-side only'}`,
    `- MongoDB timing/count: ${result.mongoTimingObserved ? 'available on instrumented requests' : 'not observed'}`,
    `- Cache validation: ${result.cachedSamples > 0 ? `${result.cachedSamples} conditional-cache samples; ${result.cacheHitResponses} returned HTTP 304` : 'not available; no ETag/validator observed'}`,
    `- Skipped cases: ${result.skippedCases.length}`,
    '',
    '## Results',
    '',
    '| Case | Phase | Samples | p50 ms | p95 ms | p99 ms | Average ms | Max ms | HTTP errors | Avg payload bytes |',
    '|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|',
  ];
  for (const row of result.summaries) {
    const s = row.summary;
    lines.push(`| ${row.case} | ${row.phase} | ${s.sampleCount} | ${s.p50ResponseMs ?? 'n/a'} | ${s.p95ResponseMs ?? 'n/a'} | ${s.p99ResponseMs ?? 'n/a'} | ${s.averageResponseMs ?? 'n/a'} | ${s.maximumResponseMs ?? 'n/a'} | ${s.httpErrors} | ${s.averagePayloadBytes ?? 'n/a'} |`);
  }
  lines.push('', '## Bottleneck evidence', '', '- Client total time is the complete request duration measured from the benchmark workstation.', '- Backend total time is read from `Server-Timing: app` when staging instrumentation is enabled.', '- Database time and operation count are read from staging-only instrumentation headers when available.', '- Network overhead is an estimate of client total minus backend total and includes transport, proxy, and scheduling effects.', '- A 404/401/403 is recorded as an HTTP error, not hidden or treated as a successful performance result.', '', '## Skipped and blocked cases', '');
  for (const item of result.skippedCases) lines.push(`- ${item.case} (${item.method} ${item.path}): ${item.reason}`);
  if (!result.skippedCases.length) lines.push('- None.');
  lines.push('', '## Flutter profile-mode collection instructions', '', 'Run these on a representative physical Android device or emulator against staging:', '', '```powershell', 'flutter pub get', 'flutter run --profile --dart-define=API_ENV=staging', '```', '', 'Collect DevTools Timeline and Performance Overlay traces for: startup, login, each role dashboard, route transition, messages, attendance, diary, resources, and image-heavy screens. Record first-frame time, time-to-useful-content, route transition time, frame build/raster jank, JSON decode time, image decode time, and memory. No Flutter profile timings were collected automatically by this server-side runner.', '', '## Static bottleneck findings', '', 'These are source-level findings, not measured protected-endpoint timings:', '', '1. `GET /api/campaign-performance` loads student records and sorts performance data in Node.js.', '2. `GET /api/messages/inbox` reads multiple message sources and merges/sorts in application memory.', '3. Groups, attendance, diary, messages, resources, news, announcements, and events contain list reads materialized with `toArray()` without a consistently visible limit/cursor/projection.', '4. Login searches multiple identifier fields and role credential collections, with legacy fallback reads.', '5. Dashboard profile loading waits on `AppState.initialization` before requesting profile data.', '6. Flutter uses both `Image.network` and `CachedNetworkImage`, producing inconsistent image-cache behavior.', '7. Duplicate runtime requests cannot be confirmed without authenticated dashboard traces; the benchmark records each request independently and does not invent duplicate counts.', '', '## Next gate', '', 'Provide staging-only login credentials, role tokens, and an optional image path through environment variables, then rerun this benchmark. Do not proceed to Phase 1 optimizations until the protected baseline is reviewed and approved.');
  return `${lines.join('\n')}\n`;
}

async function main() {
  assertSafeTarget();
  const generatedAt = new Date().toISOString();
  const samples = [];
  const summaries = [];
  const skippedCases = [];
  let instrumentedBackendTiming = false;
  let mongoTimingObserved = false;
  let cachedSamples = 0;
  let cacheHitResponses = 0;

  for (const testCase of CASES) {
    const reason = skipReason(testCase);
    if (reason) {
      skippedCases.push({ case: testCase.name, method: testCase.method, path: testCase.path, reason });
      continue;
    }

    const first = await request(testCase);
    samples.push({ case: testCase.name, phase: 'cold-observed', iteration: 1, ...first });
    if (first.backendTotalMs != null) instrumentedBackendTiming = true;
    if (first.databaseMs != null || first.databaseOperationCount != null) mongoTimingObserved = true;
    const warm = [];
    for (let i = 1; i <= WARM_REQUESTS; i += 1) {
      const sample = await request(testCase);
      warm.push(sample);
      samples.push({ case: testCase.name, phase: 'warm', iteration: i, ...sample });
      if (sample.backendTotalMs != null) instrumentedBackendTiming = true;
      if (sample.databaseMs != null || sample.databaseOperationCount != null) mongoTimingObserved = true;
    }
    summaries.push({ case: testCase.name, phase: 'cold-observed', summary: summarize([first]) });
    summaries.push({ case: testCase.name, phase: 'warm', summary: summarize(warm) });

    if (testCase.cacheable && first.etag) {
      const cached = [];
      for (let i = 1; i <= WARM_REQUESTS; i += 1) {
        const sample = await request(testCase, first.etag);
        cached.push(sample);
        cachedSamples += 1;
        if (sample.status === 304) cacheHitResponses += 1;
        samples.push({ case: testCase.name, phase: 'cached-conditional', iteration: i, ...sample });
      }
      summaries.push({ case: testCase.name, phase: 'cached-conditional', summary: summarize(cached) });
    }
  }

  const result = {
    generatedAt,
    target: BASE_URL,
    instrumentedBackendTiming,
    mongoTimingObserved,
    cachedSamples,
    cacheHitResponses,
    skippedCases,
    samples,
    summaries,
  };
  const csvHeader = ['case', 'phase', 'iteration', 'status', 'ok', 'clientTotalMs', 'backendTotalMs', 'networkOverheadMs', 'databaseMs', 'applicationNonDatabaseMs', 'databaseOperationCount', 'payloadBytes', 'requestId', 'error'];
  const csvRows = [csvHeader.join(','), ...samples.map((sample) => csvHeader.map((field) => csvEscape(sample[field])).join(','))];
  await Promise.all([
    fs.writeFile(path.join(ROOT, 'performance-baseline.json'), `${JSON.stringify(result, null, 2)}\n`, 'utf8'),
    fs.writeFile(path.join(ROOT, 'performance-baseline.csv'), `${csvRows.join('\n')}\n`, 'utf8'),
    fs.writeFile(path.join(ROOT, 'PERFORMANCE_BASELINE_REPORT.md'), buildReport(result), 'utf8'),
  ]);
  console.log(`Baseline written: ${samples.length} samples, ${skippedCases.length} skipped cases.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
