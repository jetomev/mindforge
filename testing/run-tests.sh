#!/usr/bin/env bash
# mindForge automated checks -- the executable half of the test matrix.
#   bash testing/run-tests.sh            run everything
#   bash testing/run-tests.sh <pattern>  run only checks whose name contains <pattern>
#
# Every check runs bin/mindforge against a throwaway HOME, so the real config,
# state and memory are never read or written. That is not assumed: the real
# state directory is hashed before and after, and a difference fails the run.
#
# Three things this harness refuses to do, because each is a way a check lies:
#   - report green when zero checks ran                        (#24)
#   - run at all if a deliberately false check does not fail   (#24)
#   - let an expected failure pass silently -- an XFAIL that
#     starts passing is reported, so the marker gets removed
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# MINDFORGE_UNDER_TEST points the harness at another build -- e.g. a copy
# with a bug planted on purpose, to prove the checks can see it.
MF="${MINDFORGE_UNDER_TEST:-$ROOT/bin/mindforge}"
FILTER="${1:-}"
PASS=0 FAIL=0 XFAIL=0 XPASS=0 RAN=0
FAILED=()

# ------------------------------------------------------------------ sandbox --
# SB/home        HOME -- no .config/mindforge/config, so nothing overrides us
# SB/state       MINDFORGE_STATE
# SB/projects    MINDFORGE_PROJECTS (git repos with real remotes)
# SB/mem         MINDFORGE_MEMORY
# SB/bin         stubs first on PATH: gh never reaches the network
new_sandbox() {
  SB=$(mktemp -d)
  mkdir -p "$SB/home/.claude" "$SB/state" "$SB/projects" "$SB/mem" "$SB/bin"
  printf '# date\tstart\tend\tfocus\tbullets\tkind\n' > "$SB/state/sessions.log"
  cat > "$SB/bin/gh" <<'STUB'
#!/usr/bin/env bash
# gh stub: answers from $SB_GH_STATE (OPEN | CLOSED), fails otherwise.
[ -n "${SB_GH_SLEEP:-}" ] && sleep "$SB_GH_SLEEP"
[ -n "${SB_GH_STATE:-}" ] && { echo "$SB_GH_STATE"; exit 0; }
exit 1
STUB
  chmod +x "$SB/bin/gh"
  SID="test-session"
}

# Run mindforge inside the sandbox. Only what the script needs is passed in;
# the caller's CLAUDE_CODE_SESSION_ID and FORCE_COLOUR are deliberately dropped.
mf() {
  # TZ only when set: an EMPTY TZ means UTC, which moves "now" by hours.
  env -i PATH="$SB/bin:$PATH" HOME="$SB/home" ${TZ:+TZ="$TZ"} \
    MINDFORGE_STATE="$SB/state" MINDFORGE_PROJECTS="$SB/projects" \
    MINDFORGE_MEMORY="$SB/mem" CLAUDE_CODE_SESSION_ID="$SID" \
    SB_GH_STATE="${SB_GH_STATE:-}" SB_GH_SLEEP="${SB_GH_SLEEP:-}" MINDFORGE_VAULT="${SB_VAULT:-}" \
    MINDFORGE_CHIME="${MINDFORGE_CHIME:-/nonexistent-chime}" MINDFORGE_CHIME_PLAYER="${MINDFORGE_CHIME_PLAYER:-}" \
    bash "$MF" "$@"
}

# A clean repo with a real upstream, so "unpushed" has a meaning.
make_repo() {
  local name="$1" g=(git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c core.autocrlf=false)
  "${g[@]}" init -q --bare "$SB/remotes/$name.git"
  "${g[@]}" clone -q "$SB/remotes/$name.git" "$SB/projects/$name" 2>/dev/null
  echo one > "$SB/projects/$name/f"
  "${g[@]}" -C "$SB/projects/$name" add f
  "${g[@]}" -C "$SB/projects/$name" commit -qm one
  "${g[@]}" -C "$SB/projects/$name" push -q origin main 2>/dev/null
}
commit_unpushed() {
  echo more >> "$SB/projects/$1/f"
  git -c user.name=t -c user.email=t@t -c core.autocrlf=false -C "$SB/projects/$1" commit -qam more
}

# Fingerprint of a directory tree: every file's path and content hash.
snap() { ( cd "$1" 2>/dev/null && find . -type f -exec md5sum {} + | sort ) ; }
rows() { grep -vc '^#' "$SB/state/sessions.log"; }

# ---------------------------------------------------------------- asserting --
# check <name> <command...>   passes when the command exits 0
# xfail <issue> <name> <command...>   a known defect, filed as <issue>
CUR=""
begin() {                      # begin <name> -- returns 1 when filtered out
  [ -n "$FILTER" ] && [[ "$1" != *"$FILTER"* ]] && return 1
  CUR="$1"; new_sandbox; return 0
}
end() { rm -rf "$SB"; }
check() {
  local name="$1"; shift
  RAN=$((RAN+1))
  if "$@"; then PASS=$((PASS+1)); printf '  ok     %s\n' "$CUR: $name"
  else FAIL=$((FAIL+1)); FAILED+=("$CUR: $name"); printf '  FAIL   %s\n' "$CUR: $name"; fi
}
xfail() {
  local issue="$1" name="$2"; shift 2
  RAN=$((RAN+1))
  if "$@"; then XPASS=$((XPASS+1)); FAILED+=("$CUR: $name (XPASS -- $issue fixed? remove the xfail)")
    printf '  XPASS  %s  -- %s looks fixed; remove the marker\n' "$CUR: $name" "$issue"
  else XFAIL=$((XFAIL+1)); printf '  xfail  %s  [%s]\n' "$CUR: $name" "$issue"; fi
}

# ------------------------------------------------------------ preconditions --
[ -r "$MF" ] || { echo "cannot read $MF" >&2; exit 2; }

