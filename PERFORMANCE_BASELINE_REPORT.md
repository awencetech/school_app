# Phase 0 Performance Baseline Report

Generated: 2026-11-11T07:12:22.881Z
Target: https://school-app-1uep.onrender.com

This report contains measurements collected by the safe baseline runner. It does not claim a true cold start unless the first observed request happened after a service restart. Protected cases without an explicitly supplied staging token are skipped. No production endpoint was benchmarked by default.

## Measurement status

- Instrumented backend timing: available
- MongoDB timing/count: available on instrumented requests
- Cache validation: 40 conditional-cache samples; 0 returned HTTP 304
- Skipped cases: 11

## Results

| Case | Phase | Samples | p50 ms | p95 ms | p99 ms | Average ms | Max ms | HTTP errors | Avg payload bytes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| health | cold-observed | 1 | 2256.457 | 2256.457 | 2256.457 | 2256.457 | 2256.457 | 0 | 15 |
| health | warm | 20 | 403.296 | 566.704 | 845.653 | 431.725 | 845.653 | 0 | 15 |
| health | cached-conditional | 20 | 397.716 | 461.221 | 644.859 | 395.828 | 644.859 | 0 | 15 |
| readiness | cold-observed | 1 | 655.613 | 655.613 | 655.613 | 655.613 | 655.613 | 0 | 18 |
| readiness | warm | 20 | 604.439 | 763.452 | 871.113 | 633.003 | 871.113 | 0 | 18 |
| readiness | cached-conditional | 20 | 647.449 | 798.789 | 962.473 | 657.243 | 962.473 | 0 | 18 |

## Bottleneck evidence

- Client total time is the complete request duration measured from the benchmark workstation.
- Backend total time is read from `Server-Timing: app` when staging instrumentation is enabled.
- Database time and operation count are read from staging-only instrumentation headers when available.
- Network overhead is an estimate of client total minus backend total and includes transport, proxy, and scheduling effects.
- A 404/401/403 is recorded as an HTTP error, not hidden or treated as a successful performance result.

## Skipped and blocked cases

- login (POST /api/login): Set BASELINE_LOGIN_TOKEN.
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
