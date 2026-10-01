#!/usr/bin/env bash
# Tag and publish a mindForge release -- or refuse, before anything leaves the machine.
#   bash scripts/release.sh 0.1.7
#
# #41 · v0.1.6 went public on the wrong commit. The scrub hook refused the docs
# commit, and the tag and push sat on the next line of the same command; a
# here-document ends a command line, so the && chain stopped and the next line
# ran anyway. A refused step must make a wrong tag IMPOSSIBLE, not unlikely.
# Every check below runs before the first tag or push; any failure stops here.
#
# The GitHub Release page, closing issues and the Vault entry stay human steps.
# They are printed as a checklist at the end.
set -euo pipefail

ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$ROOT"
VER="${1:-}"
TAG="v$VER"

LOGS="$ROOT/logs"
mkdir -p "$LOGS"
LOG="$LOGS/release-$(date +%Y%m%d-%H%M%S).log"
ln -sfn "$(basename "$LOG")" "$LOGS/release-latest.log"
exec > >(tee "$LOG") 2>&1

refuse() { printf 'release: REFUSED -- %s\nNothing was tagged or pushed.\n' "$1"; exit 1; }

[[ "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || refuse "give the version as X.Y.Z, e.g. 0.1.7 (got '${VER}')"

[ -z "$(git status --porcelain)" ] || refuse "the working tree has uncommitted or untracked changes"

[ "$(git rev-parse --abbrev-ref HEAD)" = main ] || refuse "not on main"
git fetch -q origin main || refuse "could not reach origin to compare main"
[ -z "$(git rev-list HEAD..origin/main)" ] || refuse "main is behind origin/main or has diverged -- pull first"

have=$(grep -m1 '^VERSION=' bin/mindforge | cut -d'"' -f2)
[ "$have" = "$VER" ] || refuse "bin/mindforge says VERSION=\"$have\", not \"$VER\" -- bump it in the docs commit first"

grep -q "^## $TAG " docs/CHANGELOG.md || refuse "docs/CHANGELOG.md has no '## $TAG — <date>' entry"

git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && refuse "$TAG already exists on this machine"
[ -z "$(git ls-remote --tags origin "refs/tags/$TAG")" ] || refuse "$TAG already exists on origin"

echo "release: running the tests"
bash testing/run-tests.sh >"$LOGS/release-tests.log" 2>&1 || {
  tail -5 "$LOGS/release-tests.log"; refuse "the tests did not pass (full output: logs/release-tests.log)"; }
grep -E 'checks ·' "$LOGS/release-tests.log" | tail -1 || true

# The tag message is the changelog entry: title line, then the body up to the next release.
title=$(grep -m1 "^## $TAG " docs/CHANGELOG.md | sed 's/^## //')
body=$(awk -v t="## $TAG " 'index($0,t)==1{on=1;next} on&&/^## v/{exit} on' docs/CHANGELOG.md)
git tag -a "$TAG" -F - <<EOF
mindForge $title
$body
EOF

git push -q origin main
git push -q origin "$TAG"

printf '\nrelease: %s tagged on %s and pushed.\n' "$TAG" "$(git rev-parse --short "$TAG^{commit}")"
cat <<EOF
Still by hand:
  [ ] GitHub Release page for $TAG with notes, marked Latest
  [ ] close the issues it fixes, each with a full explanation
  [ ] About / topics still accurate
  [ ] Vault entry, memory, TODO
OK
EOF
