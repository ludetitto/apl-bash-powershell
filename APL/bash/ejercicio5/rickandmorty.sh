#!/bin/bash

# DeclaraciÃ³n de parÃ¡metros globales
ID=""
NOMBRE=""
CLEAR=false

# FunciÃ³n para mostrar el help con formato similar a man page
mostrar_ayuda() {
  cat << 'EOF'
RICKANDMORTY - Busqueda de personajes de Rick and Morty

SINOPSIS
    rickandmorty.sh [OPCIÃ“N]...

DESCRIPCION
    Consulta la API de Rick and Morty para obtener informaciÃ³n sobre personajes.
    Los datos se cachean localmente para optimizar las consultas posteriores.

OPCIONES
    -i, --id [IDs]
        ID/s de los personajes a buscar. Acepta mÃºltiples IDs separados por comas.
        Ejemplo: ./rickandmorty.sh --id 1,2,3
                 ./rickandmorty.sh -i 1

    -n, --nombre [NOMBRES]
        Nombre/s de los personajes a buscar. Acepta mÃºltiples nombres separados 
        por comas. No es sensible a mayÃºsculas/minÃºsculas.
        Ejemplo: ./rickandmorty.sh --nombre rick,morty
                 ./rickandmorty.sh -n rick

    -c, --clear
        Limpia el cachÃ© de personajes guardado. No puede utilizarse junto con
        opciones de bÃºsqueda (-i, -n, --id, --nombre).
        Ejemplo: ./rickandmorty.sh --clear

    -h, --help
        Muestra este mensaje de ayuda.

EJEMPLOS
    # Busqueda por ID
    ./rickandmorty.sh -i 1
    ./rickandmorty.sh --id 1,2,3

    # Busqueda por nombre
    ./rickandmorty.sh -n rick
    ./rickandmorty.sh --nombre rick,morty

    # Busqueda combinada
    ./rickandmorty.sh -i 1 -n rick

    # Limpiar cachÃ©
    ./rickandmorty.sh --clear

ARCHIVOS
    characters_cache.txt
        Base de datos local de personajes consultados.
    
    api_tracking.log
        Registro de todas las consultas realizadas a la API.

EOF
}

