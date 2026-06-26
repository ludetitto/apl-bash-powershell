#!/usr/bin/env pwsh

#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 1                                    #
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
    Script para procesar archivos CSV, permitiendo filtrar registros, contar filas o sumar valores de una columna.

.DESCRIPTION
    Este script permite analizar un archivo CSV aplicando un filtro de texto sobre un campo específico. 
    Luego, dependiendo de la opción elegida, puede contar la cantidad de registros que cumplen el filtro o sumar los valores de un campo numérico para esos registros.
    El filtro es de tipo "contiene" y no distingue mayúsculas de minúsculas.

.PARAMETER archivo
    Archivo CSV de entrada. Soporta el alias -a.

.PARAMETER filtro
    Campo de la columna para filtrar. Soporta el alias -f.

.PARAMETER buscar
    Valor a buscar dentro del campo especificado. Soporta el alias -b.

.PARAMETER sumar
    Suma un campo numérico de los resultados obtenidos. Soporta el alias -s.

.PARAMETER contar
    Cuenta la cantidad de registros. Es un parámetro de tipo switch. Soporta el alias -c.

.EXAMPLE
    ./procesarCSV.ps1 -a censo.csv -c
    Cuenta la cantidad total de registros en el archivo censo.csv.

.EXAMPLE
    ./procesarCSV.ps1 -a censo.csv -f Ciudad -b "San" -c
    Cuenta la cantidad de registros donde el campo Ciudad contiene "San".

.EXAMPLE
    ./procesarCSV.ps1 -archivo clientes.csv -filtro Apellido -buscar "Perez" -sumar Saldo
    Suma el campo Saldo para los registros donde el campo Apellido contiene "Perez" (usando el nombre completo del parámetro).
#>

<<<<<<< Updated upstream
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [Alias("a")]
    [string]$Archivo,

    [Parameter(Mandatory=$false)]
    [Alias("f")]
    [string]$Filtro,

    [Parameter(Mandatory=$false)]
    [Alias("b")]
    [string]$Buscar,

    [Parameter(Mandatory=$false)]
    [Alias("s")]
    [string]$Sumar,

    [Parameter(Mandatory=$false)]
    [Alias("c")]
=======
[CmdletBinding(PositionalBinding=$false)]
param (
    [Parameter(Mandatory=$true)]
    [Alias('a')]
    [string]$Archivo,

    [Alias('f')]
    [string]$Filtro = "",

    [Alias('b')]
    [string]$Buscar = "",

    [Alias('s')]
    [string]$Sumar = "",

    [Alias('c')]
>>>>>>> Stashed changes
    [switch]$Contar
)

# =========================
# Funciones
# =========================

function Mostrar-Error {
    param (
        [string]$Mensaje
    )

    Write-Host $Mensaje -ForegroundColor Red
    exit 1
}

function Mostrar-Resultados {
    param (
        [string]$Filtro,
        [string]$Buscar,
        [bool]$Contar,
        [int]$Cantidad,
        [double]$Suma
    )

    Write-Host ""
    Write-Host "-----------------------------" -ForegroundColor Cyan

    if ($Filtro) {
        Write-Host "Filtro aplicado: '$Filtro' = '$Buscar'"
    }
    else {
        Write-Host "Filtro aplicado: ninguno"
        Write-Host ""
    }

    if ($Contar) {
        if ($Cantidad -eq 0) {
            Write-Host "Resultados:"
            Write-Host "No se encontraron registros"
        }
        else {
            Write-Host "Resultados:"
            Write-Host "Cantidad de registros = $Cantidad"
        }
    }
    else {
        if ($Cantidad -eq 0) {
            Write-Host "Resultado:"
            Write-Host "No se encontraron registros para sumar"
        }
        else {
            Write-Host "Resultados:"
            Write-Host ("Suma total = {0:F2}" -f $Suma)
        }
    }

    Write-Host "-----------------------------" -ForegroundColor Cyan
    Write-Host ""
}

<<<<<<< Updated upstream
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

=======
>>>>>>> Stashed changes
# =========================
# Validaciones generales
# =========================

# Se mantiene la lógica de errores customizada para no alterar los mensajes que el usuario recibe
if (-not $Archivo) {
    Mostrar-Error "Error: debe indicar archivo con -a"
}

if (-not (Test-Path $Archivo -PathType Leaf)) {
    Mostrar-Error "Error: el archivo no existe"
}

if ([System.IO.Path]::GetExtension($Archivo).ToLower() -ne ".csv") {
    Mostrar-Error "Error: el archivo debe tener extensión .csv"
}

if ($Contar -and $Sumar) {
    Mostrar-Error "Error: no se puede usar -c y -s juntos"
}

if (-not $Contar -and -not $Sumar) {
    Mostrar-Error "Error: debe usar -c o -s"
}

if ($Filtro -and -not $Buscar) {
    Mostrar-Error "Error: si usa -f debe usar -b"
}

if ($Buscar -and -not $Filtro) {
    Mostrar-Error "Error: -b requiere -f"
}

# =========================
# Lectura CSV
# =========================

try {
    $data = Import-Csv $Archivo -ErrorAction Stop
}
catch {
    Mostrar-Error "Error: no se pudo leer el archivo '$Archivo'. Asegúrese de que el archivo existe y es un CSV válido."
}

$headers = $data[0].PSObject.Properties.Name | ForEach-Object { $_.ToLower() }

if ($Filtro -and ($headers -notcontains $Filtro.ToLower())) {
    Mostrar-Error "Error: campo de filtro no existe"
}

if ($Sumar -and ($headers -notcontains $Sumar.ToLower())) {
    Mostrar-Error "Error: campo de suma no existe"
}

# =========================
# Procesamiento
# =========================

$c = 0
$s = 0
$error_flag = $false

foreach ($row in $data) {

<<<<<<< Updated upstream
    if ($Filtro) {
        $valorCampo = $row.$Filtro
        if (-not ($valorCampo.ToLower() -match $Buscar.ToLower())) {
            continue
        }
    }
=======
    if ($filtro) {
		$valorCampo = $row.$filtro
		if (-not ($valorCampo -eq $buscar)) {
			continue
		}
}
>>>>>>> Stashed changes

    if ($Contar) {
        $c++
    }
    else {
        $valor = $row.$Sumar

        if (-not ($valor -match '^-?[0-9]+(\.[0-9]+)?$')) {
            Mostrar-Error "Error: el campo '$Sumar' contiene valores no numéricos."
            $error_flag = $true
            break
        }

        $s += [double]$valor
        $c++
    }
}

if ($error_flag) {
    exit 1
}

# =========================
# Salida
# =========================

Mostrar-Resultados `
    -Filtro $Filtro `
    -Buscar $Buscar `
    -Contar $Contar `
    -Cantidad $c `
    -Suma $s