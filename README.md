# OpenClaw + OpenViking Official Local Guide

[中文说明 / Chinese README](./README_zh.md)

This repo documents a **working, verified, and acceptance-tested baseline** for running **OpenClaw + OpenViking in official local mode**.

It is not a generic “AI memory solved forever” landing page.
It is a practical migration and verification guide based on real debugging, real failures, and a final setup that was actually driven to runtime acceptance.

---

## Current status

**Status: fixed and minimally accepted.**

The official local path is now validated end-to-end at the minimum useful runtime layer:

- local OpenViking service starts under the OpenClaw plugin
- runtime authentication is working
- recall/search requests succeed
- capture/session message writes succeed
- commit/extraction requests succeed
- post-restart logs show no new `401`, `UNAUTHENTICATED`, or `Missing API Key`

That is a much stronger statement than “health endpoint is green.”

---

## What this repo now focuses on

The main path is:

- **OpenClaw** uses the **official `local` mode** OpenViking plugin
- **OpenViking** is pinned to **`0.3.3`**
- **Python** is pinned to **`3.13`**
- Gateway is managed only with official commands:
  - `openclaw gateway install --force`
  - `openclaw gateway start`
  - `openclaw gateway restart`

This repo no longer treats the old `remote`-mode wiring as the default story.

---

## What we actually validated

The stable baseline we verified is:

- OpenClaw plugin mode: **`local`**
- OpenViking version: **`0.3.3`**
- Python interpreter: **`3.13`**
- OpenViking port: **`1933`**
- OpenViking config path: **`~/.openviking/ov.conf`**
- OpenViking log output: **`stderr`**
- Persistent Python override file: **`~/.openclaw/openviking.env`**
- Runtime auth path: **working**
- Minimum business-path acceptance: **passed**

Specifically, after the final fix, these real API routes were validated successfully:

- `POST /api/v1/search/find` → `200`
- `POST /api/v1/sessions/<id>/messages` → `200`
- `POST /api/v1/sessions/<id>/commit` → `200`

And extraction completion was observed in logs after commit acceptance.

---

## The two critical fixes this repo now documents

### Fix 1 — Persist the correct Python

Do **not** hand-edit the LaunchAgent plist as a long-term fix.

Use:

- `~/.openclaw/openviking.env`

Example:

```bash
OPENVIKING_PYTHON="/Users/sean/venvs/openviking-py313-v033-py313/bin/python"
```

This is the key persistent fix for machines where local mode would otherwise fall back to the wrong Python.

### Fix 2 — Do not forget plugin-side API auth

If your OpenViking server uses:

- `server.auth_mode = api_key`

then the OpenClaw plugin must also be given an API key through either:

- `plugins.entries.openviking.config.apiKey`
- or `OPENVIKING_API_KEY`

**Important:**

> `ov.conf.root_api_key` is not inherited automatically by the OpenClaw plugin.

This was the second major trap in real validation.
The local service could be fully up and `/health` could be green while real plugin requests still failed with `401 Missing API Key`.

---

## Required OpenViking config

Your `~/.openviking/ov.conf` should at least satisfy:

```json
{
  "server": {
    "port": 1933,
    "auth_mode": "api_key"
  },
  "log": {
    "output": "stderr"
  }
}
```

If auth is enabled, make sure the plugin side is configured accordingly.

### Why `stderr` matters

In our validation, keeping:

- `log.output = stdout`

could make local child-process supervision unstable.

So in this repo, `stderr` is treated as part of the verified baseline, not as a cosmetic preference.

---

## Recommended OpenClaw plugin config shape

Your `~/.openclaw/openclaw.json` should contain the relevant shape:

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
          "apiKey": "<same key expected by OpenViking server>",
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

- `mode = local`
- `configPath = ~/.openviking/ov.conf`
- `port = 1933`
- `apiKey` is present if server auth is enabled
- `plugins.allow` includes `openviking`
- `plugins.slots.contextEngine = openviking`

---

## Migration steps

### Step 1 — Confirm OpenClaw plugin config is local

Confirm:

