# Main Page API Cache Security Report

Generated: 2026-11-11

## Scope and conclusion

This was a focused, read-only audit of staging `GET /api/mainpage-info` at `https://school-app-1uep.onrender.com`. No source code, database data, authentication behavior, API contract, deployment, or Git state was changed.

The endpoint has a cache-isolation risk by design:

- authentication is optional;
- administrator responses contain the full main-page document;
- non-admin responses are modified to remove `gradePage`;
- the route emits `Cache-Control: public, max-age=30, stale-while-revalidate=120`;
- the response does not vary on `Authorization`;
- `Vary: Origin` does not isolate admin, staff, student, and unauthenticated users.

No active cross-role response leak was proven from the available staging runtime because authorized synthetic admin, staff, and student credentials were not available for this audit. The tested Cloudflare response reported `cf-cache-status: DYNAMIC`, so the tested request was not served from a Cloudflare shared-cache hit. That observation does not make the public cache policy safe for other shared-cache configurations or future CDN behavior.

## Verified source findings

### Route authentication

[GET /api/mainpage-info](./backend/server.js:7403) uses [optionalAuthenticateUser](./backend/server.js:4850):

```js
if (!req.get('Authorization')) return next();
return authenticateUser(req, res, next);
```

Therefore the endpoint intentionally serves unauthenticated requests and authenticates only when an `Authorization` header is present.

### Role-dependent response generation

[mainPageInfoForUser](./backend/server.js:7443) returns the original document for normalized admin role:

```js
if (normalizeRole(auth?.role) === 'admin') return doc;
```

For all other roles, including unauthenticated requests, it shallow-copies the document and deletes `gradePage` from the top level and nested `schoolContent` object.

The route obtains the document through [getMainPageDocument](./backend/server.js:7173), which performs `collection.findOne({})`. It then performs legacy `homeContent` selection/promotion before calling the role-dependent response function.

### Cache-Control

The middleware before the route sets:

```text
Cache-Control: public, max-age=30, stale-while-revalidate=120
```

This is configured in [backend/server.js](./backend/server.js:97). Because the endpoint response varies by authorization role, `public` permits a shared-cache scenario in which a cache can retain a response that is not suitable for every requester.

### ETag and conditional requests

No custom ETag middleware is present for this route. Express's normal response handling generated a weak ETag in the staging response. A conditional request using that ETag returned HTTP 304.

The 304 response reused the validator for the URL representation. The source does not add `Authorization` to `Vary`, and the 304 path therefore has no source-level role partitioning.

### Vary headers

The live response returned:

```text
Vary: Origin, Accept-Encoding
```

[backend/cors_middleware.js](./backend/cors_middleware.js) adds `Vary: Origin`; Express/compression contributes `Accept-Encoding`. Neither value isolates authorization role or bearer token.

### Express, CDN, and Render caching

The repository contains:

- Express `compression` middleware;
- no Express response-cache middleware for this endpoint;
- no Redis/cache package or cache-store configuration for this endpoint;
- no Cloudflare, CDN, or Render cache configuration files;
- the route-level public `Cache-Control` header described above.

The live staging response included `cf-cache-status: DYNAMIC`, indicating that the tested Cloudflare path did not serve a shared-cache hit. This is an observation of the current request, not a guarantee that no intermediary can cache a response under the explicit `public` policy.

## Live staging header verification

A header-only unauthenticated GET with allowed origin `http://localhost:8000` returned:

| Header/behavior | Observed result |
|---|---|
| Status | 200 |
| Cache-Control | `public, max-age=30, stale-while-revalidate=120` |
| ETag | Present; weak Express validator |
| Vary | `Origin, Accept-Encoding` |
| Cloudflare cache status | `DYNAMIC` |
| Access-Control-Allow-Origin | `http://localhost:8000` |

A conditional request with the returned ETag returned HTTP 304. The 304 response retained the public cache policy and returned `Vary: Origin` in the observed PowerShell header view.

No response body was printed, saved, or inspected for personal data.

## Security questions and evidence status

