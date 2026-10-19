# Test Matrix for mindForge v0.1.9 — the laptop batch

*Written 2026-10-19 by Claude for the maintainer. Two machines: the home PC (Arch, the AUR
package) and the work laptop (Windows 11, Git Bash, the git checkout). The automated suite
already passed on the home PC: 258 checks, 258 pass, 1 could not look (no PowerShell there).
This matrix is what only a person on each machine can check.*

Mark each row ✅ pass · ❌ fail (paste what you saw) · — not applicable.

## A · Home PC — the locally built AUR package

| # | Step | You should see | Result |
|---|---|---|---|
| A1 | `nog install ./mindforge-0.1.9-1-any.pkg.tar.zst` (from `~/Programs/aur-mindforge/`) | nog installs it, no errors | |
| A2 | `mindforge --version` | `mindforge 0.1.9` | |
| A3 | `mindforge brief` | the full brief as always; State shows `memory  N files` (not "not found") | |
| A4 | `mindforge hooks` | `hooks: session-start and session-end are installed` | |
| A5 | `mindforge rot --timings` | a `timing` line per rule, then the rot result; total well under 2 s | |
| A6 | start a new Claude Code session | the briefing arrives as before | |

## B · Work laptop — the checkout (Git Bash)

| # | Step | You should see | Result |
|---|---|---|---|
| B1 | `git -C ~/Programs/mindforge pull --ff-only` | fast-forward to v0.1.9 | |
| B2 | `bash ~/Programs/mindforge/testing/run-tests.sh` | **0 failed.** Up to two `could not look` lines are fine: the two-spellings checks (if no link or junction can be made) and the PowerShell wrapper (if no PowerShell is found from Git Bash). Paste the last 5 lines | |
| B3 | `git -C ~/Programs/mindforge status --short` after B2 | nothing — no `%SystemDrive%` folder | |
| B4 | take `MINDFORGE_MEMORY` out of `~/.config/mindforge/config`, then `mindforge brief` | State shows the same memory count as before, from `C--Users-…` (#15) | |
| B5 | `mindforge rot --timings` | the per-rule times — paste them (#38: where the ten seconds went) | |
| B6 | `mindforge hooks --print` | the block with `"shell": "bash"` on every hook | |
| B7 | PowerShell 7: `& "$HOME\Programs\mindforge\bin\mindforge.ps1" wip 'a note with spaces \| and a pipe'`, then `... mindforge.ps1 wip --show` | the whole note comes back, pipe included (#21); then `wip --clear` | |
| B8 | `mindforge active ~/Programs/mindforge` twice in a row, with a `wrap` naming mindforge between | `mindforge active --show` prints the same spelling both times (#65 item 4) | |

## Verdict

- A all ✅ → the AUR gets 0.1.9-1 (one push).
- B: each ❌ becomes a finding (W-15, …) on GitHub; B passing closes #15, #21, #38 and #65.
