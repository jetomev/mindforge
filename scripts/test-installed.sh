#!/usr/bin/env bash
# Run part A's command steps of a test matrix against the INSTALLED package
# (/usr/bin/mindforge, never the checkout) and log what each printed.
#   bash scripts/test-installed.sh
# Steps that need a person (installing, a fresh session) stay in the matrix.
# The sample commands for the memory guard live outside the repo:
# MINDFORGE_TEST_SAMPLES (default ~/.cache/mindforge-dev/handover/m11).
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LOGS="$ROOT/logs"; mkdir -p "$LOGS"
LOG="$LOGS/test-installed-$(date +%Y%m%d-%H%M%S).log"
ln -sfn "$(basename "$LOG")" "$LOGS/test-installed-latest.log"
exec > >(tee "$LOG") 2>&1

MF=/usr/bin/mindforge
S="${MINDFORGE_TEST_SAMPLES:-$HOME/.cache/mindforge-dev/handover/m11}"
WANT=$(grep -m1 '^VERSION=' "$ROOT/bin/mindforge" | cut -d'"' -f2)   # the version this checkout releases
fails=0
step() {  # step <id> <what you should see> <pass test> -- <command...>
  local id=$1 want=$2 test=$3; shift 4
  printf '\n=== %s  %s\n    you should see: %s\n' "$id" "$*" "$want"
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "${out:-(nothing printed)}" | sed 's/^/    | /' | head -12
  if OUT="$out" RC="$rc" bash -c "$test"; then echo "    -> PASS"; else echo "    -> FAIL"; fails=$((fails+1)); fi
}

echo "mindforge installed-package test, $(date '+%F %T')"
[ -x "$MF" ] || { echo "no $MF -- install the package first"; exit 1; }
[ -r "$S/bad.json" ] && [ -r "$S/good.json" ] || { echo "sample commands missing in $S"; exit 1; }

step A2 "mindforge $WANT" "[ \"\$OUT\" = \"mindforge $WANT\" ]" -- "$MF" --version
step A3 'warnings that stood for days end in "(N sessions -- fix it)"' 'grep -q "sessions -- fix it)" <<<"$OUT"' -- "$MF" rot
step A4 "refused: sed -i on a memory file (exit 1)" '[ "$RC" = 1 ] && grep -q "sed -i on a memory file" <<<"$OUT"' -- bash -c "$MF memcheck --shell < '$S/bad.json'"
step A5 "nothing at all (exit 0)" '[ "$RC" = 0 ] && [ -z "$OUT" ]' -- bash -c "$MF memcheck --shell < '$S/good.json'"
step A6 "I never asked" '[ "$OUT" = "I never asked" ]' -- "$MF" heard --check "I never asked for that"

printf '\n%d step(s) failed. Log: %s\n' "$fails" "$LOG"
[ "$fails" -eq 0 ] && echo OK
