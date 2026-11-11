# Phase 0 Deployment Verification

Generated: 2026-11-11

Target: `https://school-app-1uep.onrender.com`

## Result summary

| Check | Result | Evidence |
|---|---|---|
| Authoritative local branch | Passed | Local branch is `master`. |
| Local commit created | Passed | Commit `1b45680` (`Enable staging performance instrumentation`). |
| Local commit matches remote | Not applicable after commit | `origin/master` was `1a65284` before the local commit. |
| Push to authoritative GitHub repository | Failed | GitHub returned HTTP 403: permission denied to `awencetech/school_app`. |
| Render repository/branch/root/start settings | Source manifest prepared | [render.yaml](./render.yaml) specifies `awencetech/school_app` by repository context, `master`, `backend`, and `npm start`; Render dashboard could not be inspected from this workspace. |
| Intended entry point | Passed locally | [backend/package.json](./backend/package.json) maps `npm start` to `node server.js`; [backend/server.js](./backend/server.js) is the application entry point. |
| Backend tests | Passed | 34 tests passed with `npm.cmd test`. |
| Staging `/` | Passed | HTTP 200 header-only request. |
| Staging `/health` | Passed | HTTP 200 header-only request. |
| Staging `/ready` | Passed | HTTP 200 header-only request. |
| Staging instrumentation headers | Failed | No `X-Performance-*` or `Server-Timing` headers observed. |
| CORS timing-header exposure | Failed on deployed service | No `Access-Control-Expose-Headers` observed. Source change is committed locally but not deployed. |
| Request-ID/timing correspondence | Blocked | No deployed request ID or timing headers available. |
| MongoDB command counts/durations | Blocked | Requires an authenticated staging GET through the deployed instrumented process. |
| Protected endpoint verification | Blocked | No local staging `BASELINE_*` credentials/tokens available. |
| Production instrumentation disabled | Source passed; deployment unverified | Instrumentation requires both `PERFORMANCE_INSTRUMENTATION=true` and `PERFORMANCE_INSTRUMENTATION_ENV=staging`; Render production environment state still requires dashboard confirmation. |

## Changes made locally

The local commit contains only Phase 0 deployment changes:

- Added the five timing headers to `exposedHeaders` in [backend/cors_middleware.js](./backend/cors_middleware.js).
- Changed the Render manifest start command to `npm start` in [render.yaml](./render.yaml).
- Kept instrumentation gated by the staging-only environment check in [backend/performance_instrumentation.js](./backend/performance_instrumentation.js).
- Registered the instrumentation before application routes and attached it to the MongoDB client in [backend/server.js](./backend/server.js).
- Added the performance benchmark script entry to [backend/package.json](./backend/package.json).

No authentication behavior, API contract, UI, database record, schema, index, or production setting was changed.

## Live response header verification

Header-only requests to `/`, `/health`, and `/ready` returned HTTP 200. The following headers were absent from all three live responses:

```text
X-Performance-Request-Id
X-Performance-Total-Ms
X-Performance-DB-Operations
X-Performance-DB-Time-Ms
Server-Timing
Access-Control-Expose-Headers
```

The live service did return normal Express ETags and Cloudflare reported `cf-cache-status: DYNAMIC`. No secrets or response bodies were included in this report.

## Exact manual Render action

An authorized repository/Render maintainer must:

1. Grant the deployment identity write access to `awencetech/school_app`, or push commit `1b45680` through an authorized GitHub account.
2. Confirm the Render service is connected to repository `awencetech/school_app`.
3. Confirm branch `master`.
4. Confirm root directory `backend`.
5. Confirm build command `npm install`.
6. Confirm start command `npm start`.
7. Confirm health check path `/health`.
8. Confirm the Render service environment contains the names `PERFORMANCE_INSTRUMENTATION` and `PERFORMANCE_INSTRUMENTATION_ENV` with the staging-only values, without sharing their values in chat or reports.
9. Confirm production services do not have the staging instrumentation gate enabled.
10. Deploy commit `1b45680` and wait for the deployment to become healthy.

Do not put credentials, tokens, MongoDB URIs, or authentication secrets into `render.yaml` or Git.

## Post-deployment verification commands

Run these only after the authorized deployment completes:

```powershell
$base = 'https://school-app-1uep.onrender.com'
$headers = @{ Origin = 'http://localhost:8000' }
foreach ($path in @('/health', '/ready')) {
  $r = Invoke-WebRequest -Uri ($base + $path) -Headers $headers -UseBasicParsing
  foreach ($name in @(
    'X-Performance-Request-Id',
    'X-Performance-Total-Ms',
    'X-Performance-DB-Operations',
    'X-Performance-DB-Time-Ms',
    'Server-Timing',
    'Access-Control-Expose-Headers'
  )) {
    "$path $name=$($r.Headers[$name])"
  }
}
```

For an authenticated, read-only staging GET, verify that:

- the response has one request ID;
- the timing headers and `Server-Timing` are present on that same response;
- `X-Performance-DB-Operations` and `X-Performance-DB-Time-Ms` are numeric;
- no token or personal data appears in logs or output;
- the benchmark runner records the same request ID and timing fields.

Use [PHASE0_PERFORMANCE_TEST_INSTRUCTIONS.md](./PHASE0_PERFORMANCE_TEST_INSTRUCTIONS.md) for the protected benchmark configuration. Do not run write endpoints.

## Remaining blockers

1. GitHub push permission for `awencetech/school_app`.
2. Render dashboard/deployment confirmation after commit `1b45680` is available.
3. Staging-only login credentials and admin/staff/student tokens for protected GET benchmarks.
4. MongoDB timing verification through a deployed instrumented authenticated request.
5. CORS exposure verification after deployment.

Phase 1 optimization has not started. Stop here pending authorized deployment and review.
