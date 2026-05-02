#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 5                                    #
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
    Obtiene información de personajes de Rick and Morty desde la API pública, con caching local para optimizar consultas repetidas.

.DESCRIPTION
    Este script permite obtener información detallada de personajes de la serie Rick and Morty utilizando la API pública (https://rickandmortyapi.com/). Se pueden buscar personajes por ID o por nombre. Para optimizar el rendimiento, el script implementa un sistema de caching local utilizando un archivo JSON para almacenar los datos de los personajes obtenidos y un archivo de log para registrar las consultas realizadas a la API. Si se solicita un personaje que ya está en la cache, se muestra la información desde el cache sin hacer una nueva consulta a la API. Además, se incluye una opción para limpiar la cache y el log.

.PARAMETER Id
    Uno o más IDs de personajes a consultar. Se pueden proporcionar múltiples IDs separadas por comas o espacios.

.PARAMETER Nombre
    Uno o más nombres de personajes a consultar. Se pueden proporcionar múltiples nombres separados por comas o espacios. La búsqueda por nombre es de tipo "contiene" (case-insensitive).

.PARAMETER Clear
    Opción para limpiar la cache de personajes y el log de consultas. No puede combinarse con las opciones de búsqueda (-Id, -Nombre).

.EXAMPLE
    .\rickandmorty.ps1 -Id 1
    Obtiene la información del personaje con ID 1 (Rick Sanchez) y la guarda en la cache.
.EXAMPLE
    .\rickandmorty.ps1 -Nombre "Morty"
    Obtiene la información de los personajes cuyo nombre contiene "Morty" (como Morty Smith) y la guarda en la cache.
.EXAMPLE
    .\rickandmorty.ps1 -Id 1,2,3 -Nombre "Rick"
    Obtiene la información de los personajes con IDs 1, 2 y 3, y de los personajes cuyo nombre contiene "Rick", mostrando la información desde la cache si ya fue consultada previamente.
.EXAMPLE
    .\rickandmorty.ps1 -Clear
    Limpia la cache de personajes y el log de consultas, eliminando los archivos "characters_cache.json" y "api_tracking.log" si existen.
#>

[CmdletBinding(DefaultParameterSetName = 'Buscar')]
param(
    [Parameter(ParameterSetName = 'Buscar')]
    [ValidateScript({ $_ -notmatch '^\s*$' -and $_ -gt 0 })]
    [Alias("i")]
    [int[]]$Id,
    
    [Parameter(ParameterSetName = 'Buscar')]
    [ValidateScript({ $_ -notmatch '^\s*$'})]
    [Alias("b")]
    [string[]]$Nombre,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Limpiar')]
    [Alias("c")]
    [switch]$Clear
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Validar-Parametros {
    if($Clear) {
        if(-not (Test-Path "characters_cache.json") -and -not (Test-Path "api_tracking.log")) {
            Write-Host "No se encontro cache de personajes para limpiar."
            exit 0
        }
        if(Test-Path "characters_cache.json") {
            Remove-Item "characters_cache.json" -ErrorAction SilentlyContinue
        } 
        if (Test-Path "api_tracking.log") {
            Remove-Item "api_tracking.log" -ErrorAction SilentlyContinue
        }

        Write-Host "Cache de personajes limpio."
        exit 0
    }
    if(-not $Id -and -not $Nombre) {
        Write-Host "No se han proporcionado argumentos validos."
        Write-Host "Use Get-Help para ver las opciones disponibles."
        exit 1
    }
}

# Funcion para crear los archivos necesarios
function Crear-Recursos {
    if(-Not (Test-Path "characters_cache.json")) {
        "[]" | Out-File -FilePath "characters_cache.json" -Encoding UTF8
    }

    if(-Not (Test-Path "api_tracking.log")) {
        "" | Out-File -FilePath "api_tracking.log" -Encoding UTF8
    }
}

# Funcion para mostrar la informacion de un personaje
function Mostrar-Personaje {
    param(
        [Parameter(Mandatory=$true)]
        $personaje
    )
    Write-Host "`nCharacter info:"
    Write-Host "    Id: $($personaje.id)"
    Write-Host "    Name: $($personaje.name)"
    Write-Host "    Status: $($personaje.status)"
    Write-Host "    Species: $($personaje.species)"
    Write-Host "    Gender: $($personaje.gender)"
    Write-Host "    Origin: $($personaje.origin.name)"
    Write-Host "    Location: $($personaje.location.name)"
    Write-Host "    Episodes: $($personaje.episode.Count)"
}

function Mostrar-Personaje-Cache {
    param(
        [Parameter(Mandatory=$true)]
        $personaje
    )
    Write-Host "`nCharacter info:"
    Write-Host "    Id: $($personaje.id)"
    Write-Host "    Name: $($personaje.name)"
    Write-Host "    Status: $($personaje.status)"
    Write-Host "    Species: $($personaje.species)"
    Write-Host "    Gender: $($personaje.gender)"
    Write-Host "    Origin: $($personaje.origin)"
    Write-Host "    Location: $($personaje.location)"
    Write-Host "    Episodes: $($personaje.episodes)"
}

# Funcion para buscar personajes en la cache o verificar en el log según el tipo
function Buscar-En-Cache {
    param(
        [string]$tipo,
        [string]$valor
    )

    $cacheFile = "characters_cache.json"

    $contenido = Get-Content $cacheFile -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($contenido)) {
        return $null
    }

    $cache = $contenido | ConvertFrom-Json -ErrorAction SilentlyContinue

    if($tipo -eq "id") {
        # Para ID: buscar en characters_cache.json
        foreach($personaje in $cache) {
            if ($personaje.id -eq [int]$valor) {
                Mostrar-Personaje-Cache $personaje
                return $true
            }
        }
    } elseif($tipo -eq "nombre") {
        # Para nombre: buscar primero en api_tracking.log y luego en characters_cache.json
        $existe = $false

        $logFile = "api_tracking.log"

        $contenidoLog = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($contenido)) {
            return $null
        }

        $logs = Get-Content "api_tracking.log" -Raw | ConvertFrom-Json

        $encontrado = $logs | Where-Object {
            $_.tipo -eq "nombre" -and $_.valor -like "*$valor*"
        }

        if ($encontrado) {
            foreach ($personaje in $cache) {
                if ($personaje.name -like "*$valor*") {
                    Mostrar-Personaje-Cache $personaje
                }
            }
            return $true
        }
    }

    return $false
}

