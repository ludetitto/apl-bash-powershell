<#
.SYNOPSIS
    Detecta archivos duplicados en un directorio y sus subdirectorios.

.DESCRIPTION
    El script busca archivos que tengan el mismo nombre y tamanio dentro
    de un directorio dado, incluyendo todos sus subdirectorios, y muestra
    un listado con los duplicados encontrados y sus ubicaciones.

.PARAMETER directorio
    Ruta del directorio a analizar. Puede ser relativa o absoluta.

.EXAMPLE
    .\ejercicio3.ps1 -directorio "C:\Users\Usuario\Documentos"

.NOTES
    Materia: Virtualizacion de Hardware (3654) - UNLaM 2026
    Integrantes:
        - Francisco, Vladimir
        - Nombre Apellido
        - Nombre Apellido
        - Nombre Apellido
        - Nombre Apellido
#>
param(
    [Parameter(Mandatory=$true, HelpMessage="Ingrese la ruta del directorio a analizar (sin comillas)")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        if (-not (Test-Path $_ -PathType Container)) {
            throw "El directorio '$_' no existe o no es valido."
        }
        $true
    })]
    [string]$directorio
)

try {
    Get-ChildItem -Path $directorio -ErrorAction Stop | Out-Null
} catch {
    Write-Error "No tenes permisos de lectura sobre '$directorio'."
    exit 1
}

function BuscarDuplicados {
    $tabla = @{}

    $archivos = Get-ChildItem -Path $directorio -Recurse -File

    foreach ($archivo in $archivos) {
        $clave = "$($archivo.Name):$($archivo.Length)"
        $dir = $archivo.DirectoryName

        if ($tabla.ContainsKey($clave)) {
            $tabla[$clave] += "|$dir"
        } else {
            $tabla[$clave] = $dir
        }
    }

    $hayDuplicados = $false

    foreach ($clave in $tabla.Keys) {
        $directorios = $tabla[$clave]
        $cantidad = ($directorios -split "\|").Count

        if ($cantidad -ge 2) {
            $hayDuplicados = $true
            $nombre = $clave -split ":" | Select-Object -First 1

            Write-Host "archivo: $nombre"
            foreach ($dir in ($directorios -split "\|")) {
                Write-Host "  directorio: $dir"
            }
            Write-Host ""
        }
    }

    if (-not $hayDuplicados) {
        Write-Host "No se encontraron archivos duplicados en '$directorio'."
    }
}

BuscarDuplicados