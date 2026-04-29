#!/usr/bin/env bash
#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 4                                    #
#                                                       #
#   Integrantes:                                        #
#       Vignardel Francisco                             #
#       De Titto Lucia                                  #
#       Gallardo Samuel                                 #
#       Francisco Vladimir                              #
#       Medna Ramiro                                    #
#                                                       #
#-------------------------------------------------------#

set -euo pipefail

# =============================================================================
# COLORES Y FUNCIONES DE SALIDA
# Definidas primero porque las usa todo lo que viene después
# =============================================================================

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'
log_error(){ echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_info(){  echo -e "${GREEN}[INFO] ${NC}$*"; }
log_warn(){  echo -e "${YELLOW}[WARN] ${NC}$*"; }
timestamp(){ date +"%Y-%m-%d %H:%M:%S"; }

# =============================================================================
# AYUDA
# =============================================================================

show_help() {
  cat <<'EOF'
Descripcion:
  Script demonio que monitorea un directorio en segundo plano y registra en un
  log cada vez que se crea o modifica un archivo que contenga alguna de las
  palabras clave indicadas.

Uso:
  Iniciar demonio (OBLIGATORIOS: -d --palabras -l):
    ./demonio.sh -d <directorio> --palabras <pal1,pal2,...> -l <archivo_log>

  Detener demonio (SOLO -d -k):
    ./demonio.sh -d <directorio> -k

Flags:
  -d, --directorio    Ruta del directorio a monitorear
  -p, --palabras      Palabras clave separadas por comas (ej: password,token,api_key)
  -l, --log           Ruta del archivo de log
  -k, --kill          Detiene el demonio del directorio indicado (solo con -d)
  -h, --help          Muestra esta ayuda

Ejemplos:
  mkdir descargas
  ./demonio.sh -d descargas -p password,token,api_key -l monitoreo.log
  ./demonio.sh -d descargas -p password,token,api_key -l monitoreo.log   # debe fallar: ya hay un daemon
  echo "mi password es 1234" > descargas/credenciales.txt
  cat monitoreo.log
  ./demonio.sh -d descargas -k
EOF
}

# =============================================================================
# FUNCIONES AUXILIARES
# Resuelven paths, manejan el PID file y verifican dependencias
# =============================================================================

# Convierte una ruta relativa a absoluta sin depender de realpath
to_abs_path() {
  local p="${1:-}"; [[ -z "$p" ]] && { echo ""; return 0; }
  if [[ "$p" = /* ]]; then echo "$p"; else
    local dir base; dir="$(dirname -- "$p")"; base="$(basename -- "$p")"
    (cd -- "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base") || printf '%s\n' "$p"
  fi
}

# Nombre del PID file: único por directorio usando un hash del path absoluto
get_pid_file() {
  echo "/tmp/demonio_$(echo -n "$DIRECTORIO" | md5sum | cut -d' ' -f1).pid"
}

# Devuelve el PID del demonio si está corriendo; si el PID file es huérfano lo limpia
running_pid() {
  local pf; pf="$(get_pid_file)"
  [[ -f "$pf" ]] || return 0
  local pid; pid="$(cat "$pf")"
  if kill -0 "$pid" 2>/dev/null; then
    echo "$pid"
  else
    rm -f "$pf"
  fi
}

check_dependencies() {
  local -a missing=()
  for cmd in grep inotifywait; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    log_error "Dependencias faltantes: ${missing[*]}"
    [[ " ${missing[*]} " == *" inotifywait "* ]] && \
      log_error "Instalá inotify-tools con: sudo apt install inotify-tools"
    exit 1
  fi
}

# =============================================================================
# FUNCIONES DE MONITOREO
# Escriben en el log y escanean archivos buscando palabras clave
# =============================================================================

log_line() {
  printf '%s\n' "$1" >> "$LOGFILE"
}

get_file_size() {
  stat -c%s "$1" 2>/dev/null || echo "?"
}

# Busca las palabras clave en un archivo y registra cada coincidencia en el log
scan_file() {
  local filepath="$1" operacion="$2"
  [[ -f "$filepath" ]] || return 0
  LC_ALL=C grep -Iq . -- "$filepath" 2>/dev/null || return 0  # saltea binarios
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

# Procesa los archivos que ya estaban en el directorio al arrancar el demonio
scan_existing_files() {
  local count=0
  log_line "[$(timestamp)] Procesando archivos existentes en '$DIRECTORIO' ..."
  while IFS= read -r -d '' f; do
    scan_file "$f" "EXISTENTE"
    count=$(( count + 1 ))
  done < <(find "$DIRECTORIO" -maxdepth 1 -type f -print0 2>/dev/null)
  log_line "[$(timestamp)] $count archivos existentes procesados."
}

# Extrae operación y ruta del evento inotify y los manda a scan_file
process_inotify_event() {
  local line="$1"
  local op filepath
  op="$(awk '{print $1}' <<< "$line")"
  filepath="$(awk '{$1=""; print substr($0,2)}' <<< "$line")"
  scan_file "$filepath" "$op"
}

# Loop principal del demonio: primero escanea existentes, después escucha eventos nuevos
daemon_loop() {
  log_line "$(printf "[%s] Demonio iniciado | Directorio: '%s' | Palabras: %s" \
    "$(timestamp)" "$DIRECTORIO" "${PALABRAS[*]}")"

  scan_existing_files

  # < <(...) en lugar de pipe | para que el while quede en el proceso principal
  while IFS= read -r line; do
    process_inotify_event "$line"
  done < <(inotifywait -m -e close_write,moved_to \
             --format '%e %w%f' "$DIRECTORIO" 2>/dev/null)
}

# =============================================================================
# PARSEO DE ARGUMENTOS
# =============================================================================

DIRECTORIO=""; PALABRAS_STR=""; LOGFILE=""; KILL_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--directorio)     DIRECTORIO="$(to_abs_path "${2:-}")"; shift 2;;
    -p|--palabras)       PALABRAS_STR="${2:-}"; shift 2;;
    -l|--log)            LOGFILE="$(to_abs_path "${2:-}")"; shift 2;;
    -k|--kill)           KILL_MODE=1; shift;;
    -h|--help)           show_help; exit 0;;
    --)                  shift; break;;
    -*)                  log_error "Flag desconocido: $1"; exit 1;;
    *)                   log_error "Argumento no reconocido: $1"; exit 1;;
  esac
done

# =============================================================================
# VALIDACIONES
# =============================================================================

if (( KILL_MODE )); then
  [[ -z "$DIRECTORIO" ]] && { log_error "Con -k/--kill tenés que indicar -d/--directorio"; exit 1; }
  [[ -n "${PALABRAS_STR:-}" || -n "${LOGFILE:-}" ]] && \
    { log_error "Con -k/--kill solo se permite -d/--directorio"; exit 1; }
else
  [[ -z "$DIRECTORIO" ]]   \
    && { log_error "Falta -d/--directorio"; exit 1; }
  [[ -z "$PALABRAS_STR" ]] \
    && { log_error "Falta --palabras"; exit 1; }
  [[ -z "$LOGFILE" ]]  \
    && { log_error "Falta -l/--log"; exit 1; }
fi

[[ -d "$DIRECTORIO" ]] || { log_error "El directorio '$DIRECTORIO' no existe"; exit 1; }

# Parsear palabras clave y sacar espacios sobrantes
IFS=',' read -ra PALABRAS <<< "$PALABRAS_STR"
for i in "${!PALABRAS[@]}"; do
  PALABRAS[$i]="$(echo "${PALABRAS[$i]}" | xargs)"
done

# =============================================================================
# FLUJO PRINCIPAL
# A partir de acá el script toma uno de tres caminos:
#   1. --kill  → mata el demonio y termina
#   2. DAEMON_MODE=1 → es el proceso hijo, entra al loop de monitoreo
#   3. Normal → prepara todo y lanza el hijo en segundo plano
# =============================================================================

# --- Camino 1: matar el demonio ---
if (( KILL_MODE )); then
  pid="$(running_pid)"
  if [[ -z "$pid" ]]; then
    log_warn "No hay demonio corriendo para '$DIRECTORIO'."
    exit 1
  fi
  kill -TERM "$pid" 2>/dev/null || true
  sleep 1
  kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
  rm -f "$(get_pid_file)"
  log_info "Demonio detenido (PID: $pid)."
  exit 0
fi

# --- Camino 2: soy el proceso demonio (relanzado por nohup con DAEMON_MODE=1) ---
if [[ "${DAEMON_MODE:-0}" == "1" ]]; then
  trap 'rm -f "$(get_pid_file)"' EXIT   # limpia el PID file al salir por cualquier motivo
  daemon_loop
  exit 0
fi

# --- Camino 3: arranque normal, preparo todo y lanzo el hijo ---
mkdir -p -- "$(dirname -- "$LOGFILE")" 2>/dev/null || true
: > "$LOGFILE" 2>/dev/null || { log_error "No puedo escribir en '$LOGFILE'"; exit 1; }

check_dependencies

pid="$(running_pid)"
if [[ -n "$pid" ]]; then
  log_error "Ya hay un demonio para este directorio (PID: $pid)."; exit 1
fi

nohup env DAEMON_MODE=1 "$0" \
 -d "$DIRECTORIO" --palabras "$PALABRAS_STR" -l "$LOGFILE" \
  >/dev/null 2>&1 &
child_pid=$!
echo "$child_pid" > "$(get_pid_file)"

log_info "Demonio iniciado en segundo plano (PID: $child_pid)."
