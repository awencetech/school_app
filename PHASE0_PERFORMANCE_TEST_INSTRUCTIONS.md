# Phase 0 Performance Test Instructions

These instructions collect a protected staging baseline only. They do not apply optimizations, change API contracts, modify UI behavior, create indexes, or modify database data.

## Safety requirements

- Use only `https://school-app-1uep.onrender.com` or another explicitly approved staging/disposable target.
- Do not use the nested repository's production environment file.
- Do not paste credentials, tokens, MongoDB URIs, or passwords into reports or chat.
- Keep credential values in a local secret manager, shell environment, or untracked local configuration.
- Do not run write endpoints. The benchmark cases are GET requests plus the normal login request.
- Treat a 401, 403, 404, 429, 5xx, or timeout as a result to report, not as a reason to retry indefinitely.

## Configure the staging target

Run from [backend/](./backend/) in a PowerShell session:

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
$env:BASELINE_TIMEOUT_MS = '20000'
$env:BASELINE_WARM_REQUESTS = '20'
```

Set the following names locally only when approved staging values are available. Do not echo them:

```text
BASELINE_LOGIN_IDENTIFIER
BASELINE_LOGIN_PASSWORD
BASELINE_ADMIN_TOKEN
BASELINE_STAFF_TOKEN
BASELINE_STUDENT_TOKEN
BASELINE_IMAGE_PATH
```

The login identifier and password are used only for the staging login request. Role tokens are used only for the corresponding read-only endpoint cases. The runner never prints their values and does not include authorization headers in output files.

## Run the benchmark

```powershell
Set-Location D:\education_app\backend
npm.cmd run benchmark:performance
```

The runner performs one first-observed request, 20 sequential warm requests, and 20 conditional requests where the first response supplies an ETag. It writes:

- [performance-baseline.json](./performance-baseline.json)
- [performance-baseline.csv](./performance-baseline.csv)
- [PERFORMANCE_BASELINE_REPORT.md](./PERFORMANCE_BASELINE_REPORT.md)

The first request is not a guaranteed process cold start. A true cold-start measurement requires a separately recorded service restart or scale-to-zero event. The report must label it as cold-observed unless that event is known.

## Validate deployed instrumentation before protected tests

The instrumentation source is currently committed locally as `1b45680`. Do not interpret missing live headers as a zero-duration backend or database measurement until that commit is deployed to staging.

Use a header-only probe; do not print response bodies or secrets:

```powershell
$response = Invoke-WebRequest -Uri "$env:BASELINE_BASE_URL/health" -UseBasicParsing
$response.Headers.Keys |
  Where-Object { $_ -match 'Performance|Server-Timing|Expose|Cache|ETag' } |
  ForEach-Object { "$_=$($response.Headers[$_])" }
```

Expected when staging instrumentation is active:

- `X-Performance-Request-Id`
- `X-Performance-Total-Ms`
- `X-Performance-DB-Operations`
- `X-Performance-DB-Time-Ms`
- `Server-Timing`

If all five headers are absent, stop the protected benchmark and follow [PHASE0_DEPLOYMENT_VERIFICATION.md](./PHASE0_DEPLOYMENT_VERIFICATION.md). Do not report client time as backend time.

For browser clients, also verify `Access-Control-Expose-Headers` includes the timing headers. Server-side benchmark code can read headers without CORS, but Flutter Web cannot.

## Validate conditional requests

```powershell
$first = Invoke-WebRequest -Uri "$env:BASELINE_BASE_URL/health" -UseBasicParsing
$etag = $first.Headers['ETag']
try {
  $conditional = Invoke-WebRequest -Uri "$env:BASELINE_BASE_URL/health" -Headers @{ 'If-None-Match' = $etag } -UseBasicParsing
  "status=$($conditional.StatusCode)"
} catch {
  if ($_.Exception.Response) {
    "status=$([int]$_.Exception.Response.StatusCode)"
  } else {
    throw
  }
}
```

For this public health response, HTTP 304 is expected when the validator is honored. Do not generalize that cache policy to private dashboard or student data. Any endpoint containing authorization-dependent data must remain private or non-cacheable unless its security properties are explicitly reviewed.

## Endpoint coverage

The current runner covers login, admin dashboard, staff profile, student profile, messages, attendance, diary, groups, classes, resources, and an optional image path. It records status, client duration, payload bytes, ETag/cache headers, backend timing headers when present, and MongoDB timing/count headers when present.

For every case, review:

- average, p50, p95, p99, and maximum client response time;
- HTTP error count and status distribution;
- payload size;
- backend total time, database time, operation count, and estimated network overhead when headers are available;
- cold-observed versus warm versus cached-conditional phases;
- timeouts and skipped-case reasons.

## Flutter profile-mode collection

Server-side benchmarking cannot measure Flutter first-frame or widget timings. Collect those separately on a representative device/profile build:

```powershell
flutter pub get
flutter run --profile --dart-define=API_ENV=staging
```

Record DevTools Timeline/Performance Overlay traces for:

- app startup and first useful frame;
- login submit to usable home screen;
- admin dashboard;
- staff dashboard;
- student dashboard;
- page navigation/route transition;
- image request, decode, and first display.

Record frame build/raster jank, JSON decode time, image decode time, memory growth, and the number of network requests. Do not alter UI code or state-management behavior as part of measurement.

## Current blockers

- Commit `1b45680` could not be pushed from this workspace because GitHub returned HTTP 403 for `awencetech/school_app`.
- Staging timing headers are not currently visible from the deployed service.
- CORS does not currently expose the custom timing headers to browser clients.
- No local `BASELINE_*` credential/token names are populated, so protected cases are skipped.
- MongoDB timing/count cannot be confirmed until a request passes through the deployed instrumented process.

Stop after the protected baseline report is generated and reviewed. Wait for explicit approval before Phase 1 optimization changes.