| Question | Result | Reason |
|---|---|---|
| Can an authenticated admin response be publicly cacheable? | Yes, structurally possible | `Cache-Control: public` is explicitly emitted and the admin response differs from non-admin output. |
| Can a student/staff request receive an admin cached response? | Not proven live; plausible cache-risk scenario | No `Vary: Authorization`; runtime role test credentials unavailable; current Cloudflare observation was `DYNAMIC`. |
| Can unauthenticated requests receive an authenticated response? | Not proven live; plausible cache-risk scenario | Optional auth plus public URL caching and no authorization cache key isolation. |
| Do roles receive isolated responses at application level? | Yes, when request reaches Express | `mainPageInfoForUser` removes grade-page data for non-admin roles. |
| Are roles isolated by the declared cache policy? | No | `public` cache policy and `Vary` omit authorization role. |
| Can conditional requests return another role's representation? | Not ruled out; risk remains | ETag/304 is URL-based in observed behavior, while role is not in `Vary`. |
| Did this audit prove an actual response leak? | No | No authorized synthetic role accounts were available and Cloudflare reported `DYNAMIC`. |

## Potential exposure scenarios

These are threat scenarios inferred from the source configuration, not confirmed incidents:

1. An admin requests the endpoint and an intermediary stores the full response because the response explicitly permits public caching.
2. A non-admin or unauthenticated user requests the same URL while that stored representation is fresh and receives the cached admin-shaped document.
3. A conditional request uses a validator generated for a role-dependent representation; because `Authorization` is not a cache key dimension, a 304 or cached representation could be associated with the wrong caller if an intermediary stores/authenticates it in that way.
4. A future CDN or proxy configuration may honor the public policy even though the currently tested Cloudflare path reported `DYNAMIC`.

The practical impact depends on whether `gradePage` contains sensitive or role-restricted content and on the behavior of every intermediary between client and origin.

## Risk assessment

Severity: **High — authorization-dependent response with public shared-cache permission**.

The risk is high because the same URL has different response representations based on authentication role, while the cache policy tells shared caches that the response is public. The risk is not classified as a confirmed data leak because runtime cross-role verification was blocked and the tested staging edge did not report a cache hit.

## Recommended remediation proposal

For the current role-dependent endpoint, the safest proposal is:

```text
Cache-Control: private, no-store
```

This should apply to `GET /api/mainpage-info` and prevent browser/shared-cache retention of role-dependent representations. It preserves the API path and response shape while removing the unsafe shared-cache permission.

Before approving a code change, decide whether ETag validators should also be disabled for this endpoint. With `private, no-store`, removing ETag is the clearest policy for sensitive role-dependent data. If private browser caching is intentionally retained later, it must be designed and tested with explicit role/user isolation; `Vary: Authorization` alone is not a preferred bearer-token cache strategy because it can create high-cardinality cache keys and risk token-related cache metadata.

No remediation was applied in this audit.

## Tests required before approving a fix

Use only synthetic staging accounts and do not record response bodies:

1. Request unauthenticated and record status plus headers only.
2. Request as admin and record status, `Cache-Control`, `ETag`, `Vary`, and a body hash calculated locally without saving body content.
3. Request as staff and student and record the same metadata and local body hashes.
4. Confirm admin and non-admin representations differ where expected without storing the content.
5. Send admin `If-None-Match` to confirm any 304 is for the admin request only.
6. Send the admin validator with a staff, student, and unauthenticated request; confirm no cross-role 304 or admin representation is returned.
7. Repeat in the reverse order: non-admin first, then admin.
8. Test through the actual staging hostname and any configured CDN/proxy, not only localhost or direct origin.
9. Confirm the final response is `private, no-store` and that no shared-cache hit occurs.
10. Confirm API functionality and application-level role filtering remain unchanged after the fix.

For body comparison, use only a local cryptographic digest and discard the body. Never put response bodies, tokens, identifiers, or personal data in the report.

## Remaining blockers

1. Authorized synthetic admin, staff, and student staging credentials are unavailable for runtime cross-role cache verification.
2. Render/Cloudflare dashboard configuration was not available from the repository, so only repository configuration and response headers were audited.
3. The remediation remains a proposal and requires approval before code changes.

Stop here. No source code or deployment was changed, and Phase 1 optimization has not started.
