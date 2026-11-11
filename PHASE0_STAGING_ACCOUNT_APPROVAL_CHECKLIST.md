# Phase 0 Staging Account Approval Checklist

Status: **Awaiting explicit application-owner approval**

This document proposes synthetic staging fixtures for Phase 0 read-only performance measurements. No accounts, profiles, classes, groups, access records, or other database records were created by this checklist.

## Verified staging target

- Approved backend hostname: `school-app-1uep.onrender.com`
- Approved URL: `https://school-app-1uep.onrender.com`
- Render service configuration: repository `awencetech/school_app`, branch `master`, root directory `backend`, start command `npm start`
- Staging database name: `mmhs_staging`
- Staging migration guard: `RUN_STARTUP_MIGRATIONS=false`
- MongoDB target validation is configured for the staging MongoDB deployment. The connection string and credentials are intentionally not recorded here.
- Read-only verification performed: `GET /health` and `GET /ready` only.
- No `POST`, `PUT`, `PATCH`, or `DELETE` endpoint was invoked.

## Proposed synthetic identifiers

The identifiers below contain no real-person information and use the reserved `example.invalid` email domain. They are proposals, not confirmed existing records. A collision check and owner approval are required before creation.

| Role | Proposed user ID | Proposed email identifier | Proposed profile ID | Status |
|---|---|---|---|---|
| Admin | `phase0-admin-20261111` | `phase0-admin-20261111@example.invalid` | None required for the credential | Awaiting approval |
| Staff/Teacher | `phase0-staff-20261111` | `phase0-staff-20261111@example.invalid` | Employee ID `phase0-staff-20261111` | Awaiting approval |
| Student | `phase0-student-20261111` | `phase0-student-20261111@example.invalid` | Student ID `phase0-student-20261111` | Awaiting approval |

The date suffix is based on the checklist preparation date. The application owner must confirm that these identifiers do not already exist in staging before authorizing creation.

## Minimum credential fields

The existing protected user-creation validation in `backend/user_management.js` requires:

- `userId`: non-empty string, maximum 128 characters
- `email`: valid email address
- `password`: 8–128 characters; the value must be generated and supplied through an approved secret mechanism, never recorded in this file
- `role`: canonical role `admin`, `staff`, or `student`

The user-creation route is admin-protected. Account creation therefore requires an already authorized staging administrator session and explicit owner approval.

No password, token, cookie, connection string, or secret value is included in this checklist.

## Required synthetic profile records

### Admin

The proposed admin requires only the credential record for the intended benchmark. No admin profile record is proposed unless the application owner identifies a dashboard-specific required fixture.

### Staff/Teacher

The existing staff-profile validation requires these fields:

| Field | Proposed synthetic value |
|---|---|
| `name` | `Phase 0 Synthetic Staff` |
| `designation` | `Synthetic Teacher` |
| `employeeCategory` | `Teaching` |
| `employeeId` | `phase0-staff-20261111` |
| `teaches` | `Synthetic Subject` |
| `role` | `staff` |

Optional personal fields such as phone number, address, email contact, hobbies, image URL, and biography should remain unset. No real-person information is required.

### Student

The existing student-profile validation requires:

| Field | Proposed synthetic value |
|---|---|
| `name` | `Phase 0 Synthetic Student` |
| `className` | `PHASE0-CLASS-2026` |
| `studentId` | `phase0-student-20261111` |
| `section` | `P0` (proposed association value) |

Optional parent, phone, address, hobbies, special-needs, image, and biography fields should remain unset.

## Required class, group, and staff-access associations

The student profile requires a class name, but the protected dashboard and class/group measurements may also require actual class/group documents and membership/access relationships.

### Proposed class fixture

| Field | Proposed synthetic value |
|---|---|
| ID | `phase0-class-20261111` |
| Name | `Phase 0 Synthetic Class` |
| Type | `class` |
| Code/description | `PHASE0-CLASS-2026` |
| Year | `2026-27` |
| School | `default-school`, only if that is the approved staging school context |
| Members | Synthetic student only, after a separately approved association step |
| Teachers | Synthetic staff only, after a separately approved association step |

The existing class-creation route initially creates empty `students` and `teachers` arrays. Membership must therefore use the application’s existing approved admin workflow or the corresponding existing association route; no association write is authorized by this checklist.

### Proposed group fixture

| Field | Proposed synthetic value |
|---|---|
| ID/group ID | `phase0-group-20261111` |
| Name | `Phase 0 Synthetic Group` |
| Type | `Benchmark` |
| Code/description | `PHASE0-GROUP-20261111` |
| Year | `2026-27` |
| School | `default-school`, only if approved for staging |
| Members | Synthetic student only, after approval |
| Teachers | Synthetic staff only, after approval |

The group route also creates empty membership arrays initially. Adding the synthetic student and staff requires an explicitly approved follow-up operation.

### Staff class access

The staff class-read path applies staff access filtering through class identifiers. If staff-class benchmarking is required, the proposed access fixture is:

- staff identity: `phase0-staff-20261111`
- allowed class ID: `phase0-class-20261111`
- access field: `classTeacherIds`

Creating or updating that access record is a database write and remains blocked pending owner approval.

## Required approvals before any creation

The application owner must explicitly approve all of the following:

