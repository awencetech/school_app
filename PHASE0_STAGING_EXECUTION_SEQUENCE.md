# Phase 0 Safe Staging Execution Sequence

Status: **Plan only — awaiting explicit application-owner approval**

This sequence describes how an authorized staging owner could create the proposed synthetic fixtures for Phase 0 measurements. It does not authorize or execute any request. During preparation of this document, no API endpoint was called, no MongoDB connection was opened, and no record was created or changed.

## Fixed safety boundary

All actions in this sequence must be restricted to:

- URL: `https://school-app-1uep.onrender.com`
- Render service: `awencetech/school_app`, branch `master`, root `backend`
- Database: `mmhs_staging`
- Migration setting: `RUN_STARTUP_MIGRATIONS=false`

Production hosts, production credentials, real people, broad database scripts, migrations, index changes, and non-synthetic fixtures are out of scope.

The proposed synthetic identifiers are:

| Fixture | Identifier |
|---|---|
| Admin user ID | `phase0-admin-20261111` |
| Admin email | `phase0-admin-20261111@example.invalid` |
| Staff user ID / employee ID | `phase0-staff-20261111` |
| Staff email | `phase0-staff-20261111@example.invalid` |
| Student user ID / student ID | `phase0-student-20261111` |
| Student email | `phase0-student-20261111@example.invalid` |
| Synthetic class ID | `phase0-class-20261111` |
| Synthetic group ID | `phase0-group-20261111` |

These values must be re-approved if the execution date changes or if a collision is found. Passwords and tokens must be generated and handled only through the owner’s approved secret manager or protected local environment. They must never be placed in this document, source code, reports, screenshots, or chat.

## Required approvals before Step 0

The application owner must approve, in writing and outside this document:

1. The exact synthetic identifiers above.
2. Creation of three role credentials and the associated staff/student profiles.
3. Creation of the class and group fixtures.
4. The exact student/group membership representation.
5. The exact staff class/group access representation.
6. The approved local secret-storage mechanism.
7. An expiration date, cleanup owner, and cleanup procedure.
8. The rule that any pre-existing record or permission causes an abort rather than an overwrite.

No approval is inferred from this plan.

## Execution state ledger

Before any write, the operator should maintain a private, non-committed ledger containing only synthetic identifiers and opaque Mongo `_id` values needed for exact cleanup. Do not record response bodies, passwords, tokens, personal fields, or connection strings.

For every successful step, record:

- Step name and timestamp.
- Target staging host and database confirmation.
- Synthetic identifier used.
- Returned opaque document ID, if needed for cleanup.
- Verification result.
- Whether the record was newly created by this run.

If a target is not proven synthetic and newly created by this run, stop and do not modify or delete it.

## Step 0 — Preflight and target lock

### Actions

1. Confirm the command environment points only to `https://school-app-1uep.onrender.com`.
2. Confirm the benchmark and account-creation operator are using the staging administrator session, not a production session.
3. Confirm the Render configuration still identifies `master`, `backend`, `npm start`, and the `mmhs_staging` database.
4. Confirm the approved identifiers and cleanup deadline from the owner approval.
5. Confirm no write operation will be retried automatically after an ambiguous network failure.

### Verification gate

- Hostname matches exactly.
- Database is `mmhs_staging`.
- All identifiers are synthetic.
- Owner approval is present.
- Secret values are available only locally and are not printed.

### Rollback

No database action has occurred. If any target check fails, stop with no rollback required.

## Step 1 — Collision and pre-existing-record inspection

### Actions

Using an authorized staging admin read workflow, inspect only the proposed identifiers:

- User ID and email across the credential collections through the existing admin user-management read path.
- Staff employee ID through the existing staff read path.
- Student ID through the existing student read path.
- Class ID and group ID through the existing class/group read paths.
- Staff access for the proposed staff identity through the existing staff-access read path.

Do not export or print broad lists. Redact all fields except the minimum identity needed for collision decisions.

### Verification gate

Every proposed identifier must be absent, or the owner must explicitly replace it with a newly approved identifier. A pre-existing staff-access record, class, group, profile, or credential is a hard stop. Do not update it, merge into it, or delete it.

Capture only the fact that the approved identifier was absent. Do not store personal data.

### Rollback

Read-only step; no rollback is required.

## Step 2 — Create the admin credential

### Dependency

Requires an already authorized staging admin session because `POST /api/users` is admin-protected. The existing owner/admin account is the actor; the proposed synthetic admin is not used to bootstrap itself.

### Action

Create exactly one credential through the existing user-management route:

- Method: `POST`
- Endpoint: `/api/users`
- Allowed fields only: `userId`, `email`, `password`, `role`
- Role: `admin`
- Password: owner-generated secret, 8–128 characters, handled locally only

Do not add profile fields or unexpected keys.

### Verification gate

- HTTP response indicates creation success.
- Returned sanitized identity matches the exact synthetic user ID, email, and `admin` role.
- No password or hash appears in the response or local report.
- A narrow authenticated read of the exact user confirms the identity, without saving the response body.
- The operator records that this credential was created by this run.

Do not proceed if the response is a conflict, ambiguous timeout, or unexpected identity. An ambiguous response is not permission to retry blindly; resolve the state with an exact read first.

### Rollback

If and only if the exact synthetic credential is confirmed to have been created by this run, an authorized admin may use `DELETE /api/users/:id` for that exact synthetic ID. This removes only the credential and cannot affect other records. If ownership is uncertain, do not delete; escalate for owner review.

## Step 3 — Create staff and student credentials

### Dependency

Requires Step 1 to prove both identifiers are absent and Step 2 or another already approved staging admin session to authorize the writes. The staff and student credentials are independent and should be created sequentially so the state ledger remains unambiguous.

### Actions

For each role, call the existing user-management route once:

| Role | Method | Endpoint | Required role |
|---|---|---|---|
| Staff | `POST` | `/api/users` | `staff` |
| Student | `POST` | `/api/users` | `student` |

Use only the approved synthetic `userId`, email, owner-generated password, and canonical role. Do not use teacher/student aliases unless separately approved; the canonical values are `staff` and `student`.

### Verification gate after each credential

- Creation response is successful and sanitized.
- Exact synthetic user ID, email, and role match.
- No password or token is printed or stored in reports.
- Exact read-back confirms the new credential exists.
- The operator marks the credential as newly created before continuing.

If one role fails, stop that role’s dependent steps. Do not compensate by modifying an existing account.

### Rollback

Delete only the exact newly created synthetic credential after confirmation. If the staff or student profile has already been created, delete the profile first during rollback, then the credential. Credential deletion is non-cascading.

## Step 4 — Create the staff profile

### Dependency

Requires the staff credential from Step 3. `POST /api/staff` verifies that `employeeId` belongs to a staff credential.

### Action

Create exactly one staff profile through:

- Method: `POST`
- Endpoint: `/api/staff`
- Required fields:
  - `name`: `Phase 0 Synthetic Staff`
  - `designation`: `Synthetic Teacher`
  - `employeeCategory`: `Teaching`
  - `employeeId`: `phase0-staff-20261111`
  - `teaches`: `Synthetic Subject`
  - `role`: `staff`
- Leave optional personal fields empty or absent according to the owner-approved payload.

### Verification gate

- HTTP response indicates creation success.
- Returned profile has the exact synthetic employee ID and synthetic display values.
- Capture the returned profile Mongo `_id` in the private ledger.
- A narrow exact read confirms one staff profile and no duplicate employee ID.

Do not continue if the employee ID resolves to an unexpected credential or if an existing profile is found.

### Rollback

If the profile is confirmed newly created by this run, delete it with `DELETE /api/staff/:id` using the captured profile `_id`. This does not delete the staff credential or staff-access record. Never delete by employee ID or by a guessed `_id`.

## Step 5 — Create the student profile

### Dependency

Requires the student credential from Step 3. The route validates the profile independently, but the protected student endpoints require the profile identity to correspond to the authenticated user ID.

### Action

Create exactly one student profile through:

- Method: `POST`
- Endpoint: `/api/students`
- Required fields:
  - `name`: `Phase 0 Synthetic Student`
  - `className`: `PHASE0-CLASS-2026`
  - `studentId`: `phase0-student-20261111`
  - `section`: `P0` as an approved optional fixture field
- Leave parent, phone, address, hobbies, special-needs, image, and biography fields empty or absent.

### Verification gate

- HTTP response indicates creation success.
- Returned profile has the exact synthetic student ID and class name.
- Capture the returned profile Mongo `_id` in the private ledger.
- An exact read confirms no case-insensitive duplicate student ID.

### Rollback

If confirmed newly created by this run, delete it with `DELETE /api/students/:id` using the captured profile `_id`. This does not delete the student credential or any class/group documents. Do not delete by student ID alone.

## Step 6 — Create the synthetic class

### Dependency

Requires owner approval of the school context and year. The student profile can exist before the class document, but the approved `className` and class description/code should be kept consistent.

### Action

Create through:

