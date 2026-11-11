# Phase 1 Messages Inbox Contract Test Report

## Scope and safety

This step establishes a before-change contract baseline for `GET /api/messages/inbox`. No runtime route, API contract, Flutter code, database, index, deployment, or Git operation was changed. All fixtures are in-memory synthetic objects.

The authoritative repository is `D:\education_app`. Existing unrelated working-tree changes were preserved.

## Files inspected

- `backend/server.js`: `/api/messages/inbox`, `requirePtmReader`, role normalization, recipient filtering, profile lookup, collection reads, merge/sort, and `sanitizeStudentMessageForResponse`.
- `backend/user_management.js` and `backend/authorization.js`: existing test/authentication setup and authorization conventions.
- `backend/package.json`: Node test command (`node --test test/*.test.js`).
- `Education_App/lib/services/admin_message_service.dart`: inbox request, envelope parsing, timeout, and model conversion.
- `Education_App/lib/models/admin_message.dart`: client fields consumed from the response.
- `Education_App/lib/screens/messages/messages_page.dart`: message-page loading and presentation mapping.
- `Education_App/lib/screens/staff/staff_group_messages_page.dart` and `Education_App/lib/screens/staff/staff_overview_dashboard_page.dart`: staff consumers.
- `PHASE1_MESSAGES_INBOX_OPTIMIZATION_PLAN.md` and `PHASE1_BACKEND_READ_AUDIT.md`.

Key source locations: role normalization at `backend/server.js:114`, `requirePtmReader` at `backend/server.js:597`, sanitizer at `backend/server.js:1093`, recipient filtering at `backend/server.js:1127`, and the inbox route at `backend/server.js:1145`. The two inbox reads are at `backend/server.js:1178` and `backend/server.js:1196`; merge/sanitize/sort is at `backend/server.js:1198`.

## File changed

- `backend/test/messages_inbox_contract.test.js`: new isolated contract and projection-coverage tests only.

`server.js` is not imported by the new test because importing it unconditionally starts the HTTP listener and attempts MongoDB startup. The test harness mirrors the current route/sanitizer contract with in-memory fixtures; this avoids changing production code merely to make it testable. This is a limitation of the baseline, not a claim that the live route was exercised.

## Existing response contract

The route returns the following envelope on success:

```json
{"success":true,"data":[/* sanitized message objects */]}
```

The sanitizer currently emits exactly these fields for every item:

`id`, `subject`, `title`, `message`, `content`, `messageType`, `category`, `senderId`, `senderName`, `senderEmail`, `senderRole`, `studentId`, `studentName`, `recipientId`, `recipientLabel`, `groupId`, `groupName`, `isViewed`, `read`, `createdAt`, `updatedAt`.

Fallback behavior captured by the tests:

- `id`: `_id.toString()`, then `id`, then `''`.
- `subject`/`title`: subject and title fall back to each other.
- `message`/`content`: message and content fall back to each other.
- `messageType`/`category`: each falls back to the other, then `General`.
- `senderId`/`studentId`: sender and student identifiers fall back to each other.
- `senderName` and `studentName`: default to `Student` where no name is present.
- `recipientLabel`: falls back to `groupName`.
- `isViewed` and `read`: either true source flag makes both true.
- `updatedAt`: falls back to `createdAt`, while `createdAt` defaults to `null`.
- Missing string fields default to `''`.

The route merges current `student-message` results with legacy `groupMessages` results and sorts the sanitized combined list descending by the string value of `createdAt`.

## Actual-source comparison and corrections

The first version of the isolated harness was compared against the source and had these mismatches. All were corrected before the final test run:

1. Role normalization used a simplified helper that did not match the inbox-specific `normalizedMessageRole`. It was changed to trim/lowercase and map only `administrator -> admin` and `teacher -> staff`, matching `backend/server.js:1120` behavior. The broader application `normalizeRole` is a different helper and was not substituted.
2. Recipient matching treated a missing `recipientRole` as an empty role. MongoDB `$in` does not match a missing `recipientRole`; the harness now requires the field to be present for the role-based empty/null-recipient branches.
3. The harness used a broad “unaddressed document” fallback. The real `messageRecipientFilter` has only direct ID, username, empty recipient ID plus allowed role, and null recipient ID plus allowed role. The fallback was removed.
4. The real direct query has a second `$or` for current recipient ID/username, sender ID, null/empty group ID/name, and profile group values. The harness now models that separate conjunction and does not collapse it into the recipient filter.
5. Student-sent messages are added to `recipientScope` only for students and still must satisfy the second target `$or`; the harness now requires both conditions.
6. Profile group values include the joined class/section expression whenever either component produces a non-empty joined value. The harness now uses the same `filter(Boolean).join('-')` construction.
7. Legacy messages allow only `senderRole` values `admin`, `staff`, and `teacher`; `administrator` is not in the live legacy filter. The harness and fixtures now reflect this and include an explicit exclusion test.
8. Legacy group matching is based on `groupId: null`, `groupId: ''`, or matching `groupId`/`groupName` values. It is not a combined “both group fields empty” condition. The harness now models MongoDB null/missing behavior for `groupId`.
9. The sanitizer returns `null` for a null document. The harness now includes this branch.

