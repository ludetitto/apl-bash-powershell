#!/bin/sh

normalizar(){
	archivo="$1"
	sed -E '
	s/ +/ /g;
	s/^ //;
	s/ ([.,;.?!])/\1/g;
	s/\.{4,}/.../g;

	#Reemplazo los puntos suspensivos por cualquier cosa para que en el agregado de espacio final no moleste
	s/\.{3,}/__PUNTOS_SUSPENSIVOS__/g;
	#esto es porque sed no soporta lookbehind como el replace de power, entonces si queda como estas? donde estas?
        #repite hasta terminar de ponerle el signo a todos
	:ciclo
        s/(^|[,.;:!¡?]+[ \t]*)([^¿?.,;:!¡ \t][^¿?.,;:!¡]*)\?/\1¿\2?/g
        s/(^|[,.;:!¿?]+[ \t]*)([^¡!.,;:?¿ \t][^¡!.,;:?¿]*)!/\1¡\2!/g
        # Si alguno de los comandos de arriba hizo un cambio, "t" salta a "ciclo" otra vez
        t ciclo

	s/([,?!.]) */\1 /g;
	s/__PUNTOS_SUSPENSIVOS__ */... /g;
	s/'"'"'/"/g;
	s/ $//;
	' "$archivo" |
	awk 'BEGIN { RS = ""; ORS = "\n\n" }
	{
	    #Limpio espacios o saltos de línea al final
	    sub(/[ \t\n]+$/, "")

	    #Si encuentra un "¡" y ningun "!" después de él
	    if ($0 ~ /¡[^!]*$/) {
	        sub(/[.!?]*$/, "")  # Borra el punto o error que haya al final
	        $0 = $0 "!"         # Le pone la exclamación
	    }
	    #Si encuentra un "¿" y ningun "?" después de él
	    else if ($0 ~ /¿[^?]*$/) {
	        sub(/[.!?]*$/, "")  
	        $0 = $0 "?"
	    }
	    #Si todo estaba bien cerrado, verifico que tenga punto final
	    else if ($0 !~ /[.!?]$/ && length($0) > 0) {
	        $0 = $0 "."
	    }

	    print $0
	}' | 
	awk 'BEGIN { 
      	    mayus = 1 
	}
	{
	    linea = ""
	    if (length($0) == 0) {
	        mayus = 1
	        print ""
	        next
	    }
	    for (i = 1; i <= length($0); i++) {
	        c = substr($0, i, 1)
	        if (mayus == 1 && c ~ /[a-zA-ZáéíóúÁÉÍÓÚñÑ]/) {
	            linea = linea toupper(c)
	            mayus = 0
	        } 
	        else {
	            linea = linea c
	            if (c ~ /[.!?]/) {
	                mayus = 1
	            }
	        }
	    }
	    print linea
	}'
}

ARCHIVO=""
SALIDA=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -a|--archivo)
            ARCHIVO="$2"
            shift 2
            ;;
        -s|--salida)
            SALIDA="$2"
            shift 2
            ;;
        *)
            echo "Uso: $0 -a <archivo_entrada> [-s <archivo_salida>]"
            exit 1
            ;;
    esac
done

# Validar que el archivo de entrada se haya pasado
if [ -z "$ARCHIVO" ]; then
    echo "Uso: $0 -a <archivo_entrada> [-s <archivo_salida>]"
    exit 1
fi

# Validar que el archivo de entrada exista
if [ ! -f "$ARCHIVO" ]; then
    echo "Error: El archivo '$ARCHIVO' no existe."
    exit 1
fi

# Condición de salida por pantalla o guardado en archivo
if [ -z "$SALIDA" ]; then
    normalizar "$ARCHIVO"
else
    # Si pasaron el parámetro de salida, redirigimos la función al archivo
    normalizar "$ARCHIVO" > "$SALIDA"
    echo -e "Proceso completado. Texto guardado en '$SALIDA'"
fi
