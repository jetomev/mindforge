# Roadmap

Newest first; Future at the top.

## Future

- [ ] **Stage 2 — the remote cache.** A scheduled collector for issue counts,
      published package versions and backup health, written to JSON. The brief
      reads the cache and **prints its age**, so it can never quietly go stale.
- [ ] **Stage 3 — decided by evidence, not appetite.** Every brief logs the cache
      age it read. After two weeks, if the cache was routinely stale on mornings
      after the machine slept, move the collector to an always-on host. If it was
      not, do not build it.
- [ ] **L2 templates** — a per-project working agreement worth copying.
- [ ] **Drift analysis** — `mindforge drift --report`, once there is data. It
      needs a month before it can say anything honest.
- [ ] **Assistant portability** — the method is not Claude-specific; the
      implementation currently is. Only claim otherwise after testing another.

## v0.1.0 — 2026-08-29

- [x] Scrub hook, installed before any content existed
- [x] L0 tier, template and generated instance, validated in a live session
- [x] L1 tier across four domains, with an explicit loading trigger
- [x] `mindforge brief` — fast local path
- [x] `wrap`, `drift`, session-start and session-end hooks
- [x] Rot check with three-strikes escalation
- [x] `docs/METHOD.md`
