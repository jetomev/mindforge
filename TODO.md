# mindForge — the list

**Current release: v0.1.7** (6 Oct 2026) — the tie alert and the chime (#45), and `scripts/release.sh` (#41).
**Tests:** `bash testing/run-tests.sh`, 180 checks, all passing (6 Oct 2026). **Release with `bash scripts/release.sh X.Y.Z`** after the docs commit.
mindForge is the start-of-session briefing and end-of-session record for working with an AI companion. It tells each new session what happened last time and what is still open, so nothing depends on one conversation remembering.

**Updated after every step.** The full story behind each item is in its GitHub issue.

---

## Next up — in this order

### 1 · Windows support (the work laptop)
- [ ] **#15** · Default memory folder is wrong on Windows.
- [ ] **#17** · The install instructions assume Linux.
- [ ] **#18** · Project folders outside the configured list (synced folders) are invisible.
- [ ] **#19** · Auto mode will not let the assistant install hooks — the install has to be designed around that.
- [ ] **#20** · Desktop notifications are Linux-only, and that isn't documented.
- [ ] **#21** · The PowerShell wrapper breaks quoted text, so `wrap` and `drift` record the wrong thing.
- [ ] **#34** · The same project is counted twice on Windows because of two spellings of the drive path.

- [ ] **#43** · W-11 (filed from the laptop 2026-10-05 after it pulled v0.1.6): R11 names every queued project as missing there (junctions to Dropbox folders, same family as #34), and the eleven `release.sh` checks fail without saying why. Suite there: 160 checks, 145 pass. To fix here.

### 1b · Asked by the maintainer (2026-10-06)
- [x] **#45** · `mindforge tone` (the tie alert, a Stop hook) and `mindforge chime` — shipped in v0.1.7 the same day. Design fix, not a reminder: the tone rule had lost to the app's built-in report style all afternoon
- [ ] **#44** · `mindforge <project>` — the brief, reduced to one project or initiative (header, phase table + NEXT items with comments, its queue and rot lines, a recommendation). Today the command prints the usage text.

### 2 · Lessons about the method (mostly writing, some design)
- [ ] **#23** · The scoped persona leaked a third time, through the vault, which the commit check cannot reach.
- [ ] **#25** · A warning written in a decision document does not reach the script that needs it.
- [ ] **#26** · A script counted what it would destroy, printed it, and destroyed it anyway.
- [ ] **#28** · The one-slot handoff note is maintained by nothing — the same failure as the old queue file.
- [ ] **#37** · S-10: the active-project banner is maintained by nothing — it announced DecadeDrop at the start of a hypeForge session (found 2026-09-29).
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
- [ ] **#42 · AUR twins whose package name differs from the repo name are not matched.** R11 named `aur-python-forgekit` (commits that day) because the twin rule strips `aur-` and looks for a queue repo called `python-forgekit`; the project is `forgekit`. Options: a `@twin aur-python-forgekit forgekit` directive, or read `pkgname`/`url` from the twin's PKGBUILD. Until then, `@quiet aur-python-forgekit` is the visible workaround (**in the queue since 2026-10-01 evening; issue #42**)

## Release incident, v0.1.6 (2026-10-01)
- [x] A refused commit was followed by a tag and a push anyway (the tag + push sat on the line after a heredoc). v0.1.6 public on the wrong commit for minutes; re-tagged with the maintainer's OK. **Fixed by design: `scripts/release.sh` (#41)**, which refuses before tagging unless tree clean, main current, VERSION + changelog match, tag new, tests pass. 14 checks; three planted broken copies each caught

## After the work laptop pulls
- [x] On the laptop: `git pull --rebase origin main` (brings v0.1.6), then `bash testing/run-tests.sh` there too. **Done 2026-10-05** (fast-forward to `832685d`): 160 checks, 145 pass; the 15 failures and the R11 false alarms are **#43**
