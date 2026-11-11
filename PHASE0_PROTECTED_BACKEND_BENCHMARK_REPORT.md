# Phase 0 Protected Backend Benchmark Report

Generated: 2026-11-11

## Result

Protected staging benchmarking was not executed because the required local `BASELINE_*` environment variables are unavailable in the current shell. No protected endpoint requests were made, no credentials were requested, and no tokens were printed or stored.

This is a skipped measurement, not a performance result. The existing public baseline in [PERFORMANCE_BASELINE_REPORT.md](./PERFORMANCE_BASELINE_REPORT.md) must not be interpreted as a protected API baseline.

## Safety checks

- Target configured for this phase: `https://school-app-1uep.onrender.com`.
- No production target was called.
- No protected endpoint was called.
- No write endpoint was called.
- No code, database data, index, schema, authentication, API contract, or UI was changed.
- No Phase 1 optimization was started.
- No credential or token value was printed, committed, or written to an output file.

## Existing safe runner configuration

The existing runner is [backend/performance-baseline.js](./backend/performance-baseline.js), invoked by the `benchmark:performance` script in [backend/package.json](./backend/package.json). Its protected cases and paths are:

| Case | Method | Existing path | Required local variable |
|---|---|---|---|
| Login | POST | `/api/login` | `BASELINE_LOGIN_IDENTIFIER`, `BASELINE_LOGIN_PASSWORD` |
| Admin dashboard | GET | `/api/mainpage-info` | `BASELINE_ADMIN_TOKEN` |
| Staff dashboard | GET | `/api/staff/profile` | `BASELINE_STAFF_TOKEN` |
| Student dashboard | GET | `/api/students/profile` | `BASELINE_STUDENT_TOKEN` |
| Messages/inbox | GET | `/api/messages/inbox` | `BASELINE_STUDENT_TOKEN` |
| Attendance | GET | `/api/student-attendance` | `BASELINE_STUDENT_TOKEN` |
| Diary | GET | `/api/diary/student` | `BASELINE_STUDENT_TOKEN` |
| Groups | GET | `/api/groups` | `BASELINE_STUDENT_TOKEN` |
| Classes | GET | `/api/classes` | `BASELINE_STAFF_TOKEN` |
| Resources | GET | `/api/school-resources` | `BASELINE_STUDENT_TOKEN` |

The runner uses a login POST only for the existing safe login measurement. Protected data cases are GET requests with bearer tokens supplied from the local environment.

## Missing variables

The following variable names were absent from the current shell. Their values were not inspected or printed:

```text
BASELINE_LOGIN_IDENTIFIER
BASELINE_LOGIN_PASSWORD
BASELINE_ADMIN_TOKEN
BASELINE_STAFF_TOKEN
BASELINE_STUDENT_TOKEN
```

The staging target controls should also be set before a future run:

```text
BASELINE_BASE_URL
BASELINE_TARGET_ENV=staging
BASELINE_STAGING_HOST=school-app-1uep.onrender.com
```

Optional controls supported by the existing runner are `BASELINE_TIMEOUT_MS`, `BASELINE_WARM_REQUESTS`, and `BASELINE_IMAGE_PATH`. An image path is not required for the protected API cases listed above.

## Generated artifacts

- [performance-protected-baseline.json](./performance-protected-baseline.json): zero requests executed; all protected cases explicitly skipped.
- [performance-protected-baseline.csv](./performance-protected-baseline.csv): schema header only; no fabricated measurements.

Because no requests ran, there are no measured p50, p95, p99, average, maximum, payload, status, timeout, request-ID, `Server-Timing`, or MongoDB timing values for protected endpoints.

## Safe rerun instructions

Set approved staging values locally without echoing them:

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
$env:BASELINE_WARM_REQUESTS = '20'
```

Populate the five credential/token variable names through a local secret manager or untracked environment configuration. Do not paste values into chat or commit them.

Then run the existing safe runner from [backend/](./backend/):

```powershell
Set-Location D:\education_app\backend
npm.cmd run benchmark:performance
```

Review the generated standard baseline artifacts, then export the protected-case rows into the protected report artifacts. Do not change the runner’s endpoint paths, request formats, authorization method, or staging target guard.

The runner is configured to collect the first observed request, 20 warm requests, and conditional requests where an ETag is available. It records client duration, backend timing headers, database operation count/time, payload bytes, request ID, status, errors, and timeout results without writing response bodies.

## Remaining blockers

1. Authorized staging login identifier and password are unavailable locally.
2. Authorized admin, staff, and student bearer tokens are unavailable locally.
3. Consequently, protected API latency and MongoDB timing cannot be measured yet.

No workaround was attempted. Stop Phase 0 protected benchmarking here until the required local variables are configured.
