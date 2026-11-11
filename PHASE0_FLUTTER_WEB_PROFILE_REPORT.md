# Phase 0 Flutter Web Profile Report

Generated: 2026-11-11

## Result

**PARTIAL.** Chrome profile mode was built and launched against the approved staging backend. Three unauthenticated reload runs were measured. Authenticated Admin, Staff, and Student dashboard profiling was not performed because no authorized local credentials or role session state were available.

These are browser-specific web observations, not Android frame/raster measurements.

## Configuration correction

[lib/config/api_config.dart](./Education_App/lib/config/api_config.dart) now maps:

- `API_ENV=staging` → `https://school-app-1uep.onrender.com`
- `API_ENV=production` → `https://school-app-1uep.onrender.com`

The staging mapping was previously pointing to `school-backend-staging.onrender.com`. The URL has no trailing slash, and existing API path construction continues to append paths such as `/api/mainpage-info`.

The profile launch used the source-supported override mechanism:

```powershell
flutter run -d chrome --profile --web-port 8000 `
  --dart-define=API_ENV=staging `
  --dart-define=API_BASE_URL=https://school-app-1uep.onrender.com
```

No credentials or tokens were supplied.

## Toolchain

| Item | Result |
|---|---|
| Flutter | 3.47.4 stable |
| Dart | 3.13.3 |
| DevTools | 2.60.0 |
| Chrome | Available, 157.0.8103.50 |
| Android SDK | Available, version 36.0.0 |
| Android devices | None connected |
| Android emulators | None available |

## Measured unauthenticated web runs

Route was the existing unauthenticated main flow. These are not Admin/Staff/Student dashboard timings.

| Run | Browser navigation duration | Wall time after reload | Observed API/image notes |
|---:|---:|---:|---|
| 1 | 1,330.9 ms | 2,909 ms | Image resources observed; one cached/zero-duration entry |
| 2 | 999.1 ms | 2,597 ms | Image resources observed; approximately 2–3 ms browser resource entries |
| 3 | 973.2 ms | 2,521 ms | Image resources observed; approximately 2–3 ms browser resource entries |

Average navigation duration: **1,101.1 ms**. These measurements include browser/web-app startup and are not backend-only timings. Browser resource timing reported `transferSize=0` for the observed cross-origin entries, so payload and decode durations are unavailable from this run.

## Dashboard profile status

| Workflow | Runs | First useful content | Loading completion | API/duplicate/JSON/image/frame/memory metrics | Status |
|---|---:|---|---|---|---|
| Admin login/dashboard | 0 | Not measured | Not measured | Not measured | Blocked: missing credentials/session state |
| Staff login/dashboard | 0 | Not measured | Not measured | Not measured | Blocked: missing credentials/session state |
| Student login/dashboard | 0 | Not measured | Not measured | Not measured | Blocked: missing credentials/session state |

No login bypass was attempted. No browser measurement is presented as native Android performance.

## Validation

- Focused API configuration tests: **PASS, 5 tests**.
- Full Flutter test suite: **PASS, 42 tests**.
- Staging `GET /health`: HTTP 200.
- Staging `GET /ready`: HTTP 200.

