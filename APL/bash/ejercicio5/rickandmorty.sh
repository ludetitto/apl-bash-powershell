#!/usr/bin/env bash
#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 5                                    #
#                                                       #
#   Integrantes:                                        #
#       Vignardel Francisco                             #
#       De Titto Lucia                                  #
#       Gallardo Samuel                                 #
#       Francisco Vladimir                              #
#       Medina Ramiro                                   #
#                                                       #
#-------------------------------------------------------#

# Declaracion de parametros globales
ID=""
NOMBRE=""
CLEAR=false

# Establecer un trap para eliminar los archivos temporales al salir del script
trap "rm -f \"/tmp/rickandmorty_$$.txt\" \"/tmp/rickandmorty_separated_$$.txt\"" EXIT

# Funcion para mostrar el help con formato similar a man page
mostrar_ayuda() {
  cat << EOF
Uso:
    $0 [opciones]

Descripcion:
    Consulta la API de Rick and Morty para obtener informacion sobre personajes.
    Los datos se cachean localmente en el directorio actual para optimizar las consultas posteriores.

Parámetros:
    -i, --id        ID/s de los personajes a buscar.
    -n, --nombre    Nombre/s de los personajes a buscar.
    -c, --clear     Limpia el cache de personajes guardado.
    -h, --help      Muestra este mensaje de ayuda.

Reglas:
    - Se pueden buscar multiples personajes a la vez separando los IDs o nombres con comas.
    - Los nombres no son sensibles a mayusculas/minusculas y pueden contener espacios.
    - Si se especifica -c/--clear, no se pueden usar opciones de busqueda (-i, -n, --id, --nombre).
    - El archivo de cache se llama 'characters_cache.txt' y el log de consultas a la API se llama 'api_tracking.log', ambos ubicados en el directorio actual.

Ejemplos:
    Busqueda por ID
      $0 -i 1
      $0 --id "1,2,3"

    Busqueda por nombre
      $0 -n rick
      $0 --nombre "rick,morty"

    Busqueda combinada
      $0 -i 1 -n rick

    Limpiar cache
      $0 --clear

EOF
}

# Funcion para validar los parametros de entrada
validar_parametros() {
  if [[ $# -eq 0 ]]; then
    echo "No se han proporcionado argumentos. Use --help para ver las opciones disponibles."
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--id)
        ID="${2:-}"
        shift 2
        ;;
      --id=*)
        ID="${1#*=}"
        shift
        ;;
      -n|--nombre)
        NOMBRE="${2:-}"
        shift 2
        ;;
      --nombre=*)
        NOMBRE="${1#*=}"
        shift
        ;;
      -c|--clear)
        CLEAR=true
        shift
        ;;
      -h|--help)
        mostrar_ayuda
        exit 0
        ;;
      *)
        echo "Parametro no reconocido: $1"
        echo "Use --help para ver las opciones disponibles."
        exit 1
        ;;
    esac
  done

  # Validar que --clear no se use con opciones de busqueda
  if [[ "$CLEAR" == true ]] && ([[ -n "$ID" ]] || [[ -n "$NOMBRE" ]]); then
    echo "Error: -c/--clear no puede utilizarse junto con opciones de busqueda (-i, -n, --id, --nombre)"
    exit 1
  fi
  
  # Validar que ID contenga solo numeros y/o comas
  if [[ -n "$ID" ]] && ! [[ "$ID" =~ ^[0-9,]+$ ]]; then
    echo "Error: El ID debe contener solo numeros y/o comas. Ejemplo: 1,2,3"
    exit 1
  fi
  
  # Validar que no haya comas dobles ni al inicio/final
  if [[ -n "$ID" ]] && [[ "$ID" =~ ,, ]]; then
    echo "Error: No se permiten comas dobles en el ID."
    exit 1
  fi
  
  if [[ -n "$ID" ]] && [[ "$ID" =~ ^, ]] || [[ "$ID" =~ ,$ ]]; then
    echo "Error: El ID no puede comenzar ni terminar con coma."
    exit 1
  fi
}

# Funcion para crear los archivos necesarios
crear_recursos() {
  touch 'characters_cache.txt'
  if ! grep -qx "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" characters_cache.txt; then
    echo "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" > 'characters_cache.txt'
  fi
  touch 'api_tracking.log'
}

# Funcion para mostrar la informacion de un personaje
mostrar_personaje() {
    local ID="$1" NOMBRE="$2" STATUS="$3" SPECIES="$4" GENDER="$5" ORIGIN="$6" LOCATION="$7" EPISODES="$8"
    printf "\nCharacter info:\n    Id: %s\n    Name: %s\n    Status: %s\n    Species: %s\n    Gender: %s\n    Origin: %s\n    Location: %s\n    Episodes: %s\n" "$ID" "$NOMBRE" "$STATUS" "$SPECIES" "$GENDER" "$ORIGIN" "$LOCATION" "$EPISODES"
}

