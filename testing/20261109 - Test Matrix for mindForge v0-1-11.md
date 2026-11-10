# Test Matrix for mindForge v0.1.11

*Written 2026-11-09 by Claude for the maintainer. The AUR gets ONE push, 0.1.11-1, after part A passes.
The automated suite passed on the home PC and inside the recipe's own `check()` (382 checks, 382 pass,
1 could not look: no PowerShell there). Every expected line below was dry-run first against the packaged
copy (`pkg/mindforge/usr/bin/mindforge`).*

**Every step calls `/usr/bin/mindforge`:** on this desktop a plain `mindforge` runs the repo copy
(`~/.local/bin` comes first on PATH), which would pass these steps without testing the package at all.
A4 and A5 read two one-line sample commands kept outside the repo (`~/.cache/mindforge-dev/handover/m11/`):
`bad.json` is an in-place `sed` on a memory note, `good.json` only reads one.

Mark each row ✅ pass · ❌ fail (paste what you saw) · — not applicable.

## A · Home PC — the locally built AUR package

| # | Step | You should see | Result |
|---|---|---|---|
| A1 | in `~/Programs/aur-mindforge`: `nog install ./mindforge-0.1.11-1-any.pkg.tar.zst` | nog installs it, no errors | |
| A2 | `/usr/bin/mindforge --version` | `mindforge 0.1.11` | |
| A3 | `/usr/bin/mindforge rot` | warnings that have stood for days end in `(N sessions -- fix it)` | |
| A4 | `/usr/bin/mindforge memcheck --shell < ~/.cache/mindforge-dev/handover/m11/bad.json` | `mindforge memcheck refused this shell command: it changes a memory file (sed -i on a memory file)…` | |
| A5 | `/usr/bin/mindforge memcheck --shell < ~/.cache/mindforge-dev/handover/m11/good.json` | nothing at all (quiet means fine) | |
| A6 | `/usr/bin/mindforge heard --check "I never asked for that"` | `I never asked` (a check only: nothing is logged) | |
| A7 | start a new Claude Code session yourself and type: *what note came in front of my message?* | it quotes your sentence "We work, step-by-step…" — the style note arriving in a session you typed into (this goes through the add-on, which calls the repo copy) | |

## Verdict

- A all ✅ → the AUR gets 0.1.11-1 (one push).
- A7 ✅ also closes the last open proof of the brain, part 1: the style note seen arriving in a session the maintainer typed into.
- Each ❌ becomes a finding (F-1, …), fixed in the same unpublished version.
