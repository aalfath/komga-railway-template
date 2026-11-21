#!/bin/sh
# Start Komga on Railway.
# 1. Keep all state on the volume mounted at /data.
# 2. Listen on $PORT (Railway) or 25600.
# 3. On first boot, claim the server for KOMGA_ADMIN_EMAIL / KOMGA_ADMIN_PASSWORD,
#    so nobody else can claim it from the public URL, and create one library at
#    /data/library. Both steps run only on an unclaimed server with no libraries,
#    so a redeploy never undoes changes made in the web UI.
set -eu

log() { echo "komga-railway: $*"; }

DATA_DIR="${KOMGA_DATA_DIR:-/data}"
export KOMGA_CONFIGDIR="${KOMGA_CONFIGDIR:-$DATA_DIR/config}"
export SERVER_PORT="${SERVER_PORT:-${PORT:-25600}}"
LIBRARY_DIR="${KOMGA_LIBRARY_DIR:-$DATA_DIR/library}"
BASE="http://127.0.0.1:$SERVER_PORT"

mkdir -p "$KOMGA_CONFIGDIR" "$LIBRARY_DIR"

if [ ! -w "$DATA_DIR" ]; then
  log "WARNING: $DATA_DIR is not writable; attach a Railway volume at $DATA_DIR"
fi

# curl reads credentials from stdin (-K -), so they never show in the process list.
cfg_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

bootstrap() {
  email="${KOMGA_ADMIN_EMAIL:-}"
  password="${KOMGA_ADMIN_PASSWORD:-}"
  if [ -z "$email" ] || [ -z "$password" ]; then
    log "KOMGA_ADMIN_EMAIL or KOMGA_ADMIN_PASSWORD is empty: open the web UI to create the admin account"
    return 0
  fi
  e="$(cfg_escape "$email")"
  p="$(cfg_escape "$password")"

  i=0
  until curl -fsS --max-time 3 "$BASE/actuator/health" 2>/dev/null | grep -q '"UP"'; do
    i=$((i + 1))
    if [ "$i" -ge 1200 ]; then log "server never reported UP; skipping first-run setup"; return 0; fi
    sleep 0.5
  done

  if curl -fsS --max-time 10 "$BASE/api/v1/claim" | grep -q '"isClaimed":false'; then
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 -X POST "$BASE/api/v1/claim" -K - <<CFG
header = "X-Komga-Email: $e"
header = "X-Komga-Password: $p"
CFG
)"
    case "$code" in
      2*) log "created the admin account $email" ;;
      *) log "claiming the server failed (HTTP $code); create the admin in the web UI"; return 0 ;;
    esac

    libs="$(curl -sS --max-time 30 "$BASE/api/v1/libraries" -K - <<CFG
user = "$e:$p"
CFG
)" || libs=error
    if [ "$libs" = "[]" ]; then
      code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 -X POST "$BASE/api/v1/libraries" \
        -H 'Content-Type: application/json' \
        --data "{\"name\":\"Library\",\"root\":\"$LIBRARY_DIR\",\"scanOnStartup\":true,\"scanInterval\":\"EVERY_6H\"}" -K - <<CFG
user = "$e:$p"
CFG
)"
      log "created library 'Library' at $LIBRARY_DIR (HTTP $code)"
    fi
  else
    log "server already claimed; leaving accounts and libraries alone"
  fi
}

bootstrap &

exec java -Dspring.profiles.include=docker --enable-native-access=ALL-UNNAMED -jar application.jar "$@"
