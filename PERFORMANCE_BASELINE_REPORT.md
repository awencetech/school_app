# Phase 0 Performance Baseline Report

Generated: 2026-11-11T06:02:55.683Z
Target: https://school-app-1uep.onrender.com

This report contains measurements collected by the safe baseline runner. It does not claim a true cold start unless the first observed request happened after a service restart. Protected cases without an explicitly supplied staging token are skipped. No production endpoint was benchmarked by default.

## Measurement status

- Instrumented backend timing: not observed; response timing is client-side only
- MongoDB timing/count: not observed
- Cache validation: 40 conditional-cache samples; 0 returned HTTP 304
- Skipped cases: 11

## Results

| Case | Phase | Samples | p50 ms | p95 ms | p99 ms | Average ms | Max ms | HTTP errors | Avg payload bytes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| health | cold-observed | 1 | 1349.238 | 1349.238 | 1349.238 | 1349.238 | 1349.238 | 0 | 15 |
| health | warm | 20 | 397.4 | 451.741 | 963.516 | 405.788 | 963.516 | 0 | 15 |
| health | cached-conditional | 20 | 363.871 | 502.157 | 510.027 | 373.018 | 510.027 | 0 | 15 |
| readiness | cold-observed | 1 | 649.861 | 649.861 | 649.861 | 649.861 | 649.861 | 0 | 18 |
| readiness | warm | 20 | 596.949 | 966.242 | 1126.755 | 638.835 | 1126.755 | 0 | 18 |
| readiness | cached-conditional | 20 | 589.505 | 654.564 | 656.198 | 584.218 | 656.198 | 0 | 18 |

## Bottleneck evidence

- Client total time is the complete request duration measured from the benchmark workstation.
- Backend total time is read from `Server-Timing: app` when staging instrumentation is enabled.
- Database time and operation count are read from staging-only instrumentation headers when available.
- Network overhead is an estimate of client total minus backend total and includes transport, proxy, and scheduling effects.
- A 404/401/403 is recorded as an HTTP error, not hidden or treated as a successful performance result.

## Skipped and blocked cases

- login (POST /api/login): Set BASELINE_LOGIN_IDENTIFIER and BASELINE_LOGIN_PASSWORD.
- admin-dashboard (GET /api/mainpage-info): Set BASELINE_ADMIN_TOKEN.
- staff-dashboard (GET /api/staff/profile): Set BASELINE_STAFF_TOKEN.
- student-dashboard (GET /api/students/profile): Set BASELINE_STUDENT_TOKEN.
- messages (GET /api/messages/inbox): Set BASELINE_STUDENT_TOKEN.
- attendance (GET /api/student-attendance): Set BASELINE_STUDENT_TOKEN.
- diary (GET /api/diary/student): Set BASELINE_STUDENT_TOKEN.
- groups (GET /api/groups): Set BASELINE_STUDENT_TOKEN.
- classes (GET /api/classes): Set BASELINE_STAFF_TOKEN.
- resources (GET /api/school-resources): Set BASELINE_STUDENT_TOKEN.
- image (GET ): No BASELINE_IMAGE_PATH supplied.

## Flutter profile-mode collection instructions

Run these on a representative physical Android device or emulator against staging:

```powershell
flutter pub get
flutter run --profile --dart-define=API_ENV=staging
```

Collect DevTools Timeline and Performance Overlay traces for: startup, login, each role dashboard, route transition, messages, attendance, diary, resources, and image-heavy screens. Record first-frame time, time-to-useful-content, route transition time, frame build/raster jank, JSON decode time, image decode time, and memory. No Flutter profile timings were collected automatically by this server-side runner.

## Static bottleneck findings

These are source-level findings, not measured protected-endpoint timings:

1. `GET /api/campaign-performance` loads student records and sorts performance data in Node.js.
2. `GET /api/messages/inbox` reads multiple message sources and merges/sorts in application memory.
3. Groups, attendance, diary, messages, resources, news, announcements, and events contain list reads materialized with `toArray()` without a consistently visible limit/cursor/projection.
4. Login searches multiple identifier fields and role credential collections, with legacy fallback reads.
5. Dashboard profile loading waits on `AppState.initialization` before requesting profile data.
6. Flutter uses both `Image.network` and `CachedNetworkImage`, producing inconsistent image-cache behavior.
7. Duplicate runtime requests cannot be confirmed without authenticated dashboard traces; the benchmark records each request independently and does not invent duplicate counts.

## Next gate

Provide staging-only login credentials, role tokens, and an optional image path through environment variables, then rerun this benchmark. Do not proceed to Phase 1 optimizations until the protected baseline is reviewed and approved.