# Funcion para validar los parametros de entrada
validar_parametros() {
  if [[ $# -eq 0 ]]; then
    echo "No se han proporcionado argumentos. Use --help para ver las opciones disponibles."
    exit 1
  fi

  while [[ $# -gt 0 ]]; do # $# es el nÃºmero de argumentos restantes, -gt es mayor que
    case "$1" in
      -i|--id)
        ID="${2:-}" # 2:- es el segundo argumento, si no existe se asigna una cadena vacÃ­a
        shift 2
        ;; # ;; es el final de un caso en el bloque case
      --id=*) # --id=* es un caso que coincide con cualquier argumento que comience con --id=
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
        echo "ParÃ¡metro no reconocido: $1"
        echo "Use --help para ver las opciones disponibles."
        exit 1
        ;;
    esac
  done

  # Validar que --clear no se use con opciones de bÃºsqueda
  if [[ "$CLEAR" == true ]] && ([[ -n "$ID" ]] || [[ -n "$NOMBRE" ]]); then
    echo "Error: -c/--clear no puede utilizarse junto con opciones de bÃºsqueda (-i, -n, --id, --nombre)"
    exit 1
  fi
}

# Funcion para crear los archivos necesarios si no existen y agregar encabezado a la cachÃ© si es la primera vez
crear_recursos() {
  touch 'characters_cache.txt';
  if ! grep -qx "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" characters_cache.txt; then
    echo "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" > 'characters_cache.txt';
  fi
  touch 'api_tracking.log'
}

# Funcion para mostrar la informacion de un personaje
mostrar_personaje() {
    local id="$1" nombre="$2" status="$3" species="$4" gender="$5" origin="$6" location="$7" episodes="$8"
    printf "Character info:\nId: %s\nName: %s\nStatus: %s\nSpecies: %s\nGender: %s\nOrigin: %s\nLocation: %s\nEpisodes: %s\n" "$id" "$nombre" "$status" "$species" "$gender" "$origin" "$location" "$episodes"
}

# Funcion para buscar personajes en la cachÃ©, una vez que se sabe que fue consultado previamente a la API
buscar_en_cache() {
    local tipo="$1" valor="$2"  # tipo puede ser "ID" o "NOMBRE"
    if [[ "$tipo" == "ID" ]]; then
        grep "^${valor}|" characters_cache.txt | while IFS='|' read -r CID NAME STATUS SPECIES GENDER ORIGIN LOCATION EPISODES; do
            [[ -z "$CID" ]] || [[ "$CID" == "ID" ]] && continue
            mostrar_personaje "$CID" "$NAME" "$STATUS" "$SPECIES" "$GENDER" "$ORIGIN" "$LOCATION" "$EPISODES"
        done
    else  # "$tipo" == "NOMBRE"
        grep -i "^[0-9]*|$valor|\|^[0-9]*|[^|]*$valor" characters_cache.txt | while IFS='|' read -r CID NAME STATUS SPECIES GENDER ORIGIN LOCATION EPISODES; do
            [[ -z "$CID" ]] || [[ "$CID" == "ID" ]] && continue
            mostrar_personaje "$CID" "$NAME" "$STATUS" "$SPECIES" "$GENDER" "$ORIGIN" "$LOCATION" "$EPISODES"
        done
    fi
    return 0
}

# Funcion para obtener personajes por ID
obtener_personajes_por_id() {
    ID_CLEAN=$(printf '%s' "$ID" | sed 's/[^0-9,]//g')
    #echo "DEBUG: ID_CLEAN='$ID_CLEAN'" >&2
    IFS=',' read -ra IDS <<< "$ID_CLEAN"

    IDS_A_PEDIR=()
    
    for id in "${IDS[@]}"; do
      if grep -q "^${id}|" characters_cache.txt; then
        buscar_en_cache "ID" "$id"
      else
        IDS_A_PEDIR+=("$id")
      fi
    done

    if [[ ${#IDS_A_PEDIR[@]} -gt 0 ]]; then
      IDS_QUERY=$(IFS=,; echo "${IDS_A_PEDIR[*]}")
      # echo "INFO: Consultando API para IDs: $IDS_QUERY"
      curl -fsS "https://rickandmortyapi.com/api/character/$IDS_QUERY" > 'temp.txt'
      
      # Loguear cada ID consultado
      for id in "${IDS_A_PEDIR[@]}"; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ID:$id" >> api_tracking.log
      done
    fi
}

# Funcion para obtener personajes por nombre
obtener_personajes_por_nombre() {
    NOMBRES_A_PEDIR=()
    NOMBRE_CLEAN=${NOMBRE//[[:space:]]/}
    IFS=',' read -ra NOMBRES <<< "$NOMBRE_CLEAN"

    for nombre in "${NOMBRES[@]}"; do
      [[ -z "$nombre" ]] && continue
      
      if grep -q "NOMBRE:$nombre" api_tracking.log; then
        buscar_en_cache "NOMBRE" "$nombre"
      else
        NOMBRES_A_PEDIR+=("$nombre")
      fi
    done
      
    for nombre in "${NOMBRES_A_PEDIR[@]}"; do
      # echo "INFO: Consultando API para nombre: $nombre"
      if [[ -s temp.txt ]]; then
        echo "," >> 'temp.txt'
      fi
      curl -fsS "https://rickandmortyapi.com/api/character/?name=$nombre" >> 'temp.txt'
      
      # Loguear cada nombre consultado
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] NOMBRE:$nombre" >> api_tracking.log
    done
}

# Funcion para parsear un campo especifico de un objeto JSON
parsear_campo() {
  local json="$1" campo="$2"
    case "$campo" in
        id) echo "$json" | sed -n 's/.*"id":\([0-9]*\).*/\1/p' ;;
        name) echo "$json" | sed -n 's/.*"id":[0-9]*,"name":"\([^"]*\)".*/\1/p' ;;
        status) echo "$json" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p' ;;
        species) echo "$json" | sed -n 's/.*"species":"\([^"]*\)".*/\1/p' ;;
        gender) echo "$json" | sed -n 's/.*"gender":"\([^"]*\)".*/\1/p' ;;
        origin) echo "$json" | sed -n 's/.*"origin":{"name":"\([^"]*\)".*/\1/p' ;;
        location) echo "$json" | sed -n 's/.*"location":{"name":"\([^"]*\)".*/\1/p' ;;
        episodes) echo "$json" | grep -o 'https://rickandmortyapi.com/api/episode/[0-9]\+' | wc -l ;;
        *) echo "" ;;
    esac
}

