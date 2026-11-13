# Phase 1 Campaign Performance Follow-up

**Date:** 2026-11-12  
**Scope:** Continue the existing Phase 1 campaign-performance target without changing its API behavior or accessing production/staging services or databases.

## Result

The campaign endpoint still has one campaign-specific `student-info` read. Its existing full-document read and single-pass recursive score calculation were retained. No additional runtime optimization passed the measured safety/performance bar in this follow-up.

The earlier Phase 1 work already consolidated achievement counting and score extraction into one recursive traversal per student. This follow-up adds a regression fixture for nested arrays, maximum-mark precedence, zero-total fallback, student counts, score values, and returned student details. A further request-local setup-hoisting experiment produced identical output on generated records but was slower in a controlled synthetic comparison; that experiment was reverted.

**Projection status: BLOCKED.** The stored campaign score schema and legacy-data compatibility contract are not authoritative in the repository. The existing recursive matching behavior can discover values under arbitrary nested paths, so narrowing the read would risk silently changing marks, totals, or toppers.

## Existing behavior and investigation

- `backend/server.js:962-969` handles `GET /api/campaign-performance`, applies the existing staff-role middleware, reads matching students once, and delegates to `buildCampaignPerformance`.
- The campaign-specific query is one `studentInfoCollection.find({ role: { $in: ['student', 'Student', ''] } }).toArray()` at `backend/server.js:965`. No duplicate campaign query was found. The protected-request authentication middleware may make its own user lookup; runtime query-command counts were not measured.
- `backend/campaign_performance.js` performs one recursive depth-first traversal per student in JavaScript property order, including array entries. It normalizes each key by lowercasing and removing non-ASCII alphanumeric characters, concatenates normalized ancestor paths, and uses substring matching. The first matching finite or numeric-convertible value wins.
- Effective score substrings are `classtest` and `monthlytest`. The legacy alias strings `class_test` and `monthly_test` are also present in the search lists, but underscores are removed from paths, so those literal alias strings do not match independently.
- Total searches include the corresponding test substring plus `totalmark` and `maxmark`. Consequently, numeric values below a test-matching ancestor can supply both that test's score and total. Generic total-mark paths may also supply both total values. Existing traversal order and this broad precedence are intentionally preserved.
- `totalMark || 100` remains in effect, so a missing or zero total falls back to 100. Response fields also depend on `name`, `studentId`, `className`, `section`, `imageUrl`, `photo`, `profileImage`, `achieved`, `status`, and the number of matching student records.
- `backend/server.js:1859-1863` declares app-managed `student-info` indexes on `studentId` and `admissionNumber`; no `role` index is declared there. This does not rule out indexes created outside the application. No database connection or `explain()` was run, so actual indexes, plans, scan counts, and query timings are unknown.
- Flutter search found the request in `lib/services/campaign_performance_service.dart:30-34`, but no service call site and no campaign-specific Dart test were found under `lib/` or `test/`. There is no repository evidence of duplicate Flutter campaign requests.

## Projection blocker: required authoritative contract

The projection must remain blocked until an application/data owner supplies a versioned contract covering all of the following:

1. **Canonical class-test score path(s):** exact dot paths from the `student-info` document root, including whether the score value is a number or a string and its accepted string format.
2. **Canonical monthly-test score path(s):** the same detail, separately from class tests.
3. **Canonical total-mark path(s):** exact total paths, including whether totals are test-specific or shared, and what to do when a total is absent or zero.
4. **Supported legacy aliases:** the exact old field names/path patterns to retain, including aliases that rely on the current normalized-ancestor substring behavior. The owner must explicitly decide whether the currently ineffective underscore spellings (`class_test`, `monthly_test`) are intended compatibility aliases or merely historical strings.
5. **Nested object and array rules:** which parent paths can contain results; whether nested arrays are supported at every level; and the required property/array traversal order if multiple values match.
6. **Matching and precedence:** key normalization, ancestor matching, numeric conversion rules, first-match selection, conflicts between score and total paths, and the zero/missing-total fallback.
7. **Existing-record policy:** an inventory/compatibility decision for existing documents outside the canonical schema, with a migration/backfill plan or explicit owner approval to stop supporting those records. A projection must include every required root-level parent path.
8. **Writer and data-conformance confirmation:** identify all writers/importers and establish that all supported existing records conform, through validation evidence or migration. The current repository does not establish that create/update flows write campaign scores or that historical records use a closed set of paths.

Until that evidence exists, adding a projection, changing the matcher, limiting records, or moving calculation into an aggregation could change which students or marks are returned. No such change was made.

## Optimization experiment and measurements

The only new runtime idea tested was hoisting the per-student query descriptors into module scope. On generated in-memory student records, old and experimental outputs passed a deep equality comparison. Five alternating measurements in the same Node process showed the experiment was slower, so it was reverted:

| Synthetic records | Existing helper median | Hoisted experiment median | Result JSON bytes |
|---:|---:|---:|---:|
| 1,000 | 7.732 ms | 19.905 ms | 2,581 |
| 10,000 | 61.264 ms | 192.556 ms | 24,507 |
| 50,000 | 304.440 ms | 913.774 ms | 122,848 |

These are helper CPU timings, not HTTP endpoint or MongoDB timings. They do not predict production latency. The experiment is not present in the final implementation.

After reverting, a separate local synthetic run (one warm-up, seven timed iterations) measured the retained helper:

| Synthetic records | Median | Maximum | Result JSON bytes |
|---:|---:|---:|---:|
| 1,000 | 8.820 ms | 15.591 ms | 2,581 |
| 10,000 | 77.317 ms | 98.413 ms | 24,507 |
| 50,000 | 328.829 ms | 359.445 ms | 122,848 |

The two runs differ in run count and observed timing; neither is a live endpoint benchmark. They support no claim of an improvement. No local MongoDB connection was attempted, so query-plan validation was not performed. The configured development environment is known from the earlier investigation to point at a remote Atlas host; it was not used.

## Regression verification

- Focused command, from `D:\education_app\backend`: `node --test test/campaign_performance.test.js test/phase1_read_optimization.test.js` — **12 passed, 0 failed**.
- Full backend command, from `D:\education_app\backend`: `npm.cmd test` — **78 passed, 0 failed, 0 skipped**.
- `node --check backend\campaign_performance.js` — passed.
- `git diff --check` — passed.
- The new campaign fixture compares the complete response against the prior algorithm and an explicit expected response. It verifies mark and total values, zero-total fallback, matching and achieved student counts, topper details, rank, and response structure.
- No Flutter campaign test was available. No Flutter source changed, so no Flutter suite was run.
- No production/staging request, database query, deployment, commit, or push was performed.

## Files and Phase 1 status

Files changed in this follow-up:

- `backend/test/campaign_performance.test.js` — added one regression fixture; this file was already untracked in the pre-existing worktree.
- `PHASE1_CAMPAIGN_PERFORMANCE_REPORT.md` — added this follow-up report.

`backend/server.js` and `backend/campaign_performance.js` were not changed by this follow-up. Pre-existing worktree changes were preserved.

Phase 1 remains **6 of 7 targets PASS**. Campaign performance is investigated and its existing one-pass calculation is regression-tested, but the campaign target remains **BLOCKED for safe database projection** until the authoritative schema, legacy compatibility policy, and data-conformance evidence above are provided.