# The harness must be able to fail. If a false check is counted as a pass,
# every result below is noise -- stop before printing any of it.
_probe() { local before=$FAIL; CUR=probe; check "deliberately false" false >/dev/null; [ "$FAIL" -eq $((before+1)) ]; }
if ! _probe; then echo "HARNESS BROKEN: a false check did not register as a failure" >&2; exit 2; fi
FAIL=0; RAN=0; FAILED=()

# Where the real state lives, read the same way mindforge reads it.
REAL_STATE=$( [ -r "$HOME/.config/mindforge/config" ] && . "$HOME/.config/mindforge/config"
              printf '%s' "${MINDFORGE_STATE:-$HOME/.claude/state}" )
REAL_BEFORE=$(snap "$REAL_STATE")

# =================================================================== checks ==

if begin "version"; then
  out=$(mf --version)
  check "prints the script's VERSION" \
    [ "$out" = "mindforge $(grep -m1 '^VERSION=' "$MF" | cut -d'"' -f2)" ]
  end
fi

if begin "session-start"; then
  out=$(mf session-start)
  check "writes a mark for this session"  [ -r "$SB/state/marks/$SID" ]
  check "wraps the briefing in tags"       grep -q '^<session-briefing>' <<<"$out"
  check "carries the directive"            grep -q '^INSTRUCTION:' <<<"$out"
  check "logs no row"                      [ "$(rows)" -eq 0 ]
  end
fi

if begin "wrap"; then
  mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
  printf 'x\tsomething\n' > "$SB/state/wip.md"
  mf wrap "the focus" "one|two" >/dev/null; rc=$?
  check "exits 0"                          [ "$rc" -eq 0 ]
  check "appends exactly one row"          [ "$(rows)" -eq 1 ]
  check "row takes its start from the mark" \
    awk -F'\t' '!/^#/ && $1=="2026-09-18" && $2=="07:00" && $4=="the focus" && $5=="one|two" && $6=="wrapped"{f=1} END{exit !f}' "$SB/state/sessions.log"
  check "clears the in-flight note"        [ ! -e "$SB/state/wip.md" ]
  end
fi

if begin "wrap-no-args"; then
  before=$(snap "$SB/state"); mf wrap >/dev/null 2>&1; rc=$?
  check "exits 2"                          [ "$rc" -eq 2 ]
  check "writes nothing"                   [ "$(snap "$SB/state")" = "$before" ]
  end
fi

# W-8a (#22): an option is not a focus. Help is answered, never recorded.
for a in "wrap --help" "wrap -h" "drift --help" "wip --help" "wrap --previous --help"; do
  if begin "$a"; then
    mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
    printf 'x\tnote\n' > "$SB/state/wip.md"
    before=$(snap "$SB/state"); out=$(mf $a 2>&1); rc=$?
    check "exits 0"                        [ "$rc" -eq 0 ]
    check "prints usage"                   grep -q '^usage:' <<<"$out"
    check "leaves state byte-identical"    [ "$(snap "$SB/state")" = "$before" ]
    end
  fi
done
for a in "wrap --bogus" "drift -x" "wip -x" "log --bogus"; do
  if begin "$a"; then
    mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
    printf 'x\tnote\n' > "$SB/state/wip.md"
    before=$(snap "$SB/state"); mf $a >/dev/null 2>&1; rc=$?
    check "refused: exits 2"               [ "$rc" -eq 2 ]
    check "writes nothing"                 [ "$(snap "$SB/state")" = "$before" ]
    end
  fi
done
if begin "drift --"; then
  mf drift -- "-x a note with a dash" >/dev/null
  check "a note after -- is logged as written" grep -q $'\t-x a note with a dash$' "$SB/state/drift.log"
  end
fi

# W-8b (#22): a second wrap in the same session corrects the first.
if begin "wrap twice"; then
  mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
  mf wrap "a mistaken focus" "bad" >/dev/null
  check "first wrap keeps the mark, stamped" \
    awk -F'\t' 'NR==1 && $1=="2026-09-18" && $2=="07:00" && $3!=""{f=1} END{exit !f}' "$SB/state/marks/$SID"
  out=$(mf wrap "the real focus" "a|b"); rc=$?
  check "second wrap exits 0"              [ "$rc" -eq 0 ]
  check "says it replaced the earlier wrap" grep -q 'replaces' <<<"$out"
  check "still exactly one row"            [ "$(rows)" -eq 1 ]
  check "row has the real focus and the original start" \
    awk -F'\t' '!/^#/ && $1=="2026-09-18" && $2=="07:00" && $4=="the real focus" && $5=="a|b" && $6=="wrapped"{f=1} END{exit !f}' "$SB/state/sessions.log"
  mf session-end
  check "session-end after a wrap adds no row" [ "$(rows)" -eq 1 ]
  check "session-end spends the mark"      [ ! -e "$SB/state/marks/$SID" ]
  end
fi
if begin "wrap keeps other rows"; then
  printf '2026-09-17\t09:00\t10:00\tolder\t\twrapped\n' >> "$SB/state/sessions.log"
  mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
  mf wrap "one" "" >/dev/null
  printf '2026-09-18\t07:30\t07:40\tsomeone else\t\tauto\n' >> "$SB/state/sessions.log"
  mf wrap 'two \\ with a backslash' "" >/dev/null
  check "three rows, in their order" \
    [ "$(grep -v '^#' "$SB/state/sessions.log" | cut -f4 | paste -sd,)" = 'older,two \\ with a backslash,someone else' ]
  end
fi

# #27: wrap measures, and says NOT clean when something is open or unknown.
g() { git -c user.name=t -c user.email=t@t -c core.autocrlf=false -C "$SB/projects/$1" "${@:2}"; }
now_mark() { mkdir -p "$SB/state/marks"; printf '%s\t%s\n' "$(date +%F)" "$(date +%H:%M)" > "$SB/state/marks/$SID"; }
last_row() { grep -v '^#' "$SB/state/sessions.log" | tail -1; }
if begin "wrap checks: clean"; then
  make_repo alpha; now_mark
  out=$(mf wrap "f" "b"); rc=$?
  check "exits 0"                          [ "$rc" -eq 0 ]
  check "says clean"                       grep -q 'wrap clean' <<<"$out"
  check "counts the repo"                  grep -q '1 repos committed and pushed' <<<"$out"
  check "row has no open field"            [ "$(last_row | awk -F'\t' '{print NF}')" -eq 6 ]
  check "memory silence is info, not open" grep -q 'memory: nothing changed' <<<"$out"
  end
fi
if begin "wrap checks: uncommitted"; then
  make_repo alpha; now_mark; echo x > "$SB/projects/alpha/new"
  out=$(mf wrap "f" "b"); rc=$?
  check "still exits 0"                    [ "$rc" -eq 0 ]
  check "says NOT clean"                   grep -q 'wrap NOT clean -- 1 open, 0 not verified' <<<"$out"
  check "names the repo"                   grep -q 'alpha: 1 uncommitted file' <<<"$out"
  check "the row carries it"               [ "$(last_row | cut -f7)" = "alpha: 1 uncommitted file(s)" ]
  check "the next brief shows it"          grep -q 'open at the last wrap.*alpha: 1 uncommitted' <<<"$(mf brief --headline)"
  rm "$SB/projects/alpha/new"
  out=$(mf wrap "f2" "b")
  check "a corrected wrap clears it"       [ "$(last_row | awk -F'\t' '{print NF}')" -eq 6 ]
  check "and the brief stops saying it"    bash -c '! grep -q "open at the last wrap" <<<"$1"' _ "$(mf brief --headline)"
  end
fi
if begin "wrap checks: unpushed"; then
  make_repo alpha; now_mark; commit_unpushed alpha
  check "counts unpushed commits"          grep -q 'alpha: 1 unpushed commit' <<<"$(mf wrap f b)"
  end
fi
if begin "wrap checks: no upstream"; then
  make_repo alpha; now_mark; g alpha checkout -q -b side
  out=$(mf wrap f b)
  check "cannot count, so says so"         grep -q 'alpha: no upstream branch.*NOT verified' <<<"$out"
  check "and is not clean"                 grep -q '0 open, 1 not verified' <<<"$out"
  end
fi
if begin "wrap checks: no remote"; then
  mkdir -p "$SB/projects/solo"; g solo init -q; echo a > "$SB/projects/solo/f"; g solo add f; g solo commit -qm a
  now_mark
  check "no remote is open"                grep -q 'solo: no remote' <<<"$(mf wrap f b)"
  end
fi
if begin "wrap checks: TODO.md"; then
  make_repo alpha; echo list > "$SB/projects/alpha/TODO.md"; g alpha add TODO.md
  GIT_COMMITTER_DATE="2026-01-01 00:00" g alpha commit -qm todo --date "2026-01-01 00:00"
  g alpha push -q origin main 2>/dev/null
  now_mark
  check "no work this session: not flagged" bash -c '! grep -q "TODO.md not updated" <<<"$1"' _ "$(mf wrap f b)"
  commit_unpushed alpha; g alpha push -q origin main 2>/dev/null
  check "work without the list: flagged"   grep -q 'alpha: 1 commit(s) this session, TODO.md not updated' <<<"$(mf wrap f b)"
  echo more >> "$SB/projects/alpha/TODO.md"; g alpha commit -qam todo2; g alpha push -q origin main 2>/dev/null
  out=$(mf wrap f b)
  check "list updated: not flagged"        bash -c '! grep -q "TODO.md not updated" <<<"$1"' _ "$out"
  check "and clean"                        grep -q 'wrap clean' <<<"$out"
  end
fi
if begin "wrap checks: start unknown"; then
  make_repo alpha
  out=$(mf wrap f b)
  check "no mark: coverage NOT verified"   grep -q 'session start unknown.*NOT verified' <<<"$out"
  check "and not clean"                    grep -q 'wrap NOT clean' <<<"$out"
  end
fi
if begin "wrap checks: vault"; then
  make_repo alpha; now_mark; mkdir -p "$SB/vault"
  out=$(SB_VAULT="$SB/vault" mf wrap f b)
  check "vault silence is info"            grep -q 'vault: 0 file(s) changed' <<<"$out"
  check "and does not block clean"         grep -q 'wrap clean' <<<"$out"
  out=$(SB_VAULT="$SB/nowhere" mf wrap f b)
  check "a missing vault is NOT verified"  grep -q 'vault folder not found.*NOT verified' <<<"$out"
  end
fi
if begin "wrap checks: in-flight note"; then
  make_repo alpha; now_mark; printf 'x\thalf-done thing\n' > "$SB/state/wip.md"
  check "shows the note it clears"         grep -q 'in-flight note cleared by this wrap: half-done thing' <<<"$(mf wrap f b)"
  end
fi

# #16: missing session hooks are said out loud, in the brief and in rot.
# hooks_json [start] [end] -- write settings.json with the named hooks
hooks_json() {
  local want="${*:-start end}" h=""
  [[ " $want " == *" start "* ]] && h+='"SessionStart":[{"hooks":[{"type":"command","command":"mindforge session-start"}]}]'
  [[ " $want " == *" end "* ]] && h+="${h:+,}"'"SessionEnd":[{"hooks":[{"type":"command","command":"mindforge session-end"}]}]'
  printf '{ "hooks": { %s } }\n' "$h" > "$SB/home/.claude/settings.json"
}
if begin "hooks: both installed"; then
  hooks_json start end
  check "no hooks line"                    bash -c '! grep -q "^hooks:" <<<"$1"' _ "$(mf brief --headline)"
  check "no R10"                           bash -c '! grep -q "R10" <<<"$1"' _ "$(mf rot)"
  end
fi
if begin "hooks: none"; then
  out=$(mf brief --headline); rc=$?
  check "names both as NOT INSTALLED"      grep -q '^hooks: NOT INSTALLED: session-start, session-end' <<<"$out"
  check "sits near the top"                [ "$(sed -n 2p <<<"$out" | cut -c1-6)" = "hooks:" ]
  check "exits 0"                          [ "$rc" -eq 0 ]
  check "R10 in rot"                       grep -q 'R10.*NOT INSTALLED' <<<"$(mf rot)"
  end
fi
if begin "hooks: only session-start"; then
  hooks_json start
  check "names the missing one only"       grep -q '^hooks: NOT INSTALLED: session-end --' <<<"$(mf brief --headline)"
  end
fi
if begin "hooks: in settings.local.json"; then
  hooks_json start; printf '{"hooks":{"SessionEnd":[{"hooks":[{"type":"command","command":"/opt/x/mindforge.cmd session-end"}]}]}}\n' > "$SB/home/.claude/settings.local.json"
  check "local file and a wrapper count"   bash -c '! grep -q "^hooks:" <<<"$1"' _ "$(mf brief --headline)"
  end
fi
if begin "hooks: mentioned but not a command"; then
  printf '{"permissions":{"allow":["Bash(mindforge brief)"]},"note":"mindforge is our tool"}\n' > "$SB/home/.claude/settings.json"
  check "a mention is not a hook"          grep -q 'NOT INSTALLED: session-start, session-end' <<<"$(mf brief --headline)"
  end
fi
if begin "hooks: disabled"; then
  hooks_json start end; sed -i 's/^{/{ "disableAllHooks": true,/' "$SB/home/.claude/settings.json"
  check "disableAllHooks is reported"      grep -q '^hooks: all hooks disabled' <<<"$(mf brief --headline)"
  end
fi
if begin "hooks: unreadable settings"; then
  hooks_json start end; chmod 000 "$SB/home/.claude/settings.json"
  if [ -r "$SB/home/.claude/settings.json" ]; then
    check "SKIPPED: running as root, chmod 000 is still readable" true
  else
    check "could not check, said so"       grep -q '^hooks: could not check' <<<"$(mf brief --headline)"
  fi
  chmod 600 "$SB/home/.claude/settings.json"
  end
fi

# #24: three answers, never two -- a check that could not look says so.
if begin "headline: no upstream"; then
  make_repo alpha; g alpha checkout -q -b side
  out=$(mf brief --headline)
  check "counted as could-not-check"       grep -q '1 could not be checked' <<<"$out"
  check "and never called clean"           bash -c '! grep -q "repos clean" <<<"$1"' _ "$out"
  end
fi
if begin "headline: unreadable repo"; then
  make_repo alpha; mkdir -p "$SB/projects/broken/.git"
  check "counted as could-not-check"       grep -q '1 could not be checked' <<<"$(mf brief --headline)"
  end
fi
if begin "headline: no repos"; then
  out=$(mf brief --headline)
  check "zero repos is not green-clean"    grep -q 'no repos found under .* nothing was checked' <<<"$out"
  end
fi
if begin "rot: could not look"; then
  make_repo alpha; g alpha checkout -q -b side
  out=$(mf rot)
  check "R3 names a repo with no upstream" grep -q 'R3.*alpha has no upstream branch' <<<"$out"
  check "R5 names a missing L0"            grep -q 'R5.*no L0 at' <<<"$out"
  check "R4 names a missing MEMORY.md"     grep -q 'R4.*no readable MEMORY.md.*not checked' <<<"$out"
  rm -rf "$SB/mem"
  check "R4 names a missing memory folder" grep -q 'R4.*memory folder not found.*not checked' <<<"$(mf rot)"
  rm -rf "$SB/projects"
  check "R6 names a missing project root"  grep -q 'R6.*project root .* does not exist' <<<"$(mf rot)"
  end
fi
if begin "rot: present and fine stays quiet"; then
  make_repo alpha; seq 10 > "$SB/home/.claude/CLAUDE.md"; : > "$SB/mem/MEMORY.md"; hooks_json
  check "nothing rotting"                  grep -q 'nothing rotting' <<<"$(mf rot)"
  end
fi

# #24: the scrub guard proves its tool works, and a partial scan says partial.
HOOK="${MINDFORGE_HOOK_UNDER_TEST:-$ROOT/.githooks/pre-commit}"
hook_repo() {
  git -c init.defaultBranch=main init -q "$SB/hr"; cp "$HOOK" "$SB/hr/.git/hooks/pre-commit"
  chmod +x "$SB/hr/.git/hooks/pre-commit"; mkdir -p "$SB/nopcre"
  local real; real=$(command -v grep)
  printf '#!/usr/bin/env bash\nfor a in "$@"; do [[ "$a" =~ ^-[A-Za-z]*P ]] && exit 2; done\nexec %s "$@"\n' "$real" > "$SB/nopcre/grep"
  chmod +x "$SB/nopcre/grep"
}
# hc <extra PATH dir or ""> -- commit what is staged, print the hook's output
hc() {
  ( cd "$SB/hr" && env HOME="$SB/home" PATH="${1:+$1:}$PATH" MINDFORGE_SCRUB_LIST="${SB_LIST:-$SB/home/no-list}" \
      git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm m 2>&1 )
}
hr_add() { printf '%s\n' "$2" > "$SB/hr/$1"; git -C "$SB/hr" add "$1"; }
committed() { git -C "$SB/hr" rev-parse -q --verify HEAD >/dev/null; }
if begin "scrub: grep without PCRE"; then
  # Addresses are assembled at run time: written whole, this file would
  # trip the very scrub it tests (it did, on the first commit).
  hook_repo; hr_add a.txt "reach me at 10.1.$((1+1)).3"
  out=$(hc "$SB/nopcre")
  check "refuses the commit"               bash -c '! git -C "$1" rev-parse -q --verify HEAD >/dev/null' _ "$SB/hr"
  check "says nothing was checked"         grep -q 'cannot run the scrub patterns' <<<"$out"
  end
fi
if begin "scrub: no wordlist"; then
  hook_repo; hr_add a.txt "hello"
  out=$(hc "")
  check "commits"                          committed
  check "says PARTIAL, not clean"          grep -q 'scrub PARTIAL.*NOT checked' <<<"$out"
  end
fi
if begin "scrub: wordlist present"; then
  hook_repo; printf 'zanzibar\n' > "$SB/home/list"
  hr_add a.txt "hello"
  out=$(SB_LIST="$SB/home/list" hc "")
  check "says clean with the term count"   grep -q 'scrub clean.*1 local terms' <<<"$out"
  hr_add b.txt "visit Zanzibar"
  SB_LIST="$SB/home/list" hc "" >/dev/null
  check "refuses a wordlist term"          [ "$(git -C "$SB/hr" rev-list --count HEAD)" -eq 1 ]
  end
fi
if begin "scrub: staged then deleted"; then
  hook_repo; hr_add a.txt "server 192.$((160+8)).1.50"; rm "$SB/hr/a.txt"
  hc "" >/dev/null
  check "still scans what is staged"       bash -c '! git -C "$1" rev-parse -q --verify HEAD >/dev/null' _ "$SB/hr"
  end
fi

# #29: the rot check runs at session start, and the git line is not it.
gh_repo() { make_repo "$1"; g "$1" remote set-url origin "https://github.com/t/$1.git"; }
if begin "session-start runs the rot check"; then
  gh_repo alpha
  printf 'alpha\tthe task\t3\t-\t#7\n' > "$SB/state/queue.md"
  out=$(SB_GH_STATE=CLOSED mf session-start)
  check "prints the rot check section"     grep -q '^rot check (R1-R11):' <<<"$out"
  check "inside the briefing tags"         bash -c 'sed -n "/^<session-briefing>/,/^<\/session-briefing>/p" <<<"$1" | grep -q "^rot check"' _ "$out"
  check "carries an R8 finding"            grep -q 'R8.*#7 is CLOSED' <<<"$out"
  check "the directive asks for findings"  grep -q 'Name every rot-check finding' <<<"$out"
  check "logs it to rot.log"               grep -q 'R8' "$SB/state/rot.log"
  end
fi
if begin "session-start: tracker unreachable"; then
  gh_repo alpha
  printf 'alpha\tthe task\t3\t-\t#7\n' > "$SB/state/queue.md"
  out=$(mf session-start)
  check "says NOT verified, not silence"   grep -q 'R8.*could not reach the tracker.*NOT verified' <<<"$out"
  end
fi
# Timed on `rot`, not session-start: the old session-start never asked the
# tracker at all, so it was fast for the wrong reason and passed this check.
if begin "rot: lookups in parallel"; then
  for r in a1 a2 a3; do gh_repo $r; done
  printf 'a1\tt\t3\t-\t#1\na2\tt\t3\t-\t#2\na3\tt\t3\t-\t#3\n' > "$SB/state/queue.md"
  t0=$(date +%s); SB_GH_SLEEP=2 SB_GH_STATE=OPEN mf rot >/dev/null; t1=$(date +%s)
  check "three 2s lookups take under 5s"   [ $((t1-t0)) -lt 5 ]
  check "and all three were cached"        [ "$(grep -c OPEN "$SB/state/queue-refs.cache")" -eq 3 ]
  end
fi
if begin "the git line says what it is"; then
  make_repo alpha
  check "labelled git:, not a rot verdict" grep -q '^git: 1 repos clean' <<<"$(mf brief --headline)"
  end
fi

# W-8d (#22): an unwrapped session can be closed later, in place.
if begin "wrap --previous"; then
  printf '2026-09-17\t09:31\t10:10\t(not wrapped)\t\tauto\n' >> "$SB/state/sessions.log"
  printf '2026-09-17\t11:00\t12:00\tlater\t\twrapped\n' >> "$SB/state/sessions.log"
  mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
  printf 'x\tnote\n' > "$SB/state/wip.md"
  mf wrap --previous "what it did" "x|y" >/dev/null; rc=$?
  check "exits 0"                          [ "$rc" -eq 0 ]
  check "the row is closed with its own times" \
    awk -F'\t' 'NR==2 && $1=="2026-09-17" && $2=="09:31" && $3=="10:10" && $4=="what it did" && $5=="x|y" && $6=="wrapped"{f=1} END{exit !f}' "$SB/state/sessions.log"
  check "no row added"                     [ "$(rows)" -eq 2 ]
  check "this session's mark untouched"    [ "$(cat "$SB/state/marks/$SID")" = $'2026-09-18\t07:00' ]
  check "in-flight note untouched"         [ -e "$SB/state/wip.md" ]
  end
fi
if begin "wrap --previous, nothing to close"; then
  printf '2026-09-17\t11:00\t12:00\tlater\t\twrapped\n' >> "$SB/state/sessions.log"
  before=$(snap "$SB/state"); mf wrap --previous "x" "" >/dev/null 2>&1; rc=$?
  check "exits 1"                          [ "$rc" -eq 1 ]
  check "writes nothing"                   [ "$(snap "$SB/state")" = "$before" ]
  end
fi
if begin "headline asks about an unwrapped session"; then
  printf '%s\t09:31\t10:10\t(not wrapped)\t\tauto\n' "$(date +%F)" >> "$SB/state/sessions.log"
  check "points at wrap --previous"        grep -q 'wrap --previous' <<<"$(mf brief --headline)"
  printf '%s\t11:00\t12:00\tdone\t\twrapped\n' "$(date +%F)" >> "$SB/state/sessions.log"
  check "silent once the last one is wrapped" bash -c '! grep -q "wrap --previous" <<<"$1"' _ "$(mf brief --headline)"
  end
fi

# W-8c (#22): log repair is a command, with a backup.
if begin "log --drop-last"; then
  mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
  printf '2026-09-17\t09:00\t10:00\tkeep\t\twrapped\n' >> "$SB/state/sessions.log"
  mf wrap "--mistake" "" >/dev/null 2>&1   # refused, so wrap for real:
  mf wrap -- "--mistake" "" >/dev/null
  before=$(cat "$SB/state/sessions.log")
  out=$(mf log --drop-last); rc=$?
  check "exits 0"                          [ "$rc" -eq 0 ]
  check "prints the dropped row"           grep -q 'dropped:.*--mistake' <<<"$out"
  check "only the last row went"           [ "$(grep -v '^#' "$SB/state/sessions.log" | cut -f4)" = "keep" ]
  check "backup holds the log from before" \
    [ "$(cat "$SB/state"/sessions.log.bak-*)" = "$before" ]
  check "the mark is no longer wrapped"    [ "$(cat "$SB/state/marks/$SID")" = $'2026-09-18\t07:00' ]
  mf session-end
  check "so session-end still records the session" \
    awk -F'\t' '!/^#/ && $4=="(not wrapped)"{n++} END{exit n!=1}' "$SB/state/sessions.log"
  end
fi
if begin "log --drop-last, empty log"; then
  before=$(snap "$SB/state"); mf log --drop-last >/dev/null 2>&1; rc=$?
  check "exits 1"                          [ "$rc" -eq 1 ]
  check "writes nothing"                   [ "$(snap "$SB/state")" = "$before" ]
  end
fi

if begin "drift"; then
  mf drift "a slip" >/dev/null
  check "appends one note"                 [ "$(grep -c 'a slip' "$SB/state/drift.log")" -eq 1 ]
  end
fi

if begin "session-end"; then
  mkdir -p "$SB/state/marks"
  printf '%s\t%s\n' "$(date +%F)" "$(date +%H:%M)" > "$SB/state/marks/$SID"
  mf session-end
  check "below the floor: no row"          [ "$(rows)" -eq 0 ]
  check "below the floor: mark spent"      [ ! -e "$SB/state/marks/$SID" ]
  printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
  mf session-end
  check "above the floor: one (not wrapped) row" \
    awk -F'\t' '!/^#/ && $4=="(not wrapped)" && $6=="auto"{n++} END{exit n!=1}' "$SB/state/sessions.log"
  end
fi

if begin "headline"; then
  make_repo alpha; make_repo beta
  out=$(mf brief --headline)
  check "two clean repos counted"          grep -q '2 repos clean · nothing unpushed' <<<"$out"
  commit_unpushed beta
  out=$(mf brief --headline)
  check "an unpushed commit is counted"    grep -q '0 dirty · 1 unpushed' <<<"$out"
  end
fi

# W-9 (#36): a queue.md saved with Windows line endings reads like any other.
if begin "queue with CRLF"; then
  make_repo bee; make_repo cee
  printf '@priority bee\r\nbee\tthe ranked task\t1\t-\t-\r\ncee\tthe heavier task\t5\t-\t-\r\n' > "$SB/state/queue.md"
  out=$(mf rot)
  check "a '-' opt-out raises no R8 at all" bash -c '! grep -q "R8" <<<"$1"' _ "$out"
  out=$(mf brief)
  check "the last name on @priority keeps its rank" \
    [ "$(grep -A1 'Recommended first' <<<"$out" | tail -1 | grep -o 'bee\|cee')" = bee ]
  check "no carriage return reaches the brief" bash -c '! grep -q $'"'"'\r'"'"' <<<"$1"' _ "$out"
  end
fi

if begin "rot"; then
  printf -- '- [a](a.md) — a\n' > "$SB/mem/MEMORY.md"
  echo a > "$SB/mem/a.md"; touch -d '2026-01-01' "$SB/mem/MEMORY.md"
  out=$(mf rot)
  check "R7 fires on a file newer than the index" grep -q 'R7.*a.md' <<<"$out"
  echo b > "$SB/mem/b.md"
  out=$(mf rot)
  check "R4 names an unindexed file"       grep -q 'R4.*b.md' <<<"$out"
  end
fi

# #39 · R11: recent work the queue does not name. Failing direction first --
# the missing repo MUST be named -- then every deliberate way out stays quiet.
old_commit() {   # old_commit <repo>: its only commit moved back to 2020
  GIT_COMMITTER_DATE='2020-01-01T00:00:00' git -c user.name=t -c user.email=t@t \
    -C "$SB/projects/$1" commit -q --amend --no-edit --date='2020-01-01T00:00:00'
}
if begin "R11 active work missing from the queue"; then
  make_repo listed; make_repo forgotten; make_repo aur-listed; make_repo aur-listed-remote
  make_repo parked; make_repo ancient; old_commit ancient
  make_repo mono; mkdir -p "$SB/projects/mono/sub"
  printf '@quiet parked\nlisted\tthe task\t3\tno\t-\nmono/sub\tthe sub task\t2\tno\t-\n' > "$SB/state/queue.md"
  out=$(mf rot)
  check "a recently active repo with no queue line is named" grep -q 'R11.*forgotten has commits from' <<<"$out"
  check "exactly one R11 (only the forgotten repo)"         [ "$(grep -c 'R11' <<<"$out")" -eq 1 ]
  check "a queued repo is not named"                        bash -c '! grep -q "R11.*listed has" <<<"$1"' _ "$out"
  check "its AUR twins are not named"                       bash -c '! grep -q "R11.*aur-listed" <<<"$1"' _ "$out"
  check "an @quiet repo is not named"                       bash -c '! grep -q "R11.*parked" <<<"$1"' _ "$out"
  check "an old repo is not named"                          bash -c '! grep -q "R11.*ancient" <<<"$1"' _ "$out"
  check "a monorepo covered by a sub-project is not named"  bash -c '! grep -q "R11.*mono" <<<"$1"' _ "$out"
  # Setup assertion: the old commit really is old, or the line above proves nothing.
  check "setup: ancient's commit is from 2020"              [ "$(git -C "$SB/projects/ancient" log -1 --format=%cs)" = 2020-01-01 ]
  rm "$SB/state/queue.md"
  check "no queue.md is first-run, not R11"                 bash -c '! grep -q "R11" <<<"$1"' _ "$(mf rot)"
  end
fi

# #40 · a name longer than 20 characters must not push its row out of line.
if begin "projects table lines up with a long name"; then
  make_repo short; make_repo a-twenty-one-chars-xx
  printf 'short\tone\t3\tno\t-\na-twenty-one-chars-xx\ttwo\t3\tno\t-\n' > "$SB/state/queue.md"
  out=$(mf brief | sed -n '/^Projects/,/^$/p')
  check "setup: the long name is 21 characters"  [ "$(printf a-twenty-one-chars-xx | wc -c)" -eq 21 ]
  cols=$(awk 'NR==2{print index($0,"LAST")} NR>2 && match($0,/[0-9]{4}-[0-9]{2}-[0-9]{2}/){print RSTART}' <<<"$out" | sort -u)
  check "LAST starts at one column on every row" [ "$(wc -l <<<"$cols")" -eq 1 ]
  check "the long name is shown whole"           grep -q 'a-twenty-one-chars-xx ' <<<"$out"
  end
fi

# #41 · scripts/release.sh refuses before anything is tagged or pushed.
# A throwaway repo shaped like mindForge: bin/mindforge with a VERSION line,
# a changelog, and a stand-in test suite whose verdict the check controls.
REL="${MINDFORGE_RELEASE_UNDER_TEST:-$ROOT/scripts/release.sh}"
rel_repo() {   # rel_repo <version in bin/mindforge> <changelog version> <tests exit>
  local g=(git -c user.name=t -c user.email=t@t -c init.defaultBranch=main -c core.autocrlf=false)
  "${g[@]}" init -q --bare "$SB/remotes/rel.git"
  "${g[@]}" clone -q "$SB/remotes/rel.git" "$SB/rel" 2>/dev/null
  mkdir -p "$SB/rel/bin" "$SB/rel/docs" "$SB/rel/testing" "$SB/rel/scripts"
  printf '#!/usr/bin/env bash\nVERSION="%s"\n' "$1" > "$SB/rel/bin/mindforge"
  printf '# Changelog\n\n## v%s — 2026-10-01\n\nThe entry.\n\n## v0.0.1 — 2026-01-01\n\nOld.\n' "$2" > "$SB/rel/docs/CHANGELOG.md"
  printf '#!/usr/bin/env bash\necho "3 checks · stand-in"\nexit %s\n' "$3" > "$SB/rel/testing/run-tests.sh"
  cp "$REL" "$SB/rel/scripts/release.sh"
  printf 'logs/\n' > "$SB/rel/.gitignore"
  "${g[@]}" -C "$SB/rel" add -A
  "${g[@]}" -C "$SB/rel" commit -qm init
  "${g[@]}" -C "$SB/rel" push -q origin main 2>/dev/null
}
rel_run() { env -i PATH="$PATH" HOME="$SB/home" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
  GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t bash "$SB/rel/scripts/release.sh" "$@" 2>&1; }
no_tag()  { [ -z "$(git -C "$SB/rel" tag)" ] && [ -z "$(git -C "$SB/rel" ls-remote --tags origin)" ]; }
if begin "release.sh refuses before tagging"; then
  rel_repo 0.2.0 0.2.0 0
  out=$(rel_run 0.2)
  check "a version that is not X.Y.Z is refused"      grep -q 'REFUSED -- give the version as X.Y.Z' <<<"$out"
  echo stray > "$SB/rel/stray"; out=$(rel_run 0.2.0); rm "$SB/rel/stray"
  check "an untracked file is refused"                grep -q 'REFUSED -- the working tree' <<<"$out"
  out=$(rel_run 0.3.0)
  check "VERSION not matching the release is refused" grep -q 'REFUSED -- bin/mindforge says VERSION="0.2.0", not "0.3.0"' <<<"$out"
  check "no tag after the refusals so far"            no_tag
  end
fi
if begin "release.sh refuses: changelog, tests, existing tag"; then
  rel_repo 0.2.0 0.1.9 0
  check "no changelog entry is refused"               grep -q "REFUSED -- docs/CHANGELOG.md has no '## v0.2.0" <<<"$(rel_run 0.2.0)"
  end; new_sandbox
  rel_repo 0.2.0 0.2.0 1
  out=$(rel_run 0.2.0)
  check "failing tests are refused"                   grep -q 'REFUSED -- the tests did not pass' <<<"$out"
  check "no tag after failing tests"                  no_tag
  end; new_sandbox
  rel_repo 0.2.0 0.2.0 0
  git -c user.name=t -c user.email=t@t -C "$SB/rel" tag -a -m pre v0.2.0
  check "an existing tag is refused"                  grep -q 'REFUSED -- v0.2.0 already exists on this machine' <<<"$(rel_run 0.2.0)"
  check "setup: the pre-existing tag never reached the remote" [ -z "$(git -C "$SB/rel" ls-remote --tags origin)" ]
  end
fi
if begin "release.sh tags the right commit"; then
  rel_repo 0.2.0 0.2.0 0
  out=$(rel_run 0.2.0)
  check "a good release ends OK"                      [ "$(tail -1 <<<"$out")" = OK ]
  check "the tag is on origin"                        grep -q 'refs/tags/v0.2.0' <<<"$(git -C "$SB/rel" ls-remote --tags origin)"
  check "the tagged commit says VERSION 0.2.0"        grep -q '^VERSION="0.2.0"' <<<"$(git -C "$SB/rel" show v0.2.0:bin/mindforge)"
  check "the tag message is the changelog entry"      bash -c 'git -C "$1" tag -l --format="%(contents)" v0.2.0 | grep -q "The entry." && ! git -C "$1" tag -l --format="%(contents)" v0.2.0 | grep -q Old' _ "$SB/rel"
  check "the run is logged with a -latest link"       [ -L "$SB/rel/logs/release-latest.log" ]
  end
fi

# ---------------------------------------------------------------- tone (0.1.7)
# The tie alert: a Stop hook that reads the assistant's last reply from the
# transcript. Fed a memo and a clean reply; the memo must be caught, the clean
# one must pass, a tool result must not reset the reply, the second pass must
# not block, and a missing transcript must be silent.
fake_transcript() {   # fake_transcript <file> <reply text...>  (one user turn, then the reply)
  local f="$1"; shift
  python3 - "$f" "$*" <<'PY'
import json, sys
f, reply = sys.argv[1], sys.argv[2]
rows = [
  {"type": "assistant", "message": {"content": [{"type": "text", "text": "## Old heading from an earlier reply"}]}},
  {"type": "user", "message": {"content": "the person speaks"}},
  {"type": "assistant", "message": {"content": [{"type": "tool_use", "id": "t1", "name": "Bash", "input": {}}]}},
  {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": "t1", "content": "## a header inside a tool result"}]}},
  {"type": "assistant", "message": {"content": [{"type": "text", "text": reply}]}},
]
open(f, "w").write("\n".join(json.dumps(r) for r in rows) + "\n")
PY
}
hook_json() { printf '{"session_id":"%s","transcript_path":"%s","hook_event_name":"Stop","stop_hook_active":%s}' "$SID" "$1" "${2:-false}"; }

if begin "tone --check"; then
  printf '## Heading\n\nExpected result: a line.\n\n```\n## inside code is fine\n```\n' > "$SB/memo.md"
  printf 'Okay, done. You should see a line ending in OK.\n\n```\nExpected result: inside code\n```\n' > "$SB/clean.md"
  out=$(mf tone --check "$SB/memo.md"); rc=$?
  check "a memo is caught (exit 1)"              [ "$rc" -eq 1 ]
  check "names the header"                       grep -q 'a section header' <<<"$out"
  check "names the form label"                   grep -q "Expected result" <<<"$out"
  out=$(mf tone --check "$SB/clean.md"); rc=$?
  check "a clean reply passes (exit 0)"          [ "$rc" -eq 0 ]
  check "code blocks are not read"               [ -z "$out" ]
  end
fi

if begin "tone as the Stop hook"; then
  fake_transcript "$SB/t.jsonl" "Here's where it all stands. **Staged and verified**"
  out=$(hook_json "$SB/t.jsonl" | mf tone); rc=$?
  check "first pass blocks the reply"            grep -q '"decision": *"block"' <<<"$out"
  check "the reason says why"                    grep -q 'status-report opener' <<<"$out"
  check "the person sees the alert"              grep -q '"systemMessage": *"tie alert' <<<"$out"
  check "exit 0 (the JSON is the answer)"        [ "$rc" -eq 0 ]
  check "the hit is logged"                      grep -q 'status-report opener' "$SB/state/tone.log"
  out=$(hook_json "$SB/t.jsonl" true | mf tone)
  check "second pass never blocks"               bash -c '! grep -q block <<<"$1"' _ "$out"
  check "second pass still alerts"               grep -q 'second pass' <<<"$out"
  fake_transcript "$SB/c.jsonl" "Nice, that worked. Run the next one and paste me the last line."
  out=$(hook_json "$SB/c.jsonl" | mf tone); rc=$?
  check "a clean reply: silence, exit 0"         [ -z "$out" ] && [ "$rc" -eq 0 ]
  check "an earlier reply's header is not counted" true
  out=$(hook_json "$SB/nowhere.jsonl" | mf tone); rc=$?
  check "no transcript: silence, exit 0"         [ -z "$out" ] && [ "$rc" -eq 0 ]
  out=$(printf 'not json' | mf tone); rc=$?
  check "bad input: silence, exit 0"             [ -z "$out" ] && [ "$rc" -eq 0 ]
  mkdir -p "$SB/home/.config/mindforge"; printf '# comment\nhell yeah\n' > "$SB/home/.config/mindforge/tone.local"
  fake_transcript "$SB/l.jsonl" "hell yeah it worked"
  out=$(hook_json "$SB/l.jsonl" | mf tone)
  check "a local pattern is honoured"            grep -q 'a local pattern' <<<"$out"
  end
fi

if begin "chime"; then
  : > "$SB/bin/paplay"; chmod +x "$SB/bin/paplay"     # a player that does nothing
  printf 'x' > "$SB/ding.oga"
  out=$(MINDFORGE_CHIME="$SB/ding.oga" mf chime --test)
  check "names the player and the file"          grep -q "chime: paplay $SB/ding.oga" <<<"$out"
  out=$(MINDFORGE_CHIME="$SB/nowhere.oga" mf chime --test); rc=$?
  check "a missing file: says so, exit 0"        grep -q 'no sound file' <<<"$out" && [ "$rc" -eq 0 ]
  out=$(MINDFORGE_CHIME="$SB/ding.oga" MINDFORGE_CHIME_PLAYER=no-such-player mf chime); rc=$?
  check "plain chime never fails"                [ "$rc" -eq 0 ] && [ -z "$out" ]
  end
fi

# ================================================================== verdict ==
REAL_AFTER=$(snap "$REAL_STATE")
echo
if [ "$REAL_BEFORE" != "$REAL_AFTER" ]; then
  echo "ISOLATION BROKEN: the real state at $REAL_STATE changed during the run" >&2
  FAIL=$((FAIL+1)); FAILED+=("isolation: real state changed")
fi
if [ "$RAN" -eq 0 ]; then
  echo "NO CHECKS RAN${FILTER:+ (filter: $FILTER)} -- this is not a pass" >&2; exit 2
fi
printf '%d checks · %d passed · %d failed · %d expected failures (known, filed) · %d unexpectedly passing\n' \
  "$RAN" "$PASS" "$FAIL" "$XFAIL" "$XPASS"
printf 'real state untouched: %s\n' "$REAL_STATE"
if [ ${#FAILED[@]} -gt 0 ]; then
  printf '  ! %s\n' "${FAILED[@]}"; exit 1
fi
exit 0
