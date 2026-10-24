# mindForge — the list

**Current release: v0.1.10** (19 Oct 2026) — everything open except v0.2.0 (#44 #47 #28 #23 #25 #26 #30), the same evening as **v0.1.9**, the laptop batch (#65 #38 #15 #31 #18 #19 #21 #17 #20 #64 #66). Both: GitHub Release with signed files, v0.1.10 Latest. **AUR: 0.1.10-1 pushed (`968bcd9`) after the maintainer's install test** (`testing/20261019 - Test Matrix for mindForge v0-1-10.md`, part A, all pass).
**Tests:** `bash testing/run-tests.sh`, 293 checks, all passing, 1 could not look on Linux (19 Oct 2026). **Release with `bash scripts/release.sh X.Y.Z`** after the docs commit.
mindForge is the start-of-session briefing and end-of-session record for working with an AI companion. It tells each new session what happened last time and what is still open, so nothing depends on one conversation remembering.

**Updated after every step.** The full story behind each item is in its GitHub issue.

---
## Found 2026-10-22 — the CLAUDE.md review
*Spotted while writing this project's CLAUDE.md; the maintainer asked for them on the board.*
- [ ] **README tells people to copy `scrub.example`**, which doesn't exist in the repo: add the example file or fix the line

## 2026-10-22 · Boards (unreleased)
- [x] **Every project's page beside the chat** (the maintainer: *"for all projects we have, the same page… opened as soon as we call a project"*): `boards/board.py` (build · status · pull) + `boards/board.html`; `mindforge active` and the one-project brief open the board first; 24 project boards published and filled from their TODO.md; checks 293 → 298 (the new ones seen failing on the old build)
- [x] CLAUDE.md for mindForge itself (it had none)
- [x] **Pending · Finished · All** on every board (`5750511`, 10-22: the maintainer asked after the KognogOS board had them): three buttons on top, the choice remembered per board
- [x] **Badges from another board** (`de463cc`, 10-22): `board.py build --badges <file>` puts "KognogOS 1.0 · stage NN" on the steps the road waits on; steps written above a TODO's first heading go into a stage called "Now". 300 checks
- [ ] **Ship it in the next version** (0.1.11 or 0.2.0): `boards/` in the AUR recipe, the README's own Boards section, `board.py pull` used at every wrap so ticks made on a page reach TODO.md

## 2026-10-19 · v0.1.9 + v0.1.10
- [x] **The issue review** (the maintainer asked): 25 open; #65 #38 #64 were missing from this list.
- [x] **v0.1.9** tagged `3a7dca3`, Release with signed files; five issues closed (#17 #18 #19 #20 #31), four commented and left open for the laptop (#15 #21 #38 #65); #66 opened (the recipe's license).
- [x] **v0.1.10** tagged `1b0d75e`, Release Latest with signed files; seven issues closed (#23 #25 #26 #28 #30 #44 #47).
- [x] **Clean-chroot builds** of 0.1.9-1 and 0.1.10-1 in the KognogOS VM: 258 and 293 checks pass; python comes in through the new checkdepends. Found on the way: nog F-20 #56 (`nog update` has no `--yes`).
- [x] **The maintainer's install test of 0.1.10-1** passed 18:26–18:32 (part A, A9 = a fresh session's briefing with R1-R12) → **AUR 0.1.10-1 pushed `968bcd9`** (one push, with 0.1.9-1 `5ed2124`) → #64 and #66 closed. 12 issues open, all v0.2.0 or waiting for the laptop.
- [ ] **The laptop's run** (the v0.1.9 matrix, part B, on 0.1.10) → closes #15 #21 #38 #65, or files W-15…
- [ ] **#67** · `wrap --previous` closed a 2-minute churn row (the maintainer's A9 test session) instead of the 17:43–18:32 session the brief named (found 2026-10-19 18:36; repaired with `log --drop-last`). Shape: print the row before closing it, refuse one shorter than 30 min unless `--row <date> <start>` names it. Next version.
- [ ] **R12 should skip `archive_index_*` files** like R4 and R7 do: an archived copy of a handoff file that still declares `rewritten_by: session` would be flagged forever (found 2026-10-19 while archiving the real one; the archive's line was removed by hand). Next version.
- [ ] **The seven older vault notes** `mindforge scrub --vault` lists: the maintainer judges each; one cleared is added to its term's line in scope.txt.

## 2026-10-12 · The 0.1.8 batch
- [x] **2026-10-17 · `mindforge active <path>` prints the summary too** (the maintainer: "summarized project table, always, when I am calling a project. Many times now."): switching used to print only the path, so the table showed only at session start and Claude kept skipping it. Now the switch prints the banner (a project just chosen is no disagreement with the last wrap). Checks 216 → 218; the new one seen failing on the old code. Live at once (the installed `mindforge` is this repo's bin); ships with 0.1.9
- [x] **#63** · W-13: the tie alert on Windows — `python3` is the Store placeholder; `tone` now keeps the first python that runs (`python3`, `python`, `py -3`)
- [x] **#43** · W-11: R11 named every queued project as missing on the laptop — one repo under two spellings of its path; compared in git's spelling now. **#34** (repo counted twice) was the same line of code and went with it
- [x] **#42** · `aur-python-<name>` is the AUR twin of `<name>` (forgekit's `@quiet` workaround can go)
- [x] **#37** · S-10: `mindforge active` replaces the personal hook; `wrap` moves the pointer; a disagreement with the last wrapped session is said on screen. This desktop's hook rewired, the 09-23 pointer file moved into the state folder
- [x] The harness prints the first lines a failing check saw (the laptop's #43 report had nothing to reason from)
- [x] **Release:** the maintainer's live test passed (banner + rot check), `release.sh 0.1.8` tagged `84521d4`, GitHub Release Latest with the signed tarball, five issues closed, topics `aur` + `aur-package` added
- [x] **AUR 0.1.8-1:** built locally AND in a clean chroot (210 checks in check() both times), installed and run by the maintainer, then pushed (`d241414`). Found on the way: python should be a checkdepends (issue filed); the KognogOS os-release hook errors inside any chroot (KognogOS #16)

## 2026-10-11 · What it needs, measured
- [x] **What it needs, measured** (2026-10-11, the Forge Suite audit): `docs/PACKAGING.md`; the AUR recipe 0.1.7-1 builds clean in a clean Arch system (180 checks) and matches the code

## Done 2026-10-09
- [x] **On the AUR, 2026-10-09:** signed files added to the v0.1.7 release; `mindforge` 0.1.7-1 built locally (180/180 checks in check()), installed and tested, then pushed; starting files in `/usr/share/mindforge`; the AUR description says where it runs

## Big next version — v0.2.0 "one brain on every machine, for every AI" (#61)
**Not now.** The maintainer's order (2026-10-08): KognogOS + hypeForge first, then DecadeDrop. The folder cleanup comes "soon"; the rest follows. Joined with ai-collab #3. Born from a 29-page research handoff (kept privately) and the 10-08 discussion; the full design is in #61.
Decided: Option 1 (one Claude only on a server) is out as the place we work · live sync, not git, for the brain · bring your own sync app, mindForge makes it safe · share 100%, machine rules labeled · cover the gaps Anthropic leaves, do not rebuild what exists · built for strangers too (Windows is the gate, macOS untested, nothing of ours hardcoded).
- [ ] **#60** · The brain's folder layout (first; the maintainer's home folder cleanup is the first case, approved before anything moves).
- [ ] **#55** · Two sessions at once hide each other: one log and one handoff per machine and per project.
- [ ] **#56** · Make any sync app safe: conflict copies, a brain that is behind, build junk.
- [ ] **#57** · Rules name their machine ("this desktop" means another computer once shared).
- [ ] **#58** · Readable by any AI: a doorway file per tool; others write only to an inbox (ai-collab #3).
- [ ] **#59** · The third brain: an always-on assistant that proposes, never edits.
- [ ] **#62** · Found the same night: the scrub guard sees commits only; issues, comments and release notes go out unchecked (seven issues had to be deleted and recreated). Fix before v0.2.0 makes the brain public-facing.
- Open: where the hub lives (home server preferred over the internet-facing one), whether the work laptop joins and with what slice, which sync app.

## Next up — in this order

### 1 · Windows support (the work laptop)
- [x] **#15** · Default memory folder is wrong on Windows — fixed in 0.1.9 (cygpath -w + Claude Code's rule); closes on the laptop's run (matrix B4).
- [x] **#17** · The install instructions assume Linux — a Windows section in the README, 0.1.9.
- [x] **#18** · Synced-folder repos — a repo can be a root itself, spaces and apostrophes tested; R1/R2 read roots with spaces, 0.1.9.
- [x] **#19** · Hooks under auto mode — `mindforge hooks --print | --check`, the person pastes the block, 0.1.9.
- [x] **#20** · Notifications Linux-only — documented in the Windows section, 0.1.9 (a Windows toast stays an idea, not built).
- [x] **#21** · The PowerShell wrapper — `bin/mindforge.ps1`, 0.1.9; its check runs where PowerShell is (matrix B7).
- [x] **#65** · W-14 (laptop, 2026-10-19): 0.1.8's suite is 197/218 there, almost all the test harness on Windows — Git Bash's `ln -s` makes a copy (12, incl. the release.sh mystery from #43), MSYS paths reach Windows python (tone ×7), a test leaves a `%SystemDrive%` folder in the repo, the active pointer saved in two spellings (1, a real small one). The live tool runs clean. **Fixed in 0.1.9**; the laptop's run closes it (matrix B2, B5).
- [x] **#38** · W-10: the parallel-lookup timing check fails on the laptop every run (still failing in #65). **Fixed in 0.1.9**; the laptop's run closes it (matrix B2, B5).
- [x] **#64** · The PKGBUILD: python belongs in `checkdepends`, since `check()` runs the tie-alert tests. **Fixed in 0.1.9** (+ #66, the recipe's license said GPL3).
- [x] **#34** · The same project is counted twice on Windows — fixed in 0.1.8 with #43 (same cause).

- [x] **#43** · W-11: fixed in 0.1.8 (the R11 part). The eleven `release.sh` failures on the laptop are still unexplained — the harness now prints what a failing check saw, so the next laptop run can tell us.

### 1b · Asked by the maintainer (2026-10-06)
- [x] **#45** · `mindforge tone` (the tie alert, a Stop hook) and `mindforge chime` — shipped in v0.1.7 the same day. Design fix, not a reminder: the tone rule had lost to the app's built-in report style all afternoon
- [x] **#44** · `mindforge <project>` — the brief, reduced to one project or initiative (header, phase table + NEXT items with comments, its queue and rot lines, a recommendation). Today the command prints the usage text. **— fixed in 0.1.10: `mindforge <project>` / `brief <project>`.**

### 2 · Lessons about the method (mostly writing, some design)
- [x] **#23** · The scoped persona leaked a third time, through the vault, which the commit check cannot reach. **— fixed in 0.1.10: `scope.txt` + the vault scrub in wrap + `mindforge scrub --vault`.**
- [x] **#25** · A warning written in a decision document does not reach the script that needs it. **— fixed in 0.1.10: `HAZARD:` lines in the project brief + `mindforge hazards`; METHOD §10.**
- [x] **#26** · A script counted what it would destroy, printed it, and destroyed it anyway. **— fixed in 0.1.10: METHOD §9 + `templates/rules/scripts.md`.**
- [x] **#28** · The one-slot handoff note is maintained by nothing — the same failure as the old queue file. **— fixed in 0.1.10: R12 + wrap, `rewritten_by: session` declared on the real handoff file.**
- [x] **#37** · S-10: the active-project banner — `mindforge active` in 0.1.8.
- [x] **#46** · W-12: the brief's NEXT column cut at 42 characters mid-word, and the hook's short brief didn't say it was short — fixed 2026-10-13 (width follows the terminal, cut at a word with …, nothing cut off a terminal; the hook brief names what it leaves out and the directive says to run the full one when asked). Unreleased.
- [x] **#47** · R8 cannot see stale queue rows: 8 of 18 rows opt out with `-` and are never checked again, and a row whose reference is still open passes even when its sentence lists finished work (found 2026-10-08: forgekit said 0.8.0, hypeForge listed done jobs). Ideas: compare a row's "X.Y.Z shipped" with the newest tag; `wrap` asks "still true?" for every project touched. **— fixed in 0.1.10: R8 checks shipped versions against tags on every row; wrap asks about the rows of projects with commits.**
- [x] **#30** · A relayed handoff carried one machine's way of working to another. **— fixed in 0.1.10: METHOD §11, `templates/handoff.md.template`, the L0 template line.**
- [x] **#31** · The sandbox advice — an explicit export now beats the config (vault included), tested both ways, 0.1.9.

---

## Waiting on a decision
- [x] **The terminal copy of the briefing (F-26)** — the maintainer: investigate or delete (2026-10-19). Found why: no controlling terminal (Desktop's processes show TT `?`, `/dev/tty` fails to open; a terminal's full-screen interface owns the screen). **Deleted**; in the Unreleased changelog.
- [ ] **One GitHub issue per finding from the v0.1.2/v0.1.3 test round** — deliberately held back; still on hold.

## Known gaps (no issue yet)
- [x] ~~The rot checks only look at projects the queue names.~~ **Closed by R11 in v0.1.6 (#39):** a repo with commits in the last 14 days and no queue line is named; `@quiet` is the visible opt-out. Found when the queue sat untouched from 29 Sep to 1 Oct and hypeForge, worked on all four days, never appeared in the brief
- [x] ~~A queue name longer than 20 characters pushes its row out of line~~ **Fixed in v0.1.6 (#40)**
- [x] **R11's first real finding:** `homelab` had no queue line — **it has one now** (checked 2026-10-19).

## R11 false alarm (2026-10-01)
- [x] **#42 · fixed in 0.1.8** (the twin rule strips `python-` too, and matches the queue's names, so a monorepo sub-project's twin counts). Was: **AUR twins whose package name differs from the repo name are not matched.** R11 named `aur-python-forgekit` (commits that day) because the twin rule strips `aur-` and looks for a queue repo called `python-forgekit`; the project is `forgekit`. Options: a `@twin aur-python-forgekit forgekit` directive, or read `pkgname`/`url` from the twin's PKGBUILD. Until then, `@quiet aur-python-forgekit` is the visible workaround (**in the queue since 2026-10-01 evening; issue #42**)

## Release incident, v0.1.6 (2026-10-01)
- [x] A refused commit was followed by a tag and a push anyway (the tag + push sat on the line after a heredoc). v0.1.6 public on the wrong commit for minutes; re-tagged with the maintainer's OK. **Fixed by design: `scripts/release.sh` (#41)**, which refuses before tagging unless tree clean, main current, VERSION + changelog match, tag new, tests pass. 14 checks; three planted broken copies each caught

## After the work laptop pulls
- [x] On the laptop: `git pull --rebase origin main` (brings v0.1.6), then `bash testing/run-tests.sh` there too. **Done 2026-10-05** (fast-forward to `832685d`): 160 checks, 145 pass; the 15 failures and the R11 false alarms are **#43**
