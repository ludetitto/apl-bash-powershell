#!/bin/bash

# =============================================================================
# Ejercicio 3 - Detección de archivos duplicados
# Materia: Virtualización de Hardware (3654) - UNLaM 2026
# Integrantes:
#   - Francisco, Vladimir
#   - Nombre Apellido
#   - Nombre Apellido
#   - Nombre Apellido
#   - Nombre Apellido
# =============================================================================

mostrar_ayuda() {
    echo "Uso: $0 -d <directorio> [opciones]"
    echo ""
    echo "Descripción:"
    echo "  Detecta archivos duplicados (mismo nombre y tamaño) dentro de un"
    echo "  directorio y sus subdirectorios."
    echo ""
    echo "Parámetros:"
    echo "  -d, --directorio  Ruta del directorio a analizar (obligatorio)"
    echo "  -h, --help        Muestra esta ayuda"
    echo ""
    echo "Ejemplo:"
    echo "  $0 --directorio /home/usuario/documentos"
}

# Directorio temporal de trabajo
DIR_TEMP=$(mktemp -d /tmp/ejercicio3.XXXXXX)

# Función de limpieza
limpiar() {
    rm -rf "$DIR_TEMP"
}

# Trap para cualquier situación de salida
trap limpiar EXIT INT TERM

# Parseamos los argumentos
ARGS=$(getopt -o d:h --long directorio:,help -n "$0" -- "$@")

if [ $? -ne 0 ]; then
    echo "Error: parámetros inválidos. Usá $0 --help para ver la ayuda."
    exit 1
fi

eval set -- "$ARGS"

directorio=""

while true; do
    case "$1" in
        -d | --directorio)
            directorio="$2"
            shift 2
            ;;
        -h | --help)
            mostrar_ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error inesperado al parsear parámetros."
            exit 1
            ;;
    esac
done

# Validaciones
if [ -z "$directorio" ]; then
    echo "Error: el parámetro --directorio es obligatorio."
    echo "Usá $0 --help para ver la ayuda."
    exit 1
fi

if [ ! -d "$directorio" ]; then
    echo "Error: '$directorio' no es un directorio válido o no existe."
    exit 1
fi

if [ ! -r "$directorio" ]; then
    echo "Error: no tenés permisos de lectura sobre '$directorio'."
    exit 1
fi

buscar_duplicados() {
    declare -A tabla

    while IFS='|' read -r clave dir; do
        if [ -z "${tabla[$clave]}" ]; then
            tabla[$clave]="$dir"
        else
            tabla[$clave]="${tabla[$clave]}|$dir"
        fi
    done < <(find "$directorio" -type f -exec stat -c "%s %n" {} \; | awk '{
        tamanio = $1
        ruta = $2
        n = split(ruta, partes, "/")
        nombre = partes[n]
        dir = ""
        for (i = 1; i < n; i++) {
            dir = dir partes[i]
            if (i < n-1) dir = dir "/"
        }
        print nombre ":" tamanio "|" dir
    }')

    hay_duplicados=false

    for clave in "${!tabla[@]}"; do
        directorios="${tabla[$clave]}"
        cantidad=$(echo "$directorios" | tr -cd '|' | wc -c)

        if [ "$cantidad" -ge 1 ]; then
            hay_duplicados=true
            nombre=$(echo "$clave" | cut -d':' -f1)

            echo "archivo: $nombre"
            echo "$directorios" | tr '|' '\n' | while read -r dir; do
                echo "  directorio: $dir"
            done
            echo ""
        fi
    done

    if [ "$hay_duplicados" = false ]; then
        echo "No se encontraron archivos duplicados en '$directorio'."
    fi
}

buscar_duplicados

