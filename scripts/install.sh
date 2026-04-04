#!/usr/bin/env bash
set -euo pipefail

OPENVIKING_URL="${OPENVIKING_URL:-http://127.0.0.1:1933}"
OPENVIKING_API_KEY="${OPENVIKING_API_KEY:-}"
OPENVIKING_AGENT_ID="${OPENVIKING_AGENT_ID:-default}"
OPENCLAW_CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
DRY_RUN=0
PRINT_NEXT_STEPS=1
ASSUME_OPENVIKING_READY=0

usage() {
  cat <<'EOF'
OpenClaw + OpenViking bootstrap

Purpose:
  Wire an existing OpenViking service into OpenClaw as the context engine.

Important:
  This script is for the "OpenViking already exists" path.
  If you do NOT have OpenViking installed yet, install OpenViking first,
  confirm its HTTP endpoint is alive, then come back and run this script.

Usage:
  ./scripts/install.sh --api-key <key> [options]

Options:
  --api-key <key>           OpenViking API key (or set OPENVIKING_API_KEY)
  --openviking-url <url>    Default: http://127.0.0.1:1933
  --agent-id <id>           Default: default
  --config <path>           Default: ~/.openclaw/openclaw.json
  --assume-openviking-ready Skip the preflight warning for users who already
                            know the OpenViking service is alive
  --dry-run                 Print what would change, do not write
  -h, --help                Show this help
EOF
}

log() {
  printf '[install] %s\n' "$*"
}

warn() {
  printf '[install][warn] %s\n' "$*" >&2
}

die() {
  printf '[install][error] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd not found in PATH"
}

print_path_guidance() {
  cat <<EOF
Choose your path:

  Path A — You already have OpenViking running
    Good. This script can wire it into OpenClaw.

  Path B — You do NOT have OpenViking running yet
    Stop here. Install OpenViking first, then come back.

Upstream references:
  - OpenClaw install docs: https://docs.openclaw.ai/install
  - OpenClaw installer docs: https://docs.openclaw.ai/install/installer
  - OpenViking repo: https://github.com/volcengine/OpenViking
EOF
}

check_openviking_health() {
  local url="$1"
  local headers=()
  if [[ -n "$OPENVIKING_API_KEY" ]]; then
    headers=(
      -H "X-API-Key: $OPENVIKING_API_KEY"
      -H "Authorization: Bearer $OPENVIKING_API_KEY"
    )
  fi

  if curl -fsS --max-time 5 "${headers[@]}" "$url/health" >/dev/null 2>&1; then
    return 0
  fi
  return 1
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
    --assume-openviking-ready)
      ASSUME_OPENVIKING_READY=1; shift ;;
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

require_cmd openclaw
require_cmd node
require_cmd curl

if [[ -z "$OPENVIKING_API_KEY" ]]; then
  die "Missing OpenViking API key. Pass --api-key or set OPENVIKING_API_KEY."
fi

log "OpenClaw + OpenViking wiring bootstrap"
print_path_guidance
printf '\n'

if [[ "$ASSUME_OPENVIKING_READY" -eq 0 ]]; then
  log "Preflight: checking whether OpenViking looks alive at $OPENVIKING_URL"
  if check_openviking_health "$OPENVIKING_URL"; then
    log "OpenViking health check passed"
  else
    warn "OpenViking health check did not pass at $OPENVIKING_URL/health"
    cat <<EOF >&2

This usually means one of these:
  - OpenViking is not installed yet
  - OpenViking is installed but not running
  - the URL is wrong
  - auth/network is wrong

If you do NOT have OpenViking ready yet, stop now and install it first.
If you already know the service is fine and just don't expose /health the same way,
rerun with:

  ./scripts/install.sh --api-key YOUR_KEY --openviking-url $OPENVIKING_URL --assume-openviking-ready
EOF
    exit 1
  fi
fi

mkdir -p "$(dirname "$OPENCLAW_CONFIG_PATH")"
if [[ ! -f "$OPENCLAW_CONFIG_PATH" ]]; then
  log "Config file does not exist yet, creating a minimal OpenClaw config"
  echo '{"plugins":{"entries":{},"allow":[],"slots":{}},"agents":{"defaults":{}},"channels":{},"tools":{}}' > "$OPENCLAW_CONFIG_PATH"
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_PATH="${OPENCLAW_CONFIG_PATH}.bak-${TIMESTAMP}"
cp "$OPENCLAW_CONFIG_PATH" "$BACKUP_PATH"
log "Backup created: $BACKUP_PATH"

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
  log "Dry run only. No config written."
  log "Backup was still created at: $BACKUP_PATH"
  exit 0
fi

log "Restarting OpenClaw gateway..."
openclaw gateway restart >/dev/null 2>&1 || warn "gateway restart command returned non-zero"
sleep 2

echo
printf 'Config: %s\n' "$OPENCLAW_CONFIG_PATH"
printf 'Backup: %s\n' "$BACKUP_PATH"
printf 'OpenViking: %s\n' "$OPENVIKING_URL"
printf 'Agent ID: %s\n' "$OPENVIKING_AGENT_ID"
echo

log "Current OpenClaw status:"
openclaw status || true

echo
cat <<'EOF'
Next steps:
  1. Run ./scripts/verify.sh
  2. Read docs/verification.md
  3. Test with a unique phrase, then confirm recall
  4. Do not pretend long-term extraction is fully proven unless you actually checked it
EOF
