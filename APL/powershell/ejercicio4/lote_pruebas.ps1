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

$SCRIPT = ".\demonio.ps1"

Write-Host ""
Write-Host "=============================================================================" -ForegroundColor Blue
Write-Host "Lote de Pruebas - Demonio de monitoreo (PowerShell)" -ForegroundColor Blue
Write-Host "=============================================================================" -ForegroundColor Blue
Write-Host ""

Write-Host "AYUDA" -ForegroundColor Yellow
Write-Host "  Get-Help $SCRIPT" -ForegroundColor Cyan
Write-Host "  Get-Help $SCRIPT -Full" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- ERRORES DE PARÁMETROS ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Sin argumentos (debe fallar):" -ForegroundColor White
Write-Host "  $SCRIPT" -ForegroundColor Cyan
Write-Host ""

Write-Host "Sin -Palabras (debe fallar):" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio C:\Windows\Temp" -ForegroundColor Cyan
Write-Host ""

Write-Host "Sin -Directorio (debe fallar):" -ForegroundColor White
Write-Host "  $SCRIPT -Palabras password,token" -ForegroundColor Cyan
Write-Host ""

Write-Host "Directorio inexistente (debe fallar):" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio C:\ruta\que\no\existe -Palabras password" -ForegroundColor Cyan
Write-Host ""

Write-Host "-Kill sin -Directorio (debe fallar):" -ForegroundColor White
Write-Host "  $SCRIPT -Kill" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- FLUJO NORMAL ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Preparar directorios de prueba:" -ForegroundColor White
Write-Host "  New-Item -ItemType Directory -Force -Path $env:TEMP\prueba_demonio_a, $env:TEMP\prueba_demonio_b" -ForegroundColor Cyan
Write-Host ""

Write-Host "Iniciar demonio con log explícito:" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_demonio_a -Palabras 'password,token,api_key' -Log $env:TEMP\monitoreo_a.log" -ForegroundColor Cyan
Write-Host ""

Write-Host "Iniciar demonio sin -Log (log se genera automáticamente en el directorio actual):" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_demonio_b -Palabras 'secret,key'" -ForegroundColor Cyan
Write-Host ""

Write-Host "Verificar que el demonio liberó la terminal (el prompt debe estar disponible):" -ForegroundColor White
Write-Host "  # Luego del inicio el script debe haber retornado inmediatamente" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Crear archivo con palabra clave (debe registrarse en el log):" -ForegroundColor White
Write-Host "  'mi password es 1234' | Out-File $env:TEMP\prueba_demonio_a\credenciales.txt" -ForegroundColor Cyan
Write-Host ""

Write-Host "Crear archivo sin palabra clave (NO debe registrarse):" -ForegroundColor White
Write-Host "  'este archivo no tiene nada relevante' | Out-File $env:TEMP\prueba_demonio_a\inofensivo.txt" -ForegroundColor Cyan
Write-Host ""

Write-Host "Crear archivo con coincidencia en mayúsculas/minúsculas (debe registrarse):" -ForegroundColor White
Write-Host "  'TOKEN de acceso: abcdef123' | Out-File $env:TEMP\prueba_demonio_a\tokens.txt" -ForegroundColor Cyan
Write-Host ""

Write-Host "Modificar archivo existente con palabra clave (debe registrarse):" -ForegroundColor White
Write-Host "  'nuevo api_key de acceso' | Add-Content $env:TEMP\prueba_demonio_a\credenciales.txt" -ForegroundColor Cyan
Write-Host ""

Write-Host "Ver el log:" -ForegroundColor White
Write-Host "  Get-Content $env:TEMP\monitoreo_a.log" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- ARCHIVO DE LOG YA EN USO ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Intentar iniciar otro demonio con el mismo log (debe fallar):" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_demonio_b -Palabras 'secret' -Log $env:TEMP\monitoreo_a.log" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- DOBLE DEMONIO MISMO DIRECTORIO ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Intentar iniciar un segundo demonio para el mismo directorio (debe fallar):" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_demonio_a -Palabras 'password' -Log $env:TEMP\otro.log" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- DETENER DEMONIOS ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Detener el demonio del directorio A:" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_demonio_a -Kill" -ForegroundColor Cyan
Write-Host ""

Write-Host "Detener el demonio del directorio B:" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_demonio_b -Kill" -ForegroundColor Cyan
Write-Host ""

Write-Host "Intentar detener un demonio que no está corriendo (debe avisar):" -ForegroundColor White
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_demonio_a -Kill" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- ARCHIVOS PREEXISTENTES ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Crear archivos antes de lanzar el demonio (deben escanearse al iniciar):" -ForegroundColor White
Write-Host "  New-Item -ItemType Directory -Force -Path $env:TEMP\prueba_preexistentes" -ForegroundColor Cyan
Write-Host "  'clave secreta de acceso' | Out-File $env:TEMP\prueba_preexistentes\previo.txt" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_preexistentes -Palabras 'secreta,clave' -Log $env:TEMP\preexistentes.log" -ForegroundColor Cyan
Write-Host "  Start-Sleep 2; Get-Content $env:TEMP\preexistentes.log" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_preexistentes -Kill" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- DIRECTORIO CON ESPACIOS EN LA RUTA ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Directorio con espacios en el nombre:" -ForegroundColor White
Write-Host "  New-Item -ItemType Directory -Force -Path '$env:TEMP\prueba con espacios'" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio '$env:TEMP\prueba con espacios' -Palabras 'token' -Log $env:TEMP\espacios.log" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio '$env:TEMP\prueba con espacios' -Kill" -ForegroundColor Cyan
Write-Host ""

Write-Host "--- ALIAS DE PARÁMETROS ---" -ForegroundColor Yellow
Write-Host ""

Write-Host "Usar alias -p para -Palabras y -l para -Log:" -ForegroundColor White
Write-Host "  New-Item -ItemType Directory -Force -Path $env:TEMP\prueba_alias" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_alias -p 'admin,root' -l $env:TEMP\alias.log" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Directorio $env:TEMP\prueba_alias -k" -ForegroundColor Cyan
Write-Host ""

Write-Host "=============================================================================" -ForegroundColor Blue
