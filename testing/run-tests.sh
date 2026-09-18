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
    SB_GH_STATE="${SB_GH_STATE:-}" \
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

# W-8a: an option is not a focus.
for a in --help -h; do
  if begin "wrap $a"; then
    mkdir -p "$SB/state/marks"; printf '2026-09-18\t07:00\n' > "$SB/state/marks/$SID"
    printf 'x\tnote\n' > "$SB/state/wip.md"
    before=$(snap "$SB/state"); mf wrap "$a" >/dev/null 2>&1; rc=$?
    xfail "#22 W-8a" "exits 2"             [ "$rc" -eq 2 ]
    xfail "#22 W-8a" "leaves state byte-identical" [ "$(snap "$SB/state")" = "$before" ]
    end
  fi
done
if begin "drift --help"; then
  before=$(snap "$SB/state"); mf drift --help >/dev/null 2>&1; rc=$?
  xfail "#22 W-8a" "exits 2"               [ "$rc" -eq 2 ]
  xfail "#22 W-8a" "logs no drift note"    [ "$(snap "$SB/state")" = "$before" ]
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