- Use of `https://school-app-1uep.onrender.com` as the only target.
- Use of the staging database `mmhs_staging`; production is out of scope.
- The exact synthetic identifiers in this document, or approved replacements.
- Creation of the three staging credentials.
- Creation of the staff and student profile records.
- Creation of the synthetic class and group fixtures.
- Association of the student and staff with the class/group.
- Creation of staff class access if staff class measurements require it.
- The approved secret-storage method for passwords and resulting role tokens.
- An expiration date or cleanup deadline for all synthetic records.
- The person responsible for approving and executing cleanup.
- Confirmation that no real customer, parent, student, teacher, or staff information will be used.

Approval must be recorded outside this file by the application owner. No approval is inferred from preparing this checklist.

## Local-only credential configuration after approval

The existing benchmark runner uses these local environment variable names:

- `BASELINE_BASE_URL`
- `BASELINE_TARGET_ENV`
- `BASELINE_STAGING_HOST`
- `BASELINE_ADMIN_TOKEN`
- `BASELINE_STAFF_TOKEN`
- `BASELINE_STUDENT_TOKEN`
- `BASELINE_LOGIN_IDENTIFIER`
- `BASELINE_LOGIN_PASSWORD`
- Optional: `BASELINE_IMAGE_PATH`

The runner does not use `BASELINE_LOGIN_TOKEN` for login. Configure values only in the local shell or an approved local secret manager. Do not put them in tracked files, reports, command history, screenshots, or chat. Use `BASELINE_TARGET_ENV=staging`, set the base URL to the approved hostname, and verify the runner rejects any non-approved target before execution.

The benchmark must use the existing authentication format and existing read-only GET cases. Login is the only existing benchmark action that uses POST, and it must not be run under the current no-write restriction unless separately approved as an authorized authentication-only action.

## Benchmark safety and cleanup scope

### Measurement scope

After approval and secure token configuration, the benchmark may measure only the existing authorized read paths. It must not create messages, attendance, diary entries, resources, classes, groups, or other records.

### Cleanup scope

Cleanup must be approved and performed against staging only. The complete cleanup inventory is:

1. Synthetic admin, staff, and student credential records.
2. Synthetic staff profile and student profile records.
3. Synthetic class and group documents.
4. Student and staff class/group memberships.
5. Staff class-access records.
6. Any explicitly approved synthetic supporting fixtures created for a measurement.
7. Local tokens, passwords, cookies, and environment-variable values from the benchmark shell and secret manager.

Deleting a credential alone may not remove its staff/student profile or class/group relationships. Cleanup must therefore follow the application’s existing admin cleanup workflow or an owner-approved staging database procedure that identifies only these exact synthetic IDs. No broad collection deletion, reset, migration, or production operation is permitted.

Retain only aggregate performance reports. Do not retain raw response bodies, personal data, passwords, tokens, cookies, or MongoDB credentials.

## Current blockers

- Explicit application-owner approval has not been provided.
- Identifier collision has not been checked because that requires an approved staging read/authenticated administrative workflow.
- No synthetic records have been created.
- Role tokens and login credentials are not available to this checklist and must be supplied through an approved local secret mechanism after approval.
- The exact existing class/group membership and staff-access write route still requires owner-approved execution; this checklist intentionally does not invoke it.

## Approval decision

**Do not create anything yet.** Proceed only after the application owner explicitly approves the proposed identifiers, required records, associations, secret-storage method, expiration, and cleanup scope above.

## Revision: mandatory disposable-clone safeguards

The approval checklist is revised as follows:

- A disposable staging database clone is the preferred **and required** path before any synthetic credential, profile, class, group, membership, or access record is created.
- The clone must be isolated from the shared `mmhs_staging` data and must be verified before writes. The approved staging host remains `https://school-app-1uep.onrender.com`; production is never an allowed target. If that host cannot be safely connected to the clone, an owner-approved isolated staging service is required.
- Group creation is optional and must be omitted unless a planned protected benchmark requires group authorization.
- A pre-existing staff-access record must never be modified. If one exists for the synthetic staff identity, the fixture request is blocked.
- Any newly inserted staff-access record requires an owner-approved isolated cleanup method before creation. The current PUT upsert route is not itself a delete or rollback method.
- The private execution ledger must record the exact MongoDB `_id` for every created fixture: credential, staff profile, student profile, class, optional group, and optional staff-access record.
- Creation and association operations must be sequential. Ambiguous create responses require exact read-back; blind retries are prohibited.
- Cleanup is non-cascading and must separately inventory credentials, profiles, memberships, access, and any approved supporting records.
- Group deletion is not an isolated cleanup action because it calls `renumberGroups()` and may update unrelated ordering. Prefer clone disposal and avoid group creation unless necessary.

### Additional owner approvals required

Before requesting execution, the owner must approve:

1. Provisioning and disposal of the clone.
2. The clone database name and restricted connection mechanism, without recording its secret.
3. The temporary service/host mapping used to ensure no shared or production database is reached.
4. The exact `_id` ledger and retention/destruction procedure.
5. The isolated cleanup method for a newly inserted staff-access record.
6. The optional group benchmark justification, if group fixtures are requested.
7. The cleanup procedure for all non-cascading related records.

Until these approvals exist, the checklist remains a planning artifact and no write is authorized.

