# Roadmap

Newest first; Future at the top.

## Future

- [ ] **A test suite.** Now the most overdue item by a distance. v0.1.1 shipped
      six fixes verified entirely by hand and v0.1.3 shipped nine more; that
      worked because the surface is small, and it will not keep working. The
      excuse is gone: the **115-check matrix in `testing/` is the specification**
      that was missing, written down and run twice across both surfaces. A check
      that can be written down can be automated. Shell, so `bats` or a plain
      harness over a sandboxed `MINDFORGE_STATE`.
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
- [ ] **Study [ctx](https://github.com/ctxrs/ctx) in depth.** An open-source
      CLI that searches the session history coding agents already keep on
      disk. It attacks the same problem from the opposite side —
      retrieval-first where mindForge is curation-first — and its agent skill
      independently arrives at a rule this method also holds: retrieved
      history is evidence, not current instructions. A first skim
      (2026-09-13) surfaced three leads worth a proper look: stamp each
      `wrap` handoff with the session transcript path, so the raw "why" is
      always findable; ship the method as a self-triggering skill, attacking
      the known "L1 does not load itself" weakness structurally; publish a
      short threat model, as ctx does even for a local-only tool. A deeper
      read decides which of these become issues.

## v0.1.3 — 2026-08-30

- [x] `always.txt` — standing orders in **every** handoff, not one per day (F-33)
- [x] In-flight notes stop truncating silently; a cut note says so (F-16)
- [x] Failed writes never report success — `wip`, `wrap`, `session_end` (F-25)
- [x] The in-flight note reaches the injected briefing, not just the full one (F-13)
- [x] In-flight line carries its own timestamp, so it cannot read as yesterday's (F-27)
- [x] `wrap` exits 0 when it warns about unpushed commits (F-17)
- [x] `scope:` line validates content, not just readability (F-18)
- [x] A project missing from disk reports `absent`, not `clean` (F-19)
- [x] Table padding counts visible characters, not bytes (F-32)
- [x] Scrub hook scans filenames containing spaces — it skipped them entirely (F-34)
- [x] Scrub hook wordlist match survives `pipefail`; a hit no longer reads as a miss (F-35)
- [x] 115-check test matrix published in `testing/`, with a tally that refuses to guess

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
