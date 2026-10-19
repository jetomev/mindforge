# Test Matrix for mindForge v0.1.10

*Written 2026-10-19 by Claude for the maintainer. 0.1.9 and 0.1.10 shipped the same evening, and
the AUR gets ONE push: 0.1.10-1, after part A passes. The automated suite passed on the home PC
(293 checks, 293 pass, 1 could not look: no PowerShell there) and in a clean Arch chroot.
The laptop's part is in the v0.1.9 matrix (section B), run on 0.1.10.*

Mark each row ✅ pass · ❌ fail (paste what you saw) · — not applicable.

## A · Home PC — the locally built AUR package

| # | Step | You should see | Result |
|---|---|---|---|
| A1 | in `~/Programs/aur-mindforge`: `nog install ./mindforge-0.1.10-1-any.pkg.tar.zst` | nog installs it, no errors | |
| A2 | `mindforge --version` | `mindforge 0.1.10` | |
| A3 | `mindforge brief` | the full brief; in State a `handoff` line naming `project_next_session_plan.md` | |
| A4 | `mindforge hypeforge` | hypeForge's own brief: git, last session, queue line, its phase table, the rot check, one recommendation | |
| A5 | `mindforge nosuchthing` | "not a command or a project I know", then the known projects | |
| A6 | `mindforge scrub --vault` | the seven older vault notes, one line per note and name — judge them yourself; nothing is changed | |
| A7 | `mindforge hooks` | `hooks: session-start and session-end are installed` | |
| A8 | `mindforge rot --timings` | a `timing` line per rule (R1 … R12), then the rot result | |
| A9 | start a new Claude Code session | the briefing arrives as before, its rot line says `(R1-R12)` | |

## B · Work laptop

Section B of `20261019 - Test Matrix for mindForge v0-1-9.md`, after `git pull` brings 0.1.10.

## Verdict

- A all ✅ → the AUR gets 0.1.10-1 (one push), and #64, #66 close.
- B passing closes #15, #21, #38 and #65; each ❌ becomes a finding (W-15, …).
