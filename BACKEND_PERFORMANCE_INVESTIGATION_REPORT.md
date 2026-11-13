# School App Backend Performance Investigation

**Investigation date:** 2026-11-12  
**Scope:** Backend routes, MongoDB access patterns, authentication, deployment configuration, performance instrumentation, and Flutter request paths.  
**Mode:** Investigation only. No application source, API contract, schema, index, database, or deployment was changed.

## Executive assessment

There is no safe, current protected-endpoint or database benchmark available from this investigation. The local development configuration points to a remote MongoDB Atlas host, so the backend was not started and no MongoDB or production/staging service was contacted. Existing local artifacts contain a historical public Render baseline from 2026-11-11; it is presented below as archival evidence, not as a new measurement.

That archived data identifies a split:

- For `GET /health`, the measured Node handler took about **0.23 ms at warm p50**, while the client observed **403 ms p50**. The app handler is not the source of that warm delay; most time was outside the measured handler (client network, proxy/edge, and hosting path).
- For `GET /ready`, which performs one MongoDB ping, archived warm p50 was **604 ms total**, **216 ms backend**, and **215 ms MongoDB**. Both the MongoDB round trip and the external path contribute materially.
- For data endpoints, static evidence shows several unbounded reads and larger request fan-out risks. Their current latency and response sizes remain **unmeasured**, so no exact share can be assigned to Render, MongoDB, backend computation, or Flutter.

The strongest cold-start risk is that the Render manifest selects the free plan and server startup awaits MongoDB connection before binding the HTTP listener. Even though `/health` itself does not query MongoDB, it cannot respond until `startServer()` finishes its connection attempt. A separate cold start after a known idle period was not measured.

## Measurements and method

### Historical public endpoint measurements

The figures below were read from the checked-in `performance-baseline.json` and `PERFORMANCE_BASELINE_REPORT.md`, generated **2026-11-11** for the Render host recorded in those files. No requests were made for this investigation. “Cold-observed” means the first request in that run; it is **not proof** that the instance had just woken from sleep.

| Endpoint | Phase | Client response time | Backend time | Mongo time / commands | Response bytes | Interpretation |
|---|---|---:|---:|---:|---:|---|
| `GET /health` | First observed (1 sample) | 2,256.457 ms | 0.209 ms | No DB call in handler; runner did not preserve a zero command count | 15 B | Nearly all observed time was outside the handler. Not a verified Render cold start. |
| `GET /health` | Warm (20 samples) | p50 403.296 ms; p95 566.704 ms; p99 845.653 ms | p50 0.226 ms; p95 0.301 ms | No DB call in handler | 15 B | Strong evidence of a client/network/proxy/hosting-path floor for this tiny response. |
| `GET /ready` | First observed (1 sample) | 655.613 ms | 216.540 ms | 214.972 ms; 1 command | 18 B | One Mongo ping consumed nearly all backend time. |
| `GET /ready` | Warm (20 samples) | p50 604.439 ms; p95 763.452 ms; p99 871.113 ms | p50 215.596 ms | p50 214.875 ms; 1 command | 18 B | Mongo RTT plus roughly 389 ms p50 outside the measured backend. |

These are small, public health/readiness endpoints. They do **not** substitute for authorized protected endpoint measurements.

### Local synthetic CPU measurement

To measure the CPU-only portion of a hot-path helper without a database or service call, `buildCampaignPerformance()` in `backend/campaign_performance.js` was run locally against generated in-memory student records. Each size used one warm-up and seven timed iterations; timings below are the median and maximum of those seven. JSON byte counts are the helper result serialized with `JSON.stringify`, not a live HTTP response.

| Synthetic student records | Helper median | Helper max | Serialized result bytes |
|---:|---:|---:|---:|
| 1,000 | 9.868 ms | 12.946 ms | 2,648 B |
| 10,000 | 83.042 ms | 100.734 ms | 26,456 B |
| 50,000 | 404.962 ms | 425.083 ms | 132,584 B |

This shows the helper’s CPU work grows with the number of records. Synthetic size and data distribution may not represent the school’s current database.

### Protected API measurements

**Not measured in this investigation.** No authenticated requests were sent and no database was queried. `performance-protected-baseline.json` already records zero requests and skipped protected cases because local login credentials and role tokens were absent. This is a measurement gap, not evidence that the protected endpoints are fast or slow.

