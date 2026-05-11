#!/bin/bash

# =============================================================================
# Lote de prueba - Ejercicio 5
# Materia: Virtualización de Hardware (3654) - UNLaM 2026
# Integrantes:
#   - Vignardel Francisco
#   - De Titto Lucia
#   - Gallardo Samuel
#   - Francisco Vladimir
#   - Medina Ramiro
# =============================================================================

SCRIPT="./rickandmorty.sh"

echo "============================================================================="
echo "Lote de Pruebas - Rick and Morty (Bash)"
echo "============================================================================="
echo ""

echo "AYUDA"
echo "  $SCRIPT -h"
echo ""

echo "BÚSQUEDA POR ID"
echo "  $SCRIPT -i 1"
echo "  $SCRIPT -i "1,2,3""
echo "  $SCRIPT --id=1"
echo ""

echo "BÚSQUEDA POR NOMBRE"
echo "  $SCRIPT -n rick"
echo "  $SCRIPT -n "'"rick,morty"'""
echo "  $SCRIPT --nombre="'"rick sanchez"'""
echo ""

echo "BÚSQUEDA COMBINADA"
echo "  $SCRIPT -i 1 -n rick"
echo "  $SCRIPT -i "1,2" -n "'"rick,morty"'""
echo ""

echo "VALIDACIÓN DE ERRORES"
echo "  $SCRIPT                      # sin argumentos"
echo "  $SCRIPT -i abc               # ID inválido"
echo "  $SCRIPT -i "1,,2"            # comas dobles"
echo "  $SCRIPT --clear -i 1         # conflicto de parámetros"
echo ""

echo "GESTIÓN DE CACHÉ"
echo "  $SCRIPT -i 1                 # primera búsqueda"
echo "  $SCRIPT -i 1                 # segunda búsqueda (desde caché)"
echo "  cat characters_cache.txt     # ver caché"
echo "  $SCRIPT --clear              # limpiar caché"
echo ""

echo "============================================================================="
