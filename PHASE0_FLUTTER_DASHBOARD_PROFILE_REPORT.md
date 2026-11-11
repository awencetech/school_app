# Phase 0 Flutter Dashboard Profile Report

Generated: 2026-11-11

## Result

**BLOCKED for authenticated dashboard profiling.** No Android physical device or emulator was available, and no authenticated staging account state was configured. No dashboard timings are invented.

## Toolchain verification

| Item | Observed result |
|---|---|
| Flutter | 3.47.4 stable |
| Dart | 3.13.3 |
| DevTools | 2.60.0 |
| Android SDK | Available, version 36.0.0 |
| Android devices | None connected |
| Android emulators | None available from `flutter emulators` |
| Chrome | Available, version 157.0.8103.50 |
| Flutter web profile | Available from prior project run |

`flutter doctor -v` also reported a network handshake warning for `pub.dev` and an unrelated missing Visual Studio C++ workload. Neither created an Android profiling target.

## Dashboard measurements

| Workflow | Profile runs | Startup/useful content | API/frame/image/memory metrics | Result |
|---|---:|---|---|---|
| Admin login/dashboard | 0 | Not measured | Not measured | Blocked: no device and no admin account state |
| Staff login/dashboard | 0 | Not measured | Not measured | Blocked: no device and no staff account state |
| Student login/dashboard | 0 | Not measured | Not measured | Blocked: no device and no student account state |

No debug-mode measurements are presented as profile measurements.

## Existing static observations

The existing Flutter code contains previously identified risks requiring runtime traces:

- Staff and student dashboards await shared app initialization with a timeout in `lib/screens/staff/staff_dashboard.dart` and `lib/screens/student/student_dashboard.dart`.
- Dashboard screens use shared provider/state dependencies that may broaden rebuild scope.
- The code mixes `Image.network`, `CachedNetworkImage`, and `Image.memory`, so image caching and decode behavior needs device tracing.
- Main-page data is recursively normalized in `lib/services/main_page_info_repository.dart`.

These are static observations only, not measured bottlenecks.

## Reproducible next run

```powershell
Set-Location D:\education_app\Education_App
flutter devices
flutter run --profile -d <android-device-id> --dart-define=API_ENV=staging
```

Use Flutter DevTools Timeline/Performance and repeat each role dashboard three times on the same device and network. Record first frame, useful content, loading completion, API count/duplicates, JSON decode, image decode, frame build/raster, jank, and memory. Do not record bodies, tokens, or personal data.

