# Phase 0 Staging Route Validation Report

Status: **Source inspection complete; no API, MongoDB, or write operation was performed.**

Scope: validation of the proposed synthetic staging account, profile, class, group, and staff-access workflow against the current backend source.

## Executive summary

The proposed credential and profile fields are broadly correct, but the approval checklist needs operational safeguards before any creation is authorized:

1. User creation checks `userId` and `email` conflicts across role-specific credential collections and the legacy users collection, but the source does not show database-level uniqueness enforcement for the new credential insert in the route itself. Creation should therefore treat a conflict response as mandatory and avoid concurrent duplicate attempts.
2. Staff and student profile records are separate from login credentials. Deleting a login credential does not delete its related school record.
3. Staff and student profile deletion routes require the Mongo `_id`, not the synthetic employee/student identifier. Cleanup must first resolve the exact synthetic profile document through an approved admin workflow without broad or ambiguous deletion.
4. Group deletion calls `renumberGroups()`, which can update unrelated group ordering. It is not an isolated cleanup operation.
5. Group updates accept replacement `students` and `teachers` arrays. An incorrect update can overwrite existing membership.
6. Staff-access updates are an upsert that replaces `accessGroups`, `groupIds`, and `classTeacherIds` for the selected staff member. An incorrect payload can remove existing staff permissions.
7. Class creation starts with empty `students` and `teachers` arrays. The class route’s PUT handler does not accept membership arrays; membership handling must use a separately verified existing workflow. The generic group PUT route can accept arrays for an existing class, but using it for class membership requires explicit owner approval because of the overwrite risk.

## Route matrix

| Operation | Method and endpoint | Auth/authz | Required validation | Database effect | Duplicate/target behavior | Cleanup assessment |
|---|---|---|---|---|---|---|
| List users | `GET /api/users` | Authenticated admin | Optional `role`; must be a supported role | Reads role credentials | No write | Read-only collision inspection, but response contains account identifiers and must not be saved or printed |
| Create login credential | `POST /api/users` | Authenticated admin | Exactly `userId`, `email`, `password`, `role`; user ID non-empty/max 128; valid email; password 8–128; role `admin`, `staff`, or `student` | Inserts into role-specific credential collection | Checks user ID and email conflicts across role collections and legacy users; returns 409 on conflict | `DELETE /api/users/:id` removes only the credential, not school records; admin cannot delete own credential |
| Delete login credential | `DELETE /api/users/:id` | Authenticated admin | ID non-empty/max 128; legacy credentials rejected; self-delete rejected | Deletes one credential document | Requires exact credential lookup | Safe only for an approved synthetic user ID; does not cascade |
| Create staff profile | `POST /api/staff` | Admin | `name`, `designation`, `employeeCategory`, `employeeId`, `teaches`, `role` must be non-empty | Inserts one employee-info document | `employeeId` must resolve to a staff credential; existing `employeeId` returns 409 | Separate `DELETE /api/staff/:id` requires profile `_id`; no cascade to credential or access |
| Delete staff profile | `DELETE /api/staff/:id` | Admin | Mongo `_id` is converted to `ObjectId` | Deletes one employee-info document | 404 if no matching `_id` | Does not delete credential or staff-access document |
| Create student profile | `POST /api/students` | Admin | `name`, `className`, `studentId` must be non-empty | Inserts one student-info document | Case-insensitive `studentId` pre-check plus duplicate-key handling; returns 409 | Separate `DELETE /api/students/:id` requires profile `_id`; no cascade |
| Delete student profile | `DELETE /api/students/:id` | Admin | Mongo `_id` is converted to `ObjectId` | Deletes one student-info document | 404 if no matching `_id` | Does not delete credential, class/group membership, attendance, messages, or other records |
| Create class | `POST /api/classes` | Admin | `name`, `id`, `type=class`, `description` or `code`, `year`; optional status/schoolId | Inserts one class document with empty `students` and `teachers` arrays; computes order using count | Duplicate `id` within `schoolId` returns 409 | `DELETE /api/classes/:id` is scoped by `schoolId` and class type; no cascade |
| Update class metadata | `PUT /api/classes/:id` | Admin | Existing class; `name`, `id`, `type=class`, description/code, year; duplicate ID check within school | Updates class metadata only | Uses `_id` or `id`/schoolId selector | Does not update membership arrays |
| Delete class | `DELETE /api/classes/:id` | Admin | `_id` or `id`, optional schoolId; target must be class | Deletes one class document | Scoped by class type and school | Does not remove staff-access references or other related records |
| List groups/classes | `GET /api/groups` | Admin, staff, or student | Optional type and schoolId | Read-only | Staff visibility filtered by access; student visibility filtered by membership | No write |
| Create group | `POST /api/groups` | Admin | `name`, `id`/`groupId`, `type`, `description`/`code`, `year`; optional status/schoolId | Inserts one group document with empty `students` and `teachers`; computes order using total group count | Duplicate `id` check is global to the groups collection, not explicitly scoped by schoolId | `DELETE /api/groups/:id` may renumber unrelated groups |
| Update group/membership | `PUT /api/groups/:id` | Admin | `name`, ID, type, description/code, year; optional `students`/`teachers` arrays replace existing arrays when supplied | Updates one group; supplied arrays replace membership | Duplicate ID check excludes current `_id`; class type checks are conditional | Dangerous if arrays are incomplete; use only with exact pre-approved full arrays |
| Delete group | `DELETE /api/groups/:id` | Admin | Resolves `_id` first, or falls back to string `id`; optional type/school checks | Deletes one group then runs `renumberGroups()` | Target checks vary by type/school | Can modify ordering of unrelated groups; not a narrowly isolated cleanup |
| Read staff access | `GET /api/stf-access` or `GET /api/stf-access/:staffId` | Admin | Existing staff lookup for parameterized route | Read-only | Broad list endpoint returns all staff access | Sensitive administrative response; do not store raw output |
| Read own staff access | `GET /api/stf-access/me` | Staff/teacher | Authenticated staff profile must exist | Read-only | 404 if profile absent | No write |
| Update staff access | `PUT /api/stf-access/:staffId` | Admin | Existing staff; arrays required: `accessGroups`, `groupIds`, `classTeacherIds`; access groups filtered to allowlist | Upserts one `stf-access` document and writes the full three access arrays | De-duplicates array values, but does not preserve omitted existing permissions | High-risk overwrite; cleanup should restore or remove only the synthetic access document after owner approval |

