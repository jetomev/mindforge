# Changelog

Newest first.

## v0.1.3 — 2026-08-30

**The handoff release.** v0.1.2 made continuity survive a change of conversation.
Then it was run against a written **115-check test matrix** across both surfaces,
and the matrix found that several of the things being handed over were arriving
damaged, or not arriving at all. Then the act of publishing that matrix found two
more — in the pre-commit scrub, the one mechanism this repo asks you to trust.
**Eleven fixes, five of them high.**

Every one was found by using the tool, not by reading the code.

### The scrub hook failed open, twice, silently

Both were found while staging this very release, by checking a green light
instead of believing it. The hook said `scrub clean` on a file carrying 26
occurrences of a name that was **on its own wordlist**.

- 🔓 **F-34 · a filename with a space in it was never scanned at all.**
  `for f in $staged` word-splits on whitespace, so
  `testing/20260830 - Test Matrix for mindForge v0-1-2.md` arrived as seven
  fragments, each failed the `[ -f "$f" ]` test, and each was skipped without a
  word. The release convention **mandates** spaces in that filename, so the one
  class of document most likely to be thick with personal detail was precisely
  the class the scrub could never see. Staged names are now read NUL-delimited,
  and the summary line reports how many files were actually scanned — a count
  you can check against what you staged.
- 🔓 **F-35 · under `pipefail`, a match reported itself as a miss.** The wordlist
  test was `printf '%s\n' "$added" | grep -qiF -- "$term"`. `grep -q` exits the
  instant it finds something; the `printf` still writing behind it takes SIGPIPE
  and exits 141; `pipefail` promotes 141 to the pipeline's status; the `if` reads
  a hit as a miss. It only appears once the content is large enough that the
  writer is still writing — 56 KB here, **deterministic, 8 runs out of 8** — so
  every small test passed and the guard failed on exactly the big documents that
  matter. Replaced with a here-string: no second process, no pipe, nothing to
  signal. **This one had been in the hook since the day it was written**, which
  means the two commits the README credits it with refusing were small enough to
  fall on the working side of the bug.

The lesson is the repo's own thesis turned on itself. `.githooks/pre-commit` is
the file that lets this project claim the separation is *mechanical, not
careful*. A guard that fails open and says `clean` is worse than no guard,
because no guard at least leaves you careful.

- 🚨 **F-33 · a standing rule that reaches almost no sessions is not a rule.**
  `rules.txt` could not do its job twice over: it prints only in the **full**
  brief, which the injected session-start handoff does not include, and even
  there it showed **one rule per day** — so with seven rules on file, any given
  rule was absent six days in seven. Found the way findings should be: the human
  asked for the same thing **twice in one day, on two surfaces**, and the file
  built for exactly that held nothing and would have shown a different rule
  anyway. Standing orders now live in their own `always.txt`, and **every line of
  it goes into every handoff**. Capped by `MINDFORGE_ALWAYS_MAX` (10), and the
  cap **announces itself in the handoff** — dropping a standing rule in silence
  is the precise failure this fix exists to end. A finding inside the finding:
  splitting the list left **7 standing orders and 1 rotating nudge**, so six of
  the seven rules had been sitting in a container that showed them one day in
  seven.
- 🚨 **F-16 · silent truncation did not lose the instruction, it inverted it.**
  The in-flight note was cut at 200 characters without saying so. On 2026-08-30 a
  543-character note delivered 200, and the 343 characters dropped carried every
  clause saying the work was **not finished** — including the ruling that each
  fix had to be proven on both surfaces. A fresh instance read the surviving
  "fixes written, not committed" as an invitation and proposed committing and
  tagging: **the one action the note existed to forbid.** The budget is now 900
  characters, and a note that is cut **says so in words**, where the reader
  cannot mistake the fragment for the whole.
- 🚨 **F-25 · a write that fails must never report success.** With the state
  directory unwritable, `mindforge wip` printed `in flight: <note>` and exited 0
  having stored nothing — the note whose entire purpose is surviving into the
  next session did not exist, and the human was told it did. Writes are now
  checked before they are claimed. `wrap` had the same shape with worse
  consequences: it deleted the in-flight note and dropped the session mark
  **before** logging, so a failed write destroyed the note *and* the session
  start while still printing `wrapped` — three losses reported as a success. It
  now logs first and destroys only what the log has actually replaced, and
  `session_end` keeps the mark when a row it meant to write did not land.
- 📌 **F-13 · the in-flight note now reaches the injected briefing.** The hook
  injects the short headline only, so the one line whose whole purpose is telling
  the next instance what to do next was the one line the next instance never saw.
  It was in the full brief, which nobody had to run.
- 🕰 **F-27 · stamp the in-flight line.** Undated and sitting directly beneath
  `last session: yesterday`, the note read as yesterday's — and a fresh instance
  duly reported work done at 09:08 that morning as "yesterday ended mid-flight."
  Two facts adjacent in injected context, one of them undated, read as one fact.
- 🔧 **F-17 · a successful closeout reported failure.** `[ $warned -eq 0 ] &&
  printf` was the last statement in `wrap`, so its false branch became the
  function's exit status: warning about unpushed commits made `wrap` exit 1,
  breaking `&&` chains and marking the SessionEnd hook failed — exactly in the
  case where there *is* unpushed work. The warning is output, not an error.
