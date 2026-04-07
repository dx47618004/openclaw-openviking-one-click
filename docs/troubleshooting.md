# OpenClaw + OpenViking Troubleshooting

This is the boring but useful part.

When people say “it’s broken,” they usually mean one of several completely different failures.
Stop mixing them together.

---

## Symptom Matrix

| Symptom | Likely Layer | Usually Means |
|---|---|---|
| `openclaw gateway status` looks broken | OpenClaw base layer | OpenClaw itself is not healthy yet |
| `127.0.0.1:1933` is not listening | local spawn layer | local OpenViking child process did not come up |
| `/health` is `200`, but runtime still feels dead | auth/runtime layer | service is up, but real API routes are failing |
| Logs show `401 Missing API Key` | auth layer | plugin client is not sending the required API key |
| Sessions seem to exist but memory is weak/empty | extraction layer | capture may work while durable extraction still does not |
| Recall tests are vague/inconsistent | test design layer | your test phrase is mush, so the result is mush |

---

## 1. OpenClaw itself is not healthy

### Typical signs

- `openclaw gateway status` hangs, errors, or looks obviously wrong
- config file is malformed
- gateway restart does nothing useful

### What to check

```bash
openclaw gateway status
```

Then inspect your config file and any recent edits.

### Likely causes

- broken JSON
- stale config edits
- gateway not restarted cleanly
- unrelated OpenClaw issue that has nothing to do with OpenViking

### What to do

Fix OpenClaw first.
Do not pile OpenViking on top of a broken base runtime.

---

## 2. Local OpenViking service does not start

### Typical signs

- `127.0.0.1:1933` has no listener
- `/health` fails
- logs mention local port unavailable or client initialization timeout

### What to check

```bash
lsof -nP -iTCP:1933 -sTCP:LISTEN
curl http://127.0.0.1:1933/health
```

### Likely causes

- wrong Python runtime
- wrong `configPath`
- wrong `port`
- child process crashed immediately
- `log.output = stdout` is destabilizing local mode on your machine

### What to do

Confirm the known-good local baseline:

- `mode = local`
- explicit `configPath`
- explicit `port`
- Python `3.13`
- persistent `OPENVIKING_PYTHON` in `~/.openclaw/openviking.env`
- `log.output = stderr`

Do not keep debugging recall until the local child process is actually alive.

---

## 3. `/health` works, but runtime still feels broken

### Typical signs

- `/health` returns `200`
- but recall/capture/commit still look dead
- logs mention `UNAUTHENTICATED` or `Missing API Key`

### What to check

Inspect runtime logs for real API routes, not just `/health`.

The important ones are:

- `/api/v1/sessions/.../context`
- `/api/v1/search/find`
- `/api/v1/sessions/.../messages`
- `/api/v1/sessions/.../commit`

### Likely causes

- OpenViking server runs with `auth_mode = api_key`
- plugin config does not include `plugins.entries.openviking.config.apiKey`
- operator assumed local mode would bypass auth

### What to do

This is the exact trap we hit in real validation:

- local OpenViking came up correctly
- `/health` was green
- but all real plugin requests returned `401`
- root cause: plugin config had **no `apiKey`**, while the OpenViking server required one

If your `ov.conf` uses:

```json
{
  "server": {
    "auth_mode": "api_key",
    "root_api_key": "..."
  }
}
```

then your OpenClaw plugin config must also provide the corresponding `apiKey`.

A green `/health` does **not** override auth requirements.

---

## 4. Config looks correct but OpenClaw still behaves weirdly

### Typical signs

- `plugins.entries.openviking` exists
- `plugins.slots.contextEngine = openviking`
- but runtime still feels half-dead, stuck, or inconsistent

### What to check

- `openclaw gateway status`
- actual runtime logs
- whether the config file you edited is the config file OpenClaw is really using
- whether auth is required server-side
- whether session/search/commit calls are succeeding rather than 401ing

### Likely causes

- plugin not loading cleanly at runtime
- the wrong config file was edited
- endpoint reachable intermittently
- auth mismatch
- old config/state residue

### What to do

Narrow it down:

1. confirm config file path
2. confirm local port listener
3. confirm `/health`
4. confirm no `401 Missing API Key`
5. retry with a clean, unique test phrase

Do not just stare at a vague “feels weird.” That is not diagnosis.

---

## 5. Recall seems dead

### Typical signs

- later prompts do not appear to remember earlier unique facts
- recall behavior is inconsistent turn to turn

### What to check

Use an explicit unique phrase.
Example:

> verification phrase: silver-cactus-2026

Then later ask for that exact weird phrase back.

### Likely causes

- runtime auth is failing
- session capture works, but retrieval path is weak
- endpoint issues are intermittent
- your test phrase was generic and impossible to attribute confidently

### What to do

First confirm there are no `401` errors.
Then repeat the test with something unique enough to be searchable and memorable.

---

## 6. Sessions appear to exist, but durable memory is poor or empty

### Typical signs

- you think messages are landing somewhere
- but useful long-term memory artifacts are absent or low quality

### Usually means

This is often **not** a wiring failure.
It is usually an extraction / commit / retrieval-quality problem.

### What to check

- whether OpenViking is storing sessions versus extracted memories
- whether extraction runs automatically or on a separate trigger
- whether the memory objects are meaningful rather than junk
- whether enough time has passed for processing

### Correct interpretation

A completely honest statement is:

> Wiring works, but long-term extraction still needs separate validation.

Yes, that sounds less sexy.
Too bad. It is the truth.

---

## 7. You are not sure whether the problem is OpenClaw or OpenViking

Use this split:

### Probably OpenClaw-side

- CLI/status broken
- config malformed
- gateway behavior odd even before OpenViking wiring
- channel/runtime behavior broken generally

### Probably OpenViking-side

- local child process never stabilizes
- `/health` fails
- extraction quality is poor
- retrieval quality is poor despite valid wiring

### Integration-layer mismatch

- `/health` works
- real API routes return `401`
- plugin config lacks `apiKey`
- service requires `auth_mode = api_key`

That last one is not “just OpenClaw” or “just OpenViking.”
That is an integration mismatch.

---

## Recommended Debug Order

Do these in order:

1. `openclaw gateway status`
2. `lsof -nP -iTCP:1933 -sTCP:LISTEN`
3. `curl http://127.0.0.1:1933/health`
4. inspect `plugins.entries.openviking.config`
5. if server auth is enabled, confirm plugin `apiKey` is present
6. inspect logs for `401 Missing API Key`
7. only then run a unique-phrase recall test
8. only then investigate extraction quality

If you skip the order, you get chaos instead of signal.

---

## Related Docs

- [README.md](../README.md)
- [docs/architecture.md](./architecture.md)
- [docs/verification.md](./verification.md)