# Funcion para buscar personajes en la cache por ID
buscar_por_id() {
    local VALOR="$1"
    grep "^${VALOR}|" characters_cache.txt | while IFS='|' read -r CID NAME STATUS SPECIES GENDER ORIGIN LOCATION EPISODES; do
      [[ -z "$CID" ]] || [[ "$CID" == "ID" ]] && continue
      mostrar_personaje "$CID" "$NAME" "$STATUS" "$SPECIES" "$GENDER" "$ORIGIN" "$LOCATION" "$EPISODES"
    done
}

# Funcion para buscar personajes en la cache por nombre
buscar_por_nombre() {
  local VALOR="$1"
  awk -F'|' -v q="$VALOR" '
  BEGIN { q=tolower(q) }
  NR==1 { next }
  index(tolower($2), q) > 0 {
    print $0
  }
' characters_cache.txt | while IFS='|' read -r CID NAME STATUS SPECIES GENDER ORIGIN LOCATION EPISODES; do
    mostrar_personaje "$CID" "$NAME" "$STATUS" "$SPECIES" "$GENDER" "$ORIGIN" "$LOCATION" "$EPISODES"
  done
}

# Funcion para validar la respuesta de la API
validar_response() {
  local response="$1"
  local http_code="$2"
  
  # Si no hay http_code, significa error de conexión
  if [[ -z "$http_code" ]] || [[ "$http_code" == "000" ]]; then
    echo "Error: No se pudo conectar a la API. Verifique su conexion a internet."
    return 1
  fi
  
  # Validar HTTP status codes
  if [[ $http_code -eq 404 ]]; then
    echo "Error: No se encontraron personajes que coincidan con la consulta."
    return 1
  fi
  
  if [[ $http_code -ge 500 ]]; then
    echo "Error: La API del servidor no está disponible (HTTP $http_code)."
    return 1
  fi
  
  if [[ $http_code -ne 200 ]]; then
    echo "Error: La API devolvió un error HTTP $http_code."
    return 1
  fi
  
  # Validar respuesta vacía
  if [[ -z "$response" ]]; then
    echo "Error: La API no devolvió respuesta."
    return 1
  fi
  
  # Validar si contiene error JSON
  if echo "$response" | grep -q '"error":'; then
    echo "Error: No se encontraron resultados."
    return 1
  fi
  
  return 0
}

# Funcion para obtener personajes por ID
obtener_personajes_por_id() {
    IFS=',' read -ra IDS <<< "$ID"
    RESPONSE=""

    IDS_A_PEDIR=()
    
    for ID_ITEM in "${IDS[@]}"; do
      if grep -q "^${ID_ITEM}|" characters_cache.txt; then
        buscar_por_id "$ID_ITEM"
      else
        IDS_A_PEDIR+=("$ID_ITEM")
      fi
    done

    if [[ ${#IDS_A_PEDIR[@]} -gt 0 ]]; then
      IDS_QUERY=$(IFS=,; echo "${IDS_A_PEDIR[*]}")
      
      # Capturar respuesta y HTTP code
      RESPONSE=$(curl -w "\n%{HTTP_CODE}" -fsS "https://rickandmortyapi.com/api/character/$IDS_QUERY" 2>/dev/null)
      HTTP_CODE=$(echo "$RESPONSE" | tail -1)
      RESPONSE=$(echo "$RESPONSE" | head -n -1)
      
      if ! validar_response "$RESPONSE" "$HTTP_CODE"; then
        return 1
      fi
      
      echo "$RESPONSE" > "/tmp/rickandmorty_$$.txt"

    fi
    return 0
}

# Funcion para obtener personajes por nombre
obtener_personajes_por_nombre() {
    NOMBRES_A_PEDIR=()
    NOMBRE_CLEAN=${NOMBRE//[[:space:]]/}
    IFS=',' read -ra NOMBRES <<< "$NOMBRE_CLEAN"
    RESPONSE=""

    for NOMBRE_ITEM in "${NOMBRES[@]}"; do
      [[ -z "$NOMBRE_ITEM" ]] && continue
      
      if grep -q "NOMBRE:$NOMBRE_ITEM" api_tracking.log; then
        buscar_por_nombre "$NOMBRE_ITEM"
      else
        NOMBRES_A_PEDIR+=("$NOMBRE_ITEM")
      fi
    done
      
    for NOMBRE_ITEM in "${NOMBRES_A_PEDIR[@]}"; do
      # Capturar respuesta y HTTP code
      RESPONSE=$(curl -w "\n%{HTTP_CODE}" -fsS "https://rickandmortyapi.com/api/character/?name=$NOMBRE_ITEM" 2>/dev/null)
      HTTP_CODE=$(echo "$RESPONSE" | tail -1)
      RESPONSE=$(echo "$RESPONSE" | head -n -1)

      if ! validar_response "$RESPONSE" "$HTTP_CODE"; then
        return 1
      fi

      echo "$RESPONSE" > "/tmp/rickandmorty_$$.txt"
      
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] NOMBRE:$NOMBRE_ITEM" >> api_tracking.log
    done

    return 0
}

# Funcion para parsear un campo especifico de un objeto JSON
parsear_campo() {
  local JSON="$1" CAMPO="$2"
    case "$CAMPO" in
        id) echo "$JSON" | sed -n 's/.*"id":\([0-9]*\).*/\1/p' ;;
        name) echo "$JSON" | sed -n 's/.*"id":[0-9]*,"name":"\([^"]*\)".*/\1/p' ;;
        status) echo "$JSON" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p' ;;
        species) echo "$JSON" | sed -n 's/.*"species":"\([^"]*\)".*/\1/p' ;;
        gender) echo "$JSON" | sed -n 's/.*"gender":"\([^"]*\)".*/\1/p' ;;
        origin) echo "$JSON" | sed -n 's/.*"origin":{"name":"\([^"]*\)".*/\1/p' ;;
        location) echo "$JSON" | sed -n 's/.*"location":{"name":"\([^"]*\)".*/\1/p' ;;
        episodes) echo "$JSON" | grep -o 'https://rickandmortyapi.com/api/episode/[0-9]\+' | wc -l ;;
        *) echo "" ;;
    esac
}

