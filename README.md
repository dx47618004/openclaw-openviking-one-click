# OpenClaw + OpenViking One-Click Setup

A practical, reproducible starter for wiring **OpenClaw** to **OpenViking** in remote mode, based on a real successful setup on macOS.

This repo is not pretending to be the official way. It is the **battle-tested shortcut**: the minimum useful pieces, the actual config shape, the common pitfall, and a small bootstrap script so people can get to a working state faster.

## What this gives you

- a small `install.sh` bootstrap that patches `~/.openclaw/openclaw.json`
- OpenViking registered as the OpenClaw context engine
- `autoRecall` + `autoCapture` turned on
- a simple verification script
- a write-up of what actually worked and what was misleading

## Who this is for

Use this if you already have:

- OpenClaw installed and running locally
- an OpenViking service reachable over HTTP
- an OpenViking API key

If you want a magical full installer for both products from scratch, this repo is **not there yet**. Right now it focuses on the integration layer that people actually get stuck on.

## Quick start

```bash
git clone https://github.com/dx47618004/openclaw-openviking-one-click.git
cd openclaw-openviking-one-click
chmod +x scripts/install.sh scripts/verify.sh
./scripts/install.sh --api-key YOUR_OPENVIKING_API_KEY
./scripts/verify.sh
```

### Optional flags

```bash
./scripts/install.sh \
  --api-key YOUR_OPENVIKING_API_KEY \
  --openviking-url http://127.0.0.1:1933 \
  --agent-id default \
  --config ~/.openclaw/openclaw.json
```

## What the script changes

It patches your OpenClaw config with the equivalent of:

```json
{
  "plugins": {
    "entries": {
      "openviking": {
        "enabled": true,
        "config": {
          "mode": "remote",
          "baseUrl": "http://127.0.0.1:1933",
          "apiKey": "...",
          "agentId": "default",
          "autoRecall": true,
          "autoCapture": true,
          "emitStandardDiagnostics": true,
          "logFindRequests": true,
          "timeoutMs": 5000
        }
      }
    },
    "allow": ["openviking"],
    "slots": {
      "contextEngine": "openviking"
    }
  }
}
```

It also restarts the OpenClaw gateway after writing the config.

## Real-world notes from the successful setup

This guide is based on a real working run where the plugin ended up in this shape:

- `plugins.entries.openviking.enabled = true`
- `plugins.entries.openviking.config.mode = remote`
- `plugins.entries.openviking.config.baseUrl = http://127.0.0.1:1933`
- `plugins.entries.openviking.config.autoRecall = true`
- `plugins.entries.openviking.config.autoCapture = true`
- `plugins.slots.contextEngine = openviking`

And `openclaw status` showed the plugin as loaded and registered as context engine.

## What worked

### 1) Remote mode was the clean path

Using OpenViking in **remote mode** with a local HTTP endpoint was much simpler than trying to reason about hidden internal state. Once the endpoint was reachable and the plugin config was correct, OpenClaw could:

- auto-recall context before prompt build
- auto-capture after turns
- register OpenViking as the context engine

### 2) Human-readable memory files still matter

Even with OpenViking attached, the practical continuity layer still benefits from human-readable files like:

- `MEMORY.md`
- `memory/YYYY-MM-DD.md`

OpenViking is great as a backend/context system. But for day-to-day continuity, explicit text files are still the safest source of truth.

### 3) `openclaw status` is your friend

If you're diagnosing the integration, start with:

```bash
openclaw status
```

In the successful setup, that surfaced the important bits immediately:

- gateway healthy
- plugin loaded
- context engine registered
- session and memory stats visible

## What was confusing

### Session capture working is **not** the same as long-term memory extraction working

This is the trap.

You can get to a state where:

- session capture is working
- recall hooks are wired
- the plugin is definitely loaded

...and still **not** see the long-term extracted memories you expected.

That does **not** automatically mean the integration failed. It may mean memory extraction/commit still needs to be triggered, verified, or separately debugged.

In the real run behind this repo:

- OpenClaw ↔ OpenViking remote integration was functioning
- session capture/recall path looked good
- but long-term memory generation still needed explicit follow-up validation

So don’t lie to yourself with a fake green check. Separate these questions:

1. Is the plugin wired correctly?
2. Is recall happening?
3. Is capture happening?
4. Is long-term extraction actually producing memories?

Those are related, but not identical.

## Verify the integration

### Fast check

```bash
./scripts/verify.sh
```

### Manual checks

```bash
openclaw status
```

You want to see evidence that:

- OpenClaw is healthy
- OpenViking plugin is enabled
- `contextEngine` is `openviking`

## Troubleshooting

### OpenClaw loads forever or behaves weird after enabling OpenViking

Check the config carefully instead of reinstalling blindly.

Useful things to verify:

- `plugins.entries.openviking.enabled` is `true`
- `plugins.entries.openviking.config.baseUrl` points to a live OpenViking service
- `plugins.allow` includes `openviking`
- `plugins.slots.contextEngine` is `openviking`

### OpenViking is running but nothing is being recalled

Look at:

- `autoRecall`
- plugin load state in `openclaw status`
- logs / routing diagnostics

### You expected memories/entities/events/preferences, but they stay empty

That may be an extraction/commit issue rather than a transport/integration issue.

Do not blur those together.

## Suggested repo structure for future improvement

This repo is intentionally small. The obvious next upgrades would be:

- Linux support
- Docker / Compose examples
- health checks against the OpenViking HTTP endpoint
- a dedicated memory extraction validation script
- CI smoke tests against a sample config

## Why this repo exists

Because a lot of integration write-ups are fluff.

People say “it works” when they really mean “the process stopped erroring.” That’s not the same thing.

This repo tries to be more honest:

- here is the config shape
- here is the tiny script
- here is what was actually proven
- here is what was still unresolved

## Attribution / scope

This is an unofficial community integration note and helper script. Use it as a practical starting point, not as a substitute for the upstream OpenClaw/OpenViking docs.

## Star bait, but honest

If this saved you an hour of digging through config and false positives, give it a star.

That’s the whole pitch. No mystical productivity revolution. It just helps you get the damn thing wired up.
