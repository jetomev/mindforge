# Roadmap

Newest first; Future at the top.

## Future

- [ ] **A test suite.** v0.1.1 shipped six fixes verified entirely by hand.
      That worked because the surface is small; it will not keep working.
      Shell, so `bats` or a plain harness over a sandboxed `MINDFORGE_STATE`.
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

## v0.1.2 — 2026-08-29

- [x] Per-session marks, keyed on the session id, with an orphan sweep (F-7)
- [x] Launch notification over DBus, rate-limited to one per launch (F-8)
- [x] `scope:` line in every brief, from `persona.txt` (F-9)
- [x] R7 — memory index stale relative to the files it indexes (F-10)
- [x] Dirty repos report the shape of the change, not just the fact (F-11)
- [x] `mindforge wip` — in-flight work survives a change of conversation (F-12)

## v0.1.1 — 2026-08-29

- [x] Terminal/Desktop parity established and documented in the source
- [x] `last_wrapped()` — the closeout no longer buried by session churn (F-1)
- [x] Rot log appends once per day per finding (F-2)
- [x] Dependency annotates the git state instead of replacing it (F-3)
- [x] `session_end` floor, so an empty session is not recorded as one (F-4)
- [x] `days_since` survives a malformed row (F-5)
- [x] State logs archived and pruned of pre-fix churn

## v0.1.0 — 2026-08-29

- [x] Scrub hook, installed before any content existed
- [x] L0 tier, template and generated instance, validated in a live session
- [x] L1 tier across four domains, with an explicit loading trigger
- [x] `mindforge brief` — fast local path
- [x] `wrap`, `drift`, session-start and session-end hooks
- [x] Rot check with three-strikes escalation
- [x] `docs/METHOD.md`
