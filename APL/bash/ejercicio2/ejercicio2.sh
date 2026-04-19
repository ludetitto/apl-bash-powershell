#!/bin/sh

normalizar(){
	texto="$1"
	texto=$(echo "$texto" | tr '[:upper:]' '[:lower:]')
	echo "$texto"
}

if [ "$#" -ne 1 ]; then
	echo "No uso 1 parametro"
	exit 1
fi

ARCHIVO=$1

if [ ! -f "$ARCHIVO" ]; then
	echo "No se paso un archivo"
	exit 1
fi

while read -r linea
do
	normalizada=$(normalizar "$linea")
	echo "$normalizada"
	echo "$linea"
done < "$ARCHIVO"
