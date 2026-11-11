# Staging Connectivity Report

Generated: 2026-11-11  
Authoritative repository: `D:\education_app`  
Nested repository intentionally not modified: `D:\education_app\Education_App`

## Executive result

The repository contains a valid Express backend with the required `/health` and `/ready` routes. The configured staging hostname is not serving that application: it resolves through Render/Cloudflare but returns an edge-style plain-text HTTP 404 for `/`, `/health`, and `/ready`.

The local deployment configuration has been corrected, but the fix cannot be verified live until the Render service syncs and deploys the Blueprint from `master`. No Render API credentials or dashboard access were available, so no remote deployment was started and no success is claimed.

## 1. Actual application entry point

The backend entry point is [backend/server.js](./backend/server.js):

- `backend/package.json` declares `server.js` as `main` and `npm start` runs `node server.js`.
- `startServer()` connects to MongoDB, logs a sanitized connection failure if needed, and then calls `app.listen(port, '0.0.0.0')`.
- `GET /health` is defined in `backend/server.js` and returns `{ "status": "ok" }` without calling MongoDB.
- `GET /ready` uses `createMongoReadinessHandler` and returns `200 { "status": "ready" }` only after a MongoDB ping succeeds; it returns `503 { "status": "not_ready" }` when the client is absent or the ping fails.
- Staging startup migrations remain disabled by `RUN_STARTUP_MIGRATIONS=false`.

## 2. Deployment configuration inspection

The authoritative Blueprint is [render.yaml](./render.yaml):

| Setting | Before | Current | Assessment |
|---|---|---|---|
| Service type | `web` | `web` | Correct |
| Runtime | `node` | `node` | Correct |
| Root directory | `backend` | `backend` | Correct for this monorepo |
| Build command | `npm install` | `npm install` | Valid |
| Start command | `node server.js` | `node server.js` | Valid |
| Deployment branch | Unspecified | `master` | Now explicit and aligned with the authoritative root |
| Auto deploy | Unspecified | `autoDeployTrigger: commit` | Now explicit |
| Liveness check | `/ready` | `/health` | Corrected so liveness does not depend on MongoDB |
| Database | `mmhs_staging` | `mmhs_staging` | Correct, assuming the dashboard secret targets staging |
| Startup migrations | `false` | `false` | Safe; no migration is enabled |
| Instrumentation | Not declared | Explicit staging-only enablement | Correct for baseline collection |

The staging application URL is defined in [api_config.dart](./lib/config/api_config.dart) as `https://school-backend-staging.onrender.com`. The production URL is separate: `https://school-app-1uep.onrender.com`.

The actual Render dashboard values for deployment status, environment variables, latest deploy logs, and linked repository cannot be confirmed from this checkout. They require Render dashboard/API access. No secrets were read or printed.

## 3. Root cause of the 404

Observed HTTP behavior:

| Target | Result |
|---|---|
| Staging `/` | HTTP 404, `text/plain; charset=utf-8`, Cloudflare `Server` header |
| Staging `/health` | HTTP 404, `text/plain; charset=utf-8`, Cloudflare `Server` header |
| Staging `/ready` | HTTP 404, `text/plain; charset=utf-8`, Cloudflare `Server` header |
| Production `/health` | HTTP 200, JSON `{ "status": "ok" }` |

This is not evidence of a MongoDB readiness failure. A running copy of [backend/server.js](./backend/server.js) would return `/health` before MongoDB is available, and `/ready` would return the application’s JSON `503`, not a plain-text edge 404.

The most supported diagnosis is that the staging hostname is not routed to the current backend deployment. Possible Render-side states are:

1. The service is missing, suspended, or has no active deployment.
2. The service is linked to a different repository, branch, or revision.
3. The service is using a different root directory/start command.
4. The Render Blueprint was never synchronized after the staging service was created.
5. The service’s onrender.com subdomain is disabled or the hostname belongs to a different service.

The repository previously left the branch unspecified and configured Render’s health check as `/ready`; both have now been corrected. These settings alone cannot repair a hostname that is not serving the service until the Blueprint is synchronized/deployed.

## 4. Changes made

