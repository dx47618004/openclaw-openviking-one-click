# OpenClaw + OpenViking Verification Guide

This guide exists because people keep mixing up four different milestones:

1. **the plugin is wired correctly**
2. **the local OpenViking service actually starts**
3. **runtime requests are authenticated correctly**
4. **session capture / recall / extraction are working**

Those are related, but they are **not** the same thing.

---

## Verification Ladder

Think of verification in layers.

### Layer 1 — Wiring is correct

At this layer, you are only proving that OpenClaw is configured to use OpenViking.

You want to confirm:

- the `openviking` plugin exists and is enabled
- `plugins.allow` includes `openviking`
- `plugins.slots.contextEngine = openviking`
- `mode = local`
- `configPath` points to the real `~/.openviking/ov.conf`
- `port` is explicitly set
- `autoRecall = true`
- `autoCapture = true`

This is the minimum “the cable is plugged in” layer.

### Layer 2 — Local service actually starts

At this layer, you are proving the plugin can launch OpenViking in official local mode.

You want evidence that:

- `127.0.0.1:<port>` is listening
- `/health` responds
- the child process is stable after gateway restart
- OpenViking is using the intended Python runtime

This is the “the engine is on” layer.

### Layer 3 — Runtime requests are authenticated

At this layer, you are proving that OpenClaw is not just talking to `/health`, but can also use real API routes.

You want evidence that:

- `/api/v1/sessions/.../context` is not returning `401`
- `/api/v1/search/find` is not returning `401`
- `/api/v1/sessions/.../messages` is not returning `401`
- `/api/v1/sessions/.../commit` is not returning `401`

This matters because `/health` can be green while the real integration is still dead.

### Layer 4 — Capture / recall / extraction are alive

At this layer, you are proving the integration is doing something useful during usage.

You want evidence that:

- conversation/session data is being captured
- recall hooks are active during later turns
- session writes succeed
- commit/extraction paths succeed
- later turns can retrieve useful context

This is the “not just alive, actually helpful” layer.

---

## Quick Verification Checklist

Run these in order:

```bash
openclaw gateway status
lsof -nP -iTCP:1933 -sTCP:LISTEN
curl http://127.0.0.1:1933/health
```

Then inspect the relevant config and logs.

A decent result should show most or all of the following:

- OpenClaw status prints without obvious failure
- `openviking` plugin config is present
- `contextEngine` is `openviking`
- OpenViking local port is listening
- OpenViking health endpoint responds
- recall/capture flags are on in config
- no `401 Missing API Key` errors in runtime logs

If you only have the first five bullets, then congratulations: **local startup is probably correct**.

Do **not** oversell that as “runtime memory fully working.”

---

## Recommended Manual Test Flow

### Test A — Config shape

Check the relevant OpenClaw config block.

What you want:

- no broken JSON
- `mode = local`
- correct `configPath`
- explicit `port`
- `contextEngine = openviking`
- `autoRecall = true`
- `autoCapture = true`

If your OpenViking server config uses:

- `server.auth_mode = api_key`

then you also need:

- `plugins.entries.openviking.config.apiKey`

Local mode does **not** magically remove auth requirements.

### Test B — Local service startup

Check:

```bash
lsof -nP -iTCP:1933 -sTCP:LISTEN
curl http://127.0.0.1:1933/health
```

What you want:

- the port is listening
- `/health` returns cleanly

This proves startup, not full runtime correctness.

### Test C — Authentication path

Now inspect the logs for real API calls.

Good signs:

- no `401`
- no `Missing API Key`
- no `UNAUTHENTICATED`

Bad signs:

- `/health` is `200`
- but `/api/v1/search/find` returns `401`
- or `/api/v1/sessions/.../context` returns `401`
- or session writes / commit return `401`

That means startup succeeded, but the plugin client is still missing auth.

### Test D — Session capture and recall

Have a short conversation with OpenClaw after enabling the plugin.

Example pattern:

1. send a message with a unique phrase
2. continue for 1-2 more turns
3. ask for the phrase back later
4. inspect whether logs show successful search/session writes instead of 401s

Good unique phrase example:

> `verification phrase: silver-cactus-2026`

Why unique? Because otherwise you end up searching generic garbage and then wondering why nothing is obvious.

### Test E — Long-term extraction

You still need to confirm things like:

- does OpenViking show extracted memories, not just sessions?
- does extraction run automatically or require explicit commit behavior?
- are memories retrievable later by semantic search?
- are the extracted items useful, clean, and attributable?

If this step is unclear, say so honestly.

A correct statement is:

> “The OpenClaw ↔ OpenViking local wiring is working, but long-term extraction still needs separate validation.”

That sentence is boring, but at least it is not bullshit.

---

## What a Green `/health` Does and Does Not Prove

A green `/health` proves:

- OpenViking is up
- the chosen port is reachable
- local spawn is probably working

A green `/health` does **not** prove:

- the plugin client has the right API key
- session reads work
- search works
- session writes work
- commit/extraction works

If the service runs with `auth_mode=api_key`, then runtime requests can still fail with `401` even while `/health` is healthy.

---

## Failure Patterns

### 1. `openclaw gateway status` is weird or broken

That usually means one of these:

- OpenClaw itself is not healthy yet
- config JSON is broken
- gateway restart did not succeed
- the plugin config is malformed

Fix that before doing anything clever.

### 2. Local port is not listening

Usually:

- wrong Python runtime
- wrong `configPath`
- wrong `port`
- OpenViking child process crashed immediately
- `log.output=stdout` is destabilizing local spawn on your machine

### 3. `/health` is green but runtime still feels dead

Usually:

- the plugin client is missing `apiKey`
- OpenViking server is running with `auth_mode=api_key`
- session/context/search/commit routes are all returning `401`

This is a real integration failure, not a cosmetic warning.

### 4. Config looks correct but recall still looks dead

Possible causes:

- runtime auth is still failing
- session capture works partially but retrieval path is failing
- your test was too vague to tell whether recall happened

Use a unique phrase. Don’t test memory with mush.

### 5. Sessions exist but durable memory is poor or empty

That is often **not** a transport problem.

It may be:

- extraction not triggered yet
- extraction pipeline not configured the way you think
- memory thresholds too conservative
- server-side processing lag
- retrieval quality issue rather than storage failure

---

## Honest Success Statements You Can Use

### Conservative success statement

> OpenClaw is successfully wired to OpenViking in local mode, with `openviking` set as the context engine and recall/capture enabled.

### Stronger success statement

> OpenClaw is successfully launching OpenViking locally, runtime requests are authenticated, session capture is happening, and recall behavior appears to be working.

### Statement that still needs separate proof

> Long-term memory extraction is fully validated and production-ready.

Do not say that unless you actually checked it.

---

## Suggested Evidence for Public Writeups

If you want this repo to look credible rather than hand-wavey, show evidence like:

- sanitized `openclaw gateway status` output
- `lsof` output for the local OpenViking port
- `/health` output
- config snippet showing `mode = local` and `contextEngine = openviking`
- if auth is enabled, evidence that runtime routes are not returning `401`
- a tiny recall test transcript
- a separate note on what still remains unproven

That last one matters. People trust repos more when they admit the boundary instead of pretending everything is magically solved.

---

## Related Docs

- [README.md](../README.md)
- [README_zh.md](../README_zh.md)
- [docs/architecture.md](./architecture.md)
