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

<<<<<<< HEAD
# demonio.sh - Monitorea un directorio y detecta archivos con palabras clave.

# Ejemplo (parado en ~/):
#   cd ~/apl-bash-powershell/APL/bash/ejercicio4/
#   mkdir descargas
#   ./demonio.sh -d descargas -p password,token,api_key -l monitoreo.log
#   ./demonio.sh -d descargas -p password,token,api_key -l monitoreo.log   # debe fallar: ya hay un daemon
#   echo "mi password es 1234" > descargas/credenciales.txt
#   cat monitoreo.log
#   ./demonio.sh -d descargas -k
#   cat monitoreo.log                                                       # verificar que se registró el cierre

set -euo pipefail # parametros de seguridad que hace que el script frene y muestre el error


ROJO=$'\033[0;31m'; VERDE=$'\033[0;32m'; AMARILLO=$'\033[1;33m'; SIN_COLOR=$'\033[0m'
log_error(){ echo -e "${ROJO}[ERROR]${SIN_COLOR} $*" >&2; }
log_info(){  echo -e "${VERDE}[INFO] ${SIN_COLOR}$*"; }
log_warning(){ echo -e "${AMARILLO}[AVISO]${SIN_COLOR} $*"; }
time_stamp(){ date +"%Y-%m-%d %H:%M:%S"; }

# HELP
# Flags: -d/--directorio  -p/--palabras  -l/--log  -k/--kill  -h/--help
mostrar_ayuda() {
  cat <<'EOF'
Uso:
  Iniciar daemon (OBLIGATORIOS: -d -p -l):
    ./demonio.sh -d <directorio> -p <pal1,pal2,...> -l <archivo_log>
=======
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
Uso:
  Iniciar demonio (OBLIGATORIOS: -d --palabras -l):
    ./demonio.sh -d <directorio> --palabras <pal1,pal2,...> -l <archivo_log>
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)

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

