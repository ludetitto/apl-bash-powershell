#!/bin/sh

normalizar(){
	archivo="$1"
	sed -E '
	s/ +/ /g;
	s/^ //;
	s/ $//;
	s/ ([.,;.?!])/\1/g;
	s/\.{4,}/.../g;
	' "$archivo"
}

# 1. Validar cantidad de parámetros
if [ "$#" -ne 1 ]; then
        echo "Uso: $0 <archivo>"
        exit 1
fi

ARCHIVO=$1

# 2. Validar que el archivo exista
if [ ! -f "$ARCHIVO" ]; then
        echo "Error: El archivo '$ARCHIVO' no existe."
        exit 1
fi

# 3. Llamar a la función
normalizar "$ARCHIVO"
