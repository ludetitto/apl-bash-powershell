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
	
.PARAMETER -a, --archivo
    Especifica el archivo CSV de entrada. Este parámetro es obligatorio.

.PARAMETER -f, --filtro
    Especifica el campo sobre el cual se aplicará el filtro. Este parámetro es opcional, pero si se usa, debe ir acompañado de -b.

.PARAMETER -b, --buscar
    Especifica el valor a buscar en el campo indicado por -f. Este parámetro es opcional, pero si se usa, debe ir acompañado de -f.

.PARAMETER -c, --contar
    Indica que se desea contar la cantidad de registros que cumplen el filtro. No se puede usar junto con -s.

.PARAMETER -s, --sumar
    Indica que se desea sumar los valores de un campo numérico para los registros que cumplen el filtro. Requiere especificar el campo a sumar. No se puede usar junto con -c.

.EXAMPLE
		./procesarCSV.ps1 -a censo.csv -c
		Cuenta la cantidad total de registros en el archivo censo.csv.

.EXAMPLE
		./procesarCSV.ps1 -a censo.csv -f Ciudad -b "San" -c
		Cuenta la cantidad de registros donde el campo Ciudad contiene "San".

.EXAMPLE
		./procesarCSV.ps1 -a clientes.csv -f Apellido -b "Perez" -s Saldo
		Suma el campo Saldo para los registros donde el campo Apellido contiene "Perez".
	
#>

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

# =========================
# Validaciones generales
# =========================

if (-not $archivo) {
    Mostrar-Error "Error: debe indicar archivo con -a"
    exit 1
}

if (-not (Test-Path $Archivo -PathType Leaf)) {
    Mostrar-Error "Error: el archivo no existe"
}

if ([System.IO.Path]::GetExtension($Archivo).ToLower() -ne ".csv") {
    Mostrar-Error "Error: el archivo debe tener extensión .csv"
}

if ($contar -and $sumar) {
    Mostrar-Error "Error: no se puede usar -c y -s juntos"
    exit 1
}

if (-not $contar -and -not $sumar) {
    Mostrar-Error "Error: debe usar -c o -s"
    exit 1
}

if ($filtro -and -not $buscar) {
    Mostrar-Error "Error: si usa -f debe usar -b"
    exit 1
}

if ($buscar -and -not $filtro) {
    Mostrar-Error "Error: -b requiere -f"
    exit 1
}

# =========================
# Lectura CSV
# =========================

try {
    $data = Import-Csv $Archivo -ErrorAction Stop
}
catch {
    Mostrar-Error "Error: no se pudo leer el archivo '$Archivo'. Asegúrese de que el archivo existe y es un CSV válido."
    exit 1
}

$headers = $data[0].PSObject.Properties.Name | ForEach-Object { $_.ToLower() }

if ($filtro -and ($headers -notcontains $filtro.ToLower())) {
    Mostrar-Error "Error: campo de filtro no existe"
    exit 1
}

if ($sumar -and ($headers -notcontains $sumar.ToLower())) {
    Mostrar-Error "Error: campo de suma no existe"
    exit 1
}

# =========================
# Procesamiento
# =========================

$c = 0
$s = 0
$error_flag = $false

foreach ($row in $data) {

    if ($filtro) {
		$valorCampo = $row.$filtro
		if (-not ($valorCampo -eq $buscar)) {
			continue
		}
}

    if ($contar) {
        $c++
    }
    else {
        $valor = $row.$sumar

        if (-not ($valor -match '^-?[0-9]+(\.[0-9]+)?$')) {
            Mostrar-Error "Error: el campo '$sumar' contiene valores no numéricos."
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
    -Filtro $filtro `
    -Buscar $buscar `
    -Contar $contar `
    -Cantidad $c `
    -Suma $s