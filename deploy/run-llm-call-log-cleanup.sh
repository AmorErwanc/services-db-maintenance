#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_ROOT="/home/flow/docker-services/services-db-maintenance"
export MYSQL_DEFAULTS_FILE="${PROJECT_ROOT}/mysql.cnf"

"${PROJECT_ROOT}/scripts/cleanup-llm-call-log.sh" --apply 2>&1 \
  | /usr/bin/logger -t services-db-maintenance
