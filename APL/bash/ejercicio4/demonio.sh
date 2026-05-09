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
#       Medina Ramiro                                   #
#                                                       #
#-------------------------------------------------------#

set -euo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'
registrar_error(){ echo -e "${RED}[ERROR]${NC} $*" >&2; }
registrar_info(){  echo -e "${GREEN}[INFO] ${NC}$*"; }
registrar_aviso(){  echo -e "${YELLOW}[AVISO] ${NC}$*"; }
marca_tiempo(){ date +"%Y-%m-%d %H:%M:%S"; }

show_help() {
  cat << EOF
Uso:
  Iniciar demonio
    $0 -d <directorio> --palabras <pal1,pal2,...> -l <archivo.log>

  Detener demonio
    $0 -d <directorio> -k

Descripción:
  Script demonio que monitorea un directorio en segundo plano y registra en un
  log cada vez que se crea o modifica un archivo que contenga alguna de las
  palabras clave indicadas.

Parámetros:
  -d, --directorio    Ruta del directorio a monitorear (obligatorio)
  -p, --palabras      Palabras clave separadas por comas (obligatorio)
  -l, --log           Ruta del archivo de log (obligatorio)
  -k, --kill          Detiene el demonio del directorio indicado
  -h, --help          Muestra esta ayuda

Reglas:
  - Para detener el demonio debe especificarse el directorio con -d y la flag -k, sin otros parámetros.

Ejemplos:
  mkdir descargas
  $0 -d descargas -p password,token,api_key -l monitoreo.log
  $0 -d descargas -p password,token,api_key -l monitoreo.log   # debe fallar: ya hay un daemon
  echo "mi password es 1234" > descargas/credenciales.txt
  cat monitoreo.log
  $0 -d descargas -k
EOF
}

