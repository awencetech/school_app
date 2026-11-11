# Phase 0 Protected API Benchmark Report

Generated: 2026-11-11

## Result

**BLOCKED.** The existing runner was inspected, but protected benchmarks were not executed because the required staging credentials are absent from the local environment. The completed public baseline was not repeated.

No protected request, login attempt, credential value, token, response body, or personal data was sent or recorded.

## Runner and safety verification

The existing runner is [backend/performance-baseline.js](./backend/performance-baseline.js), invoked by the `benchmark:performance` script in [backend/package.json](./backend/package.json). It uses the existing login payload and bearer-token authentication format.

The approved target configuration is:

- `BASELINE_BASE_URL=https://school-app-1uep.onrender.com`
- `BASELINE_TARGET_ENV=staging`
- `BASELINE_STAGING_HOST=school-app-1uep.onrender.com`

The hostname was verified as exactly `school-app-1uep.onrender.com`. No production override was used.

## Missing variables

Environment-name-only inspection found these variables unavailable; values were never read or printed:

- `BASELINE_ADMIN_TOKEN`
- `BASELINE_STAFF_TOKEN`
- `BASELINE_STUDENT_TOKEN`
- `BASELINE_LOGIN_IDENTIFIER`
- `BASELINE_LOGIN_PASSWORD`
- `BASELINE_IMAGE_PATH` (optional image case)

## Protected benchmark status

| Case | Existing request | Result | Missing requirement |
|---|---|---|---|
| Login | POST `/api/login` | Skipped | `BASELINE_LOGIN_IDENTIFIER`, `BASELINE_LOGIN_PASSWORD` |
| Admin dashboard | GET `/api/mainpage-info` | Skipped | `BASELINE_ADMIN_TOKEN` |
| Staff profile | GET `/api/staff/profile` | Skipped | `BASELINE_STAFF_TOKEN` |
| Student profile | GET `/api/students/profile` | Skipped | `BASELINE_STUDENT_TOKEN` |
| Student messages/inbox | GET `/api/messages/inbox` | Skipped | `BASELINE_STUDENT_TOKEN` |
| Student attendance | GET `/api/student-attendance` | Skipped | `BASELINE_STUDENT_TOKEN` |
| Student diary | GET `/api/diary/student` | Skipped | `BASELINE_STUDENT_TOKEN` |
| Groups | GET `/api/groups` | Skipped | `BASELINE_STUDENT_TOKEN` |
| Staff classes | GET `/api/classes` | Skipped | `BASELINE_STAFF_TOKEN` |
| School resources | GET `/api/school-resources` | Skipped | `BASELINE_STUDENT_TOKEN` |
| Representative image | GET configured path | Skipped | `BASELINE_IMAGE_PATH` |

No protected sample exists in this run. Therefore p50, p95, p99, average, maximum, status, error, timeout, payload, backend, and MongoDB metrics are **not measured** for these cases.

## Previously measured public comparison

The existing public result in [PERFORMANCE_BASELINE_REPORT.md](./PERFORMANCE_BASELINE_REPORT.md) remains the comparison source. Its warm p50 values were approximately 403.296 ms for health and 604.439 ms for readiness. These are not protected endpoint measurements and were not repeated.

## Safe local setup for the next run

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
$env:BASELINE_WARM_REQUESTS = '20'
Set-Location D:\education_app\backend
npm.cmd run benchmark:performance
```

Do not paste secrets into chat, reports, Git, or Dart source.

