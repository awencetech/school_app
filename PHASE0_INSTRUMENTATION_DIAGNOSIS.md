# Phase 0 Instrumentation Diagnosis

Generated: 2026-11-11

Scope: review of the existing Phase 0 artifacts and staging-only instrumentation. No application code, API contract, authentication behavior, UI, production data, or production configuration was changed during this diagnosis.

Reviewed artifacts:

- [PERFORMANCE_BASELINE_REPORT.md](./PERFORMANCE_BASELINE_REPORT.md)
- [performance-baseline.json](./performance-baseline.json)
- [performance-baseline.csv](./performance-baseline.csv)
- [backend/performance_instrumentation.js](./backend/performance_instrumentation.js)
- [backend/performance-baseline.js](./backend/performance-baseline.js)
- [backend/server.js](./backend/server.js)
- [backend/cors_middleware.js](./backend/cors_middleware.js)
- [backend/.env.example](./backend/.env.example)
- [render.yaml](./render.yaml)

## Executive diagnosis

The staging application is reachable and healthy, but the deployed response path is not exposing the staging instrumentation headers. The source implementation and middleware registration are present locally; however, live staging responses do not contain `X-Performance-*` or `Server-Timing` headers. Consequently, backend processing time, MongoDB operation count, and MongoDB execution time cannot yet be measured from the protected benchmark runner.

The baseline report's 40 conditional requests returning zero HTTP 304 responses is not reproducible as a persistent application defect. A direct follow-up request to the live `/health` endpoint using the returned ETag and `If-None-Match` returned HTTP 304 with an empty body. The earlier benchmark result should therefore be retained as historical evidence for that run, but cache validation must be rerun after instrumentation/deployment verification.

Protected endpoint benchmarking remains blocked because no local `BASELINE_*` credential or role-token variables are present. No credentials were printed, inferred, or taken from the nested repository.

## Findings

| Area | Finding | Evidence | Severity | Action in this phase |
|---|---|---|---|---|
| Middleware order | Instrumentation is registered after CORS, JSON parsing, and compression, and before application routes. | [backend/server.js](./backend/server.js) | Low | No change required for Phase 0. |
| Staging deployment | Live `/health` response has no `X-Performance-*` or `Server-Timing` headers. | Live header probe on `https://school-app-1uep.onrender.com/health` | High | Verify the deployed revision and actual Render environment variables before benchmarking protected APIs. |
| CORS | `exposedHeaders` is not configured. Browser clients cannot read custom timing headers cross-origin even if the server sends them. | [backend/cors_middleware.js](./backend/cors_middleware.js) | Medium | No code change applied; additive CORS exposure requires approval. |
| MongoDB monitoring | Mongo command listeners are attached in source before `client.connect()`, but no live Mongo timing/count headers were observed. | [backend/server.js](./backend/server.js), [backend/performance_instrumentation.js](./backend/performance_instrumentation.js) | High | Deploy/enable staging instrumentation, then verify with an authenticated request. |
| Cache validators | Express emits an ETag for `/health`; no `Cache-Control` header was observed there. A direct conditional request returned 304. | Live staging probe | Low | Do not add caching to protected responses. Rerun the benchmark after deployment verification. |
| Protected credentials | Required local credential/token variable names are absent from the current shell. | Environment-name-only inspection | Blocking | Supply staging-only values through a secret manager or local environment without printing them. |

## Middleware registration and instrumentation behavior

The relevant source order is:

1. CORS middleware.
2. JSON body parsing.
3. Response compression.
4. `performanceInstrumentation.middleware`.
5. Upload and API route middleware.

This order allows instrumentation to wrap route responses and measure the response body bytes written through the response object. It also means CORS currently runs before the instrumentation headers are added. That is acceptable for sending headers, but the CORS configuration must explicitly expose custom response headers for browser-based clients to read them.

The instrumentation is intentionally gated by both:

```text
PERFORMANCE_INSTRUMENTATION=true
PERFORMANCE_INSTRUMENTATION_ENV=staging
```

The source gate is staging-only. Production must keep the instrumentation disabled unless the deployment environment is explicitly and safely isolated for measurement.

## Actual staging response headers

Observed from `https://school-app-1uep.onrender.com/health`:

- HTTP status: 200.
- `ETag`: present.
- `cf-cache-status`: `DYNAMIC`.
- `X-Performance-Request-Id`: absent.
- `X-Performance-Total-Ms`: absent.
- `X-Performance-DB-Operations`: absent.
- `X-Performance-DB-Time-Ms`: absent.
- `Server-Timing`: absent.
- `Cache-Control`: absent.
- `Access-Control-Expose-Headers`: absent in the direct probe.

The missing timing headers prove that timing data is not currently observable from the deployed staging service. They do not prove that the Node process has zero database work.

## Conditional request diagnosis

The baseline report recorded 40 conditional samples and zero HTTP 304 responses. A follow-up direct test performed the following sequence:

