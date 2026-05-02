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
    [Alias("a")]
    [string]$Archivo,

    [Alias("f")]
    [string]$Filtro,

    [Alias("b")]
    [string]$Buscar,

    [Alias("s")]
    [string]$Sumar,

    [Alias("c")]
    [switch]$Contar
)

# =========================
# Validaciones
# =========================

if (-not $Archivo) {
    Write-Host "Error: Debe indicar archivo con -a"
    exit 1
}

if (-not (Test-Path $Archivo)) {
    Write-Host "Error: el archivo no existe"
    exit 1
}

if ($Archivo -notlike "*.csv") {
    Write-Host "Error: el archivo debe tener extensión .csv"
    exit 1
}

if ($Contar -and $Sumar) {
    Write-Host "Error: no se puede usar -c y -s juntos"
    exit 1
}

if (-not $Contar -and -not $Sumar) {
    Write-Host "Error: debe usar -c o -s"
    exit 1
}

if ($Filtro -and -not $Buscar) {
    Write-Host "Error: si usa -f debe usar -b"
    exit 1
}

if ($Buscar -and -not $Filtro) {
    Write-Host "Error: -b requiere -f"
    exit 1
}

# =========================
# Lectura CSV
# =========================

$data = Import-Csv $Archivo

if (-not $data) {
    Write-Host "Error: el archivo está vacío o no es válido"
    exit 1
}

$headers = $data[0].PSObject.Properties.Name | ForEach-Object { $_.ToLower() }

if ($filtro -and ($headers -notcontains $filtro.ToLower())) {
    Write-Host "Error: campo de filtro no existe"
    exit 1
}

if ($sumar -and ($headers -notcontains $sumar.ToLower())) {
    Write-Host "Error: campo de suma no existe"
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
            Write-Host ""
            Write-Host "Error: el campo '$sumar' contiene valores no numéricos."
            Write-Host ""
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