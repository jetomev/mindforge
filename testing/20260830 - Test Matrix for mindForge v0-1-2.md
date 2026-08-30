# Test Matrix — mindForge v0.1.2

**Run date:** 2026-08-30
**Build under test:** `mindforge 0.1.2` (`~/.local/bin/mindforge` → `~/Programs/mindforge/bin/mindforge`)
**Tester:** Claude (sandboxed sections) · the maintainer (live sections §4.7, §4.8, §10)
**Why this exists:** twelve findings shipped across three releases in one day, every one
verified by hand and none by a suite. This matrix is the specification that was missing.
Automating it is the next step — a check that cannot be written down cannot be automated.

## How to run

Work top to bottom. Fill the **Result** column with `PASS`, `FAIL`, or `N/A` and put
anything surprising in **Notes** — a surprise that is not written down did not happen.
Findings become issues titled `F-n: <description>` carrying the full entry.

**Sandbox everything that writes.** Unless a check says *live*, export a throwaway state
directory first so a failed check cannot corrupt the real log:

```
export MINDFORGE_STATE=/tmp/mf-test; rm -rf $MINDFORGE_STATE; mkdir -p $MINDFORGE_STATE
printf '# hdr\n' > $MINDFORGE_STATE/sessions.log
cp ~/.claude/state/queue.md ~/.claude/state/rules.txt $MINDFORGE_STATE/
```

Open a **new terminal** for the live checks so the sandbox variable is gone.

**Never hand-tally the roll-up** (M-4). Run `python3 testing/tally-matrix.py` — with no
argument it picks up the newest matrix in `testing/`. It counts from the tables themselves and
**stops rather than guesses**: a verdict it has not been taught exits 1 and names the cell.

---

## §1 · Identity and install

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 1.1 | `mindforge --version` | `mindforge 0.1.2` | PASS | |
| 1.2 | `mindforge -V` | same as 1.1 | PASS | |
| 1.3 | `mindforge nonsense` | usage block, exit 2 | PASS | |
| 1.4 | usage lists `wip`, `--version` | both present | PASS | |
| 1.5 | `ls -l ~/.local/bin/mindforge` | symlink into `~/Programs/mindforge/bin/` | PASS | |
| 1.6 | `bash -n bin/mindforge` | silent | PASS | |
| 1.7 | installed version == `git describe --tags` | both `v0.1.2` | PASS | Both say v0.1.2 — but the symlink targets a DIRTY tree carrying the F-13 fix. --version cannot tell tag from working copy. See F-24. |

## §2 · Brief — core rendering

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 2.1 | `mindforge brief` | all sections render, no shell errors | PASS | |
| 2.2 | `mindforge brief --headline` | 3–4 lines only, no table | PASS | Renders 3 lines here. Expectation '3-4 lines' is stale post-F-13: headline is now up to 5 (date, last, dirty, in flight, scope). |
| 2.3 | headline date/time | matches `date` | PASS | |
| 2.4 | `Last time` panel | date, focus, bullets from last **wrapped** row | PASS | |
| 2.5 | with zero wrapped rows ever | `Last time` omitted, no crash | PASS | |
| 2.6 | `Projects` table | one row per `queue.md` entry, none missing | PASS | 6 queue entries, 6 table rows, none missing. |
| 2.7 | `Recommended first` | nog outranks Forge apps (@priority ×10) | PASS | |
| 2.8 | `State` counts | memory files, L0 lines, L1 domains plausible | PASS | 43 files / 51 L0 lines / 4 L1 domains — all match independent counts exactly. |
| 2.9 | one working rule printed | one line from `rules.txt` | PASS | |
| 2.10 | run twice in a row | identical output apart from the clock | PASS | |

## §3 · Session lifecycle — F-4, F-7

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 3.1 | `CLAUDE_CODE_SESSION_ID=aaa mindforge session-start` | `marks/aaa` created | PASS | |
| 3.2 | then `…ID=bbb session-start` | **both** `aaa` and `bbb` exist | PASS | |
| 3.3 | `…ID=aaa session-end` | only `aaa` removed; `bbb` survives | PASS | |
| 3.4 | rows logged after 3.3 | **0** — session was under the floor | PASS | |
| 3.5 | backdate a mark 40 min, then `session-end` | 1 row, real duration | PASS | Row logged 08:10-08:50, real 40-minute duration. |
| 3.6 | `MINDFORGE_MIN_SESSION_MIN=0`, 0-min session-end | row **is** written | PASS | |
| 3.7 | corrupt mark (`printf 'garbage\tnottime\n'`), `session-end` | row written with a **valid** date | PASS | |
| 3.8 | headline after 3.7 | renders cleanly, no `date: invalid date` | PASS | |
| 3.9 | legacy `.session-start` present, then `session-start` | migrated into `marks/`, legacy gone | PASS | |
| 3.10 | mark aged 20h, then `session-start` | swept, not selected | PASS | |
| 3.11 | `MINDFORGE_MARK_TTL_H=1`, mark aged 2h | swept | PASS | |
| 3.12 | `wrap` with **no** session id set | uses the **oldest** mark | PASS | |
| 3.13 | `wrap` with no marks at all | still logs; start == end; no crash | PASS | |
| 3.14 | `wrap` | removes the mark it consumed | PASS | |
| 3.15 | `wrap` with unpushed commits | warns and names the repo | PASS | Warns and names the repo correctly — but wrap then exits 1. See F-17. |
| 3.16 | `wrap` with everything pushed | `all repos pushed` | PASS | |

## §4 · Visible channel — F-8

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 4.1 | `session-start` with stamp cleared | exactly **one** popup | PASS | |
| 4.2 | second `session-start` immediately | **no** popup; stamp unchanged | PASS | |
| 4.3 | `MINDFORGE_NOTIFY_GAP_S=0` | popup fires again | PASS | |
| 4.4 | popup content | title + the two headline lines, **no ANSI escapes** | PASS | Title + body, zero ANSI escapes (verified with cat -v). Body is headline minus line 1 — now 3 lines post-F-13, so 'the two headline lines' is stale. |
| 4.5 | urgency | normal — must **not** persist until dismissed | PASS | |
| 4.6 | `PATH=/nonexistent session-start` (no `notify-send`) | hook still succeeds, silent | PASS | Passes on intent, via a PATH holding the full toolchain minus notify-send: exit 0, silent, mark still created. The check AS WRITTEN is defective — PATH=/nonexistent also removes date, git and grep, giving exit 127 that says nothing about notify-send. See M-1. |
| 4.7 | `DBUS_SESSION_BUS_ADDRESS` stripped | still delivers | PASS | Terminal surface, 2026-08-30 09:18, confirmed by the maintainer on screen. notify-send located the bus by itself with the variable unset. exit 0, stamp written, mark created. Desktop cell still open — see 11.4. |
| 4.8 | *live* — close/open Desktop | **one** popup for ~3 spawned sessions | **PASS (observable)** | the maintainer restarted the Desktop at ~15:0x on 2026-08-30 and saw exactly **one** popup; reported 16:33. Third cold launch counted this way (08:47, 10:10, 15:0x) and one popup every time. The `~3 spawned sessions` half of the expectation is stale on this build (F-28): one session spawns per launch, so the rate limit had nothing to suppress and is still untested on its actual purpose. Same standing as 11.4 — the popup behaviour is confirmed, the limit is not. |

