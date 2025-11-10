Set-StrictMode -Version Latest
Set-Location "$PSScriptRoot\automation"
Copy-Item .\.env.pc .\.env -Force
docker compose -f docker-compose.yml -f docker-compose.pc.yml up -d
