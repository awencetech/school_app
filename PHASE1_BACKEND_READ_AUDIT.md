# Phase 1 Backend Read Audit

Status: **Source-only audit.** No source code was modified. No API was called, no MongoDB connection was opened, no production system was accessed, and no indexes were created.

## Scope and method

Reviewed the backend read paths in [backend/server.js](./backend/server.js), credential helpers in [backend/server.js](./backend/server.js), and the related user router in [backend/user_management.js](./backend/user_management.js). The audit searched for MongoDB `find`, `findOne`, `aggregate`, `sort`, `countDocuments`, and `toArray` usage and traced the surrounding route handlers.

This report contains static code findings only. Query cardinality, execution time, index usage, payload size, and actual response performance were not measured in this phase.

## Priority summary

| Priority | Finding | Main impact |
|---|---|---|
| P0 | Multiple privileged and dashboard list endpoints use unbounded `find(...).toArray()` | Memory pressure, large payloads, long MongoDB scans, slow dashboards |
| P0 | Student/staff authorization helpers repeat access, group, class, and student reads | Duplicate database work on protected endpoints; latency multiplies across dashboard calls |
| P0 | `/api/messages/inbox` loads two unbounded collections, merges, sanitizes, and sorts in Node | Large response and CPU/memory cost; possible duplicate legacy/current records |
| P0 | `/api/students` loads every student, then filters staff visibility in memory | Data transfer and memory cost; poor scaling and unnecessary exposure inside the process |
| P0 | `/api/campaign-performance` loads all student documents and computes/sorts results in memory | Unbounded data and CPU work for a dashboard/report endpoint |
| P1 | Broad staff-access, staff, student, attendance, leave, resource, news, and announcement lists have no pagination or projection | Payload and serialization growth; slow admin screens |
| P1 | Group-scoped messages load all messages and all comments into memory | High response and memory cost; nested fan-out behavior |
| P1 | Many read paths sort without a visible limit and rely on potentially unverified compound indexes | Increasing sort cost and possible in-memory sort/spill |
| P1 | Legacy fallback paths query multiple collections sequentially or in parallel | Compatibility cost on authentication and recipient resolution |
| P2 | Several endpoint responses read a document again after insert/update | Extra round trip; often necessary for current response shape but can be optimized carefully |
| P2 | Projections are absent from nearly all reads | Unneeded fields cross MongoDB, Node, and JSON serialization boundaries |

## Detailed prioritized findings

### P0-01 — Credential listing is unbounded and reads legacy data

- Location: [backend/server.js:253](./backend/server.js:253), [backend/server.js:257](./backend/server.js:257)
- Helper: `listCredentials`
- Affected API: `GET /api/users`
- Collections: all role-specific credential collections plus legacy `users`
- Current behavior: `find({}).toArray()` is executed for each selected role collection, then another unbounded legacy query is executed. All documents are merged in Node and de-duplicated by `userId`/email.
- Problem: no limit, pagination, projection, or server-side merge. Credential documents may contain password hashes and other fields before sanitization. Even though the response is sanitized, the process reads and holds all documents.
- Proposed optimization: add an admin-only paginated contract or internal bounded listing; project only fields required by `safeUser`; query only the requested page and use a deterministic sort. Preserve the response contract through an explicit compatibility mode if pagination changes the response.
- API/UI impact: likely API response-shape or pagination impact if implemented directly; admin user-management UI may need page controls. Internal projection alone should not change the response.
- Risk: High.

### P0-02 — Staff authorization helper materializes groups and classes without limits

- Location: [backend/server.js:417](./backend/server.js:417), [backend/server.js:434](./backend/server.js:434), [backend/server.js:435](./backend/server.js:435)
- Helpers: `staffAssignedStudentIds`
- Affected APIs: all protected reads that call `staffAssignedStudentIds`, including student lists, attendance, requests, and related group-scoped paths
- Collections: `stf-access`, `groups`, `classes`
- Current behavior: reads staff access, builds a selector, then loads all matching groups and classes with `toArray()`. It iterates every membership entry in Node to build an identifier set.
- Problem: membership arrays and group/class documents are unbounded. Large groups create large Node sets and response latency before the actual endpoint query begins.
- Proposed optimization: project only membership and identifier fields; normalize group/class membership storage for targeted lookups; use bounded queries where the endpoint has a date/page scope; avoid loading both collections when the access record identifies the source type. Any schema/index change requires separate approval.
- API/UI impact: internal projections should be transparent. Moving filtering to MongoDB must preserve all accepted ID representations and role visibility.
- Risk: High.