## Detailed validation findings

### Credentials

`backend/user_management.js` mounts authentication on the entire user-management router. The create and delete handlers require admin authorization. Creation rejects unexpected fields, hashes the password with bcrypt, and returns a sanitized user object without the password.

The repository implementation in `backend/server.js` selects a role-specific collection for inserts and checks conflicts across all role collections plus the legacy `users` collection. The route performs separate conflict reads for user ID and email before insert. This is a check-then-insert sequence, so an owner-approved creation process must not run concurrent duplicate creations.

### Staff profile

`POST /api/staff` requires the proposed staff credential to exist first. It verifies the employee ID against a staff credential, rejects an existing employee profile with the same employee ID, and inserts a document containing the required fields plus many optional fields initialized to empty strings.

The proposed checklist’s minimum required staff fields are accurate. No personal optional fields are required for a synthetic fixture.

### Student profile

`POST /api/students` requires the proposed student credential separately only by workflow convention; the route itself validates `name`, `className`, and `studentId`, then checks the student collection for a case-insensitive student-ID match. It inserts optional fields as empty strings when absent.

The proposed checklist’s minimum student fields are accurate. `section` is optional at route-validation level, but it may be required by specific student-facing data filters or dashboard fixtures and should remain part of the owner-approved fixture definition.

### Class, group, and access relationships

Student-facing group authorization looks up the student profile by `studentId` or `admissionNumber` and then requires the student identity to appear in the target group’s `students` array. Staff-facing group/class authorization looks up the employee profile, then uses `stf-access.groupIds` and `stf-access.classTeacherIds`.

Therefore, a credential and profile alone may not be sufficient for all protected dashboard measurements:

- Student group-specific measurements require a group document containing the synthetic student identity in the expected representation.
- Staff group/class measurements require a staff-access document whose IDs match the group/class `id` or `_id` representation used by the route.
- `POST /api/classes` and `POST /api/groups` create empty membership arrays, so associations are a separate mutation.

## Cleanup validation and risks

The existing routes do not provide a transactional synthetic-fixture cleanup operation. Cleanup is multi-step and must be performed in dependency-aware order by an authorized owner:

1. Stop benchmarks and revoke/clear local tokens, cookies, and secret-manager entries.
2. Remove or restore the synthetic staff-access record. Do not send empty arrays to a pre-existing staff record unless the owner explicitly approves replacing its permissions; first determine whether the record was created for the synthetic staff profile.
3. Remove synthetic group/class memberships using an exact, owner-approved update that preserves unrelated members. Avoid broad replacement arrays.
4. Delete the synthetic group or class using the exact synthetic ID and correct school/type scope. For groups, separately review the effects of `renumberGroups()`.
5. Delete the synthetic student/staff profile using the exact Mongo `_id`, not the user ID or employee/student ID.
6. Delete the synthetic login credentials using the exact synthetic user IDs.
7. Review related synthetic-only records, if any were explicitly approved. No automatic cascade exists for attendance, messages, diary, resources, images, or other collections.

The order above is a safe review sequence, not authorization to execute cleanup. No cleanup route was called during this report.

## Required corrections to the approval checklist

The existing [PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md](./PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md) should be read with these corrections:

- Replace any implication that staff/student profiles can be deleted by synthetic employee/student ID alone. The deletion routes require the Mongo profile `_id`.
- Treat `DELETE /api/groups/:id` as potentially affecting unrelated group ordering because it calls `renumberGroups()`.
- Treat group membership updates as full-array replacement, not additive association operations.
- Treat `PUT /api/stf-access/:staffId` as a full access-set replacement/upsert, not a narrow append operation.
- Do not assume a class membership association route exists based only on class creation. The class POST route creates empty arrays and the class PUT route updates metadata only; verify the approved membership workflow separately.
- The proposed `example.invalid` email identifiers satisfy the route’s syntactic email check, but uniqueness is not confirmed. A collision check must be performed through an approved staging admin workflow before creation.
- The prior checklist’s statement that no writes were performed remains correct.

## Routes that can affect unrelated records

The following routes require elevated review before use:

- `PUT /api/groups/:id`: can replace all supplied student/teacher memberships for the target document.
- `DELETE /api/groups/:id`: deletes the target and renumbers other groups.
- `PUT /api/stf-access/:staffId`: replaces the full access arrays for the selected staff member.
- `PUT /api/classes/:id`: can change a class ID, which may invalidate references held by staff-access records.
- `DELETE /api/users/:id`, `DELETE /api/staff/:id`, and `DELETE /api/students/:id`: are non-cascading and can leave orphaned related records if used without a complete cleanup inventory.
- Any write route that receives a profile or group Mongo `_id` selected from a broad list can target an unrelated record if the ID is copied incorrectly. Exact synthetic identifiers and an owner-reviewed target inventory are required.

## Approval gate and remaining blockers

No creation is approved by this source review. Before any write operation, the application owner must approve:

- Exact synthetic IDs and reserved email identifiers.
- The staging-only target and `mmhs_staging` database.
- Credential, profile, class, group, and staff-access mutations as separate steps.
- The membership representation expected by the protected read routes.
- Collision-check and target-resolution procedure.
- A cleanup operator, deadline, and exact record inventory.
- How pre-existing staff-access or group records will be preserved.

Remaining blockers are the absence of explicit owner approval, unconfirmed identifier uniqueness, unconfirmed association representation, and the lack of an isolated cleanup transaction. This report does not authorize account creation or cleanup.

## Source references

- [backend/user_management.js](./backend/user_management.js): user router validation, authorization, conflict handling, and non-cascading credential deletion.
- [backend/server.js](./backend/server.js): credential repository, staff/student routes, classes/groups CRUD, access filtering, and staff-access mutation.
- [PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md](./PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md): proposed identifiers and prior approval plan.

