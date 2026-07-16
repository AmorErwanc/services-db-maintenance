#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly MYSQL_DEFAULTS_FILE="${MYSQL_DEFAULTS_FILE:-${PROJECT_ROOT}/mysql.cnf}"
readonly MYSQL_DATABASE="${MYSQL_DATABASE:-services}"
readonly RETENTION_DAYS="${RETENTION_DAYS:-30}"
readonly BATCH_SIZE="${BATCH_SIZE:-10000}"
readonly MAX_BATCHES="${MAX_BATCHES:-100}"
readonly PAUSE_SECONDS="${PAUSE_SECONDS:-0.2}"

apply=false
case "${1:-}" in
  ""|--dry-run) ;;
  --apply) apply=true ;;
  -h|--help)
    cat <<'EOF'
用法：cleanup-llm-call-log.sh [--dry-run|--apply]

默认只预览超过保留期的行数；--apply 才会分批删除。
可通过环境变量覆盖：MYSQL_DEFAULTS_FILE、MYSQL_DATABASE、RETENTION_DAYS、
BATCH_SIZE、MAX_BATCHES、PAUSE_SECONDS。
EOF
    exit 0
    ;;
  *)
    echo "不支持的参数：${1}" >&2
    exit 64
    ;;
esac

for value_name in RETENTION_DAYS BATCH_SIZE MAX_BATCHES; do
  value="${!value_name}"
  if [[ ! "${value}" =~ ^[1-9][0-9]*$ ]]; then
    echo "${value_name} 必须是正整数，当前值：${value}" >&2
    exit 64
  fi
done

if [[ ! -r "${MYSQL_DEFAULTS_FILE}" ]]; then
  echo "MySQL 配置不可读：${MYSQL_DEFAULTS_FILE}" >&2
  exit 66
fi

mysql_query() {
  mysql \
    --defaults-extra-file="${MYSQL_DEFAULTS_FILE}" \
    --batch \
    --raw \
    --skip-column-names \
    --show-warnings \
    "${MYSQL_DATABASE}" \
    -e "$1"
}

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$*"
}

db_name="$(mysql_query 'SELECT DATABASE();')"
if [[ "${db_name}" != "services" ]]; then
  echo "安全检查失败：当前数据库是 ${db_name}，预期 services" >&2
  exit 65
fi

table_exists="$(mysql_query "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='llm_call_log';")"
index_exists="$(mysql_query "SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='llm_call_log' AND index_name='idx_created';")"
if [[ "${table_exists}" != "1" || "${index_exists}" -lt 1 ]]; then
  echo "安全检查失败：llm_call_log 或 idx_created 不存在" >&2
  exit 65
fi

cutoff="$(mysql_query "SELECT DATE_FORMAT(DATE_SUB(NOW(), INTERVAL ${RETENTION_DAYS} DAY), '%Y-%m-%d %H:%i:%s');")"
expired_before="$(mysql_query "SELECT COUNT(*) FROM llm_call_log FORCE INDEX (idx_created) WHERE created_at < '${cutoff}';")"

log "mode=$([[ "${apply}" == true ]] && echo apply || echo dry-run) database=${db_name} cutoff='${cutoff}' expired_rows=${expired_before} batch_size=${BATCH_SIZE} max_batches=${MAX_BATCHES}"

if [[ "${apply}" != true || "${expired_before}" == "0" ]]; then
  exit 0
fi

deleted_total=0
batch=0
while (( batch < MAX_BATCHES )); do
  batch=$((batch + 1))
  deleted="$(mysql_query "DELETE FROM llm_call_log WHERE created_at < '${cutoff}' ORDER BY created_at ASC LIMIT ${BATCH_SIZE}; SELECT ROW_COUNT();")"
  deleted="$(printf '%s\n' "${deleted}" | tail -n 1)"
  deleted_total=$((deleted_total + deleted))
  log "batch=${batch} deleted=${deleted} deleted_total=${deleted_total}"

  if (( deleted < BATCH_SIZE )); then
    break
  fi
  sleep "${PAUSE_SECONDS}"
done

remaining="$(mysql_query "SELECT COUNT(*) FROM llm_call_log FORCE INDEX (idx_created) WHERE created_at < '${cutoff}';")"
log "completed cutoff='${cutoff}' deleted_total=${deleted_total} remaining_expired_rows=${remaining}"

if (( remaining > 0 )); then
  echo "仍有 ${remaining} 行过期数据；已达到 MAX_BATCHES=${MAX_BATCHES}" >&2
  exit 2
fi
