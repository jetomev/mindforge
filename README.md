# mindForge

**A working agreement between you and your AI assistant that does not decay.**

If you work with an AI assistant on real projects over months, two things go
wrong. It forgets *how you work* between sessions, and it drifts *within* long
ones. mindForge fixes both structurally — with tiers that decide what is always
loaded, triggers that make the rest actually load, and a closeout ritual that
cannot be forgotten because it does not depend on remembering.

📖 **[Read the method](docs/METHOD.md)** — the doctrine. The scripts are the easy part.

> **Status: v0.1.6, one month old.** Built and dogfooded on Arch Linux with
> [Claude Code](https://claude.com/claude-code), in a terminal *and* in Claude
> Desktop — the briefing is verified identical on both. A second machine, a
> Windows laptop running Git Bash, has used it since mid-September and found
> nine defects of its own; three are fixed, six are open and listed in the
> issues. Its **automated test suite** has 160 checks. Every check it makes
> answers yes, no, or *could not look* — never two answers where three are
> true. Still: one user, and we publish early and say so.

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
| `mindforge wrap "<focus>" "<b1>\|<b2>"` | deliberate closeout that measures: uncommitted, unpushed, no remote, stale `TODO.md` — and says **clean** or **NOT clean**. Run it again in the same session to correct it |
| `mindforge wrap --previous "<focus>" "<b1>\|<b2>"` | close the last session that ended without a wrap, keeping its own times |
| `mindforge wip "<note>"` | leave an in-flight note for the next session — `--show`, `--clear` |
| `mindforge drift "<what slipped>"` | log a drift observation with a timestamp |
| `mindforge rot` | the silent-failure checks, on their own |
| `mindforge log [--drop-last]` | the last few rows of the session log; `--drop-last` removes the last one and keeps a backup |

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
commits this session while its `TODO.md` did not. A check that cannot run is
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
| R8 | the queue pointing at an issue that is already closed — checked against GitHub |
| R9 | a memory index too big to load in full, which fails with no message at all |
| R10 | the session hooks missing or switched off — without them nothing above runs by itself |
| R11 | a project with recent commits but no line in the queue — so the brief cannot show it at all |

---

## Install

```bash
git clone https://github.com/jetomev/mindforge.git ~/Programs/mindforge
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
```

Then edit `~/.claude/CLAUDE.md` — replace the `{{PLACEHOLDERS}}` with your own
names and rules, and **keep it under 60 lines**. See
[`templates/rules/_ABOUT.md`](templates/rules/_ABOUT.md) for the L1 tier.

To wire the hooks, add to `~/.claude/settings.json`:

```json
{ "hooks": {
    "SessionStart": [
      { "matcher": "startup|resume|clear",
        "hooks": [{ "type": "command", "command": "mindforge session-start" }] },
      { "matcher": "compact",
        "hooks": [{ "type": "command", "command": "cat \"$HOME/.claude/CLAUDE.md\"" }] }
    ],
    "SessionEnd": [
      { "hooks": [{ "type": "command", "command": "mindforge session-end" }] }
    ] } }
```

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
assistant. The **automated suite** (`bash testing/run-tests.sh`, 160 checks)
covers the closeout, the queue, session start, the headline, the scrub hook,
the release script, R11, and the "could not look" path of R3–R6 and R10 — and refuses to report green
when nothing ran. R1, R2 and much of the full brief are still checked by hand
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
