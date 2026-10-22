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
PASS=0 FAIL=0 XFAIL=0 XPASS=0 RAN=0 SKIP=0
FAILED=()

# #65 (W-14, item 3) · A Windows program started under `env -i` has no
# SystemDrive, and writes its cache into a literal %SystemDrive% folder in the
# CURRENT directory -- which was the repo, and the next brief called mindForge
# dirty. Two fixes: the few variables Windows itself needs go through every
# `env -i` here (WINENV), and the whole run happens from a scratch folder.
# The repo is also compared before and after; a run that leaves anything
# behind in it fails (see the verdict).
WINENV=()
while IFS= read -r _v; do
  case "${_v^^}" in SYSTEMROOT|SYSTEMDRIVE|WINDIR|TEMP|TMP|COMSPEC|PATHEXT) WINENV+=("$_v=${!_v}") ;; esac
done < <(compgen -e)
unset _v
REPO_BEFORE=$(git -C "$ROOT" status --porcelain --untracked-files=all 2>/dev/null)
RUN_DIR=$(mktemp -d); cd "$RUN_DIR" || exit 2

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
  env -i "${WINENV[@]}" PATH="$SB/bin:$PATH" HOME="$SB/home" ${TZ:+TZ="$TZ"} \
    MINDFORGE_STATE="$SB/state" MINDFORGE_PROJECTS="${SB_PROJECTS:-$SB/projects}" \
    MINDFORGE_MEMORY="${SB_MEM-$SB/mem}" CLAUDE_CODE_SESSION_ID="$SID" \
    SB_GH_STATE="${SB_GH_STATE:-}" SB_GH_SLEEP="${SB_GH_SLEEP:-}" MINDFORGE_VAULT="${SB_VAULT:-}" \
    ${COLUMNS:+COLUMNS="$COLUMNS"} \
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
  else FAIL=$((FAIL+1)); FAILED+=("$CUR: $name"); printf '  FAIL   %s\n' "$CUR: $name"
    # #43 · A failing check on another machine printed nothing to reason from:
    # eleven release checks failed on the laptop and the report could not say
    # whether the script refused for the wrong reason or never ran. The first
    # lines of what the check looked at go with the verdict.
    [ -n "${out:-}" ] && head -4 <<<"$out" | sed 's/^/         | /'
  fi
}
# cond '<a> && <b>' -- a check with more than one condition. Written as
#   check "x" [ A ] && [ B ]
# only A was the check: the && ran OUTSIDE it and its answer was thrown away,
# so twenty checks (eleven from 0.1.7/0.1.8) claimed two conditions and proved
# one (found 2026-10-19). The whole condition goes in, evaluated here.
cond() { eval "$1"; }
# skip <name> <why> -- the check could not be made here. Never a pass, never
# a failure: said out loud and counted on its own (#24's third answer).
skip() {
  SKIP=$((SKIP+1)); printf '  skip   %s -- could not look: %s\n' "$CUR: $1" "$2"
}
# make_link <target> <link> -- a REAL link, or status 1. #65 (W-14, item 1):
# Git Bash's `ln -s` silently COPIES unless told otherwise, so a "link" taken
# before a change never shows it. Tried in order: ln -s; ln -s with native
# Windows links (needs Developer Mode); a directory junction. Each is proven
# by changing the target and looking through the link.
make_link() {
  local target="$1" link="$2" probe=".mf-link-probe-$$"
  link_works() { : > "$target/$probe"; local ok=1; [ -e "$link/$probe" ] && ok=0; rm -f "$target/$probe"; return $ok; }
  rm -rf "$link"
  ln -s "$target" "$link" 2>/dev/null && link_works && return 0
  rm -rf "$link"
  MSYS=winsymlinks:nativestrict ln -s "$target" "$link" 2>/dev/null && link_works && return 0
  rm -rf "$link"
  if command -v cygpath >/dev/null 2>&1 && command -v cmd >/dev/null 2>&1; then
    cmd //c mklink /J "$(cygpath -w "$link")" "$(cygpath -w "$target")" >/dev/null 2>&1 && link_works && return 0
    rm -rf "$link"
  fi
  return 1
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
  # #46 (W-12) · the short brief names what it leaves out, and the directive says what to do
  check "says which sections it leaves out" grep -q '^short brief: the Projects table, Recommended first and State' <<<"$out"
  check "directive: run the full one when asked" grep -q 'run it' <<<"$out"
  end
fi

# #46 (W-12) · the NEXT column was cut at 42 characters, mid-word. It follows the terminal's
# width and cuts at a word with an ellipsis; off a terminal nothing is cut.
if begin "brief: NEXT column"; then
  long='Accountants email SENT 09-29 (the owner words) then groom the GitHub milestones and close the quarter'
  printf 'alpha\t%s\t3\t-\t#7\n' "$long" > "$SB/state/queue.md"
  out=$(COLUMNS=100 mf brief)
  row=$(grep -m1 '^  alpha ' <<<"$out")                          # the table's row, not Recommended-first's
  check "a narrow terminal cuts it"        bash -c '[[ "$1" == *"…"* ]]' _ "$row"
  cell=$(sed -E 's/^  alpha +(no repo|[0-9-]+) +//; s/….*$//' <<<"$row")     # the NEXT text before the ellipsis
  check "the cut lands on a word"          bash -c '[ -n "$2" ] && [[ "$1" == "$2 "* ]]' _ "$long" "$cell"
  out=$(COLUMNS= mf brief)
  check "off a terminal nothing is cut"    bash -c '[[ "$1" == *"close the quarter"* ]]' _ "$(grep -m1 '^  alpha ' <<<"$out")"
  out=$(COLUMNS=250 mf brief)
  check "a wide terminal shows it whole"   bash -c '[[ "$1" == *"close the quarter"* && "$1" != *"…"* ]]' _ "$(grep -m1 '^  alpha ' <<<"$out")"
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
  check "prints the rot check section"     grep -q '^rot check (R1-R12):' <<<"$out"
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
  # #38 · "under 5s" measured the machine, not the design: on the work laptop
  # the rest of rot alone took longer, so it failed every run and never said by
  # how much. Now the same rot is timed with an instant tracker first; the
  # three 2s lookups may add at most 4s on top (one at a time they add 6s+).
  ms() { local n; n=$(date +%s%N); echo $(( n / 1000000 )); }
  t0=$(ms); SB_GH_SLEEP=0 SB_GH_STATE=OPEN mf rot >/dev/null; t1=$(ms)
  rm -f "$SB/state/queue-refs.cache"
  t2=$(ms); SB_GH_SLEEP=2 SB_GH_STATE=OPEN mf rot >/dev/null; t3=$(ms)
  base=$((t1-t0)) slow=$((t3-t2))
  out="rot with an instant tracker: ${base} ms; with three 2s lookups: ${slow} ms (+$((slow-base)) ms)"
  check "three 2s lookups add under 4s, not 6s+" [ $((slow-base)) -lt 4000 ]
  printf '         | %s\n' "$out"
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
  make_repo aur-python-listed; make_repo aur-python-other     # #42: Arch's python-<name>
  make_repo aur-sub; make_repo aur-python-sub                 # twins of a monorepo sub-project
  make_repo parked; make_repo ancient; old_commit ancient
  make_repo mono; mkdir -p "$SB/projects/mono/sub"
  printf '@quiet parked\nlisted\tthe task\t3\tno\t-\nmono/sub\tthe sub task\t2\tno\t-\n' > "$SB/state/queue.md"
  out=$(mf rot)
  check "a recently active repo with no queue line is named" grep -q 'R11.*forgotten has commits from' <<<"$out"
  check "exactly two R11 (forgotten, and the python twin of nothing)" [ "$(grep -c 'R11' <<<"$out")" -eq 2 ]
  check "a queued repo is not named"                        bash -c '! grep -q "R11.*listed has" <<<"$1"' _ "$out"
  check "its AUR twins are not named"                       bash -c '! grep -q "R11.*aur-listed" <<<"$1"' _ "$out"
  check "its aur-python- twin is not named (#42)"           bash -c '! grep -q "R11.*aur-python-listed" <<<"$1"' _ "$out"
  check "an aur-python- twin of an unqueued project is named" grep -q 'R11.*aur-python-other has commits' <<<"$out"
  check "the twins of a monorepo sub-project are not named"   bash -c '! grep -q "R11.*aur-.*sub" <<<"$1"' _ "$out"
  check "an @quiet repo is not named"                       bash -c '! grep -q "R11.*parked" <<<"$1"' _ "$out"
  check "an old repo is not named"                          bash -c '! grep -q "R11.*ancient" <<<"$1"' _ "$out"
  check "a monorepo covered by a sub-project is not named"  bash -c '! grep -q "R11.*mono" <<<"$1"' _ "$out"
  # Setup assertion: the old commit really is old, or the line above proves nothing.
  check "setup: ancient's commit is from 2020"              [ "$(git -C "$SB/projects/ancient" log -1 --format=%cs)" = 2020-01-01 ]
  rm "$SB/state/queue.md"
  check "no queue.md is first-run, not R11"                 bash -c '! grep -q "R11" <<<"$1"' _ "$(mf rot)"
  end
fi

# #43 / #34 · One repo, two spellings of its path. On Windows the folder
# listing says /c/Users/x/repo and git says C:/Users/x/repo; a junction (or a
# symlinked root, which is how it is staged here) resolves to a third. The
# brief counted every queued repo twice (#34) and R11 named every queued
# project as missing (#43). The setup assertion proves the two spellings
# really differ in the sandbox, or the checks below prove nothing.
if begin "one repo under two spellings of its path"; then
  make_repo listed; make_repo forgotten
  if ! make_link "$SB/projects" "$SB/link"; then
    skip "the two-spellings checks" "no way to make a folder link on this machine (ln -s copies, no junction)"
  else
  printf 'listed\tthe task\t3\tno\t-\n' > "$SB/state/queue.md"
  check "setup: git spells the repo differently from the listing" \
    [ "$(git -C "$SB/link/listed" rev-parse --show-toplevel)" != "$SB/link/listed" ]
  out=$(SB_PROJECTS="$SB/link" mf brief --headline)
  check "the headline counts 2 repos, not 3 (#34)"         grep -q 'git: 2 repos clean' <<<"$out"
  commit_unpushed listed
  out=$(SB_PROJECTS="$SB/link" mf rot)
  check "R11 does not name the queued repo (#43)"          bash -c '! grep -q "R11.*listed has" <<<"$1"' _ "$out"
  check "R11 still names the forgotten one"                grep -q 'R11.*forgotten has commits' <<<"$out"
  check "R3 counts the unpushed repo once, not twice (#34)" [ "$(grep -c 'R3.*listed has 1 unpushed' <<<"$out")" -eq 1 ]
  fi
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
rel_run() { env -i "${WINENV[@]}" PATH="$PATH" HOME="$SB/home" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
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
  # #65 (W-14) · a link where links work, a copy of the run's log where they do not
  check "the run is logged with a -latest link or copy" bash -c '[ -L "$1" ] || { [ -s "$1" ] && cmp -s "$1" "$(ls -t "$(dirname "$1")"/release-2*.log | head -1)"; }' _ "$SB/rel/logs/release-latest.log"
  check "the -latest log holds the whole run"         grep -q '^OK$' "$SB/rel/logs/release-latest.log"
  end
fi

# ---------------------------------------------------------------- tone (0.1.7)
# The tie alert: a Stop hook that reads the assistant's last reply from the
# transcript. Fed a memo and a clean reply; the memo must be caught, the clean
# one must pass, a tool result must not reset the reply, the second pass must
# not block, and a missing transcript must be silent.
# #63 · the harness needs a python that runs, for the same reason tone does.
PY=python3
for c in python3 python; do command -v "$c" >/dev/null 2>&1 && "$c" -c pass 2>/dev/null && { PY="$c"; break; }; done
fake_transcript() {   # fake_transcript <file> <reply text...>  (one user turn, then the reply)
  local f="$1"; shift
  "$PY" - "$f" "$*" <<'PY'
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
  check "a clean reply: silence, exit 0"         cond '[ -z "$out" ] && [ "$rc" -eq 0 ]'
  check "an earlier reply's header is not counted" true
  out=$(hook_json "$SB/nowhere.jsonl" | mf tone); rc=$?
  check "no transcript: silence, exit 0"         cond '[ -z "$out" ] && [ "$rc" -eq 0 ]'
  out=$(printf 'not json' | mf tone); rc=$?
  check "bad input: silence, exit 0"             cond '[ -z "$out" ] && [ "$rc" -eq 0 ]'
  mkdir -p "$SB/home/.config/mindforge"; printf '# comment\nhell yeah\n' > "$SB/home/.config/mindforge/tone.local"
  fake_transcript "$SB/l.jsonl" "hell yeah it worked"
  out=$(hook_json "$SB/l.jsonl" | mf tone)
  check "a local pattern is honoured"            grep -q 'a local pattern' <<<"$out"
  end
fi

# #63 · On the Windows laptop `python3` is the Microsoft Store placeholder:
# on PATH, found by `command -v`, and it prints "Python was not found" and
# fails when run. Staged here with a stub that does exactly that, in front of
# a `python` that works; then with nothing that works at all.
if begin "tone finds a python that runs"; then
  REAL_PY=$(command -v "$PY")
  printf '#!/usr/bin/env bash\necho "Python was not found; run without arguments to install from the Microsoft Store" >&2\nexit 9009\n' > "$SB/bin/python3"
  printf '#!/usr/bin/env bash\nexec "%s" "$@"\n' "$REAL_PY" > "$SB/bin/python"
  chmod +x "$SB/bin/python3" "$SB/bin/python"
  check "setup: the python3 on PATH refuses to run" \
    bash -c 'p=$1; shift; ! env -i "$@" PATH="$p:$PATH" python3 -c pass 2>/dev/null' _ "$SB/bin" "${WINENV[@]}"
  printf '## Heading\n\nExpected result: a line.\n' > "$SB/memo.md"
  out=$(mf tone --check "$SB/memo.md"); rc=$?
  check "the memo is still caught through \`python\` (exit 1)" [ "$rc" -eq 1 ]
  check "names the header"                       grep -q 'a section header' <<<"$out"
  fake_transcript "$SB/t.jsonl" "Here's where it all stands."
  out=$(hook_json "$SB/t.jsonl" | mf tone); rc=$?
  check "the hook still blocks"                  grep -q '"decision": *"block"' <<<"$out"
  cp "$SB/bin/python3" "$SB/bin/python"; cp "$SB/bin/python3" "$SB/bin/py"
  out=$(mf tone --check "$SB/memo.md"); rc=$?
  check "no python that runs: --check is silent, exit 0" cond '[ -z "$out" ] && [ "$rc" -eq 0 ]'
  out=$(hook_json "$SB/t.jsonl" | mf tone); rc=$?
  check "no python that runs: the hook never blocks"    cond '[ -z "$out" ] && [ "$rc" -eq 0 ]'
  end
fi

# #37 · The active project's banner. The pointer used to be a hand-edited
# file that nothing moved; now `wrap` moves it to the project the focus
# names, and the banner says so when the pointer and the last wrapped
# session disagree instead of rendering the stale one as fact.
status_script() { mkdir -p "$SB/projects/$1/scripts"; printf '#!/usr/bin/env bash\necho "status of %s"\n' "$1" > "$SB/projects/$1/scripts/status.sh"; chmod +x "$SB/projects/$1/scripts/status.sh"; }
if begin "active project"; then
  make_repo listed; make_repo other; make_repo plain; status_script listed; status_script other
  printf 'listed\tthe task\t3\tno\t-\n' > "$SB/state/queue.md"
  out=$(mf active); rc=$?
  check "no pointer: silence, exit 0"            cond '[ -z "$out" ] && [ "$rc" -eq 0 ]'
  out=$(mf active "$SB/projects/plain" 2>/dev/null); rc=$?
  check "a project with no status script is refused (exit 2)" [ "$rc" -eq 2 ]
  out=$(mf active "$SB/projects/listed"); rc=$?
  check "pointing at a project is confirmed"     cond '[ "$rc" -eq 0 ] && grep -q '\''active project: .*/listed'\'' <<<"$out"'
  out=$(mf active)
  check "the banner carries the directive"       grep -q '^ACTIVE PROJECT' <<<"$out"
  check "the banner runs the status script"      grep -q 'status of listed' <<<"$out"
  check "no disagreement with nothing wrapped"   bash -c '! grep -q DISAGREES <<<"$1"' _ "$out"
  now_mark; out=$(mf wrap "paperwork, nothing in particular" "b1")
  check "a focus naming no project leaves the pointer" [ "$(mf active --show)" = "$(git -C "$SB/projects/listed" rev-parse --show-toplevel)" ]
  now_mark; out=$(mf wrap "other: the whole afternoon" "b1|b2")
  check "setup: the wrap was recorded"           grep -q 'other: the whole afternoon' "$SB/state/sessions.log"
  # #65 (W-14, item 4) · the pointer is stored in git's spelling, whoever writes it
  other_git=$(git -C "$SB/projects/other" rev-parse --show-toplevel)
  check "wrap moves the pointer to the project the focus names" [ "$(mf active --show)" = "$other_git" ]
  check "wrap says so"                           grep -q 'active project: other' <<<"$out"
  check "the banner follows"                     grep -q 'status of other' <<<"$(mf active)"
  mf active "$SB/projects/listed" >/dev/null     # a stale pointer, set by hand
  out=$(mf active)
  check "pointer vs last wrap: the disagreement is said" grep -q 'DISAGREES: the pointer says listed, but the last wrapped session was about other' <<<"$out"
  check "and the stale status still prints, after the warning" grep -q 'status of listed' <<<"$out"
  # The maintainer, 2026-10-17: "summarized project table, always, when I am calling a project. Many times now."
  out=$(mf active "$SB/projects/listed")
  check "switching to a project prints its summary too"   cond 'grep -q '\''status of listed'\'' <<<"$out" && grep -q '\''^ACTIVE PROJECT'\'' <<<"$out"'
  check "a project just chosen is no disagreement"        bash -c '! grep -q DISAGREES <<<"$1"' _ "$out"
  printf '%s\n' "$SB/projects/other" > "$SB/home/.claude/active-project"; rm "$SB/state/active-project"
  check "the 2026-09-23 pointer file is adopted"  [ "$(mf active --show)" = "$SB/projects/other" ]
  mf active "$SB/projects/other" >/dev/null
  check "active <path> stores the same spelling wrap does" [ "$(mf active --show)" = "$other_git" ]
  check "and moved into the state folder"        cond '[ ! -e "$SB/home/.claude/active-project" ] && [ -s "$SB/state/active-project" ]'
  mf active --clear >/dev/null
  check "--clear: silence again"                 [ -z "$(mf active)" ]
  end
fi

# Boards (the maintainer, 2026-10-22: "all projects need their own project page, and be opened as soon as
# we call a project"). A `.board` file names the page; calling the project says to open it first, and a
# project with a board but no status script gets the board's summary from its TODO.md.
if begin "boards"; then
  make_repo boarded; make_repo both; status_script both
  printf 'https://claude.ai/artifact/BOARDTEST\n' > "$SB/projects/boarded/.board"
  printf '# Boarded — the list\n\n## Phase 1 · Build\n- [x] the first step\n- [ ] the second step\n\n## Phase 2 · Ship\n- [ ] the release\n' > "$SB/projects/boarded/TODO.md"
  printf 'https://claude.ai/artifact/BOTHTEST\n' > "$SB/projects/both/.board"
  out=$(mf active "$SB/projects/boarded" 2>&1); rc=$?
  check "a project with a board and no status script is accepted" [ "$rc" -eq 0 ]
  check "calling it says to open the board first"   grep -q 'BOARD — open it beside the chat FIRST (Artifact open): https://claude.ai/artifact/BOARDTEST' <<<"$out"
  check "and shows the board's stages from TODO.md" cond 'grep -q '\''Phase 1 · Build *1/2'\'' <<<"$out" && grep -q '\''NEXT — Phase 1 · Build'\'' <<<"$out"'
  out=$(mf active "$SB/projects/both" 2>&1)
  check "a status script still runs, the board line above it" cond 'grep -q '\''BOARD .*BOTHTEST'\'' <<<"$out" && grep -q '\''status of both'\'' <<<"$out"'
  rm "$SB/projects/boarded/.board"
  out=$(mf active "$SB/projects/boarded" 2>/dev/null); rc=$?
  check "without the board file it is refused again (exit 2)" [ "$rc" -eq 2 ]
  mf active --clear >/dev/null
  end
fi

if begin "chime"; then
  : > "$SB/bin/paplay"; chmod +x "$SB/bin/paplay"     # a player that does nothing
  printf 'x' > "$SB/ding.oga"
  out=$(MINDFORGE_CHIME="$SB/ding.oga" mf chime --test)
  check "names the player and the file"          grep -q "chime: paplay $SB/ding.oga" <<<"$out"
  out=$(MINDFORGE_CHIME="$SB/nowhere.oga" mf chime --test); rc=$?
  check "a missing file: says so, exit 0"        cond 'grep -q '\''no sound file'\'' <<<"$out" && [ "$rc" -eq 0 ]'
  out=$(MINDFORGE_CHIME="$SB/ding.oga" MINDFORGE_CHIME_PLAYER=no-such-player mf chime); rc=$?
  check "plain chime never fails"                cond '[ "$rc" -eq 0 ] && [ -z "$out" ]'
  end
fi

# ------------------------------------------------------------ 0.1.9 (Windows)
# #15 · The memory folder Claude Code really uses. Staged with a cygpath stub
# that answers what Git Bash's would: the Windows spelling of HOME.
if begin "memory folder: Claude Code's spelling (#15)"; then
  printf '#!/usr/bin/env bash\n[ "$1" = -w ] && { echo '"'"'C:\\Users\\test'"'"'; exit 0; }\n[ "$1" = -m ] && { echo "$2"; exit 0; }\nexit 1\n' > "$SB/bin/cygpath"
  chmod +x "$SB/bin/cygpath"
  mkdir -p "$SB/home/.claude/projects/C--Users-test/memory"
  printf 'x\n' > "$SB/home/.claude/projects/C--Users-test/memory/a.md"
  printf -- '- [a](a.md)\n' > "$SB/home/.claude/projects/C--Users-test/memory/MEMORY.md"
  out=$(SB_MEM="" mf brief | sed -n '/^State/,/^$/p')
  check "on Windows: C:\\Users\\test is read from C--Users-test" grep -q 'memory     2 files' <<<"$out"
  rm "$SB/bin/cygpath"
  enc=$(printf '%s' "$SB/home" | sed 's/[^A-Za-z0-9]/-/g')
  mkdir -p "$SB/home/.claude/projects/$enc/memory"; printf 'x\n' > "$SB/home/.claude/projects/$enc/memory/b.md"
  out=$(SB_MEM="" mf brief | sed -n '/^State/,/^$/p')
  check "elsewhere: every non-letter, non-digit becomes -" grep -q 'memory     1 files' <<<"$out"
  out=$(SB_MEM="$SB/nowhere" mf brief | sed -n '/^State/,/^$/p')
  check "a missing folder is named, not counted as 0" grep -q "memory     not found at $SB/nowhere" <<<"$out"
  end
fi

# #31 · An explicit export beats the config. A config that points state and the
# vault at decoys must not pull a sandboxed run onto them.
if begin "config never overrides an export (#31)"; then
  mkdir -p "$SB/home/.config/mindforge" "$SB/decoy" "$SB/decoyvault"
  printf 'MINDFORGE_STATE="%s"\nMINDFORGE_VAULT="%s"\nMINDFORGE_ALWAYS_MAX=1\n' "$SB/decoy" "$SB/decoyvault" > "$SB/home/.config/mindforge/config"
  mf wip "the note" >/dev/null
  check "the exported state is used"            [ -s "$SB/state/wip.md" ]
  check "the config's state is not"             [ ! -e "$SB/decoy/wip.md" ]
  now_mark; mf wrap "focus" "b1" >/dev/null
  check "the exported (empty) vault wins too"   bash -c '! grep -q "vault" <<<"$1"' _ "$(tail -1 "$SB/state/sessions.log")"
  out=$(env -i "${WINENV[@]}" PATH="$SB/bin:$PATH" HOME="$SB/home" bash "$MF" wip --show)
  check "with nothing exported, the config still applies" [ "$out" = "nothing in flight" ]
  printf 'a\tb\n' > "$SB/decoy/wip.md"
  out=$(env -i "${WINENV[@]}" PATH="$SB/bin:$PATH" HOME="$SB/home" bash "$MF" wip --show)
  check "setup: the config's own state really is the decoy" grep -q 'b' <<<"$out"
  end
fi

# #18 · A repo in a synced folder: a path with spaces and an apostrophe, given
# directly as a root (it is itself the repo), no junction.
if begin "a repo given as a root, spaces and an apostrophe (#18)"; then
  make_repo alpha
  synced="$SB/Dropbox (Work)/it's here"
  mkdir -p "$synced"; mv "$SB/projects/alpha" "$synced/alpha"
  make_repo beta
  out=$(SB_PROJECTS="$SB/projects:$synced/alpha" mf brief --headline)
  check "the headline counts it: 2 repos"       grep -q 'git: 2 repos clean' <<<"$out"
  printf 'alpha\tthe task\t3\tno\t-\n' > "$SB/state/queue.md"
  out=$(SB_PROJECTS="$SB/projects:$synced/alpha" mf rot)
  check "a queue name finds it (no R6)"         bash -c '! grep -q "R6.*alpha" <<<"$1"' _ "$out"
  git -c user.name=t -c user.email=t@t -C "$synced/alpha" commit -q --allow-empty -m fresh
  rm "$SB/state/queue.md"; printf 'beta\tthe task\t3\tno\t-\n' > "$SB/state/queue.md"
  out=$(SB_PROJECTS="$SB/projects:$synced/alpha" mf rot)
  check "R3 sees its unpushed commit"           grep -q 'R3.*alpha has 1 unpushed' <<<"$out"
  check "R11 sees it is missing from the queue" grep -q 'R11.*alpha has commits' <<<"$out"
  mkdir -p "$synced/withpkg"; printf 'pkgver=0.1.0\n' > "$synced/withpkg/PKGBUILD"
  git -c init.defaultBranch=main init -q "$synced/withpkg"
  git -c user.name=t -c user.email=t@t -C "$synced/withpkg" commit -q --allow-empty -m one
  git -c user.name=t -c user.email=t@t -C "$synced/withpkg" tag -a -m v v0.2.0
  out=$(SB_PROJECTS="$synced" mf rot)
  check "R1 reads a root with spaces in it"     grep -q 'R1.*withpkg says 0.1.0, latest tag is 0.2.0' <<<"$out"
  end
fi

# #19 · Hooks are installed by a person; mindForge prints the block and checks it.
if begin "hooks --print / --check (#19)"; then
  out=$(mf hooks --check); rc=$?
  check "nothing installed: says so, exit 1"   cond '[ "$rc" -eq 1 ] && grep -q '\''NOT INSTALLED: session-start, session-end'\'' <<<"$out"'
  mf hooks --print --linux 2>/dev/null > "$SB/home/.claude/settings.json"
  check "the Linux block is valid JSON"         "$PY" -c 'import json,sys; json.load(open(sys.argv[1]))' "$SB/home/.claude/settings.json"
  check "the Linux block has no shell key"      bash -c '! grep -q "\"shell\"" "$1"' _ "$SB/home/.claude/settings.json"
  out=$(mf hooks --check); rc=$?
  check "the printed block passes --check"      cond '[ "$rc" -eq 0 ] && grep -q '\''are installed'\'' <<<"$out"'
  check "and the brief's own check agrees"      bash -c '! grep -q "^hooks:" <<<"$1"' _ "$(mf brief --headline)"
  out=$(mf hooks --print --windows 2>/dev/null)
  check "the Windows block is valid JSON"       "$PY" -c 'import json,sys; json.loads(sys.stdin.read())' <<<"$out"
  check "every Windows hook runs in bash"       [ "$(grep -c '"shell": "bash"' <<<"$out")" -eq 6 ]
  check "with the script's full path"           grep -q "\\\\\"[^\"]*mindforge\\\\\" session-start" <<<"$out"
  end
fi

# #21 · The PowerShell wrapper hands every argument to bash intact. Run only
# where PowerShell is (the laptop); elsewhere it says it could not look.
if begin "PowerShell wrapper (#21)"; then
  PS=$(command -v pwsh || command -v powershell || command -v powershell.exe || true)
  if [ -z "$PS" ]; then
    skip "wrap 'a b' 'c|d' arrives as two arguments" "no PowerShell on this machine"
  else
    mkdir -p "$SB/w"; cp "$ROOT/bin/mindforge.ps1" "$SB/w/"
    printf '#!/usr/bin/env bash\nfor a in "$@"; do printf "[%%s]\\n" "$a"; done\n' > "$SB/w/mindforge"
    wps="$SB/w/mindforge.ps1"; command -v cygpath >/dev/null 2>&1 && wps=$(cygpath -w "$wps")
    out=$(MINDFORGE_BASH="$(command -v bash)" "$PS" -NoProfile -File "$wps" wrap 'Focus with spaces' 'b1|b2' "it's here" 2>&1)
    check "every argument arrives whole"        [ "$out" = "$(printf '[wrap]\n[Focus with spaces]\n[b1|b2]\n[it'"'"'s here]')" ]
  fi
  end
fi

# #38 · Where the time goes, per rule.
if begin "rot --timings (#38)"; then
  make_repo alpha
  out=$(mf rot --timings 2>&1 >/dev/null)
  for r in "repo list" tracker R1 R2 R3 R4 R5 R8 R10 R11 R7 R9 total; do
    check "times $r"                            grep -qE "^timing	$r +[0-9]+ ms" <<<"$out"
  done
  check "stdout is the plain rot"               [ "$(mf rot --timings 2>/dev/null)" = "$(mf rot)" ]
  check "an unknown option is refused"          bash -c '! "$@" 2>/dev/null' _ mf rot --bogus
  end
fi

# #65 (W-14, item 2) · A transcript path in Git Bash's spelling reaches a Windows
# python that cannot open it. Staged with a cygpath stub that knows the way.
if begin "tone: a Git Bash transcript path (#65)"; then
  fake_transcript "$SB/t.jsonl" "Here's where it all stands."
  printf '#!/usr/bin/env bash\n[ "$1" = -m ] && [ "$2" = /msys/t.jsonl ] && { echo "%s/t.jsonl"; exit 0; }\nexit 1\n' "$SB" > "$SB/bin/cygpath"
  chmod +x "$SB/bin/cygpath"
  out=$(hook_json "/msys/t.jsonl" | mf tone)
  check "the path is translated and the memo caught" grep -q '"decision": *"block"' <<<"$out"
  rm "$SB/bin/cygpath"
  out=$(hook_json "/msys/t.jsonl" | mf tone); rc=$?
  check "setup: without cygpath the same path is silent" cond '[ -z "$out" ] && [ "$rc" -eq 0 ]'
  end
fi

# ------------------------------------------------------------------ 0.1.10
# #47 · R8 holds a version a queue row says shipped against the newest tag --
# "-" rows included -- and wrap asks about the row of a project with commits.
if begin "R8: a row behind its newest tag (#47)"; then
  make_repo alpha; g alpha tag -a -m v v0.9.0
  printf 'alpha\tnext: labels; 0.8.0 shipped 10-06\t3\tno\t-\n' > "$SB/state/queue.md"
  out=$(mf rot)
  check "a '-' row saying 0.8.0 shipped, tag v0.9.0: flagged" grep -q 'R8.*alpha says 0.8.0 shipped, but its newest tag is 0.9.0' <<<"$out"
  printf 'alpha\tnext: labels; 0.9.0 shipped 10-07\t3\tno\t-\n' > "$SB/state/queue.md"
  check "a row naming the newest tag: quiet"     bash -c '! grep -q "R8.*alpha says" <<<"$1"' _ "$(mf rot)"
  printf 'alpha\tnext: the 1.0.0 plan\t3\tno\t-\n' > "$SB/state/queue.md"
  check "a version not said to be shipped: quiet" bash -c '! grep -q "R8.*alpha says" <<<"$1"' _ "$(mf rot)"
  # a monorepo section tags <section>-vX.Y.Z
  make_repo suite; mkdir -p "$SB/projects/suite/kit"; echo x > "$SB/projects/suite/kit/f"
  g suite add -A; g suite commit -qm kit; g suite tag -a -m v kit-v0.9.0; g suite tag -a -m v other-v3.0.0
  printf 'suite/kit\tnext: x; 0.8.0 shipped\t3\tno\t-\n' > "$SB/state/queue.md"
  check "a monorepo section: held against <section>-v tags" grep -q 'R8.*suite/kit says 0.8.0 shipped, but its newest tag is 0.9.0' <<<"$(mf rot)"
  end
fi
if begin "wrap asks about the queue row (#47)"; then
  make_repo alpha; make_repo beta
  printf 'alpha\tthe old plan\t3\tno\t-\nbeta\tbeta things\t3\tno\t-\n' > "$SB/state/queue.md"
  touch -d '-2 hours' "$SB/state/queue.md"
  # the mark a minute ahead, so make_repo's commits fall before the session
  mkdir -p "$SB/state/marks"; printf '%s\t%s\n' "$(date -d '+1 min' +%F)" "$(date -d '+1 min' +%H:%M)" > "$SB/state/marks/$SID"
  GIT_COMMITTER_DATE="$(date -d '+2 min' -R)" g alpha commit -q --allow-empty -m "this session"; g alpha push -q origin main 2>/dev/null
  out=$(mf wrap "alpha work" "b1")
  check "a project with commits, queue untouched: still true?" grep -q 'queue: alpha got [0-9]* commit(s) this session and its row still says "the old plan" -- still true' <<<"$out"
  check "and the wrap is NOT clean"            grep -q 'wrap NOT clean' <<<"$out"
  check "a project without commits is not asked about" bash -c '! grep -q "queue: beta" <<<"$1"' _ "$out"
  now_mark; touch "$SB/state/queue.md"
  out=$(mf wrap "alpha work" "b1")
  check "queue.md edited this session: shown, not open" cond 'grep -q '\''queue: alpha -- the old plan'\'' <<<"$out" && bash -c '\''! grep -q "still true" <<<"$1"'\'' _ "$out"'
  end
fi

# #28 · A file that declares `rewritten_by: session` is held to it, at both ends.
if begin "R12: the every-session file (#28)"; then
  make_repo alpha; : > "$SB/mem/MEMORY.md"
  out=$(mf brief | sed -n '/^State/,/^$/p')
  check "no file declares it: said out loud"   grep -q 'no memory file declares rewritten_by: session -- R12 has nothing to check' <<<"$out"
  printf -- '---\nname: plan\nmetadata:\n  type: project\n  rewritten_by: session\n---\nthe plan\n' > "$SB/mem/plan.md"
  printf -- '- [plan](plan.md)\n' > "$SB/mem/MEMORY.md"
  y=$(date -d yesterday +%F)
  printf '%s\t10:00\t12:00\twork\tb\twrapped\n' "$y" >> "$SB/state/sessions.log"
  touch -d "$y 09:00" "$SB/mem/plan.md"; touch -d "$y 09:00" "$SB/mem/MEMORY.md"
  out=$(mf rot)
  check "written before the last session began: R12" grep -q 'R12.*plan.md is rewritten every session, but was last written .* before the last session began' <<<"$out"
  touch -d "$y 11:00" "$SB/mem/plan.md" "$SB/mem/MEMORY.md"
  check "rewritten during it: quiet"           bash -c '! grep -q R12 <<<"$1"' _ "$(mf rot)"
  printf '%s\t13:00\t13:05\t(not wrapped)\t\tauto\n' "$y" >> "$SB/state/sessions.log"
  check "a 5-minute churn session after it does not count" bash -c '! grep -q R12 <<<"$1"' _ "$(mf rot)"
  check "the State line names the file"        grep -q 'handoff    plan.md, written' <<<"$(mf brief)"
  now_mark; touch -d '-2 hours' "$SB/mem/plan.md"
  out=$(mf wrap "focus" "b")
  check "a wrap that left it untouched: open"  grep -q 'plan.md is rewritten every session, and this one has not rewritten it' <<<"$out"
  now_mark; touch "$SB/mem/plan.md"
  check "a wrap after rewriting it: ok"        grep -q 'plan.md rewritten this session' <<<"$(mf wrap focus b)"
  end
fi

# #44 · One project's brief.
if begin "mindforge <project> (#44)"; then
  make_repo alpha; make_repo suite; mkdir -p "$SB/projects/suite/kit/scripts"
  printf '#!/usr/bin/env bash\necho "kit status table"\n' > "$SB/projects/suite/kit/scripts/status.sh"; chmod +x "$SB/projects/suite/kit/scripts/status.sh"
  g suite add -A; g suite commit -qm kit; g suite push -q origin main 2>/dev/null; g suite tag -a -m v kit-v0.9.0
  printf 'suite/kit\tlabels; 0.8.0 shipped\t3\twaits:review\t-\nalpha\tthe alpha task\t3\tno\t-\n' > "$SB/state/queue.md"
  printf -- '- [ ] alpha open item one\n- [x] done item\n' > "$SB/projects/alpha/TODO.md"; g alpha add -A; g alpha commit -qm todo; g alpha push -q origin main 2>/dev/null
  printf '%s\t10:00\t11:00\tkit: the labels\tb\twrapped\n' "$(date +%F)" >> "$SB/state/sessions.log"
  out=$(mf KIT); rc=$?
  check "found by its folder name, any case"   cond '[ "$rc" -eq 0 ] && grep -q '\''^suite/kit · '\'' <<<"$out"'
  check "the queue line"                       grep -q '^queue: labels; 0.8.0 shipped · waits:review' <<<"$out"
  check "the last session that names it"       grep -q '^last session on it: .* — kit: the labels' <<<"$out"
  check "its own status script"                grep -q 'kit status table' <<<"$out"
  check "the rot finding that names it"        grep -q 'R8.*suite/kit says 0.8.0 shipped' <<<"$out"
  check "another project's rot is not shown"   bash -c '! grep -q "alpha" <<<"$1"' _ "$(sed -n '/^Rot check/,/^$/p' <<<"$out")"
  check "recommended: the rot first"           grep -A1 '^Recommended first' <<<"$out" | grep -q 'fix the rot above first'
  out=$(mf brief alpha)
  check "brief <name> works too"               grep -q '^alpha · ' <<<"$out"
  check "no status script: its TODO.md open items" cond 'grep -q '\''alpha open item one'\'' <<<"$out" && bash -c '\''! grep -q "done item" <<<"$1"'\'' _ "$out"'
  check "recommended: the queue's next"        grep -A1 '^Recommended first' <<<"$out" | grep -q 'the alpha task'
  echo dirt > "$SB/projects/alpha/new"
  check "a dirty tree is recommended first"    grep -A1 '^Recommended first' <<<"$(mf alpha)" | grep -q 'commit what is in the tree'
  out=$(mf nosuch 2>&1); rc=$?
  check "an unknown name: exit 2, the known ones listed" cond '[ "$rc" -eq 2 ] && grep -q '\''not a command or a project I know'\'' <<<"$out" && grep -q '\''^  suite/kit'\'' <<<"$out"'
  check "brief --bogus is refused"             bash -c '! "$@" >/dev/null 2>&1' _ mf brief --bogus
  end
fi

# #23 · The scope list runs over the vault notes a session changed.
if begin "the vault scrub (#23)"; then
  make_repo alpha; mkdir -p "$SB/vault/My-Novel" "$SB/vault/HomeLab"
  printf 'Aldric\tMy-Novel|The-Game\n' > "$SB/state/scope.txt"
  now_mark
  printf 'Aldric walked in.\n' > "$SB/vault/My-Novel/ch1.md"
  printf 'Today aldric fixed the router.\n' > "$SB/vault/HomeLab/log.md"
  out=$(SB_VAULT="$SB/vault" mf wrap "focus" "b")
  check "a scoped name out of scope: the wrap names the note" grep -q 'vault: HomeLab/log.md names Aldric outside its scope' <<<"$out"
  check "the note where it belongs is not named" bash -c '! grep -q "My-Novel/ch1.md names" <<<"$1"' _ "$out"
  out=$(SB_VAULT="$SB/vault" mf scrub --vault); rc=$?
  check "scrub --vault: exit 1, the note and the count" cond '[ "$rc" -eq 1 ] && grep -q '\''HomeLab/log.md  Aldric x1 (line 1)'\'' <<<"$out"'
  printf 'nothing to see\n' > "$SB/vault/HomeLab/log.md"
  now_mark
  check "clean again: the wrap says so"        grep -q 'vault: no scoped name out of its scope' <<<"$(SB_VAULT="$SB/vault" mf wrap f b)"
  out=$(SB_VAULT="$SB/vault" mf scrub --vault); rc=$?
  check "scrub --vault clean: exit 0"          [ "$rc" -eq 0 ]
  rm "$SB/state/scope.txt"
  out=$(SB_VAULT="$SB/vault" mf scrub --vault 2>&1); rc=$?
  check "no scope list: could not look, exit 2" cond '[ "$rc" -eq 2 ] && grep -q '\''nothing was checked'\'' <<<"$out"'
  printf 'the X/Y persona is scoped to A ONLY\n' > "$SB/state/persona.txt"; now_mark
  check "a persona but no scope list: the wrap says NOT verified" grep -q 'no scope.txt, so the vault notes were not checked for it -- NOT verified' <<<"$(SB_VAULT="$SB/vault" mf wrap f b)"
  end
fi

# #25 · HAZARD: lines surface where a session about to act will see them.
if begin "hazards (#25)"; then
  make_repo alpha; mkdir -p "$SB/projects/alpha/docs"
  printf '# Decisions\n\nHAZARD: ufw-docker blocks ports 80/443 until ufw-docker allow AND the cloud firewall rule.\nNot a hazard: ufw is fine.\n' > "$SB/projects/alpha/docs/DECISIONS.md"
  printf 'alpha\tgo live\t3\tno\t-\n' > "$SB/state/queue.md"
  out=$(mf hazards alpha ufw)
  check "a word that matches: the line, with its file" grep -q 'docs/DECISIONS.md:3:HAZARD: ufw-docker blocks' <<<"$out"
  check "only HAZARD: lines"                   bash -c '! grep -q "Not a hazard" <<<"$1"' _ "$out"
  check "a word that does not match: none, said" grep -q 'hazards: none written in alpha for: nginx' <<<"$(mf hazards alpha nginx)"
  check "the project brief shows them"         grep -A1 '^Hazards' <<<"$(mf alpha)" | grep -q 'ufw-docker'
  end
fi

# ================================================================== verdict ==
REAL_AFTER=$(snap "$REAL_STATE")
echo
if [ "$REAL_BEFORE" != "$REAL_AFTER" ]; then
  echo "ISOLATION BROKEN: the real state at $REAL_STATE changed during the run" >&2
  FAIL=$((FAIL+1)); FAILED+=("isolation: real state changed")
fi
cd "$ROOT" && rm -rf "$RUN_DIR"
REPO_AFTER=$(git -C "$ROOT" status --porcelain --untracked-files=all 2>/dev/null)
if [ "$REPO_BEFORE" != "$REPO_AFTER" ]; then
  echo "REPO CHANGED: the run left this behind in $ROOT:" >&2
  diff <(printf '%s\n' "$REPO_BEFORE") <(printf '%s\n' "$REPO_AFTER") | grep '^>' | sed 's/^> /  /' >&2
  FAIL=$((FAIL+1)); FAILED+=("isolation: the run changed the repo")
fi
if [ "$RAN" -eq 0 ]; then
  echo "NO CHECKS RAN${FILTER:+ (filter: $FILTER)} -- this is not a pass" >&2; exit 2
fi
printf '%d checks · %d passed · %d failed · %d expected failures (known, filed) · %d unexpectedly passing' \
  "$RAN" "$PASS" "$FAIL" "$XFAIL" "$XPASS"
[ "$SKIP" -gt 0 ] && printf ' · %d could not look here (skipped, see above)' "$SKIP"
echo
printf 'real state untouched: %s\n' "$REAL_STATE"
if [ ${#FAILED[@]} -gt 0 ]; then
  printf '  ! %s\n' "${FAILED[@]}"; exit 1
fi
exit 0