# Funcion para guardar personajes en la cache
function Guardar-En-Cache {
    param(
        [Parameter(Mandatory=$true)]
        $personaje
    )
    $personaje = @{
        id = $personaje.id
        name = $personaje.name
        status = $personaje.status
        species = $personaje.species
        gender = $personaje.gender
        origin = $personaje.origin.name
        location = $personaje.location.name
        episodes = if ($personaje.episode -is [array]) { $personaje.episode.Length } elseif ($personaje.episode) { 1 } else { 0 }
    }
    
    $contenido = Get-Content "characters_cache.json" -Raw -ErrorAction SilentlyContinue
    $cacheArray = @()
    
    if (-not [string]::IsNullOrWhiteSpace($contenido) -and $contenido -ne "[]") {
        try {
            $parsed = $contenido | ConvertFrom-Json -ErrorAction Stop
            if ($parsed -is [array]) {
                $cacheArray = @($parsed)
            } elseif ($parsed.id) {
                $cacheArray = @($parsed)
            }
        } catch {
            $cacheArray = @()
        }
    }
    
    # Verificar si el personaje ya existe en la cache por ID
    $existe = $false
    foreach ($item in $cacheArray) {
        if ($item.id -eq $personaje.id) {
            $existe = $true
            break
        }
    }
    
    # Solo agregar si no existe
    if (-not $existe) {
        $cacheArray += $personaje
        # Siempre guardar como un array JSON válido
        $json = $cacheArray | ConvertTo-Json -Compress
        $json | Set-Content "characters_cache.json" -Encoding UTF8
    }
}

# Funcion para obtener personajes por ID
function Obtener-Personaje-Por-ID {
    param(
        [int[]]$ids
    )
    
    foreach($idItem in $ids) {
        $idItem = $idItem.ToString().Trim()
        if(-not $idItem) { continue }
        
        if(-not (Buscar-En-Cache "id" $idItem)) {

            $uri = "https://rickandmortyapi.com/api/character/$idItem"
            
            try {
                $response = Invoke-RestMethod -Uri $uri -TimeoutSec 10 -ErrorAction Stop
                
                if($response) {
                    Mostrar-Personaje $response
                    Guardar-En-Cache $response
                }
                    
                $log = @{
                    timestamp = (Get-Date).ToString("o")
                    tipo = "id"
                    valor = $idItem
                    endpoint = "/api/character/$idItem"
                }

                Registrar-Consulta-API $log
            }
            catch {
                Write-Host "Error al obtener personaje con ID $idItem : $_"
            }
        }
    }
}

# Funcion para obtener personajes por nombre
function Obtener-Personaje-Por-Nombre {
    param(
        [string[]]$nombres
    )

    foreach($nombre in $nombres) {
        $nombre = $nombre.Trim()
        if(-not $nombre) { continue }
        
        if(-not (Buscar-En-Cache "nombre" $nombre)) {
            $uri = "https://rickandmortyapi.com/api/character/?name=$nombre"
            
            try {
                $response = Invoke-RestMethod -Uri $uri -TimeoutSec 10 -ErrorAction Stop
                
                if($response.results) {
                    foreach($personaje in $response.results) {
                        Mostrar-Personaje $personaje
                        Guardar-En-Cache $personaje
                    }
                    
                    $log = @{
                        timestamp = (Get-Date).ToString("o")
                        tipo = "nombre"
                        valor = $nombre
                        endpoint = "/api/character/?name=$nombre"
                    }

                    Registrar-Consulta-API $log
                }
            }
            catch {
                Write-Host "Error al obtener personaje con nombre $nombre : $_"
            }
        }
    }
}

# Funcion para registrar consultas a la API
function Registrar-Consulta-API {
    param(
        [Parameter(Mandatory=$true)]
        $logEntry
    )
    
    $logs = @()
    
    $contenido = Get-Content "api_tracking.log" -Raw -ErrorAction SilentlyContinue

    if ($contenido) {
        $parsed = $contenido | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed -is [array]) {
            $logs = @($parsed)
        } elseif ($parsed) {
            $logs = @($parsed)
        }
    }

    $logs += $logEntry
    $logs | ConvertTo-Json -Compress | Set-Content "api_tracking.log" -Encoding UTF8
}

# Función para mostrar la ruta de los archivos utilizados
function Mostrar-Path-Archivos {
    Write-Host "`nINFO: Ruta de archivos utilizados:"
    Write-Host "    Cache de personajes: $(Get-Item "characters_cache.json").FullName"
    Write-Host "    Log de consultas a la API: $(Get-Item "api_tracking.log").FullName`n"
}

# Funcionamiento del script
Validar-Parametros
Crear-Recursos

if($id) {
    Write-Host "`nINFO: Obteniendo personajes por ID: $($id -join ',')"
    Obtener-Personaje-Por-ID $id
}
if($nombre) {
    Write-Host "`nINFO: Obteniendo personajes por nombre: $($nombre -join ',')"
    Obtener-Personaje-Por-Nombre $nombre
}

Mostrar-Path-Archivos