## §5 · Scope line — F-9

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 5.1 | `persona.txt` present | `scope:` line ends the headline | PASS | |
| 5.2 | `persona.txt` absent | line omitted, no error | PASS | |
| 5.3 | multi-line `persona.txt` | only the first line printed | PASS | |
| 5.4 | empty `persona.txt` | no crash | FAIL | No crash, so the letter of the check passes — but an empty file prints a bare 'scope:' label with no scope. Content is never validated. See F-18. |
| 5.5 | scope line appears in `--headline` | yes — it must reach injected context | PASS | |
| 5.6 | `persona.example` in repo | placeholders only, **no real names** | PASS | persona.example holds placeholders only. Repo-wide git grep for the persona names is clean across all tracked files. |

## §6 · Rot checks — F-2, F-10

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 6.1 | `mindforge rot` twice | `rot.log` line count **unchanged** | PASS | |
| 6.2 | R1 | PKGBUILD version vs latest tag | PASS | |
| 6.3 | R2 | root PKGBUILD vs AUR twin — still fires for nog | PASS | Still fires for nog — two R2 lines, source and validpgpkeys. |
| 6.4 | R3 | unpushed commits named | PASS | |
| 6.5 | R4 | memory file with no index line is named | PASS | |
| 6.6 | R5 | L0 over 60 lines | PASS | Fires at 70 lines against the 60-line budget. |
| 6.7 | R6 | queue names a project that is not there | PASS | |
| 6.8 | R7 — index newer than files | silent | PASS | |
| 6.9 | R7 — file newer than index | fires, names the file | PASS | |
| 6.10 | R7 ignores `MEMORY.md`, `archive_index_*` | not self-reported | PASS | |
| 6.11 | three-strikes escalation | promotes only on **sessions**, not reads | PASS | Escalates at 3 distinct days; six extra reads the same day did not inflate it. Note the unit is DAYS, though the label reads 'sessions'. See F-23. |

## §7 · Projects table — F-3, F-11

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 7.1 | clean repo, no dependency | `clean` | PASS | |
| 7.2 | clean repo, `blocks:` | `clean clears` — dirt not masked | PASS | |
| 7.3 | clean repo, `waits:` | `clean waits` | PASS | |
| 7.4 | dirty repo **with** a dependency | shows `dirty`, not only the label | PASS | Shows 'dirty 1f +2/-0 clears' — dirt is not masked by the dependency label. |
| 7.5 | tracked edits | `dirty Nf +i/-d`, numbers correct | PASS | |
| 7.6 | untracked only | `dirty N?` | PASS | |
| 7.7 | both | both fragments shown | PASS | |
| 7.8 | queue entry with no repo on disk | `no repo`, no crash | FAIL | 'no repo' appears in the LAST column, but STATE reads a green 'clean'. A project absent from disk is reported as clean. See F-19. **Re-verified on Desktop 2026-08-30 14:5x against the post-F-32 build:** STATE now reads `absent` in red, LAST reads a dim `no repo`, no crash. Result stays FAIL because that is what the run caught — the fix is recorded in the fix tables, same convention as 5.4. |
| 7.9 | headline `N dirty` vs table | difference explained by repos absent from `queue.md` | PASS | |

## §8 · In flight — F-12

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 8.1 | `mindforge wip "note"` | stored, echoed back | PASS | |
| 8.2 | `mindforge brief` | **In flight** panel above Projects, with timestamp | PASS | |
| 8.3 | `mindforge wip` (no args) | prints the note | PASS | |
| 8.4 | `mindforge wip --show` | same as 8.3 | PASS | |
| 8.5 | `mindforge wip --clear` | removed; brief omits the panel | PASS | |
| 8.6 | `mindforge wip` with nothing set | `nothing in flight` | PASS | |
| 8.7 | `wrap` after setting a note | note **cleared automatically** | PASS | |
| 8.8 | note containing quotes / `\|` / UTF-8 | survives round-trip intact | PASS | Quotes, pipe, em-dash, UTF-8, $HOME and backticks all survive unexpanded. A literal TAB in the note silently truncates the headline. See F-22. |
| 8.9 | second `wip` call | **replaces**, does not append | PASS | |

## §9 · Robustness

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 9.1 | `sessions.log` missing | brief renders, no crash | PASS | |
| 9.2 | `queue.md` missing | brief renders or fails cleanly | FAIL | Raw shell error leaks into the Projects table and exit is still 0. Confined to full() — injected context uses headline() and stays clean. See F-20. |
| 9.3 | `rules.txt` missing | no rule line, no crash | PASS | |
| 9.4 | `$MINDFORGE_PROJECTS` empty | `0 repos clean`, no crash | PASS | |
| 9.5 | `days_since garbage` | `?`, no arithmetic error | PASS | |
| 9.6 | `MINDFORGE_VAULT` unset | vault line skipped | PASS | Vault line skipped when VAULT is empty. Note env alone cannot achieve this: config is sourced first and overwrites it. See F-21. |
| 9.7 | state dir read-only | fails loudly, does **not** corrupt | FAIL | Read path fine. Write path is silent: wip prints its success line and exits 0 while storing nothing. See F-25. |
| 9.8 | no network for the whole matrix | everything passes — brief is local-only | PASS | |
| 9.9 | `mindforge brief` under `sh` not `bash` | documented behaviour either way | N/A | /bin/sh is a symlink to bash on this box and dash is not installed, so the check cannot discriminate here. |

## §10 · Cross-instance continuity — the thesis

