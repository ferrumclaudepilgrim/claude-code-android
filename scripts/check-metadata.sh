#!/usr/bin/env bash
# Fail when stable repository-version metadata disagrees across canonical files.

set -u

REPO_ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)"
README="$REPO_ROOT/README.md"
COMPAT="$REPO_ROOT/docs/device-compatibility.md"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

fail() { printf 'metadata check: %s\n' "$*" >&2; exit 1; }

for file in "$README" "$COMPAT" "$CHANGELOG"; do
  [ -s "$file" ] || fail "missing or empty ${file#"$REPO_ROOT/"}"
done

readme_version="$(sed -n 's/.*Repo-\([0-9][0-9.]*\)-blue\.svg.*/\1/p' "$README" | head -1)"
compat_version="$(sed -n 's/.*Repository version `\([0-9][0-9.]*\)`.*/\1/p' "$COMPAT" | head -1)"

[ -n "$readme_version" ] || fail 'README repository-version badge is missing or malformed'
[ -n "$compat_version" ] || fail 'device compatibility repository version is missing or malformed'
[ "$readme_version" = "$compat_version" ] || \
  fail "README version $readme_version differs from compatibility version $compat_version"
grep -Fq "## [$readme_version] - " "$CHANGELOG" || \
  fail "CHANGELOG has no dated [$readme_version] release heading"
grep -Fq '## [Unreleased]' "$CHANGELOG" || fail 'CHANGELOG has no [Unreleased] heading'

printf 'metadata check: repository version %s is consistent\n' "$readme_version"
