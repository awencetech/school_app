# Phase 0 Disposable Staging Clone Approval Request

## Request status

**Approval request only.** No owner has been contacted through this document, and no infrastructure, database, API, account, or application change has been performed.

## Purpose

Approve a disposable staging database clone and temporary backend service for:

- Safe creation of synthetic Admin, Staff/Teacher, and Student fixtures.
- Read-only protected Phase 0 performance measurements.
- Authenticated Flutter dashboard profiling against synthetic data.
- Isolation from shared staging data and reliable cleanup by clone disposal.

Phase 1 optimization remains out of scope.

## Approved source staging environment

- Source staging URL: `https://school-app-1uep.onrender.com`
- Source staging database: `mmhs_staging`
- Source repository/service configuration: `awencetech/school_app`, branch `master`, backend root
- Production systems and production credentials are explicitly excluded.

The source staging environment is reference-only for this request. No fixture writes should be made to the shared `mmhs_staging` database under the normal plan.

## Requested isolated environment

Please approve the following temporary resources:

1. A disposable clone of the approved staging database with a distinct database name, for example an owner-selected `mmhs_phase0_clone_<run-id>` name.
2. A temporary backend service or isolated staging deployment connected exclusively to that clone.
3. A verified service-to-database mapping before any write or login test.
4. Restricted database and application credentials supplied only through the approved secret manager.
5. A defined expiration date and disposal owner for both the temporary service and clone.

The clone name, service name, network policy, and credentials should be selected by the infrastructure/database owner. They are intentionally not created or recorded here.

## Proposed synthetic fixtures

These are synthetic identifiers only and contain no real-person information. The owner may approve them or provide replacements.

| Fixture | Proposed identifier | Required data |
|---|---|---|
| Admin credential | `phase0-admin-20261111` / `phase0-admin-20261111@example.invalid` | Credential only; canonical role `admin` |
| Staff credential/profile | `phase0-staff-20261111` / `phase0-staff-20261111@example.invalid` | Credential plus synthetic employee profile using employee ID `phase0-staff-20261111` |
| Student credential/profile | `phase0-student-20261111` / `phase0-student-20261111@example.invalid` | Credential plus synthetic student profile using student ID `phase0-student-20261111` |
| Class, if required | `phase0-class-20261111` | Synthetic class metadata only, with approved school ID and year |
| Group, optional | `phase0-group-20261111` | Create only if the selected benchmark requires group authorization |

Passwords, tokens, cookies, MongoDB URIs, and secret values must be generated and stored only in the approved secret manager. They must not be placed in this request or project files.

## Fixture rules

- Verify every identifier is absent in the clone before creation.
- Treat any pre-existing matching record as a stop condition; never modify it.
- Create credentials, profiles, class/group records, memberships, and staff access sequentially.
- Record exact MongoDB `_id` values privately for every created fixture.
- After every successful operation, perform exact read-back and verify the synthetic identity.
- After an ambiguous response or timeout, read back by the exact approved identifier before deciding whether the operation succeeded. Never blindly retry.
- Do not create a Group unless group authorization is required by the benchmark plan.
- Never modify a pre-existing staff-access record.
- Create a staff-access record only if it is absent and an isolated cleanup method is approved in advance.
- Keep all benchmark traffic read-only after normal authentication setup.

## Cleanup and disposal responsibilities

### Infrastructure/database owner

- Provision the clone and restricted credentials.
- Verify the temporary service connects only to the clone.
- Set the clone and temporary service expiration.
- Dispose of the clone and temporary service after the run.
- Confirm disposal without exposing credentials or raw data.

### Application/performance test owner

- Maintain a private fixture ledger containing only approved synthetic identifiers, exact MongoDB `_id` values, creation status, and verification status.
- Revoke and remove local tokens, cookies, passwords, and secret-manager entries after testing.
- Stop benchmarks and Flutter sessions before disposal.
- Confirm no writes were made outside the clone.
- Retain only aggregate performance reports.

### Cleanup limitations

Cleanup through application routes is non-cascading:

- Deleting credentials does not delete profiles.
- Deleting profiles does not delete credentials, memberships, access, attendance, messages, diary, resources, or images.
- Group deletion invokes `renumberGroups()` and may update unrelated group ordering.
- Staff-access has no isolated delete route identified; an empty-array update could remove permissions and is not an acceptable cleanup substitute.

For these reasons, clone disposal is the preferred cleanup mechanism. If a staff-access record is created, its isolated cleanup method must be approved before creation. If a Group is not required, it should not be created.

## Known risks and safeguards

| Risk | Required safeguard |
|---|---|
| Writes reach shared staging or production | Verify service/database mapping and target allowlist before every phase |
| Synthetic ID collision | Exact preflight read; abort on any existing match |
| Duplicate record after timeout | Exact read-back; no blind retry |
| Existing staff permissions overwritten | Abort if staff-access record exists; never merge or replace it |
| Group deletion changes unrelated ordering | Omit Group unless required; prefer clone disposal |
| Related records remain after route deletion | Use a private `_id` ledger and dispose of the clone |
| Secrets appear in artifacts | Secret manager only; no secrets in source, logs, reports, or chat |
| Concurrent create race | Sequential execution only |
| Benchmark changes data | Existing read-only benchmark scope; no write endpoints |

## Separate approval checklist

Please approve or reject each item independently:

- [ ] Clone the approved staging database into a distinct disposable database.
- [ ] Provision a temporary backend service connected exclusively to that clone.
- [ ] Approve the service-to-clone mapping and target verification procedure.
- [ ] Approve restricted credentials through the approved secret manager.
- [ ] Approve the proposed synthetic Admin credential.
- [ ] Approve the proposed synthetic Staff credential and profile.
- [ ] Approve the proposed synthetic Student credential and profile.
- [ ] Approve the synthetic class fixture, if needed.
- [ ] Approve the optional Group fixture only if group authorization is required.
- [ ] Approve the private exact-Mongo-`_id` fixture ledger.
- [ ] Approve the isolated cleanup method for any newly inserted staff-access record.
- [ ] Approve the sequential execution and ambiguous-response read-back policy.
- [ ] Approve the clone expiration date and disposal owner.
- [ ] Approve retention of aggregate reports only, with deletion of secrets and raw test artifacts.

## Requested owner decision

Approve the disposable clone and temporary isolated backend service first. Fixture creation will remain blocked until the clone is provisioned, target mapping is verified, secret handling is approved, and the fixture/cleanup checklist above is separately approved.

