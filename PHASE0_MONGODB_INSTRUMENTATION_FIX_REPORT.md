# Phase 0 MongoDB Instrumentation Fix Report

Generated: 2026-11-11

Scope: telemetry-only correction for staging performance measurement. No Phase 1 optimization, deployment, push, database write, schema/index change, authentication change, API contract change, or UI change was performed.

## Result

Implemented and tested the two approved instrumentation corrections:

1. MongoDB command monitoring is enabled with `monitorCommands: true`.
2. The `ping` command is included in the monitored database-command allowlist.

The existing staging-only gate remains unchanged, and the readiness response implementation remains unchanged.

## Files changed

- [backend/server.js](./backend/server.js)
- [backend/performance_instrumentation.js](./backend/performance_instrumentation.js)
- [backend/test/performance_instrumentation.test.js](./backend/test/performance_instrumentation.test.js)

## Exact changes

### MongoDB command monitoring

In [initializeMongo](./backend/server.js:1840), the client construction now uses:

```js
client = new MongoClient(mongoUri, {
  monitorCommands: true,
});
```

There were no existing MongoClient options to preserve or overwrite. The existing URI, connection lifecycle, database selection, collection initialization, and readiness behavior are unchanged.

### Ping counting

In [backend/performance_instrumentation.js](./backend/performance_instrumentation.js), `ping` was added to `DB_COMMANDS`.

The existing event handling remains in place:

- `commandStarted` creates a command context and increments the request operation count.
- `commandSucceeded` completes and removes the command context.
- `commandFailed` completes and removes the command context.

The implementation continues to avoid logging command documents, query values, credentials, tokens, passwords, or personal data.

## Focused tests

Added [performance_instrumentation.test.js](./backend/test/performance_instrumentation.test.js) covering:

1. `ping` command count and duration.
2. `find` and `aggregate` command counting.
3. Failed command cleanup and late completion isolation.
4. Concurrent request isolation.
5. Staging-only instrumentation gate.
6. Production instrumentation disabled.
7. Request ID and response timing-header consistency.
8. Readiness-style ping timing captured before response headers finalize.
9. MongoClient source configuration includes `monitorCommands: true`.

Focused result: 7 tests passed, 0 failed.

## Complete backend test suite

Command:

```text
cd D:\education_app\backend
npm.cmd test
```

Result:

```text
41 tests passed
0 failed
0 cancelled
```

## Production safety verification

The existing gate in [isEnabled](./backend/performance_instrumentation.js:12) still requires both conditions:

```text
PERFORMANCE_INSTRUMENTATION=true
PERFORMANCE_INSTRUMENTATION_ENV=staging
```

The tests verify that instrumentation is disabled when:

- the instrumentation flag is false;
- the environment is production;
- the environment gate is missing.

No production environment variable or production deployment was changed. CORS, authentication, readiness responses, database data, indexes, and API contracts were not changed by this correction.

## Staging deployment instructions

Deployment was intentionally not performed.

After review approval:

1. Commit the three listed files in the authoritative root repository.
2. Push the approved commit to the configured staging branch.
3. Confirm Render uses the `backend` root and `npm start` entry point.
4. Confirm staging has the names `PERFORMANCE_INSTRUMENTATION` and `PERFORMANCE_INSTRUMENTATION_ENV` configured for the staging-only gate. Do not expose their values in reports or chat.
5. Wait for the staging deployment to become healthy.
6. Send a header-only GET to `/health` and `/ready`.
7. Confirm `/health` reports zero MongoDB operations.
8. Confirm `/ready` reports a captured `ping` operation and a nonzero database duration when the command event is observed.
9. Run one authorized, read-only protected GET using the existing safe benchmark configuration.
10. Confirm no credentials, tokens, query values, or personal data appear in instrumentation output.

Safe verification example:

```powershell
$base = 'https://school-app-1uep.onrender.com'
foreach ($path in @('/health', '/ready')) {
  $response = Invoke-WebRequest -Uri ($base + $path) -UseBasicParsing
  foreach ($name in @(
    'X-Performance-Request-Id',
    'X-Performance-Total-Ms',
    'X-Performance-DB-Operations',
    'X-Performance-DB-Time-Ms',
    'Server-Timing'
  )) {
    "$path $name=$($response.Headers[$name])"
  }
}
```

For browser/Flutter Web verification, include an allowed `Origin` header and confirm `Access-Control-Expose-Headers` still lists the five timing headers. Do not use an unapproved origin or disable the allowlist.

## Expected post-deployment evidence

For `/ready`, the response should continue to be HTTP 200 when MongoDB is ready and HTTP 503 when MongoDB is unavailable. The correction should change only observability:

- `X-Performance-DB-Operations` should include the readiness `ping`.
- `X-Performance-DB-Time-Ms` should contain the measured command duration.
- `Server-Timing` should report the same database duration.
- The response request ID should remain unique and consistent with any staging instrumentation record.

The approximately 200 ms readiness latency should not be interpreted as fixed database latency until several cold-observed and warm requests are measured after deployment.

## Remaining blockers

1. Review approval is required before committing or deploying this correction.
2. The fix has not been pushed or deployed.
3. Protected endpoint verification still requires staging-only credentials/tokens supplied through local environment variables; no credentials were requested or exposed.
4. MongoDB command counts and durations require a new staging deployment before they can be confirmed live.
5. If request-ID-to-log correlation is required, configure a staging-only log sink/path outside the repository and verify records without logging sensitive values.

Phase 1 optimization has not started. Stop here for review.
