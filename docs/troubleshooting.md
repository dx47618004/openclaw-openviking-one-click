# OpenClaw + OpenViking Troubleshooting

This is the boring but useful part.

When people say “it’s broken,” they usually mean one of several completely different failures.
Stop mixing them together.

---

## Symptom Matrix

| Symptom | Likely Layer | Usually Means |
|---|---|---|
| `openclaw status` looks broken | OpenClaw base layer | OpenClaw itself is not healthy yet |
| `install.sh` fails preflight on `/health` | OpenViking base layer | wrong URL, dead service, auth problem, or OpenViking not installed |
| Config contains `openviking`, but runtime still feels wrong | wiring / plugin load layer | config exists, but runtime/plugin may still not be loading cleanly |
| Sessions seem to exist but memory is weak/empty | extraction layer | capture may work while durable extraction still does not |
| Recall tests are vague/inconsistent | test design layer | your test phrase is mush, so the result is mush |

---

## 1. OpenClaw itself is not healthy

### Typical signs

- `openclaw status` hangs, errors, or looks obviously wrong
- config file is malformed
- gateway restart does nothing useful

### What to check

```bash
openclaw status
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

## 2. OpenViking `/health` does not respond

### Typical signs

- `install.sh` preflight fails
- `verify.sh` warns on `/health`
- `curl http://127.0.0.1:1933/health` fails

### What to check

```bash
curl http://127.0.0.1:1933/health
```

If you use a different URL, test that exact URL.

### Likely causes

- wrong base URL
- OpenViking service is not running
- remote network / firewall problem
- auth setup mismatch

### What to do

Do not continue wiring until the endpoint is reachable.
If the backend is dead, integration scripts won’t save you.

---

## 3. Config looks correct but OpenClaw still behaves weirdly

### Typical signs

- `plugins.entries.openviking` exists
- `plugins.slots.contextEngine = openviking`
- but the runtime still feels half-dead, stuck, or inconsistent

### What to check

- `openclaw status`
- `./scripts/verify.sh`
- whether the gateway restart actually happened
- whether the config file you edited is the config file OpenClaw is really using

### Likely causes

- plugin not loading cleanly at runtime
- the wrong config file was edited
- endpoint reachable intermittently
- old config/state residue

### What to do

Narrow it down:

1. confirm config file path
2. confirm health endpoint
3. confirm status output
4. retry with a clean, unique test phrase

Do not just stare at a vague “feels weird.” That’s not diagnosis.

---

## 4. Recall seems dead

### Typical signs

- later prompts do not appear to remember earlier unique facts
- recall behavior is inconsistent turn to turn

### What to check

Use an explicit unique phrase.
Example:

> verification phrase: silver-cactus-2026

Then later ask for that exact weird phrase back.

### Likely causes

- plugin path is not actually alive
- session capture works, but retrieval path is weak
- endpoint issues are intermittent
- your test phrase was generic and impossible to attribute confidently

### What to do

Run:

```bash
./scripts/verify.sh
```

Then repeat the test with something unique enough to be searchable and memorable.

---

## 5. Sessions appear to exist, but durable memory is poor or empty

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
Too bad. It’s the truth.

---

## 6. You are not sure whether the problem is OpenClaw or OpenViking

Use this split:

### Probably OpenClaw-side

- CLI/status broken
- config malformed
- gateway behavior odd even before OpenViking wiring
- channel/runtime behavior broken generally

### Probably OpenViking-side

- `/health` fails
- `/ping` fails
- extraction quality is poor
- memory retrieval quality is poor despite valid wiring

### Possibly either side

- recall feels flaky
- config is right but runtime behavior is inconsistent

In those cases, reduce variables and test one layer at a time.

---

## Recommended Debug Order

Do these in order:

1. `openclaw status`
2. `curl <openviking-base-url>/health`
3. `./scripts/install.sh --dry-run ...`
4. `./scripts/verify.sh`
5. one unique-phrase recall test
6. only then investigate extraction quality

If you skip the order, you get chaos instead of signal.

---

## Related Docs

- [README.md](../README.md)
- [docs/architecture.md](./architecture.md)
- [docs/verification.md](./verification.md)
- [docs/install-from-scratch.md](./install-from-scratch.md)
