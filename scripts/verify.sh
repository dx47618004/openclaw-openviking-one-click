#!/usr/bin/env bash
set -euo pipefail

export OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"

echo '== OpenClaw status =='
openclaw status || true

echo
echo '== openviking config =='
node <<'EOF'
const fs = require('fs');
const p = process.env.OPENCLAW_CONFIG_PATH;
const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
console.log(JSON.stringify(cfg.plugins?.entries?.openviking || null, null, 2));
console.log(JSON.stringify(cfg.plugins?.slots || null, null, 2));
EOF
