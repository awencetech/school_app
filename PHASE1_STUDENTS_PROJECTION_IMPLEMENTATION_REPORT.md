# Phase 1 Students Projection Implementation Report

## Scope

Implemented only the projection-only optimization for `GET /api/students`. No pagination, limit, filter, authorization, staff-helper, sanitizer, response, Flutter, database, index, migration, deployment, commit, or push changes were made.

## Files changed for this task

- `backend/server.js`
  - Added `STUDENT_LIST_PROJECTION` near `sanitizeStudentForResponse`.
  - Applied it only to the existing `studentInfoCollection.find({})` read inside `GET /api/students`.
- `backend/test/students_contract.test.js`
  - Added synthetic in-memory contract tests and source-level assertions.
- `PHASE1_STUDENTS_PROJECTION_IMPLEMENTATION_REPORT.md`
  - This report.

The working tree already contained unrelated Phase 0/Phase 1 artifacts and an earlier Messages Inbox projection change in `backend/server.js`. That existing Messages Inbox change was preserved and not modified as part of this task.

## Exact projection

```js
const STUDENT_LIST_PROJECTION = Object.freeze({
  _id: 1,
  id: 1,
  name: 1,
  className: 1,
  section: 1,
  studentId: 1,
  admissionNumber: 1,
  admissionNo: 1,
  parentName: 1,
  mobileNumber: 1,
  address: 1,
  about: 1,
  hobbies: 1,
  specialNeeds: 1,
  special_needs: 1,
  role: 1,
  imageUrl: 1,
  createdAt: 1,
  updatedAt: 1,
});
```

All 19 requested fields are present, including `_id`. The projection includes `admissionNo`, `id`, and `_id` because staff filtering currently runs after the MongoDB read and supports all five identifier variants.

## Exact route change

The existing route now uses:

```js
studentInfoCollection
  .find({}, { projection: STUDENT_LIST_PROJECTION })
  .sort({ createdAt: -1, _id: -1 })
  .toArray();
```

The empty filter, sort, `toArray()`, staff post-read authorization filter, sanitizer, bare JSON array response, and error handling are unchanged. Shared staff helpers were not changed.

## Contract tests

`backend/test/students_contract.test.js` covers:

1. All 19 projection fields and `_id`.
2. Source-level confirmation that the students read uses the shared projection.
3. Admin sanitized-record equivalence before/after projection.
4. Staff authorized-record equivalence.
5. `id`, `_id`, `studentId`, `admissionNo`, and `admissionNumber` access identifiers.
6. `special_needs` fallback.
7. Missing-field defaults.
8. BSON-like `_id` and `id` fallback behavior.
9. Created-at and `_id` sorting/tie-breaking preservation.
10. Empty collection and error response behavior.
11. Bare JSON array response shape.
12. Student-role denial contract.

The test harness is synthetic and does not import `server.js` or connect to MongoDB. The source-level assertions do not claim live Express route execution.

## Validation results

Focused command:

```text
cd D:\education_app\backend
node --test test/students_contract.test.js
```

Result: **10 passed, 0 failed, 0 skipped**.

Full backend command:

```text
cd D:\education_app\backend
npm.cmd test
```

Result: **66 passed, 0 failed, 0 skipped**.

## Diff review

The task-specific runtime diff adds one frozen projection constant and one projection option to the existing `/api/students` collection read. No other student route or shared helper was changed. The existing Messages Inbox projection lines remain in `server.js` as pre-existing working-tree changes and were not altered.

## Safety confirmation

- No database connection or query was made.
- No data, indexes, schemas, or migrations were changed.
- No Flutter files were changed.
- No production or staging API was accessed.
- No deployment, commit, or push occurred.
- Unrelated working-tree changes were preserved.
