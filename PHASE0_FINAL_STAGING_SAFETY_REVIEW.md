# Phase 0 Final Staging Safety Review

Status: **Source-only review complete. No API endpoint was called, no MongoDB connection was opened, no account was created, no record was modified or deleted, and production was not accessed.**

Reviewed:

- [PHASE0_STAGING_EXECUTION_SEQUENCE.md](./PHASE0_STAGING_EXECUTION_SEQUENCE.md)
- [PHASE0_SYNTHETIC_ACCOUNT_CREATION_PLAN.md](./PHASE0_SYNTHETIC_ACCOUNT_CREATION_PLAN.md)
- [PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md](./PHASE0_STAGING_ACCOUNT_APPROVAL_CHECKLIST.md)
- [PHASE0_STAGING_ROUTE_VALIDATION_REPORT.md](./PHASE0_STAGING_ROUTE_VALIDATION_REPORT.md)
- [backend/user_management.js](./backend/user_management.js)
- [backend/server.js](./backend/server.js)

## Final conclusion

The proposed credential and profile creation sequence can be made reasonably target-specific, but the current routes do not provide an isolated, reliable rollback for every proposed fixture. In particular:

- Group deletion invokes `renumberGroups()`, which can change unrelated group ordering.
- Staff-access mutation is an upsert with full-array replacement and no dedicated delete route was identified.
- Profile, class, group, and credential deletion are non-cascading, so related records and references can remain behind.
- The generic group update route replaces membership arrays and must never be used against an existing group containing unrelated members.

## 1. Can all proposed records be cleaned up safely?

**No, not with complete isolation using the current routes.**

| Record | Exact target possible? | Existing cleanup | Isolation assessment |
|---|---:|---|---|
| Admin credential | Yes, by synthetic user ID or credential `_id` | `DELETE /api/users/:id` | Generally isolated if creation ownership and exact identity are proven; non-cascading |
| Staff credential | Yes | `DELETE /api/users/:id` | Generally isolated for the credential; does not remove profile/access |
| Student credential | Yes | `DELETE /api/users/:id` | Generally isolated for the credential; does not remove profile/group data |
| Staff profile | Yes, but requires returned profile Mongo `_id` | `DELETE /api/staff/:id` | Isolated to one profile if `_id` is exact; does not cascade |
| Student profile | Yes, but requires returned profile Mongo `_id` | `DELETE /api/students/:id` | Isolated to one profile if `_id` is exact; does not cascade |
| Class | Yes, by exact ID plus school scope | `DELETE /api/classes/:id` | Narrow deletion, but references in staff access or other documents remain |
| Group | Usually yes for the target document | `DELETE /api/groups/:id` | Not fully isolated because `renumberGroups()` updates other groups |
| Staff-access record | Staff ID identifies the upsert target | No dedicated delete route identified | Not safely reversible if it pre-existed; empty-array PUT could remove permissions |
| Membership arrays | Target group/class can be identified | Group PUT replaces arrays; class PUT does not manage arrays | Safe only for a newly created empty fixture; unsafe for pre-existing records |

The sequence correctly requires proof that every target was absent and newly created by the current run. That condition materially reduces the risk, but it does not eliminate the group-renumbering and staff-access rollback problems.

## 2. Synthetic group cleanup

There is no fully safe group cleanup route in the current implementation.

`DELETE /api/groups/:id` resolves and deletes the selected group, then calls `renumberGroups()`. This means a synthetic group deletion can rewrite the `order` values of unrelated group documents. The target deletion itself can be exact, but the complete operation is not isolated.

Recommended handling:

- Prefer not to create a group in the shared staging database if a disposable clone is available.
- If shared staging is the only option, require owner approval for the ordering side effect and capture a private before/after ordering inventory of unrelated groups.
- Never delete a group by broad type, name pattern, or collection-wide script.
- Never treat a successful delete response as proof that no unrelated documents changed.

The existing execution sequence appropriately flags this limitation, but group creation should remain optional and blocked unless the measurement genuinely requires group membership authorization.

## 3. Synthetic staff-access cleanup

There is no dedicated staff-access delete route in the inspected source.

`PUT /api/stf-access/:staffId` performs an upsert and writes the complete `accessGroups`, `groupIds`, and `classTeacherIds` arrays. Sending empty arrays to remove access is not an isolated cleanup method because it can erase permissions from a pre-existing staff record.

Safe condition:

- Only create staff access after proving that no access document exists for the synthetic staff identity.
- Record that the upsert inserted a new document for this run.
- Use an owner-approved administrative cleanup method that deletes only that newly inserted synthetic access document, or use a disposable database clone.

