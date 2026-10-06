# Changelog

Newest first.

## v0.1.7 — 2026-10-06

- 👔 **`mindforge tone` — the tie alert (#45).** The tone rule lost, every long
  turn, to the assistant's built-in report style; a reminder cannot beat a house
  style. Now a Stop hook reads the last reply from the transcript and flags
  memo-speak (section headers, "Expected result:", status-report openers, local
  patterns from `tone.local`). First hit: the reply goes back for a rewrite and
  the person sees "tie alert"; second pass: alert only, never a loop. Code blocks
  are not read; a tool result does not reset the reply; no transcript, bad input
  or no python: silence.
- 🔔 **`mindforge chime` (#45).** "When you finish and are waiting for me, make a
  chime sound, so if I am away I can hear it." A sound from the Stop hook (after
  a reply goes through) and the Notification hook. Player and file found on the
  machine or set in the config (`MINDFORGE_CHIME`, `MINDFORGE_CHIME_PLAYER`);
  silent, never failing, without them.
- 🔓 **`scripts/release.sh` (#41).** v0.1.6 went public on the wrong commit: the
  scrub hook refused the docs commit, and the tag and push on the next line ran
  anyway. The script refuses, before anything is tagged or pushed, when the
  version is not X.Y.Z, the tree is not clean, `main` is behind `origin`, the
  `VERSION` line or the changelog does not match, the tag already exists, or
  the tests fail. Then it tags (the message is the changelog entry), pushes,
  and prints the human steps that remain. Logged to `logs/`.

Tests: 180 checks, 180 pass (was 146): the tie alert and the chime are 20 of them,
each fed a known-bad input as well as a good one. The release checks were also run
against three planted copies of the script, each missing one guard; each was
caught.

## v0.1.6 — 2026-10-01

**The queue is checked for what it leaves out.** One morning's brief showed a
table two days stale and a rot check with nothing to say. v0.1.5 fails **4 of
this release's 146 checks**: the three new ones below, and the heading that
now reads "rot check (R1-R11)".

- 🚨 **R11 · active work the queue does not name (#39).** hypeForge had been
  worked on for four days, the previous session was entirely hypeForge, and
  the brief did not show it at all: nobody had added its line. R6 asked whether
  each line points at something real, R8 whether its task is still open;
  nothing asked whether the list was complete. R11 names any repo with commits
  in the last 14 days (`MINDFORGE_ACTIVE_DAYS`) and no queue line. AUR twins
  ride on their project's line. A repo deliberately left out goes on a new
  `@quiet` line, so the opt-out is visible in the file. Its first real run
  named a true finding: `homelab`. Same shape as #28 and #37 — a hand-written
  record that nothing checks — and it closes the "Known gaps" line that said
  so.
- **The projects table lines up with long names (#40).** A 21-character
  project name in a 20-wide column pushed its whole row one place right. The
  column now sizes to the longest name; names are never cut.

Tests: 146 checks, 146 pass (was 134; +12, none removed). Each new check was
also run against v0.1.5: the R11 and alignment checks fail there, as they
must. Warnings: no shell linter installed; not counted. `bash -n` is clean.

## v0.1.5 — 2026-09-29

**Nothing silent.** Four fixes, one idea: a check that did not run, could not
look, or was never asked must say so. v0.1.4 fails **47 of this release's 134
checks**.

- 🚨 **`wrap` measures instead of trusting (#27).** Twice in one session a wrap
  was declared and was not. It now checks every repo for uncommitted files,
  unpushed commits and a missing remote, and flags a project with commits this
  session whose `TODO.md` did not change. It ends with **`wrap clean`** or
  **`wrap NOT clean -- N open, M not verified`**. Open items are stored with the
  row, and the next brief opens with them, dated. Memory and vault changes are
  shown as facts, not counted: when to write those is the human's call.
- 🚨 **Every check answers yes, no, or could not look (#24).** An audit of every
  check found ten that reported "fine" when they could not measure: no upstream
  read as "nothing unpushed", an unreadable repo as clean, zero repos as a green
  "0 repos clean", a missing memory folder skipped three rules and said "nothing
  rotting", a missing `CLAUDE.md` passed its line budget. All ten now say what
  they could not check.
- 🔓 **The scrub hook proves its tool before trusting its silence (#24).** On a
  grep without PCRE, every pattern silently found nothing and the hook said
  `scrub clean` — proven, it let a private address through. It now tests the
  tool on a must-match and a must-not-match sample and refuses the commit if
  they come out the same. No wordlist is `scrub PARTIAL`, not clean. A file
  staged and then deleted from the folder is scanned; it used to be skipped.
  The new hook refused its own first commit.
- 🚨 **The rot check runs at every session start (#29).** It had only ever run
  when a human typed `brief` or `rot`, so a finding could be true all night and
  reach no one. Meanwhile the git count was labelled "rot line" and printed a
  clean verdict in the check's place; it now reads `git: …`. GitHub lookups run
  in parallel: session start costs about a second cold, and offline at most one
  timeout (`MINDFORGE_GH_TIMEOUT`, 8s) instead of one per reference. Its first
  real run reported a true finding.
- **R10 — the session hooks (#16).** Missing hooks, or `disableAllHooks`, are
  said on the brief's second line and in the rot check. A Windows install had
  run three days without them.

Tests: 134 checks, 134 pass (was 71). Warnings: no shell linter installed; not
counted. `bash -n` is clean.

## v0.1.4 — 2026-09-29

**The release that tests itself.** A month of daily use on two machines, one of
them Windows, found the queue lying, a health check blind to part of the disk,
and a closeout that could be destroyed by asking it for help. Every fix below
was found by using the tool. For the first time, **the fixes ship with automated
tests** — 71 checks, all passing, and each new check was also run against the
previous version to prove it fails there.

### The queue — hand-written, and now checked

- 🚨 **R8 · the queue is held against the real tracker (#13).** The brief
  recommended an issue for **16 days after it was closed**, while the rot check
  said "nothing rotting" every session. The file announced itself as
  "maintained by `mindforge wrap`"; nothing had ever written it, so every
  reader assumed someone else kept it. The queue cannot be generated — no tool
  knows what you decided to do next — so it stays hand-written and becomes
  checkable: column 5 names the issue, and R8 asks GitHub whether it is still
  open. `-` opts a row out on purpose; a **blank** column is reported, so a row
  cannot drop out of coverage by forgetting it. Answers are cached for six hours
  (`MINDFORGE_QUEUE_TTL`); "could not reach the tracker" is **never** cached, so
  a network blip cannot harden into a lasting answer. R8 is the first check that
  needs the network.
- **A missing `queue.md` is a first-run state, not a crash (#14).** Two raw
  shell errors landed in the middle of the brief, with exit status 0. mindForge
  shipped no queue template, so this was the path every new user met. The reads
  are guarded, and `templates/queue.md.template` now ships with the format.
- **Two projects can share a priority tier.** `@priority nog,store/two kognog`
  ranks the first two equally. A dated launch no longer has to wait its turn
  behind a standing ranking.
- **Windows line endings in `queue.md` (#36).** A queue saved on Windows turned
  every `-` opt-out into "could not reach the tracker", silently cost the last
  name on the `@priority` line its rank, and leaked a stray character into the
  table. All five readers now go through one helper that drops it.

### The health line — "clean" must mean safe

- 🚨 **Every project root is scanned (#33).** The brief said "19 repos clean ·
  nothing unpushed" while a repo outside the one configured folder held two
  unpushed commits and another had no remote at all. `MINDFORGE_PROJECTS` is a
  colon-separated list now, and — the half that closes the hole — **every repo
  the queue names is scanned whether or not it sits under a root**. A repo with
  no remote is a finding in R3, in `wrap` and in the headline
  ("· N with nowhere to push"), and may no longer be called clean.
- 🚨 **R9 · a memory index too big to load (new).** Past the loader's limit the
  index is cut short on its way into the session, and nothing says so; the
  brief is then built from an unknown part of it. Live for two sessions before
  it was caught by chance. R9 warns at 20,000 bytes (`MINDFORGE_MEMORY_MAX`),
  deliberately early, while there is still room to compact.

### The closeout — asking for help must never run the command (#22)

- 🚨 **`wrap --help` recorded a real closeout.** An assistant learning the
  syntax ran it; mindForge logged a finished session titled "--help", deleted
  the in-flight note and threw away the session's start time. `-h`/`--help` now
  prints help for **every** command before anything runs. Any other leading
  dash is refused with nothing written; a note that really starts with a dash
  goes after `--`.
- **A second wrap corrects the first.** It replaces the session's row and keeps
  the real start time, where it used to add a zero-length duplicate.
- **`wrap --previous`** closes a session that ended without a wrap, in place,
  with its own times. The brief asks the human what that session did rather
  than inviting a guess.
- **`mindforge log [--drop-last]`** shows recent rows and removes the last one
  with a timestamped backup, so repairing the log is a command, not a hand edit
  that an assistant is rightly not allowed to make.

### Tests

- **`testing/run-tests.sh` — the first automated suite (#35).** Every check runs
  against a throwaway home directory, and the real state is fingerprinted
  before and after to prove it was not touched. It refuses to lie three ways: a
  deliberately false check must fail or the run stops; zero checks run is not a
  pass; a known defect is marked with its issue number, and one that starts
  passing is reported. Written on the Windows laptop, carried home in the issue
  as a patch, applied here byte-identical. **71 checks, 71 pass.** Against
  v0.1.3's `bin/mindforge` the suite reports 38 failures.
- Warnings: no shell linter is installed on the build machine, so none were
  counted. `bash -n` is clean.

### Still open

Seven Windows findings (#15–#21) and #34, the silent-failure group (#16, #24,
#27, #29) and six method lessons (#23, #25, #26, #28, #30, #31). All on the
issue tracker.

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