# Convierte una ruta relativa a absoluta sin depender de realpath
ruta_absoluta() {
  local p="${1:-}"; [[ -z "$p" ]] && { echo ""; return 0; }
  if [[ "$p" = /* ]]; then echo "$p"; else
    local dir base; dir="$(dirname -- "$p")"; base="$(basename -- "$p")"
    (cd -- "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base") || printf '%s\n' "$p"
  fi
}

# Nombre del PID file: único por directorio usando un hash del path absoluto
ruta_archivo_pid() {
  echo "/tmp/demonio_$(echo -n "$DIRECTORIO" | md5sum | cut -d' ' -f1).pid"
}

ruta_archivo_estado() {
  echo "/tmp/demonio_$(echo -n "$DIRECTORIO" | md5sum | cut -d' ' -f1).timestamp"
}


# Devuelve el PID del demonio si está corriendo; si el PID file es huérfano lo limpia
pid_del_daemon_activo() {
  local pf; pf="$(ruta_archivo_pid)"
  [[ -f "$pf" ]] || return 0
  local pid; pid="$(cat "$pf")"
  if kill -0 "$pid" 2>/dev/null; then
    echo "$pid"
  else
    rm -f "$pf"
  fi
}

# Verifica si el log ya está siendo usado por otro demonio activo
verificar_log_disponible() {
  local registry="/tmp/demonio_logs.registry"
  [[ -f "$registry" ]] || return 0
  local linea pid logpath
  while IFS='|' read -r pid logpath; do
    [[ -z "$pid" || -z "$logpath" ]] && continue
    # Si el proceso ya no existe, ignorar esa entrada
    kill -0 "$pid" 2>/dev/null || continue
    if [[ "$logpath" == "$LOGFILE" ]]; then
      registrar_error "El archivo de log '$LOGFILE' ya está en uso por otro demonio (PID: $pid)."
      registrar_error "Cambiá el nombre o la ruta del log con -l/--log."
      exit 1
    fi
  done < "$registry"
}

# Registra el par PID|log en el registro global al lanzar un demonio
registrar_log_en_uso() {
  local pid="$1"
  printf '%s|%s\n' "$pid" "$LOGFILE" >> "/tmp/demonio_logs.registry"
}

# Elimina la entrada de este demonio del registro global al detenerse
liberar_log_en_uso() {
  local pid="$1"
  local registry="/tmp/demonio_logs.registry"
  [[ -f "$registry" ]] || return 0
  local tmp; tmp="$(mktemp)"
  grep -v "^${pid}|" "$registry" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$registry"
}

verificar_dependencias() {
  local -a missing=()
  for cmd in grep inotifywait; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  if ((${#missing[@]})); then
    registrar_error "Dependencias faltantes: ${missing[*]}"
    [[ " ${missing[*]} " == *" inotifywait "* ]] && \
      registrar_error "Instalá inotify-tools con: sudo apt install inotify-tools"
    exit 1
  fi
}

escribir_linea_log() {
  printf '%s\n' "$1" >> "$LOGFILE"
}

obtener_tamanio_en_bytes() {
  stat -c%s "$1" 2>/dev/null || echo "?"
}

# Busca las palabras clave en un archivo y registra cada coincidencia en el log
buscar_palabras_clave_en_archivo() {
  local filepath="$1" operacion="$2"
  [[ -f "$filepath" ]] || return 0
  LC_ALL=C grep -Iq . -- "$filepath" 2>/dev/null || return 0  # saltea binarios
  local size; size="$(obtener_tamanio_en_bytes "$filepath")"
  local pal
  for pal in "${PALABRAS[@]}"; do
    [[ -z "$pal" ]] && continue
    if LC_ALL=C grep -qi -- "$pal" "$filepath" 2>/dev/null; then
      escribir_linea_log "$(printf "[%s] Operación: %-10s | Archivo: '%s' | Palabra: '%s' | Tamaño: %s bytes" \
        "$(marca_tiempo)" "$operacion" "$filepath" "$pal" "$size")"
    fi
  done
}

# Procesa los archivos que ya estaban en el directorio al arrancar el demonio
escanear_archivos_preexistentes() {
  local count=0
  local timestamp_file; timestamp_file="$(ruta_archivo_estado)"
  local -a find_args=("$DIRECTORIO" -maxdepth 1 -type f)
  [[ -f "$timestamp_file" ]] && find_args+=(-newer "$timestamp_file")
  escribir_linea_log "[$(marca_tiempo)] Procesando archivos existentes en '$DIRECTORIO' ..."
  while IFS= read -r -d '' f; do
    buscar_palabras_clave_en_archivo "$f" "EXISTENTE"
    count=$(( count + 1 ))
  done < <(find "${find_args[@]}" -print0 2>/dev/null)
  escribir_linea_log "[$(marca_tiempo)] $count archivos existentes procesados."
}

# Extrae operación y ruta del evento inotify y los manda a buscar_palabras_clave_en_archivo
procesar_evento_inotify() {
  local line="$1"
  local op filepath
  op="$(awk '{print $1}' <<< "$line")"
  filepath="$(awk '{$1=""; print substr($0,2)}' <<< "$line")"
  buscar_palabras_clave_en_archivo "$filepath" "$op"
}

# Loop principal del demonio: primero escanea existentes, después escucha eventos nuevos
iniciar_bucle_de_monitoreo() {
  escribir_linea_log "$(printf "[%s] Demonio iniciado | Directorio: '%s' | Palabras: %s" \
    "$(marca_tiempo)" "$DIRECTORIO" "${PALABRAS[*]}")"

  escanear_archivos_preexistentes

  # < <(...) en lugar de pipe | para que el while quede en el proceso principal
  while IFS= read -r line; do
    procesar_evento_inotify "$line"
    touch "$(ruta_archivo_estado)"
  done < <(inotifywait -m -e close_write,moved_to \
             --format '%e %w%f' "$DIRECTORIO" 2>/dev/null)
}

# PARSEO DE ARGUMENTOS
DIRECTORIO=""; PALABRAS_STR=""; LOGFILE=""; KILL_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--directorio)     DIRECTORIO="$(ruta_absoluta "${2:-}")"; shift 2;;
    -p|--palabras)       PALABRAS_STR="${2:-}"; shift 2;;
    -l|--log)            LOGFILE="$(ruta_absoluta "${2:-}")"; shift 2;;
    -k|--kill)           KILL_MODE=1; shift;;
    -h|--help)           show_help; exit 0;;
    --)                  shift; break;;
    -*)                  registrar_error "Flag desconocido: $1"; exit 1;;
    *)                   registrar_error "Argumento no reconocido: $1"; exit 1;;
  esac
done

# VALIDACIONES
if (( KILL_MODE )); then
  [[ -z "$DIRECTORIO" ]] && { registrar_error "Con -k/--kill tenés que indicar -d/--directorio"; exit 1; }
  [[ -n "${PALABRAS_STR:-}" || -n "${LOGFILE:-}" ]] && \
    { registrar_error "Con -k/--kill solo se permite -d/--directorio"; exit 1; }
else
  [[ -z "$DIRECTORIO" ]]   \
    && { registrar_error "Falta -d/--directorio"; exit 1; }
  [[ -z "$PALABRAS_STR" ]] \
    && { registrar_error "Falta --palabras"; exit 1; }
  [[ -z "$LOGFILE" ]]  \
    && { registrar_error "Falta -l/--log"; exit 1; }
fi

[[ -d "$DIRECTORIO" ]] || { registrar_error "El directorio '$DIRECTORIO' no existe"; exit 1; }

# Parsear palabras clave y sacar espacios sobrantes
IFS=',' read -ra PALABRAS <<< "$PALABRAS_STR"
for i in "${!PALABRAS[@]}"; do
  PALABRAS[$i]="$(echo "${PALABRAS[$i]}" | xargs)"
done

#  matar el demonio
if (( KILL_MODE )); then
  pid="$(pid_del_daemon_activo)"
  if [[ -z "$pid" ]]; then
    registrar_aviso "No hay demonio corriendo para '$DIRECTORIO'."
    exit 1
  fi
  kill -TERM "$pid" 2>/dev/null || true
  sleep 1
  kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
  rm -f "$(ruta_archivo_pid)" "$(ruta_archivo_estado)"
  registrar_info "Demonio detenido (PID: $pid)."
  exit 0
fi

# proceso demonio (relanzado por nohup con DAEMON_MODE=1) ---
if [[ "${DAEMON_MODE:-0}" == "1" ]]; then
  trap 'liberar_log_en_uso "$$"; rm -f "$(ruta_archivo_pid)" "$(ruta_archivo_estado)"' EXIT
  registrar_log_en_uso "$$"
  iniciar_bucle_de_monitoreo
  exit 0
fi

verificar_dependencias

# valida si ya hay un demonio corriendo
pid="$(pid_del_daemon_activo)"
if [[ -n "$pid" ]]; then
  registrar_error "Ya hay un demonio para este directorio (PID: $pid)."; exit 1
fi

# valida que el log no esté en uso por otro demonio
verificar_log_disponible

# crea el archivo de log
mkdir -p -- "$(dirname -- "$LOGFILE")" 2>/dev/null || true
: > "$LOGFILE" 2>/dev/null || { registrar_error "No puedo escribir en '$LOGFILE'"; exit 1; }

# se crea el demonio y guarda su pid
nohup env DAEMON_MODE=1 "$0" -d "$DIRECTORIO" --palabras "$PALABRAS_STR" -l "$LOGFILE" >/dev/null 2>&1 &
child_pid=$!
echo "$child_pid" > "$(ruta_archivo_pid)"

registrar_info "Demonio iniciado en segundo plano (PID: $child_pid)."
