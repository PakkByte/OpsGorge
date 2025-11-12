Write-Host "=== HOME PC STACK VALIDATION ==="

Write-Host "`n[1] Checking Git branch and status..."
git remote -v
git branch
git status --short

Write-Host "`n[2] Checking Docker containers..."
if (-not (Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ Docker Desktop not running — skipping container checks."
    exit 0
}
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | Select-String "n8n|postgres"

Write-Host "`n[3] Testing n8n HTTP endpoint..."
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:5555" -UseBasicParsing -ErrorAction Stop
    Write-Host "HTTP $($resp.StatusCode) OK"
} catch {
    Write-Host "n8n not responding on port 5555."
}

Write-Host "`n[4] Checking Postgres volume binding..."
docker inspect postgres 2>$null | Select-String "automation_postgres_data"

Write-Host "`n[5] Checking docker-compose.yml volumes..."
Select-String -Path ".\docker-compose.yml" -Pattern "volumes:" -Context 0,3

Write-Host "`n[6] Checking environment variables..."
Select-String -Path ".\.env.shared", ".\.env.home.local" -Pattern "N8N_PORT|POSTGRES" -ErrorAction SilentlyContinue

Write-Host "`n[7] Checking Docker volume list..."
if (docker volume ls | Select-String "automation_postgres_data") {
    Write-Host "Volume exists."
} else {
    Write-Host "Volume missing."
}

Write-Host "`n[8] Final summary..."
$dockerHealthy = docker ps | Select-String "postgres"
$webHealthy = $false
try {
    $res = Invoke-WebRequest -Uri "http://localhost:5555" -UseBasicParsing -ErrorAction Stop
    if ($res.StatusCode -eq 200) { $webHealthy = $true }
} catch {}

if ($dockerHealthy -and $webHealthy) {
    Write-Host "✅ Home PC stack is healthy."
} else {
    Write-Host "❌ Something is wrong. Check logs."
}
