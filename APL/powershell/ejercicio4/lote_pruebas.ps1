#!/usr/bin/env pwsh

#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 4                                    #
#                                                       #
#   Integrantes:                                        #
#       Vignardel Francisco                             #
#       De Titto Lucia                                  #
#       Gallardo Samuel                                 #
#       Francisco Vladimir                              #
#       Medina Ramiro                                   #
#                                                       #
#-------------------------------------------------------#

$SCRIPT = ".\demonio.ps1"
$T = "/tmp"

Write-Host "===== Lote de Pruebas - Demonio de monitoreo (PowerShell) =====" -ForegroundColor Blue
Write-Host ""

Write-Host "AYUDA" -ForegroundColor Yellow
Write-Host "  Get-Help $SCRIPT" -ForegroundColor Cyan
Write-Host ""

Write-Host "ERRORES DE PARAMETROS" -ForegroundColor Yellow
Write-Host "  $SCRIPT                                                         # sin argumentos" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T                                          # sin -Palabras" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Palabras password,token                                # sin -Directorio" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/no_existe -Palabras pass                 # dir inexistente" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Kill                                                   # -Kill sin -Directorio" -ForegroundColor Cyan
Write-Host ""

Write-Host "FLUJO NORMAL" -ForegroundColor Yellow
Write-Host "  New-Item -ItemType Directory -Force -Path $T/prueba_a, $T/prueba_b" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/prueba_a -Palabras 'password,token,api_key' -Log $T/monitoreo_prueba_a.log" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/prueba_b -Palabras 'secret,key'           # log automatico" -ForegroundColor Cyan
Write-Host "  'mi password es 1234'    | Out-File $T/prueba_a/credenciales.txt # debe registrarse" -ForegroundColor Cyan
Write-Host "  'archivo sin relevancia' | Out-File $T/prueba_a/inofensivo.txt   # NO debe registrarse" -ForegroundColor Cyan
Write-Host "  'TOKEN de acceso: abc'   | Out-File $T/prueba_a/tokens.txt       # case-insensitive" -ForegroundColor Cyan
Write-Host "  Get-Content $T/monitoreo_prueba_a.log" -ForegroundColor Cyan
Write-Host ""

Write-Host "ERRORES EN TIEMPO DE EJECUCION" -ForegroundColor Yellow
Write-Host "  $SCRIPT -Directorio $T/prueba_b -Palabras 'secret' -Log $T/monitoreo_prueba_a.log  # log ya en uso" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/prueba_a -Palabras 'pass' -Log $T/segundo_demonio.log        # dir ya monitorado" -ForegroundColor Cyan
Write-Host ""

Write-Host "ARCHIVOS PREEXISTENTES" -ForegroundColor Yellow
Write-Host "  New-Item -ItemType Directory -Force -Path $T/prueba_prev" -ForegroundColor Cyan
Write-Host "  'clave secreta' | Out-File $T/prueba_prev/previo.txt" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/prueba_prev -Palabras 'secreta,clave' -Log $T/preexistentes.log" -ForegroundColor Cyan
Write-Host "  Start-Sleep 2; Get-Content $T/preexistentes.log" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/prueba_prev -Kill" -ForegroundColor Cyan
Write-Host ""

Write-Host "DETENER DEMONIOS" -ForegroundColor Yellow
Write-Host "  $SCRIPT -Directorio $T/prueba_a -Kill" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/prueba_b -Kill" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $T/prueba_a -Kill   # ya detenido, debe avisar" -ForegroundColor Cyan
Write-Host ""

Write-Host "RUTAS CON ESPACIOS Y ALIAS DE PARAMETROS" -ForegroundColor Yellow
Write-Host "  New-Item -ItemType Directory -Force -Path `"$T/prueba con espacios`"" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio `"$T/prueba con espacios`" -p 'token' -l $T/ruta_con_espacios.log" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio `"$T/prueba con espacios`" -k" -ForegroundColor Cyan
Write-Host ""

Write-Host "===============================================================" -ForegroundColor Blue
