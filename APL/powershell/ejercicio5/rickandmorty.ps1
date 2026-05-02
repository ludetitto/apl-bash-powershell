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

param(
    [Parameter(ParameterSetName = 'ID')]
    [ValidateScript({ $_ -gt 0 })]
    [Alias("i")]
    [int[]]$Id,
    
    [Parameter(ParameterSetName = 'Nombre')]
    [ValidateNotNullOrEmpty()]
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
        if(-not (Test-Path "cache")) {
            Write-Host "No se encontro cache de personajes para limpiar."
            exit 0
        }
        if(Test-Path "cache") {
            Remove-Item "cache" -Recurse -ErrorAction SilentlyContinue
        }
        if (Test-Path "api_tracking.log") {
            Remove-Item "api_tracking.log" -ErrorAction SilentlyContinue
        }

        Write-Host "Cache de personajes limpio."
        exit 0
    }
}

# Funcion para crear los archivos necesarios
function Crear-Recursos {
    if(-Not (Test-Path  "cache")) {
        New-Item -ItemType Directory -Name "cache" | Out-Null
        New-Item -ItemType Directory -Path "cache/id" | Out-Null
        New-Item -ItemType Directory -Path "cache/nombre" | Out-Null
    }
}

# Funcion para mostrar la informacion de un personaje
function Mostrar-Personaje {
    param(
        [Parameter(Mandatory=$true)]
        $personajes
    )

    foreach($personaje in $personajes) {
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
}

# Funcion para buscar personajes en la cache o verificar en el log según el tipo
function Buscar-En-Cache {
    param(
        [string]$tipo,
        [string]$valor
    )

    if (Test-Path "cache/$tipo/$valor")
    {
        $cache = Get-Content "cache/$tipo/$valor" -Raw | ConvertFrom-Json
        Mostrar-Personaje $cache
        return $true
    }

    return $false
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
                    $response | ConvertTo-Json | Out-File "./cache/id/$idItem" -Encoding UTF8
                }
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
                    }
                    $response.results | ConvertTo-Json | Out-File "./cache/nombre/$nombre" -Encoding UTF8
                }
            }
            catch {
                Write-Host "Error al obtener personaje con nombre $nombre : $_"
            }
        }
    }
}

# Función para mostrar la ruta de los archivos utilizados
function Mostrar-Path-Cache {
    Write-Host "`nINFO: Ruta de cache"
    Write-Host "    Cache de personajes: .\cache"
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

Mostrar-Path-Cache