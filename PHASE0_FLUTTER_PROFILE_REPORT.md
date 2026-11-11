# Phase 0 Flutter Profile Report

Generated: 2026-11-11

## Result

Native Flutter dashboard measurements remain pending. No physical Android device or emulator was available, and `flutter emulators` listed none. Flutter Web profile mode was available and compiled successfully, but authenticated dashboard flows could not be entered because no local test-account state was available.

No source code, UI, API, authentication, backend, database, dependency, or production configuration was modified.

## Environment

| Item | Value |
|---|---|
| Flutter | 3.47.4 stable |
| Dart | 3.13.3 |
| DevTools | 2.60.0 |
| Android device/emulator | Unavailable |
| Chrome | Available; 157.0.8103.50 |
| Mode attempted | Flutter Web `--profile` |
| Local command | `flutter run -d chrome --profile --web-port 8000` |
| Browser network | Local Flutter server to staging API; no throttling |

## Dashboard measurements

| Screen | First frame | Useful content | Loading complete | API count | Duplicate requests | Frame/raster | Memory | Result |
|---|---:|---:|---:|---:|---:|---|---|---|
| Admin Dashboard | n/m | n/m | n/m | n/m | n/m | n/m | n/m | Blocked: no authenticated admin state |
| Staff Dashboard | n/m | n/m | n/m | n/m | n/m | n/m | n/m | Blocked: no authenticated staff state |
| Student Dashboard | n/m | n/m | n/m | n/m | n/m | n/m | n/m | Blocked: no authenticated student state |

No native profile, dashboard, login, route-transition, memory, frame-build, frame-raster, JSON-decoding, or image-decoding measurements are claimed.

## Existing web-profile observation

The earlier local main-route Flutter Web profile run produced these measured resource timings. They are not dashboard results:

| Resource | Duration |
|---|---:|
| Local browser navigation | 1481.0 ms |
| `/api/mainpage-info` | 7574.6 ms |
| First observed image path | 5124.5 ms |
| Same image path second entry | 2.6 ms |

The same image path appeared twice. This is evidence of repeated browser resource observation, not proof of a protected dashboard duplicate request. Cross-origin resource timing did not provide reliable API response status or payload bytes.

## Reproducible native profile plan

When an authorized Android device/emulator and local test state are available, use one device and one network condition for all runs:

```powershell
flutter devices
flutter run --profile -d <android-device-id> --dart-define=API_ENV=staging
```

For each of three runs per screen, record using DevTools Timeline, Performance Overlay, Network/Chrome tracing where applicable, and memory tooling:

1. App startup: process launch to first frame and first useful frame.
2. Login: submit to authenticated dashboard route.
3. Admin, Staff, Student dashboard: route entry to useful content and loading completion.
4. Route transitions: tap/navigation start to transition completion.
5. Messages, Attendance, Diary, Resources: first useful content and API completion.
6. Image-heavy screens: request start, first display, decode duration, and cache hit/miss.

Capture frame build time, raster time, janky-frame count/percentage, memory before/after, JSON parse/decode time, image decode time, API request count, status, duration, and duplicate requests. Export only aggregate timings and redacted URL paths; never export bodies, identifiers, tokens, or personal data.

## Static code risks to validate during profiling

- [AppState initialization](./lib/services/app_state.dart:29) loads persisted state before role profile loading; Staff and Student dashboards await it with a six-second timeout at [staff_dashboard.dart:119](./lib/screens/staff/staff_dashboard.dart:119) and [student_dashboard.dart:75](./lib/screens/student/student_dashboard.dart:75).
- Staff starts staff-information and assigned-class loads from [staff_dashboard.dart:51](./lib/screens/staff/staff_dashboard.dart:51); runtime tracing is required to confirm request overlap or duplication.
- Dashboard trees watch shared providers, for example [admin_dashboard.dart:146](./lib/screens/admin/admin_dashboard.dart:146), which may broaden rebuild scope.
- Posters use `CachedNetworkImage`, while profile images use `Image.network`, for example [staff_dashboard.dart:187](./lib/screens/staff/staff_dashboard.dart:187), creating different cache/decode paths.
- Base64 poster paths use `Image.memory`, for example [student_dashboard.dart:842](./lib/screens/student/student_dashboard.dart:842), which may create decode pressure for large images.
- Main-page data is fetched and recursively normalized in [main_page_info_repository.dart:141](./lib/services/main_page_info_repository.dart:141) and [main_page_info_repository.dart:53](./lib/services/main_page_info_repository.dart:53).

These are static observations only. No optimization was implemented.

## Blockers

1. Android profiling device/emulator unavailable.
2. Authenticated local test state unavailable.
3. Cross-origin browser timing lacks reliable API status and payload-size data.

Phase 1 work has not started.
