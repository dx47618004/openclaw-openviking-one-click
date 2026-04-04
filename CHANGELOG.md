# Changelog

## 2026-04-05

### Added

- a first-class architecture doc at `docs/architecture.md`
- a Mermaid architecture diagram in both English and Chinese READMEs
- a split install flow for two audiences:
  - people who already have OpenViking running
  - people who still need to install OpenViking first
- direct official / upstream doc entry points for both OpenClaw and OpenViking
- a more beginner-oriented “ultimate setup” structure with explicit Step 1 / Step 2 / Step 3 flow

### Clarified

- this repo should lead with the integration path itself, not a “please star this” pitch
- OpenClaw is the runtime, OpenViking is the context / memory backend, and workspace Markdown files still matter
- the repo currently supports the “already have OpenViking” path best, while the from-scratch path still relies on upstream installation docs
- successful wiring does **not** automatically prove long-term memory extraction quality

### Positioning

- this repo is now framed as a practical, small, honest integration guide for beginners instead of a star-bait landing page
