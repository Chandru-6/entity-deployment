#!/usr/bin/env bash
set -euo pipefail

OCIR_REGION_HOST="<region>.ocir.io"
COLLECTOR_REPO="$OCIR_REGION_HOST/<TENANCY_NS>/entity-collector"
PROCESSOR_REPO="$OCIR_REGION_HOST/<TENANCY_NS>/entity-processor"
COMPOSE="/opt/stack/docker-compose.yml"

log(){ echo "$(date '+%F %T') $*"; }

check_health() {
  curl -fsS --max-time 5 "$1" >/dev/null 2>&1
}

roll_if_changed() {
  local service="$1" repo="$2" health_url="$3"

  docker pull "$repo:latest" >/dev/null 2>&1 || { log "pull failed $service"; return; }

  local latest running
  latest="$(docker image inspect "$repo:latest" -f '{{.Id}}' 2>/dev/null || true)"
  running="$(docker inspect "$service" -f '{{.Image}}' 2>/dev/null || true)"

  if [ -z "$running" ]; then
    log "$service not running → starting"
    docker compose -f "$COMPOSE" up -d "$service"
    check_health "$health_url" && log "$service healthy" || log "$service unhealthy after start"
    return
  fi

  if [ "$latest" != "$running" ]; then
    log "new image for $service → rolling"
    docker compose -f "$COMPOSE" up -d "$service"
  else
    if check_health "$health_url"; then
      log "$service up-to-date and healthy"
    else
      log "$service unhealthy → restart"
      docker compose -f "$COMPOSE" up -d "$service"
    fi
  fi
}

roll_if_changed "entity-collector"  "$COLLECTOR_REPO"  "http://localhost:8081/actuator/health"
roll_if_changed "entity-processor"  "$PROCESSOR_REPO"  "http://localhost:8082/actuator/health"