# Funcion para separar objetos JSON en lineas individuales
separar_objetos_json() {
    local INPUT_FILE="$1" OUTPUT_FILE="$2"
    awk 'BEGIN{RS="},{"}
  {
    gsub(/^\[/, ""); gsub(/\]$/, ""); gsub(/^{/, ""); gsub(/}$/, ""); gsub(/^ +/, ""); gsub(/ +$/, "")
    if (NF > 0) {
      print "{" $0 "}"
    }
  }' "$INPUT_FILE" > "$OUTPUT_FILE"
}

# Funcion para parsear la respuesta de la API
parsear_respuesta() {
  if [[ -s /tmp/rickandmorty_$$.txt ]]; then
    separar_objetos_json /tmp/rickandmorty_$$.txt /tmp/rickandmorty_separated_$$.txt

    while IFS= read -r JSON_LINE; do
      [[ -z "$JSON_LINE" ]] && continue 
    
      CID=$(parsear_campo "$JSON_LINE" "id")
      NAME=$(parsear_campo "$JSON_LINE" "name")
      STATUS=$(parsear_campo "$JSON_LINE" "status")
      SPECIES=$(parsear_campo "$JSON_LINE" "species")
      GENDER=$(parsear_campo "$JSON_LINE" "gender")
      ORIGIN=$(parsear_campo "$JSON_LINE" "origin")
      LOCATION=$(parsear_campo "$JSON_LINE" "location")
      EPISODES=$(parsear_campo "$JSON_LINE" "episodes")

      [[ -z "$CID" ]] && continue

      # Eliminar cualquier entrada previa del mismo ID para evitar duplicados
      grep -v "^${CID}|" characters_cache.txt > characters_cache.tmp && mv characters_cache.tmp characters_cache.txt
      
      # Guardar la informacion del personaje en la cachÃ© y mostrarla por pantalla
      echo "$CID|$NAME|$STATUS|$SPECIES|$GENDER|$ORIGIN|$LOCATION|$EPISODES" >> characters_cache.txt
      mostrar_personaje "$CID" "$NAME" "$STATUS" "$SPECIES" "$GENDER" "$ORIGIN" "$LOCATION" "$EPISODES"
            
    done < /tmp/rickandmorty_separated_$$.txt
    rm -f /tmp/rickandmorty_$$.txt /tmp/rickandmorty_separated_$$.txt
  fi
}

# Funcion para mostrar la ruta de los archivos utilizados
mostrar_path_archivos() {
  echo ""
  echo "INFO: Ruta de archivos utilizados:"
  echo "  Cache de personajes: $(realpath characters_cache.txt)"
  echo "  Log de consultas a la API: $(realpath api_tracking.log)"
}

# Funcion para limpiar el cache
limpiar_cache() {
  rm -f characters_cache.txt api_tracking.log
  echo "INFO: Cache limpiado correctamente."
}

# Ejecucion del script
validar_parametros "$@"
crear_recursos

if [[ "$CLEAR" == true ]]; then
  limpiar_cache
  exit 0
fi

if [[ -n "$ID" ]]; then
  obtener_personajes_por_id
  parsear_respuesta
  mostrar_path_archivos
fi

if [[ -n "$NOMBRE" ]]; then
  obtener_personajes_por_nombre
  parsear_respuesta
  mostrar_path_archivos
fi
