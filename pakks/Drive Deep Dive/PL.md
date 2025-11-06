## Perfection Loop — Rubric
- Completeness: brain files present; manifest respected.
- CI/DoD: \alidate\ enforces \scripts/check-dod.ps1\ (Strict).
- Policy & Exclusions: no drift on \skipPaths\, \MinSizeMB\.
- Evidence: logs available under \2-Logs/\.
- Scope: this PR is small; no runtime risk.

### Changelog (OpsGorge bootstrap)
- Asserted CI workflow path (\.github/workflows/validate.yml\).
- Ensured \scripts/check-dod.ps1\ exists (Strict).
- Seeded \2-Logs/restore_map_init.json\.

### Proof
- Local DoD: \pwsh -NoProfile -File .\scripts\check-dod.ps1 -Strict\ passed.
- CI gate: job **validate** required on PR.

PL-Score: 10/10
