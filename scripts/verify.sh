#!/usr/bin/env bash
set -euo pipefail

export OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
OPENVIKING_API_KEY="${OPENVIKING_API_KEY:-}"

if ! command -v openclaw >/dev/null 2>&1; then
  echo '[verify][error] openclaw not found in PATH' >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo '[verify][error] node not found in PATH' >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo '[verify][error] curl not found in PATH' >&2
  exit 1
fi

echo '== OpenClaw status =='
openclaw status || true

echo
echo '== openviking config =='
CONFIG_JSON="$(node <<'EOF'
const fs = require('fs');
const p = process.env.OPENCLAW_CONFIG_PATH;
const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
const payload = {
  openviking: cfg.plugins?.entries?.openviking || null,
  slots: cfg.plugins?.slots || null,
};
process.stdout.write(JSON.stringify(payload, null, 2));
EOF
)"
printf '%s\n' "$CONFIG_JSON"

BASE_URL="$(node <<'EOF'
const fs = require('fs');
const p = process.env.OPENCLAW_CONFIG_PATH;
const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
process.stdout.write(cfg.plugins?.entries?.openviking?.config?.baseUrl || '');
EOF
)"

if [[ -z "$OPENVIKING_API_KEY" ]]; then
  OPENVIKING_API_KEY="$(node <<'EOF'
const fs = require('fs');
const p = process.env.OPENCLAW_CONFIG_PATH;
const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
process.stdout.write(cfg.plugins?.entries?.openviking?.config?.apiKey || '');
EOF
)"
fi

CURL_HEADERS=()
if [[ -n "$OPENVIKING_API_KEY" ]]; then
  CURL_HEADERS=(
    -H "X-API-Key: $OPENVIKING_API_KEY"
    -H "Authorization: Bearer $OPENVIKING_API_KEY"
  )
fi

if [[ -z "$BASE_URL" ]]; then
  echo
  echo '[verify][warn] No OpenViking baseUrl found in config.'
  exit 0
fi

echo
echo "== OpenViking health check =="
if curl -fsS --max-time 5 "${CURL_HEADERS[@]}" "$BASE_URL/health"; then
  echo
  echo '[verify][ok] /health responded'
else
  echo
  echo '[verify][warn] /health did not respond cleanly'
fi

echo
echo "== OpenViking ping check =="
if curl -fsS --max-time 5 "${CURL_HEADERS[@]}" "$BASE_URL/ping"; then
  echo
  echo '[verify][ok] /ping responded'
else
  echo
  echo '[verify][warn] /ping did not respond cleanly'
fi

echo
echo '== Interpretation =='
cat <<'EOF'
If config looks right and health/ping respond, you likely proved:
- OpenClaw is wired to OpenViking
- contextEngine is configured
- the endpoint is reachable

You did NOT automatically prove:
- long-term extraction quality
- memory usefulness across time
- rerank / retention quality

Read docs/verification.md for the non-bullshit version.
EOF
