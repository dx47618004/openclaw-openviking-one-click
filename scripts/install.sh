#!/usr/bin/env bash
set -euo pipefail

OPENVIKING_URL="http://127.0.0.1:1933"
OPENVIKING_API_KEY="${OPENVIKING_API_KEY:-}"
OPENVIKING_AGENT_ID="${OPENVIKING_AGENT_ID:-default}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
DRY_RUN=0

usage() {
  cat <<'EOF'
OpenClaw + OpenViking bootstrap

Usage:
  ./scripts/install.sh --api-key <key> [options]

Options:
  --api-key <key>           OpenViking API key (or set OPENVIKING_API_KEY)
  --openviking-url <url>    Default: http://127.0.0.1:1933
  --agent-id <id>           Default: default
  --config <path>           Default: ~/.openclaw/openclaw.json
  --dry-run                 Print what would change, do not write
  -h, --help                Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key)
      OPENVIKING_API_KEY="$2"; shift 2 ;;
    --openviking-url)
      OPENVIKING_URL="$2"; shift 2 ;;
    --agent-id)
      OPENVIKING_AGENT_ID="$2"; shift 2 ;;
    --config)
      OPENCLAW_CONFIG_PATH="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1 ;;
  esac
done

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw not found in PATH" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "node not found in PATH" >&2
  exit 1
fi

if [[ -z "$OPENVIKING_API_KEY" ]]; then
  echo "Missing OpenViking API key. Pass --api-key or set OPENVIKING_API_KEY." >&2
  exit 1
fi

mkdir -p "$(dirname "$OPENCLAW_CONFIG_PATH")"
if [[ ! -f "$OPENCLAW_CONFIG_PATH" ]]; then
  echo '{"plugins":{"entries":{},"allow":[],"slots":{}},"agents":{"defaults":{}},"channels":{},"tools":{}}' > "$OPENCLAW_CONFIG_PATH"
fi

export OPENCLAW_CONFIG_PATH OPENVIKING_URL OPENVIKING_API_KEY OPENVIKING_AGENT_ID DRY_RUN
node <<'EOF'
const fs = require('fs');
const path = process.env.OPENCLAW_CONFIG_PATH;
const url = process.env.OPENVIKING_URL;
const apiKey = process.env.OPENVIKING_API_KEY;
const agentId = process.env.OPENVIKING_AGENT_ID;
const dryRun = process.env.DRY_RUN === '1';

const raw = fs.readFileSync(path, 'utf8');
const cfg = JSON.parse(raw || '{}');

cfg.plugins ||= {};
cfg.plugins.entries ||= {};
cfg.plugins.allow ||= [];
cfg.plugins.slots ||= {};
cfg.agents ||= {};
cfg.agents.defaults ||= {};

cfg.plugins.entries.openviking = {
  enabled: true,
  config: {
    mode: 'remote',
    baseUrl: url,
    apiKey,
    agentId,
    autoRecall: true,
    autoCapture: true,
    emitStandardDiagnostics: true,
    logFindRequests: true,
    timeoutMs: 5000,
  },
};

if (!cfg.plugins.allow.includes('openviking')) {
  cfg.plugins.allow.push('openviking');
}

cfg.plugins.slots.contextEngine = 'openviking';

if (!cfg.agents.defaults.model) {
  cfg.agents.defaults.model = { primary: 'openai/gpt-4o-mini' };
}

const pretty = JSON.stringify(cfg, null, 2) + '\n';
if (dryRun) {
  process.stdout.write(pretty);
} else {
  fs.writeFileSync(path, pretty);
  console.log(`Patched ${path}`);
}
EOF

if [[ "$DRY_RUN" -eq 1 ]]; then
  exit 0
fi

echo "Restarting OpenClaw gateway..."
openclaw gateway restart >/dev/null 2>&1 || true
sleep 2

echo
printf 'Config: %s\n' "$OPENCLAW_CONFIG_PATH"
printf 'OpenViking: %s\n' "$OPENVIKING_URL"
printf 'Agent ID: %s\n' "$OPENVIKING_AGENT_ID"
echo
openclaw status || true