### Backend tests

Command run from `D:\education_app\backend`:

```text
npm.cmd test
```

**Result: 77 tests passed, 0 failed.** These are the repository’s backend tests; they are not a throughput or live-database benchmark.

## Endpoint inventory: measurements unavailable

The read counts below are **source-level logical reads**, not observed MongoDB command counts or query timings. They exclude possible cursor `getMore` commands and may gain a legacy-user fallback read during authentication. Payload sizes and endpoint timings were not measured.

| Endpoint / method | Source-level reads on typical success | DB time / response size | Principal concern |
|---|---:|---|---|
| `POST /api/login` | 1–4 sequential credential lookups, then local `bcrypt.compare` | Not measured | Searches multiple credential collections in series; broad legacy identifier `$or` query. |
| `GET /api/mainpage-info` | 1 main-page `findOne`; a bearer token can add an auth lookup | Not measured | Returns the full configuration document, with no projection or response limit. |
| `GET /api/staff/profile` | Auth lookup + 1 profile lookup | Not measured | Profile query has no projection. |
| `GET /api/students/profile` | Auth lookup + 1 profile lookup | Not measured | Profile query has no projection. |
| `GET /api/messages/inbox` | Auth lookup + profile lookup + 2 parallel message reads | Not measured | Both message sets are fully materialized, merged, and sorted without a page limit. |
| `GET /api/student-attendance` | Student: auth + identity lookup + attendance read. Staff: auth + staff/access/group/class reads + attendance read. | Not measured | The final projected query still uses unbounded `toArray()`; wide admin/staff filters may return large histories. |
| `GET /api/diary/student` | Auth + profile lookup + 2 parallel diary reads | Not measured | Two result sets are merged and sorted in memory; currently scoped to a required date. |
| `GET /api/groups` | Auth + all matching groups + role-dependent profile/access reads | Not measured | Full group documents are loaded before role filtering and serialization. |
| `GET /api/classes` | Admin: auth + class read. Staff: those plus staff and access reads. | Not measured | Full class documents are loaded before staff filtering. |
| `GET /api/school-resources` | Auth + 1 projected read | Not measured | Projection and sort exist, but no visible page limit. |
| `GET /api/campaign-performance` | Auth + 1 full student read | No live HTTP size/time measured; synthetic CPU measured above | Reads all matching student docs before recursive extraction, sorting, and response construction. |
| `GET /api/stf-access/me` | Auth + staff lookup + access lookup | Not measured | Flutter requests this during app-state initialization and again during staff dashboard setup. |
| `GET /uploads/:filename` | Static authorization middleware does a medical-event lookup; GridFS fallback does a file lookup and may do another medical-event lookup | Not measured | A file-serving path can perform database work, including a regex lookup, before returning an asset. |

## Top 10 bottlenecks, ranked by likely impact

These are ranked from source and the limited archived measurements. Except where explicitly marked above, the impact on current production traffic is **not measured**.

