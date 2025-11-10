#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/automation"
cp .env.mac .env
docker compose -f docker-compose.yml -f docker-compose.mac.yml up -d
