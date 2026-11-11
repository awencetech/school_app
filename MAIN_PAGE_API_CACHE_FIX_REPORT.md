# Main Page API Cache Fix Report

Date: 2026-11-11

## Scope

Applied the approved local-only security fix for `GET /api/mainpage-info`. No deployment, Git push, production access, database writes, schema changes, authentication changes, API route changes, or frontend changes were performed.

## Findings addressed

The prior audit found that the endpoint had optional authentication, role-dependent response filtering, `Cache-Control: public`, and an Express-generated ETag. That combination allowed a shared-cache or conditional-response risk because the URL representation varied by authorization role without authorization-based cache isolation.

## Files changed

- `backend/server.js`
- `backend/main_page_info_security.js`
- `backend/test/main_page_info_security.test.js`

No other application files were changed by this fix.

## Exact changes

### `GET /api/mainpage-info`

- Replaced the route-scoped public cache policy with `Cache-Control: private, no-store` for GET requests.
- Removed the Express-generated `ETag` immediately before the response is committed for this endpoint.
- Kept the existing optional authentication middleware and route path unchanged.
- Preserved the existing administrator behavior: administrators receive the full document.
- Preserved the existing unauthenticated, staff, and student behavior: `gradePage` is removed from the top level and nested `schoolContent` object.
- The PUT route and all other `/api/mainpage-info` routes are not affected by the GET-only cache middleware.

## Tests added

The focused test file verifies:

1. Unauthenticated, admin, staff, and student-shaped requests receive `private, no-store` and no ETag.
2. A request containing `If-None-Match` still receives HTTP 200 rather than a role-dependent HTTP 304.
3. Existing role filtering remains intact for admin, unauthenticated, staff, and student roles.

The role cases use synthetic test values only. No credentials, tokens, response bodies, or personal data were used.

## Test results

Command:

```powershell
cd D:\education_app\backend
npm.cmd test
```

Result: **PASS**

- Tests: 44
- Passed: 44
- Failed: 0
- Skipped: 0
- Cancelled: 0

The focused cache tests also passed before the full suite.

## Production safety

- The change is local only and has not been deployed or pushed.
- No production configuration was changed.
- No production endpoint was called.
- No database operation was introduced.
- No indexes, migrations, schemas, authentication behavior, API fields, or UI behavior were changed.
- The endpoint remains role-filtered exactly as before.

## Remaining limitations

- Staging verification is pending because this task explicitly stops before deployment.
- The tests exercise the extracted endpoint middleware and filtering logic with an in-memory Express test app; they do not claim that the staging hostname has received this fix.
- After approval and an authorized staging deployment, verify headers with header-only requests: confirm `Cache-Control: private, no-store`, absence of `ETag`, and HTTP 200 for requests carrying arbitrary `If-None-Match` values. Cross-role runtime testing still requires authorized synthetic staging accounts.

## Next step requiring approval

Review this local diff and approve a separate staging deployment/verification step. Phase 1 optimization has not started.
