# Known-Good Example

This page shows what a **reasonable, known-good OpenClaw + OpenViking wiring state** looks like.

Not a fantasy screenshot.
Not “trust me bro.”
Just a concrete example of the kind of config and output you want to see.

---

## What this example is for

Use this page when you want to answer questions like:

- “What should my config roughly look like?”
- “What does a healthy verification result look like?”
- “What does this prove?”
- “What does this still **not** prove?”

If your setup looks broadly like this and your checks behave similarly, you are probably past the basic wiring stage.

---

## Example config shape

Your actual `~/.openclaw/openclaw.json` may contain much more than this.
That is fine.
The point here is the **relevant integration shape**, not an exact full-file diff.

```json
{
  "plugins": {
    "allow": ["openviking"],
    "entries": {
      "openviking": {
        "enabled": true,
        "config": {
          "mode": "remote",
          "baseUrl": "http://127.0.0.1:1933",
          "apiKey": "YOUR_OPENVIKING_API_KEY",
          "agentId": "default",
          "autoRecall": true,
          "autoCapture": true,
          "emitStandardDiagnostics": true,
          "logFindRequests": true,
          "timeoutMs": 5000
        }
      }
    },
    "slots": {
      "contextEngine": "openviking"
    }
  }
}
```

What matters here:

- `plugins.entries.openviking.enabled = true`
- `plugins.allow` contains `openviking`
- `plugins.slots.contextEngine = openviking`
- `mode = remote`
- `baseUrl` is your real reachable OpenViking endpoint
- `autoRecall = true`
- `autoCapture = true`

If those are missing, don’t act surprised when memory behavior is weird.

---

## Example `openclaw status` expectations

The exact text may differ across versions.
The point is the **shape of success**, not pixel-perfect matching.

You want something broadly consistent with:

- OpenClaw CLI responds normally
- gateway is healthy / running
- config is loadable
- runtime is not obviously stuck, exploding, or half-dead

If `openclaw status` hangs, errors, or looks obviously broken, stop there.
That is not a “later maybe memory” problem. That is a base runtime problem.

---

## Example `./scripts/verify.sh` success shape

A decent run should look roughly like this:

```text
== OpenClaw status ==
...normal OpenClaw status output...

== openviking config ==
{
  "openviking": {
    "enabled": true,
    "config": {
      "mode": "remote",
      "baseUrl": "http://127.0.0.1:1933",
      "agentId": "default",
      "autoRecall": true,
      "autoCapture": true,
      "emitStandardDiagnostics": true,
      "logFindRequests": true,
      "timeoutMs": 5000
    }
  },
  "slots": {
    "contextEngine": "openviking"
  }
}

== OpenViking health check ==
...endpoint response...
[verify][ok] /health responded

== OpenViking ping check ==
...endpoint response...
[verify][ok] /ping responded

== Interpretation ==
If config looks right and health/ping respond, you likely proved:
- OpenClaw is wired to OpenViking
- contextEngine is configured
- the endpoint is reachable
```

That is the “known-good wiring” zone.

---

## What this example **does prove**

If your setup matches this closely, you likely proved:

- OpenClaw is configured to use OpenViking
- the plugin wiring is present
- the intended context engine is selected
- the configured OpenViking endpoint is reachable
- your recall/capture switches are turned on

That is already useful.
A lot of people don’t even get this far.

---

## What this example **does not prove**

It does **not** prove:

- long-term extraction quality
- memory usefulness over time
- cross-session retrieval quality
- ranking quality
- whether the retrieved memories are clean instead of junk
- whether your deployment has no hidden auth / timeout / retry issues under load

So if you only have this level of evidence, say:

> Wiring is working, but long-term extraction still needs separate validation.

Yes, it sounds less sexy.
That’s because it’s honest.

---

## Minimal follow-up test after this page

Once the known-good wiring checks pass, do one non-mushy recall test.

Example:

1. send a unique phrase:

> verification phrase: silver-cactus-2026

2. continue for another turn or two
3. later ask:

> What was the weird verification phrase I gave you earlier?

If that works consistently, then recall/capture behavior is probably alive too.

That is stronger than config-only proof, but still weaker than full long-term extraction validation.

---

## Related docs

- [README.md](../README.md)
- [docs/verification.md](./verification.md)
- [docs/install-from-scratch.md](./install-from-scratch.md)
- [docs/troubleshooting.md](./troubleshooting.md)
- [docs/architecture.md](./architecture.md)