The following behavior matched without correction: sanitizer fallback precedence, BSON-like `_id.toString()` conversion, the 21-field response object, descending string timestamp sorting, and stable ordering for equal timestamps on the current Node runtime.

## Coverage of requested cases

The new tests cover:

- Student current-format direct messages.
- Legacy `groupMessages` messages using title/content/category fallbacks.
- Mixed-format documents with missing optional fields.
- Direct-recipient and group-recipient matching.
- Student-sent messages.
- Admin, staff, student roles and `administrator`/`teacher` aliases.
- Empty inbox response.
- Missing bearer authentication, malformed authentication, and invalid role authorization.
- Exact success envelope and sanitized field set.

The test fixture for non-student legacy recipients reflects the current route’s behavior: `sendToStaff` is selected for every non-student role, including administrators. `sendToStudents` is selected for students. It also verifies that a legacy source document whose `senderRole` is literally `administrator` is excluded by the current legacy filter.

## Projection verification

The proposed sanitizer projection coverage set is:

`_id`, `id`, `subject`, `title`, `message`, `content`, `messageType`, `category`, `senderId`, `studentId`, `senderName`, `senderEmail`, `senderRole`, `studentName`, `recipientId`, `recipientLabel`, `groupId`, `groupName`, `isViewed`, `read`, `createdAt`, `updatedAt`.

Coverage result: **PASS for all sanitizer source and fallback fields**. In-memory projection tests compare the sanitized full document with the sanitized projected document for current, legacy, mixed, and viewed/read-alias fixtures.

The query predicates still use fields such as `recipientUsername`, `recipientRole`, `senderRole`, `sendToStudents`, `sendToStaff`, and group/profile fields. These fields must remain available to MongoDB’s filter, but do not need to be returned by a projection because filtering occurs in MongoDB before result serialization. Any future implementation must verify that the projection is applied to the returned documents only and does not alter the existing predicates.

## Authentication test boundary

The missing/invalid authentication test is explicitly a **simulated authorization contract test**. It checks bearer-header shape and allowed normalized roles in memory; it does not invoke `authenticateUser`, Firebase/JWT verification, `authorizeRequestRole`, `requireRecipientRole`, or the live Express route. Existing authorization tests in the full suite cover those middleware paths separately. No claim is made that the real inbox Express route was exercised.

## Test results

Focused command:

```text
cd D:\education_app\backend
node --test test/messages_inbox_contract.test.js
```

Result: **11 passed, 0 failed, 0 skipped**.

Complete backend command:

```text
cd D:\education_app\backend
npm.cmd test
```

Result: **55 passed, 0 failed, 0 skipped**.

The complete suite completed successfully without connecting this new test to a real MongoDB database or using real accounts.

## Uncovered or limited compatibility cases

1. The live inbox Express handler was not invoked because `server.js` has import-time startup and MongoDB side effects and does not export the app or handler. Direct live-route testing would require a separate testability change, which is outside this contract-only step.
2. The tests do not prove MongoDB query-plan behavior, result ordering under equal timestamps, or collection-level filtering against real documents.
3. The tests do not verify the authentication middleware’s JWT cryptography; the inbox test’s auth case is simulated only. Existing authorization tests remain green.
4. ObjectId conversion is represented by string-compatible synthetic IDs. A real BSON ObjectId serialization test would require a MongoDB/BSON dependency path and is not necessary for projection field coverage.
5. Flutter consumers use the `data` list and the sanitized message fields, but no Flutter files were changed or executed in this step.

## Approval boundary

This report is a baseline only. A later projection-only change should first use these tests, then add a live/mock collection integration test if the project introduces a safe dependency-injection seam. No projection was added to the live queries, and no sorting, pagination, deduplication, filtering, or sanitizer behavior was changed.
