# Phase 0 Final Backend Performance Report

Generated: 2026-11-11

## Executive result

Protected endpoint measurement could not be completed because the required staging-only environment variables were absent from the local shell. No protected requests were sent, no credentials or tokens were printed, and no code or backend configuration was changed.

This report separates the previously measured public staging results from protected endpoints that remain unmeasured.

## Benchmark configuration reviewed

The existing safe runner is [backend/performance-baseline.js](./backend/performance-baseline.js), invoked by [backend/package.json](./backend/package.json) using `npm.cmd run benchmark:performance`.

Configured existing protected cases:

| Case | Method | Path | Auth variable used by runner |
|---|---|---|---|
| Login | POST | `/api/login` | `BASELINE_LOGIN_IDENTIFIER` + `BASELINE_LOGIN_PASSWORD` |
| Admin dashboard | GET | `/api/mainpage-info` | `BASELINE_ADMIN_TOKEN` |
| Staff dashboard | GET | `/api/staff/profile` | `BASELINE_STAFF_TOKEN` |
| Student dashboard | GET | `/api/students/profile` | `BASELINE_STUDENT_TOKEN` |
| Messages | GET | `/api/messages/inbox` | `BASELINE_STUDENT_TOKEN` |
| Attendance | GET | `/api/student-attendance` | `BASELINE_STUDENT_TOKEN` |
| Diary | GET | `/api/diary/student` | `BASELINE_STUDENT_TOKEN` |
| Groups | GET | `/api/groups` | `BASELINE_STUDENT_TOKEN` |
| Classes | GET | `/api/classes` | `BASELINE_STAFF_TOKEN` |
| Resources | GET | `/api/school-resources` | `BASELINE_STUDENT_TOKEN` |
| Image | GET | value of `BASELINE_IMAGE_PATH` | none in runner |

The user-specified `BASELINE_LOGIN_TOKEN` is not consumed by the existing runner. It is not safe to modify the runner or invent a new login authentication method during this measurement-only phase. The existing runner correctly uses identifier/password for its login POST and role tokens for protected GET requests.

## Local variable availability

Environment-name-only inspection found these variables absent or empty:

```text
BASELINE_ADMIN_TOKEN
BASELINE_STAFF_TOKEN
BASELINE_STUDENT_TOKEN
BASELINE_LOGIN_TOKEN
BASELINE_IMAGE_PATH
BASELINE_LOGIN_IDENTIFIER
BASELINE_LOGIN_PASSWORD
```

No values were read into output or reports.

## Protected measurements

| Endpoint | Result | p50/p95/p99 | Backend/Mongo timings | Payload/status/errors |
|---|---|---|---|---|
| Login | Not measured; missing runner login variables | n/m | n/m | No request sent |
| Admin dashboard | Not measured; missing admin token | n/m | n/m | No request sent |
| Staff dashboard | Not measured; missing staff token | n/m | n/m | No request sent |
| Student dashboard | Not measured; missing student token | n/m | n/m | No request sent |
| Messages | Not measured; missing student token | n/m | n/m | No request sent |
| Attendance | Not measured; missing student token | n/m | n/m | No request sent |
| Diary | Not measured; missing student token | n/m | n/m | No request sent |
| Groups | Not measured; missing student token | n/m | n/m | No request sent |
| Classes | Not measured; missing staff token | n/m | n/m | No request sent |
| Resources | Not measured; missing student token | n/m | n/m | No request sent |
| Image | Not measured; missing image path | n/m | n/m | No request sent |

No authentication failures were silently treated as successful measurements. No timeout, status, payload, request ID, `Server-Timing`, or MongoDB metric is claimed for these cases.

## Previously measured public staging baseline

Source: [performance-baseline.json](./performance-baseline.json) and [PERFORMANCE_BASELINE_REPORT.md](./PERFORMANCE_BASELINE_REPORT.md), generated 2026-11-11. Target was `https://school-app-1uep.onrender.com`.

| Case | Phase | Samples | p50 ms | p95 ms | p99 ms | Average ms | Max ms | HTTP errors | Avg payload |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Health | cold-observed | 1 | 2256.457 | 2256.457 | 2256.457 | 2256.457 | 2256.457 | 0 | 15 B |
| Health | warm | 20 | 403.296 | 566.704 | 845.653 | 431.725 | 845.653 | 0 | 15 B |
| Health | conditional | 20 | 397.716 | 461.221 | 644.859 | 395.828 | 644.859 | 0 | 15 B |
| Readiness | cold-observed | 1 | 655.613 | 655.613 | 655.613 | 655.613 | 655.613 | 0 | 18 B |
| Readiness | warm | 20 | 604.439 | 763.452 | 871.113 | 633.003 | 871.113 | 0 | 18 B |
| Readiness | conditional | 20 | 647.449 | 798.789 | 962.473 | 657.243 | 962.473 | 0 | 18 B |

Instrumentation was available in this baseline, and MongoDB timing was observed on instrumented requests. The baseline recorded 40 conditional samples and zero HTTP 304 responses in that run. These public health/readiness results are not substitutes for protected endpoint measurements.

## Safe completion instructions

Configure approved staging values locally, without echoing them:

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
$env:BASELINE_WARM_REQUESTS = '20'
```

Then supply the runner’s required credential/token names through a local secret manager or untracked environment configuration and run:

```powershell
Set-Location D:\education_app\backend
npm.cmd run benchmark:performance
```

Do not change endpoint paths, authorization behavior, request formats, or the staging safety guard.

## Remaining blockers

1. Missing `BASELINE_ADMIN_TOKEN`, `BASELINE_STAFF_TOKEN`, and `BASELINE_STUDENT_TOKEN`.
2. Missing `BASELINE_LOGIN_IDENTIFIER` and `BASELINE_LOGIN_PASSWORD` required by the existing login runner.
3. Missing optional `BASELINE_IMAGE_PATH` for image measurement.

Phase 1 optimization has not started.
