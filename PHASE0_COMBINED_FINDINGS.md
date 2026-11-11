# Phase 0 Combined Performance Findings

Generated: 2026-11-11

## Measurement status

| Area | Status | Evidence |
|---|---|---|
| Public backend staging | Measured | [performance-baseline.json](./performance-baseline.json) |
| Protected backend endpoints | Pending | Required local staging tokens/credentials absent |
| MongoDB instrumentation | Verified on public readiness path | Existing deployment report and current baseline |
| Native Flutter profiling | Pending | No Android device/emulator available |
| Flutter Web profile startup | Partially measured | Main-route resource timings only |
| Admin Dashboard authenticated profiling | Pending | No authenticated local state |

## Confirmed measured results

- Public staging health warm p50: 403.296 ms; p95: 566.704 ms; p99: 845.653 ms.
- Public staging readiness warm p50: 604.439 ms; p95: 763.452 ms; p99: 871.113 ms.
- Public staging baseline had zero HTTP errors in the measured public cases.
- Flutter Web local main-route navigation: 1481.0 ms.
- Flutter Web local main-page API resource timing: 7574.6 ms.
- Flutter Web local image resource timings: 5124.5 ms and 2.6 ms for repeated entries.

## Not confirmed

- Admin, Staff, and Student protected API latency.
- Protected MongoDB operation counts and durations.
- Login latency and Admin Dashboard navigation.
- Dashboard API duplication, dashboard payload sizes, frame jank, memory, JSON parsing, and image decoding.
- Native Android first-frame and rendering metrics.

## Primary remaining blockers

1. Configure approved staging-only `BASELINE_ADMIN_TOKEN`, `BASELINE_STAFF_TOKEN`, and `BASELINE_STUDENT_TOKEN` locally.
2. Configure the existing runner’s login variables: `BASELINE_LOGIN_IDENTIFIER` and `BASELINE_LOGIN_PASSWORD`. `BASELINE_LOGIN_TOKEN` is not consumed by the existing runner.
3. Provide an Android emulator or physical Android device for native profile measurements.
4. Repeat Flutter dashboard profiling with authenticated local state and three comparable runs per role.

## Safety boundary

No production testing, database writes, indexes, migrations, query optimization, API changes, Flutter source changes, deployment, Git push, or Phase 1 implementation was performed.

Wait for approval and the missing local test configuration before continuing.