### P0-03 — `staffAssignedClassNames` repeats the same access and group work

- Location: [backend/server.js:460](./backend/server.js:460), [backend/server.js:463](./backend/server.js:463), [backend/server.js:480](./backend/server.js:480), [backend/server.js:481](./backend/server.js:481), [backend/server.js:482](./backend/server.js:482)
- Helper: `staffAssignedClassNames`
- Affected APIs: staff-visible campaigns/PTM and other paths using class-name scoping
- Collections: `employee-info`, `stf-access`, `groups`, `classes`, `student-info`
- Current behavior: reads staff profile and access, loads groups/classes, then calls `staffAssignedStudentIds(auth)`, which independently reads staff profile/access and loads groups/classes again before another student query at [backend/server.js:492](./backend/server.js:492).
- Problem: duplicate staff, access, group, and class database operations in one request. The duplication is especially expensive when a dashboard calls multiple scoped endpoints.
- Proposed optimization: create one request-scoped authorization context containing staff profile, access, group/class IDs, and assigned student IDs; reuse it across helpers. Add projections and avoid re-reading the same collections.
- API/UI impact: should be internal-only if authorization semantics remain unchanged; incorrect caching or reuse across users would be a security issue.
- Risk: High.

### P0-04 — Student list loads the entire collection and filters in memory

- Location: [backend/server.js:6918](./backend/server.js:6918), [backend/server.js:6920](./backend/server.js:6920)
- Affected API: `GET /api/students`
- Collection: `student-info`
- Current behavior: `find({}).sort(...).toArray()` loads every student, then staff results are filtered in Node using `staffAssignedStudentIds`.
- Problem: no pagination, limit, projection, or database-side visibility filter. Admin and staff requests both pay for the full collection; staff receives a potentially very large intermediate result.
- Proposed optimization: keep role-specific filters in MongoDB; project only fields used by `sanitizeStudentForResponse`; add explicit pagination/limit while preserving a compatibility mode for existing Flutter callers.
- API/UI impact: pagination would require Flutter list changes or a backward-compatible default limit. Projection must include every response field currently emitted.
- Risk: Critical for large schools.

### P0-05 — Campaign performance is an unbounded report calculation

- Location: [backend/server.js:940](./backend/server.js:940), [backend/server.js:941](./backend/server.js:941), [backend/server.js:956](./backend/server.js:956)
- Affected API: `GET /api/campaign-performance`
- Collection: `student-info`
- Current behavior: reads all matching students without projection or limit, computes several result arrays in Node, filters, and sorts each result in memory.
- Problem: response latency and memory use scale with total student count even when the caller needs a small dashboard summary.
- Proposed optimization: project only performance fields and identity fields; add server-side date/class/test scope; use aggregation or bounded result limits after confirming the exact UI semantics.
- API/UI impact: changing result limits or ordering could change report contents. Requires product/UI confirmation.
- Risk: Critical.

### P0-06 — Messages inbox performs two unbounded reads and an in-memory merge/sort

- Location: [backend/server.js:1178](./backend/server.js:1178), [backend/server.js:1196](./backend/server.js:1196), [backend/server.js:1200](./backend/server.js:1200)
- Affected API: `GET /api/messages/inbox`
- Collections: `student-messages`, `group-messages`
- Current behavior: reads direct/current messages and legacy/group messages with two unbounded `toArray()` calls, concatenates them, sanitizes all records, and sorts the combined array in Node.
- Problem: duplicate or overlapping records can be loaded; MongoDB cannot use a single ordered/limited result; response size and Node memory grow without bound.
- Proposed optimization: project response fields, define a server-side page size, use a stable cursor such as `(createdAt, _id)`, and either unify the read model or merge bounded sorted streams. Preserve legacy visibility rules before changing query logic.
- API/UI impact: pagination and cursor metadata could require Flutter changes. A default bounded page may hide older messages unless UI adds loading more.
- Risk: Critical.

