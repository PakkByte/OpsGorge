# StateOfWorld.md
Readiness: 70% (C+ guardrails live; DoD in bootstrap)
Top 5 Risks:
1) DoD still soft (CI_BOOTSTRAP=1) — not yet blocking merges.
2) Secrets false positives — keep allowlist tight.
3) YAML/editor drift — enforce .editorconfig/.gitattributes.
4) Missing restore-map artifacts in real runs — add when wiring audits.
5) Branch rule drift — re-check required checks after renaming jobs.
Wins:
- Public repo with Classic protection fully active.
- validate job stable on Windows runners using pwsh.
- CODEOWNERS in place; PR template available.
Last Runs:
- validate: green on smoke branches.
- DoD: bootstrap soft-pass (warnings only).
Next Changes:
- Enforce DoD (CI_BOOTSTRAP=0 or -Strict).
- Add Notion + n8n (read-only pulses).
- Add JSON Schema & sample-tree test harness.
