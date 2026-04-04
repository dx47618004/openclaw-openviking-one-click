# OpenClaw + OpenViking Verification Guide

This guide exists because people keep mixing up three different milestones:

1. **the plugin is wired correctly**
2. **session capture / recall are working**
3. **long-term extraction is producing useful memory artifacts**

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
- `mode = remote`
- `baseUrl` points to a live OpenViking endpoint
- `autoRecall = true`
- `autoCapture = true`

This is the minimum “the cable is plugged in” layer.

### Layer 2 — Capture and recall are alive

At this layer, you are proving the integration is doing something real during usage.

You want evidence that:

- conversation/session data is being captured
- recall hooks are active during later turns
- OpenClaw can actually reach OpenViking during runtime

This is the “not just config, actually alive” layer.

### Layer 3 — Long-term extraction is validated

At this layer, you are proving that OpenViking is not just storing sessions, but also extracting durable, retrievable long-term memories in a way you trust.

That may require:

- time for extraction to run
- server-side extraction jobs or commit behavior
- checking the OpenViking side directly
- validating the retrieved memories are meaningful rather than junk

This is the hardest layer, and people bullshit it the most.

---

## Quick Verification Checklist

Run:

```bash
./scripts/verify.sh
```

Then manually review the output.

A decent result should show most or all of the following:

- OpenClaw status prints without obvious failure
- `openviking` plugin config is present
- `contextEngine` is `openviking`
- OpenViking health endpoint responds
- OpenViking ping endpoint responds
- recall/capture flags are on in config

If you only have that much, then congratulations: **wiring is probably correct**.

Do **not** oversell that as “production memory fully solved.”

---

## Recommended Manual Test Flow

### Test A — Health and config

Check these first:

```bash
openclaw status
./scripts/verify.sh
```

What you want:

- no broken JSON
- OpenClaw gateway alive
- OpenViking endpoint reachable
- context engine set to `openviking`

### Test B — Session capture

Have a short conversation with OpenClaw after enabling the plugin.

Example pattern:

1. send a message with a unique phrase
2. continue for 1-2 more turns
3. later inspect whether the session exists on the OpenViking side

Good unique phrase example:

> `verification phrase: silver-cactus-2026`

Why unique? Because otherwise you end up searching generic garbage and then wondering why nothing is obvious.

### Test C — Recall behavior

After a few turns, ask a follow-up that requires remembering the earlier unique phrase.

Example:

> “What was the weird verification phrase I told you earlier?”

If recall is working, you should see behavior consistent with the previous turn being available through the integration path.

This still does **not** prove long-term extraction. It only proves recall/capture are not dead.

### Test D — Long-term extraction

This step depends more on the OpenViking side.

You need to confirm things like:

- does OpenViking show extracted memories, not just sessions?
- does extraction run automatically or require explicit commit/trigger behavior?
- are memories retrievable later by semantic search?
- are the extracted items useful, clean, and attributable?

If this step is unclear, say so honestly.

A correct statement is:

> “The OpenClaw ↔ OpenViking wiring is working, but long-term extraction still needs separate validation.”

That sentence is boring, but at least it’s not bullshit.

---

## What `verify.sh` Proves Well

The current script is good at checking:

- OpenClaw can start and report status
- config contains the expected OpenViking wiring
- target OpenViking URL is reachable
- basic HTTP health/ping checks respond

That is useful.

It is **not** enough to prove:

- extraction quality
- retention quality
- ranking quality
- cross-session memory quality
- whether your prompts actually benefit from the stored memory

---

## Failure Patterns

### 1. `openclaw status` is weird or broken

That usually means one of these:

- OpenClaw itself is not healthy yet
- config JSON is broken
- gateway restart did not succeed
- the plugin config is malformed

Fix that before doing anything clever.

### 2. Health endpoint fails

Usually:

- wrong `baseUrl`
- OpenViking service not running
- local/remote network issue
- server needs auth you didn’t provide correctly

### 3. Config looks correct but recall still looks dead

Possible causes:

- plugin failed to load even though config exists
- OpenViking is reachable intermittently
- session capture path works but retrieval path is failing
- your test was too vague to tell whether recall happened

Use a unique phrase. Don’t test memory with mush.

### 4. Sessions exist but durable memory is poor or empty

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

> OpenClaw is successfully wired to OpenViking in remote mode, with `openviking` set as the context engine and recall/capture enabled.

### Stronger success statement

> OpenClaw is successfully talking to OpenViking, session capture is happening, and runtime recall behavior appears to be working.

### Statement that still needs separate proof

> Long-term memory extraction is fully validated and production-ready.

Do not say that unless you actually checked it.

---

## Suggested Evidence for Public Writeups

If you want this repo to look credible rather than hand-wavey, show evidence like:

- sanitized `openclaw status` output
- `verify.sh` output
- config snippet showing `contextEngine = openviking`
- a tiny recall test transcript
- a separate note on what still remains unproven

That last one matters. People trust repos more when they admit the boundary instead of pretending everything is magically solved.

---

## Related Docs

- [README.md](../README.md)
- [README_zh.md](../README_zh.md)
- [docs/architecture.md](./architecture.md)