<<<<<<< HEAD
#Convierte una ruta relativa en absoluta.
ruta_absoluta() {
  local ruta="${1:-}"; [[ -z "$ruta" ]] && { echo ""; return 0; }
  if [[ "$ruta" = /* ]]; then echo "$ruta"; else
    local dir base; dir="$(dirname -- "$ruta")"; base="$(basename -- "$ruta")"
    (cd -- "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base") || printf '%s\n' "$ruta"
  fi
}

# Genera una ruta única en /tmp para guardar el PID del daemon.
obtener_archivo_pid() {
  echo "/tmp/demonio_$(echo -n "$DIRECTORIO" | md5sum | cut -d' ' -f1).pid" 
} #El hash del directorio evita colisiones si se monitorean múltiples directorios.

# Verifica si el daemon está corriendo: devuelve su PID o vacío si no existe
pid_en_ejecucion() {
  local archivo_pid; archivo_pid="$(obtener_archivo_pid)"
  [[ -f "$archivo_pid" ]] || return 0          # no existe el archivo PID → no hay daemon
  local pid; pid="$(cat "$archivo_pid")"
  if kill -0 "$pid" 2>/dev/null; then #kill -0 --> este proceso sigue vivo?
    echo "$pid"                               
  else
    rm -f "$archivo_pid"                        
  fi
}

# revisa que inotifywait este instalado
verificar_dependencias() {
  local -a faltantes=()
=======
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
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
  for cmd in grep inotifywait; do
    command -v "$cmd" &>/dev/null || faltantes+=("$cmd")
  done
<<<<<<< HEAD
  if ((${#faltantes[@]})); then
    log_error "Dependencias faltantes: ${faltantes[*]}"
    [[ " ${faltantes[*]} " == *" inotifywait "* ]] && \
      log_error "Instalar inotify-tools: sudo apt install inotify-tools"
=======
  if ((${#missing[@]})); then
    log_error "Dependencias faltantes: ${missing[*]}"
    [[ " ${missing[*]} " == *" inotifywait "* ]] && \
      log_error "Instalá inotify-tools con: sudo apt install inotify-tools"
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
    exit 1
  fi
}

<<<<<<< HEAD
escribir_linea_log() {
  printf '%s\n' "$1" >> "$ARCHIVO_LOG"
}
obtener_tamanio_archivo() {
  stat -c%s "$1" 2>/dev/null || echo "?"
}

declare -a PALABRAS=()

# Busca las palabras clave dentro de un archivo y si las encuentra registra la coincidencia en el log
escanear_archivo() {
  local ruta_archivo="$1" operacion="$2"
  [[ -f "$ruta_archivo" ]] || return 0
  LC_ALL=C grep -Iq . -- "$ruta_archivo" 2>/dev/null || return 0
  local tamanio; tamanio="$(obtener_tamanio_archivo "$ruta_archivo")"
  local palabra
  for palabra in "${PALABRAS[@]}"; do
    [[ -z "$palabra" ]] && continue
    if LC_ALL=C grep -qi -- "$palabra" "$ruta_archivo" 2>/dev/null; then
      escribir_linea_log "$(printf "[%s] Operación: %-10s | Archivo: '%s' | Palabra: '%s' | Tamaño: %s bytes" \
        "$(time_stamp)" "$operacion" "$ruta_archivo" "$palabra" "$tamanio")"
=======
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
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
    fi
  done
}

<<<<<<< HEAD
# Escanea los archivos que ya estaban en el directorio al momento de iniciar el daemon
escanear_archivos_existentes() {
  local cantidad=0
  escribir_linea_log "[$(time_stamp)] Procesando archivos existentes en '$DIRECTORIO' ..."
  while IFS= read -r -d '' archivo; do
    escanear_archivo "$archivo" "EXISTENTE"
    cantidad=$(( cantidad + 1 ))
=======
# Procesa los archivos que ya estaban en el directorio al arrancar el demonio
scan_existing_files() {
  local count=0
  log_line "[$(timestamp)] Procesando archivos existentes en '$DIRECTORIO' ..."
  while IFS= read -r -d '' f; do
    scan_file "$f" "EXISTENTE"
    count=$(( count + 1 ))
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
  done < <(find "$DIRECTORIO" -maxdepth 1 -type f -print0 2>/dev/null)
  escribir_linea_log "[$(time_stamp)] $cantidad archivos existentes procesados."
}

<<<<<<< HEAD
# Recibe el evento de inotify, extrae la operación y la ruta del archivo afectado, y lo manda a escanear.
procesar_evento_inotify() {
  local linea="$1"
  local operacion ruta_archivo
  operacion="$(awk '{print $1}' <<< "$linea")"
  ruta_archivo="$(awk '{$1=""; print substr($0,2)}' <<< "$linea")"
  escanear_archivo "$ruta_archivo" "$operacion"
}

# Bucle infinito que espera eventos de inotify y los procesa uno a uno
bucle_daemon() {
  escribir_linea_log "$(printf "[%s] Demonio iniciado | Directorio: '%s' | Palabras: %s" \
    "$(time_stamp)" "$DIRECTORIO" "${PALABRAS[*]}")"
  escanear_archivos_existentes
  while IFS= read -r linea; do
    procesar_evento_inotify "$linea"
  done < <(inotifywait -m -e close_write,moved_to \
             --format '%e %w%f' "$DIRECTORIO" 2>/dev/null)
}
# Parseo de argumentos
DIRECTORIO=""; PALABRAS_STR=""; ARCHIVO_LOG=""; MODO_KILL=0
=======
# Extrae operación y ruta del evento inotify y los manda a scan_file
# Función separada para poder usar 'local' (solo válido dentro de funciones, no en while)
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
  # Con pipe, el while corre en un subshell hijo y ps mostraría dos procesos demonio
  while IFS= read -r line; do
    process_inotify_event "$line"
  done < <(inotifywait -m -e close_write,moved_to \
             --format '%e %w%f' "$DIRECTORIO" 2>/dev/null)
}

# =============================================================================
# PARSEO DE ARGUMENTOS
# =============================================================================

DIRECTORIO=""; PALABRAS_STR=""; LOGFILE=""; KILL_MODE=0
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--directorio)     DIRECTORIO="$(ruta_absoluta "${2:-}")"; shift 2;;
    -p|--palabras)       PALABRAS_STR="${2:-}"; shift 2;;
    -l|--log)            ARCHIVO_LOG="$(ruta_absoluta "${2:-}")"; shift 2;;
    -k|--kill)           MODO_KILL=1; shift;;
    -h|--help)           mostrar_ayuda; exit 0;;
    --)                  shift; break;;
    -*)                  log_error "Flag desconocido: $1"; exit 1;;
    *)                   log_error "Argumento no reconocido: $1"; exit 1;;
  esac
done

<<<<<<< HEAD
# Validacion de los argumentos
if (( MODO_KILL )); then
  [[ -z "$DIRECTORIO" ]] && \
    { log_error "Con -k/--kill debe indicar -d/--directorio"; exit 1; }
  [[ -n "${PALABRAS_STR:-}" || -n "${ARCHIVO_LOG:-}" ]] && \
=======
# =============================================================================
# VALIDACIONES
# =============================================================================

if (( KILL_MODE )); then
  [[ -z "$DIRECTORIO" ]] && { log_error "Con -k/--kill tenés que indicar -d/--directorio"; exit 1; }
  [[ -n "${PALABRAS_STR:-}" || -n "${LOGFILE:-}" ]] && \
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
    { log_error "Con -k/--kill solo se permite -d/--directorio"; exit 1; }
else
  [[ -z "$DIRECTORIO" ]]   \
    && { log_error "Falta -d/--directorio"; exit 1; }
  [[ -z "$PALABRAS_STR" ]] \
    && { log_error "Falta --palabras"; exit 1; }
  [[ -z "$ARCHIVO_LOG" ]]  \
    && { log_error "Falta -l/--log"; exit 1; }
fi

[[ -d "$DIRECTORIO" ]] || { log_error "El directorio '$DIRECTORIO' no existe"; exit 1; }

<<<<<<< HEAD
# Parsear palabras pasadas por parametro
=======
# Parsear palabras clave y sacar espacios sobrantes
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
IFS=',' read -ra PALABRAS <<< "$PALABRAS_STR"
for i in "${!PALABRAS[@]}"; do
  PALABRAS[$i]="$(echo "${PALABRAS[$i]}" | xargs)"
done

<<<<<<< HEAD
# Matar Demonio
if (( MODO_KILL )); then
  pid="$(pid_en_ejecucion)"
  if [[ -z "$pid" ]]; then
    log_warning "No hay daemon corriendo para '$DIRECTORIO'."
    exit 1
  fi
  kill -TERM "$pid" 2>/dev/null || true #intenta hacer un sigterm
  sleep 1 # si en 1 segundo no murio
  kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true # mata a la fuerza con SIGKILL
  rm -f "$(obtener_archivo_pid)"
  log_info "Daemon detenido (PID: $pid)."
  exit 0
fi

# Modo daemon (hijo relanzado por nohup)
# Es una señal que el padre le manda al hijo para que sepa que 
# ya es el proceso en segundo plano y no vuelva a lanzar otro hijo.
if [[ "${DAEMON_MODE:-0}" == "1" ]]; then
  trap 'rm -f "$(obtener_archivo_pid)"' EXIT  
  bucle_daemon
  exit 0
fi

# Preparar log 
mkdir -p -- "$(dirname -- "$ARCHIVO_LOG")" 2>/dev/null || true
: > "$ARCHIVO_LOG" 2>/dev/null || { log_error "No puedo escribir en '$ARCHIVO_LOG'"; exit 1; }
=======
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
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)

verificar_dependencias

<<<<<<< HEAD
# Prevenir demonios duplicados
pid="$(pid_en_ejecucion)"
=======
pid="$(running_pid)"
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
if [[ -n "$pid" ]]; then
  log_error "Ya hay un demonio para este directorio (PID: $pid)."; exit 1
fi

<<<<<<< HEAD
#Lanza el daemon en segundo plano y guarda su PID para poder matarlo después.
=======
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
nohup env DAEMON_MODE=1 "$0" \
 -d "$DIRECTORIO" --palabras "$PALABRAS_STR" -l "$ARCHIVO_LOG" \
  >/dev/null 2>&1 &
pid_hijo=$! #obtiene el pid del ultimo proceso lanzado
echo "$pid_hijo" > "$(obtener_archivo_pid)"

<<<<<<< HEAD
log_info "Daemon iniciado en segundo plano (PID: $pid_hijo)."
=======
log_info "Demonio iniciado en segundo plano (PID: $child_pid)."
>>>>>>> b3c0620 (modificaciones de comentarios en codigo)
