# Changelog

## 2026-04-07

### Changed

- repositioned the repo around the **official local** OpenClaw + OpenViking path instead of the earlier mixed remote-first story
- updated both `README.md` and `README_zh.md` to mark the current state as **fixed** and **minimum runtime acceptance passed**
- clarified the validated baseline: OpenViking `0.3.3`, Python `3.13`, `OPENVIKING_PYTHON` persisted in `~/.openclaw/openviking.env`, `log.output=stderr`, plugin mode `local`
- documented the second major real-world failure mode: a green `/health` does **not** prove runtime auth is working
- documented the required auth rule: if OpenViking server uses `auth_mode=api_key`, the OpenClaw plugin must also be given `plugins.entries.openviking.config.apiKey` or `OPENVIKING_API_KEY`
- made explicit that `ov.conf.root_api_key` is **not** inherited automatically by the plugin
- rewrote `docs/verification.md` around four layers: wiring, local startup, runtime auth, and capture/recall/extraction
- rewrote `docs/troubleshooting.md` to include the `/health`-green-but-401` trap and the exact integration mismatch behind it

### Verified

- `POST /api/v1/search/find` returns `200`
- `POST /api/v1/sessions/<id>/messages` returns `200`
- `POST /api/v1/sessions/<id>/commit` returns `200`
- extraction completion was observed after commit acceptance
- post-restart logs showed no new `401`, `UNAUTHENTICATED`, or `Missing API Key`

### Status

- official local migration: **complete**
- runtime auth: **verified**
- minimum business-path acceptance: **passed**

## 2026-04-05

### Added

- a first-class architecture doc at `docs/architecture.md`
- a Mermaid architecture diagram in both English and Chinese READMEs
- a split install flow for two audiences:
  - people who already have OpenViking running
  - people who still need to install OpenViking first
- direct official / upstream doc entry points for both OpenClaw and OpenViking
- a more beginner-oriented “ultimate setup” structure with explicit Step 1 / Step 2 / Step 3 flow
- a standalone verification guide at `docs/verification.md`
- a from-scratch onboarding guide at `docs/install-from-scratch.md`
- a troubleshooting guide at `docs/troubleshooting.md`
- a known-good reference page at `docs/known-good-example.md`
- stronger preflight / backup / next-step behavior in `scripts/install.sh`
- broader config + health + ping checks in `scripts/verify.sh`

### Clarified

- this repo should lead with the integration path itself, not a “please star this” pitch
- OpenClaw is the runtime, OpenViking is the context / memory backend, and workspace Markdown files still matter
- the repo currently supports the “already have OpenViking” path best, while the from-scratch path still relies on upstream installation docs
- successful wiring does **not** automatically prove long-term memory extraction quality
- a known-good wiring state should be compared against config shape plus verify output, not just vibes

### Positioning

- this repo is now framed as a practical, small, honest integration guide for beginners instead of a star-bait landing page