### P0-07 — Staff/student diary reads query two stores and merge in Node

- Location: [backend/server.js:1423](./backend/server.js:1423), [backend/server.js:1424](./backend/server.js:1424), [backend/server.js:1431](./backend/server.js:1431)
- Affected API: `GET /api/diary/student`
- Collections: `student-diary`, `diary`
- Current behavior: two collection reads run in parallel for the same student/date scope, then records are merged and sorted in Node.
- Problem: duplicate data models, no projection, no limit, and a second in-memory merge path. Parallelism helps latency but does not control result size or CPU.
- Proposed optimization: project required fields, enforce date/student bounds, use a unified read model or a bounded aggregation/merge strategy after compatibility review.
- API/UI impact: response merging semantics must remain identical; changing precedence of staff/student observations could alter UI.
- Risk: High.

### P0-08 — Student attendance is unbounded even when date filters are optional

- Location: [backend/server.js:3023](./backend/server.js:3023)
- Affected API: `GET /api/student-attendance`
- Collection: `student-attendance`
- Current behavior: constructs a role-aware filter, but permits no date/range and then executes an unbounded sorted `toArray()`.
- Problem: a student/admin/staff request can return all accessible attendance history, with complete documents copied into `data`.
- Proposed optimization: require or default a bounded date range; project response fields; introduce cursor/page controls while retaining existing filters.
- API/UI impact: default date window can change visible history; needs UI agreement.
- Risk: High.

### P1-01 — Broad public/dashboard content lists have no page boundary

The following routes all use unbounded collection reads and should be reviewed as a group. Each has no visible `limit`, page/cursor input, or projection at the cited read:

| Location | API route | Collection | Current concern | Risk |
|---|---|---|---|---|
| [backend/server.js:632](./backend/server.js:632) | `GET /api/student-campaigns` | `student-campaigns` | Full active campaign set; staff filtering after read | High |
| [backend/server.js:719](./backend/server.js:719) | `GET /api/student-ptm` | `student-ptm` | Full filtered PTM set; staff filtering after read | High |
| [backend/server.js:894](./backend/server.js:894) | `GET /api/messages/student` and staff/admin helper | `group-messages` | Full recipient message set | High |
| [backend/server.js:1048](./backend/server.js:1048) | `GET /api/student-requests/pending` | `student-requests` | Full pending set then in-memory staff filtering | High |
| [backend/server.js:1284](./backend/server.js:1284) | `GET /api/messages/student-message` | `student-messages` | Full student message history | High |
| [backend/server.js:1297](./backend/server.js:1297) | `GET /api/messages/group/:groupId` | `group-messages` | Full group message history | High |
| [backend/server.js:1394](./backend/server.js:1394) | `GET /api/diary` | `diary` | Date/group constrained but no result cap/projection | Medium/High |
| [backend/server.js:2674](./backend/server.js:2674) | internal group lookup | `groups` | Full collection for helper path | High |
| [backend/server.js:2681](./backend/server.js:2681) | group listing helper | `groups` | Full sorted group collection | High |
| [backend/server.js:2791](./backend/server.js:2791) | `GET /api/employee-attendance` | `employee-attendance` | Optional date allows all history | High |
| [backend/server.js:2806](./backend/server.js:2806) | `GET /api/employee-attendance/summary` | `employee-attendance` | Full date attendance array for counting | Medium |
| [backend/server.js:2822](./backend/server.js:2822) | `GET /api/employee-attendance/pending` | `employee-attendance` | Full pending set | High |
| [backend/server.js:2835](./backend/server.js:2835) | `GET /api/employee-attendance/late` | `employee-attendance` | Full late set | High |
| [backend/server.js:3095](./backend/server.js:3095) | `GET /api/gate-register` | `gate-reg` | Full filtered history | High |
| [backend/server.js:3186](./backend/server.js:3186) | `GET /api/bus-gps` | `bus gps` | Full route list | Medium |
| [backend/server.js:3277](./backend/server.js:3277) | `GET /api/classes` | `groups/classes` collection | Full class list, staff filtered after read | Medium/High |
| [backend/server.js:3418](./backend/server.js:3418) | `GET /api/groups` | `groups` | Full group list; staff/student visibility filtering after read | High |
| [backend/server.js:3499](./backend/server.js:3499) | `GET /api/groups/:groupId/events` | `events` | Full group event history | Medium/High |
| [backend/server.js:3613](./backend/server.js:3613) | `GET /api/groups/:groupId/today-in-class` | `today-in-class` | Full group history | Medium/High |
| [backend/server.js:3628](./backend/server.js:3628) | `GET /api/groups/:groupId/homework` | `homework` | Full homework history | High |
| [backend/server.js:3646](./backend/server.js:3646) | `GET /api/online-assignment` | `online-assignment` | Loads all records before role filtering | High |
| [backend/server.js:3872](./backend/server.js:3872) | `GET /api/groups/:groupId/class-timetable` | `class-timetable` | Full group timetable | Medium |
| [backend/server.js:3943](./backend/server.js:3943) | `GET /api/groups/:groupId/lesson-plans` | `lesson-plans` | Full group lesson-plan history | Medium/High |
| [backend/server.js:4286](./backend/server.js:4286) | `GET /api/groups/:groupId/messages` | `group-messages` | Full messages plus comments | Critical |
| [backend/server.js:4387](./backend/server.js:4387) | `GET /api/groups/:groupId/messages/:messageId/comments` | `group-message-comments` | Full comment list | Medium/High |
| [backend/server.js:4930](./backend/server.js:4930) | `GET /api/demography` | `demography` | Full collection, staff filtering after read | High |
| [backend/server.js:4953](./backend/server.js:4953) | `GET /api/demography/group/:groupId` | `demography` | Full group history | Medium |
| [backend/server.js:5069](./backend/server.js:5069) | `GET /api/library` | `library` | Full library catalog | Medium/High |
| [backend/server.js:5274](./backend/server.js:5274) | `GET /api/events-celebration` | `events-celebration` | Full school event list | Medium |
| [backend/server.js:5388](./backend/server.js:5388) | `GET /api/class-resources/:groupId` | `class-resources` | Full group resource list, potentially large metadata | High |
| [backend/server.js:5479](./backend/server.js:5479) | `GET /api/school-resources` | `school-resources` | Full school resource list | High |
| [backend/server.js:5588](./backend/server.js:5588) | `GET /api/news-letter` | `news-letter` | Full school newsletter list | Medium/High |
| [backend/server.js:5702](./backend/server.js:5702) | `GET /api/schoolnews` | `school-news` | Full news list | Medium/High |
| [backend/server.js:5834](./backend/server.js:5834) | `GET /api/announcement` | `announcement` | Full announcement list | High |
| [backend/server.js:5884](./backend/server.js:5884) | `GET /api/medical-events` | `medical-event` | Full privileged medical event list | Critical |
| [backend/server.js:6189](./backend/server.js:6189) | `GET /api/one-on-one-meetings` | `one-on-one-meetings` | Full privileged meeting list | High |
| [backend/server.js:6204](./backend/server.js:6204) | `GET /api/one-on-one-meetings/my-meetings` | `one-on-one-meetings` | Full staff history | Medium/High |
| [backend/server.js:6221](./backend/server.js:6221) | `GET /api/one-on-one-meetings/staff/:staffId` | `one-on-one-meetings` | Full staff history | Medium/High |
| [backend/server.js:6354](./backend/server.js:6354) | `GET /api/staff-request` | `staff-request` | Full admin request history | High |
| [backend/server.js:6429](./backend/server.js:6429) | `GET /api/emp-leave/:staffId/entitlements` | `staff-leave-entitlements` | Full entitlement set | Medium |
| [backend/server.js:6440](./backend/server.js:6440) | `GET /api/emp-leave/employee/:staffId` | `emp-leave` | Full staff leave history | High |
| [backend/server.js:6492](./backend/server.js:6492) | `GET /api/emp-leave` | `emp-leave` | Full admin leave history | High |
| [backend/server.js:6503](./backend/server.js:6503) | `GET /api/emp-leave/history` | `emp-leave` | Full approved/rejected history | High |
| [backend/server.js:6558](./backend/server.js:6558) | `GET /api/staff-resources/my-resources` | `staff-resources` | Full staff resource history | Medium/High |
| [backend/server.js:6570](./backend/server.js:6570) | `GET /api/staff-resources` | `staff-resources` | Admin can request all resources | High |
| [backend/server.js:6668](./backend/server.js:6668) | `GET /api/stf-access` | `employee-info` | Full staff list plus all access records | Critical |
| [backend/server.js:6669](./backend/server.js:6669) | `GET /api/stf-access` | `stf-access` | Separate unbounded access read and in-memory map | Critical |
| [backend/server.js:6767](./backend/server.js:6767) | `GET /api/staff` | `employee-info` | Full staff directory | High |
| [backend/server.js:7541](./backend/server.js:7541) | `GET /api/images/:id` | GridFS files | Bounded to one file, but metadata projection absent | Low/Medium |
| [backend/server.js:7595](./backend/server.js:7595) | `GET /uploads/:filename` | GridFS files | Loads all matching file metadata before using first file | Medium |
| [backend/server.js:7647](./backend/server.js:7647) | `GET /api/groups/:groupId/photos` | `class-photos` | Full group photo metadata list | High |
| [backend/server.js:7770](./backend/server.js:7770) | `GET /api/groups/:groupId/news` | `class-news` | Full group news history | Medium/High |