1. **Render cold-start exposure is amplified by startup ordering.** `render.yaml:1-14` selects `plan: free` and `/health` as the health check. `backend/server.js:8204-8232` awaits `connectMongo()` before `app.listen()`. A remote or slow Mongo connection can therefore delay the first HTTP listener and liveness response. The health handler itself does not need Mongo (`server.js:7472-7474`).
2. **The measured warm request floor is mostly outside Node; DB round trips are also material.** The archived health samples show ~0.23 ms backend versus ~403 ms client p50; readiness samples show ~215 ms of Mongo time per ping. The archived results do not distinguish client-to-Render network, Render proxy/queueing, or client geography.
3. **Main-page configuration is a full-document read with cache disabled.** `backend/server.js:7448-7456,7679-7713` reads and returns the complete document. `backend/main_page_info_security.js:1-16` sets `private, no-store` and removes the ETag. That policy may be required for role-scoped data, but it means repeat fetches cannot use an HTTP conditional-cache hit.
4. **Campaign performance scans all matching student documents and computes in Node.** `backend/server.js:962-970` performs an unprojected `find(...).toArray()`; `backend/campaign_performance.js:18-109` recursively examines records and sorts results. The synthetic CPU benchmark reached ~405 ms median at 50,000 records.
5. **Groups and classes load complete matching documents before authorization filtering.** `backend/server.js:3492-3526,3635-3695` has no projection or page bound on the main reads. Staff/student filtering occurs after retrieval; groups may embed student arrays.
6. **Inbox response work grows with both message collections.** `backend/server.js:1156-1210` performs one profile read, then two parallel reads (parallelism is already present), materializes both collections, merges them, and sorts in memory. The projection is a useful existing optimization, but there is no visible result bound.
7. **Attendance history can be unbounded for broad roles or date ranges.** `backend/server.js:3169-3188,3201-3248` projects fields and sorts, but the query ends in `toArray()` with no limit. Student identity lookup adds a read; staff access resolution can add several.
8. **Login compatibility lookup can serialize multiple collection scans.** `backend/server.js:237-253,7569-7590` builds lookup alternatives across identifier fields and tries the student, staff, admin, then legacy users collection in a `for` loop. Existing indexes visible in `server.js:1830-1879` cover selected identity/email fields, not every legacy alias. Actual query plans are unknown without `explain()`.
9. **Some upload requests perform a database regex lookup before serving the file.** The `/uploads` middleware at `backend/server.js:76-101` queries medical events for each request. The GridFS fallback at `server.js:7866-7890` also checks medical-report references. This adds latency to asset delivery and may repeat the lookup for a GridFS-served file.
10. **Staff startup has a repeated access request and serialized waits.** `lib/services/app_state.dart:58-104` waits for stored auth state and then requests staff access. `lib/screens/staff/staff_dashboard.dart:54-62` also requests access, while its profile load waits for app-state initialization (`staff_dashboard.dart:118-131`). The service calls `/api/stf-access/me` (`lib/services/staff_access_service.dart:56-61`); its backend handler uses authentication plus staff and access reads (`backend/server.js:6960-6973`).

## Other checks

- **MongoDB reconnection:** No per-request reconnection bug was found. `createMongoConnector()` memoizes its connection promise (`backend/staging_safety.js:76-93`), and the backend constructs one `MongoClient` (`backend/server.js:1909-1925`). Route-level `await connectMongo()` reuses that connection.
- **Startup migrations/indexes:** `ensureIndexes()` includes a duplicate-attendance aggregation and many index creations (`backend/server.js:1829-1892`), but it is behind `RUN_STARTUP_MIGRATIONS=true` (`server.js:1978-1992`). The checked-in Render manifest sets it to `"false"` (`render.yaml:17-19`); the startup index sweep is therefore not expected under that manifest.
- **Query patterns:** The reviewed inbox and diary routes parallelize independent reads. No classic query-per-row N+1 was established in those paths; the demonstrated risks are full-result materialization, repeated per-request reads, and post-query filtering/computation.
- **Authentication middleware:** Protected requests validate the signed token and load the user record through `createAuthenticate` (`backend/user_management.js:68-116`, wired at `backend/server.js:5100-5108`). This adds a Mongo lookup to protected endpoints. Role checks themselves are in-process.
- **External APIs:** No general external API fan-out was found in the reviewed route handlers. Firebase Admin token verification is an external-dependent path (`backend/server.js:339-355`) for Firebase ID tokens at `/api/auth/check-email`; the normal app-signed-token path and password login do not call it.
- **Flutter request coalescing:** `MainPageInfoRepository.getMainPageInfo()` shares an in-flight future (`lib/services/main_page_info_repository.dart:71,107-114`), so the splash and school-config providers starting together should coalesce their initial main-page request. This is a mitigation, not a durable cache.
- **Instrumentation limitation:** `backend/performance_instrumentation.js:61-95` records request time and Mongo command time, but the baseline runner maps a numeric zero to `null` (`backend/performance-baseline.js:117-126`). Therefore a reported `null` command count is not evidence that the count was measured as zero. The middleware is installed after compression (`backend/server.js:72-75`), so verify the exact byte-count semantics before using instrumentation bytes as compressed wire size.
- **Middleware:** JSON parsing, compression, and instrumentation are global (`backend/server.js:65-75`). No evidence indicates these dominate the measured tiny health handler; compression may trade CPU for smaller large JSON responses.

## Is the main problem Render, MongoDB, backend code, or Flutter?

**Current protected API attribution is unresolved.** There were no current live endpoint or DB measurements. Based on the available evidence:

1. **Cold first response:** Render idle/cold behavior is plausible and the server’s Mongo-before-listen startup sequence can make it worse. The stored first-observed sample is not a controlled cold-start test.
2. **Warm health requests:** The archived measurement points to the network/proxy/hosting path, not backend application work.
3. **Mongo-dependent reads:** The archived readiness test demonstrates a ~215 ms Mongo round trip. Full-list queries and remote database placement could add much more, depending on cardinality and plans.
4. **Backend computation/payload:** Campaign computation has measurable local CPU growth on synthetic data; several list routes and the main-page endpoint are unbounded at the source.
5. **Flutter:** One repeated staff-access call is visible in the startup path. The current evidence does not establish that Flutter is the dominant contributor overall.

## Recommended fixes, in priority order

| Priority | Recommendation | Expected improvement | Main risk / validation |
|---|---|---|---|
| P0 | Separate listener/liveness startup from database readiness; keep `/ready` as the dependency check and verify Render health-check behavior. | Removes the Mongo connection attempt from the time before `/health` can respond; reduces cold-bind dependence on database server-selection delay. | Requests may arrive while DB is unavailable; readiness and retry semantics must remain correct. Measure after a controlled restart and database outage simulation. |
| P1 | Benchmark protected GET endpoints using approved synthetic/local data and request-scoped timings; capture Mongo `explain("executionStats")`, sizes, and p50/p95/p99. | Identifies which endpoints and query plans actually dominate before changes. | Requires a disposable local DB or explicitly approved non-production target; do not infer from health probes. |
| P1 | Bound and paginate high-volume list endpoints; push role/date filtering and sort into Mongo; keep stable sort keys and response compatibility. | Caps work and payload growth to the requested page instead of total collection size. | Pagination can change UX/order and must preserve authorization semantics; add only after contract tests. |
| P1 | Reduce the main-page response to the fields needed by each client view, or split it into smaller read resources without weakening role filtering. | Can reduce database bytes, JSON encoding, transfer, and Flutter decode work. | Broadly consumed response; test all roles and existing screens. Avoid shared caching unless role-aware invalidation/security is proved. |
| P1 | Replace repeated legacy login field/collection probing with a normalized, indexed identifier lookup after reviewing data compatibility. | Reduces sequential database round trips on fallback login paths. | Requires data migration/index review and careful case-insensitive uniqueness; bcrypt cost remains intentionally CPU-expensive. |
| P2 | Optimize campaign-performance data selection/projection and compute only needed records; benchmark on representative cardinalities. | Reduces Mongo transfer and Node CPU proportional to irrelevant records. | Do not change tie/rank semantics or result shape; synthetic measurements are not production forecasts. |
| P2 | Avoid medical-event regex lookups on every upload request; use trustworthy file metadata or a narrowly indexed authorization lookup while preserving medical-report privacy. | Reduces DB work and latency on media-heavy screens. | Security-sensitive: must not make medical reports public or rely on untrusted filename metadata. |
| P2 | Reuse the already loaded staff access state in the dashboard and refresh it deliberately when permissions change. | Removes one `/api/stf-access/me` round trip from staff startup. | Stale access UI; authorization must continue to be enforced server-side. |
| P2 | Preserve and test projections already present on messages, diary, attendance, resources, and student-list reads; add projections to profile/class reads only after sanitizer contracts are reviewed. | Lowers document transfer and decode costs without changing response shape. | Omitting fallback fields can break legacy records. |
| P3 | Correct measurement reporting so zero commands/zero durations are not converted to missing values; separately record serialized and compressed wire bytes. | Makes future diagnosis and cache/compression comparisons reliable. | Instrumentation adds some overhead; keep sampling/retention bounded. |

No percentage improvement is claimed because no representative protected endpoint baseline was collected. The only quantitative improvement expectation supported directly by code is that reusing staff access state would remove one duplicate `/api/stf-access/me` HTTP call from that startup path.

## Safety and change summary

- No production or staging service was contacted during this investigation.
- No MongoDB connection was attempted: the available development environment points to a remote Atlas host, and it was deliberately not used.
- Backend tests ran locally; the campaign CPU benchmark used generated in-memory data only.
- No source file, schema, index, data, API response, authentication behavior, or deployment setting was modified.
- A new report file was created: `BACKEND_PERFORMANCE_INVESTIGATION_REPORT.md`.
