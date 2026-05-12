#!/bin/bash

# =============================================================================
# Lote de prueba - Ejercicio 4
# Materia: Virtualización de Hardware (3654) - UNLaM 2026
# Integrantes:
#   - Vignardel Francisco
#   - De Titto Lucia
#   - Gallardo Samuel
#   - Francisco Vladimir
#   - Medina Ramiro
# =============================================================================

SCRIPT="./demonio.sh"

echo "===== Lote de Pruebas - Demonio de monitoreo (Bash) ====="
echo ""

echo "AYUDA"
echo "  $SCRIPT -h"
echo ""

echo "ERRORES DE PARÁMETROS"
echo "  $SCRIPT                                          # sin argumentos"
echo "  $SCRIPT -d /tmp                                  # sin --palabras"
echo "  $SCRIPT --palabras password,token                # sin -d"
echo "  $SCRIPT -d /tmp/no_existe --palabras pass        # directorio inexistente"
echo "  $SCRIPT --invalido                               # flag desconocida"
echo "  $SCRIPT -k                                       # -k sin -d"
echo "  $SCRIPT -d /tmp --palabras token -k              # -k con --palabras"
echo ""

echo "FLUJO NORMAL"
echo "  mkdir -p /tmp/prueba_a /tmp/prueba_b"
echo "  $SCRIPT -d /tmp/prueba_a --palabras password,token,api_key -l /tmp/monitoreo_prueba_a.log"
echo "  $SCRIPT -d /tmp/prueba_b --palabras secret,key              # log automático"
echo '  echo "mi password es 1234" > /tmp/prueba_a/credenciales.txt  # debe registrarse'
echo '  echo "archivo sin relevancia" > /tmp/prueba_a/inofensivo.txt  # NO debe registrarse'
echo '  echo "TOKEN de acceso: abc" > /tmp/prueba_a/tokens.txt        # case-insensitive'
echo "  tail -f /tmp/monitoreo_prueba_a.log"
echo ""

echo "ERRORES EN TIEMPO DE EJECUCIÓN"
echo "  $SCRIPT -d /tmp/prueba_b --palabras secret -l /tmp/monitoreo_prueba_a.log  # log ya en uso"
echo "  $SCRIPT -d /tmp/prueba_a --palabras pass   -l /tmp/segundo_demonio.log   # dir ya monitorado"
echo ""

echo "ARCHIVOS PREEXISTENTES"
echo "  mkdir -p /tmp/prueba_prev"
echo '  echo "clave secreta" > /tmp/prueba_prev/previo.txt'
echo "  $SCRIPT -d /tmp/prueba_prev --palabras secreta,clave -l /tmp/preexistentes.log"
echo "  sleep 2 && cat /tmp/preexistentes.log"
echo "  $SCRIPT -d /tmp/prueba_prev -k"
echo ""

echo "DETENER DEMONIOS"
echo "  $SCRIPT -d /tmp/prueba_a -k"
echo "  $SCRIPT -d /tmp/prueba_b -k"
echo "  $SCRIPT -d /tmp/prueba_a -k   # ya detenido, debe avisar"
echo ""

echo "PARÁMETROS EN DISTINTO ORDEN Y RUTAS CON ESPACIOS"
echo "  mkdir -p /tmp/prueba_orden"
echo "  $SCRIPT -l /tmp/orden_parametros.log --palabras admin -d /tmp/prueba_orden"
echo "  $SCRIPT -d /tmp/prueba_orden -k"
echo '  mkdir -p "/tmp/prueba con espacios"'
echo '  '"$SCRIPT"' -d "/tmp/prueba con espacios" --palabras token -l /tmp/ruta_con_espacios.log'
echo '  '"$SCRIPT"' -d "/tmp/prueba con espacios" -k'
echo ""

echo "========================================================="