For each row, the safe first optimization is an internal projection and bounded/cursor-based query. The exact default page size and response compatibility need to be determined from Flutter callers before implementation.

### P1-02 — In-memory filtering after broad reads

The following patterns should be moved into MongoDB filters or aggregation only after authorization semantics are preserved:

- Staff student visibility: [backend/server.js:6918](./backend/server.js:6918) followed by [backend/server.js:6920](./backend/server.js:6920).
- Staff class visibility: [backend/server.js:3277](./backend/server.js:3277) followed by [backend/server.js:3281](./backend/server.js:3281).
- Staff group visibility: [backend/server.js:3418](./backend/server.js:3418) followed by the staff access filtering in the same handler.
- Campaign/PTM staff visibility: [backend/server.js:632](./backend/server.js:632) and [backend/server.js:719](./backend/server.js:719), followed by class-name filtering.
- Student request visibility: [backend/server.js:1048](./backend/server.js:1048) followed by [backend/server.js:1049](./backend/server.js:1049).
- Demography visibility: [backend/server.js:4930](./backend/server.js:4930) followed by role-based filtering.
- Online assignment visibility: [backend/server.js:3646](./backend/server.js:3646) followed by role filtering.

Risk: High. Moving filters server-side can change edge-case visibility if legacy identifiers, `_id` strings, `id` fields, or role aliases are not preserved.

### P1-03 — Group messages have a two-stage unbounded fan-out

- Location: [backend/server.js:4286](./backend/server.js:4286) and [backend/server.js:4299](./backend/server.js:4299)
- Affected API: `GET /api/groups/:groupId/messages`
- Collections: `group-messages`, `group-message-comments`
- Current behavior: loads every group message, extracts all message keys, then loads every matching comment and hydrates nested comments in memory.
- Proposed optimization: paginate messages first, fetch comments only for the current page, project fields, and use a stable created-at/_id cursor.
- API/UI impact: nested comment completeness and older-message behavior may change; likely requires UI pagination/load-more semantics.
- Risk: Critical for active groups.

### P1-04 — Legacy/current dual reads and sequential fallback queries

