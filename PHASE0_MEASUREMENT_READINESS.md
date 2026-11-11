# Phase 0 Measurement Readiness

Generated: 2026-11-11

## Scope

This document prepares the remaining protected backend and Flutter measurements. It does not change the benchmark runner, Flutter source, APIs, authentication, database, deployment, dependencies, or Git state.

## 1. Protected API benchmark setup

### Obtain dedicated staging accounts

Request dedicated, non-production test accounts from the application owner or staging administrator. Ask for separate accounts/tokens for:

- one staging administrator;
- one staging staff/teacher;
- one staging student;
- one dedicated staging login account if login timing is required.

The accounts should contain synthetic or approved test data only, have the minimum role required for the read-only endpoints, and not be shared production accounts. The benchmark does not create records and should not use write endpoints.

### Retrieve role tokens

Use the normal staging login/authentication process approved by the application owner. The existing runner sends bearer tokens as:

```text
Authorization: Bearer <role-token>
```

The role-token variables consumed by [backend/performance-baseline.js](./backend/performance-baseline.js) are:

```text
BASELINE_ADMIN_TOKEN
BASELINE_STAFF_TOKEN
BASELINE_STUDENT_TOKEN
```

The existing runner does not consume `BASELINE_LOGIN_TOKEN`. Its login case is a normal `POST /api/login` and requires:

```text
BASELINE_LOGIN_IDENTIFIER
BASELINE_LOGIN_PASSWORD
```

Do not alter the runner to accept a different authentication format during Phase 0. If a dedicated login token is provided instead of an identifier/password, the login timing case remains blocked while token-based GET measurements may proceed with the matching role variables.

### Configure PowerShell without printing secrets

Set the staging target controls:

```powershell
$env:BASELINE_BASE_URL = 'https://school-app-1uep.onrender.com'
$env:BASELINE_TARGET_ENV = 'staging'
$env:BASELINE_STAGING_HOST = 'school-app-1uep.onrender.com'
$env:BASELINE_TIMEOUT_MS = '20000'
$env:BASELINE_WARM_REQUESTS = '20'
```

Set secret values only through a local secret manager or an untracked PowerShell session. Do not use commands that print values:

```powershell
$env:BASELINE_ADMIN_TOKEN = '<local secret value>'
$env:BASELINE_STAFF_TOKEN = '<local secret value>'
$env:BASELINE_STUDENT_TOKEN = '<local secret value>'
$env:BASELINE_LOGIN_IDENTIFIER = '<local secret value>'
$env:BASELINE_LOGIN_PASSWORD = '<local secret value>'
$env:BASELINE_IMAGE_PATH = '<approved staging image path>'
```

The placeholder assignments above are instructions only; replace them locally and never commit the resulting shell history or an environment file.

To verify presence without printing values:

```powershell
foreach ($name in @(
  'BASELINE_ADMIN_TOKEN',
  'BASELINE_STAFF_TOKEN',
  'BASELINE_STUDENT_TOKEN',
  'BASELINE_LOGIN_IDENTIFIER',
  'BASELINE_LOGIN_PASSWORD',
  'BASELINE_IMAGE_PATH'
)) {
  $item = Get-Item "Env:$name" -ErrorAction SilentlyContinue
  [pscustomobject]@{ Name = $name; Present = [bool]$item; NonEmpty = [bool]($item -and -not [string]::IsNullOrWhiteSpace($item.Value)) }
}
```

### Run and verify staging-only targeting

Run the existing runner without changing it:

```powershell
Set-Location D:\education_app\backend
npm.cmd run benchmark:performance
```

Before running, verify only the non-secret target values:

```powershell
"BASELINE_BASE_URL=$env:BASELINE_BASE_URL"
"BASELINE_TARGET_ENV=$env:BASELINE_TARGET_ENV"
"BASELINE_STAGING_HOST=$env:BASELINE_STAGING_HOST"
```

The runner’s safety guard requires the URL hostname to match `BASELINE_STAGING_HOST` when `BASELINE_TARGET_ENV=staging`. It refuses an unknown or production hostname unless the caller explicitly sets the unsafe override; do not set that override.

The runner uses the existing paths and methods, records errors rather than treating failed authentication as success, and writes aggregate/sample metadata without response bodies or authorization headers.

## 2. Flutter profiling readiness

### Verified tool state

- Flutter: 3.47.4 stable.
- Dart: 3.13.3.
- Android SDK/toolchain: available through Flutter Doctor at `C:\Users\user\AppData\Local\Android\Sdk`.
- Android emulator executable: recognized by Flutter Doctor.
- Connected Android device: none.
- Configured Flutter emulators: none (`flutter emulators` returned no emulators).
- Chrome and Edge: available.
- Android environment variables `ANDROID_HOME` and `ANDROID_SDK_ROOT`: absent in the current shell. This did not prevent Flutter Doctor from locating the SDK.

### Exact commands

List connected devices:

```powershell
flutter devices
```

List configured emulators:

```powershell
flutter emulators
```

After an authorized emulator/device is available, launch the existing app in native profile mode:

```powershell
Set-Location D:\education_app
flutter run --profile -d <android-device-id> --dart-define=API_BASE_URL=https://school-app-1uep.onrender.com
```

The Flutter CLI prints a VM service URL when the profile app is running. Connect DevTools with:

```powershell
dart devtools
```

Open the displayed DevTools URL, select the running VM service, and use:

- Performance/Timeline for frame build and raster timing;
- Performance Overlay for janky frames;
- Memory for heap/RSS trend and snapshots;
- Network/HTTP instrumentation available in the selected runtime tooling for request timing.

