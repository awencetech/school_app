# Education App Performance Optimization Plan

This plan follows the read-only audit in [PERFORMANCE_AUDIT_REPORT.md](./PERFORMANCE_AUDIT_REPORT.md). It is a plan only; no optimization code has been applied.

## Phase 0: safe baseline

1. Confirm the authoritative repository tree. The workspace contains both the root app and a nested `Education_App` Git repository; do not benchmark or modify both unintentionally.
2. Create a staging database clone or obtain explicit approval for a read-only staging target with representative volume.
3. Add opt-in staging instrumentation for request ID, route, method, status, elapsed time, response bytes, DB operation count, and DB elapsed time.
4. Run the endpoint matrix with cold, warm, and cached cases. Export raw results as CSV/JSON.
5. Run Flutter profile/release traces for startup, login, each role dashboard, navigation, lists, and image-heavy screens.

## Phase 1: backend and MongoDB

1. Fix the highest-volume unbounded reads first: messages, attendance, diary, groups/classes, students/staff, resources, news, announcements, and photos.
2. Add server-side projection, stable sort, and cursor pagination while preserving current response contracts unless separately approved.
3. Move campaign-performance filtering/sorting and inbox merging into bounded MongoDB operations.
4. Replace upload filename regex authorization lookups with exact indexed metadata or a protected media route.
5. Inventory actual indexes, then validate candidate compound indexes with `explain("executionStats")`.
6. Tune MongoClient pool and timeout settings from measured concurrency, not guesses.
7. Measure login query variants; reduce fallback searches only after legacy data usage is understood.

## Phase 2: Flutter

1. Make auth restoration and dashboard rendering independent: show the cached shell and load profile/data concurrently.
2. Add in-flight request coalescing and explicit freshness policies in the service/state layer.
3. Use `Future.wait` for independent calls after confirming that error handling and authorization semantics remain safe.
4. Standardize on cached, resized image providers; remove base64 image bodies from ordinary list responses.
5. Profile rebuilds and list performance; narrow provider subscriptions and use lazy builders.
6. Replace full-screen spinners with partial loading/skeleton states where stale data is valid.

## Phase 3: deployment

1. Benchmark warm versus cold Render requests.
2. Use a non-sleeping plan for production traffic and colocate the service with MongoDB.
3. Set production log levels and sampling; alert on p95 latency, timeout rate, database wait queue, and 5xx rate.

## Verification gates

- No API contract change without approval.
- No production data mutation during explain/index validation.
- No index removal without inventory, query evidence, and rollback plan.
- Compare p50/p95/p99, payload size, DB examined/returned, error rate, and Flutter frame/memory metrics before and after each phase.
- Keep a regression benchmark for login and all three dashboards.
