#!/bin/bash
# rc-watchdog.sh — auto-heal de sesiones Remote Control (tmux + claude remote-control).
#
# Detecta RCs zombies/muertas y las recrea via rc-manager.sh start.
# Corre cada 3 min via cron (con flock). NO toca PM2 (regla CLAUDE.md).
#
# Reglas:
#   - oraculo siempre on: si no existe o está muerta → recrear (prioridad absoluta).
#   - Resto de RCs: solo vigila las que ya tienen tmux session creada (Pablo las inició).
#   - Respeta /tmp/rc-stopped/<name>.flag (Pablo la apagó intencional) salvo oraculo.
#   - Tope MAX_RCS=5 sesiones sanas concurrentes (no crear sexta).
#   - "Sano" = tmux existe + proceso claude hijo del pane vivo + pane no muestra "SESSION DIED".
#   - Si claude está ocupado/trabajando pero vivo → SANO, NO tocar.

set -u

LOG_FILE="/home/ubuntu/logs/rc-watchdog.log"
LOCK_FILE="/tmp/rc-watchdog.lock"
RC_MANAGER="/home/ubuntu/projects/oraculo/tools/rc-manager.sh"
TELEGRAM="/home/ubuntu/projects/oraculo/modules/telegram-notify/send.sh"
STOPPED_DIR="/tmp/rc-stopped"
MAX_RCS=5
WHITELIST="oraculo"   # RCs que SIEMPRE deben estar vivas (reusa convención de rc-manager)

mkdir -p "$(dirname "$LOG_FILE")" "$STOPPED_DIR" 2>/dev/null

exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

log() { echo "[$(date -Iseconds)] $1" >> "$LOG_FILE"; }

sanitize() { echo "$1" | tr '.:' '__'; }

# Set de RCs a vigilar: whitelist ∪ tmux sessions rc-* actuales (deduplicado)
gather_targets() {
    {
        echo "$WHITELIST" | tr ' ' '\n'
        tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^rc-' | sed 's/^rc-//'
    } | sort -u | sed '/^$/d'
}

session_exists() {
    local name; name=$(sanitize "$1")
    tmux has-session -t "rc-$name" 2>/dev/null
}

is_healthy() {
    local name="$1"
    local tmux_name="rc-$(sanitize "$name")"
    session_exists "$name" || return 1
    local pane_pid
    pane_pid=$(tmux list-panes -t "$tmux_name" -F '#{pane_pid}' 2>/dev/null | head -1)
    [ -n "$pane_pid" ] || return 1
    # Si el pane está mostrando "SESSION DIED", la RC está muerta aunque haya un sleep infinity
    if tmux capture-pane -t "$tmux_name" -p 2>/dev/null | grep -q 'SESSION DIED'; then
        return 1
    fi
    # Proceso claude hijo del pane vivo = sano (incluye claude ocupado/trabajando)
    pgrep -P "$pane_pid" -f claude >/dev/null 2>&1
}

count_healthy() {
    local n=0 s
    for s in $(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^rc-'); do
        if is_healthy "${s#rc-}"; then n=$((n+1)); fi
    done
    echo "$n"
}

recreate() {
    local name="$1"
    local tmux_name="rc-$(sanitize "$name")"
    if session_exists "$name"; then
        tmux kill-session -t "$tmux_name" 2>/dev/null
        log "killed zombie tmux $tmux_name"
    fi
    local healthy; healthy=$(count_healthy)
    if [ "$healthy" -ge "$MAX_RCS" ] && [ "$name" != "oraculo" ]; then
        log "skip $name: ya hay $healthy RCs sanas (max $MAX_RCS)"
        echo "skip-max"; return 1
    fi
    bash "$RC_MANAGER" start "$name" >>"$LOG_FILE" 2>&1
    sleep 4
    if is_healthy "$name"; then
        log "recrear OK: $name"
        echo "recreated"; return 0
    fi
    log "recrear FAIL: $name (rc-manager no levantó proceso claude)"
    echo "fail"; return 1
}

log "--- rc-watchdog tick ---"

declare -a RECREATED=()
declare -a FAILED=()
declare -a SUMMARY=()

for name in $(gather_targets); do
    flag="$STOPPED_DIR/$(sanitize "$name").flag"
    if [ -f "$flag" ] && [ "$name" != "oraculo" ]; then
        SUMMARY+=("$name: STOPPED (flag rc-stopped, skip)")
        log "skip $name: flag stopped por Pablo"
        continue
    fi

    if is_healthy "$name"; then
        SUMMARY+=("$name: SANO (no toco)")
        continue
    fi

    if ! session_exists "$name" && [ "$name" != "oraculo" ]; then
        # Sesión no existe y no es whitelist → Pablo no la inició, no la fuerzo
        SUMMARY+=("$name: ausente y fuera de whitelist (skip)")
        continue
    fi

    log "UNHEALTHY: $name → recreando"
    result=$(recreate "$name")
    case "$result" in
        recreated) RECREATED+=("$name"); SUMMARY+=("$name: MUERTA → recreada") ;;
        skip-max)  SUMMARY+=("$name: MUERTA → skip (5 RCs sanas)") ;;
        *)         FAILED+=("$name"); SUMMARY+=("$name: MUERTA → recrear FALLÓ") ;;
    esac
done

# Auto-sanado (recreó OK) → DIGEST: informativo, no interrumpe a Pablo.
if [ ${#RECREATED[@]} -gt 0 ]; then
    list=$(printf '%s, ' "${RECREATED[@]}"); list="${list%, }"
    bash "$TELEGRAM" --digest "🩺 rc-watchdog auto-revivió: $list" >/dev/null 2>&1 || log "telegram fail"
fi
# Recrear FALLÓ → DIRECTO: Pablo tiene que actuar, la RC no levanta sola.
if [ ${#FAILED[@]} -gt 0 ]; then
    list=$(printf '%s, ' "${FAILED[@]}"); list="${list%, }"
    bash "$TELEGRAM" --immediate "🔴 rc-watchdog NO pudo recrear RC(s): $list — no levantan solas, revisar." >/dev/null 2>&1 || log "telegram fail"
fi

printf '%s\n' "${SUMMARY[@]}" | tee -a "$LOG_FILE"
log "--- tick fin (recreadas=${#RECREATED[@]}) ---"
