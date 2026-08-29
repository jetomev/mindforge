# Changelog

Newest first.

## v0.1.1 — 2026-08-29

Parity hotfix. KognogOS ships both Claude Code in a terminal *and* Claude
Desktop, so a briefing that behaves differently depending on which one you
opened is a defect, not a quirk. Every finding below was caught by using
mindForge from Desktop on the day after it shipped.

**The principle, now written into the source:** parity does not rest on the
`/dev/tty` copy — Desktop's hook runner has no controlling terminal, so that
copy is silently dropped. It rests on the **directive** injected into the
assistant's context, which reaches the model identically on both surfaces.

- 🪵 **F-1 · `Last time` rendered empty.** `last_session()` was one `tail -1`
  answering two different questions. Split into `last_session()` (when did I
  last work) and `last_wrapped()` (what did I last finish). The v0.1.0 closeout
  had been sitting thirteen rows deep, unread, while the panel showed nothing.
- 🧹 **F-2 · `rot.log` grew every time it was read.** `brief` runs the rot check
  on each invocation; unguarded, that appended two identical lines per run —
  17 lines carrying 2 real facts. Now appended once per day per finding.
- 🔍 **F-3 · a dirty repo could hide behind a dependency label.** The projects
  table assigned over the git state, so a dirty repo that also had a dependency
  printed `waits` and its dirt surfaced nowhere. Dependency now annotates
  rather than replaces: `clean waits`, `dirty clears`.
- ⏱ **F-4 · Desktop session churn buried the log** — 14 rows in one afternoon,
  four of them stamped `18:02–18:02`. `session_end` now has a floor: below two
  minutes the mark is cleared and no row is written. `wrap` always logs
  regardless of length, so nothing deliberate is ever lost.
  Override with `MINDFORGE_MIN_SESSION_MIN`.
- 🛟 **F-5 · one malformed row took down the whole headline.** `days_since` fed
  `date(1)` straight into arithmetic and printed a raw shell error where the
  briefing belonged. It now returns `?`, and the unmeasurable path can no
  longer write a bad date into the log in the first place.
- 🏷 **`mindforge --version`.** v0.1.0 had no version surface in the binary at
  all — `--version` printed usage and exited 2. Once KognogOS ships this,
  "which mindforge is installed" has to be answerable without reading git.
- 📝 **F-6 · the tty comment claimed less than we knew.** Replaced "unproven on
  Claude Code" with what is actually proven, what is still unproven, and why
  the directive — not the terminal — is the delivery mechanism.

**Known and filed, not fixed here:** the session mark is a single global file,
so concurrent Claude sessions overwrite each other's boundaries. Caught live
while writing this release, with Desktop and two terminals open at once (F-7).

**Verification:** no automated suite exists yet — this is shell, and the
project has none. Every fix was exercised by hand, including three cases for
the F-4 floor (0-minute suppressed, 40-minute recorded, unmeasurable recorded
rather than guessed) and an end-to-end corrupt-mark run for F-5. `bash -n`
clean. The absence of a test suite is itself on the roadmap.

## v0.1.0 — 2026-08-29

First release. Built and dogfooded in a single day.

- 🏛 **The tier pyramid** — L0 always-loaded working agreement under a hard
  60-line budget, L1 domain files loaded by topic, L2 per-project, L3 history.
- 🔗 **Explicit triggers.** L1 does not load itself, and injected context does
  nothing without a directive attached. Both were discovered the hard way.
- 📋 **`mindforge brief`** — local-only orientation: last session, project table,
  a ranked recommendation, and state. No network, so it cannot hang or lie.
- 🔚 **`wrap`, `drift`, and a session-end floor** — the closeout runs whether or
  not anyone remembers, so a session cannot vanish unrecorded.
- 🔎 **Rot check with three-strikes escalation** — six silent-failure checks;
  anything red for three sessions is promoted from a row to a demand.
- 🛡 **Two-layer scrub hook** — published shape patterns plus a local wordlist
  that never enters the repo. Refused two real leaks on day one.
- 📖 **`docs/METHOD.md`** — the doctrine, which is the actual product.
