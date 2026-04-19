# Lectura de comando
ID=""
NOMBRE=""

# Validación de argumentos
if [[ $# -eq 0 ]]; then
  echo "No se han proporcionado argumentos. Use --help para ver las opciones disponibles."
  exit 1
fi

while [[ $# -gt 0 ]]; do # $# es el número de argumentos restantes, -gt es mayor que
  case "$1" in
    --id)
      ID="${2:-}" # 2:- es el segundo argumento, si no existe se asigna una cadena vacía
      shift 2
      ;; # ;; es el final de un caso en el bloque case
    --id=*) # --id=* es un caso que coincide con cualquier argumento que comience con --id=
      ID="${1#*=}"
      shift
      ;;
    --nombre)
      NOMBRE="${2:-}"
      shift 2
      ;;
    --nombre=*)
      NOMBRE="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Uso: ./rickandmorty.sh [--id 1,2,3] [--nombre rick,morty]"
      exit 0
      ;;
    *)
      echo "Parametro no reconocido: $1"
      exit 1
      ;;
  esac
done

# IFS es el Internal Field Separator, es una variable de entorno que define los caracteres que se utilizan para separar los campos en una cadena. Por defecto, IFS está configurado para separar por espacios, tabulaciones y saltos de línea.
IFS=',' read -ra NOMBRES <<< "$NOMBRE" # read -ra es una opción de read que lee una línea de entrada y la divide en un array, <<< es una redirección que permite pasar una cadena como entrada a un comando

# Creación de caché
touch 'characters_cache.txt';
if ! grep -qx "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" characters_cache.txt; then
  echo "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" > 'characters_cache.txt';
fi
touch 'api_tracking.log'

# Caso de uso: Obtener personajes por ID
if [[ -n "$ID" ]]; then

  ID_CLEAN=$(printf '%s' "$ID" | tr -d '[:space:]')
  IFS=',' read -ra IDS <<< "$ID_CLEAN"

  IDS_A_PEDIR=()
  
  for id in "${IDS[@]}"; do
    if grep -q "ID:$id" api_tracking.log; then
      #echo "DEBUG: ID $id ya fue consultado"
      # TODO: Devolver información desde cache
      grep "^${id}|" characters_cache.txt | while IFS='|' read -r CID NAME STATUS SPECIES GENDER ORIGIN LOCATION EPISODES; do
        [[ "$CID" == "ID" ]] && continue  # Saltar header
      echo "Character info: Id: $CID Name: $NAME Status: $STATUS Species: $SPECIES Gender: $GENDER Origin: $ORIGIN Location: $LOCATION Episodes: $EPISODES"
      done
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
fi

# Caso de uso: Obtener personajes por nombre
if [[ -n "$NOMBRE" ]]; then
  NOMBRES_A_PEDIR=()

  for nombre in "${NOMBRES[@]}"; do
    [[ -z "$nombre" ]] && continue
    
    if grep -q "NOMBRE:$nombre" api_tracking.log; then
      #echo "DEBUG: Nombre '$nombre' ya fue consultado"
      grep -i "$nombre" characters_cache.txt | while IFS='|' read -r CID NAME STATUS SPECIES GENDER ORIGIN LOCATION EPISODES; do
        [[ -z "$CID" ]] && continue
        echo "Character info: Id: $CID Name: $NAME Status: $STATUS Species: $SPECIES Gender: $GENDER Origin: $ORIGIN Location: $LOCATION Episodes: $EPISODES"
      done
     else
      NOMBRES_A_PEDIR+=("$nombre")
    fi
  done
    
  for nombre in "${NOMBRES_A_PEDIR[@]}"; do
    # echo "INFO: Consultando API para IDs: $IDS_QUERY"
    curl -fsS "https://rickandmortyapi.com/api/character/?name=$nombre" > 'temp.txt'
    
    # Loguear cada ID consultado
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] NOMBRE:$nombre" >> api_tracking.log
  done
fi

# Parso de la respuesta JSON en temp
# Separar objetos JSON en líneas
if [[ -s temp.txt ]]; then
  awk 'BEGIN{RS="},{"} {gsub(/^\[/,""); gsub(/\]$/,""); print}' temp.txt > temp_separated.txt

#echo "DEBUG: Líneas en temp_separated.txt:" >&2
#wc -l temp_separated.txt >&2
#echo "DEBUG: Primeros 100 chars:" >&2
#head -c 100 temp_separated.txt >&2
#echo "" >&2

  while IFS= read -r json_line; do
    [[ -z "$json_line" ]] && continue 
  
    CID=$(echo "$json_line" | sed -n 's/.*"id":\([0-9]*\).*/\1/p')
    NAME=$(echo "$json_line" | sed -n 's/.*"id":[0-9]*,"name":"\([^"]*\)".*/\1/p')
    STATUS=$(echo "$json_line" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')
    SPECIES=$(echo "$json_line" | sed -n 's/.*"species":"\([^"]*\)".*/\1/p')
    GENDER=$(echo "$json_line" | sed -n 's/.*"gender":"\([^"]*\)".*/\1/p')
    ORIGIN=$(echo "$json_line" | sed -n 's/.*"origin":{"name":"\([^"]*\)".*/\1/p')
    LOCATION=$(echo "$json_line" | sed -n 's/.*"location":{"name":"\([^"]*\)".*/\1/p')
    EPISODES=$(echo "$json_line" | grep -o 'https://rickandmortyapi.com/api/episode/[0-9]\+' | wc -l)
    
    [[ -z "$CID" ]] && continue

    # Evitar duplicados
    grep -v "^${CID}|" characters_cache.txt > characters_cache.tmp && mv characters_cache.tmp characters_cache.txt
    
    # Guardar
    echo "$CID|$NAME|$STATUS|$SPECIES|$GENDER|$ORIGIN|$LOCATION|$EPISODES" >> characters_cache.txt
    echo "Character info: Id: $CID Name: $NAME Status: $STATUS Species: $SPECIES Gender: $GENDER Origin: $ORIGIN Location: $LOCATION Episodes: $EPISODES"
    
  done < temp_separated.txt
fi

rm -f temp.txt temp_separated.txt
echo ""
echo "Los personajes se han guardado en $PWD/characters_cache.txt"
echo ""
echo "Las consultas a la api se han guardado en $PWD/api_tracking.log"