- `mode = local`
- correct `configPath`
- explicit `port`
- `contextEngine = openviking`

### Step 2 — Fix OpenViking config

Make sure `~/.openviking/ov.conf` uses:

- `server.port = 1933`
- `log.output = stderr`

If server auth is enabled, note that plugin auth must be configured separately.

### Step 3 — Persist the correct Python

Create or update:

- `~/.openclaw/openviking.env`

Example:

```bash
OPENVIKING_PYTHON="/Users/sean/venvs/openviking-py313-v033-py313/bin/python"
```

### Step 4 — Configure plugin-side API key when auth is enabled

Use either:

```bash
openclaw config set plugins.entries.openviking.config.apiKey your-api-key
```

or provide:

```bash
OPENVIKING_API_KEY="your-api-key"
```

Again: the plugin does **not** auto-import `root_api_key` from `ov.conf`.

### Step 5 — Remove the old separate OpenViking service from the main path

If you previously ran OpenViking as a separate launchd service, stop using that as the main production path before switching.

The point of the final state is:

- OpenClaw gateway runs normally
- the plugin starts OpenViking in official local mode
- you are no longer depending on the old standalone service as the main path

### Step 6 — Use only official gateway service commands

Run:

```bash
openclaw gateway install --force
openclaw gateway restart
```

Do not replace this step with manual long-term plist editing.

### Step 7 — Verify startup and runtime auth

Run:

```bash
openclaw gateway status
lsof -nP -iTCP:1933 -sTCP:LISTEN
curl http://127.0.0.1:1933/health
```

Then check logs and confirm real API routes are not returning `401`.

Expected result:

- gateway is running
- port `1933` is listening
- `/health` returns healthy
- runtime routes no longer show `Missing API Key`

---

## Quick acceptance checklist

- [ ] `openclaw gateway status` is healthy
- [ ] `1933` is listening
- [ ] `curl http://127.0.0.1:1933/health` returns OK
- [ ] OpenViking version is `0.3.3`
- [ ] `~/.openclaw/openviking.env` exists
- [ ] `OPENVIKING_PYTHON` points to Python 3.13
- [ ] `~/.openviking/ov.conf` uses `log.output=stderr`
- [ ] if `auth_mode=api_key`, plugin `apiKey` or `OPENVIKING_API_KEY` is configured
- [ ] `POST /api/v1/search/find` succeeds
- [ ] `POST /api/v1/sessions/<id>/messages` succeeds
- [ ] `POST /api/v1/sessions/<id>/commit` succeeds

---

## What this repo now proves well

With the baseline above, this repo can credibly help you prove:

- OpenClaw is configured to use OpenViking in official local mode
- the plugin is active as the context engine
- the local OpenViking process can be supervised stably
- the correct Python runtime is being used
- runtime authentication is working
- the minimum useful business path has passed acceptance

---

## What this repo still does not magically prove

It does **not** automatically prove:

- long-term extraction quality in every workload
- cross-session memory quality
- ranking quality
- whether retrieved memories are meaningful rather than junk
- whether your workload-specific recall behavior is already production-perfect

So the honest statement is:

> Wiring, local runtime, and minimum runtime auth/business-path acceptance are working, but memory quality and long-term extraction still need their own validation.

That sentence is less sexy than marketing, but at least it is not fake.

---

## Related docs in this repo

- [docs/architecture.md](./docs/architecture.md)
- [docs/verification.md](./docs/verification.md)
- [docs/troubleshooting.md](./docs/troubleshooting.md)
- [CHANGELOG.md](./CHANGELOG.md)
- [ROADMAP.md](./ROADMAP.md)

---

## Bottom line

If you want a stable **official local** setup, the minimum reliable baseline is:

- OpenViking `0.3.3`
- Python `3.13`
- `OPENVIKING_PYTHON` persisted in `~/.openclaw/openviking.env`
- `log.output = stderr`
- plugin mode `local`
- explicit local `port`
- plugin-side `apiKey` when server auth is enabled

That combination is not hypothetical anymore.
It has now been driven through real runtime verification and minimum acceptance.
