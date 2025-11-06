# Tests (T1–T4) — AI_Workspace
- T1: Repo guards — validate.yml present; PL.md has PL-Score; PR template exists.
- T2: Brains present — brain_global + project + chat indices exist.
- T3: Pakks portability — fresh clone on macOS runs a sample script without local-only paths.
- T4: Dupes under control — dupes.csv groups reduced vs previous snapshot; LatestPath kept.

## Quick verify
- T1: PR → CI shows DoD PASS + PL PASS (≥9/10).
- T2: git ls-files brain_global/** projects/AI_Workspace/brain/** non-empty.
- T3: pwsh ./pakks/HomePC/sample.ps1 -WhatIf on macOS (or zsh shim).
- T4: Run DeepRepoAudit.ps1 and compare dupe-group count.
