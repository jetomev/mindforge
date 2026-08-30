# mindForge

**A working agreement between you and your AI assistant that does not decay.**

If you work with an AI assistant on real projects over months, two things go
wrong. It forgets *how you work* between sessions, and it drifts *within* long
ones. mindForge fixes both structurally — with tiers that decide what is always
loaded, triggers that make the rest actually load, and a closeout ritual that
cannot be forgotten because it does not depend on remembering.

📖 **[Read the method](docs/METHOD.md)** — the doctrine. The scripts are the easy part.

> **Status: v0.1.3, days old.** Built and dogfooded on Arch Linux with
> [Claude Code](https://claude.com/claude-code), in a terminal *and* in Claude
> Desktop — the briefing is verified identical on both. It has already caught
> real defects (see below), including six in itself the day after it shipped.
> v0.1.2 was then put through a **115-check test matrix**, which found nine more
> and is what v0.1.3 fixes. Still: one machine, one user, and nothing here has
> survived a month. We publish early and say so.

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
| `mindforge wrap "<focus>" "<b1>\|<b2>"` | deliberate closeout; warns on unpushed work |
| `mindforge wip "<note>"` | leave an in-flight note for the next session — `--show`, `--clear` |
| `mindforge drift "<what slipped>"` | log a drift observation with a timestamp |
| `mindforge rot` | the silent-failure checks, on their own |

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
neither depends on anyone remembering.

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

**Not yet demonstrated:** the drift log is empty, so drift instrumentation is a
designed mechanism, not a proven result. One machine, one user, one assistant.
There is still **no automated test suite** — the matrix is a specification run
by hand, which is the most overdue item on the roadmap.

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