If the CLI offers a direct DevTools link, use that link instead of manually copying the VM service URI.

### Reproducible trace sequence

Use the same device, app build, account type, network, and cache state for three runs per flow:

1. Cold app launch: process start to first frame and first useful content.
2. Login: submit to role route usable.
3. Admin dashboard: route entry to useful content and loading completion.
4. Staff dashboard: same markers.
5. Student dashboard: same markers.
6. Route transitions: navigation start to settled frame.
7. Messages, Attendance, Diary, Resources: route entry to useful content.
8. Image-heavy screen: request start, first display, decode, and cache hit/miss.

Record only aggregate timings and redacted endpoint paths. Do not export bodies, names, identifiers, passwords, tokens, or screenshots containing personal data.

### Current Flutter limitation

At the time of this readiness check, no Android device or configured emulator was available. Therefore native profile measurements remain pending. Chrome Flutter Web profile mode is available, but web results must remain labeled separately from native Android results.

## 3. Investigation of the 7.57-second main-page API observation

### Exact client flow

The client path is:

1. [SplashConfigService._load](./lib/services/splash_config_service.dart:33) loads cached splash values.
2. It then calls [MainPageInfoRepository.getMainPageInfo](./lib/services/splash_config_service.dart:72).
3. [getMainPageInfo](./lib/services/main_page_info_repository.dart:107) coalesces concurrent calls through `_inFlightMainPageInfoFuture`.
4. [_fetchMainPageInfo](./lib/services/main_page_info_repository.dart:141) performs `GET /api/mainpage-info` with bearer headers and a 15-second timeout.
5. The response is decoded with `jsonDecode` at [main_page_info_repository.dart:149](./lib/services/main_page_info_repository.dart:149).
6. The entire decoded object is recursively traversed by [_normalizePayload](./lib/services/main_page_info_repository.dart:53), including every nested map and list.
7. Legacy `schoolContent.homeContent` is inspected and may be promoted at [main_page_info_repository.dart:157](./lib/services/main_page_info_repository.dart:157).
8. `MainPageInfo.fromJson` parses the normalized object at [main_page_info_repository.dart:196](./lib/services/main_page_info_repository.dart:196).

On the backend, [GET /api/mainpage-info](./backend/server.js:7403) calls [getMainPageDocument](./backend/server.js:7173), which executes `findOne({})`, selects/possibly promotes legacy home content, and returns the whole document through `mainPageInfoForUser` at [server.js:7443](./backend/server.js:7443). Admin authentication receives the full document; non-admin users have `gradePage` removed.

### What the 7.57 seconds includes

The earlier 7,574.6 ms value came from browser Resource Timing for `/api/mainpage-info` in a local Flutter Web profile run. That measurement is end-to-end browser resource duration. It may include:

- connection setup, DNS, TLS, proxy/Cloudflare, and network transfer;
- Render service wake-up or scheduling;
- backend request processing and MongoDB work;
- response transfer to the browser;
- browser resource-timing scheduling overhead.

It does not isolate server time, database time, JSON parsing, recursive normalization, or Flutter widget build time. The backend instrumentation headers and protected benchmark are required to split server/database/network components safely.

### Response parsing and normalization cost

The client performs a full `jsonDecode`, recursively visits every map/list/string, performs compatibility list inspection, and constructs a typed model. This is potentially expensive for a large document, but no Dart timeline trace was available to quantify each stage.

### Potential payload size

The endpoint can return a large school-configuration document containing school settings, content, members, news, achievements, grade data, and potentially poster/image data. The exact protected payload byte size was not available from the cross-origin browser timing trace, and no response body was recorded. Measure payload bytes with the existing backend benchmark after supplying an authorized admin token; do not save the response body.

### Timeout and retry behavior

- `_fetchMainPageInfo` has a 15-second timeout.
- The repository does not implement an application-level retry loop for this GET.
- `_inFlightMainPageInfoFuture` coalesces concurrent calls while one request is active, then clears after completion.
- `SplashConfigService` keeps cached values if the network request fails, but still attempts the server request during `_load`.
- There is no client-side evidence here that the 7.57-second request was retried.

### Backend cache behavior

The backend applies `Cache-Control: public, max-age=30, stale-while-revalidate=120` to `GET /api/mainpage-info` in [server.js:97](./backend/server.js:97). The route is optional-authenticated and returns a full admin document for admin auth, so the existing public cache policy requires security review before treating it as a safe optimization. This task does not change it.

## Verified findings versus assumptions

Verified:

- Existing runner paths and authentication variable names.
- Protected variables are currently not configured in the local shell.
- Android SDK/toolchain is available to Flutter Doctor, but no device/emulator is connected/configured.
- Flutter 3.47.4/Dart 3.13.3 and Chrome are available.
- Main-page request uses `GET /api/mainpage-info`, bearer headers, 15-second timeout, JSON decode, recursive normalization, compatibility handling, and model parsing.
- Backend uses MongoDB `findOne({})` and returns a large configuration document shaped by role.

Not yet measured:

- Protected endpoint latency, payload sizes, MongoDB operation timings, and error rates.
- Native first-frame, frame build/raster, jank, memory, JSON parsing, and image decode timings.
- Exact contribution of connection setup, Render, network, backend, MongoDB, parsing, and widget rendering to 7.57 seconds.

## Next gate

1. Obtain dedicated staging-only test accounts through the application owner.
2. Configure the existing runner’s exact local variables without printing values.
3. Run the protected backend benchmark at the existing low rate.
4. Connect an Android device or create an approved emulator, then collect three native profile runs per dashboard.
5. Review measured evidence before proposing any Phase 1 change.

Stop here. No Phase 1 implementation was started.
