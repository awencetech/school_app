# Phase 0 Synthetic Staging Account Creation Plan

Generated: 2026-11-11

## Scope and safety boundary

This is a plan only. No account creation, login, database write, cleanup, production access, or authenticated staging request was executed.

Approved target: `https://school-app-1uep.onrender.com`

Use only dedicated synthetic staging identities and synthetic data. Never use a real student, staff member, administrator, parent, production credential, personal email, or production token.

## Required synthetic roles

Create or obtain four separate staging access paths:

1. **Admin** — required for the admin dashboard/main-page protected case.
2. **Staff/teacher** — required for staff profile and classes.
3. **Student** — required for student profile, messages, attendance, diary, groups, and resources.
4. **Dedicated login account** — recommended for measuring `POST /api/login` independently. This may be one of the role accounts only if the test owner approves that measurement design.

Each identity must be labeled as synthetic, have only staging access, and contain the minimum synthetic records required by the selected read-only endpoints.

## Existing supported creation workflow

### Credential creation

The backend’s protected `/api/users` workflow supports administrator-managed credential creation:

- `POST /api/users`
- Authentication: existing administrator bearer token
- Minimum fields:
  - `userId` — non-empty, maximum 128 characters, unique
  - `email` — syntactically valid synthetic address, unique
  - `password` — 8–128 characters, generated only by the account owner/secret manager
  - `role` — exactly `admin`, `staff`, or `student`
- The backend hashes the password before storage.
- The response is sanitized and does not return the password hash.

The route rejects unexpected fields and duplicate user IDs/emails. It is a write endpoint and must not be called until the application owner explicitly approves the exact synthetic accounts and staging database target.

### Role-specific profile data

Credential creation alone may not provide all data needed by the protected dashboard endpoints. The repository also contains staff and student profile creation workflows using `/api/staff` and `/api/students`. These must be considered separate, approved staging writes:

- Staff profile: create only the minimum synthetic staff/employee identity needed for `/api/staff/profile` and `/api/classes`.
- Student profile: create only the minimum synthetic student identity and synthetic class/group associations needed for `/api/students/profile`, messages, attendance, diary, groups, and resources.
- Admin: create only the credential unless the admin dashboard requires additional synthetic school configuration; do not populate unrelated modules.

The exact profile payload should be reviewed by the staging owner against the current route validation and existing UI workflow before submission. Do not guess payload fields or use production data.

## Required approvals before any write

Obtain written approval from the application/staging owner for:

1. The target hostname and database are staging only.
2. The synthetic identifiers and email domains to use.
3. Creation of one admin, one staff, and one student credential.
4. Any required staff/student profile and class/group fixture records.
5. The account expiration date and cleanup owner.
6. The exact cleanup scope, including whether profile records are retained or removed separately.
7. The administrator or secret-manager process that will securely receive passwords and tokens.

Do not request or paste passwords, tokens, MongoDB URIs, or personal credentials in chat.

## Obtaining authenticated sessions safely

Use the normal staging login route only:

`POST https://school-app-1uep.onrender.com/api/login`

Send the existing login payload fields `identifier` and `password`. Capture the returned token directly into a local protected shell variable or approved secret manager. Do not print the response, token, cookies, or user object.

For benchmark readiness, provide the resulting role tokens locally as:

- `BASELINE_ADMIN_TOKEN`
- `BASELINE_STAFF_TOKEN`
- `BASELINE_STUDENT_TOKEN`

Use `BASELINE_LOGIN_IDENTIFIER` and `BASELINE_LOGIN_PASSWORD` for the dedicated login timing case. The existing runner does not consume `BASELINE_LOGIN_TOKEN`.

Example pattern using a local secret manager or secure shell integration:

```powershell
# Set values through the approved local secret mechanism; do not echo them.
$env:BASELINE_ADMIN_TOKEN = '<local secret value>'
$env:BASELINE_STAFF_TOKEN = '<local secret value>'
$env:BASELINE_STUDENT_TOKEN = '<local secret value>'
$env:BASELINE_LOGIN_IDENTIFIER = '<local secret value>'
$env:BASELINE_LOGIN_PASSWORD = '<local secret value>'
```

The placeholders are instructions only. Do not commit an environment file or shell history containing real values.

## Benchmark target and environment configuration

