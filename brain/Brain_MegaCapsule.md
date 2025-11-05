# Brain_MegaCapsule.md — OpsGorge (C+ Stack)
## Identity & Scope
- Stack name: OpsGorge (C+)
- Purpose: Solo/Small-team hardened Workflow (PR gates + DoD + CI validate) for Windows-first ops.

## How to Think/Answer (Style Rules)
- Priorities: correctness > safety > clarity > speed.
- Style: crisp headings, short bullets, numbered steps, end with “Next steps.”
- Be a constructive skeptic: challenge assumptions, surface risks, propose mitigations.
- Evidence-first: show commands, exact toggles/clicks, and minimal context.

## Macros & Patterns
- **DoD Gate**: `validate` job must pass; DoD checks run via `scripts/check-dod.ps1`.
- **Perfection Loop**: define internal rubric ➜ iterate until 10/10 ➜ deliver.
- **Router Nudge + XML Sandwich**: use when creating major docs/specs.
- **Bootstrap vs Enforce**: `CI_BOOTSTRAP=1` = soft-pass; remove/flip to enforce.

## Current Repo State (from last session)
- Repo: PakkByte/OpsGorge (public).
- Branch protection (classic) on `main`: PR required (1 approval), conversation resolution ON, signed commits ON,
  required check: `validate`, up-to-date required, Code Owners enabled (`@PakkByte`).
- Workflow: `.github/workflows/validate.yml` (Windows, `pwsh`, job name: `validate`).
- DoD script: `scripts/check-dod.ps1` (secret scan, restore-map presence, bootstrap-safe).
- Dummy restore map: `2-Logs\restore_map_init.json` (can remove later).
- Known pitfalls fixed: here-string interpolation in YAML; regex/param header in DoD; avoid self-flag; skip binary/large files.

## Guardrails
- Never push to `main` directly; always branch + PR.
- Keep secrets out of repo; use allowlist/ignores in DoD scan when needed.
- Keep YAML ASCII/UTF-8 safe; avoid smart quotes/dashes in workflows.

## What “good” looks like (Definition of Done)
1) CI `validate` green; DoD checks pass or explicitly soft-passed in bootstrap.
2) PR small and scoped; conversations resolved; 1 approval (CODEOWNER).
3) README and scripts updated if behavior changed.
4) No secrets/artifacts committed; logs/snapshots in `2-Logs` as needed.

## Next Steps (typical)
- Flip DoD to enforce (unset `CI_BOOTSTRAP` or add `-Strict`).
- Wire Notion dashboard + n8n read-only pulses.
- Add JSON Schema checks + sample trees for policy tests.
