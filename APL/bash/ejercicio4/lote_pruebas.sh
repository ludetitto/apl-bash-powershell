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

echo "============================================================================="
echo "Lote de Pruebas - Demonio de monitoreo (Bash)"
echo "============================================================================="
echo ""

echo "AYUDA"
echo "  $SCRIPT -h"
echo "  $SCRIPT --help"
echo ""

echo "--- ERRORES DE PARÁMETROS ---"
echo ""

echo "Sin argumentos (debe fallar):"
echo "  $SCRIPT"
echo ""

echo "Sin --palabras (debe fallar):"
echo "  $SCRIPT -d /tmp"
echo ""

echo "Sin -d/--directorio (debe fallar):"
echo "  $SCRIPT --palabras password,token"
echo ""

echo "Directorio inexistente (debe fallar):"
echo "  $SCRIPT -d /tmp/directorio_que_no_existe --palabras password"
echo ""

echo "Flag desconocida (debe fallar):"
echo "  $SCRIPT --invalido"
echo ""

echo "-k sin -d (debe fallar):"
echo "  $SCRIPT -k"
echo ""

echo "-k con --palabras (debe fallar, kill solo admite -d):"
echo "  $SCRIPT -d /tmp --palabras token -k"
echo ""

echo "--- FLUJO NORMAL ---"
echo ""

echo "Preparar directorios de prueba:"
echo "  mkdir -p /tmp/prueba_demonio_a /tmp/prueba_demonio_b"
echo ""

echo "Iniciar demonio con log explícito (ruta absoluta):"
echo "  $SCRIPT -d /tmp/prueba_demonio_a --palabras password,token,api_key -l /tmp/monitoreo_a.log"
echo ""

echo "Iniciar demonio sin -l (log se genera automáticamente en el directorio actual):"
echo "  $SCRIPT -d /tmp/prueba_demonio_b --palabras secret,key"
echo ""

echo "Verificar que el demonio liberó la terminal (el prompt debe estar disponible):"
echo "  # Luego del inicio el script debe haber retornado inmediatamente"
echo ""

echo "Crear archivo con palabra clave (debe registrarse en el log):"
echo '  echo "mi password es 1234" > /tmp/prueba_demonio_a/credenciales.txt'
echo ""

echo "Crear archivo sin palabra clave (NO debe registrarse):"
echo '  echo "este archivo no tiene nada relevante" > /tmp/prueba_demonio_a/inofensivo.txt'
echo ""

echo "Crear archivo con coincidencia en mayúsculas/minúsculas (debe registrarse):"
echo '  echo "TOKEN de acceso: abcdef123" > /tmp/prueba_demonio_a/tokens.txt'
echo ""

echo "Modificar archivo existente con palabra clave (debe registrarse como escritura/modificación):"
echo '  echo "nuevo token de acceso" >> /tmp/prueba_demonio_a/credenciales.txt'
echo ""

echo "Ver el log en tiempo real:"
echo "  tail -f /tmp/monitoreo_a.log"
echo ""

echo "--- ARCHIVO YA EN USO ---"
echo ""

echo "Intentar iniciar otro demonio con el mismo log (debe fallar):"
echo "  $SCRIPT -d /tmp/prueba_demonio_b --palabras secret -l /tmp/monitoreo_a.log"
echo ""

echo "--- DOBLE DEMONIO MISMO DIRECTORIO ---"
echo ""

echo "Intentar iniciar un segundo demonio para el mismo directorio (debe fallar):"
echo "  $SCRIPT -d /tmp/prueba_demonio_a --palabras password -l /tmp/otro.log"
echo ""

echo "--- PARÁMETROS EN DISTINTO ORDEN ---"
echo ""

echo "Parámetros en orden alternativo (-l antes que --palabras):"
echo "  mkdir -p /tmp/prueba_orden"
echo "  $SCRIPT -l /tmp/orden.log --palabras admin -d /tmp/prueba_orden"
echo "  $SCRIPT -d /tmp/prueba_orden -k"
echo ""

echo "Nombre largo y alias:"
echo "  mkdir -p /tmp/prueba_alias"
echo "  $SCRIPT --directorio /tmp/prueba_alias --palabras clave --log /tmp/alias.log"
echo "  $SCRIPT --directorio /tmp/prueba_alias --kill"
echo ""

echo "--- DETENER DEMONIOS ---"
echo ""

echo "Detener el demonio del directorio A:"
echo "  $SCRIPT -d /tmp/prueba_demonio_a -k"
echo ""

echo "Detener el demonio del directorio B:"
echo "  $SCRIPT -d /tmp/prueba_demonio_b -k"
echo ""

echo "Intentar detener un demonio que no está corriendo (debe avisar):"
echo "  $SCRIPT -d /tmp/prueba_demonio_a -k"
echo ""

echo "--- ARCHIVOS PREEXISTENTES ---"
echo ""

echo "Crear archivos antes de lanzar el demonio (deben escanearse al iniciar):"
echo "  mkdir -p /tmp/prueba_preexistentes"
echo '  echo "clave secreta de acceso" > /tmp/prueba_preexistentes/previo.txt'
echo "  $SCRIPT -d /tmp/prueba_preexistentes --palabras secreta,clave -l /tmp/preexistentes.log"
echo "  sleep 2 && cat /tmp/preexistentes.log"
echo "  $SCRIPT -d /tmp/prueba_preexistentes -k"
echo ""

echo "--- DIRECTORIOS CON ESPACIOS EN LA RUTA ---"
echo ""

echo "Directorio con espacios en el nombre:"
echo '  mkdir -p "/tmp/prueba con espacios"'
echo '  '"$SCRIPT"' -d "/tmp/prueba con espacios" --palabras token -l /tmp/espacios.log'
echo '  '"$SCRIPT"' -d "/tmp/prueba con espacios" -k'
echo ""

echo "============================================================================="