Unsafe condition:

- If an access document already exists, do not update it, merge into it, replace its arrays, or delete it. Abort and escalate.

The current sequence correctly identifies this as a blocker and must retain that gate.

## 4. Can creation operations be verified using exact synthetic IDs?

**Mostly, with important limits.**

### Credentials

`POST /api/users` validates the exact `userId` and email, checks conflicts across role-specific credential collections and the legacy collection, and returns a sanitized identity. The creation route uses a check-then-insert sequence rather than an atomic application-level reservation. Therefore:

- Create sequentially, never concurrently.
- Treat a timeout as ambiguous and resolve it with an exact read before retrying.
- Require the returned role and identifier to match exactly.

### Staff and student profiles

The proposed employee ID and student ID are exact lookup keys for creation verification. Cleanup still requires the returned Mongo `_id`. The profile response must be checked for the expected synthetic identity before recording that the fixture is owned by the run.

### Class

Class creation checks `id` within `schoolId`, and deletion is scoped by class type and school ID. The exact class ID plus captured `_id` is sufficient for a narrow target inventory, but deletion does not remove references elsewhere.

### Group

Group creation checks the group `id` globally in the groups collection. The exact group ID is suitable for collision checking, but deletion still has the unrelated-ordering side effect described above.

### Staff access

The staff ID identifies the upsert target, but exact identification does not make overwriting safe. The operator must verify absence before creation and record whether the operation inserted a new document.

## 5. Route assumptions that require correction or qualification

The prior reports and sequence are substantially accurate, with these qualifications:

1. **Class membership is not supported by `PUT /api/classes/:id`.** That route updates class metadata only. The generic `PUT /api/groups/:id` route accepts `students` and `teachers` arrays and can conditionally handle an existing class, but that is a full replacement operation and is not a dedicated additive class-membership API.
2. **Group membership is replacement, not append.** Any supplied `students` or `teachers` array replaces the existing array.
3. **Group deletion is not isolated.** It calls `renumberGroups()` after deleting the target.
4. **Staff access is not additive.** The PUT route replaces all three access arrays and uses upsert semantics.
5. **Credential deletion is non-cascading.** It removes only the login credential.
6. **Staff/student profile deletion requires Mongo `_id`.** Synthetic employee/student IDs alone are not valid cleanup targets for those routes.
7. **Default school context must not be assumed.** The source defaults many routes to `default-school`, but the owner must approve that context for the staging fixture rather than relying on the default.
8. **A successful create response is not sufficient after an ambiguous network failure.** Exact read-back and creation ownership must be established before retry or cleanup.

## 6. Disposable staging database clone assessment

**A disposable clone is the safer alternative.** It reduces the risk that synthetic fixture creation, group ordering changes, access upserts, and non-cascading cleanup affect shared staging data.

Preferred arrangement:

1. Clone the approved staging database into an isolated database with a distinct database name and restricted credentials.
2. Point a temporary backend instance or isolated staging service at that clone.
3. Verify the service target and database name before any write.
4. Create the synthetic fixtures and run measurements there.
5. Destroy the disposable clone using the database owner’s approved lifecycle procedure after retaining only aggregate reports.

The clone must be provisioned and destroyed by the authorized infrastructure/database owner. This review does not authorize clone creation, data copying, or any database operation.

If a clone cannot be provided, the shared staging workflow should not create the group or staff-access fixtures until the owner explicitly accepts the rollback limitations and supplies an isolated cleanup procedure.

## Required safeguards before requesting approval

Before requesting creation approval, add these conditions to the approval record:

- Use a disposable database clone, or explicitly accept the shared-staging side effects in writing.
- Do not create a group unless group authorization is required for the planned measurements.
- Do not modify any pre-existing staff-access document.
- Require an owner-approved delete method for a newly inserted synthetic staff-access document.
- Record returned Mongo `_id` values privately for staff, student, class, group, and access fixtures.
- Treat ambiguous create responses as a stop condition requiring exact read-back.
- Keep the fixture sequence single-threaded.
- Define how non-cascading related records will be inventoried and cleaned.
- Do not benchmark until every fixture’s ownership and cleanup path is confirmed.

## Final recommendation

# NOT SAFE — ADDITIONAL SAFEGUARDS REQUIRED

Do not request creation approval for the full fixture set in the shared staging database yet. First obtain a disposable staging database clone, or obtain explicit owner approval for the group-renumbering side effect and an isolated cleanup method for the synthetic staff-access document. 񟿿

