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

# Ejemplo (parado en ~/):
#   cd ~/apl-bash-powershell/APL/bash/ejercicio4/
#   mkdir descargas
#   ./demonio.sh -d descargas -p password,token,api_key -l monitoreo.log
#   echo "mi password es 1234" > descargas/credenciales.txt
#   ./demonio.sh -d descargas -k
#   cat monitoreo.log
#   ps aux | grep demonio

set -euo pipefail # parametros de seguridad que hace que el script frene y muestre el error


ROJO=$'\033[0;31m'; VERDE=$'\033[0;32m'; AMARILLO=$'\033[1;33m'; SIN_COLOR=$'\033[0m'
registrar_error(){ echo -e "${ROJO}[ERROR]${SIN_COLOR} $*" >&2; }
registrar_info(){  echo -e "${VERDE}[INFO] ${SIN_COLOR}$*"; }
registrar_aviso(){ echo -e "${AMARILLO}[AVISO]${SIN_COLOR} $*"; }
marca_tiempo(){ date +"%Y-%m-%d %H:%M:%S"; }

# HELP
# Flags: -d/--directorio  -p/--palabras  -l/--log  -k/--kill  -h/--help
mostrar_ayuda() {
  cat <<'EOF'
Uso:
  Iniciar daemon (OBLIGATORIOS: -d --palabras -l):
    ./demonio.sh -d <directorio> --palabras <pal1,pal2,...> -l <archivo_log>

  Detener daemon (SOLO -d -k):
    ./demonio.sh -d <directorio> -k

Flags:
  -d, --directorio    Ruta del directorio a monitorear
  -p, --palabras      Palabras clave separadas por comas (ej: password,token,api_key)
  -l, --log           Ruta del archivo de log
  -k, --kill          Detiene el daemon del directorio indicado (solo con -d)
  -h, --help          Muestra esta ayuda

Ejemplos:
  ./demonio.sh -d ../descargas -p password,token,api_key -l log.txt
  ./demonio.sh -d ../descargas -k
EOF
}

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
  for cmd in grep inotifywait; do
    command -v "$cmd" &>/dev/null || faltantes+=("$cmd")
  done
  if ((${#faltantes[@]})); then
    log_error "Dependencias faltantes: ${faltantes[*]}"
    [[ " ${faltantes[*]} " == *" inotifywait "* ]] && \
      log_error "Instalar inotify-tools: sudo apt install inotify-tools"
    exit 1
  fi
}

print_log() {
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
      print_log "$(printf "[%s] Operación: %-10s | Archivo: '%s' | Palabra: '%s' | Tamaño: %s bytes" \
        "$(time_stamp)" "$operacion" "$ruta_archivo" "$palabra" "$tamanio")"
    fi
  done
}

# Escanea los archivos que ya estaban en el directorio al momento de iniciar el daemon
escanear_archivos_existentes() {
  local cantidad=0
  print_log "[$(time_stamp)] Procesando archivos existentes en '$DIRECTORIO' ..."
  while IFS= read -r -d '' archivo; do
    escanear_archivo "$archivo" "EXISTENTE"
    cantidad=$(( cantidad + 1 ))
  done < <(find "$DIRECTORIO" -maxdepth 1 -type f -print0 2>/dev/null)
  print_log "[$(time_stamp)] $cantidad archivos existentes procesados."
}

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
  print_log "$(printf "[%s] Demonio iniciado | Directorio: '%s' | Palabras: %s" \
    "$(time_stamp)" "$DIRECTORIO" "${PALABRAS[*]}")"
  escanear_archivos_existentes
  while IFS= read -r linea; do
    procesar_evento_inotify "$linea"
  done < <(inotifywait -m -e close_write,moved_to \
             --format '%e %w%f' "$DIRECTORIO" 2>/dev/null)
}
# Parseo de argumentos
DIRECTORIO=""; PALABRAS_STR=""; ARCHIVO_LOG=""; MODO_KILL=0

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

# Validacion de los argumentos
if (( MODO_KILL )); then
  [[ -z "$DIRECTORIO" ]] && \
    { log_error "Con -k/--kill debe indicar -d/--directorio"; exit 1; }
  [[ -n "${PALABRAS_STR:-}" || -n "${ARCHIVO_LOG:-}" ]] && \
    { log_error "Con -k/--kill solo se permite -d/--directorio"; exit 1; }
else
  [[ -z "$DIRECTORIO" ]]   \
    && { log_error "Falta -d/--directorio"; exit 1; }
  [[ -z "$PALABRAS_STR" ]] \
    && { log_error "Falta --palabras"; exit 1; }
  [[ -z "$ARCHIVO_LOG" ]]  \
    && { log_error "Falta -l/--log"; exit 1; }
fi

[[ -d "$DIRECTORIO" ]] || { log_error "El directorio no existe: '$DIRECTORIO'"; exit 1; }

# Parsear palabras pasadas por parametro
IFS=',' read -ra PALABRAS <<< "$PALABRAS_STR"
for i in "${!PALABRAS[@]}"; do
  PALABRAS[$i]="$(echo "${PALABRAS[$i]}" | xargs)"
done

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

verificar_dependencias

# Prevenir demonios duplicados
pid="$(pid_en_ejecucion)"
if [[ -n "$pid" ]]; then
  log_error "Ya hay un daemon para este directorio (PID: $pid)."; exit 1
fi

#Lanza el daemon en segundo plano y guarda su PID para poder matarlo después.
nohup env DAEMON_MODE=1 "$0" \
 -d "$DIRECTORIO" --palabras "$PALABRAS_STR" -l "$ARCHIVO_LOG" \
  >/dev/null 2>&1 &
pid_hijo=$! #obtiene el pid del ultimo proceso lanzado
echo "$pid_hijo" > "$(obtener_archivo_pid)"

log_info "Daemon iniciado en segundo plano (PID: $pid_hijo)."
