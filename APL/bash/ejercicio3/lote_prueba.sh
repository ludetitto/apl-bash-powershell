#!/bin/bash

# =============================================================================
# Lote de prueba - Ejercicio 3
# Materia: Virtualización de Hardware (3654) - UNLaM 2026
# Integrantes:
#   - Francisco, Vladimir
#   - Nombre Apellido
#   - Nombre Apellido
#   - Nombre Apellido
#   - Nombre Apellido
# =============================================================================

DIR_PRUEBA="/tmp/prueba_ej3"

echo "Creando estructura de prueba en $DIR_PRUEBA..."

# Creamos los directorios
mkdir -p "$DIR_PRUEBA/sub1"
mkdir -p "$DIR_PRUEBA/sub2"
mkdir -p "$DIR_PRUEBA/sub2/sub3"

# Caso duplicado real (mismo nombre y mismo tamaño)
echo "hola" > "$DIR_PRUEBA/sub1/test.txt"
echo "hola" > "$DIR_PRUEBA/sub2/test.txt"
echo "hola" > "$DIR_PRUEBA/sub2/sub3/test.txt"

# Mismo nombre pero distinto tamaño (NO debe aparecer como duplicado)
echo "hola" > "$DIR_PRUEBA/sub1/foto.png"
echo "contenido diferente mas largo" > "$DIR_PRUEBA/sub2/foto.png"

# Archivo único (no debe aparecer)
echo "soy unico" > "$DIR_PRUEBA/sub1/unico.txt"

echo "Estructura creada. Podés probar con los siguientes casos:"
echo ""
echo "  # Caso 1: directorio completo con duplicados"
echo "  ./ejercicio3.sh --directorio $DIR_PRUEBA"
echo ""
echo "  # Caso 2: subdirectorio sin duplicados"
echo "  ./ejercicio3.sh --directorio $DIR_PRUEBA/sub1"
echo ""
echo "  # Caso 3: subdirectorio con duplicados"
echo "  ./ejercicio3.sh --directorio $DIR_PRUEBA/sub2"
echo ""
echo "  # Caso 4: sin parámetros"
echo "  ./ejercicio3.sh"
echo ""
echo "  # Caso 5: directorio inexistente"
echo "  ./ejercicio3.sh --directorio /ruta/inexistente"
echo ""
echo "  # Caso 6: parámetro inválido"
echo "  ./ejercicio3.sh --inventado"
echo ""
echo "  # Caso 7: ayuda"
echo "  ./ejercicio3.sh --help"