# Phase 0 Test Access Readiness Report

Generated: 2026-11-11

## Result

Protected performance measurement remains **blocked**. No dedicated synthetic staging account credentials were found in the current local environment, and no account was created or modified.

## Repository and safety

- Authoritative repository inspected: `D:\education_app`.
- The nested Flutter repository `D:\education_app\Education_App` has unrelated existing changes; they were preserved.
- No staging write endpoint was called.
- No production endpoint, production account, database write, migration, index operation, credential inspection, or authentication bypass was performed.
- Secret values, passwords, tokens, MongoDB URIs, and personal data were not printed or saved.

## Existing authentication and account workflows

### Login

The backend login route is `POST /api/login`. It accepts an identifier and password, looks up the credential in role-specific credential collections with legacy fallback support, verifies the password with bcrypt, and returns an application token plus sanitized user metadata. The Flutter login service uses the same route and payload shape.

### Admin-managed login credentials

The protected `/api/users` router supports administrator-managed credential records:

- `GET /api/users` — administrator-only listing.
- `POST /api/users` — administrator-only credential creation with `userId`, `email`, `password`, and role (`admin`, `staff`, or `student`).
- `PUT /api/users/:id` — controlled email/password updates.
- `DELETE /api/users/:id` — administrator-only credential deletion.

These are write-capable account-management routes. They were inspected only; none was called.

### Staff and student profile workflows

The Flutter application also contains staff and student profile creation services that use write endpoints such as `/api/staff` and `/api/students`. These create or modify school records and are not appropriate for automatic benchmark-account provisioning without explicit authorization and synthetic data fixtures.

## Synthetic account availability

| Role | Dedicated staging account verified | Local secret/token available | Status |
|---|---|---|---|
| Admin | No evidence in repository or local environment | No | Blocked |
| Staff/teacher | No evidence in repository or local environment | No | Blocked |
| Student | No evidence in repository or local environment | No | Blocked |
| Dedicated login account | No evidence in repository or local environment | No | Blocked |

The repository contains no approved account inventory or secret-manager connector. `backend/inspect_credentials.js` is an administrative MongoDB inspection script that prints credential collection documents and was not executed because doing so would expose sensitive data and would not establish authorized benchmark access.

## Required benchmark variables

The existing safe runner [backend/performance-baseline.js](./backend/performance-baseline.js) consumes these local environment variable names:

- `BASELINE_ADMIN_TOKEN`
- `BASELINE_STAFF_TOKEN`
- `BASELINE_STUDENT_TOKEN`
- `BASELINE_LOGIN_IDENTIFIER`
- `BASELINE_LOGIN_PASSWORD`
- Optional `BASELINE_IMAGE_PATH`

The runner does not consume `BASELINE_LOGIN_TOKEN`. It uses identifier/password for its login case and bearer tokens for protected GET cases.

Target guard variables must designate only the approved host:

- `BASELINE_BASE_URL=https://school-app-1uep.onrender.com`
- `BASELINE_TARGET_ENV=staging`
- `BASELINE_STAGING_HOST=school-app-1uep.onrender.com`

Environment-name-only inspection found no populated `BASELINE_*` variables. Values were never read or displayed.

## Minimum authorized setup

An application owner or staging administrator should provision, outside this workflow, four dedicated synthetic staging access paths:

1. An admin account with only the synthetic staging data and role required for read-only dashboard/main-page measurements.
2. A staff/teacher account with synthetic staff/profile/class data required for read-only measurements.
3. A student account with synthetic student/messages/attendance/diary/group/resource data required for read-only measurements.
4. A dedicated login test account, if login timing must be measured separately from role-token requests.

The owner should then place the resulting values in the approved local secret manager or an untracked PowerShell session. Do not send them in chat, commit them, put them in Dart source, or place them in a report.

## Safe local configuration example

Set only the target controls openly:

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
$env:BASELINE_TIMEOUT_MS = '20000'
$env:BASELINE_WARM_REQUESTS = '20'
```

Set secret variables only through the approved local mechanism, without echoing values. Verify presence by checking variable names and non-empty state only. Then run the unchanged runner:

```powershell
Set-Location D:\education_app\backend
npm.cmd run benchmark:performance
```

The benchmark remains read-only for protected cases and must stop if authentication fails; do not substitute production credentials or invent tokens.

## Flutter profiling readiness

Flutter toolchain and Chrome are available. The approved staging URL mapping is now corrected in [Education_App/lib/config/api_config.dart](./Education_App/lib/config/api_config.dart), and the Flutter test suite passes. Chrome profile mode can launch against the approved staging host using the existing `API_BASE_URL` override mechanism.

Authenticated Admin, Staff, and Student profiling is still blocked until role-specific synthetic staging login state is securely available. No Android device or emulator is currently available, so remaining profiling will be browser-specific and must not be reported as native frame/raster performance.

## Readiness decision

- Account provisioning: **Not performed; explicit authorization is required.**
- Protected backend benchmark: **Not ready; credentials missing.**
- Admin dashboard profile: **Not ready; admin account/session missing.**
- Staff dashboard profile: **Not ready; staff account/session missing.**
- Student dashboard profile: **Not ready; student account/session missing.**
- Phase 1 optimization: **Not started.**

