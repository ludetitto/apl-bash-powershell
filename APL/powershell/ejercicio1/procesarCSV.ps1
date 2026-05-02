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

.PARAMETER Archivo
   Archivo de entrada en formato CSV. El archivo debe tener una fila de encabezado con los nombres de las columnas.

.PARAMETER Filtro
    Nombre del campo a usar como filtro. Requiere el parámetro -Buscar.

.PARAMETER Buscar
    Valor a buscar en el campo indicado por -Filtro.

.PARAMETER Sumar
    Nombre del campo numérico a sumar. No puede usarse junto con -Contar.

.PARAMETER Contar
    Indica que se desea contar la cantidad de registros que cumplen el filtro.

.EXAMPLE
    .\procesarCSV.ps1 -a censo.csv -c
    Cuenta la cantidad total de registros en el archivo censo.csv.

.EXAMPLE
    .\procesarCSV.ps1 -a censo.csv -f Ciudad -b "San" -c
    Cuenta la cantidad de registros donde el campo Ciudad contiene "San".

.EXAMPLE
    .\procesarCSV.ps1 -a clientes.csv -f Apellido -b "Perez" -s Saldo
    Suma el campo Saldo para los registros donde el campo Apellido contiene "Perez".
#>

param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Sumar')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Contar')]
    [ValidateScript({ 
        if(Test-Path $_ -PathType Leaf) { 
            $true 
        } else { 
            throw "El archivo '$_' no existe." 
            } 
        if([System.IO.Path]::GetExtension($_) -ne ".csv") {
            throw "El archivo '$_' no tiene extensión .csv."
        }
        })]
    [Alias("a")]
    [string]$Archivo,

    [Alias("f")]
    [string]$Filtro,

    [Alias("b")]
    [string]$Buscar,

    [Parameter(Mandatory = $true, ParameterSetName = 'Sumar')]
    [Alias("s")]
    [string]$Sumar,

    [Parameter(Mandatory = $true, ParameterSetName = 'Contar')]
    [Alias("c")]
    [switch]$Contar
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# =========================
# Validaciones
# =========================

if ($Filtro -and -not $Buscar) {
    Write-Error "Error: si usa -f debe usar -b"
    exit 1
}

if ($Buscar -and -not $Filtro) {
    Write-Error "Error: -b requiere -f"
    exit 1
}

# =========================
# Lectura CSV
# =========================

try {
    $data = Import-Csv $Archivo -ErrorAction Stop
}
catch {
    Write-Error "Error: no se pudo leer el archivo '$Archivo'. Asegúrese de que el archivo existe y es un CSV válido."
    exit 1
}

$headers = $data[0].PSObject.Properties.Name | ForEach-Object { $_.ToLower() }

if ($filtro -and ($headers -notcontains $filtro.ToLower())) {
    Write-Error "Error: campo de filtro no existe"
    exit 1
}

if ($sumar -and ($headers -notcontains $sumar.ToLower())) {
    Write-Error "Error: campo de suma no existe"
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
        if (-not ($valorCampo.ToLower() -match $buscar.ToLower())) {
            continue
        }
    }

    if ($contar) {
        $c++
    }
    else {
        $valor = $row.$sumar

        if (-not ($valor -match '^-?[0-9]+(\.[0-9]+)?$')) {
            Write-Error "Error: el campo '$sumar' contiene valores no numéricos."
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

Write-Host ""
Write-Host "-----------------------------"

if ($filtro) {
    Write-Host "Filtro aplicado: '$filtro' = '$buscar'"
}
else {
    Write-Host "Filtro aplicado: ninguno"
    Write-Host ""
}

if ($contar) {
    if ($c -eq 0) {
        Write-Host "Resultados:"
        Write-Host "No se encontraron registros"
    }
    else {
        Write-Host "Resultados:"
        Write-Host "Cantidad de registros = $c"
    }
}
else {
    if ($c -eq 0) {
        Write-Host "Resultado:"
		Write-Host "No se encontraron registros para sumar"
    }
    else {
        $s = [math]::Round($s, 2)
        Write-Host "Resultados:"
		Write-Host "Suma total = $s"
    }
}

Write-Host "-----------------------------"
Write-Host ""