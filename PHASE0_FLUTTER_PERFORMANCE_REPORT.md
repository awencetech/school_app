# Phase 0 Flutter Performance Report

Generated: 2026-11-11

## Scope and result

This was a read-only profiling pass for the existing Flutter application. No Dart source, UI, API, authentication, backend, database, dependency, or configuration files were modified. Nothing was committed or pushed.

Native Android profiling was unavailable because no physical Android device or Android emulator was connected, and `flutter emulators` reported no available emulators. Flutter Web profile mode was available and was used for the limited measurements below.

The Admin, Staff, and Student dashboards could not be measured because no authenticated local test-account state was available in the running browser session. No credentials were requested, entered, printed, or inferred. Their results are explicitly marked **not measured**.

## Environment

| Item | Observed value |
|---|---|
| Flutter | 3.47.4, stable channel |
| Flutter framework revision | `9584c6713b` |
| Dart | 3.13.3 |
| DevTools | 2.60.0 |
| Android device | Not available |
| Android emulator | Not available; no emulators listed |
| Windows device | Available, but not used for dashboard profiling |
| Chrome | Available, Chrome 157.0.8103.50 |
| Edge | Available, Edge 157.0.4341.46 |
| Profiling mode | Flutter Web `--profile` |
| Local app URL | `http://127.0.0.1:8000/` |
| Backend target | Staging target configured by the existing app; no production endpoint was intentionally called by this profiling pass |
| Network conditions | Local Chrome-to-local Flutter web server with cross-origin staging API requests; no bandwidth or latency throttling applied |

## Measurement methodology

The app was launched with:

```text
flutter run -d chrome --profile --web-port 8000
```

The browser Performance Resource Timing API was used for URL paths, resource durations, and transfer-size metadata. Response bodies and dashboard data were not read or recorded. These are **web-profile browser measurements**, not native Android profile measurements.

Only one comparable startup/main-route run was available. Three dashboard runs were not practical because authenticated dashboard state was unavailable. No values are fabricated for missing runs.

## Dashboard measurements

| Dashboard | Run 1 | Run 2 | Run 3 | Average | First useful content | Loading complete | Initial API count | Duplicate API requests | Status |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Admin Dashboard | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m | Blocked: no authenticated admin test state |
| Staff Dashboard | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m | Blocked: no authenticated staff test state |
| Student Dashboard | n/m | n/m | n/m | n/m | n/m | n/m | n/m | n/m | Blocked: no authenticated student test state |

`n/m` means not measured. The running app reached `/#/main`, not one of the requested role dashboards.

## Actual web-profile observations

These observations are from the local Flutter Web profile startup/main route and must not be presented as role-dashboard timings:

| Resource path | Observed duration | Observation |
|---|---:|---|
| `/api/mainpage-info` | 7,574.6 ms | Initial main-page API resource timing; response status/body was not recorded |
| `/api/images/<redacted-id>` | 5,124.5 ms | First observed image resource timing; identifier redacted |
| `/api/images/<redacted-id>` | 2.6 ms | Same image path appeared a second time in the browser resource list |
| `/assets/assets/data/school.json` | 2.9 ms | Local asset load |
| `/assets/assets/data/staff.json` | 5.7 ms | Local asset load |
| Navigation `/` | 1,481.0 ms | Browser navigation resource timing |

The repeated image path is an observed duplicate resource entry on the main route. It is not proof of a duplicate dashboard request. The second fast entry may represent a cache hit or a second browser-level resource event; response headers/status were not captured.

### Browser/runtime symptoms

- Flutter Web profile compilation completed successfully.
- Chrome displayed a missing-font warning for some Noto glyphs.
- The initial attempt on port 8765 produced a CORS failure because that origin was not in the backend allowlist. The profiling run was repeated on port 8000, which is an allowed development origin.
- No native frame build/raster metrics or memory measurements were collected because no Android profile device was available.
- No dashboard-specific UI freeze or stutter assessment is claimed.

## API and image measurement limitations

The browser resource timing trace exposed durations but not reliable response status or body sizes for the cross-origin staging API. Transfer sizes were reported as zero for those entries because cross-origin timing metadata was not available to the browser. Therefore:

- API status codes: not measured from the Flutter browser trace.
- API payload sizes: not measured from the Flutter browser trace.
- Backend versus network split: not measured from Flutter; use the Phase 0 backend instrumentation headers/benchmark for that split.
- Image byte sizes: not measured from the Flutter browser trace.
- Protected dashboard API list: not measured.

## Static code observations

The following are code-level risks, not measured dashboard timings.

### Shared initialization dependency

[AppState](./lib/services/app_state.dart:29) creates a single `initialization` future. It loads six persisted values concurrently with `Future.wait` in [\_loadInitialState](./lib/services/app_state.dart:51), but applies a six-second timeout. Both [\_loadStaffInformation](./lib/screens/staff/staff_dashboard.dart:119) and [\_loadStudentInformation](./lib/screens/student/student_dashboard.dart:75) await that initialization future before loading the role profile. A slow preference/startup operation can delay first useful dashboard content.

