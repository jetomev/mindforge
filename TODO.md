# mindForge — the list

**Current release: v0.1.3** (30 Aug 2026). **Not yet released:** 9 changes, including fixes #13, #14, #22, #33 and #36 and the first automatic tests.
**Tests:** `bash testing/run-tests.sh`, 71 checks, all passing (29 Sep 2026).
mindForge is the start-of-session briefing and end-of-session record for working with an AI companion. It tells each new session what happened last time and what is still open, so nothing depends on one conversation remembering.

**Updated after every step.** The full story behind each item is in its GitHub issue.

---

## Next up — in this order

### 1 · Release v0.1.4
- [ ] Changelog entries for everything since v0.1.3: R8 (queue checked against GitHub, #13), the missing-queue first run (#14), R9 (memory index too big to load), every project folder scanned (#33), projects sharing a priority tier, the test script (#35), the `wrap` fixes (#22), and Windows line endings in the queue file (#36).
- [ ] Version bump in every place it appears, README checked top to bottom, test count reported.
- [ ] Signed tag, GitHub Release with full notes, set as Latest.

### 2 · Records that say something false, or failures that stay quiet
- [ ] **#27** · `wrap` says a session is finished without checking that it is — two false wraps in one session.
- [ ] **#24** · A check that cannot run reports "nothing found" instead of "could not check".
- [ ] **#29** · The briefing prints a line labelled "rot" that is not the rot check, so a real warning fired all night unseen.
- [ ] **#16** · The briefing never says when the session hooks are missing, so the handoff quietly stops working.

### 3 · Windows support (the work laptop)
- [ ] **#15** · Default memory folder is wrong on Windows.
- [ ] **#17** · The install instructions assume Linux.
- [ ] **#18** · Project folders outside the configured list (synced folders) are invisible.
- [ ] **#19** · Auto mode will not let the assistant install hooks — the install has to be designed around that.
- [ ] **#20** · Desktop notifications are Linux-only, and that isn't documented.
- [ ] **#21** · The PowerShell wrapper breaks quoted text, so `wrap` and `drift` record the wrong thing.
- [ ] **#34** · The same project is counted twice on Windows because of two spellings of the drive path.

### 4 · Lessons about the method (mostly writing, some design)
- [ ] **#23** · The scoped persona leaked a third time, through the vault, which the commit check cannot reach.
- [ ] **#25** · A warning written in a decision document does not reach the script that needs it.
- [ ] **#26** · A script counted what it would destroy, printed it, and destroyed it anyway.
- [ ] **#28** · The one-slot handoff note is maintained by nothing — the same failure as the old queue file.
- [ ] **#30** · A relayed handoff carried one machine's way of working to another.
- [ ] **#31** · The test-matrix advice about sandboxes behaves differently on every machine.

---

## Waiting on a decision
- [ ] **The terminal copy of the briefing (F-26)** never appears, in the terminal or in Desktop. Find out why, or delete it.
- [ ] **One GitHub issue per finding from the v0.1.2/v0.1.3 test round** — deliberately held back; still on hold.

## Known gaps (no issue yet)
- [ ] The rot checks only look at projects the queue names. A project nobody adds to the queue is never checked.

## After the work laptop pulls
- [ ] On the laptop: `git pull --rebase origin main`, then `bash testing/run-tests.sh` there too.
