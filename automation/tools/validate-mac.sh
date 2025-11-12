#!/bin/bash
echo "=== MAC STACK VALIDATION ==="

echo "[1] Checking Git branch and status..."
git remote -v
git branch
git status --short

echo "[2] Checking Docker containers..."
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" | grep -E "n8n|postgres"

echo "[3] Testing n8n HTTP endpoint..."
curl -s -I http://localhost:5554 | head -n 1 || echo "n8n not responding on port 5554."

echo "[4] Checking Postgres volume binding..."
docker inspect postgres 2>/dev/null | grep -A3 automation_postgres_data || echo "Volume not found."

echo "[5] Checking docker-compose.mac.yml volumes..."
grep -A3 "volumes:" docker-compose.mac.yml || echo "No volume section found."

echo "[6] Checking environment variables..."
grep -E "N8N_PORT|POSTGRES" .env.shared .env.mac.local 2>/dev/null || echo "Missing expected vars."

echo "[7] Checking Docker volume list..."
docker volume ls | grep automation_postgres_data && echo "Volume exists." || echo "Volume missing."

echo "[8] Final summary..."
if curl -s -I http://localhost:5554 | grep -q "200 OK" && docker ps | grep -q postgres; then
  echo "✅ Mac stack is healthy."
else
  echo "❌ Something is wrong. Check logs."
fi