### Staff dashboard starts two independent loads

[StaffDashboard.initState](./lib/screens/staff/staff_dashboard.dart:51) starts [\_loadStaffInformation](./lib/screens/staff/staff_dashboard.dart:119) and [\_loadAssignedClass](./lib/screens/staff/staff_dashboard.dart:57) independently. This is potentially parallel, but both paths may trigger separate authenticated API work and the assigned-class path explicitly requests a refresh at [staff_dashboard.dart:70](./lib/screens/staff/staff_dashboard.dart:70). Runtime tracing with an authenticated account is required to determine whether requests are duplicated or safely independent.

### Student dashboard waits on initialization before profile loading

[StudentDashboard.initState](./lib/screens/student/student_dashboard.dart:70) calls [\_loadStudentInformation](./lib/screens/student/student_dashboard.dart:75), which waits for `AppState.initialization` at [student_dashboard.dart:78](./lib/screens/student/student_dashboard.dart:78) before requesting student information. This is a candidate startup critical path, but its impact was not measured without an authenticated dashboard run.

### Dashboard rebuild scope

The Admin, Staff, and Student dashboard builds use `context.watch<SchoolConfigService>()` and, in places, `context.watch<AppState>()`; examples are [admin_dashboard.dart:146](./lib/screens/admin/admin_dashboard.dart:146), [staff_dashboard.dart:293](./lib/screens/staff/staff_dashboard.dart:293), and [student_dashboard.dart:299](./lib/screens/student/student_dashboard.dart:299). Any notification from those providers can rebuild the large dashboard subtree. This is a static rebuild-risk observation, not a measured rebuild count.

### Image loading and caching inconsistency

The dashboards use `CachedNetworkImage` for posters, such as [admin_dashboard.dart:177](./lib/screens/admin/admin_dashboard.dart:177), and `Image.network` for role profile images, such as [staff_dashboard.dart:187](./lib/screens/staff/staff_dashboard.dart:187) and [student_dashboard.dart:148](./lib/screens/student/student_dashboard.dart:148). This creates different cache/decode behavior between poster and profile-image paths. The main-route trace also observed the same image path twice, so image-cache behavior should be measured with authenticated dashboard flows.

### Large synchronous image decode risk

The dashboards can render base64 poster data through `Image.memory`, for example in [student_dashboard.dart:842](./lib/screens/student/student_dashboard.dart:842) and [admin_dashboard.dart:210](./lib/screens/admin/admin_dashboard.dart:210). Large base64 payloads and image decoding can create main-isolate or browser decode pressure. No frame trace was available to quantify it.

### Large dashboard widget trees and grids

The dashboards compose long `SingleChildScrollView`/column content with dashboard grids and quick-access sections. Examples include [student_dashboard.dart:702](./lib/screens/student/student_dashboard.dart:702) and [admin_dashboard.dart:303](./lib/screens/admin/admin_dashboard.dart:303). This is a static rendering-cost risk; visible frame jank was not measured.

### Main-page configuration request and normalization

[MainPageInfoRepository._fetchMainPageInfo](./lib/services/main_page_info_repository.dart:141) performs a 15-second timeout-wrapped request and then recursively normalizes the decoded payload through [_normalizePayload](./lib/services/main_page_info_repository.dart:53). The observed `/api/mainpage-info` resource duration was 7.57 s on the local web-profile run. The timing includes the cross-origin request path and cannot isolate backend, network, JSON decode, or normalization time.

### In-flight request coalescing exists for main-page info

[MainPageInfoRepository](./lib/services/main_page_info_repository.dart:71) has an in-flight future for main-page data, which is a positive duplicate-request safeguard. It was not possible to verify whether all dashboard consumers use the same repository path during authenticated flows.

## Performance conclusions

Measured:

- Flutter 3.47.4 / Dart 3.13.3.
- Flutter Web profile mode is supported and compiled successfully.
- Main-route navigation took 1,481.0 ms in one browser run.
- Main-page API resource timing was 7,574.6 ms.
- One image path was observed twice, with 5,124.5 ms and 2.6 ms resource durations.

Not measured:

- Native Android profile results.
- Three-run Admin, Staff, and Student dashboard timings.
- Dashboard first useful content and completion times.
- Protected API status, payload sizes, request IDs, MongoDB timing, and duplicate request counts.
- Flutter frame build/raster performance and memory usage.

The largest measured startup/main-route signal is the `/api/mainpage-info` resource at approximately 7.57 seconds, followed by an image resource at approximately 5.12 seconds. These are not sufficient to identify the protected dashboard bottleneck without authenticated runs and browser/network instrumentation that can safely record headers and sizes without recording bodies.

## Remaining blockers

1. No Android emulator or physical Android device is available for native profile mode.
2. No authenticated local admin, staff, or student test state is available.
3. Cross-origin browser resource timing does not expose reliable API status or payload-size data for the staging backend.
4. Three comparable runs per dashboard cannot be collected until authorized test accounts are available locally.

Phase 1 optimization has not started. No source code was changed.
