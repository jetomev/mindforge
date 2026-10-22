# mindForge — project rules

*How this project is built, tested and shipped. Written for the AI co-developer, and public on purpose: it is part of how the human + AI method is documented.*

## What it is
The start-of-session briefing and end-of-session record for working with an AI assistant across sessions and machines. `brief` says what is true right now, `wrap` measures the closeout instead of trusting "done", and the rot check (R1–R12) finds what has quietly gone wrong. One bash script, `bin/mindforge` (`VERSION=` near the top), plus `bin/mindforge.ps1`, the PowerShell wrapper for Windows. The doctrine is `docs/METHOD.md`; the script is the easy part. The name is `mindForge`; the command is `mindforge`. Its own repository, not a Forge Suite section.

## Non-negotiables
- **Three answers, never two (#24).** Every check says yes, no, or *could not look*. A check that could not measure never prints a pass, in the tool and in the tests. Helpers return non-zero when they could not look; every caller decides what to say about it.
- **Nothing personal, ever.** The repo is public. Turn the guard on in every clone: `git config core.hooksPath .githooks`. The pre-commit hook refuses emails, private addresses, keys, real home paths and the terms on the maintainer's private wordlist, which lives outside the repo and is never copied into a file, a commit or a reply. Write "the maintainer", never a name. A refused commit is a finding: fix the text, never bypass with `MINDFORGE_SCRUB=off`.
- **The hook sees commits only (#62).** Issue text, comments and release notes go out unchecked; seven issues once had to be deleted and recreated. Write public text to a file and check it against the wordlist before `gh` posts it.
- **Scoped names never leave their scope (#23).** Some names belong to a few projects only. `scope.txt` (private, in the state folder) lists where each term is allowed; `wrap` checks the vault notes the session changed, and `mindforge scrub --vault` checks them all. Why: a scoped name leaked three times, each time in a session that had the rule loaded, and the vault has no commits for the hook to see. A printed rule did not stop it; a check does.
- **The queue is hand-written, never generated (#13).** No tool can know what was decided next. `queue.md` once claimed "maintained by `mindforge wrap`" while nothing wrote it, and a closed issue sat at the top of the brief for 16 days. Never add code or a comment that claims to maintain it; R8 checks it instead (column 5 is `#n`, or `-` to opt out; a blank is reported). Keep the warning header in `templates/queue.md.template`.
- **Hooks are installed by a person (#19).** `mindforge hooks --print` gives the block, `--check` verifies it. The assistant never edits `settings.json` to add them.
- **The person cannot see hook output.** Anything they must see is printed as an instruction to the assistant to render it (the banner says "render this to the person").
- **Nothing hard-coded.** Paths come from `~/.config/mindforge/config` or the environment (see `config.example`); `bin/mindforge` is published. An explicit export beats the config (#31), so a sandbox stays a sandbox.
- **Every command answers `--help` without running** (W-8a, in the dispatcher), and a leading dash it does not know is refused before anything is written (`bad_option`). A new command keeps both.

## Linux AND the Windows laptop
mindForge must work on any Linux and on Windows through Git Bash (and PowerShell 7 via `bin/mindforge.ps1`). Each gap below cost a laptop run; write for it up front:
- `ln -s` makes a **copy** without Developer Mode. Never rely on a link; the harness proves one with `make_link`.
- One path, two spellings (`/c/Users/x` vs `C:/Users/x`). Compare paths in git's spelling (`canon_dir`, #43 #34). Roots are `:`-separated, in Git Bash's spelling.
- The memory folder is named after the Windows spelling of home (`C--Users-x`), found with `cygpath -w` (#15).
- `python3` can be the Store placeholder: a name on PATH proves nothing, only a run does (`find_python`, #63). Git Bash paths must be converted before Windows python sees them.
- `env -i` drops `SystemDrive`; the harness passes `WINENV` through (#65).
- Hand-written files may have Windows line endings: read the queue only through `queue_lines` (#36).
- Every process start is slow there: build the repo list once (`prime_repos`, #38); no new git call per repo per rule.
- Hooks run in PowerShell: `"shell": "bash"` and a full path (`hooks --print --windows`). From PowerShell, `mindforge.ps1`, never a `.cmd` (#21). No `notify-send` and no sound player: both stay silent, never an error.
- **A Windows fix is proven only by the laptop's run** (the test matrix's part B), not by stand-ins on Linux. Its issue stays open until then (#15 #21 #38 #65 today).

## How to run and test
- From source: `bash bin/mindforge brief`, `bash bin/mindforge rot --timings`.
- **HAZARD:** where `mindforge` on PATH is a link to this checkout, every saved edit is live in every running session at once. A half-done edit breaks the next session start. Keep edits whole; test before saving over a working state.
- **HAZARD:** `python3 - <<'PY'` makes the here-document the program's input, so a hook's JSON on stdin vanishes. Pass the code with `-c`.
- **Tests:** `bash testing/run-tests.sh` (or `… <pattern>`), about 16 seconds. **293 checks, all passing, 1 could not look on Linux** (the PowerShell wrapper), 2026-10-22. Report the count in TODO.md and on every release; it never drops silently. The harness runs in a throwaway home with `gh` stubbed, proves the real state untouched, fails when zero checks ran or when the run leaves anything in the repo.
- **A new check is seen failing first:** run it against the previous build (`MINDFORGE_UNDER_TEST=<copy of the old bin/mindforge>`). A new test can pass on old code for the wrong reason.
- Two conditions go through `cond '<a> && <b>'`; `check "x" [ A ] && [ B ]` tests only A (twenty checks did, found 2026-10-19). Cannot check here: `skip`, never a pass. A known, filed defect: `xfail <#issue>`.
- **A new rot rule (R13…)** needs: checks in the failing direction, its could-not-look path, its row in the README's rule table, and the range in `rot check (R1-Rn):` plus the check that reads it.
- Hand-run matrices go in `testing/`: part A is the home PC on the **installed** package (it calls `/usr/bin/mindforge`, not the checkout), part B is the laptop's checkout. `python3 testing/tally-matrix.py` computes the totals; never type them.

## What `mindforge active` needs from a project
An executable `scripts/status.sh` that prints the project's summary (phases, NEXT items). `mindforge active <path>` refuses a folder without one, and `wrap` moves the pointer only to a project that has one. The banner runs it from wherever the session is, so it must find its files from its own path. Without it, the one-project brief falls back to TODO.md's open `- [ ]` items. mindForge itself has no `scripts/status.sh`.

## Documentation, at every step
- `TODO.md` after every step: the current release, the test count, open items with their issue numbers.
- README accurate top to bottom: the commands table, the rule table, the check count.
- `docs/CHANGELOG.md` `## Unreleased` gets each change as it lands; a new program the code calls goes into `docs/PACKAGING.md` in the same commit; a lesson about the method becomes a numbered section of `docs/METHOD.md`.

## Release
`~/.claude/rules/release.md` and `aur.md` apply. Here: after the `docs: README + version bump` commit (`VERSION=` in `bin/mindforge`, `## vX.Y.Z — date` in the changelog), run `bash scripts/release.sh X.Y.Z`. It refuses before anything is tagged or pushed (#41, after v0.1.6 went public on the wrong commit); never tag or push by hand. No PKGBUILD in this repo; the AUR recipe ships the `*.example` files and `templates/`, so a new starting file means a recipe change too.