- 🚧 **F-18 · readable is not the same as meaningful.** The `scope:` line was
  gated on the file being readable, never on its content. An empty `persona.txt`
  printed a bare `scope:` with no scope, and `persona.example` copied verbatim —
  which its own first line tells you to do — announced
  `scope: # Copy to $MINDFORGE_STATE/persona.txt`. The line whose whole job is
  stating the boundary stated a comment. Comments and blanks are now skipped, and
  nothing is printed rather than something empty.
- 👻 **F-19 · absent is not clean.** A project named in `queue.md` but missing
  from disk was reported as `clean`, in green, because the state defaulted to
  clean and the not-a-repo branch never overwrote it. It now reads `absent`, in
  red. Absent is not clean; it is unknown.
- 📐 **F-32 · printf field widths count bytes, not visible characters.** A table
  cell carrying colour codes eats its own padding — `${D}no repo${O}` is 15 bytes
  for 7 visible characters, so a 10-wide field added nothing and every column to
  its right shifted left by three. Padding now happens **inside** the colour. The
  misalignment was on screen on both surfaces and read by nobody until the matrix
  reached it: output that is looked at but not read is its own class of defect.

**Testing.** 115 checks, both surfaces: **103 pass · 7 fail · 2 that this
hardware cannot decide either way · 2 whose expectation was wrong · 1 N/A · 0
deferred.** The failures are published in `testing/` rather than argued into
passes, and 12 findings remain open — all low, none blocking. The roll-up is
recomputed by `testing/tally-matrix.py`, never hand-tallied, and that script
**refuses to count a verdict it has not been taught** rather than guessing.

**Still no automated test suite.** Nine fixes verified by hand against a written
specification is better than nine verified by hand against nothing, but the
matrix is a spec waiting to be automated. It remains the most overdue item.

## v0.1.2 — 2026-08-29

Continuity across instances. v0.1.1 made the briefing identical on both
surfaces; v0.1.2 makes it survive the thing that actually happens all day —
you abandon a slugged conversation and open a clean one, and the new instance
has to pick up where the old one was. Every finding came from doing exactly
that, repeatedly, on purpose.

- 🔑 **F-7 · one mark per session, not one per machine.** Claude Desktop spawns
  roughly three sessions per launch, all sharing a single `.session-start`.
  They consumed each other's marks and the surviving conversation was left
  with none — so a wrap recorded `19:42–19:42` for an hour and a quarter of
  work. Marks are now keyed on the session id, which is exported to child
  processes. `wrap` runs from your own shell where that id is absent, so it
  takes the **oldest** surviving mark: the long-running session actually being
  worked in, never a churn sibling. Orphans swept after
  `MINDFORGE_MARK_TTL_H` (12h). The v0.1.1 mark migrates itself on first run.
- 🔔 **F-8 · a visible channel that works on both surfaces.** `/dev/tty` needs
  a controlling terminal and Desktop's hook runner has none. DBus needs
  neither — and `notify-send` locates the session bus by itself even with
  `DBUS_SESSION_BUS_ADDRESS` stripped from the environment. Verified on Plasma
  at all three urgency levels. Rate-limited to one popup per launch
  (`MINDFORGE_NOTIFY_GAP_S`), normal urgency never critical, and every failure
  path silent: no daemon, no `notify-send`, headless — none may break the hook.
- 🚧 **F-9 · scope printed, not remembered.** A persona scoped to two projects
  leaked into an unrelated one twice in three weeks — **both times in sessions
  that had the rule loaded.** A rule that breaks while loaded is a design
  problem, so the brief now ends with a `scope:` line read from
  `persona.txt`. See `persona.example`.
- 🕰 **F-10 · the index can be stale, not just incomplete.** R4 catches a memory
  file with no index line. It did not catch an index line that *contradicts*
  the file it points at — the failure that actually bit, when a fresh session
  read the one-line index, reported it as the file's contents, and stated the
  opposite of what the file said. New R7 flags any memory file written more
  recently than the index itself.
- 📊 **F-11 · "dirty" is a fact, not information.** A fresh session was told
  `2 dirty` and nothing more, so it offered to build a release that was
  already written and tested in the working tree. One stray untracked file and
  89 lines of finished work looked identical. The table now reads
  `dirty 1f +133/-13` or `dirty 1?`.
- 📌 **F-12 · `mindforge wip` — the mid-session sibling of `wrap`.** git can
  show that 133 lines changed. It cannot say *"written and tested, pending
  release"*, and that sentence is the entire difference between a fresh
  session resuming work and offering to redo it. Shown as an **In flight**
  panel above the project table; cleared automatically by `wrap`, because
  wrapped work is by definition no longer in the air.

**Verification:** still no automated suite — a full manual regression across
all six, including two concurrent sessions proving they no longer stomp each
other, `wrap` recovering a real multi-hour duration, and `wip` surviving into
a brief and being cleared by `wrap`. `bash -n` clean. F-7 and F-8 were also
confirmed in the wild: a real Desktop restart produced exactly one popup and
two coexisting marks.

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
