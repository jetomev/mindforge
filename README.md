# mindForge

**A working agreement between you and your AI assistant that does not decay.**

> 🖥 **Where it runs:** **any Linux distribution, and Windows through Git Bash** · **no desktop needed**: a terminal tool (bash) · a plain text console should work, not tested yet.

If you work with an AI assistant on real projects over months, two things go
wrong. It forgets *how you work* between sessions, and it drifts *within* long
ones. mindForge fixes both structurally — with tiers that decide what is always
loaded, triggers that make the rest actually load, and a closeout ritual that
cannot be forgotten because it does not depend on remembering.

📖 **[Read the method](docs/METHOD.md)** — the doctrine. The scripts are the easy part.

> **Status: v0.1.10, seven weeks old.** Built and dogfooded on Arch Linux with
> [Claude Code](https://claude.com/claude-code), in a terminal *and* in Claude
> Desktop — the briefing is verified identical on both. A second machine, a
> Windows laptop running Git Bash, has used it since mid-September and found
> fourteen defects of its own; with 0.1.9 every one has a fix, and the
> Windows-only ones wait for that laptop's next run to be proven there. Its
> **automated test suite** has 293 checks. Every check it makes
> answers yes, no, or *could not look* — never two answers where three are
true. Still: one user, and we publish early and say so.

---

## The idea in one table

| Tier | Loaded | Budget | Holds |
|---|---|---|---|
| **L0** `~/.claude/CLAUDE.md` | always | **60 lines, hard** | rules that must never lapse |
| **L1** `~/.claude/rules/*.md` | by domain | ~100 lines | doctrine for one kind of work |
| **L2** `<repo>/CLAUDE.md` | in that project | ~80 lines | how *this* project ships |
| **L3** memory, docs | on demand | unbounded | history, decisions, why |

Assistant memory is normally one pile, retrieved when something seems relevant.
That works for facts and fails for rules — **retrieval is selective by design,
so a rule that applies only when recalled is not a rule.**

Two laws keep the pyramid standing:

- **One fact, one level.** Two copies drift by a word, then the wrong one wins.
- **Promotion requires demotion.** The top budget is hard. Dilution looks
  exactly like drift.

---

## What you get

```
$ mindforge brief

Sat 2026-08-29 · 16:48
last session: yesterday (19:00–23:05) — shipped v1.3.0 and v1.3.1
in flight (2026-08-29 16:31): matrix at 114/115 — one live check left, do NOT commit
always: Write plainly. Assume the reader is not an engineer.
always: One command per turn - intro, command, expected result, then stop.

Last time
  · Closed the 42-check test matrix, blocked 3 days on one section
  · Found a latent transaction-breaking bug mid-matrix, shipped the fix same night

Projects
  REPO        LAST         NEXT                                  STATE
  toolA       2026-08-28   #9 reboot advice after key upgrades    clean
  libB        2026-08-18   #1 unreadable on a text console        clears
  appC        2026-08-23   v2.0.0 migration                       waits

Recommended first
  toolA — #9 reboot advice after key upgrades

Rot check
  R2  toolA root packaging file diverges from published copy

One command per turn - intro, command, expected result, then stop.
```

| Command | Does |
|---|---|
| `mindforge brief` | what is true right now — local only, no network |
| `mindforge <project>` · `mindforge brief <project>` | **one project's brief** (0.1.10): its git state, the last session that named it, its queue line, its own `scripts/status.sh` (or its `TODO.md`'s open items), its hazards, the rot findings that name it, and one recommendation. Any case; a queue name or a folder name; an unknown name lists the known ones |
| `mindforge wrap "<focus>" "<b1>\|<b2>"` | deliberate closeout that measures: uncommitted, unpushed, no remote, stale `TODO.md` — and says **clean** or **NOT clean**. Run it again in the same session to correct it |
| `mindforge wrap --previous "<focus>" "<b1>\|<b2>"` | close the last session that ended without a wrap, keeping its own times |
| `mindforge wip "<note>"` | leave an in-flight note for the next session — `--show`, `--clear` |
| `mindforge drift "<what slipped>"` | log a drift observation with a timestamp |
| `mindforge rot [--timings]` | the silent-failure checks, on their own; `--timings` says how long each rule took (0.1.9) |
| `mindforge scrub --vault \| <file>...` | **scoped names where they do not belong** (0.1.10): every term in your private `scope.txt` is allowed only under the paths listed with it. `wrap` runs it over the vault notes changed in the session — the vault has no commits, so the commit scrub never saw it |
| `mindforge hazards <project> [word...]` | **the hazards a project wrote down** (0.1.10): every line starting `HAZARD:` in its Markdown, filtered by what you are about to touch |
| `mindforge hooks [--check \| --print]` | **are the hooks installed?** (0.1.9) — and `--print` gives the exact block to paste into `settings.json` for this platform (`--windows`, `--linux`). Hooks are installed by a person, by design: an assistant in auto mode is rightly not allowed to |
| `mindforge log [--drop-last]` | the last few rows of the session log; `--drop-last` removes the last one and keeps a backup |
| `mindforge tone [--check <file>]` | **the tie alert** (0.1.7): a Stop hook that reads the assistant's last reply and flags memo-speak — section headers, "Expected result:", status-report openers. First hit: the reply goes back for a rewrite and you see the alert; second pass: alert only. `--check` reads a file instead |
| `mindforge chime [--test]` | **a sound when the assistant is done and waiting** (0.1.7), so you hear it from the next room. From the Stop and Notification hooks; silent when there is no player or sound file |
| `mindforge active [--show\|--clear\|<path>]` | **the active project's banner** (0.1.8): a SessionStart hook that prints `scripts/status.sh` of the project in play — or, for a project with a **board** (a `.board` file), says to open the board beside the chat first and summarises its TODO.md (`boards/board.py`, unreleased). `wrap` moves the pointer to the project the focus names, so nobody edits it by hand; when the pointer and the last wrapped session disagree, the banner says so instead of stating the stale one as fact. Silent with no pointer |