# Funcion para separar objetos JSON en lineas individuales
separar_objetos_json() {
    local input_file="$1" output_file="$2"
    awk 'BEGIN{RS="},{"}
  {
    gsub(/^\[/, ""); gsub(/\]$/, ""); gsub(/^{/, ""); gsub(/}$/, ""); gsub(/^ +/, ""); gsub(/ +$/, "")
    if (NF > 0) {
      print "{" $0 "}"
    }
  }' "$input_file" > "$output_file"
}

# Funcion para parsear la respuesta de la API y guardar los datos en la caché
parsear_respuesta() {
  if [[ -s temp.txt ]]; then
    separar_objetos_json temp.txt temp_separated.txt

    while IFS= read -r json_line; do
      [[ -z "$json_line" ]] && continue 
    
      CID=$(parsear_campo "$json_line" "id")
      NAME=$(parsear_campo "$json_line" "name")
      STATUS=$(parsear_campo "$json_line" "status")
      SPECIES=$(parsear_campo "$json_line" "species")
      GENDER=$(parsear_campo "$json_line" "gender")
      ORIGIN=$(parsear_campo "$json_line" "origin")
      LOCATION=$(parsear_campo "$json_line" "location")
      EPISODES=$(parsear_campo "$json_line" "episodes")

      [[ -z "$CID" ]] && continue

      # Eliminar cualquier entrada previa del mismo ID para evitar duplicados
      grep -v "^${CID}|" characters_cache.txt > characters_cache.tmp && mv characters_cache.tmp characters_cache.txt
      
      # Guardar la informaciÃ³n del personaje en la cachÃ© y mostrarla por pantalla
      echo "$CID|$NAME|$STATUS|$SPECIES|$GENDER|$ORIGIN|$LOCATION|$EPISODES" >> characters_cache.txt
      mostrar_personaje "$CID" "$NAME" "$STATUS" "$SPECIES" "$GENDER" "$ORIGIN" "$LOCATION" "$EPISODES"
            
    done < temp_separated.txt
  fi
}

# Funcion para borrar archivos temporales
borrar_temporales() {
  rm -f temp.txt temp_separated.txt
}

# Funcion para mostrar la ruta de los archivos utilizados
mostrar_path_archivos() {
  echo ""
  echo "INFO: Ruta de archivos utilizados:"
  echo "  CachÃ© de personajes: $(realpath characters_cache.txt)"
  echo "  Log de consultas a la API: $(realpath api_tracking.log)"
}

# Funcion para limpiar el cache
limpiar_cache() {
  rm -f characters_cache.txt api_tracking.log
  echo "INFO: CachÃ© limpiado correctamente."
}

# Ejecucion del script
validar_parametros "$@"
crear_recursos

if [[ "$CLEAR" == true ]]; then
  limpiar_cache
  exit 0
elif [[ -n "$ID" ]] && [[ -n "$NOMBRE" ]]; then
  #echo "INFO: Obteniendo personajes por ID: $ID"
  obtener_personajes_por_id
  #echo "INFO: Obteniendo personajes por nombre: $NOMBRE"
  obtener_personajes_por_nombre
elif [[ -n "$ID" ]]; then
  #echo "INFO: Obteniendo personajes por ID: $ID"
  obtener_personajes_por_id
elif [[ -n "$NOMBRE" ]]; then
  #echo "INFO: Obteniendo personajes por nombre: $NOMBRE"
  obtener_personajes_por_nombre
fi

parsear_respuesta
borrar_temporales
mostrar_path_archivos