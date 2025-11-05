# OpsGorge

# Repository

<!-- DOD_V2_START -->
## Definition of Done (v2)

> A change is **done** when it meets every **Core** item and documents any **Quality** or **Excellence** notes.

### 🧱 Core (must pass)
1. PR to protected `main` with **signed commit**.  
   *Because provenance matters and prevents tampering.*
2. CI (`validate.yml`) **passes schema + self-tests**.  
   *Because correctness beats speed.*
3. **Security least-privilege confirmed** (no secrets committed).  
   *Because permissions should only ever decrease, not grow.*
4. **Docs updated** (README/runbook).  
   *Because future-you is another developer.*
5. **Logs + restore-map generated & archived**.  
   *Because rollback is risk insurance.*
6. **Issue/Changelog linked** in PR body.  
   *Because traceability prevents ghost changes.*

### ⚙️ Quality (recommended)
1. Inline comments explain **intent**, not mechanics.  
2. Names follow conventions; logs **human-readable** and **timestamped**.  
3. Minimal diff surface; avoids unrelated changes.

### ⭐ Excellence (stretch)
1. Errors are **actionable** (message + next step).  
2. Runbook includes **rollback** step with example.  
3. Validated on **Windows + macOS** where applicable.

<!-- DOD_V2_END -->

