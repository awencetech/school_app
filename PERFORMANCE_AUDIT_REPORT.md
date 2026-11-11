# Education App Performance Audit Report

Audit date: 2026-11-11  
Scope: `D:\education_app` primary tree, including Flutter client, Node/Express backend, deployment configuration, tests, and checked-in upload assets.  
Mode: read-only audit. No application code, production data, indexes, or API contracts were changed.

## Executive summary

The strongest evidence points to backend/database response amplification rather than a single Flutter rendering defect:

1. The backend is a single approximately 7,966-line `server.js` containing 216 route declarations and many unbounded `find(...).toArray()` reads.
2. Several list endpoints return whole collections and sort in MongoDB without a visible limit, cursor, or projection. This makes latency and payload size grow with school data.
3. The API has a broad legacy compatibility layer: duplicate collections, fallback reads, cross-role credential searches, and in-memory joins/sorts. These add work and make query behavior difficult to observe.
4. The configured Render deployment uses the free plan. Cold starts, CPU throttling, and network/database distance can dominate sub-second targets even when queries are efficient.
5. Flutter uses many independent service calls and predominantly 15–30 second request timeouts. Some screens parallelize requests, but dashboard/profile initialization commonly waits on app initialization and then performs another request.
6. Image handling is inconsistent. `CachedNetworkImage` is used in several places, but many screens still use `Image.network`; some profile paths accept base64 data and decode it into memory.

The audit cannot honestly provide endpoint or screen milliseconds yet. No reachable staging API/MongoDB test target was available for a controlled benchmark, and the backend test command did not finish during the observation window. All latency fields below are therefore explicitly marked **Not measured**.

## Evidence and scope

| Item | Observed evidence |
|---|---|
| Flutter source | 285 Dart files; approximately 73,185 lines |
| Backend source | 16 JavaScript files including tests/diagnostics; approximately 9,193 lines; production server is 7,966 lines |
| API surface | 216 `app.get/post/put/patch/delete` route declarations in `backend/server.js` |
| Checked-in uploads | 9 files, approximately 14.8 MB |
| Deployment | Render Node service, Oregon, `plan: free`, `/ready` health check |
| MongoDB | Native MongoDB driver; startup index setup is controlled by `RUN_STARTUP_MIGRATIONS` |
| Flutter networking | `package:http`, many per-service calls, mostly 15–30 second timeouts |
| Flutter image packages | `cached_network_image` is present and used, but not consistently |
| Duplicate tree | `Education_App/` is a nested Git repository containing another copy of the app; root Git status shows it untracked |
| Tests | `npm.cmd test` executed many visible passing tests but did not terminate cleanly during the observation window; it was stopped, so the suite is not reported as passing |
| Static analyzer | `flutter analyze --no-pub` did not produce a completed result during the observation window and was stopped |

## Measurement status

### Measurements actually collected

These are repository measurements, not runtime latency measurements:

| Measurement | Result | Confidence |
|---|---:|---|
| Dart file count | 285 | High |
| Dart line count | ~73,185 | High |
| Backend JS line count | ~8,109 | High |
| Declared backend routes | 215 | High |
| Upload asset count / size | 9 / ~14.8 MB | High |
| Backend test observation | Started, no completion in 60 s | High |
| Public production `GET /health` | First request timed out at ~20.9 s; following requests were ~3.0 s and ~0.42 s; HTTP 200, 15 bytes | High |
| Public staging `GET /health` | Three requests returned HTTP 404 in ~0.31–0.83 s | High |
| Public staging `GET /ready` | Three requests returned HTTP 404 in ~0.35–0.40 s | High |

### Measurements not collected

The following require a reachable, authorized staging environment with representative data and a Flutter profile/release run. They are intentionally **not fabricated**:

- HTTP status, p50/p95/p99, first/warm/cached latency, payload bytes, error rate, query duration, and query count for each endpoint.
- MongoDB `explain("executionStats")`, collection cardinalities, index usage, document sizes, and slow-query samples.
- Flutter startup, login, dashboard, navigation, frame build/raster times, memory, and image decode timings.
- Production CPU, memory, cold-start, connection-pool, and network RTT data.

### Safe public health measurements

These are real network measurements from the audit workstation, not representative protected-endpoint benchmarks. The production health endpoint was reachable but showed a first-request delay of approximately 20.9 seconds, followed by approximately 3.0 seconds and 0.42 seconds. This is consistent with a cold/warm distinction but is not enough to attribute latency between Render, MongoDB, and Node. The configured staging hostname returned 404 for both `/health` and `/ready`, so staging endpoint/database measurements could not be run against it.

## Provisional performance score

**Provisional: 43/100 (static-risk score, not a measured user-experience score).**

