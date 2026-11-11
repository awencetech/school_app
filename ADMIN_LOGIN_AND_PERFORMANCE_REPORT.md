# Admin Login and Performance Report

Generated: 2026-11-11

## Result

Admin login and authenticated Admin Dashboard profiling were blocked before authentication because the two required local environment variables are unavailable:

```text
BASELINE_LOGIN_IDENTIFIER
BASELINE_LOGIN_PASSWORD
```

Their values were not read, printed, requested in chat, entered into the browser, or written to any file. No authentication request was sent. No source code or application behavior was changed.

## Environment and safety

- Target: staging only, `https://school-app-1uep.onrender.com`.
- Flutter profile environment: Chrome web profile mode on the local Flutter application.
- No production target was used.
- No write endpoint was called.
- No database data, API, authentication, routes, UI, or backend files were modified.
- No credentials, tokens, response bodies, or personal information were recorded.

## Existing login implementation reviewed

The Flutter login flow is implemented in [login_screen.dart](./lib/screens/login/login_screen.dart:55):

1. It trims the username/identifier and password fields.
2. It calls the existing [UserService.login](./lib/services/user_service.dart:109) method.
3. The service sends `POST /api/login` with JSON fields `identifier` and `password` in [user_service.dart](./lib/services/user_service.dart:113).
4. The login screen stores the returned authenticated state through the existing `AppState` flow and selects a role route. Admin navigation resolves to [AppRoutes.adminDashboard](./lib/routes/app_routes.dart:92), which is mapped to [AdminDashboard](./lib/routes/app_router.dart:425).

No alternate endpoint, authentication bypass, token fabrication, or new request format was used.

## Login verification status

| Check | Result |
|---|---|
| Credential variable names present | Failed: both absent |
| Login HTTP status | Not measured; request not sent |
| Authentication response structure | Not measured |
| Token handling | Not exercised |
| Navigation to Admin Dashboard | Not exercised |
| Credential/token exposure | Passed; none exposed |

## Admin Dashboard verification status

| Measurement | Result |
|---|---|
| Dashboard loading time | Not measured |
| Initial API request count | Not measured for authenticated dashboard |
| Duplicate requests | Not measured for authenticated dashboard |
| Slowest protected API | Not measured |
| MongoDB timing headers | Not measured for authenticated dashboard |
| Image delays | Not measured for authenticated dashboard |
| Never-ending loading indicator | Not assessed |
| Flutter exceptions during dashboard flow | Not assessed |
| Browser console errors during dashboard flow | Not assessed |
| Dashboard frame/rendering performance | Not measured |

The browser reached the local app main route, but no authenticated Admin Dashboard route was entered.

## Previously observed web-profile signals

These are not Admin Dashboard measurements. They were observed during the earlier unauthenticated/local main-route Flutter Web profile run:

- Flutter Web navigation: 1,481.0 ms.
- `/api/mainpage-info` resource timing: 7,574.6 ms.
- First observed image resource: 5,124.5 ms.
- The same image path appeared a second time with a 2.6 ms resource timing.

These values are documented in [PHASE0_FLUTTER_PERFORMANCE_REPORT.md](./PHASE0_FLUTTER_PERFORMANCE_REPORT.md) and must not be attributed to the authenticated Admin Dashboard.

## Static performance risks reviewed

These are source observations only, not confirmed Admin Dashboard bottlenecks:

- [AdminDashboard](./lib/screens/admin/admin_dashboard.dart:29) uses a large scrollable dashboard tree with quick-access grids and multiple provider reads.
- The main body creates a [FutureBuilder](./lib/screens/admin/admin_dashboard.dart:143) around `DummyDataService.getSchoolInfo()`.
- [SchoolConfigService](./lib/services/school_config_service.dart:109) loads persisted school configuration and notifies listeners; the dashboard watches this provider at [admin_dashboard.dart:146](./lib/screens/admin/admin_dashboard.dart:146).
- The dashboard uses `CachedNetworkImage` for the school poster at [admin_dashboard.dart:177](./lib/screens/admin/admin_dashboard.dart:177) and can decode base64 poster data with `Image.memory` at [admin_dashboard.dart:210](./lib/screens/admin/admin_dashboard.dart:210).
- Provider notifications may rebuild a broad dashboard subtree. This requires an authenticated DevTools trace to confirm cost or frequency.

No fix was applied because no confirmed Admin Dashboard runtime issue could be established without authorized login.

## How to configure the blocker locally

Set the approved staging test account values in a local secret manager or untracked shell environment. Do not paste them into chat or commit them:

```powershell
$env:BASELINE_LOGIN_IDENTIFIER = '<authorized staging identifier>'
$env:BASELINE_LOGIN_PASSWORD = '<authorized staging password>'
```

Also ensure the existing staging target guard is configured:

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
```

After local configuration, rerun the existing login flow and capture only status, durations, header names/values that are non-sensitive performance metadata, and route transitions. Never record the identifier, password, bearer token, response body, or personal data.

## Tests

No application tests were changed or run for this blocked login attempt. There were no code changes requiring regression testing.

## Remaining issues and next gate

1. Provide the two required staging variables locally through a secret manager or untracked environment configuration.
2. Re-run the existing login flow against staging.
3. Measure the Admin Dashboard with at least three comparable runs.
4. Inspect request headers, API durations, image timing, console errors, loading completion, and frame/memory data.
5. Only after a confirmed runtime cause is identified should a minimal fix be proposed for approval.

Staff and Student dashboards were not modified or profiled in this task. Broad Phase 1 optimization has not started.