*This is the section the project exists for. Run it last, live, no sandbox.*

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| 10.1 | `mindforge wip "<something specific>"` | stored | **PASS** | Closed 2026-08-30 on Desktop, and it closed the whole loop rather than the storage step alone. The note was written on Terminal at 12:36; this Desktop instance received it in the injected handoff at 12:38 and stated it back **unprompted** in its first reply — including the instruction that it do so, so the note was its own fixture. 891 characters, inside F-16's 900 cap, so it arrived whole, and it rendered with its timestamp (`in flight (2026-08-30 12:36)`), so F-27 did not recur. Contrast 10.3, where this same check passed on a note that truncation had inverted. |
| 10.2 | close Desktop, reopen | one popup; brief rendered unprompted in the first reply | PASS (terminal) | Second terminal session 09:20: one popup, briefing rendered unprompted. Desktop half still open. |
| 10.3 | the fresh instance | can state the in-flight note **without being told** | PASS, with a serious caveat | It stated the note unprompted — the thesis holds. But it received a truncated note, dated it to 'yesterday', and recommended 'commit and tag' — the one action the note existed to forbid. Capability proven; fidelity failed. See F-16 and F-27. |
| 10.4 | `sessions.log` after the restart | no junk rows from churn sessions | **PASS (both)** | Terminal: exactly one row for the closed session, 09:20-09:26, real 6-minute duration. Desktop 10:10: cold launch on the fixed code added NO rows at all -- `sessions.log` tail is unchanged, last row is still the 08:47-09:44 wrap. No churn rows on either surface. Note the ~3x spawn never happened, so the floor was not actually stressed; see F-28. |
| 10.5 | `ls ~/.claude/state/marks/` | one mark per live conversation, none stomped | PASS | Two live terminal sessions, two marks, neither stomped. F-7 confirmed on the live path. |
| 10.6 | open a **second** chat alongside the first | two marks coexist | PASS | Confirmed 09:20 — ef44dfb1 (08:47) and 4384fdff (09:20) side by side. |
| 10.7 | close one of the two | only its own mark consumed | PASS | Closed 4384fdff at 09:26; it took its own mark and left ef44dfb1 untouched. F-7 confirmed on the live path in both directions. |
| 10.8 | fresh instance reads a dirty repo | reports the **shape** of the work, not just `dirty` | **FAIL** (as predicted) | Closed 2026-08-30 on Desktop. The handoff delivered `2 dirty · 0 unpushed` — a count of repositories, with no filenames and no shape. The fresh instance could not tell what the work was and ran `git status --porcelain` to find out, **bypassing mindForge entirely**; it did not reach for `mindforge brief`, the remedy the note itself predicted. That is the more useful half of the result. The shape does exist in the tool — `full()` renders `mindforge  dirty 3f +142/-14 2?` — but only in the surface a fresh instance never automatically receives. **F-14 and F-33 are one defect wearing two hats:** something that must arrive lives only in the full brief while the handoff carries a summary of it. F-33's fix is the template — what must arrive belongs in `headline()`. |
| 10.9 | `mindforge wrap` at the end | real multi-hour duration, not `HH:MM–HH:MM` identical | PASS | Logged 08:47-09:44 — a real 57-minute session, not a collapsed stamp. The mark was consumed by wrap, so the SessionEnd that follows will correctly find nothing and log no duplicate row. |
| 10.10 | brief in the next session | `Last time` shows that wrap, not an older one | **PASS** | Desktop 10:10, live. `Last time - 2026-08-30` renders the 08:47-09:44 wrap with all six bullets -- the immediately previous session, not an older one, and not the unwrapped 09:20-09:26 auto row that sits above it in the log. The final check in the file. |

## §11 · Surface parity — Terminal vs Desktop

*The maintainer's ruling, 2026-08-30: a fix is not proven until it is proven on both surfaces.*

This is not pedantry, it is the reason v0.1.1 exists. The two surfaces run different
code paths in `session_start`: the `/dev/tty` visible copy works in a terminal and is
**proven absent** on Desktop, whose hook runner has no controlling terminal. Parity
therefore rests on the injected DIRECTIVE, which is the only channel both surfaces
share. Desktop also spawns roughly three sessions per launch where a terminal spawns
one — so mark handling, the notification rate limit and the session floor are all
exercised far harder there.

Everything in §1-§9 tests logic that does not depend on the surface, and it was run
from a terminal-side shell. The checks below depend on the surface and must be filled
in **twice**. A row is not passed until both cells are.