This score reflects high scalability risk and incomplete observability, not a claim that every request is slow. It should be replaced with a measured score after the benchmark protocol in the optimization plan is run.

## Module summary

| Module | Current speed | Problem | Root cause evidence | Priority | Expected after optimization |
|---|---|---|---|---|---|
| Login | Not measured | Potentially several credential reads before password verification | `findCredentialByIdentifier` searches multiple fields and role collections; fallback legacy lookup exists | High | Measure first; target p95 <500 ms warm, subject to password hashing and network |
| Admin dashboard | Not measured | Likely fan-out and large lists | Admin screens invoke many services; backend contains unbounded list reads | High | Target first useful content <1 s; full data separately |
| Staff dashboard | Not measured | Profile/class data waits behind initialization | Dashboard waits up to 6 s for `AppState.initialization` before profile request | High | Render shell immediately; target profile/data p95 <500 ms warm |
| Student dashboard | Not measured | Same initialization gate plus profile request; image may be uncached | `student_dashboard.dart` waits for app initialization then calls current profile; profile uses `Image.network` in the header path | High | Target first useful content <1 s |
| MongoDB | Not measured | Unbounded reads, legacy collections, and uncertain index usage | Many `.find(...).toArray()` calls; no runtime explain evidence available | Critical | Validate with explain; target indexed reads examined/docs returned near 1 |
| Messages | Not measured | Full inbox/group message reads and merge/sort behavior | Inbox reads student and group collections and merges in memory; group messages use unbounded arrays | High | Paginated cursor reads; target p95 <300 ms warm for first page |
| Attendance | Not measured | Full history reads and broad filters | Attendance endpoints sort and materialize arrays; only some compound indexes are declared | High | Date/user scoped pagination; target p95 <300 ms warm |
| Resources/news | Not measured | Media-heavy payloads and repeated image requests | Mixed `Image.network`/`CachedNetworkImage`; list endpoints lack consistently visible limits | Medium | Metadata first, thumbnails/pagination |
| Uploads/images | Not measured | Upload middleware performs a MongoDB lookup per public upload request | `/uploads` middleware queries `medicalEventCollection` before serving a file | High | Separate protected media route or indexed filename metadata |

## Backend bottleneck analysis

### Critical / high findings

| ID | Severity | Finding | Why it slows the system | Recommended fix |
|---|---|---|---|---|
| B-01 | Critical | Unbounded collection reads | `toArray()` transfers and materializes all matching documents; latency, memory, and JSON size grow with data | Add explicit limits/cursors, projections, stable sort keys, and response envelopes without changing existing contracts until approved |
| B-02 | Critical | Missing runtime query observability | There is no request ID, endpoint duration, DB duration, query count, payload byte, or error-rate instrumentation visible in the audit scope | Add opt-in staging telemetry and MongoDB command monitoring; sample safely and redact credentials/PII |
| B-03 | High | Legacy/fallback reads | Credential and data compatibility paths query multiple collections/field variants, sometimes sequentially | Normalize read paths after measuring usage; parallelize independent reads only when authorization and semantics remain identical |
| B-04 | High | In-memory joins and sorts | Campaign performance loads all students, then filters/sorts in JavaScript; inbox merges collections in memory | Push filtering/projection/sort to MongoDB; use aggregation or bounded queries |
| B-05 | High | Upload authorization lookup on every public file request | `/uploads` checks MongoDB by regex before static file serving, adding DB latency to image/file loads | Store protected-media metadata by exact filename and index it, or route protected files separately |
| B-06 | High | Unclear MongoClient pool configuration | `new MongoClient(mongoUri)` is used without explicit pool/timeout settings | Set and measure `maxPoolSize`, `minPoolSize`, wait queue, server selection, socket, and connect timeouts for the deployment size |
| B-07 | High | Free-tier hosting | Free plans can sleep and have constrained CPU; cold starts and cross-region DB traffic can exceed the desired budget | Use a warm staging/production plan and colocate compute with MongoDB region; verify with measurements |
| B-08 | Medium | Large JSON/body limits and media in document responses | `express.json({limit: '10mb'})` permits large request bodies; base64 images can inflate payload and heap | Keep media out of normal list responses; return URLs/metadata and resize thumbnails |
| B-09 | Medium | Excessive route concentration | One very large server file makes middleware/query behavior hard to profile and regress | Modularize only after baseline tests and contract snapshots exist |
| B-10 | Medium | Logging in request/error paths | Rejected CORS and upload failures log synchronously to the process output; high-volume logs can add I/O pressure | Structured, sampled logs with production levels and request IDs |

### Specific backend patterns observed

