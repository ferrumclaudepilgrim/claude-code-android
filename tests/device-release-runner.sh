#!/usr/bin/env bash
# On-device release matrix runner. Stage this file beside the installer scripts,
# then invoke it once from foregrounded Termux.
#
# Usage: bash device-release-runner.sh MODE DEVICE_SERIAL
# MODE: pixel-refresh | pixel-concurrency | migration-abort | fresh-gate
# Exit: 0 = no FAIL, 1 = one or more tested checks FAIL, 2 = HARNESS_ERROR.
# PASS/FAIL/SKIP/HARNESS_ERROR are recorded in the TSV. The .done marker means
# execution completed and is not a success verdict.

set -u

MODE="${1:-}"
DEVICE="${2:-unknown}"
case "$MODE" in
  pixel-refresh|pixel-concurrency|migration-abort|fresh-gate) ;;
  *) printf 'usage: %s MODE DEVICE_SERIAL\n' "$0" >&2; exit 2 ;;
esac

ANDROID="$(getprop ro.build.version.release)"
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
OUT_DIR="${CC_MATRIX_OUT:-/sdcard/Download/claude-code-android-matrix}"
RUN_ID="${MODE}-${DEVICE}"
TRANSCRIPT="$OUT_DIR/$RUN_ID.txt"
RESULTS="$OUT_DIR/$RUN_ID.tsv"
WORK="$HOME/.cache/claude-code-android-matrix"
if ! mkdir -p "$OUT_DIR" "$WORK"; then
  printf 'HARNESS_ERROR: cannot create output/work directories\n' >&2
  exit 2
fi
: > "$TRANSCRIPT" || { printf 'HARNESS_ERROR: cannot write transcript\n' >&2; exit 2; }
printf 'check_id\tdevice\tandroid_version\texpected\tactual\tverdict\n' > "$RESULTS" || {
  printf 'HARNESS_ERROR: cannot write results\n' >&2
  exit 2
}
FAIL_N=0
HARNESS_ERROR_N=0
exec > >(tee -a "$TRANSCRIPT") 2>&1

clean_field() {
  printf '%s' "$1" | tr '\t\r\n' '   '
}

record() {
  local check_id="$1" expected="$2" actual="$3" verdict="$4"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$(clean_field "$check_id")" "$(clean_field "$DEVICE")" \
    "$(clean_field "$ANDROID")" "$(clean_field "$expected")" \
    "$(clean_field "$actual")" "$verdict" >> "$RESULTS"
  [ "$verdict" = "FAIL" ] && FAIL_N=$((FAIL_N + 1))
  [ "$verdict" = "HARNESS_ERROR" ] && HARNESS_ERROR_N=$((HARNESS_ERROR_N + 1))
}

not_run() {
  record "$1" "$2" "$3" "SKIP"
}

file_hash() {
  if [ -f "$1" ]; then
    sha256sum "$1" 2>/dev/null | cut -d' ' -f1
  else
    printf 'MISSING'
  fi
}

