# Install OpenViking for OpenClaw (Official Local Mode)

[中文说明 / Chinese README](./README_zh.md)

This repo is a **beginner-friendly guide** for installing and wiring **OpenViking** into **OpenClaw** using the **official local mode**.

The goal is simple:

> help a new user go from “I want OpenClaw memory” to “OpenClaw is running with OpenViking locally” with the fewest surprises possible.

This repo is **not** meant to be a personal debug diary.
The project-specific pitfalls we hit are still useful, but they belong in the appendix and troubleshooting docs — not in the main install path.

---

## Who this guide is for

This guide is for people who want:

- OpenClaw to use OpenViking as its context / memory backend
- the **official `local` plugin mode** instead of a custom remote deployment
- a practical installation guide with clear steps
- a setup that is easy to verify after installation

If you just want the shortest answer:

1. install OpenClaw
2. install OpenViking
3. enable the OpenViking plugin in local mode
4. restart the OpenClaw gateway
5. verify the local service and plugin wiring

The rest of this README turns that into a step-by-step path.

---

## What this repo covers

Mainline path:

- **OpenClaw**
- **OpenViking**
- **official `local` mode** plugin wiring
- a **basic verification flow**
- a few important caveats collected into appendix / troubleshooting

This is a general-purpose setup guide, not a claim that every memory workflow is already perfect.

---

## Upstream references

You should keep the official docs nearby.

### OpenClaw

- Docs: <https://docs.openclaw.ai>
- Install: <https://docs.openclaw.ai/install>
- Installer: <https://docs.openclaw.ai/install/installer>
- macOS: <https://docs.openclaw.ai/platforms/macos>

### OpenViking

- GitHub: <https://github.com/volcengine/OpenViking>
- OpenClaw plugin install doc: <https://github.com/volcengine/OpenViking/blob/v0.3.3/examples/openclaw-plugin/INSTALL.md>
- OpenClaw plugin schema/example: <https://github.com/volcengine/OpenViking/blob/v0.3.3/examples/openclaw-plugin/openclaw.plugin.json>

This repo complements the official docs. It does not replace them.

---

## Recommended baseline

If you want the path that is easiest to reproduce, use this baseline:

- OpenClaw plugin mode: **`local`**
- OpenViking version: **`0.3.3`**
- Python: **`3.13`**
- OpenViking config path: **`~/.openviking/ov.conf`**
- OpenViking port: **`1933`**
- OpenViking log output: **`stderr`**
- OpenClaw gateway managed with official commands only

---

# Step-by-step install flow

## Step 1 — Install OpenClaw

If OpenClaw is not installed yet, start with the official docs:

- <https://docs.openclaw.ai/install>
- <https://docs.openclaw.ai/install/installer>

After installation, confirm the gateway is available:

```bash
openclaw gateway status
```

If OpenClaw itself is not healthy, stop here and fix that first.
Do not stack OpenViking on top of a broken OpenClaw install.

---

## Step 2 — Install OpenViking

Follow the upstream OpenViking installation flow and plugin references:

- <https://github.com/volcengine/OpenViking>
- <https://github.com/volcengine/OpenViking/blob/v0.3.3/examples/openclaw-plugin/INSTALL.md>

For a cleaner local setup, prefer:

- OpenViking `0.3.3`
- Python `3.13`

After installation, make sure you have:

- an OpenViking config file at `~/.openviking/ov.conf`
- a working Python environment that can actually run OpenViking

A minimal config usually looks like:

```json
{
  "server": {
    "port": 1933
  },
  "log": {
    "output": "stderr"
  }
}
```

If you enable API-key auth on the OpenViking side, keep reading carefully — the plugin side must also be configured for auth.

---

## Step 3 — Enable the OpenViking plugin in OpenClaw

Your `~/.openclaw/openclaw.json` should end up with the OpenViking plugin enabled in `local` mode.

Example shape:

```json
{
  "plugins": {
    "allow": ["openviking"],
    "entries": {
      "openviking": {
        "enabled": true,
        "config": {
          "mode": "local",
          "configPath": "~/.openviking/ov.conf",
          "port": 1933,
          "agentId": "main",
          "autoRecall": true,
          "autoCapture": true,
          "emitStandardDiagnostics": true,
          "logFindRequests": true,
          "bypassSessionPatterns": ["agent:*:cron:**"]
        }
      }
    },
    "slots": {
      "contextEngine": "openviking"
    }
  }
}
```

What matters most:

- `plugins.allow` includes `openviking`
- `plugins.entries.openviking.enabled = true`
- `mode = local`
- `configPath` points to your real `ov.conf`
- `port` is explicitly set
- `plugins.slots.contextEngine = openviking`

---

## Step 4 — Persist the correct Python runtime

This is one of the easiest ways to avoid pain.

Create:

- `~/.openclaw/openviking.env`

Example:

```bash
OPENVIKING_PYTHON="/path/to/your/python3.13"
```

If you already know your working OpenViking Python path, put it here.
This helps OpenClaw local mode launch the correct Python consistently.

**Do not** rely on hand-editing the generated LaunchAgent plist as your long-term fix.
Use `~/.openclaw/openviking.env` instead.

---

## Step 5 — If OpenViking uses API-key auth, configure the plugin too

If your `ov.conf` enables:

- `server.auth_mode = api_key`

then the OpenClaw plugin must also receive an API key through either:

- `plugins.entries.openviking.config.apiKey`
- or `OPENVIKING_API_KEY`

For example:

```bash
openclaw config set plugins.entries.openviking.config.apiKey your-api-key
```

**Important:**

> `ov.conf.root_api_key` is not automatically inherited by the OpenClaw plugin.

If you skip this step, the local service may still start and `/health` may still look fine, but real API routes can fail with `401 Missing API Key`.

---

## Step 6 — Restart the OpenClaw gateway

Use official gateway commands:

```bash
openclaw gateway install --force
openclaw gateway restart
```

Avoid building your own long-term service-management story unless you really need it.
The point here is a simple, upstream-aligned setup.

---

## Step 7 — Verify the installation

Start with the basics:

```bash
openclaw gateway status
lsof -nP -iTCP:1933 -sTCP:LISTEN
curl http://127.0.0.1:1933/health
```

You want to see:

- OpenClaw gateway is healthy
- OpenViking is listening on `1933`
- `/health` responds successfully

Then confirm the OpenViking plugin is really wired in:

- `plugins.slots.contextEngine = openviking`
- no obvious plugin-load errors in logs

If API-key auth is enabled, also confirm your real routes are not failing with `401`.

---

## Quick checklist

- [ ] OpenClaw is installed and healthy
- [ ] OpenViking is installed
- [ ] `~/.openviking/ov.conf` exists
- [ ] OpenClaw plugin mode is `local`
- [ ] `plugins.slots.contextEngine = openviking`
- [ ] `~/.openclaw/openviking.env` exists when Python needs to be pinned
- [ ] `OPENVIKING_PYTHON` points to the correct Python runtime
- [ ] OpenViking local port is listening
- [ ] `/health` returns OK
- [ ] if `auth_mode=api_key`, plugin-side `apiKey` or `OPENVIKING_API_KEY` is configured

---

## What to read next

### Core docs

- [docs/architecture.md](./docs/architecture.md)
- [docs/verification.md](./docs/verification.md)
- [docs/troubleshooting.md](./docs/troubleshooting.md)

### Appendix / deeper reading

Use these docs when the install path is not enough:

- `docs/verification.md` — what “working” actually means
- `docs/troubleshooting.md` — symptom-based debugging

That is where the tricky pitfalls belong.
They should support the install guide, not drown it.

---

## Bottom line

If you want a **new-user-friendly** way to install OpenViking for OpenClaw, the cleanest story is:

1. install OpenClaw
2. install OpenViking
3. enable the OpenViking plugin in `local` mode
4. persist the correct Python in `~/.openclaw/openviking.env`
5. if auth is enabled, configure the plugin-side API key too
6. restart the gateway
7. verify the local service and plugin wiring

That is the main story.
Everything else is appendix.
