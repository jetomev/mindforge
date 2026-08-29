# mindForge

**A working agreement between you and your AI assistant that does not decay.**

If you work with an AI assistant on real projects over months, two things go
wrong. It forgets *how you work* between sessions, and it drifts *within* long
ones. mindForge fixes both structurally — with tiers that decide what is always
loaded, triggers that make the rest actually load, and a closeout ritual that
cannot be forgotten because it does not depend on remembering.

📖 **[Read the method](docs/METHOD.md)** — the doctrine. The scripts are the easy part.

> **Status: v0.1.1, days old.** Built and dogfooded on Arch Linux with
> [Claude Code](https://claude.com/claude-code), in a terminal *and* in Claude
> Desktop — the briefing is verified identical on both. It has already caught
> real defects (see below), including six in itself the day after it shipped,
> but nothing here has survived a month. We publish early and say so.

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
| `mindforge drift "<what slipped>"` | log a drift observation with a timestamp |
| `mindforge rot` | the silent-failure checks, on their own |

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

---

## Honest status

**Caught on day one:** two personal-data leaks in commits, and a packaging file
whose *content* had diverged while its version matched — so every version check
had passed it.

**Not yet demonstrated:** the drift log is empty, so drift instrumentation is a
designed mechanism, not a proven result. One machine, one user, one assistant.

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