- `findCredentialByIdentifier` builds many `$or` variants across email/user identifier fields and searches role collections one collection at a time. This is a login latency risk and an index-design risk.
- `findCredentialAcrossRoleCollections` parallelizes three role lookups, which is good for latency, but it can create unnecessary database work for every request using the fallback path.
- Campaign performance reads all student records and sorts in JavaScript. This is an explicit memory/CPU scalability risk.
- Inbox handling reads student and group messages, then combines/sorts results in application memory.
- Groups, attendance, diary, messages, resource, and event endpoints contain multiple list reads using `.toArray()` without a consistently visible limit or projection.
- Startup index/migration setup is gated, which is safer for production data, but it means indexes may not exist in an environment where the flag is false. Index presence must be verified with `listIndexes()` in staging.

## MongoDB audit

### Indexes declared by application code

The server declares useful indexes for credentials, groups/classes, events, homework, diary, messages, requests, timetables, students, resources, attendance, leave, GPS, and staff access. This is a positive baseline. However, declarations in source are not proof that indexes exist in the target database.

### Risks requiring `explain("executionStats")`

1. List endpoints whose filter and sort do not match a compound index.
2. Regex filename lookup in the `/uploads` authorization middleware.
3. Case-insensitive credential lookups across many alternative fields.
4. Student attendance filters that combine role/group/date conditions.
5. News, announcements, resources, meetings, leave, gate-register, and employee-attendance history endpoints.
6. Legacy collection fallback queries and queries that use `$in` with large student ID lists.

### Safe recommendations

- Capture `winningPlan`, `totalKeysExamined`, `totalDocsExamined`, `nReturned`, and execution time for representative queries in staging.
- Prefer compound indexes matching equality fields first, then sort fields; validate selectivity before creating anything.
- Remove duplicate/overlapping indexes only after inventory, workload review, and approval. This audit made no index changes.
- Use projections for list views and exclude base64/image bodies from normal responses.
- Use cursor pagination (`createdAt` plus `_id`) for chronological feeds; retain existing query parameters and response shape until an API-contract change is approved.
- Avoid startup duplicate cleanup or migration work in request paths. Review `ensureStudentAttendanceUniqueness` and all migration behavior separately before enabling it against production.

## Flutter frontend bottleneck analysis

### High-risk patterns

| ID | Severity | Evidence | Likely effect | Recommendation |
|---|---|---|---|---|
| F-01 | High | Dashboard profile loaders wait on `AppState.initialization` with a 6-second timeout | Delays the first useful dashboard content when initialization is slow | Split auth restoration from data loading; render cached shell immediately and fetch profile concurrently |
| F-02 | High | Many services use 15–30 second per-call timeouts | Slow failures remain visible for a long time and retries can stack | Centralize transport policy, use bounded retries only for idempotent calls, and record timeout causes |
| F-03 | High | Many screens use `Image.network`; some decode base64 into `MemoryImage` | Repeated downloads, no disk cache, main-isolate memory pressure, slower first paint | Standardize image provider, cache widths, thumbnail URLs, and avoid base64 in list responses |
| F-04 | High | Numerous screens use `FutureBuilder`/`initState` service calls | Re-entering a screen can repeat requests; future identity and lifecycle need review | Cache in service/state layer with explicit freshness and in-flight request coalescing |
| F-05 | Medium | Dashboards and list screens use broad `setState` | Larger widget subtrees rebuild on small state changes | Split stateful regions, use `Selector`/`Consumer` narrowly, and profile rebuild counts |
| F-06 | Medium | Some screens already use `Future.wait`, but not all request groups are parallel | Sequential waits increase wall-clock time | Parallelize only independent reads after auth/authorization review |
| F-07 | Medium | `HomeScreen` uses `FutureBuilder` for local dummy school information on build | May recreate the future on rebuild and show unnecessary loading transitions | Hoist a stable future or use already-loaded config state |
| F-08 | Medium | Large, image-heavy admin screens and grids | Build/layout/image decode work can exceed frame budget | Use lazy builders, bounded image cache sizes, and pagination |
| F-09 | Low | Many inline loading indicators | Multiple spinners make perceived performance worse even when data is partly available | Use skeleton/partial rendering and retain prior data during refresh |

### Frontend measurement required

Run profile/release builds on a representative Android device and web target. Capture timeline events for startup, login, dashboard, route transition, build, raster, network wait, JSON decode, and image decode. A static source review cannot replace this.

## Slowest API endpoints

No endpoint was benchmarked, so a truthful measured top-20 list is **not available**. The following are **static-analysis candidates**, ordered by expected scalability risk, not observed milliseconds:

