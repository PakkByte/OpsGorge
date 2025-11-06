# Project Seed — AI_Workspace
- Goal: Build/maintain pakks monorepo (scripts + policies) with CI/PL/DoD.
- Environments: Win11 (home PC), macOS (MacBook).
- Repo: https://github.com/PakkByte/OpsGorge (branch protection on main).
- CI Check: "OpsGorge - Validate (Enforced) / Validate (C+ Gate)".

## Sources
- pakks/* — working packs
- .github/workflows/validate.yml — gates
- PL.md — fallback rubric & PL-Score

## Constraints
- No secrets in git; use .env (local) + .env.example (repo).
- >100MB → Git LFS or keep out.
