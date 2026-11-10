# Test Matrix for mindForge v0.1.12

*Written 2026-11-09 by Claude for the maintainer. 0.1.12 is the hotfix for F-1 (#75), found in step A7 of
the 0.1.11 test. 0.1.11-1 never reaches the AUR; 0.1.12-1 gets the ONE push, after part A passes. The
automated suite passed on the home PC and inside the recipe's own `check()` (388 checks, 1 could not
look: no PowerShell there).*

**Every step calls `/usr/bin/mindforge`:** on this desktop a plain `mindforge` runs the repo copy
(`~/.local/bin` comes first on PATH), which would pass these steps without testing the package at all.

Mark each row ✅ pass · ❌ fail (paste what you saw) · — not applicable.

## A · Home PC — the locally built AUR package

| # | Step | You should see | Result |
|---|---|---|---|
| A1 | in `~/Programs/aur-mindforge`: `nog install ./mindforge-0.1.12-1-any.pkg.tar.zst` | nog installs it, 0.1.11-1 → 0.1.12-1, no errors | |
| A2–A6 | `bash ~/Programs/mindforge/scripts/test-installed.sh` | the version is `mindforge 0.1.12`; then the same four checks as 0.1.11 (escalated warnings, the guard refuses an in-place `sed` and lets a read through, the correction catcher); `0 step(s) failed`, `OK` | |
| A7 | start a new Claude Code session yourself and type: *quote me, word for word, any note that came in front of my message* | your turn note, word for word, and **no** "Your last reply was caught with" line (F-1) | |

## Verdict

- A all ✅ → the AUR gets 0.1.12-1 (one push), and #75 closes with the result.
- Each ❌ becomes a finding (F-2, …), fixed before the push.
