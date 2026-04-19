# Lectura de comando
ID=""
NAME=""

while [[ $# -gt 0 ]]; do # $# es el número de argumentos restantes, -gt es mayor que
  case "$1" in
    --id)
      ID="${2:-}" # 2:- es el segundo argumento, si no existe se asigna una cadena vacía
      shift 2
      ;; # ;; es el final de un caso en el bloque case
    --id=*) # --id=* es un caso que coincide con cualquier argumento que comience con --id=
      ID="${1#*=}" # ${1#*=} es el primer argumento sin el prefijo --id=
      shift
      ;;
    --name)
      NAME="${2:-}"
      shift 2
      ;;
    --name=*)
      NAME="${1#*=}"
      shift
      ;;
    -h|--help)
      echo "Uso: ./rickandmorty.sh [--id 1,2,3] [--name rick,morty]"
      exit 0
      ;;
    *)
      echo "Parametro no reconocido: $1"
      exit 1
      ;;
  esac
done

# IFS es el Internal Field Separator, es una variable de entorno que define los caracteres que se utilizan para separar los campos en una cadena. Por defecto, IFS está configurado para separar por espacios, tabulaciones y saltos de línea.
IFS=',' read -ra IDS <<< "$ID" # read -ra es una opción de read que lee una línea de entrada y la divide en un array, <<< es una redirección que permite pasar una cadena como entrada a un comando
IFS=',' read -ra NAME <<< "$NAME"

# Creación de caché
touch 'personajes_cache.txt';
if ! grep -qx "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" personajes_cache.txt; then
  echo "ID|NAME|STATUS|SPECIES|GENDER|ORIGIN|LOCATION|EPISODES" > 'personajes_cache.txt';
fi

# Caso de uso: Obtener personajes por ID
if [[ ${#IDS[@]} -gt 0 ]]; then
  echo "Obteniendo personajes con IDs: ${IDS[*]}"; \
  
  curl "https://rickandmortyapi.com/api/character/${IDS[*]}" --silent \
  > 'temp.txt';
    #echo "Character info: Id: ${id} Name: ${NAME} Status: ${STATUS} Species: ${SPECIES} Gender: ${GENDER} Origin: ${ORIGIN} Location: ${LOCATION} Episodes: ${EPISODES}";
fi


# Parso de la respuesta JSON en temp
JSON=$(cat temp.txt)
while IFS= read -r JSON || [[ -n "$JSON" ]]; do
  [[ -z "$JSON" ]] && continue
    ID=$(echo "$JSON" | sed -n 's/.*"id":\([0-9]*\).*/\1/p')
    NAME=$(echo "$JSON" | sed -n 's/.*"id":[0-9][0-9]*,"name":"\([^"]*\)".*/\1/p')
    STATUS=$(echo "$JSON" | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')
    SPECIES=$(echo "$JSON" | sed -n 's/.*"species":"\([^"]*\)".*/\1/p')
    GENDER=$(echo "$JSON" | sed -n 's/.*"gender":"\([^"]*\)".*/\1/p')
    ORIGIN=$(echo "$JSON" | sed -n 's/.*"origin":{"name":"\([^"]*\)".*/\1/p')
    LOCATION=$(echo "$JSON" | sed -n 's/.*"location":{"name":"\([^"]*\)".*/\1/p')
    EPISODES=$(echo "$JSON" | grep -o 'https://rickandmortyapi.com/api/episode/[0-9]\+' | wc -l)
    
    echo "$ID|$NAME|$STATUS|$SPECIES|$GENDER|$ORIGIN|$LOCATION|$EPISODES" >> personajes_cache.txt
    echo "Character info: Id: $ID Name: $NAME Status: $STATUS Species: $SPECIES Gender: $GENDER Origin: $ORIGIN Location: $LOCATION Episodes: $EPISODES"

    echo "Los personajes se han guardado en $PWD/personajes_cache.txt"

done < temp.txt

# TODO: Caso de uso: Obtener personajes por nombre 

#if [[ ${#NAME[@]} -gt 0 ]]; then
#  curl 'https://rickandmortyapi.com/api/character/?name=$NAMES' \
#    --silent \
#    > 'personajes_cache.txt'; \
#    echo "Los personajes se han guardado en $PWD/personajes_cache.txt"
#fi

# Paso 2: Crear archivo caché para evitar múltiples solicitudes
#> personajes_cache.txt; echo "Los archivos de cache se encuentran en $PWD/personajes_cache.txt"
#--variable '$ID' '$NOMBRE' \
#--expand-url 'https://rickandmortyapi.com/api/character/$ID' \