- Method: `POST`
- Endpoint: `/api/classes`
- `name`: `Phase 0 Synthetic Class`
- `id`: `phase0-class-20261111`
- `type`: `class`
- `description` or `code`: `PHASE0-CLASS-2026`
- `year`: `2026-27`
- `schoolId`: only the owner-approved staging school ID; `default-school` is not assumed unless approved

The route creates empty `students` and `teachers` arrays.

### Verification gate

- HTTP response indicates creation success.
- Exact class ID, type, year, and school ID match the approved values.
- Capture the class Mongo `_id`.
- Exact read confirms it was absent before creation and is now the sole synthetic class fixture.
- Confirm the class starts with empty membership arrays before any association step.

### Rollback

For a newly created synthetic class only, `DELETE /api/classes/:id` can remove the class using the exact ID and school scope. It does not clean staff-access references or other records. Remove any approved references before deletion. Do not delete if the class was not proven newly created by this run.

## Step 7 — Create the synthetic group

### Dependency

Requires owner approval of the group type, school context, and membership representation. It does not require class deletion or modification.

### Action

Create through:

- Method: `POST`
- Endpoint: `/api/groups`
- `name`: `Phase 0 Synthetic Group`
- `id`/`groupId`: `phase0-group-20261111`
- `type`: `Benchmark`
- `description` or `code`: `PHASE0-GROUP-20261111`
- `year`: `2026-27`
- `schoolId`: only the owner-approved staging school ID

The route creates empty `students` and `teachers` arrays.

### Verification gate

- HTTP response indicates creation success.
- Exact group ID, type, year, and school ID match.
- Capture the group Mongo `_id`.
- Exact read confirms the group was absent before creation and has empty membership arrays.

### Rollback

The existing `DELETE /api/groups/:id` deletes the target and then calls `renumberGroups()`, which can modify ordering in unrelated groups. Therefore, do not use this route as routine rollback without an owner-approved before/after ordering inventory and explicit acceptance of that side effect. If that cannot be approved, leave the synthetic group untouched and escalate to the owner for a safe administrative cleanup method.

## Step 8 — Associate the student and staff with the group

### Dependency

Requires a newly created synthetic group from Step 7 and the exact student/staff identities from Steps 4–5. Requires an owner-approved association payload.

### Action

The existing group PUT route accepts `students` and `teachers` arrays as replacement values:

- Method: `PUT`
- Endpoint: `/api/groups/:id`
- Target: the captured `_id` or exact synthetic group ID
- Include the complete approved metadata required by the route.
- Include only the exact synthetic student and staff entries in the arrays because the group was verified newly created and empty.

Do not use this operation against a pre-existing group. Do not send a partial array assuming it will append; supplied arrays replace the existing arrays.

### Verification gate

- Returned group contains exactly the approved synthetic student and staff membership representation.
- No unrelated member identity is present.
- A protected read using the synthetic student confirms group access only after the association is verified.
- A protected read using the synthetic staff confirms access only after the staff access step below is also complete.

### Rollback

Because the group was created by this run and verified empty before association, an owner-approved update could restore its arrays to empty. Do not use that method on a pre-existing group. Final group deletion remains subject to the `renumberGroups()` warning in Step 7.

## Step 9 — Create staff class/group access

### Dependency

Requires the staff profile, the newly created class/group IDs, and proof from Step 1 that no `stf-access` record exists for the synthetic staff. If a record already exists, stop; do not overwrite it.

### Action

Using the existing admin route:

- Method: `PUT`
- Endpoint: `/api/stf-access/phase0-staff-20261111`
- `accessGroups`: only the minimum owner-approved read groups required for measurement
- `groupIds`: only the synthetic group ID if group reads require it
- `classTeacherIds`: only the synthetic class ID if class reads require it

This route is an upsert and writes the complete access arrays. It is safe to create only when the absence of a pre-existing access record has been established and the payload is intentionally minimal.

### Verification gate

- Returned access object has the exact synthetic staff ID and only approved IDs.
- Exact read confirms access points only to the synthetic class/group.
- Staff protected reads return only authorized synthetic scope.
- No existing staff permission was changed.

### Rollback

If the access record was newly inserted by this run, owner-approved cleanup may remove that exact synthetic access document using an approved administrative procedure. The current route shown in source is an upsert/update route, not a dedicated delete route. Do not send empty arrays to a pre-existing record as a substitute for deletion; that can remove real staff permissions.

## Step 10 — End-to-end verification before benchmarking

Only after all prior gates pass:

1. Authenticate through the normal staging login flow using locally protected credentials.
2. Verify admin, staff, and student roles from sanitized authentication results without printing tokens.
3. Verify the exact protected read endpoints needed by the benchmark, using GET only after login setup is approved.
4. Confirm failed authentication is treated as failure, not as a performance sample.
5. Confirm no request targets production and no write endpoint is included in the benchmark runner.
6. Record only aggregate timings, status codes, payload sizes, and telemetry headers.

If any role receives unexpected access, missing-profile, missing-association, or unrelated-record results, stop benchmarking and do not “repair” the fixture by overwriting an existing record.

## Abort conditions

Stop immediately if any of the following occurs:

- Hostname or database cannot be verified as staging.
- Owner approval is missing or ambiguous.
- Any proposed identifier already exists.
- A write returns an ambiguous timeout.
- A returned document does not match the exact synthetic identity.
- A pre-existing profile, group, class, or staff-access record would need to be modified.
- An association would require replacing an array containing unrelated members.
- Cleanup would require deleting a record whose creation ownership cannot be proven.
- A route would affect unrelated ordering, permissions, or references without explicit approval.

## Operations that cannot be safely rolled back with the current routes

The following actions do not have a fully isolated rollback in the current implementation:

- Deleting a group, because `renumberGroups()` may update unrelated group ordering.
- Removing or correcting a pre-existing staff-access record, because the available PUT route replaces the full access set and no dedicated delete route was identified.
- Removing class/group references from unrelated existing records.
- Cleaning up any related messages, attendance, diary, resources, images, or other records because credential/profile/group deletion is non-cascading and no single fixture transaction exists.
- Retrying an ambiguous create after a network failure without first resolving whether the first request succeeded.

These cases require owner-approved administrative cleanup or a disposable database clone. They must not be handled by ad-hoc broad deletes.

## Final approval gate

This document is a sequencing plan only. Do not execute Step 1 or any subsequent step until the application owner approves the exact identifiers, payloads, association representation, staging database, secret method, and cleanup limitations. Phase 1 optimization remains out of scope.

## Revision: disposable-clone requirement

The following safeguards are mandatory overrides for every step above:

1. A disposable staging database clone is the required execution target before any fixture creation. The shared `mmhs_staging` database must not receive synthetic fixture writes unless the application owner explicitly documents that a clone is unavailable and separately accepts every shared-staging side effect.
2. The temporary backend/service used for the clone must be verified to point to the clone database before Step 1. The approved public staging host remains `https://school-app-1uep.onrender.com`; no production host is permitted. If the approved host cannot safely be directed to the clone, use an owner-approved isolated staging service rather than writing to the shared host/database.
3. Group creation is optional. Do not execute Step 7 or Step 8 unless the planned benchmark specifically requires group authorization. Student and staff measurements that do not require group membership must omit the group fixture entirely.
4. Never modify a pre-existing `stf-access` document. If any access record exists for the proposed staff identity, abort. A newly inserted synthetic access document may be created only when an owner-approved isolated cleanup method exists before creation.
5. Record the exact MongoDB `_id` privately, outside Git, for every credential/profile/class/group/access fixture created. Do not record raw documents, passwords, tokens, personal data, or connection strings.
6. Keep all creation and association operations sequential. Do not run concurrent creates or automatic retries.
7. If a create operation times out or otherwise has an ambiguous result, perform an exact read-back using the approved synthetic identifier and verify the returned identity before deciding whether to continue. Never blindly retry.
8. Cleanup is non-cascading. Credential deletion does not remove profiles; profile deletion does not remove credentials, memberships, access, messages, attendance, diary, resources, or images. The operator must maintain an exact fixture inventory and owner-approved cleanup sequence.
9. Group deletion remains unsafe as an isolated rollback because the route invokes `renumberGroups()`, which can update unrelated group ordering. Prefer clone disposal over group deletion. If shared staging is exceptionally approved, the owner must approve an ordering inventory and side-effect review first.
10. If the clone, isolated staff-access cleanup method, exact `_id` ledger, or owner approval is missing, stop before any write.

These requirements supersede any earlier wording that allowed shared-staging creation as the normal path. Phase 1 remains out of scope.

## Source documents

- [PHASE0_SYNTHETIC_ACCOUNT_CREATION_PLAN.md](./PHASE0_SYNTHETIC_ACCOUNT_CREATION_PLAN.md)
- [PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md](./PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md)
- [PHASE0_STAGING_ROUTE_VALIDATION_REPORT.md](./PHASE0_STAGING_ROUTE_VALIDATION_REPORT.md)
- [backend/user_management.js](./backend/user_management.js)
- [backend/server.js](./backend/server.js)

