# OpenClaw + OpenViking From-Scratch Guide

This guide is for people in the more annoying branch:

- you **do not** already have OpenViking running
- you want to get to a clean OpenClaw + OpenViking integration from near-zero
- you want the steps separated so failures are easier to localize

The basic rule is simple:

1. get **OpenClaw** healthy first
2. get **OpenViking** healthy second
3. wire them together third
4. verify wiring before claiming “memory solved”

If you try to collapse all four into one blurry mega-step, you deserve the debugging pain you get.

---

## Official / Upstream References

### OpenClaw

- Docs: <https://docs.openclaw.ai>
- Install: <https://docs.openclaw.ai/install>
- Installer: <https://docs.openclaw.ai/install/installer>
- macOS: <https://docs.openclaw.ai/platforms/macos>

### OpenViking

- GitHub repo: <https://github.com/volcengine/OpenViking>

This repo does **not** replace OpenViking upstream install docs.
It exists to make the OpenClaw-side integration path less stupid.

---

## Step 1 — Install and validate OpenClaw first

Install OpenClaw using the official docs.

Then validate the OpenClaw side **before** touching OpenViking:

```bash
openclaw status
```

You want a sane result here.

If OpenClaw itself is already broken, do not move on.
Otherwise you will end up blaming OpenViking for damage OpenClaw already had.

### Step 1 success criteria

You should be able to say:

- OpenClaw is installed
- the CLI works
- `openclaw status` does not look obviously broken
- your config file location is known

---

## Step 2 — Install and validate OpenViking separately

Now go install OpenViking using the upstream repo/docs.

Your goal here is **not** to make memory magical yet.
Your goal is much smaller:

- OpenViking service exists
- it is running
- it exposes a reachable HTTP endpoint
- you know the base URL
- you know whether it requires an API key
- you know which agent ID you plan to use

Typical example values:

- base URL: `http://127.0.0.1:1933`
- agent ID: `default`

### Minimum check

Once OpenViking is up, test:

```bash
curl http://127.0.0.1:1933/health
```

If that does not respond cleanly, stop.
Do **not** continue to integration yet.

### Step 2 success criteria

You should be able to say:

- OpenViking is alive on a known URL
- I can hit `/health`
- I have the required auth/key material
- I know the agent ID I want to use

---

## Step 3 — Wire OpenViking into OpenClaw

Once both sides work independently, use this repo’s wiring script:

```bash
git clone https://github.com/dx47618004/openclaw-openviking-one-click.git
cd openclaw-openviking-one-click
chmod +x scripts/install.sh scripts/verify.sh
./scripts/install.sh --api-key YOUR_OPENVIKING_API_KEY
```

If your OpenViking URL is different:

```bash
./scripts/install.sh \
  --api-key YOUR_OPENVIKING_API_KEY \
  --openviking-url http://127.0.0.1:1933 \
  --agent-id default \
  --config ~/.openclaw/openclaw.json
```

### What this script does

It configures OpenClaw roughly like this:

- enables the `openviking` plugin
- sets remote mode
- sets `baseUrl`
- turns on `autoRecall`
- turns on `autoCapture`
- sets `plugins.slots.contextEngine = openviking`
- restarts the OpenClaw gateway
- creates a backup of your previous config first

### What this script does **not** do

It does **not**:

- install OpenViking for you
- prove extraction quality
- guarantee every upstream deployment shape works the same

---

## Step 4 — Verify wiring honestly

Run:

```bash
./scripts/verify.sh
```

Also run:

```bash
openclaw status
```

Then read:

- [docs/verification.md](./verification.md)
- [docs/troubleshooting.md](./troubleshooting.md)

### Step 4 success criteria

You should be able to say:

- config is wired correctly
- OpenViking endpoint is reachable from the OpenClaw side
- recall/capture switches are on
- the plugin path is plausible and alive

That still does **not** automatically mean long-term extraction is production-ready.

---

## Step 5 — Run one non-mushy recall test

Use a unique phrase.
Not something generic like “hello memory test”.
That kind of test is trash.

Example:

> verification phrase: silver-cactus-2026

Then later ask for it back.

Example:

> What was the weird verification phrase I gave you earlier?

If it comes back reliably, good — recall behavior is probably alive.

But again: that is still weaker than full long-term extraction validation.

---

## Practical Split of Responsibility

### OpenClaw is responsible for

- runtime orchestration
- channels/tools/agent behavior
- local workspace continuity files
- calling the configured context engine

### OpenViking is responsible for

- context retrieval path
- session/archive storage behavior
- memory extraction behavior
- retrieval quality on the backend side

If something breaks, knowing which side owns what saves a lot of clown debugging.

---

## If you get stuck

Start with these docs:

- [README.md](../README.md)
- [docs/architecture.md](./architecture.md)
- [docs/verification.md](./verification.md)
- [docs/troubleshooting.md](./troubleshooting.md)

And the most important rule:

Do not describe the setup as “fully working memory” unless you actually verified the memory part.