version_snapshot() {
  local f
  for f in "$HOME/.local/share/claude/versions"/*; do
    [ -f "$f" ] || continue
    printf '%s:%s ' "$(basename "$f")" "$(file_hash "$f")"
  done
}

run_pixel_common() {
  local install_log="$WORK/install.log"
  local settings_before login_before versions_before versions_after
  local install_rc version_rc trace_rc dns_rc update_rc
  local version_output trace_line dns_result update_output

  settings_before="$(file_hash "$HOME/.claude/settings.json")"
  login_before="$(file_hash "$HOME/.claude.json")"
  versions_before="$(version_snapshot)"
  timeout -s KILL 900 bash "$SCRIPT_DIR/install.sh" > "$install_log" 2>&1
  install_rc=$?
  cat "$install_log"
  if [ "$install_rc" -eq 0 ] &&
     grep -q 'existing v2.9 install detected; refreshing the launcher' "$install_log"; then
    record refresh_classified "existing install refreshed" "rc=$install_rc; classification present" PASS
  else
    record refresh_classified "existing install refreshed" "rc=$install_rc; classification absent or failed" FAIL
  fi

  versions_after="$(version_snapshot)"
  if [ "$versions_before" = "$versions_after" ]; then
    record refresh_no_download "no versioned binary change during refresh" "unchanged: $versions_after" PASS
  else
    record refresh_no_download "no versioned binary change during refresh" "before=$versions_before after=$versions_after" FAIL
  fi
  if [ "$settings_before" = "$(file_hash "$HOME/.claude/settings.json")" ] &&
     [ "$login_before" = "$(file_hash "$HOME/.claude.json")" ]; then
    record identity_preserved "settings and login preserved" "hashes unchanged" PASS
  else
    record identity_preserved "settings and login preserved" "one or more hashes changed" FAIL
  fi

  timeout -s KILL 60 "$PREFIX/bin/claude" --version > "$WORK/version.log" 2>&1
  version_rc=$?
  version_output="$(tr '\n' ' ' < "$WORK/version.log")"
  if [ "$version_rc" -eq 0 ] &&
     ! grep -q 'Cannot read directory.*EACCES' "$WORK/version.log"; then
    record version_no_eacces "version succeeds without EACCES" "rc=$version_rc; $version_output" PASS
  else
    record version_no_eacces "version succeeds without EACCES" "rc=$version_rc; $version_output" FAIL
  fi

  timeout -s KILL 60 bash -x "$PREFIX/bin/claude" --version > "$WORK/xtrace.log" 2>&1
  trace_rc=$?
  trace_line="$(grep -E 'BUN_OPTIONS=.*--preload ' "$WORK/xtrace.log" | tail -1)"
  if [ "$trace_rc" -eq 0 ] &&
     printf '%s' "$trace_line" | grep -Eq -- '--preload (\./|\.\./)'; then
    record relative_preload "preload begins ./ or ../" "rc=$trace_rc; $trace_line" PASS
  else
    record relative_preload "preload begins ./ or ../" "rc=$trace_rc; $trace_line" FAIL
  fi

  cat > "$WORK/dns-probe.js" <<'JS'
const dns=require("dns"),fs=require("fs");
dns.resolve4("api.anthropic.com",(e,a)=>fs.writeFileSync(process.env.DNS_MARKER,e?`ERROR:${e.code||e}`:`ADDR:${a.join(",")}`));
JS
  rm -f "$WORK/dns.marker"
  (
    cd "$HOME" || exit
    DNS_MARKER="$WORK/dns.marker" \
      BUN_OPTIONS="--preload ./.cache/claude-code-android-matrix/dns-probe.js" \
      timeout -s KILL 60 "$PREFIX/bin/claude" --version
  ) > "$WORK/dns.log" 2>&1
  dns_rc=$?
  dns_result="$(cat "$WORK/dns.marker" 2>/dev/null)"
  if [ "$dns_rc" -eq 0 ] &&
     printf '%s' "$dns_result" | grep -Eq '^ADDR:([0-9]{1,3}\.){3}[0-9]{1,3}'; then
    record dns_lookup "dns.resolve4 returns IPv4 addresses" "rc=$dns_rc; $dns_result" PASS
  else
    record dns_lookup "dns.resolve4 returns IPv4 addresses" "rc=$dns_rc; $dns_result" FAIL
  fi

  timeout -s KILL 360 "$PREFIX/bin/claude" --update-now --version > "$WORK/update.log" 2>&1
  update_rc=$?
  update_output="$(tr '\n' ' ' < "$WORK/update.log")"
  if [ "$update_rc" -eq 0 ] && ! grep -qi 'checksum mismatch' "$WORK/update.log"; then
    record update_check "non-interactive update completes without checksum mismatch" "rc=$update_rc; $update_output" PASS
  else
    record update_check "non-interactive update completes without checksum mismatch" "rc=$update_rc; $update_output" FAIL
  fi
}

run_concurrency() {
  local a_rc b_rc combined old fresh sweep_rc tmp_list
  rm -f "$HOME/.local/share/claude/versions"/*.tmp
  timeout -s KILL 360 "$PREFIX/bin/claude" --update-now --version > "$WORK/concurrent-a.log" 2>&1 &
  local a_pid
  a_pid=$!
  sleep 0.15
  timeout -s KILL 360 "$PREFIX/bin/claude" --update-now --version > "$WORK/concurrent-b.log" 2>&1 &
  local b_pid
  b_pid=$!
  wait "$a_pid"; a_rc=$?
  wait "$b_pid"; b_rc=$?
  combined="$(cat "$WORK/concurrent-a.log" "$WORK/concurrent-b.log")"
  if [ "$a_rc" -eq 0 ] && [ "$b_rc" -eq 0 ] &&
     ! printf '%s' "$combined" | grep -Eqi 'checksum mismatch|No such file'; then
    record concurrent_updates "two non-interactive launches complete without race symptoms" "rc1=$a_rc; rc2=$b_rc" PASS
  else
    record concurrent_updates "two non-interactive launches complete without race symptoms" "rc1=$a_rc; rc2=$b_rc; output=$combined" FAIL
  fi
  tmp_list="$(printf '%s\n' "$HOME/.local/share/claude/versions"/*.tmp)"
  if ! compgen -G "$HOME/.local/share/claude/versions/*.tmp" >/dev/null; then
    record concurrent_no_tmp "no staging files remain" "none" PASS
  else
    record concurrent_no_tmp "no staging files remain" "$tmp_list" FAIL
  fi

  old="$HOME/.local/share/claude/versions/matrix-old.tmp"
  fresh="$HOME/.local/share/claude/versions/matrix-fresh.tmp"
  printf old > "$old"
  if ! touch -d '2 days ago' "$old" 2>/dev/null; then
    not_run stale_sweep "old removed and fresh retained" "touch cannot set an old mtime"
    rm -f "$old"
    return
  fi
  printf fresh > "$fresh"
  timeout -s KILL 360 "$PREFIX/bin/claude" --update-now --version > "$WORK/sweep.log" 2>&1
  sweep_rc=$?
  if [ "$sweep_rc" -eq 0 ] && [ ! -e "$old" ] && [ -e "$fresh" ]; then
    record stale_sweep "old removed and fresh retained" "rc=$sweep_rc; old removed; fresh retained" PASS
  else
    record stale_sweep "old removed and fresh retained" "rc=$sweep_rc; old=$([ -e "$old" ] && echo present || echo removed); fresh=$([ -e "$fresh" ] && echo present || echo removed)" FAIL
  fi
  rm -f "$old" "$fresh"
}

run_migration_abort() {
  local before after before_rc migrate_rc version_rc output
  timeout -s KILL 60 claude --version > "$WORK/pinned-before.log" 2>&1
  before_rc=$?
  before="$(readlink "$PREFIX/bin/claude" 2>/dev/null):$(tr '\n' ' ' < "$WORK/pinned-before.log")"
  printf 'n\ny\n' | timeout -s KILL 1200 bash "$SCRIPT_DIR/migrate.sh" > "$WORK/migrate.log" 2>&1
  migrate_rc=$?
  cat "$WORK/migrate.log"
  if grep -qi 'crashes on this device' "$WORK/migrate.log" &&
     grep -qi 'migration aborted' "$WORK/migrate.log" &&
     ! grep -q 'migration stopped (exit' "$WORK/migrate.log"; then
    record migration_abort "crash guidance and migration aborted; no ERR trap exit" "rc=$migrate_rc; expected abort observed" PASS
  else
    record migration_abort "crash guidance and migration aborted; no ERR trap exit" "rc=$migrate_rc; required evidence missing" FAIL
  fi
  timeout -s KILL 60 claude --version > "$WORK/pinned-after.log" 2>&1
  version_rc=$?
  output="$(tr '\n' ' ' < "$WORK/pinned-after.log")"
  after="$(readlink "$PREFIX/bin/claude" 2>/dev/null):${output% }"
  if [ "$before_rc" -ne 0 ]; then
    not_run pinned_intact "pinned target and version unchanged" "baseline version failed with rc=$before_rc"
  elif [ "$version_rc" -eq 0 ] && [ "${before% }" = "$after" ]; then
    record pinned_intact "pinned target and version unchanged" "before=$before; after=$after" PASS
  else
    record pinned_intact "pinned target and version unchanged" "rc=$version_rc; before=$before; after=$after" FAIL
  fi
}

run_fresh_gate() {
  local install_rc pinned_rc version_rc output
  printf 'y\nn\n' | timeout -s KILL 1800 bash "$SCRIPT_DIR/install.sh" > "$WORK/fresh-install.log" 2>&1
  install_rc=$?
  cat "$WORK/fresh-install.log"
  if [ "$install_rc" -eq 0 ] &&
     grep -q 'Install complete, but this Claude Code release cannot run on this device.' "$WORK/fresh-install.log" &&
     grep -q 'install-pinned.sh' "$WORK/fresh-install.log"; then
    record release_gate "crash-aware install completes with pinned guidance" "rc=$install_rc; crash-aware close present" PASS
  else
    record release_gate "crash-aware install completes with pinned guidance" "rc=$install_rc; required close or guidance missing" FAIL
  fi
  if [ -f "$PREFIX/bin/claude" ] && [ -f "$HOME/.claude/settings.json" ] &&
     grep -Fq 'native-install launcher discovery' "$HOME/.bashrc"; then
    record gate_artifacts "launcher, settings, and PATH entry exist" "all present" PASS
  else
    record gate_artifacts "launcher, settings, and PATH entry exist" "one or more missing" FAIL
  fi
  printf 'y\n' | timeout -s KILL 1200 bash "$SCRIPT_DIR/install-pinned.sh" > "$WORK/pinned-install.log" 2>&1
  pinned_rc=$?
  cat "$WORK/pinned-install.log"
  timeout -s KILL 60 "$PREFIX/bin/claude" --version > "$WORK/pinned-version.log" 2>&1
  version_rc=$?
  output="$(tr '\n' ' ' < "$WORK/pinned-version.log")"
  if [ "$pinned_rc" -eq 0 ] && [ "$version_rc" -eq 0 ]; then
    record pinned_restore "pinned installer and version succeed" "install_rc=$pinned_rc; version_rc=$version_rc; $output" PASS
  else
    record pinned_restore "pinned installer and version succeed" "install_rc=$pinned_rc; version_rc=$version_rc; $output" FAIL
  fi
}

echo "START $RUN_ID $(date -Is)"
missing_scripts=""
case "$MODE" in
  pixel-refresh|pixel-concurrency)
    [ -f "$SCRIPT_DIR/install.sh" ] || missing_scripts="install.sh"
    ;;
  migration-abort)
    [ -f "$SCRIPT_DIR/migrate.sh" ] || missing_scripts="migrate.sh"
    ;;
  fresh-gate)
    [ -f "$SCRIPT_DIR/install.sh" ] || missing_scripts="install.sh"
    [ -f "$SCRIPT_DIR/install-pinned.sh" ] || missing_scripts="${missing_scripts:+$missing_scripts,}install-pinned.sh"
    ;;
esac
if [ -n "$missing_scripts" ]; then
  record runner_preflight "required staged scripts exist" "missing: $missing_scripts" HARNESS_ERROR
  case "$MODE" in
    pixel-refresh)
      for id in refresh_classified refresh_no_download identity_preserved version_no_eacces relative_preload dns_lookup update_check; do
        not_run "$id" "mode check executes" "required staged scripts missing"
      done
      ;;
    pixel-concurrency)
      for id in refresh_classified refresh_no_download identity_preserved version_no_eacces relative_preload dns_lookup update_check concurrent_updates concurrent_no_tmp stale_sweep; do
        not_run "$id" "mode check executes" "required staged scripts missing"
      done
      ;;
    migration-abort)
      not_run migration_abort "migration abort behavior verified" "required staged scripts missing"
      not_run pinned_intact "pinned install remains intact" "required staged scripts missing"
      ;;
    fresh-gate)
      not_run release_gate "crash-aware install completes" "required staged scripts missing"
      not_run gate_artifacts "launcher, settings, and PATH entry exist" "required staged scripts missing"
      not_run pinned_restore "pinned install restored" "required staged scripts missing"
      ;;
  esac
  echo "DONE $RUN_ID $(date -Is)"
  touch "$OUT_DIR/$RUN_ID.done" || exit 2
  exit 2
fi
record runner_preflight "required staged scripts exist" "present" PASS
case "$MODE" in
  pixel-refresh) run_pixel_common ;;
  pixel-concurrency) run_pixel_common; run_concurrency ;;
  migration-abort) run_migration_abort ;;
  fresh-gate) run_fresh_gate ;;
esac
echo "DONE $RUN_ID $(date -Is)"
if ! touch "$OUT_DIR/$RUN_ID.done"; then
  printf 'HARNESS_ERROR: cannot write completion marker\n' >&2
  exit 2
fi
if [ "$HARNESS_ERROR_N" -gt 0 ]; then
  exit 2
elif [ "$FAIL_N" -gt 0 ]; then
  exit 1
fi
exit 0