1. Request `/health` and read its ETag.
2. Send the same URL with `If-None-Match` set to that ETag.
3. Observe HTTP 304 and a zero-length response body.

Therefore:

- Express/Render can honor an ETag conditional request for this public health response.
- The earlier zero-304 result was specific to that benchmark run or its request/intermediary conditions and is not sufficient evidence of a server-side ETag failure.
- The benchmark must be rerun after staging instrumentation is live. The rerun should record the ETag from the first response and the status of every conditional request.
- No new cache policy is recommended for protected student, staff, admin, message, attendance, diary, or dashboard responses in this phase.

The source currently contains different cache policies for different routes. In particular, the existing `public` cache policy on `GET /api/mainpage-info` requires a security review because dashboard data may be role- or tenant-sensitive. It was not changed here. A public cache policy must not be used for private or authorization-dependent data.

## MongoDB instrumentation diagnosis

The source attaches MongoDB command listeners to the application `MongoClient` before the connection is opened. The listener counts selected database commands and sums command durations using the request context. Query documents and values are not written to the performance record.

No MongoDB timings or operation counts were observed in the baseline files because the deployed responses did not include the instrumentation headers. Until a staging request returns headers such as `X-Performance-DB-Operations` and `X-Performance-DB-Time-Ms`, the database portion of the baseline remains unmeasured.

The current source-level implementation should be validated with an authenticated endpoint after deployment. The validation must confirm that the request ID, database count, and database duration belong to the same request and that command events occurring outside an HTTP request are not attributed to a user request.

## Protected benchmark configuration

The existing safe benchmark maps these cases to staging-only credentials:

| Case | Method and path | Required variable |
|---|---|---|
| Login | `POST /api/login` | `BASELINE_LOGIN_IDENTIFIER`, `BASELINE_LOGIN_PASSWORD` |
| Admin dashboard | `GET /api/mainpage-info` | `BASELINE_ADMIN_TOKEN` |
| Staff dashboard/profile | `GET /api/staff/profile` | `BASELINE_STAFF_TOKEN` |
| Student dashboard/profile | `GET /api/students/profile` | `BASELINE_STUDENT_TOKEN` |
| Messages | `GET /api/messages/inbox` | `BASELINE_STUDENT_TOKEN` |
| Attendance | `GET /api/student-attendance` | `BASELINE_STUDENT_TOKEN` |
| Diary | `GET /api/diary/student` | `BASELINE_STUDENT_TOKEN` |
| Groups | `GET /api/groups` | `BASELINE_STUDENT_TOKEN` |
| Classes | `GET /api/classes` | `BASELINE_STAFF_TOKEN` |
| Resources | `GET /api/school-resources` | `BASELINE_STUDENT_TOKEN` |
| Images | `GET $BASELINE_IMAGE_PATH` | `BASELINE_IMAGE_PATH` plus any required role token if applicable |

The runner reads these variables from the local process environment and does not write their values into JSON, CSV, Markdown, or console output.

## Exact environment variable names

Required only when running the corresponding protected case:

```text
BASELINE_LOGIN_IDENTIFIER
BASELINE_LOGIN_PASSWORD
BASELINE_ADMIN_TOKEN
BASELINE_STAFF_TOKEN
BASELINE_STUDENT_TOKEN
```

Target and optional benchmark controls:

```text
BASELINE_BASE_URL
BASELINE_TARGET_ENV=staging
BASELINE_STAGING_HOST
BASELINE_TIMEOUT_MS
BASELINE_WARM_REQUESTS
BASELINE_IMAGE_PATH
```

Staging instrumentation controls:

```text
PERFORMANCE_INSTRUMENTATION=true
PERFORMANCE_INSTRUMENTATION_ENV=staging
PERFORMANCE_INSTRUMENTATION_LOG
```

Only the names and non-secret configuration values should appear in diagnostics. Never print or commit the values of credentials, tokens, MongoDB URIs, or authentication secrets.

## Remaining blockers

1. Confirm that the Render service is deployed from the authoritative root repository and the revision containing [backend/performance_instrumentation.js](./backend/performance_instrumentation.js), [backend/server.js](./backend/server.js), and [render.yaml](./render.yaml).
2. Confirm the actual Render environment has staging instrumentation enabled with the two exact gating variables. The repository declaration alone cannot prove the dashboard environment state.
3. Confirm the deployed process is starting the intended entry point, `backend/server.js` through the configured backend root/start command.
4. Add or approve CORS `exposedHeaders` for the timing headers if Flutter Web or another browser client must read them. This was not changed in Phase 0 diagnosis.
5. Provide staging-only login credentials and role tokens through local environment variables. Protected endpoint measurements remain skipped until then.
6. Rerun the baseline after the deployment is verified, including a direct conditional-cache validation and at least 20 warm samples per authorized endpoint.

## Phase boundary

No Phase 1 optimization was started. No production data, database schema, indexes, UI, authentication behavior, or API contract was modified.
