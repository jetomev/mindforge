# mindForge — the list

**Current release: v0.1.8** (12 Oct 2026) — the 0.1.8 batch: #63, #43 (+#34), #42, #37. GitHub Release Latest with signed files; AUR `mindforge` 0.1.8-1 pushed (`d241414`) after the maintainer's local install test.
**Tests:** `bash testing/run-tests.sh`, 210 checks, all passing (12 Oct 2026). **Release with `bash scripts/release.sh X.Y.Z`** after the docs commit.
mindForge is the start-of-session briefing and end-of-session record for working with an AI companion. It tells each new session what happened last time and what is still open, so nothing depends on one conversation remembering.

**Updated after every step.** The full story behind each item is in its GitHub issue.

---

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
- [ ] **#15** · Default memory folder is wrong on Windows.
- [ ] **#17** · The install instructions assume Linux.
- [ ] **#18** · Project folders outside the configured list (synced folders) are invisible.
- [ ] **#19** · Auto mode will not let the assistant install hooks — the install has to be designed around that.
- [ ] **#20** · Desktop notifications are Linux-only, and that isn't documented.
- [ ] **#21** · The PowerShell wrapper breaks quoted text, so `wrap` and `drift` record the wrong thing.
- [ ] **#65** · W-14 (laptop, 2026-10-19): 0.1.8's suite is 197/218 there, almost all the test harness on Windows — Git Bash's `ln -s` makes a copy (12, incl. the release.sh mystery from #43), MSYS paths reach Windows python (tone ×7), a test leaves a `%SystemDrive%` folder in the repo, the active pointer saved in two spellings (1, a real small one). The live tool runs clean.
- [ ] **#38** · W-10: the parallel-lookup timing check fails on the laptop every run (still failing in #65).
- [ ] **#64** · The PKGBUILD: python belongs in `checkdepends`, since `check()` runs the tie-alert tests.
- [x] **#34** · The same project is counted twice on Windows — fixed in 0.1.8 with #43 (same cause).

- [x] **#43** · W-11: fixed in 0.1.8 (the R11 part). The eleven `release.sh` failures on the laptop are still unexplained — the harness now prints what a failing check saw, so the next laptop run can tell us.

### 1b · Asked by the maintainer (2026-10-06)
- [x] **#45** · `mindforge tone` (the tie alert, a Stop hook) and `mindforge chime` — shipped in v0.1.7 the same day. Design fix, not a reminder: the tone rule had lost to the app's built-in report style all afternoon
- [ ] **#44** · `mindforge <project>` — the brief, reduced to one project or initiative (header, phase table + NEXT items with comments, its queue and rot lines, a recommendation). Today the command prints the usage text.

### 2 · Lessons about the method (mostly writing, some design)
- [ ] **#23** · The scoped persona leaked a third time, through the vault, which the commit check cannot reach.
- [ ] **#25** · A warning written in a decision document does not reach the script that needs it.
- [ ] **#26** · A script counted what it would destroy, printed it, and destroyed it anyway.
- [ ] **#28** · The one-slot handoff note is maintained by nothing — the same failure as the old queue file.
- [x] **#37** · S-10: the active-project banner — `mindforge active` in 0.1.8.
- [x] **#46** · W-12: the brief's NEXT column cut at 42 characters mid-word, and the hook's short brief didn't say it was short — fixed 2026-10-13 (width follows the terminal, cut at a word with …, nothing cut off a terminal; the hook brief names what it leaves out and the directive says to run the full one when asked). Unreleased.
- [ ] **#47** · R8 cannot see stale queue rows: 8 of 18 rows opt out with `-` and are never checked again, and a row whose reference is still open passes even when its sentence lists finished work (found 2026-10-08: forgekit said 0.8.0, hypeForge listed done jobs). Ideas: compare a row's "X.Y.Z shipped" with the newest tag; `wrap` asks "still true?" for every project touched.
- [ ] **#30** · A relayed handoff carried one machine's way of working to another.
- [ ] **#31** · The test-matrix advice about sandboxes behaves differently on every machine.

---

## Waiting on a decision
- [ ] **The terminal copy of the briefing (F-26)** never appears, in the terminal or in Desktop. Find out why, or delete it.
- [ ] **One GitHub issue per finding from the v0.1.2/v0.1.3 test round** — deliberately held back; still on hold.

## Known gaps (no issue yet)
- [x] ~~The rot checks only look at projects the queue names.~~ **Closed by R11 in v0.1.6 (#39):** a repo with commits in the last 14 days and no queue line is named; `@quiet` is the visible opt-out. Found when the queue sat untouched from 29 Sep to 1 Oct and hypeForge, worked on all four days, never appeared in the brief
- [x] ~~A queue name longer than 20 characters pushes its row out of line~~ **Fixed in v0.1.6 (#40)**
- [ ] **R11's first real finding, for the maintainer:** `homelab` (commits 28 Sep) has no queue line. Add it with its next step, or put it on an `@quiet` line

## R11 false alarm (2026-10-01)
- [x] **#42 · fixed in 0.1.8** (the twin rule strips `python-` too, and matches the queue's names, so a monorepo sub-project's twin counts). Was: **AUR twins whose package name differs from the repo name are not matched.** R11 named `aur-python-forgekit` (commits that day) because the twin rule strips `aur-` and looks for a queue repo called `python-forgekit`; the project is `forgekit`. Options: a `@twin aur-python-forgekit forgekit` directive, or read `pkgname`/`url` from the twin's PKGBUILD. Until then, `@quiet aur-python-forgekit` is the visible workaround (**in the queue since 2026-10-01 evening; issue #42**)

## Release incident, v0.1.6 (2026-10-01)
- [x] A refused commit was followed by a tag and a push anyway (the tag + push sat on the line after a heredoc). v0.1.6 public on the wrong commit for minutes; re-tagged with the maintainer's OK. **Fixed by design: `scripts/release.sh` (#41)**, which refuses before tagging unless tree clean, main current, VERSION + changelog match, tag new, tests pass. 14 checks; three planted broken copies each caught

## After the work laptop pulls
- [x] On the laptop: `git pull --rebase origin main` (brings v0.1.6), then `bash testing/run-tests.sh` there too. **Done 2026-10-05** (fast-forward to `832685d`): 160 checks, 145 pass; the 15 failures and the R11 false alarms are **#43**
