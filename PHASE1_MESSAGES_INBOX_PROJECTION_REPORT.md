# Phase 1 Messages Inbox Projection Report

## Scope

Implemented only explicit MongoDB projections for the two database reads inside `GET /api/messages/inbox`. No pagination, limits, sorting, filtering, deduplication, sanitizer, API envelope, Flutter, database, index, deployment, commit, or push changes were made.

## Files changed

- `backend/server.js`
  - Added the shared `INBOX_MESSAGE_PROJECTION` constant.
  - Applied it to the existing `student-message` and `groupMessages` `find()` calls.
- `backend/test/messages_inbox_contract.test.js`
  - Added a source-level assertion confirming both inbox reads use the same complete projection.
- `PHASE1_MESSAGES_INBOX_PROJECTION_REPORT.md`
  - This report.

Existing unrelated working-tree changes were preserved.

## Exact projection

The shared projection is:

```js
const INBOX_MESSAGE_PROJECTION = Object.freeze({
  _id: 1,
  id: 1,
  subject: 1,
  title: 1,
  message: 1,
  content: 1,
  messageType: 1,
  category: 1,
  senderId: 1,
  studentId: 1,
  senderName: 1,
  senderEmail: 1,
  senderRole: 1,
  studentName: 1,
  recipientId: 1,
  recipientLabel: 1,
  groupId: 1,
  groupName: 1,
  isViewed: 1,
  read: 1,
  createdAt: 1,
  updatedAt: 1,
});
```

`_id` is explicitly included. The projection contains every source field used by `sanitizeStudentMessageForResponse`, including its fallback fields.

## Read application

Both existing reads use the same MongoDB driver syntax and projection:

```js
studentMessagesCollection.find(existingFilter, {
  projection: INBOX_MESSAGE_PROJECTION,
}).toArray();

groupMessagesCollection.find(legacyFilter, {
  projection: INBOX_MESSAGE_PROJECTION,
}).toArray();
```

The actual formatting in `server.js` keeps the original filters inline; the filters themselves are unchanged. Both reads remain inside the existing `Promise.all`, so their parallel execution is preserved.

## Behavior preservation verification

- Existing `student-message` and `groupMessages` collections remain unchanged.
- Existing MongoDB filters are unchanged byte-for-byte in the runtime diff.
- Existing profile lookup and group/class matching are unchanged.
- Existing recipient-role and student-sent logic is unchanged.
- Existing sanitizer and all fallback behavior are unchanged.
- Existing `{ success: true, data: messages }` response envelope is unchanged.
- Existing merge and descending string timestamp sort are unchanged.
- No pagination, default limit, deduplication, or API response field changes were introduced.
- `/api/messages/student` and `/api/messages/staff` were not modified.

The projection intentionally includes fields needed for output only. Fields used solely inside MongoDB predicates, such as `recipientUsername`, `recipientRole`, `sendToStudents`, and `sendToStaff`, remain usable by the filters and do not need to be returned to the sanitizer.

## Validation

Focused command:

```text
cd D:\education_app\backend
node --test test/messages_inbox_contract.test.js
```

Result: **12 passed, 0 failed, 0 skipped**.

This includes the source-level assertion that:

- `studentMessagesCollection.find(...)` uses `INBOX_MESSAGE_PROJECTION`.
- `groupMessagesCollection.find(...)` uses `INBOX_MESSAGE_PROJECTION`.
- All required projection fields are present in the live source.

Full backend command:

```text
cd D:\education_app\backend
npm.cmd test
```

Result: **56 passed, 0 failed, 0 skipped**.

## Limitations

The contract harness remains intentionally isolated: it does not import `backend/server.js`, create a database connection, invoke the live Express route, or run MongoDB queries. The new projection assertion is source-level only. Therefore this report does not claim that the live Express route or a real MongoDB query plan was executed.

No database data, indexes, production configuration, Flutter files, deployment settings, commits, or remotes were accessed or changed.
