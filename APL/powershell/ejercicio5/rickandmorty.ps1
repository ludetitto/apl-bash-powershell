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
    [Parameter(ParameterSetName = 'Consultar')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ $_ -gt 0 })]
    [Alias("i")]
    [int[]]$Id,
    
    [ValidateNotNullOrEmpty()]
    [Parameter(ParameterSetName = 'Consultar')]
    [Alias("b")]
    [string[]]$Nombre,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Limpiar')]
    [Alias("c")]
    [switch]$Clear
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Validar-Parametros {
    if(!$Id -and !$Nombre -and !$Clear) {
        throw "Error: Debe proporcionar al menos una opción de búsqueda (-Id o -Nombre) o la opción de limpieza (-Clear). Use -Help para más información."
    }

    if($Clear) {
        if(-not (Test-Path "cache")) {
            throw "No se encontro cache de personajes para limpiar."
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
        $PERSONAJES
    )

    foreach($PERSONAJE in $PERSONAJES) {
        Write-Host "`nCharacter info:"
        Write-Host "    Id: $($PERSONAJE.id)"
        Write-Host "    Name: $($PERSONAJE.name)"
        Write-Host "    Status: $($PERSONAJE.status)"
        Write-Host "    Species: $($PERSONAJE.species)"
        Write-Host "    Gender: $($PERSONAJE.gender)"
        Write-Host "    Origin: $($PERSONAJE.origin.name)"
        Write-Host "    Location: $($PERSONAJE.location.name)"
        Write-Host "    Episodes: $($PERSONAJE.episode.Count)"
    }
}

# Funcion para buscar personajes en la cache o verificar en el log según el tipo
function Buscar-En-Cache {
    param(
        [string]$TIPO,
        [string]$VALOR
    )

    if (Test-Path "cache/$TIPO/$VALOR")
    {
        $CACHE = Get-Content "cache/$TIPO/$VALOR" -Raw | ConvertFrom-Json
        Mostrar-Personaje $CACHE
        return $true
    }

    return $false
}

# Funcion para validar la respuesta de la API
function Validar-Respuesta {
    param(
        [int]$HTTP_CODE
    )

    if($HTTP_CODE -eq 0 -or -not $HTTP_CODE) {
        Write-Host "Error: No se pudo conectar a la API. Verifique su conexion a internet."
    }
    
    if($HTTP_CODE -eq 404) {
        Write-Host "Error: No se encontraron personajes que coincidan con la consulta."
    }
    
    if($HTTP_CODE -ge 500) {
        Write-Host "Error: La API del servidor no esta disponible (HTTP $HTTP_CODE)."
    }
    
    if($HTTP_CODE -ne 200) {
        Write-Host "Error: La API devolvio un error HTTP $HTTP_CODE."
    }
}

# Funcion para obtener personajes por ID
function Obtener-Personaje-Por-ID {
    param(
        [int[]]$IDS
    )
    
    foreach($ID_ITEM in $IDS) {
        $ID_ITEM = $ID_ITEM.ToString().Trim()
        if(-not $ID_ITEM) { continue }
        
        if(-not (Buscar-En-Cache "id" $ID_ITEM)) {
            $URI = "https://rickandmortyapi.com/api/character/$ID_ITEM"
            
            try {
                $RESPONSE = Invoke-WebRequest -Uri $URI -TimeoutSec 10 -ErrorAction Stop
                $HTTP_CODE = $RESPONSE.StatusCode
                
                $CONTENT = $RESPONSE.Content | ConvertFrom-Json
                Mostrar-Personaje $CONTENT
                $CONTENT | ConvertTo-Json | Out-File "./cache/id/$ID_ITEM" -Encoding UTF8
            }
            catch [System.Net.Http.HttpRequestException] {
                if($_.Exception.Response) {
                    $HTTP_CODE = $_.Exception.Response.StatusCode -as [int]
                }
                Validar-Respuesta $HTTP_CODE
            }
            catch [System.Net.WebException] {
                Validar-Respuesta 0
            }
        }
    }
}

# Funcion para obtener personajes por nombre
function Obtener-Personaje-Por-Nombre {
    param(
        [string[]]$NOMBRES
    )

    foreach($NOMBRE in $NOMBRES) {
        $NOMBRE = $NOMBRE.Trim()
        if(-not $NOMBRE) { continue }
        
        if(-not (Buscar-En-Cache "nombre" $NOMBRE)) {
            $URI = "https://rickandmortyapi.com/api/character/?name=$NOMBRE"
            
            try {
                $RESPONSE = Invoke-WebRequest -Uri $URI -TimeoutSec 10 -ErrorAction Stop
                $HTTP_CODE = $RESPONSE.StatusCode
                
                $CONTENT = $RESPONSE.Content | ConvertFrom-Json
                if($CONTENT.results) {
                    foreach($PERSONAJE in $CONTENT.results) {
                        Mostrar-Personaje $PERSONAJE
                    }
                    $CONTENT.results | ConvertTo-Json | Out-File "./cache/nombre/$NOMBRE" -Encoding UTF8
                }
            }
            catch [System.Net.Http.HttpRequestException] {
                if($_.Exception.Response) {
                    $HTTP_CODE = $_.Exception.Response.StatusCode -as [int]
                }
                Validar-Respuesta $HTTP_CODE
            }
            catch [System.Net.WebException] {
                Validar-Respuesta 0
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