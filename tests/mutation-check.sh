#!/usr/bin/env bash
# Verify that representative launcher/installer regressions make a check fail.

set -u

REPO_ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)"
BASH_BIN="$(command -v bash)"
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT HUP INT TERM

NAMES=()
EXPECTED=()
ACTUAL=()
VERDICTS=()
SURVIVORS=0

fresh_copy() {
  local dst="$1"
  mkdir -p "$dst/scripts"
  cp "$REPO_ROOT/install.sh" "$REPO_ROOT/migrate.sh" "$dst/"
  cp "$REPO_ROOT/scripts/check-sync.sh" "$dst/scripts/"
}

rewrite_awk() {
  local file="$1" program="$2"
  local tmp="$file.rewrite"
  awk "$program" "$file" > "$tmp" && mv "$tmp" "$file"
}

relative_to_absolute() {
  rewrite_awk "$1/install.sh" '
    /  cc_preload=\\\$\(realpath / {
      print "  cc_preload=\"\\$CC_SETDNS\""
      skipping=1
      next
    }
    skipping && /  esac/ { skipping=0; next }
    !skipping { print }
  '
}

break_absolute_fallback() {
  rewrite_awk "$1/install.sh" '
    /""\) cc_preload="\\\$CC_SETDNS"/ {
      sub(/cc_preload="\\\$CC_SETDNS"/, "cc_preload=\"./missing-setdns.js\"")
    }
    { print }
  '
}

remove_realpath_stderr_suppression() {
  rewrite_awk "$1/install.sh" '
    /cc_preload=.*realpath/ { sub(/ 2>\/dev\/null/, "") }
    { print }
  '
}

remove_update_lock() {
  rewrite_awk "$1/install.sh" '
    /if mkdir "\\\$LOCK" 2>\/dev\/null; then/ { sub(/if mkdir .*; then/, "if true; then") }
    { print }
  '
}

shared_staging_path() {
  sed 's/tmp="\\$new_bin\.\\$\\$\.tmp"/tmp="\\$new_bin.tmp"/' \
    "$1/install.sh" > "$1/install.sh.rewrite" &&
    mv "$1/install.sh.rewrite" "$1/install.sh"
}

remove_prune_guard() {
  sed '/printf.*"\\$base".*grep.*continue/d' "$1/install.sh" > "$1/install.sh.rewrite" &&
    mv "$1/install.sh.rewrite" "$1/install.sh"
}

probe_guard_to_bare() {
  local file
  for file in "$1/install.sh" "$1/migrate.sh"; do
    rewrite_awk "$file" '
      /^if HOME="\$ST_HOME".*"\$ST_ERR"; then$/ {
        line=$0
        sub(/^if /, "", line)
        sub(/; then$/, "", line)
        print line
        print "ST_RC=$?"
        skipping=1
        next
      }
      skipping && /^fi$/ { skipping=0; next }
      !skipping { print }
    '
  done
}

timeout_as_crash() {
  sed '/st_elapsed.*-ge.*st_limit.*return 2/s/return 2/return 1/' \
    "$1/install.sh" > "$1/install.sh.rewrite" &&
    mv "$1/install.sh.rewrite" "$1/install.sh"
}

remove_stale_sweep() {
  rewrite_awk "$1/install.sh" '
    /    # A SIGKILL during download/ { skipping=1; next }
    skipping && /    done/ { skipping=0; next }
    !skipping { print }
  '
}

install_only_edit() {
  rewrite_awk "$1/install.sh" '
    { print }
    /# SYNC:BEGIN wrapper-heredoc/ { print "# mutation: install-only launcher edit" }
  '
}

remove_crash_aware_final_verification() {
  rewrite_awk "$1/install.sh" '
    /elif \[ "\$\{ST_CRASHED:-0\}" = 1 \]; then/ { skipping=1; next }
    skipping && /^else$/ { skipping=0 }
    !skipping { print }
  '
}

run_wrapper_check() {
  TEST_DL_DELAY=0.1 TEST_LAUNCH_GAP=0.02 \
    "$BASH_BIN" "$REPO_ROOT/tests/wrapper-update-tests.sh" "$1/install.sh"
}

run_installer_check() {
  "$BASH_BIN" "$REPO_ROOT/tests/installer-smoke-tests.sh" \
    "$1/install.sh" "$1/migrate.sh"
}

run_sync_check() {
  (cd "$1" && "$BASH_BIN" scripts/check-sync.sh)
}

