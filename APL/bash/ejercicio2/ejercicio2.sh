#!/bin/sh

normalizar(){
	archivo="$1"
	sed -E '
	s/ +/ /g;
	s/^ //;
	s/ $//;
	s/ ([.,;.?!])/\1/g;
	s/\.{4,}/.../g;
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
	}' > texto_corregido.txt	
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
