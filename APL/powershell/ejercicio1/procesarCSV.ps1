
param (
    [Alias("a")]
    [string]$archivo,

    [Alias("f")]
    [string]$filtro,

    [Alias("b")]
    [string]$buscar,

    [Alias("s")]
    [string]$sumar,

    [Alias("c")]
    [switch]$contar,

    [Alias("h")]
    [switch]$help
)

function Mostrar-Ayuda {
@"

Uso:
  ./procesarCSV.ps1 -a archivo.csv [opciones]

Descripción:
  Script para procesar archivos CSV, permitiendo filtrar registros,
  contar filas o sumar valores de una columna.

Parámetros:
  -a, -archivo   Archivo CSV de entrada (obligatorio)
  -f, -filtro    Nombre del campo para filtrar (opcional)
  -b, -buscar    Valor a buscar en el campo filtro (requerido si se usa -f)
  -c, -contar    Cuenta la cantidad de registros
  -s, -sumar     Suma los valores de un campo numérico
  -h, -help      Muestra esta ayuda
  
Reglas:
  - Debe indicar -c o -s (no ambos)
  - -b requiere -f
  - El filtro es opcional
  - Los nombres de columnas o valores pueden ser escritos tanto en minusculas como en mayusculas

Ejemplos:
  ./procesarCSV.ps1 -a censo.csv -c
  ./procesarCSV.ps1 -a censo.csv -f Ciudad -b "San" -c
  ./procesarCSV.ps1 -a clientes.csv -f Apellido -b "Perez" -s Saldo
  
  
"@
}

if ($help) {
    Mostrar-Ayuda
    exit 0
}

# =========================
# Validaciones
# =========================

if (-not $archivo) {
    Write-Host "Error: Debe indicar archivo con -a"
    exit 1
}

if (-not (Test-Path $archivo)) {
    Write-Host "Error: el archivo no existe"
    exit 1
}

if ($archivo -notlike "*.csv") {
    Write-Host "Error: el archivo debe tener extensión .csv"
    exit 1
}

if ($contar -and $sumar) {
    Write-Host "Error: no se puede usar -c y -s juntos"
    exit 1
}

if (-not $contar -and -not $sumar) {
    Write-Host "Error: debe usar -c o -s"
    exit 1
}

if ($filtro -and -not $buscar) {
    Write-Host "Error: si usa -f debe usar -b"
    exit 1
}

if ($buscar -and -not $filtro) {
    Write-Host "Error: -b requiere -f"
    exit 1
}

# =========================
# Lectura CSV
# =========================

$data = Import-Csv $archivo

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