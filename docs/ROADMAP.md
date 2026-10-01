# Roadmap

Newest first; Future at the top.

## Future

- [ ] **Extend the test suite to R1, R2 and the full brief.** 146 checks cover
      the closeout, the queue, session start, the headline, the scrub hook and
      the could-not-look paths. R1, R2 and most of the full brief are still
      verified by hand against the 115-check matrix.
- [ ] **Windows as a supported platform.** Six open findings from a month on
      a Windows laptop (#15, #17–#21) plus #34: install, paths, hooks under auto
      mode, notifications, the PowerShell wrapper.
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

## v0.1.6 — 2026-10-01

- [x] R11 — a project with recent work but no queue line; `@quiet` opt-out (#39)
- [x] The projects table lines up whatever the length of a name (#40)

## v0.1.5 — 2026-09-29

- [x] `wrap` measures and says clean or NOT clean; open items carry into the next brief (#27)
- [x] Every check answers yes, no, or could not look — ten places fixed (#24)
- [x] Scrub hook proves its grep works; `scrub PARTIAL` without a wordlist (#24)
- [x] Rot check runs at every session start, lookups in parallel (#29)
- [x] R10 — missing or disabled session hooks (#16)

## v0.1.4 — 2026-09-29

- [x] R8 — the queue is checked against the real tracker (#13)
- [x] A missing `queue.md` is a first-run state; the template ships (#14)
- [x] Every project root scanned, and the queue's repos wherever they are (#33)
- [x] R9 — memory index too large to load in full
- [x] Projects can share a priority tier
- [x] Automated test suite, `testing/run-tests.sh` (#35)
- [x] `--help` never runs a command; `wrap` can be corrected, closed later, and repaired (#22)
- [x] Windows line endings in `queue.md` read correctly (#36)

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