- Locations: [backend/server.js:150](./backend/server.js:150), [backend/server.js:193](./backend/server.js:193), [backend/server.js:206](./backend/server.js:206), [backend/server.js:210](./backend/server.js:210), [backend/server.js:216](./backend/server.js:229)
- Helpers: `findCredentialByUserId`, `findCredentialAcrossRoleCollections`, `findCredentialByIdentifier`, `findCredentialById`
- Affected APIs: authentication, user management, recipient-scoped messages, profile lookups, authorization middleware
- Current behavior: credential resolution probes role-specific collections and the legacy users collection. Some fallbacks are sequential; other paths query all role collections with `Promise.all`.
- Problem: every login or protected request may perform multiple reads; legacy fallback remains on hot paths.
- Proposed optimization: define a single canonical credential lookup path, use a migration-completion flag or bounded compatibility adapter, and project only auth fields. Do not remove legacy support until migration coverage is proven.
- API/UI impact: potentially none if the adapter preserves aliases and role canonicalization; authentication regression risk is high.
- Risk: High/Critical.

### P1-05 — `getAdminMessagesForRecipient` repeats profile and credential lookups

- Location: [backend/server.js:878](./backend/server.js:878) through [backend/server.js:881](./backend/server.js:881)
- Affected APIs: `GET /api/messages/student`, `GET /api/messages/staff`
- Collections: credentials plus `student-info` or `employee-info`, followed by `group-messages` at [backend/server.js:890](./backend/server.js:890)
- Current behavior: reads credential and profile separately for each request, derives group values, then reads an unbounded message set.
- Problem: authentication already has user identity; repeated credential lookup and full message scan increase latency.
- Proposed optimization: attach minimal authenticated identity/profile context to the request, project only group fields, and paginate the message query.
- API/UI impact: internal context reuse should be transparent; pagination may change visible history.
- Risk: High.

### P1-06 — Diary route has an avoidable field-normalization mismatch

- Location: [backend/server.js:1394](./backend/server.js:1394)
- Affected API: `GET /api/diary`
- Collection: `diary`
- Current behavior: validates `date`, creates `filter.diaryDate = filter.date`, deletes `filter.date`, then sorts by `studentName` without `_id` tie-break or limit.
- Problem: large same-day group results may require a blocking sort; deterministic ordering is not guaranteed for equal names.
- Proposed optimization: sort with a stable secondary key, project response fields, and apply a bounded page. Confirm the actual stored date field and matching index before changing it.
- API/UI impact: ordering and pagination could change; response fields should remain stable.
- Risk: Medium/High.

### P1-07 — Images endpoint reads all matching metadata

- Location: [backend/server.js:7595](./backend/server.js:7595)
- Affected API: `GET /uploads/:filename`
- Collection: GridFS files metadata
- Current behavior: `imageBucket.find({ filename }).toArray()` loads every matching file metadata, then uses the first entry.
- Problem: duplicate filenames cause unnecessary metadata transfer and ambiguity; the query is not bounded.
- Proposed optimization: apply `.limit(1)` with deterministic sort, then stream the selected file. Preserve existing filename behavior and verify duplicate-file semantics first.
- API/UI impact: normally none; choosing a different duplicate file could alter image behavior.
- Risk: Medium.

### P1-08 — Full-document reads without projections

- Scope: nearly every `.find(...).toArray()` and many `findOne()` calls in [backend/server.js](./backend/server.js), including high-traffic routes at lines 632, 719, 894, 940, 1048, 1195–1196, 1284, 1394, 1423–1424, 2791, 3023, 3277, 3418, 4286, 5479, 6668–6669, 6767, and 6918.
- Current behavior: full MongoDB documents are transferred to Node, then sanitizers select response fields.
- Problem: sensitive or bulky fields such as images, comments, audit fields, or large embedded arrays may be read even when not returned.
- Proposed optimization: add explicit projections matching each sanitizer and authorization helper. For embedded arrays, project only the subset required by the route or redesign the read model later.
- API/UI impact: projection omissions can silently remove response fields; each sanitizer and Flutter model must be mapped before implementation.
- Risk: High.

### P1-09 — Sorts are unbounded and index assumptions are unverified