Set only the non-secret target controls openly:

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
$env:BASELINE_TIMEOUT_MS = '20000'
$env:BASELINE_WARM_REQUESTS = '20'
# Optional, only if an approved synthetic staging image path exists:
$env:BASELINE_IMAGE_PATH = '<approved staging image path>'
```

Verify variable presence without printing values:

```powershell
foreach ($name in @(
  'BASELINE_BASE_URL', 'BASELINE_TARGET_ENV', 'BASELINE_STAGING_HOST',
  'BASELINE_ADMIN_TOKEN', 'BASELINE_STAFF_TOKEN', 'BASELINE_STUDENT_TOKEN',
  'BASELINE_LOGIN_IDENTIFIER', 'BASELINE_LOGIN_PASSWORD', 'BASELINE_IMAGE_PATH'
)) {
  $item = Get-Item "Env:$name" -ErrorAction SilentlyContinue
  [pscustomobject]@{
    Name = $name
    Present = [bool]$item
    NonEmpty = [bool]($item -and -not [string]::IsNullOrWhiteSpace($item.Value))
  }
}
```

The hostname must remain exactly `school-app-1uep.onrender.com`. Do not set `ALLOW_PRODUCTION_BENCHMARK=true`.

## Read-only benchmark scope

After account creation and token setup, the unchanged [backend/performance-baseline.js](./backend/performance-baseline.js) runner can measure:

- Login: `POST /api/login` — authentication/session behavior only.
- Admin dashboard: `GET /api/mainpage-info`.
- Staff profile: `GET /api/staff/profile`.
- Student profile: `GET /api/students/profile`.
- Student messages: `GET /api/messages/inbox`.
- Student attendance: `GET /api/student-attendance`.
- Student diary: `GET /api/diary/student`.
- Groups: `GET /api/groups`.
- Staff classes: `GET /api/classes`.
- School resources: `GET /api/school-resources`.
- Optional image: configured GET path only.

The protected benchmark cases do not create, update, or delete records. Do not add write endpoints to the runner. Failed authentication must remain an error/skip, never a successful performance sample.

Run only after the owner confirms the variables are populated locally:

```powershell
Set-Location D:\education_app\backend
npm.cmd run benchmark:performance
```

The runner should collect at least 20 warm requests per available case and record aggregate timing/telemetry without saving response bodies or authorization headers.

## Flutter profiling readiness

The Flutter staging mapping is configured in [Education_App/lib/config/api_config.dart](./Education_App/lib/config/api_config.dart). Chrome profile mode can use the approved staging host through the existing source-supported `API_BASE_URL` override when needed. Role-specific dashboard profiling requires a normal login session for each role.

Do not put any credentials or tokens in Dart defines, Dart source, screenshots, browser storage exports, or reports. Record only aggregate browser timings, redacted paths, request counts, errors, image behavior, and memory observations.

## Cleanup plan

Cleanup must be performed only after measurements are exported and the staging owner approves it:

1. Stop the benchmark and close local browser/app sessions.
2. Revoke or delete the synthetic credential records through the approved administrator workflow, or use the approved staging-admin procedure.
3. Confirm the deleted IDs are the synthetic test IDs only.
4. Treat related staff/student profile, class, group, message, attendance, diary, and resource records separately. The credential deletion route does not automatically delete related school records.
5. Remove synthetic fixture records only through an explicitly approved staging cleanup procedure; never run ad-hoc database deletes.
6. Revoke any temporary tokens and remove local environment variables/secret-manager entries.
7. Record cleanup completion without recording passwords, tokens, personal data, or raw database documents.

## Remaining blockers

- No synthetic staging Admin, Staff, or Student account credentials are currently available locally.
- No explicit approval exists to create credential or profile records.
- Required synthetic student/staff related fixtures may need owner-defined payloads.
- Protected backend benchmarks and authenticated Flutter dashboard profiling must remain paused until the approvals, accounts, and local secret configuration are complete.

Phase 1 optimization has not started.

## Revision: clone-first execution policy

The creation plan is updated with these mandatory safeguards:

1. Do not create fixtures in the shared staging database as the normal workflow. Provision and verify a disposable staging database clone first; create all synthetic records only in that clone or an owner-approved isolated staging service connected to it.
2. Keep the approved staging restriction intact: `https://school-app-1uep.onrender.com` and the staging configuration only. Never access production. If the approved host cannot be mapped safely to the clone, stop rather than pointing it at an unverified database.
3. The group fixture is optional. Omit group creation and membership writes unless the selected benchmark requires group authorization. Do not create a group merely to make the account plan look complete.
4. Never modify a pre-existing staff-access record. An existing access record for the proposed staff identity is an abort condition.
5. Before any staff-access upsert, obtain owner approval for an isolated cleanup method for the newly inserted access document. Empty-array updates are not an acceptable cleanup substitute.
6. Keep an uncommitted private ledger containing exact MongoDB `_id` values for every created credential/profile/class/group/access fixture. Do not store raw records, secrets, tokens, or personal data.
7. Execute every create and association operation sequentially. After any ambiguous response, perform exact read-back by the synthetic identifier and verify creation ownership before retrying or continuing. Never blindly retry.
8. Cleanup must account for non-cascading behavior across credentials, staff/student profiles, class/group memberships, staff access, and any approved supporting fixtures.
9. Group deletion must not be treated as an isolated rollback because `renumberGroups()` may change unrelated group ordering. Prefer disposing of the clone; any shared-staging exception requires explicit owner acceptance of that side effect.

The plan is not execution authorization. Phase 0 measurements remain blocked until clone ownership, target mapping, secret handling, exact-ID recording, and cleanup approvals are complete.

