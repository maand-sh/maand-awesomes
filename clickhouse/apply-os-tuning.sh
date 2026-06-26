#!/usr/bin/env bash
# Apply ClickHouse host OS tuning (see OS-TUNING.md).
#
# Usage:
#   sudo ./apply-os-tuning.sh apply          # install and apply settings
#   sudo ./apply-os-tuning.sh check          # verify current settings
#   sudo ./apply-os-tuning.sh apply --cpu    # also set CPU governor to performance
#
set -euo pipefail

SYSCTL_FILE="/etc/sysctl.d/99-clickhouse.conf"
LIMITS_FILE="/etc/security/limits.d/clickhouse.conf"
THP_SERVICE="/etc/systemd/system/disable-thp.service"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "run as root (sudo $0 $*)"
  fi
}

thp_enabled_path() {
  if [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]]; then
    echo /sys/kernel/mm/transparent_hugepage/enabled
  else
    echo ""
  fi
}

thp_defrag_path() {
  if [[ -f /sys/kernel/mm/transparent_hugepage/defrag ]]; then
    echo /sys/kernel/mm/transparent_hugepage/defrag
  else
    echo ""
  fi
}

apply_thp_runtime() {
  local enabled defrag
  enabled="$(thp_enabled_path)"
  defrag="$(thp_defrag_path)"

  if [[ -z "$enabled" ]]; then
    warn "THP sysfs not found; skipping runtime THP change"
    return 0
  fi

  log "setting THP to madvise (runtime)"
  echo madvise >"$enabled"
  if [[ -n "$defrag" ]]; then
    echo madvise >"$defrag"
  fi
}

install_thp_service() {
  log "installing systemd unit: $THP_SERVICE"
  cat >"$THP_SERVICE" <<'EOF'
[Unit]
Description=Disable Transparent Huge Pages for ClickHouse
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'test -f /sys/kernel/mm/transparent_hugepage/enabled && echo madvise > /sys/kernel/mm/transparent_hugepage/enabled || true'
ExecStart=/bin/sh -c 'test -f /sys/kernel/mm/transparent_hugepage/defrag && echo madvise > /sys/kernel/mm/transparent_hugepage/defrag || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now disable-thp.service
}

install_sysctl() {
  log "writing $SYSCTL_FILE"
  cat >"$SYSCTL_FILE" <<'EOF'
# ClickHouse host tuning (managed by apply-os-tuning.sh)
vm.swappiness = 1
kernel.task_delayacct = 1
vm.max_map_count = 262144

net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 4096
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
EOF
  sysctl --system >/dev/null
}

install_limits() {
  log "writing $LIMITS_FILE"
  cat >"$LIMITS_FILE" <<'EOF'
# ClickHouse / Docker host processes
*               soft    nofile          262144
*               hard    nofile          262144
clickhouse      soft    nofile          262144
clickhouse      hard    nofile          262144
EOF
}

apply_cpu_governor() {
  local gov_path n=0
  shopt -s nullglob
  for gov_path in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance >"$gov_path"
    n=$((n + 1))
  done
  shopt -u nullglob

  if [[ "$n" -eq 0 ]]; then
    warn "no CPU frequency governors found; skipped"
  else
    log "set performance governor on $n CPU(s)"
  fi
}

check_thp() {
  local enabled
  enabled="$(thp_enabled_path)"
  if [[ -z "$enabled" ]]; then
    echo "THP:             (not available)"
    return 0
  fi
  echo "THP enabled:     $(cat "$enabled")"
  if grep -q '\[always\]' "$enabled" 2>/dev/null; then
    return 1
  fi
  return 0
}

check_sysctl() {
  local ok=0
  echo "delayacct:         $(sysctl -n kernel.task_delayacct 2>/dev/null || echo '?')"
  echo "swappiness:        $(sysctl -n vm.swappiness 2>/dev/null || echo '?')"
  echo "somaxconn:         $(sysctl -n net.core.somaxconn 2>/dev/null || echo '?')"
  echo "max_map_count:     $(sysctl -n vm.max_map_count 2>/dev/null || echo '?')"

  [[ "$(sysctl -n kernel.task_delayacct 2>/dev/null)" == "1" ]] || ok=1
  [[ "$(sysctl -n vm.swappiness 2>/dev/null)" == "1" ]] || ok=1
  return "$ok"
}

check_limits_file() {
  if [[ -f "$LIMITS_FILE" ]]; then
    echo "limits.d:          $LIMITS_FILE (present)"
  else
    echo "limits.d:          missing ($LIMITS_FILE)"
    return 1
  fi
}

check_clickhouse_process() {
  local pid
  pid="$(pgrep -f 'clickhouse-server|clickhouse-keeper' | head -1 || true)"
  if [[ -n "$pid" ]]; then
    echo "clickhouse pid:    $pid"
    grep "open files" "/proc/$pid/limits" || true
  else
    echo "clickhouse pid:    (not running)"
  fi
}

check_data_mount() {
  local path opts
  for path in /opt/worker/*/jobs/clickhouse/data ./data; do
    if [[ -d "$path" ]]; then
      opts="$(findmnt -no OPTIONS "$path" 2>/dev/null || true)"
      if [[ -n "$opts" ]]; then
        echo "data mount opts:   $path -> $opts"
        return 0
      fi
    fi
  done
  echo "data mount opts:   (clickhouse data path not found)"
}

cmd_check() {
  local rc=0
  echo "--- ClickHouse OS tuning status ---"
  check_thp || rc=1
  check_sysctl || rc=1
  check_limits_file || rc=1
  check_clickhouse_process
  check_data_mount
  echo "-----------------------------------"
  if [[ "$rc" -eq 0 ]]; then
    log "checks passed (reboot if delayacct was just enabled)"
  else
    die "one or more checks failed; run: sudo $0 apply"
  fi
}

cmd_apply() {
  local use_cpu=0
  for arg in "$@"; do
    case "$arg" in
      --cpu) use_cpu=1 ;;
      *) die "unknown apply option: $arg (supported: --cpu)" ;;
    esac
  done

  apply_thp_runtime
  install_thp_service
  install_sysctl
  install_limits

  if [[ "$use_cpu" -eq 1 ]]; then
    apply_cpu_governor
  fi

  log "done"
  echo
  cmd_check || true
  echo
  warn "reboot recommended so delay accounting applies to all processes"
  warn "restart ClickHouse after apply: cd jobs/clickhouse && make restart"
}

usage() {
  cat <<EOF
Usage: sudo $0 <command> [options]

Commands:
  apply [--cpu]   Install sysctl, limits, THP service; apply runtime THP
  check           Print current tuning status

See OS-TUNING.md for background and manual steps (disk layout, NUMA).
EOF
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    apply)
      require_root
      cmd_apply "$@"
      ;;
    check)
      cmd_check
      ;;
    -h|--help|help|"")
      usage
      [[ -z "$cmd" ]] && exit 1
      ;;
    *)
      die "unknown command: $cmd (try: apply | check)"
      ;;
  esac
}

main "$@"