Only Phase 0 connectivity/deployment configuration was changed:

- [render.yaml](./render.yaml): pin `branch: master`.
- [render.yaml](./render.yaml): set `autoDeployTrigger: commit`.
- [render.yaml](./render.yaml): change Render liveness from `/ready` to `/health`.
- [render.yaml](./render.yaml): enable `PERFORMANCE_INSTRUMENTATION=true` only with `PERFORMANCE_INSTRUMENTATION_ENV=staging`.
- Existing [backend/server.js](./backend/server.js) health/readiness behavior was preserved.
- No production data, schema, indexes, migrations, API contracts, or UI were changed.

## 5. Validation performed

### Local source and tests

The focused backend safety suite passed:

- 14 tests passed, 0 failed.
- Readiness behavior passed for uninitialized MongoDB, failed ping, and successful ping.
- Production configuration validation passed.
- Staging migration safety validation passed.
- MongoDB failure messages were verified not to expose URI/password details.

The instrumentation gate was also verified: it enables only when both `PERFORMANCE_INSTRUMENTATION=true` and `PERFORMANCE_INSTRUMENTATION_ENV=staging`; a production environment value does not enable it.

### Live HTTP validation

The live staging hostname remains unverified because it still returns 404:

| Probe | Current result | Required result |
|---|---:|---:|
| Staging `/` | 404 | Application response |
| Staging `/health` | 404 | 200 JSON |
| Staging `/ready` | 404 | 200 when MongoDB is ready, otherwise JSON 503 |
| Authorized protected API | Not attempted | Requires staging token and live application |
| MongoDB connectivity | Not observable through staging | Requires live application |
| Performance headers | Not observable through staging | Requires instrumentation-enabled live application |

Production was not used for protected benchmarking or deployment validation.

## 6. Deployment instructions

1. In Render, open the service currently associated with `school-backend-staging.onrender.com`.
2. Confirm the repository is `awencetech/school_app` and the branch is `master`.
3. Confirm the root directory is `backend`.
4. Confirm the build command is `npm install` and the start command is `node server.js`.
5. Confirm the service’s public onrender.com subdomain is enabled.
6. Synchronize the Blueprint or manually apply the changes from [render.yaml](./render.yaml).
7. Confirm these environment variables in Render without exposing their values:
   - `NODE_ENV=production`
   - `PORT=10000` (Render may inject its assigned port; do not override incorrectly)
   - `MONGODB_DATABASE=mmhs_staging`
   - `RUN_STARTUP_MIGRATIONS=false`
   - valid staging-only `MONGODB_URI`
   - valid `AUTH_SECRET` of at least 32 characters
   - `PERFORMANCE_INSTRUMENTATION=true`
   - `PERFORMANCE_INSTRUMENTATION_ENV=staging`
8. Deploy the latest `master` revision and inspect the build/start logs for `Backend listening on port` and either `Connected to MongoDB` or the sanitized MongoDB failure category.
9. Verify `/health`, `/ready`, and one authorized protected endpoint from a staging-only client.
10. Confirm the protected response includes `X-Performance-Request-Id`, `X-Performance-Total-Ms`, `X-Performance-DB-Operations`, `X-Performance-DB-Time-Ms`, and `Server-Timing`.
11. Confirm the production service does not have `PERFORMANCE_INSTRUMENTATION=true` with `PERFORMANCE_INSTRUMENTATION_ENV=staging`.

Render’s Blueprint and health-check documentation supports `branch`, `rootDir`, `startCommand`, `healthCheckPath`, and commit-triggered auto deploy configuration: [Blueprint specification](https://render.com/docs/blueprint-spec), [health checks](https://render.com/docs/health-checks).

## 7. Remaining blockers

- Render dashboard/API access is required to inspect the service’s actual linked repository, branch, deploy state, environment variables, and logs.
- The corrected Blueprint must be synchronized and deployed from `master`.
- A staging-only MongoDB credential and authorized role tokens are required for `/ready`, protected endpoint validation, and MongoDB timing.
- Until the live staging host returns the expected application responses, connectivity is **not verified** and Phase 1 must not begin.
