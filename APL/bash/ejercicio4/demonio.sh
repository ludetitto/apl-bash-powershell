#!/usr/bin/env bash
#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 4                                    #
#                                                       #
#   Integrantes:                                        #
#       Vignardel Francisco                             #
#       Lucia de Titto                                  #
#       Samuel                                          #
#       Francisco Vladimir                              #
#                                                       #
#-------------------------------------------------------#

# demonio.sh - Monitorea un directorio y detecta archivos con palabras clave.
# Flags: -d/--directorio  --palabras  -l/--log  -k/--kill  -h/--help
set -euo pipefail

# ---------- UI ----------
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'
log_error(){ echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_info(){  echo -e "${GREEN}[INFO] ${NC}$*"; }
log_warn(){  echo -e "${YELLOW}[WARN] ${NC}$*"; }
timestamp(){ date +"%Y-%m-%d %H:%M:%S"; }

# ---------- Help ----------
show_help() {
  cat <<'EOF'
Uso:
  Iniciar daemon (OBLIGATORIOS: -d --palabras -l):
    ./demonio.sh -d <directorio> --palabras <pal1,pal2,...> -l <archivo_log>

  Detener daemon (SOLO -d -k):
    ./demonio.sh -d <directorio> -k

Flags:
  -d, --directorio    Ruta del directorio a monitorear
  --palabras          Palabras clave separadas por comas (ej: password,token,api_key)
  -l, --log           Ruta del archivo de log
  -k, --kill          Detiene el daemon del directorio indicado (solo con -d)
  -h, --help          Muestra esta ayuda

Ejemplos:
  ./demonio.sh -d ../descargas --palabras password,account,unlam -l log.txt
  ./demonio.sh -d ../descargas --kill
EOF
}

# ---------- Helpers ----------
to_abs_path() {
  local p="${1:-}"; [[ -z "$p" ]] && { echo ""; return 0; }
  if [[ "$p" = /* ]]; then echo "$p"; else
    local dir base; dir="$(dirname -- "$p")"; base="$(basename -- "$p")"
    (cd -- "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base") || printf '%s\n' "$p"
  fi
}

# PID file único por directorio (basado en hash del path absoluto)
get_pid_file() {
  echo "/tmp/demonio_$(echo -n "$DIRECTORIO" | md5sum | cut -d' ' -f1).pid"
}

# Devuelve el PID del daemon si está corriendo, vacío si no
running_pid() {
  local pf; pf="$(get_pid_file)"
  [[ -f "$pf" ]] || return 0
  local pid; pid="$(cat "$pf")"
  if kill -0 "$pid" 2>/dev/null; then
    echo "$pid"
  else
    rm -f "$pf"   # PID file huérfano
  fi
}

# ---------- Dependencias ----------
check_dependencies() {
  local -a missing=()
  for cmd in grep inotifywait; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    log_error "Dependencias faltantes: ${missing[*]}"
    [[ " ${missing[*]} " == *" inotifywait "* ]] && \
      log_error "Instalar inotify-tools: sudo apt install inotify-tools"
    exit 1
  fi
}

# ---------- Log ----------
log_line() {
  printf '%s\n' "$1" >> "$LOGFILE"
}

# ---------- Tamaño ----------
get_file_size() {
  stat -c%s "$1" 2>/dev/null || echo "?"
}

# ---------- Escaneo ----------
declare -a PALABRAS=()

scan_file() {
  local filepath="$1" operacion="$2"
  [[ -f "$filepath" ]] || return 0
  LC_ALL=C grep -Iq . -- "$filepath" 2>/dev/null || return 0  # saltar binarios
  local size; size="$(get_file_size "$filepath")"
  local pal
  for pal in "${PALABRAS[@]}"; do
    [[ -z "$pal" ]] && continue
    if LC_ALL=C grep -qi -- "$pal" "$filepath" 2>/dev/null; then
      log_line "$(printf "[%s] Operación: %-10s | Archivo: '%s' | Palabra: '%s' | Tamaño: %s bytes" \
        "$(timestamp)" "$operacion" "$filepath" "$pal" "$size")"
    fi
  done
}

scan_existing_files() {
  local count=0
  log_line "[$(timestamp)] Procesando archivos existentes en '$DIRECTORIO' ..."
  while IFS= read -r -d '' f; do
    scan_file "$f" "EXISTENTE"
    count=$(( count + 1 ))
  done < <(find "$DIRECTORIO" -maxdepth 1 -type f -print0 2>/dev/null)
  log_line "[$(timestamp)] $count archivos existentes procesados."
}

# Función separada para poder usar 'local' correctamente
# (local solo es válido dentro de funciones, no en un while/pipe)
process_inotify_event() {
  local line="$1"
  local op filepath
  op="$(awk '{print $1}' <<< "$line")"
  filepath="$(awk '{$1=""; print substr($0,2)}' <<< "$line")"
  scan_file "$filepath" "$op"
}

# ---------- Daemon loop ----------
daemon_loop() {
  log_line "$(printf "[%s] Demonio iniciado | Directorio: '%s' | Palabras: %s" \
    "$(timestamp)" "$DIRECTORIO" "${PALABRAS[*]}")"

  scan_existing_files

  # Process substitution < <(...) en lugar de pipe |
  # Con pipe: inotifywait | while → el while corre en un subshell hijo
  #           que hereda los args del padre → ps ve DOS procesos con los mismos args
  # Con < <(): inotifywait corre en un subshell separado, el while queda
  #            en el proceso principal → ps ve UN solo proceso demonio
  while IFS= read -r line; do
    process_inotify_event "$line"
  done < <(inotifywait -m -e close_write,moved_to \
             --format '%e %w%f' "$DIRECTORIO" 2>/dev/null)
}

# ---------- CLI ----------
DIRECTORIO=""; PALABRAS_STR=""; LOGFILE=""; KILL_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--directorio)     DIRECTORIO="$(to_abs_path "${2:-}")"; shift 2;;
    --palabras)          PALABRAS_STR="${2:-}"; shift 2;;
    -l|--log)            LOGFILE="$(to_abs_path "${2:-}")"; shift 2;;
    -k|--kill)           KILL_MODE=1; shift;;
    -h|--help)           show_help; exit 0;;
    --)                  shift; break;;
    -*)                  log_error "Flag desconocido: $1"; exit 1;;
    *)                   log_error "Argumento no reconocido: $1"; exit 1;;
  esac
done

# ---------- Validaciones ----------
if (( KILL_MODE )); then
  [[ -z "$DIRECTORIO" ]] && { log_error "Con -k/--kill debe indicar -d/--directorio"; exit 1; }
  [[ -n "${PALABRAS_STR:-}" || -n "${LOGFILE:-}" ]] && \
    { log_error "Con -k/--kill solo se permite -d/--directorio"; exit 1; }
else
  [[ -z "$DIRECTORIO" ]]   && { log_error "Falta -d/--directorio"; exit 1; }
  [[ -z "$PALABRAS_STR" ]] && { log_error "Falta --palabras"; exit 1; }
  [[ -z "$LOGFILE" ]]      && { log_error "Falta -l/--log"; exit 1; }
fi

[[ -d "$DIRECTORIO" ]] || { log_error "El directorio no existe: '$DIRECTORIO'"; exit 1; }

# Parsear palabras clave
IFS=',' read -ra PALABRAS <<< "$PALABRAS_STR"
for i in "${!PALABRAS[@]}"; do
  PALABRAS[$i]="$(echo "${PALABRAS[$i]}" | xargs)"
done

# ---------- Kill mode ----------
if (( KILL_MODE )); then
  pid="$(running_pid)"
  if [[ -z "$pid" ]]; then
    log_warn "No hay daemon corriendo para '$DIRECTORIO'."
    exit 1
  fi
  kill -TERM "$pid" 2>/dev/null || true
  sleep 1
  kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
  rm -f "$(get_pid_file)"
  log_info "Daemon detenido (PID: $pid)."
  exit 0
fi

# ---------- Modo daemon (hijo relanzado por nohup) ----------
# El hijo entra aquí directamente, sin re-truncar el log ni re-chequear deps
if [[ "${DAEMON_MODE:-0}" == "1" ]]; then
  trap 'rm -f "$(get_pid_file)"' EXIT   # limpia PID file al salir (éxito, error o señal)
  daemon_loop
  exit 0
fi

# ---------- Preparar log ----------
mkdir -p -- "$(dirname -- "$LOGFILE")" 2>/dev/null || true
: > "$LOGFILE" 2>/dev/null || { log_error "No puedo escribir en '$LOGFILE'"; exit 1; }

check_dependencies

# ---------- Prevenir duplicados ----------
pid="$(running_pid)"
if [[ -n "$pid" ]]; then
  log_error "Ya hay un daemon para este directorio (PID: $pid)."; exit 1
fi

# ---------- Lanzar daemon ----------
nohup env DAEMON_MODE=1 "$0" \
  -d "$DIRECTORIO" \
  --palabras "$PALABRAS_STR" \
  -l "$LOGFILE" >/dev/null 2>&1 &
child_pid=$!
echo "$child_pid" > "$(get_pid_file)"

log_info "Daemon iniciado en segundo plano (PID: $child_pid)."