1. `GET /api/campaign-performance` — loads all students and sorts in JavaScript.
2. `GET /api/messages/inbox` — reads multiple message sources and merges/sorts.
3. `GET /api/groups/:groupId/messages` — unbounded group feed.
4. `GET /api/messages/group/:groupId` — unbounded group/admin message read.
5. `GET /api/student-attendance` — history list with sort and no visible pagination.
6. `GET /api/employee-attendance` — history list with sort and no visible pagination.
7. `GET /api/gate-register` — list read and sort without visible pagination.
8. `GET /api/diary` — list read and sort without visible limit.
9. `GET /api/diary/student` — reads two diary collections for a list of students.
10. `GET /api/bus-gps` — reads and sorts all routes.
11. `GET /api/groups` — broad group/class data with compatibility behavior.
12. `GET /api/classes` — broad list data.
13. `GET /api/students` — likely large administrative list.
14. `GET /api/staff` — likely large administrative list.
15. `GET /api/schoolnews` — feed endpoint; validate pagination/index.
16. `GET /api/announcement` — feed endpoint; validate pagination/index.
17. `GET /api/news-letter` — list endpoint; validate pagination/index.
18. `GET /api/school-resources` — media/list payload risk.
19. `GET /api/class-resources/:groupId` — media/list payload risk.
20. `GET /api/groups/:groupId/photos` — image metadata/payload risk.

## Slowest screens

No Flutter profile trace or real device timing was available, so a measured top-10 list is **not available**. Static-risk candidates are:

1. Admin dashboard
2. Staff dashboard
3. Student dashboard
4. Messages/inbox
5. Admin group/class news
6. Class resources and school resources
7. Attendance history/management
8. Diary pages
9. Admin student/staff management lists
10. Homework/today-in-class pages with attachments

## Prioritized optimization roadmap

### P0 — establish trustworthy measurements

1. Use a disposable/staging database clone or approved read-only staging database.
2. Add opt-in request timing with request ID, route, status, response bytes, DB operation count, and DB duration.
3. Add MongoDB command monitoring in staging; redact query values and personal data.
4. Build a benchmark matrix for login, dashboards, feeds, attendance, diary, resources, and images. Run 1 cold request, 10 warm requests, and 10 cached requests per endpoint.
5. Capture Flutter profile traces on representative Android hardware.

### P1 — remove response amplification

1. Add pagination, bounded limits, projections, and stable sort/cursor rules to the top candidates.
2. Push filtering and sorting into MongoDB; eliminate in-memory full-collection sorts.
3. Separate media metadata from media bytes and use thumbnails.
4. Replace per-upload regex database authorization checks with indexed exact metadata or a separately protected route.

### P2 — validate and tune MongoDB

1. Inventory actual indexes and collection sizes.
2. Run `explain("executionStats")` for the benchmark matrix.
3. Add only approved, workload-supported compound indexes.
4. Verify pool and timeout settings against concurrency; monitor wait queues and connection errors.

### P3 — reduce Flutter wall-clock and rebuild work

1. Render dashboard shells from already-restored auth/config state.
2. Coalesce duplicate in-flight requests and add bounded, truthful freshness caching.
3. Parallelize independent dashboard calls.
4. Replace uncached image loads with a consistent cached provider and server-side thumbnails.
5. Profile rebuilds, list virtualization, JSON decode, and image decode before changing widget structure.

### P4 — hosting and operations

1. Benchmark warm and cold requests separately on the deployed service.
2. Move compute and MongoDB closer together and use a non-sleeping production plan appropriate to traffic.
3. Configure health checks, graceful shutdown, pool sizing, structured logs, and alerting for p95 latency/error rate.

## Acceptance targets

Targets are goals, not current measurements:

- Warm small read endpoint: p95 under 300 ms where network distance permits.
- Dashboard first useful content: under 1 second with cached shell and parallel reads.
- Login: p95 under 500 ms warm, excluding unusually slow external identity providers.
- Indexed MongoDB query: `totalDocsExamined` close to `nReturned` for selective reads.
- Feed/list endpoints: bounded payloads and cursor pagination; no full collection transfer.
- Flutter: no sustained build/raster frame over budget during standard navigation; verify on device.

## Conclusion

The exact reason the backend is likely slow is cumulative work per request: unbounded MongoDB reads, application-side joining/sorting, compatibility fallbacks, media authorization lookups, and a sleeping/free-tier deployment. The public production health probe provides one measured signal of severe cold-start/wake latency, but it does not prove protected API latency. The configured staging hostname currently returns 404, which must be resolved before a trustworthy protected-endpoint benchmark. The exact contribution of each backend component remains unmeasured. The next authorized step should be instrumentation and a valid staging benchmark, followed by the P0/P1 changes above. No production data, API contract, UI, or application code was changed during this audit.