- Examples: [backend/server.js:632](./backend/server.js:632), [backend/server.js:719](./backend/server.js:719), [backend/server.js:2791](./backend/server.js:2791), [backend/server.js:3023](./backend/server.js:3023), [backend/server.js:3277](./backend/server.js:3277), [backend/server.js:3418](./backend/server.js:3418), [backend/server.js:3943](./backend/server.js:3943), [backend/server.js:4930](./backend/server.js:4930), [backend/server.js:5479](./backend/server.js:5479), [backend/server.js:6767](./backend/server.js:6767), [backend/server.js:6918](./backend/server.js:6918)
- Current behavior: filters and sorts are sent to MongoDB, but no limit is applied and this source audit does not verify supporting indexes.
- Problem: result growth increases scan/sort work; missing compound indexes could force blocking in-memory sorts.
- Proposed optimization: verify query plans with `explain('executionStats')` in a disposable/staging environment, then propose indexes separately. Add limits/cursors before or alongside index work.
- API/UI impact: index-only changes should not change responses; limits/cursors can.
- Risk: High.

## Additional duplicate-query observations

1. `staffAssignedClassNames` duplicates the entire `staffAssignedStudentIds` access/group/class path, described in P0-03.
2. `GET /api/messages/inbox` reads both current and legacy message collections by design, but does not bound either side before merging.
3. `GET /api/diary/student` reads both `student-diary` and `diary` for the same student/date scope; this is compatibility logic, not an accidental duplicate, but should be bounded and projected.
4. `findCredentialById` attempts `_id` and then `userId` for each role collection, while legacy fallback adds more reads. This is safe compatibility behavior but expensive on a hot administrative path.
5. Create/update handlers often perform a second `findOne` after a write to build the response, for example staff at [backend/server.js:6849](./backend/server.js:6849) and students at [backend/server.js:7018](./backend/server.js:7018). This is outside the read-only endpoint priority but is a measurable round-trip pattern.

## Route-level optimization priority

### Immediate design review before code changes

1. `/api/messages/inbox`
2. `/api/students`
3. `/api/student-attendance`
4. `/api/groups/:groupId/messages`
5. `/api/campaign-performance`
6. `staffAssignedStudentIds` and `staffAssignedClassNames` authorization helpers
7. `/api/stf-access`, `/api/staff`, and `/api/emp-leave`
8. `/api/school-resources`, `/api/class-resources/:groupId`, and `/api/staff-resources`
9. `/api/groups`, `/api/classes`, homework, diary, timetable, and lesson plans
10. Broad public/admin content lists and GridFS filename lookup

### Safe implementation order for a later phase

1. Add request-level query/result telemetry in staging and capture actual cardinality, execution time, and payload size.
2. Map every sanitizer and Flutter consumer to an explicit projection.
3. Introduce backward-compatible default limits and cursors on the highest-risk lists.
4. Move authorization filters into MongoDB only after preserving legacy ID representations and role semantics.
5. Consolidate duplicate request-scoped authorization lookups.
6. Run `explain('executionStats')` for the resulting queries in a disposable clone and propose indexes separately.
7. Update Flutter callers only where pagination or changed response metadata is approved.

## Compatibility and security constraints

- Do not remove legacy fallback reads until migration coverage is verified.
- Do not cache role-dependent or private student/staff/admin responses publicly.
- Do not use a shared mutable authorization cache across users.
- Do not reduce fields in projections until every route sanitizer and Flutter model is mapped.
- Do not add limits that silently hide records required by existing dashboards.
- Do not change API response formats without explicit approval.
- Do not create indexes, run `explain`, or connect to MongoDB as part of this source-only audit.

## Limitations

- No query execution plans were collected.
- No database cardinalities were observed.
- No endpoint latency or payload measurements were collected.
- Index availability was not verified against a live database.
- Some helper-to-route call relationships may be shared by multiple endpoints; the cited source lines identify the read site, not a runtime call count.

## Final status

Phase 1 source audit is complete. The highest-confidence bottlenecks are unbounded list reads, full-document transfers, in-memory authorization/filtering, dual legacy/current reads, and repeated authorization queries. No optimization implementation has started.

