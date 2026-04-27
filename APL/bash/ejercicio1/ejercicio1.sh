#!/usr/bin/env bash

mostrar_ayuda() {
  cat << EOF
Uso:
  $0 -a archivo.csv [opciones]

Descripción:
  Script para procesar archivos CSV, permitiendo filtrar registros,
  contar filas o sumar valores de una columna.

Parámetros:
  -a, --archivo   Archivo CSV de entrada (obligatorio)
  -f, --filtro    Nombre del campo para filtrar (opcional)
  -b, --buscar    Valor a buscar en el campo filtro (requerido si se usa -f)
  -c, --contar    Cuenta la cantidad de registros
  -s, --sumar     Suma los valores de un campo numérico
  -h, --help      Muestra esta ayuda

Reglas:
  - Debe indicar -c o -s (no ambos)
  - -b requiere -f
  - El filtro es opcional
  - Los nombres de columnas o valores pueden ser escritos tanto en minusculas como en mayusculas

Ejemplos:
  $0 -a censo.csv -c
  $0 -a censo.csv -f Ciudad -b "San" -c
  $0 -a clientes.csv -f Apellido -b "Perez" -s Saldo

EOF

}

archivo=""
campo_filtro=""
valor_buscar=""
campo_sumar=""
modo_contar=false

# Obtencion de parametros
while [[ $# -gt 0 ]]; do
  case "$1" in
	-h|--help)
	  mostrar_ayuda
	  exit 0 ;;
    -a|--archivo)
	  if [[ -z "$2" || "$2" == -* ]]; then
		echo "Error: -a requiere un archivo"
		exit 1
	  fi
	  archivo="$2"
	  shift 2 ;;
    -f|--filtro)
	  if [[ -z "$2" || "$2" == -* ]]; then
		echo "Error: si usa -f debe especificar la columna"
		exit 1
	  fi
	  campo_filtro="$2"
	  shift 2 ;;
    -b|--buscar)
	  if [[ -z "$2" || "$2" == -* ]]; then
		echo "Error: si usa -b debe especificar que desea buscar"
		exit 1
	  fi
	  valor_buscar="$2"
	  shift 2 ;;
    -s|--sumar)
	  if [[ -z "$2" || "$2" == -* ]]; then
		echo "Error: si usa -s debe especificar sobre que campo sumar"
		exit 1
	  fi
	  campo_sumar="$2"
	  shift 2 ;;
    -c|--contar)
	  if [[ "$modo_contar" == true ]]; then
        echo "Error: -c ya fue especificado"
		exit 1
      fi
	  modo_contar=true
	  shift ;;
    *) echo "Error: parametro desconocido -> $1"; exit 1 ;;
  esac
done

# Validaciones basicas
if [[ -z "$archivo" ]]; then
  echo "Error: Debe indicar archivo con -a"
  exit 1
fi

if [[ ! -f "$archivo" ]]; then
  echo "Error: el archivo no existe"
  exit 1
fi

if [[ "$archivo" != *.csv ]]; then
  echo "Error: el archivo debe tener extensión .csv"
  exit 1
fi

if [[ "$modo_contar" = true && -n "$campo_sumar" ]]; then
  echo "Error: no se puede usar -c y -s juntos"
  exit 1
fi

if [[ "$modo_contar" = false && -z "$campo_sumar" ]]; then
  echo "Error: debe usar -c o -s"
  exit 1
fi

if [[ -n "$campo_filtro" && -z "$valor_buscar" ]]; then
  echo "Error: si usa -f debe usar -b"
  exit 1
fi

if [[ -n "$valor_buscar" && -z "$campo_filtro" ]]; then
  echo "Error: -b requiere -f"
  exit 1
fi


# Operaciones del script
awk -F',' \
-v filtro="$campo_filtro" \
-v buscar="$valor_buscar" \
-v sumar="$campo_sumar" \
-v contar="$modo_contar" '

BEGIN {
  IGNORECASE = 1
  filtro = tolower(filtro)
  sumar = tolower(sumar)
  error_flag = 0
}

NR==1 {
  for (i=1; i<=NF; i++) {
    headers[tolower($i)] = i
  }

  # Validar columnas una sola vez
  if (filtro != "" && !(filtro in headers)) {
    print "Error: campo de filtro no existe"
    exit 1
  }

  if (sumar != "" && !(sumar in headers)) {
    print "Error: campo de suma no existe"
    exit 1
  }

  next
}

{
  # Aplicar filtro
  if (filtro != "") {
    if (tolower($headers[filtro]) !~ tolower(buscar)) {
      next
    }
  }

  if (contar == "true") {
    c++
  } else {
	valor = $headers[sumar]
	
	# validar que sea número (entero o decimal)
	if (valor !~ /^-?[0-9]+(\.[0-9]+)?$/) {
		printf "\nError: el campo %c%s%c contiene valores no numéricos.\n\n", 39, sumar, 39
		error_flag = 1
		exit 1
	}
    s += valor
    c++
  }
}

END {
  if(error_flag) {
    exit 1
  }
  
  print "\n\n-----------------------------"

  if (filtro != "") {
    printf "Filtro aplicado: %c%s%c = %c%s%c\n", 39, filtro, 39, 39, buscar, 39
  } else {
    print "Filtro aplicado: ninguno\n"
  }

  if (contar == "true") {
    if (c == 0) {
      print "Resultados:\nNo se encontraron registros"
    } else {
		if (filtro != "") {
		  printf "Resultados:\nCantidad de registros = %d\n", c
		}
    }
  } else {
    if (c == 0) {
      print "Resultado: no se encontraron registros para sumar"
    } else {
      printf  "Resultado: suma total = %.2f\n", s
    }
  }

  print "-----------------------------\n\n"
}
' "$archivo"