| # | Check | Expected | Terminal | Desktop |
|---|---|---|---|---|
| 11.1 | marks created per launch | 1 in a terminal; ~3 on Desktop, none stomping another | PASS — 1 mark, 09:20 | **PREMISE IS FALSE, twice** — cold Desktop launch 08:47 created exactly ONE mark; cold Desktop launch 10:10 again created exactly ONE (`5e76be2f`, matching this session's own id). Two independent cold launches, one mark each. See F-28. |
| 11.2 | injected DIRECTIVE reaches the model | first reply opens with the briefing, unprompted, on both | PASS — 09:20, no tool calls | PASS — 08:47 opened with the rendered briefing unprompted; re-confirmed 10:10 on the fixed code, again unprompted, again with no tool calls needed to produce it |
| 11.3 | `/dev/tty` visible copy | present in a terminal; absent on Desktop and silent about it | **FAIL** — nothing on screen at a real Claude Code terminal launch, splash only | FAIL — proven absent 2026-08-29, no controlling terminal. Absent on BOTH. See F-26. |
| 11.4 | notification on launch | exactly one popup per launch on both, despite the spawn count | PASS — one popup, 09:20 | PASS — one popup at 08:47 and one popup at the 10:10 cold launch, both confirmed by the maintainer. Note this still does NOT exercise the rate limit: one session spawned each time (F-28), so there was nothing to suppress. Twice observed, and the limit remains untested on its actual purpose -- on this box the condition it guards against does not occur. |
| 11.5 | in-flight note in the injected headline (F-13) | present on both | PASS — present, but truncated; see F-16 | PASS, and now clean — the 08:47 briefing carried the line but truncated (F-16). At 10:10 on the fixed code the full 707-char note arrived whole: all three Desktop questions, the DO NOT COMMIT ruling, the matrix path and the closing 'Ask the maintainer before doing anything else'. **F-16 fix proven on Desktop.** F-27 proven with it -- the line arrived stamped `2026-08-30 09:44`, and was read as this morning rather than 'yesterday'. |
| 11.6 | `scope:` line in the injected headline (F-18 fix) | present on both, and never a comment or a blank | PASS — 09:20 | PASS — 08:47, and re-confirmed 10:10 on the fixed code: the scope line rendered in full with real content, naming both persona-scoped projects. **F-18 fix proven on Desktop.** |
| 11.7 | session floor under churn | short spawned siblings write no rows on either surface | **CANNOT DISCRIMINATE** — no churn exists to floor. A Claude Code terminal launch spawns exactly ONE session: `~/.claude/state/marks/` held a single mark (`00dcad86-…`, this session's own id) at 11:0x. Unlike the Desktop cell, this is not a stale premise about a particular build — one session per launch is what the terminal surface *is*. No short-lived sibling can exist here, so the floor has nothing to suppress. Not a pass; the check cannot fire on this surface by construction. Both columns now read CANNOT DISCRIMINATE for the same behaviour but for different reasons — see F-28. | **CANNOT DISCRIMINATE** — there was no churn to floor. The 10:10 cold launch spawned exactly one session, so no short-lived sibling existed to be suppressed. Same root cause as 11.4 and F-28: the behaviour under test does not occur on this Desktop build. Not a pass; the check simply cannot fire here. |
| 11.8 | `session_end` exit 1 on an unwritable log (new, F-25) | surfaces as a hook failure, not silence — confirm the noise is acceptable on Desktop, where it can fire ~3x per launch | **PASS** — Sandboxed run 2026-08-30 11:0x on Terminal, maintainer-typed, via the *same* `~/mindforge-sandbox.sh` at the *same* fixture path as the Desktop run, so the surface is the only variable. With `sessions.log` set read-only and a 30-minute-old mark carrying two genuine tab-separated fields (`2026-08-30^I10:59`), `session-end` printed `cannot write … -- row NOT logged` on stderr in red, **exited 1**, left rows unchanged (3 → 3) and **preserved the mark**. Identical to Desktop in every observable. The `~3x per launch` noise worry does not arise here either: one session per launch (11.7), so the failure surfaces once. Acceptable. Guard confirmed the real state byte-identical, marks unchanged. | **PASS** — Sandboxed run 2026-08-30 10:4x on Desktop via `~/mindforge-sandbox.sh` (`MINDFORGE_STATE`/`MINDFORGE_PROJECTS` redirected to a scratch dir; the script fingerprints the real state before and after and reported it byte-identical, marks unchanged). With `sessions.log` set read-only and a 30-minute-old mark, `session-end` printed `cannot write ... -- row NOT logged` on stderr in red, **exited 1**, left the row count unchanged (3 -> 3) and **preserved the mark**. The stated worry about ~3x noise does not arise: one session spawns per launch (F-28), so the failure surfaces once, not three times. Acceptable. |
| 11.9 | `wrap` | terminal only in practice — Desktop has no shell. Confirm that is acceptable, or wrap needs another trigger | **PASS** — and this is the surface where the trigger is native: the maintainer typed the run themselves, no assistant in the path. `wrap` was exercised twice under redirected state — CHECK B ran it against a repo with 2 genuinely unpushed commits, which printed the warning and **exited 0** (F-17 fix), and CHECK C confirmed a following `&&` chain continued. Live `wrap` against real state was deliberately NOT run, for the same reason as Desktop: it would consume the mark and write a row mid-matrix. Row resolved — `wrap` is reachable on both surfaces, directly here and through the assistant's shell on Desktop (F-29). | **PREMISE IS FALSE** — Desktop does have a shell: the assistant's. `mindforge brief` was executed on this surface at 10:12 and returned the full brief, so `mindforge wrap` is equally runnable here. The trigger exists; it routes through the assistant rather than the human's own prompt. `wrap` itself was deliberately NOT run -- it would consume the mark and write a row mid-matrix. See F-29. |
| 11.10 | `absent` in the Projects table (F-19 fix) | renders the same on both | **PASS (sandboxed)** — Same script and fixture as Desktop, 2026-08-30 11:0x on Terminal. A queue naming `ghostrepo` rendered LAST `no repo` (dim) and STATE `absent` (red), while `alpha` and `beta` stayed green `clean`. Renders the same on both surfaces — the row's actual question — so F-19 is parity-proven. **Re-checked on Desktop 2026-08-30 14:5x against the NEW code, as the handoff required:** alignment holds — `no repo` is padded to 10 visible characters INSIDE the colour codes, so it ends level with `2026-08-30` on the rows above, and STATE lines up across all three rows. F-32's fix is confirmed on Desktop, not only on Terminal. **But the terminal run exposed what the Desktop run did not notice: the row is misaligned.** `last` and `st` carry ANSI codes into `printf '%-10s'` at line 162, and the field width counts bytes, not visible characters — `${D}no repo${O}` is 15 bytes for 7 visible, so the 10-wide field gets no padding and every column to its right shifts left by three. Cosmetic, affects only the `absent` row, present on both surfaces and missed on both until now. Filed as F-32, **fixed and re-verified on Terminal 12:33** — the row now aligns with `alpha` and `beta`, all other checks unchanged, guard clean. **The fix itself is Terminal-only so far**: it edits the very line this row exercises, so the Desktop column of 11.10 was filled against the OLD code and must be re-run. The parity ruling applies to a fix made *because* of parity testing too. | **PASS (sandboxed)** — live state could not discriminate: all six queue repos are on disk, so nothing renders `absent`. Sandboxed run 2026-08-30 10:4x on Desktop via `~/mindforge-sandbox.sh` (`MINDFORGE_STATE`/`MINDFORGE_PROJECTS` redirected to a scratch dir; the script fingerprints the real state before and after and reported it byte-identical, marks unchanged). A queue naming `ghostrepo` rendered LAST `no repo` (dim) and STATE `absent` (red), while `alpha` and `beta` stayed green `clean`. Rot rule R6 independently flagged `queue names ghostrepo, which is not in <projects>` — the condition surfaces twice, by two mechanisms. |

**Why 11.8 and 11.9 are new questions, not just new checks.** Both are consequences of
today's fixes rather than pre-existing behaviour, and both land differently on Desktop
than in a terminal. 11.8 turns a silent failure into a visible one exactly where the
surface is noisiest. 11.9 is the older question the F-25 fix made concrete: the
deliberate closeout has no trigger at all on the surface that churns sessions hardest.

---

## Results

**§1-§10:** 95 accounted for · **Pass:** 89 · **Fail:** 5 · **N/A:** 1 · **Deferred:** 0
**§11 surface parity:** 10 checks × 2 surfaces = 20 cells · **20 filled — COMPLETE** — **Desktop 10/10, Terminal 10/10**

**Total: 115 cells, 115 filled — the matrix is COMPLETE.** The last cell was §4.8, closed
2026-08-30 at ~15:0x: the maintainer restarted the Desktop and counted **one** popup, reported at 16:33.
§10.1 and §10.8 were closed on Desktop 14:5x. **§11 is complete: 20/20.**
Verdicts across all 115: **pass 103 · fail 7 · N/A 1 · cannot-discriminate 2 · premise-false 2 · deferred 0.**
§1-§9 was run from a terminal-side shell; §10 and the Desktop column of §11 were run
live on Desktop (cold launches 08:47 and 10:10); the Terminal column of §11 was closed
from a terminal-side shell at 11:0x, maintainer-typed.

*Counts recomputed programmatically from the tables on 2026-08-30 at 10:14 and again at
11:0x when §11 closed — never hand-tallied. The 11:0x recount caught its own arithmetic slip
before it landed: the first pass counted the 3 deferred cells as filled and reported 115/115.
Deferred is not filled. That is M-4's failure shape appearing inside the fix for M-4, which is
why the block is computed and not typed. The previous roll-up claimed `§11 · 0 filled` while the table already held
12 filled cells, and understated §1-§10 passes by 9 -- a stale summary over a live table,
which is the same failure shape as a stale README over shipped code. Logged as M-4.*

**Deferred is now 0.** §4.8 was the last one and no script could substitute for it: it took a
Desktop restart with the popups counted by the human. §10.1 and §10.8 were closed on Desktop
2026-08-30 14:5x by the handoff note that carried this round between the two surfaces.
Every cell that was ever deferred has now been run live on Desktop. Everything
else ran under `MINDFORGE_STATE` pointed at a throwaway directory; the real state
directory was never written to.

**What 4.8 does and does not prove.** It confirms the popup: one cold launch, one popup, now
three times over (08:47, 10:10, 15:0x). It does **not** exercise F-8's rate limit, because the
condition the limit guards against — several sessions spawning at once — does not occur on this
box (F-28). The limit remains untested on its actual purpose, the same standing already recorded
at 11.4 and 11.7. The matrix being complete does not upgrade that.

Section roll-up (cells **filled**, not cells passed — a FAIL is a filled cell):
§1 7/7 · §2 10/10 · §3 16/16 · §4 8/8 · §5 6/6 (1 fail) · §6 11/11 · §7 9/9 (1 fail) · §8 9/9 · §9 9/9 (2 fail, 1 N/A) · §10 10/10 (1 fail) · §11 20/20 (2 fail, 2 cannot-discriminate, 2 premise-false).

**§11 is complete — 20/20, both columns.** The Desktop column was filled live on that surface (cold launches 08:47 and 10:10) plus one sandboxed run; the Terminal column was closed 2026-08-30 11:0x by re-running the *same* `~/mindforge-sandbox.sh` at the *same* fixture path, so the surface was the only variable between the two runs. Every observable matched. Three rows resolve to something other than a pass and are recorded as they fell rather than forced: 11.3 is FAIL on both — the `/dev/tty` visible copy has now failed everywhere it was tried (F-26) — 11.7 is CANNOT DISCRIMINATE on both, for different reasons on each surface (F-28), and 11.1 and 11.9 are PREMISE IS FALSE, where the code did the right thing and the matrix's expectation was wrong. The parity ruling is satisfied: no fix in this release is claimed on one surface alone.

Every fix from the three v0.1.x releases held. F-7 per-session marks, F-8 rate limiting,
F-3/F-11 unmasked dirt, F-2/F-10 rot dedup and F-12 in flight all passed without
qualification. The new findings are in paths those releases never touched: exit codes,
absent files, and unwritable state.

### Findings

*(F-14 onward. Each gets a GitHub issue opened with the full entry and closed with a
full explanation — traceability is the evidence of the process, not bookkeeping.)*

| ID | § | Severity | Description | Issue |
|---|---|---|---|---|
| F-14 | 2.2 | low | Headline says `N dirty` without naming the files. Banked 2026-08-29: this is what made a stale-report explanation look plausible. | |
| F-15 | 3.x | medium | `wrap` deletes `wip.md`, but session end is not work end. Banked 2026-08-29. **First concrete cost, 2026-08-30 12:4x:** the deliberate closeout and the handoff note are mutually exclusive. Wrapping this session to hand over to Desktop would have destroyed the very note written to make the handover possible — the tool's two continuity mechanisms cancelling each other. Avoided only because the code was read first (`wrap` line 14 `rm -f wip.md`; `session_end` touches only the mark, so closing normally preserves it). A user following the documented "close deliberately" advice loses the note and gets no warning. Raise on the strength of this: the closeout should carry the note forward or refuse, not silently delete it. | |
| F-16 | 8.2, 10.3 | **high** (was low) | The in-flight note truncates at 200 chars in the injected headline. Proven harmful 2026-08-30: a 543-char note delivered 200 chars to a fresh terminal instance. The 343 cut characters contained 'BUT terminal-side only', 'the maintainer ruled: every fix must be proven on BOTH Desktop and Terminal', and '83 of 115 cells done' — every clause saying the work was unfinished. The instance received only 'fixes written, not committed', and recommended committing and tagging: the exact action the note existed to prevent. The truncation does not merely lose detail, it inverts the instruction. Raised from low. | |
| F-17 | 3.15 | medium | `wrap` exits 1 whenever it warns about unpushed commits. `[ $warned -eq 0 ] && printf` is the last statement in the function, so its false branch becomes the exit status. A successful closeout reports failure, breaks `&&` chains, and would mark a SessionEnd hook failed — exactly when there IS unpushed work. | |
| F-18 | 5.4 | medium | `persona.txt` is gated on readability only, never content. An empty file prints a bare `scope:` with no scope; `persona.example` copied verbatim — which its own first line instructs — prints `scope: # Copy to $MINDFORGE_STATE/persona.txt…`. The one line whose job is stating the persona boundary silently states a comment. F-9's leak happened twice with the rule loaded. | |
| F-19 | 7.8 | medium | A project named in `queue.md` but absent from disk reports STATE `clean`, in green. Line 125 defaults `st` to clean and the `else` at line 131 sets only `last`, never `st` — the same shape as the bug the comment directly below it documents. | |
| F-20 | 9.2 | low | A missing `queue.md` leaks a raw shell error into the middle of the Projects table, and exit stays 0. Three unguarded reads: lines 140, 152, 257. Confined to `full()` — injected context uses `headline()` and stays clean — but it is the first-run path for a new user. | |
| F-21 | 9.6 | low | `~/.config/mindforge/config` is sourced at line 10, before the `${VAR:-default}` block at 13-18, so config silently overrides the environment for any variable it sets. A user whose config sets `MINDFORGE_STATE` would run this matrix against real state believing it sandboxed. Fix: `:=` defaults in `config.example`. | |
| F-22 | 8.8 | low | A literal tab in a `wip` note truncates the headline at the tab, silently. `cut -f2` takes one field. F-16's truncation at least signals with `…`. | |
| F-23 | 6.11 | low | Three-strikes escalation counts distinct DAYS but prints `(N sessions -- fix it)`. Three sessions in one day still reads as 1. The dedup is right; the noun is wrong. | |
| F-24 | 1.7 | low | `mindforge --version` reports 0.1.2 from a symlink pointing at a dirty working tree carrying the unreleased F-13 fix, and `git describe` agrees. Version identity cannot distinguish tag from working copy — the same failure shape L1 release discipline records for the nog PKGBUILD, where both files said 1.3.1. | |
| F-28 | 11.1 | medium | The '~3 sessions per launch' premise is stale on this Desktop build. A cold launch on 2026-08-30 08:47 created exactly ONE mark. That premise is cited as justification for F-7 (per-session marks) and F-8 (notification rate limiting) in the code comments. Both mitigations remain correct and cost nothing — per-session marks are right regardless, and a rate limit is cheap insurance — but the comments now overstate the threat, and a reader trusting them would be misled about why the code looks the way it does. Verify the spawn count before citing it again. **Second cold launch 10:10: one mark again.** Two for two. The practical consequence is that F-8's notification rate limit has now never been exercised on its actual purpose on this surface -- 11.4 and 11.7 both come back untestable for the same reason. The mitigations are not wrong, but nothing on this box can demonstrate they work. | |
| F-27 | 10.3 | medium | The injected in-flight line carries no timestamp. `wip.md` stores one (`2026-08-30 09:08`) and the full brief prints it as an `In flight · <date>` panel header, but `headline()` emits only the text — directly beneath `last session: yesterday`. The fresh instance duly reported work done at 09:08 today as 'yesterday ended mid-flight'. Two facts adjacent in the injected context, one of them undated, read as one fact. | |
| F-26 | 11.3 | medium | The `/dev/tty` visible copy never reaches the human on EITHER surface. Proven absent on Desktop 2026-08-29 (no controlling terminal); proven absent in a real Claude Code terminal 2026-08-30 (splash only, no headline). Whether the probe fails or the TUI clears the screen over it is undetermined — the delivery outcome is identical either way. 6 lines of code and 12 of comment for a channel that has now failed everywhere it was tried. Either find the mechanism or delete it; a "bonus" that never once arrived is dead code pretending to be a feature. | |
| F-25 | 9.7 | high | Write failures are silent. Under an unwritable state directory `mindforge wip` prints `in flight: <note>` and exits 0 while storing nothing. The note whose entire purpose is surviving into the next session does not exist, and the human is told it does. | |
| F-30 | sandbox | low | `persona.txt` content is not checked for a leading `scope:`. mindForge prints the prefix itself (`printf '%sscope:%s %s'`), so a file whose first line already reads `scope: ...` renders `scope: scope: ...`. The real `persona.txt` correctly omits it, so this is not live — but the rendered brief shows the line WITH the prefix, and copying that line back into `persona.txt` is the obvious way a user would create the file. Same family as F-18: the scope line trusts its input. | |
| F-31 | sandbox | low | With an empty memory directory the State panel prints `memory     0 files, newest ` — a label with nothing after it. Cosmetic, but it is the first-run path, same territory as F-20. Print `n/a` or omit the clause when the count is 0. | |
| F-29 | 11.9 | low | The matrix's own premise that "Desktop has no shell" is false, and it is the second stale premise this section has produced. Desktop has a shell -- the assistant's -- and `mindforge brief` was run through it on this surface at 10:12 to confirm. `wrap` is therefore triggerable on Desktop; what is actually true is narrower and less alarming: the human cannot type it, so the closeout routes through the assistant. That is worth a doc line, not a feature. Filed alongside F-28 because both are the same defect class: a confident claim about the Desktop surface written from a terminal and never checked. | |
| F-32 | 11.10 | low | The Projects table misaligns any cell that carries colour. Line 162 pads with `printf '%-10s'`, whose field width counts BYTES, not visible characters — `${D}no repo${O}` is 15 bytes for 7 visible, so a 10-wide field gets zero padding and every column to its right shifts left by three. Only the `absent` row is affected today, because it is the only LAST cell that is coloured; `2026-08-30` is plain and pads correctly. Present on BOTH surfaces and missed on both until the terminal run of 11.10 — the Desktop run produced the same output and it went unremarked, which is the same class as M-5: output that was looked at but not read. | |
| F-33 | handoff | **high** | **A rule you write down cannot be counted on to reach the session that needs it.** mindForge keeps a list of working rules in `rules.txt`. Two separate things stop them arriving. **First:** the short handoff injected into every new session — the one carrying the date, the last session, the repo counts, the in-flight note and the scope line — has no rule line in it at all. Rules appear only in the long `mindforge brief`, which somebody has to run by hand. **Second:** even the long brief shows **one** rule per day, chosen by the day of the year (`date +%j % count`, line 207). There are 7 rules on file, so any given rule is missing 6 days out of 7. **How it was found — the way findings should be found:** on 2026-08-30 the maintainer had to ask for the same thing twice in one day, on two different surfaces — *write plainly, I am not an engineer.* That rule did exist in the top-level CLAUDE.md, but written narrowly, as though it only applied to installing software. It was not in memory (that file was created at 12:25, after the second ask), and it is **still** not in `rules.txt` — so the one surface built for exactly this job was empty, and on 2026-08-30 would have shown a different rule anyway. **This is the tool's own thesis failing on its own terms:** mindForge exists so something said once survives into the next session. Here something said once did not. **Fix direction:** rules that always apply belong in the injected handoff, every session, not in a daily rotation. Rotation is the right shape for occasional nudges and the wrong shape for standing rules. Needs a design decision from the maintainer, not a patch. | |

### Matrix defects

The specification has its own bugs. These are document fixes, not code fixes.

| ID | § | Description |
|---|---|---|
| M-1 | 4.6 | `PATH=/nonexistent` removes `date`, `git` and `grep` along with `notify-send`, so the run exits 127 and proves nothing about the guard. Rewrite as a PATH holding the full toolchain minus `notify-send`, which is how it was actually verified. |
| M-2 | header | The header said 88 checks. There are 95 numbered rows. |
| M-3 | 2.2, 4.4 | Both expectations predate F-13 and were never updated for it. The headline is now up to 5 lines and the notification body 3. A spec that is not updated with the fix silently starts failing correct code. |
| M-4 | Results | The roll-up drifted from the tables it summarises. It claimed `§11 · 0 filled` while §11 already held 12 filled cells, and reported 78 passes against an actual 87 -- understating finished work by 9 checks and overstating deferred by 9. Recomputed programmatically 2026-08-30 10:14. **Fix: never hand-tally this block.** A summary that is edited by hand while the tables move underneath it is the same failure shape as a stale README over shipped code, which L1 release discipline already calls a regression. |
| M-5 | 11.9 | The Desktop column of §11 was written from a terminal, and two of its stated premises turned out to be false when checked on Desktop: the `~3 sessions per launch` spawn count (F-28) and `Desktop has no shell` (F-29). Expectations for a surface should be marked provisional until they are observed on that surface. |
| M-6 | method | **A test fixture can fake a failure.** The first run of Check E reported `MARK LOST -- F-25 regression`. It was not a regression; the fixture was wrong twice over. `date '+%F\t%H:%M'` emits a literal backslash-t, not a tab, so the mark held one field instead of two; and `chmod a-w` on the state DIRECTORY does not prevent writing to an ALREADY-EXISTING file, so `sessions.log` stayed writable and the row landed normally. Both had to be fixed before the check tested anything. Check D passed under the same directory chmod only because `wip.md` did not yet exist and creation genuinely needs the directory bit -- a passing sibling check was therefore no evidence the method was sound. **Rule: when a check reports a regression in code that was just verified elsewhere, suspect the fixture first and prove the negative control before filing.** Nothing was filed; this entry exists so the near-miss is on the record.

### Verdict

*Revised 2026-08-30 11:0x when §11 closed. The original run-time verdict is preserved in
the fix tables above, which record what was believed at each round; this block states what is
true now. A verdict left at its first draft is the stale-summary regression M-4 names.*

**Shipped-ready:** F-13 is verified — the in-flight note reaches the injected headline
(§8.2), which is the whole reason it was written. The three v0.1.x release fixes all
hold under adversarial input: corrupt marks, garbage dates, missing files, 20-hour-old
marks, hostile UTF-8.

**Ship as v0.1.3:** F-13 plus **eight** fixes now in the working tree — F-25, F-17, F-18 and
F-19 from the first round, then F-16 and F-27 from the second, after the live §10 run caught
them, F-32 from the third, and **F-33 from the fourth — the only one that is a design change rather than a patch**. F-25 and F-16 are the highs: F-25 breaks the continuity thesis directly, and F-16 was
raised from low when it was proven to *invert* its own payload. Each has a proven reproduction
above and each is now verified on **both** surfaces. F-32 was ruled IN by the maintainer on 2026-08-30 and
fixed the same round — one line, cosmetic, and it sits in a path Desktop was going to re-check anyway.

**Defer:** F-14, F-20 through F-24, and F-28 through F-31 — real, all low, none blocking.
F-15 was ruled on 2026-08-29 and needs a design decision, not a patch. **F-16 is no longer
on this list**: it was deferred as low at the time this verdict was first written, then the
live run proved it harmful and it was fixed the same session.

**Still unproven: 0 of 115 — all three closed.** §10.1 and §10.8 went on Desktop at 14:5x,
and §4.8 at ~15:0x when the maintainer restarted the Desktop and counted one popup (reported 16:33).
All three were deliberate live actions rather than observations, and all three *cross-instance*:
a note written on one surface to be read on the other. §4.7 was closed 09:18, §10 is 10/10,
§11 is complete at 20/20. Cross-instance continuity **has** been demonstrated end to end
(§10.2, §10.3, §10.10, §11.2) — including the run where it worked and delivered the wrong
instruction anyway, which is F-16 and is fixed.

Complete is not the same as proven. Of the 115, one hundred and three pass; seven fail, two
cannot discriminate on this hardware, two had a false premise, one is N/A. The failures and the
undiscriminating cells are recorded as they fell rather than argued into passes, and F-8's rate
limit is still untested on its actual purpose because this box will not produce the condition it
guards (F-28).

**The surface caveat is discharged.** All six fixes are now proven on both surfaces. F-18 and
F-19 were argued to be "pure rendering and surface-independent" — that argument was not
accepted, they were run anyway, and F-19's terminal run is what turned up F-32. "Should be"
is exactly what this matrix exists to replace, and it earned its keep here. F-25 changes
`session_end`, which runs on both surfaces: §11.8 is filled on both, exit 1 and the mark
preserved in each. The `~3x per launch` premise that made it urgent turned out to be false
(F-28) — the fix stands regardless, but for a smaller reason than the one that motivated it.

**On the method:** 83 cells filled in one sitting against a script that had 12 findings
verified by hand. Nine more surfaced. Two of them — F-25 and F-19 — live in paths no
hand-check would ever visit, because nobody makes their state directory read-only or
names a project they have not cloned. That is the argument for the suite this matrix
was written to specify.

---

## Fixes applied — 2026-08-30, same session

Four findings were fixed in `bin/mindforge` immediately after the run and each was
re-verified against the exact check that caught it. **Not committed** — the 2026-08-29
ruling holds until the maintainer releases v0.1.3.

| ID | Fix | Re-verified by |
|---|---|---|
| F-17 | `[ $warned -eq 0 ] && printf` was the last statement in `wrap`, so its false branch became the exit status. Made it an `if`, added an explicit `return 0`. | §3.15 — exit 0 with the warning still printed; `&&` chain continues. **Desktop-proven (sandboxed) 2026-08-30:** with 2 genuinely unpushed commits the warning fired AND exit was 0; a following `&&` continued. |
| F-18 | `head -1` replaced with `grep -vE '^[[:space:]]*(#\|$)' \| head -1`, and nothing printed when the result is empty. | §5.4 — empty file prints no line; `persona.example` copied verbatim prints no line; a real scope line after comments still prints. |
| F-19 | The `else` branch now sets `st="${R}absent${O}"` as well as `last`. | §7.8 — absent projects read `absent` in red, not `clean` in green. **Desktop-proven (sandboxed) 2026-08-30:** see 11.10. |
| F-25 | New `can_write()` guard on `wip` and `log_row`. `wrap` now logs BEFORE destroying anything and returns 1 if the row did not land; `session_end` keeps its mark when a write it intended fails. | §9.7 — refuses with a message on stderr, exit 1, `wip.md` and the mark both preserved; writable path unchanged. **Desktop-proven (sandboxed) 2026-08-30 on BOTH guarded paths:** `wip` under an unwritable dir refused and created no file; `session-end` under a read-only `sessions.log` exited 1, logged nothing and kept the mark. See 11.8. |

**F-25 grew during the fix.** The guard on `wip` exposed the same bug one level up:
`wrap` deleted `wip.md` first, called `log_row`, ignored its result, removed the mark
and printed `wrapped:` regardless. A failed write lost the note, the mark and the row
while reporting success — three losses reported as a win. Order of operations was as
much of the bug as the missing guard.

### Second fix round — F-16 and F-27, after the live §10 run

The live run caught two more, and both were fixed the same session because every
remaining check *uses* the in-flight note as its handoff mechanism. Continuing to
Desktop through a channel proven to invert its own payload would have wasted the run.

| ID | Fix | Re-verified by |
|---|---|---|
| F-16 | Cap raised 200 -> 900, and a cut note now says so: `[TRUNCATED at 900 of N chars -- run \`mindforge brief\` for the rest]`. A truncated note announces that it is truncated. | 1192-char note shows the marker with exact counts and withholds the tail; the real 543-char note now arrives whole, parity ruling included. |
| F-27 | `headline()` now emits the stored timestamp: `in flight (2026-08-30 09:08): ...`. | Renders dated; short notes render plainly; no note still prints no line. |

**Consequence to rule on:** the popup body is `headline()` minus its first line, so a
long in-flight note now makes for a long notification. A verbose popup is cosmetic; a
truncated instruction was a correctness bug. They were deliberately not coupled, but
The maintainer may want a separate cap on the notification body.

**Regression pass:** 19 checks re-run across §2, §3, §5, §8 and §9 after the edits.
19 passed, 0 failed.

**Behaviour change to note before release:** `session_end` now exits 1 when it cannot
write the row. That is a hook path, so a genuinely broken state directory will surface
as a hook failure rather than silence. That is the intent of F-25, but it is a visible
change and the maintainer should confirm it. **CONFIRMED by the maintainer 2026-08-30 12:4x** — approved on the reasoning that silently losing the record is the worse outcome, and that quiet failure is the exact class of bug this whole round existed to remove. Ships in v0.1.3.

**Still open at the close of *that* round (10:4x):** §4.7, §4.8 and all of §10 — 12 checks,
none of which a sandboxed shell can honestly run. Superseded by the round below; left in place
because it records what was true when the fixes were made.

---

## Third round — Terminal parity, 2026-08-30 11:0x

`~/mindforge-sandbox.sh` re-run on the Terminal surface, maintainer-typed, using the *same* script
at the *same* fixture path as the Desktop run so the surface was the only variable. All five
checks passed and matched Desktop on every observable; the guard reported the real state
byte-identical and marks unchanged.

§11 closed at **20/20**: 11.8 PASS, 11.10 PASS (sandboxed), 11.9 PASS — natively triggered here,
the human typed it — and 11.7 recorded as CANNOT DISCRIMINATE rather than forced to a pass,
because a terminal launch spawns exactly one session and no sibling can exist to floor.

**One new finding, F-32**, and it is a finding about reading rather than about code: the
`absent` row is misaligned on both surfaces, and the Desktop run produced the identical output
without anyone noticing. Output that is looked at but not read is the same class as M-5.

**Still open, 3 of 115** — §4.8, §10.1 and §10.8. Every one is cross-instance by nature: a note
written on one surface to be read on the other. They cannot be closed from a single surface,
which is why they are last.

**F-32 fixed 12:33 and re-verified on Terminal**, along with a fixture hardening: `~/mindforge-sandbox.sh` no longer hard-codes its scratch path, which had it pointing into an OLD session's temp folder that can be reaped at any time. A vanished fixture mid-handoff would have looked like a code failure — M-6's trap, avoided rather than survived this time.

**Carried into the Desktop round:** F-32's fix edits the Projects-table render, the same line 11.10 and §7.8 exercise, so those Desktop cells were filled against the previous build. Desktop must re-confirm F-19 still holds and that F-32 is gone. This is the parity ruling applied to itself.

`VERSION` is still `0.1.2`; F-24 argues it should not be bumped until the tag exists — unruled.
No GitHub issues opened — per L1 each of F-14..F-33 needs one opened with the full entry
and closed with a full explanation. **The maintainer ruled on 2026-08-30 that the issue batch waits**;
the findings stay in this document until they say otherwise. Nothing is committed; the 2026-08-29 ruling holds.

## Fourth round — F-33, the standing-rule split, 2026-08-30 13:2x

Not a test round. The maintainer ruled on F-33 the same session it was raised: **split the rules**,
**add the plain-language rule**, **no issue yet**.

| ID | Fix | Re-verified by |
|---|---|---|
| F-33 | Standing orders move to their own file, `$STATE/always.txt`. **Every** line of it prints in `headline()`, so it reaches the injected handoff in every session — not only when somebody runs the full brief by hand, and not one-in-seven by rotation. `rules.txt` is unchanged in behaviour and keeps the daily rotation for nudges. New `always_rules()`; `headline()` gains a `--no-rules` flag; `notify_headline()` uses it so the launch popup stays a glance. Cap `MINDFORGE_ALWAYS_MAX` (default 10) and, when it bites, the handoff says so in words — a silently dropped standing rule is the exact failure this fix exists to end. | The five checks below, plus 2.9 and 4.4 re-run. |

**Checks run for the new code. These are NOT numbered rows — the roll-up denominator stays
115 and the three open checks stay open. The v0.1.3 matrix must absorb them as §12.**

| # | Check | Expected | Result | Notes |
|---|---|---|---|---|
| A | live `brief --headline` with 7 standing rules | all 7 print as `always:` lines, after `scope:` | PASS | 7 of 7 present in the injected handoff. |
| B | no `always.txt` at all | nothing printed, no error | PASS | Backward compatible: an existing install is unchanged until the file is created. |
| C | `always.txt` holding only comments and blanks | nothing printed, no bare label | PASS | Deliberately not F-18's shape — content is filtered before the count is taken. |
| D | `MINDFORGE_ALWAYS_MAX=3` against 7 rules | 3 printed, then a loud line naming the 4 dropped | PASS | `[4 MORE ALWAYS-ON RULES NOT SHOWN -- trim always.txt or raise MINDFORGE_ALWAYS_MAX]`. |
| E | notification body excludes the rules | popup carries date/last/counts/scope only | PASS | Verified against the **real** `notify-send` argument list, captured with a stub on `PATH` — not inferred from reading the code. 0 `always:` lines, 0 ANSI escapes (4.4 holds). |

**Re-verified after the change:** 2.9 (full brief still prints one rotating rule — now the
single remaining line in `rules.txt`) and 4.4 (popup content, zero escapes, per E).

**Caught in review, worth recording.** The first draft of the fix put the maintainer's name in a code
comment in `bin/mindforge` — a published file whose existing comments say "the human"
throughout. Removed before it went anywhere near a commit, and `git grep` over all tracked
files is clean. Same class as F-9 and the 2026-08-07 kognog leak: the rule was loaded and the
mistake was made anyway, which is the argument for printing the boundary rather than trusting
recall. It is also the argument for `always.txt` existing at all.

**A finding inside the finding.** Splitting the list left **7 standing orders and 1 rotating
nudge**. Six of the seven rules the maintainer had written were never nudges — they were standing
orders sitting in a container that showed them one day in seven. The split did not just fix
the delivery; it revealed that the rotation had been the wrong home for almost the entire file.

---

### Round close — 2026-08-30 16:3x · the last cell

**§4.8 closed. The matrix is 115/115, 0 deferred.** The maintainer restarted the Desktop at ~15:0x and
saw **one** popup, reported at 16:33. That is the third cold launch counted this way — 08:47,
10:10, 15:0x — one popup every time.

The roll-up was recomputed by script, never by hand (M-4), and the script earned its keep twice.
It **refused to count** a cell it did not recognise instead of guessing: §11.9 Desktop reads
`PREMISE IS FALSE`, a fifth verdict the classifier had never been taught. Silent
misclassification is precisely how a hand tally goes wrong, and this one stopped rather than
rounded. It was given its own bucket — filled, observed, not a pass — because folding it into
`fail` or `pass` would have been the tallier deciding what the tester meant.

**Wording ruled, 2026-08-30 17:1x.** §11.1 Desktop read `FAIL of the PREMISE` while §11.9 Desktop
read `PREMISE IS FALSE` for the same shape of result, so one counted as a failure and the other
did not. The maintainer's call: pick whichever makes sense. **`PREMISE IS FALSE` wins, and 11.1 is
relabelled to match.** The reason is not tidiness — in 11.1 the code did exactly the right thing
(one mark per session, nothing stomped); it was the matrix's guess of `~3 on Desktop` that was
wrong. Calling that `FAIL` charges the software for a bad expectation, which is the one thing a
test record must never do. The count moves with it: **fail 8 → 7, premise-false 1 → 2.** The
totals are unchanged at 115 filled — relabelling moves a cell between buckets, it does not
create one.

**Independent cross-check on the new number:** §1-§10 passes moved 88 → 89, exactly the one cell
added, and deferred moved 1 → 0. The total is unchanged at 115, as it must be — closing a cell
moves it between buckets, it does not create one.
