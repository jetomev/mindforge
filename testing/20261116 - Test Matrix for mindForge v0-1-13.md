# Test Matrix for mindForge v0.1.13

*Written 2026-11-16 by Claude for the maintainer. 0.1.13 is the hotfix for F-2 (#77): a chat left open for
more than 12 hours lost its start mark. 0.1.13-1 gets the ONE AUR push, after part A passes. The automated
suite passed on the home PC, in `scripts/release.sh` and inside the recipe's own `check()` (391 checks, 1 could
not look: no PowerShell there).*

**Every step calls `/usr/bin/mindforge`:** on this desktop a plain `mindforge` runs the repo copy
(`~/.local/bin` comes first on PATH), which would pass these steps without testing the package at all.

Mark each row ✅ pass · ❌ fail (paste what you saw) · — not applicable.

## A · Home PC — the locally built AUR package

| # | Step | You should see | Result |
|---|---|---|---|
| A1 | in `~/Programs/aur-mindforge`: `nog install ./mindforge-0.1.13-1-any.pkg.tar.zst` | nog installs it, 0.1.12-1 → 0.1.13-1, no errors | |
| A2–A6 | `bash ~/Programs/mindforge/scripts/test-installed.sh` | the version is `mindforge 0.1.13`; then the same four checks as 0.1.12 (escalated warnings, the guard refuses an in-place `sed` and lets a read through, the correction catcher); `0 step(s) failed`, `OK` | |
| A7 | (Claude runs it) `cmp /usr/bin/mindforge <(git -C ~/Programs/mindforge show v0.1.13:bin/mindforge)` | nothing printed: the installed program is the tagged one, F-2's fix included | |
| A8 | (follow-up, does not hold the AUR) the next morning, the desk chat opened 2026-11-16 18:09 still has its start mark | its wrap replaces its own row instead of adding a second one | |

## Verdict
A1–A7 pass (see the results file of the same date).
