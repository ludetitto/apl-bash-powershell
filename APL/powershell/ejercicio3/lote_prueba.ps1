#!/usr/bin/env pwsh

#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 3                                    #
#                                                       #
#   Integrantes:                                        #
#       Vignardel Francisco                             #
#       De Titto Lucia                                  #
#       Gallardo Samuel                                 #
#       Francisco Vladimir                              #
#       Medina Ramiro                                   #
#                                                       #
#-------------------------------------------------------#

<#
.SYNOPSIS
    Lote de prueba para el ejercicio 3 - Deteccion de archivos duplicados.

.DESCRIPTION
    Crea una estructura de directorios y archivos temporales para probar
    el ejercicio 3. Una vez creada la estructura, el usuario puede probar
    los casos manualmente. Al presionar Enter, limpia todo.
#>

$script = ".\ejercicio3.ps1"
$dirPrueba = "$env:TEMP\prueba_ej3"

try {
    # ============================================================
    # PREPARACION: Crear estructura de directorios y archivos
    # ============================================================
    Write-Host "Creando estructura de prueba..." -ForegroundColor Yellow

    New-Item -ItemType Directory -Path "$dirPrueba\sub1" -Force | Out-Null
    New-Item -ItemType Directory -Path "$dirPrueba\sub2" -Force | Out-Null
    New-Item -ItemType Directory -Path "$dirPrueba\sub2\sub3" -Force | Out-Null

    # Caso 1: duplicado real (mismo nombre y mismo tamanio)
    "hola" | Out-File "$dirPrueba\sub1\test.txt" -Encoding utf8 -NoNewline
    "hola" | Out-File "$dirPrueba\sub2\test.txt" -Encoding utf8 -NoNewline
    "hola" | Out-File "$dirPrueba\sub2\sub3\test.txt" -Encoding utf8 -NoNewline

    # Caso 2: mismo nombre distinto tamanio (NO es duplicado)
    "hola" | Out-File "$dirPrueba\sub1\foto.png" -Encoding utf8 -NoNewline
    "contenido diferente mas largo" | Out-File "$dirPrueba\sub2\foto.png" -Encoding utf8 -NoNewline

    # Caso 3: archivo unico
    "soy unico" | Out-File "$dirPrueba\sub1\unico.txt" -Encoding utf8 -NoNewline

    Write-Host "Estructura creada en: $dirPrueba" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Casos de prueba disponibles:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "CASO 1 - Duplicados en directorio completo (debe mostrar test.txt en 3 ubicaciones):"
    Write-Host "  & $script -directorio '$dirPrueba'" -ForegroundColor White
    Write-Host ""
    Write-Host "CASO 2 - Sin duplicados (no debe mostrar nada):"
    Write-Host "  & $script -directorio '$dirPrueba\sub1'" -ForegroundColor White
    Write-Host ""
    Write-Host "CASO 3 - Subdirectorio con duplicados (test.txt en sub2 y sub3):"
    Write-Host "  & $script -directorio '$dirPrueba\sub2'" -ForegroundColor White
    Write-Host ""
    Write-Host "CASO 4 - Directorio inexistente (debe mostrar error):"
    Write-Host "  & $script -directorio 'C:\ruta\falsa'" -ForegroundColor White
    Write-Host ""
    Write-Host "CASO 5 - Sin parametros (debe pedir el directorio):"
    Write-Host "  & $script" -ForegroundColor White
    Write-Host ""
    Write-Host "CASO 6 - Ayuda:"
    Write-Host "  Get-Help $script -Full" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan

    Read-Host "Presione Enter cuando termine de probar para limpiar los archivos"

} finally {
    Remove-Item -Path $dirPrueba -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Archivos temporales eliminados." -ForegroundColor Green
}