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

$SCRIPT = ".\rickandmorty.ps1"

Write-Host ""
Write-Host "=============================================================================" -ForegroundColor Blue
Write-Host "Lote de Pruebas - Rick and Morty (PowerShell)" -ForegroundColor Blue
Write-Host "=============================================================================" -ForegroundColor Blue
Write-Host ""

Write-Host "AYUDA" -ForegroundColor Yellow
Write-Host "  $SCRIPT -?" -ForegroundColor Cyan
Write-Host "  Get-Help $SCRIPT" -ForegroundColor Cyan
Write-Host ""

Write-Host "BÚSQUEDA POR ID" -ForegroundColor Yellow
Write-Host "  $SCRIPT -Id 1" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Id 1, 2, 3" -ForegroundColor Cyan
Write-Host "  $SCRIPT -i 1" -ForegroundColor Cyan
Write-Host ""

Write-Host "BÚSQUEDA POR NOMBRE" -ForegroundColor Yellow
Write-Host "  $SCRIPT -Nombre rick" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Nombre rick, morty" -ForegroundColor Cyan
Write-Host "  $SCRIPT -b 'rick sanchez'" -ForegroundColor Cyan
Write-Host ""

Write-Host "BÚSQUEDA COMBINADA" -ForegroundColor Yellow
Write-Host "  $SCRIPT -Id 1 -Nombre rick" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Id 1, 2 -Nombre rick, morty" -ForegroundColor Cyan
Write-Host ""

Write-Host "VALIDACIÓN DE ERRORES" -ForegroundColor Yellow
Write-Host "  $SCRIPT                      # sin argumentos" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Clear -Id 1         # conflicto de parámetros" -ForegroundColor Cyan
Write-Host ""

Write-Host "GESTIÓN DE CACHÉ" -ForegroundColor Yellow
Write-Host "  $SCRIPT -Id 1                # primera búsqueda" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Id 1                # segunda búsqueda (desde caché)" -ForegroundColor Cyan
Write-Host "  Dir .\cache\id" -ForegroundColor Cyan
Write-Host "  Get-Content .\cache\id\1" -ForegroundColor Cyan
Write-Host "  $SCRIPT -Clear               # limpiar caché" -ForegroundColor Cyan
Write-Host ""

Write-Host "=============================================================================" -ForegroundColor Blue