run_mutation() {
  local name="$1" file="$2" expected="$3" mutator="$4" checker="$5"
  local index case_dir output
  local rc actual verdict
  index="${#NAMES[@]}"
  case_dir="$WORK_ROOT/case-$index"
  output="$WORK_ROOT/case-$index.out"

  fresh_copy "$case_dir"
  if ! "$mutator" "$case_dir"; then
    actual="mutation edit failed"
    verdict="ERROR"
    SURVIVORS=$((SURVIVORS + 1))
  elif ! "$BASH_BIN" -n "$case_dir/install.sh" || ! "$BASH_BIN" -n "$case_dir/migrate.sh"; then
    actual="invalid mutation"
    verdict="ERROR"
    SURVIVORS=$((SURVIVORS + 1))
  else
    "$checker" "$case_dir" > "$output" 2>&1
    rc=$?
    if [ "$rc" -ne 0 ]; then
      actual="failed (rc=$rc)"
      verdict="KILLED"
    else
      actual="passed"
      verdict="SURVIVOR"
      SURVIVORS=$((SURVIVORS + 1))
    fi
  fi

  NAMES[index]="$name [$file]"
  EXPECTED[index]="$expected"
  ACTUAL[index]="$actual"
  VERDICTS[index]="$verdict"
}

run_mutation "relative preload reverted to absolute" "install.sh" "wrapper fails" relative_to_absolute run_wrapper_check
run_mutation "absolute fallback broken" "install.sh" "wrapper fails" break_absolute_fallback run_wrapper_check
run_mutation "realpath stderr suppression removed" "install.sh" "wrapper fails" remove_realpath_stderr_suppression run_wrapper_check
run_mutation "update lock removed" "install.sh" "wrapper fails" remove_update_lock run_wrapper_check
run_mutation "per-process staging path shared" "install.sh" "wrapper fails" shared_staging_path run_wrapper_check
run_mutation "prune version-name guard removed" "install.sh" "wrapper fails" remove_prune_guard run_wrapper_check
run_mutation "installer probe guard made bare" "install.sh+migrate.sh" "installer fails" probe_guard_to_bare run_installer_check
run_mutation "timed-out probe classified as crash" "install.sh" "wrapper fails" timeout_as_crash run_wrapper_check
run_mutation "stale staging sweep removed" "install.sh" "wrapper fails" remove_stale_sweep run_wrapper_check
run_mutation "launcher edit applied to install only" "install.sh" "check-sync fails" install_only_edit run_sync_check
run_mutation "crash-aware final verification removed" "install.sh" "installer fails" remove_crash_aware_final_verification run_installer_check

run_exit_semantics_check() {
  local name="$1" expected="$2" runner="$3"
  local index case_dir output rc verdict actual
  index="${#NAMES[@]}"
  case_dir="$WORK_ROOT/semantics-$index"
  output="$WORK_ROOT/semantics-$index.out"
  mkdir -p "$case_dir/bin" "$case_dir/home"
  printf '#!/usr/bin/env sh\nprintf "17\\n"\n' > "$case_dir/bin/getprop"
  chmod +x "$case_dir/bin/getprop"
  "$runner" "$case_dir" > "$output" 2>&1
  rc=$?
  if [ "$rc" -eq "$expected" ]; then
    actual="failed as required (rc=$rc)"
    verdict="KILLED"
  else
    actual="unexpected rc=$rc"
    verdict="SURVIVOR"
    SURVIVORS=$((SURVIVORS + 1))
  fi
  NAMES[index]="$name [gate semantics]"
  EXPECTED[index]="exit $expected"
  ACTUAL[index]="$actual"
  VERDICTS[index]="$verdict"
}

verify_failure_exits_one() {
  local dir="$1"
  mkdir -p "$dir/repo/tests"
  cp "$REPO_ROOT/tests/verify-claims.sh" "$dir/repo/tests/"
  PATH="$dir/bin:$PATH" HOME="$dir/home" PREFIX="$dir/prefix" \
    "$BASH_BIN" "$dir/repo/tests/verify-claims.sh"
}

release_preflight_exits_two() {
  local dir="$1"
  cp "$REPO_ROOT/tests/device-release-runner.sh" "$dir/"
  PATH="$dir/bin:$PATH" HOME="$dir/home" CC_MATRIX_OUT="$dir/out" \
    "$BASH_BIN" "$dir/device-release-runner.sh" fresh-gate test-device
}

run_exit_semantics_check "selected evidence FAIL returns nonzero" 1 verify_failure_exits_one
run_exit_semantics_check "release runner setup error is distinct" 2 release_preflight_exits_two

printf '%-48s | %-15s | %-15s | %s\n' "MUTATION (FILE)" "EXPECTED" "ACTUAL" "VERDICT"
printf '%s\n' "----------------------------------------------------------------------------------------------------------------"
for i in "${!NAMES[@]}"; do
  printf '%-48s | %-15s | %-15s | %s\n' \
    "${NAMES[i]}" "${EXPECTED[i]}" "${ACTUAL[i]}" "${VERDICTS[i]}"
done

if [ "$SURVIVORS" -ne 0 ]; then
  printf '\n%d mutation(s) survived or were invalid:\n' "$SURVIVORS" >&2
  for i in "${!NAMES[@]}"; do
    [ "${VERDICTS[i]}" = "KILLED" ] || printf ' - %s: %s\n' "${NAMES[i]}" "${VERDICTS[i]}" >&2
  done
  exit 1
fi
printf '\nAll %d mutations killed.\n' "${#NAMES[@]}"