Two files hold your rules, and the difference is the whole point:

| File | Shown | For |
|---|---|---|
| `always.txt` | **every line, every brief — including the injected handoff** | standing orders |
| `rules.txt` | one line per day, full brief only | rotating nudges |

They were one file until v0.1.3, and that file rotated. With seven rules on it,
any given rule was missing six days in seven — and it never appeared in the
short handoff the assistant actually receives at session start. A rule that
arrives sometimes is not a rule. Rotation is right for a nudge and wrong for a
standing order, so the two now live apart.

Hooks wire `brief` to session start and the closeout floor to session end, so
neither depends on anyone remembering. **The rot check runs at every session
start**, inside the briefing the assistant receives, because the moment
nothing looks wrong is the moment it exists for. Its GitHub lookups run in
parallel, so a cold start costs about a second, and offline at most one timeout.

`wrap` does not take "done" on trust. It checks every repo for uncommitted
files, unpushed commits and a missing remote, and flags a project that got
commits this session while its `TODO.md` did not — and, since 0.1.10, shows the
queue row of every project that got commits and asks *still true?* when
`queue.md` was not touched; holds the every-session handoff file to its
contract; and runs the scope list over the vault notes the session wrote. A check that cannot run is
reported as **not verified**, never as a pass. Memory and vault changes are
shown as facts, because when to write those is your call. Anything left open is
stored with the session's row, and the next brief opens with it.

A closeout can be corrected. Run `wrap` again in the same session and it
replaces its own row, keeping the real start time. A session that ended without
a wrap is closed later with `wrap --previous`, and the briefing asks *you* what
it did rather than letting the assistant reconstruct it. `--help` on any command
only prints help — it never runs the command.

The rot check looks for things that have quietly gone wrong, and says so in
every brief:

| Rule | Catches |
|---|---|
| R1 | a packaging file's version behind the repo's latest tag |
| R2 | a repo-root packaging file whose *content* differs from its published copy |
| R3 | uncommitted or unpushed work, or a repo with no remote at all |
| R4 | a memory file the index does not list |
| R5 | the always-loaded tier over its 60-line budget |
| R6 | the queue naming a project that is not on disk |
| R7 | a memory index older than the files it describes |
| R8 | the queue pointing at an issue that is already closed — checked against GitHub; and a row saying a version shipped that is behind the project's newest tag, `-` rows included |
| R9 | a memory index too big to load in full, which fails with no message at all |
| R10 | the session hooks missing or switched off — without them nothing above runs by itself |
| R11 | a project with recent commits but no line in the queue — so the brief cannot show it at all |
| R12 | a memory file that declares `rewritten_by: session` and was not rewritten during the last session — the one-slot handoff that said "read this first" while hours behind |

---

## Install

**Everything it needs** to build, run and test, with why, is in [docs/PACKAGING.md](docs/PACKAGING.md), measured from the code (the Forge Suite's [dependency audit](https://github.com/jetomev/forge-suite/issues/91), 2026-10-11).

From the AUR (since 2026-10-09): `yay -S mindforge`. The command lands in `/usr/bin/mindforge` and the starting files (templates and examples) in `/usr/share/mindforge/`, so the copies below come from there instead of a clone. Or from the source:

```bash
git clone https://github.com/jetomev/mindforge.git ~/Programs/mindforge
mkdir -p ~/.local/bin ~/.config/mindforge ~/.claude/state
ln -s ~/Programs/mindforge/bin/mindforge ~/.local/bin/mindforge
cp ~/Programs/mindforge/config.example ~/.config/mindforge/config   # edit paths
cp ~/Programs/mindforge/templates/CLAUDE.md.template ~/.claude/CLAUDE.md
```

Then the optional state files, into whatever `MINDFORGE_STATE` points at
(`~/.claude/state` by default) — each one is a plain list you edit by hand:

```bash
cp ~/Programs/mindforge/always.example  ~/.claude/state/always.txt    # standing orders
cp ~/Programs/mindforge/rules.example   ~/.claude/state/rules.txt     # rotating nudges
cp ~/Programs/mindforge/persona.example ~/.claude/state/persona.txt   # scope boundary
cp ~/Programs/mindforge/templates/queue.md.template ~/.claude/state/queue.md  # next task per project
cp ~/Programs/mindforge/scope.example   ~/.claude/state/scope.txt     # where scoped names belong
```

`templates/handoff.md.template` is the shape for a handoff to a session on
another machine: scope and facts, and deliberately nowhere to put working method
([METHOD.md §11](docs/METHOD.md)). `templates/rules/scripts.md` is an L1 file for
scripts that destroy: back up, gate on the measurement, move aside (§9).

Then edit `~/.claude/CLAUDE.md` — replace the `{{PLACEHOLDERS}}` with your own
names and rules, and **keep it under 60 lines**. See
[`templates/rules/_ABOUT.md`](templates/rules/_ABOUT.md) for the L1 tier.

**The hooks are the one step a person does, always** (#19). They run commands at
every session start and end, so Claude Code's auto mode does not let the
assistant add them — rightly. mindForge prints the exact block for your
platform, you paste it, and it checks the result:

```bash
mindforge hooks --print
```

Merge its `"hooks"` part into `~/.claude/settings.json` (keep any hooks already
there), then:

```bash
mindforge hooks --check
```

On Linux the block looks like this:

```json
{ "hooks": {
    "SessionStart": [
      { "matcher": "startup|resume|clear",
        "hooks": [{ "type": "command", "command": "mindforge session-start" },
                  { "type": "command", "command": "mindforge active" }] },
      { "matcher": "compact",
        "hooks": [{ "type": "command", "command": "cat \"$HOME/.claude/CLAUDE.md\"" }] }
    ],
    "SessionEnd": [
      { "hooks": [{ "type": "command", "command": "mindforge session-end" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "mindforge tone" }] }
    ],
    "Notification": [
      { "hooks": [{ "type": "command", "command": "mindforge chime" }] }
    ] } }
```

`Stop` and `Notification` are the 0.1.7 pair: the tie alert and the chime. `mindforge active`
(0.1.8) is the active project's banner, for projects that carry a `scripts/status.sh`. All
three are optional; the brief does not count them as missing.

### On Windows (Git Bash)

In daily use since September on a Windows 11 laptop with
[Git for Windows](https://gitforwindows.org/), which brings bash and every tool
the script uses (`date -d`, `stat -c`, `find -printf`). The differences, each
found there (#17). The 0.1.9 fixes among them are proven here with stand-ins and
wait for that laptop's next run to be proven on Windows itself:

- **No `ln -s`.** Without Developer Mode, Git Bash's `ln -s` makes a *copy*,
  which goes stale at the next `git pull`. Use a two-line wrapper instead:

  ```bash
  mkdir -p ~/bin ~/.config/mindforge ~/.claude/state
  printf '#!/usr/bin/env bash\nexec bash "$HOME/Programs/mindforge/bin/mindforge" "$@"\n' > ~/bin/mindforge
  ```

- **The hooks need `"shell": "bash"` and a full path**, because Claude Code runs
  hook commands in PowerShell there. `mindforge hooks --print` writes them that
  way on Windows (or anywhere, with `--windows`).
- **From PowerShell, use `bin/mindforge.ps1`** (#21), never a `.cmd` wrapper: a
  `.cmd` pastes the arguments into one string, so `wrap 'a focus' 'b1|b2'` lost
  every word after the first and cmd.exe ran `|` as a pipe. In your PowerShell
  profile: `Set-Alias mindforge "$HOME\Programs\mindforge\bin\mindforge.ps1"`.
  PowerShell 7 passes every argument intact; Windows PowerShell 5.1 can still
  mangle a `"` *inside* an argument.
- **The memory folder is found by itself** (#15, 0.1.9): Claude Code names it
  after the Windows spelling of your home (`C--Users-you`), and mindForge now
  does too. `MINDFORGE_MEMORY` still overrides it.
- **Project roots in Git Bash's spelling**, `/c/Users/you/Programs`: roots are
  separated by `:`, so `C:/…` would split in two. A repo inside a synced folder
  (Dropbox, OneDrive) can be listed **directly** as a root, spaces and
  apostrophes included (#18) — no junction needed.
- **No desktop notification** (#20): the launch popup uses `notify-send`, which
  Windows does not have. The hook quietly skips it; the briefing itself
  is unaffected. The chime needs one of `paplay`, `pw-play`,
  `canberra-gtk-play`, `aplay` or `afplay`, so on Windows it is silent too.

### The tie alert — why a hook and not a rule

The tone rule ("talk like I talk, not like a memo") was one line among thirty in
the working agreement, loaded every session — and it lost, every long turn, to
the assistant's own built-in report style, which is re-applied by the app on
every reply. A reminder cannot beat a house style. So the rule became a check
that fires on screen: when a reply carries a section header, a form label or a
status-report opener, the person sees "tie alert: …" and the assistant gets the
reply back to rewrite, once. Extra patterns go in `~/.config/mindforge/tone.local`,
one regular expression per line. The same shape as the handoff: drift is
something both can see, not something one has to catch.

The `compact` entry re-injects your working agreement after context compaction —
the moment standing rules are most likely to be flattened away.

If either hook is missing, or `disableAllHooks` is on, `mindforge brief` says so
on its second line and the rot check reports it as R10. Without them the
handoff happens only when someone remembers it, which is the failure this whole
tool exists to remove.

---

## Nothing personal, ever

If you publish your own fork, the templates and your filled-in instances must be
different artifacts, and the separation must be **mechanical, not careful**.

`.githooks/pre-commit` refuses any commit carrying personal data, in two layers:
generic published patterns that name *shapes* (emails, private IPs, key material,
real home paths), and a local wordlist of literal terms that lives outside the
repo because it is itself personal data.

```bash
git config core.hooksPath .githooks
mkdir -p ~/.config/mindforge && cp scrub.example ~/.config/mindforge/scrub.local
```

**On the day this was built, that hook refused two commits.** Neither was a test.
Both were genuine mistakes by the person who had written the rule an hour
earlier. That is the argument: you cannot be careful enough, often enough,
forever.

**And then the hook itself failed open — twice.** While staging v0.1.3 it
reported `scrub clean` on a file carrying 26 occurrences of a name that was on
its own wordlist. Two independent defects: a filename containing a space was
never scanned at all, and under `pipefail` a match reported itself as a miss on
any file big enough to matter. Both are fixed (F-34, F-35), both are written up
in the changelog, and neither is edited out of this README. A guard that fails
open and says `clean` is worse than no guard, because no guard at least leaves
you careful — and the only reason these were caught is that the green light was
checked instead of believed.

So the hook now checks itself before it checks you. It first runs its search
tool against a sample it must catch and one it must not; if the tool cannot
tell them apart, the commit is refused, because nothing could be scanned.
Without a local wordlist it says **`scrub PARTIAL`**, not `clean` — names and
hostnames were not looked for. The same rule runs through every check
mindForge makes: **yes, no, or could not look** — never two answers where three
are true.

---

## Honest status

**Caught on day one:** two personal-data leaks in commits, and a packaging file
whose *content* had diverged while its version matched — so every version check
had passed it.

**Caught by testing itself:** v0.1.2 was run against a written 115-check matrix
across both surfaces. It came back 103 pass, 7 fail, 2 that the hardware cannot
decide either way, 2 whose expectation was simply wrong, 1 not applicable. Nine
of those became the v0.1.3 fixes. The failures are published in `testing/`
rather than argued into passes.

**Caught by releasing itself:** v0.1.6 went public on the wrong commit for a
few minutes. The scrub hook refused a commit, and the tag and push, typed on the
next line, ran anyway. Releases now go through `scripts/release.sh`, which
refuses before anything is tagged unless the tree is clean, `main` is current,
the version and changelog match, and the tests pass (#41).

**Not yet demonstrated:** the drift log holds one note in a month, so drift
instrumentation is a designed mechanism, not a proven result. One user, one
assistant. The **automated suite** (`bash testing/run-tests.sh`, 293 checks)
covers the closeout, the queue, session start, the headline, the scrub hook,
the release script, R11, the tie alert, the chime, the active project, one repo
seen under two spellings of its path, the hooks command, the Windows memory
folder, a config that tries to override a sandbox, a repo in a synced folder,
one project's brief, stale queue rows, the every-session handoff file, the vault
scrub, hazards, and the "could not look" path of R3–R6 and R10 — and refuses to report green
when nothing ran. A check that cannot be made on a machine (a folder link where
Git Bash only copies, the PowerShell wrapper where there is no PowerShell) says
*could not look* and is counted on its own, never as a pass. The run also fails
if it leaves anything behind in the repo. On 2026-10-19 the harness itself was
found to hold twenty checks that claimed two conditions and proved one — written
`check "x" [ A ] && [ B ]`, the `&& [ B ]` ran outside the check. Each now passes
its whole condition in, and a planted check proves the second half counts. A failing check prints the
first lines of what it looked at, so a report from another machine carries
evidence, not just a verdict. R1, R2 and much of the full brief are still checked by hand
against the 115-check matrix.

**Assistant-agnostic in method, Claude Code in implementation.** The tiers, the
laws and the rituals transfer to any assistant that reads project files. We have
only tested one, and we will not claim otherwise.

---

## Authors

Built by [jetomev](https://github.com/jetomev) with Claude (Anthropic) as
co-developer. Part of the [KognogOS](https://github.com/jetomev/KognogOS)
ecosystem, and useful entirely on its own.

MIT licensed — deliberately more permissive than the rest of the suite, because
the whole point is that you copy these templates into your own setup.
