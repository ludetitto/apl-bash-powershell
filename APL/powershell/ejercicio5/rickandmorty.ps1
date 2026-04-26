
param(
    [int[]]$id,
    [string[]]$nombre,
    [switch]$help,
    [switch]$clear
)
function Validar-Parametros {
    if($help) {
        Write-Host "
        NOMBRE
            rickandmorty.sh - busca personajes de Rick and Morty.

        SINOPSIS
            rickandmorty.sh [OPCIONES]

        DESCRIPCION
            Consulta la API de Rick and Morty para obtener informacion sobre personajes.
            Los datos se cachean localmente en el directorio actual para optimizar las consultas posteriores.

        ARCHIVOS
            characters_cache.txt
                Base de datos local de personajes consultados.
            
            api_tracking.log
                Registro de todas las consultas realizadas a la API.

        OPCIONES
            -i, --id [IDs]
                ID/s de los personajes a buscar. Acepta mÃºltiples IDs separados por comas.
                Ejemplo: ./rickandmorty.sh --id 1,2,3
                        ./rickandmorty.sh -i 1

            -n, --nombre [NOMBRES]
                Nombre/s de los personajes a buscar. Acepta mÃºltiples nombres separados 
                por comas. No es sensible a mayÃºsculas/minÃºsculas.
                Ejemplo: ./rickandmorty.sh --nombre rick,morty
                        ./rickandmorty.sh -n rick

            -c, --clear
                Limpia el cache de personajes guardado. No puede utilizarse junto con
                opciones de busqueda (-i, -n, --id, --nombre).
                Ejemplo: ./rickandmorty.sh --clear

            -h, --help
                Muestra este mensaje de ayuda.

        EJEMPLOS
            # Busqueda por ID
            ./rickandmorty.sh -i 1
            ./rickandmorty.sh --id 1,2,3

            # Busqueda por nombre
            ./rickandmorty.sh -n rick
            ./rickandmorty.sh --nombre rick,morty

            # Busqueda combinada
            ./rickandmorty.sh -i 1 -n rick

            # Limpiar cache
            ./rickandmorty.sh --clear
        "
        exit 0
    }
    elseif($clear) {
        if($id -or $nombre) {
            Write-Host "Error: La opcion --clear no puede combinarse con opciones de busqueda (-id, -nombre)"
            exit 1
        }
        if(Test-Path "characters_cache.json") {
            Remove-Item "characters_cache.json" -ErrorAction SilentlyContinue
        } 
        if (Test-Path "api_tracking.log") {
            Remove-Item "api_tracking.log" -ErrorAction SilentlyContinue
        }
        if(-not (Test-Path "characters_cache.json") -and -not (Test-Path "api_tracking.log")) {
            Write-Host "No se encontro cache de personajes para limpiar."
        }
        Write-Host "Cache de personajes limpio."
        exit 0
    }
    if(-not $id -and -not $nombre) {
        Write-Host "Error: No se han proporcionado argumentos validos. Use --help para ver las opciones disponibles."
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
    Write-Host "Character info:"
    Write-Host "  Id: $($personaje.id)"
    Write-Host "  Name: $($personaje.name)"
    Write-Host "  Status: $($personaje.status)"
    Write-Host "  Species: $($personaje.species)"
    Write-Host "  Gender: $($personaje.gender)"
    Write-Host "  Origin: $($personaje.origin.name)"
    Write-Host "  Location: $($personaje.location.name)"
    Write-Host "  Episodes: $($personaje.episode.Count)"
}

# Funcion para buscar personajes en la cache, una vez que se sabe que fue consultado previamente a la API
function Buscar-En-Cache {
    param(
        [string]$tipo,
        [string]$valor
    )

    $contenido = Get-Content "characters_cache.json" -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($contenido) -or $contenido -eq "[]") {
        return $false
    }
    
    $cache = @($contenido | ConvertFrom-Json -ErrorAction SilentlyContinue)
    
    if($tipo -eq "ID") {
        $personajes = @($cache | Where-Object { $_.id -eq [int]$valor })
    } else {
        $personajes = @($cache | Where-Object { $_.name -like "*$valor*" })
    }

    if($personajes.Count -gt 0) {
        foreach($p in $personajes) { 
            Mostrar-Personaje $p 
        }
        return $true
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
                $cacheArray = $parsed | Where-Object { $_.id }
            } elseif ($parsed.id) {
                $cacheArray = @($parsed)
            }
        } catch {
            $cacheArray = @()
        }
    }
    
    $cacheArray += $personaje
    $json = $cacheArray | ConvertTo-Json -Compress
    $json | Set-Content "characters_cache.json" -Encoding UTF8
}

# Funcion para obtener personajes por ID
function Obtener-Personaje-Por-ID {
    param(
        [int[]]$ids
    )
    
    foreach($idItem in $ids) {
        $idItem = $idItem.ToString().Trim()
        if(-not $idItem) { continue }
        
        if(-not (Buscar-En-Cache "ID" $idItem)) {

            $uri = "https://rickandmortyapi.com/api/character/$idItem"
            
            try {
                $response = Invoke-RestMethod -Uri $uri -TimeoutSec 10 -ErrorAction Stop
                
                if($response) {
                    Mostrar-Personaje $response
                    Guardar-En-Cache $response
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ID:$idItem" | Add-Content "api_tracking.log"
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
        
        if(-not (Buscar-En-Cache "NOMBRE" $nombre)) {
            $uri = "https://rickandmortyapi.com/api/character/?name=$nombre"
            
            try {
                $response = Invoke-RestMethod -Uri $uri -TimeoutSec 10 -ErrorAction Stop
                
                if($response.results) {
                    foreach($personaje in $response.results) {
                        Mostrar-Personaje $personaje
                        Guardar-En-Cache $personaje
                    }
                    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] NOMBRE:$nombre" | Add-Content "api_tracking.log"
                }
            }
            catch {
                Write-Host "Error al obtener personaje con nombre $nombre : $_"
            }
        }
    }
}

# Función para mostrar la ruta de los archivos utilizados
function Mostrar-Path-Archivos {
    Write-Host "INFO: Ruta de archivos utilizados:"
    Write-Host "Cache de personajes: $(Get-Item "characters_cache.json").FullName"
    Write-Host "Log de consultas a la API: $(Get-Item "api_tracking.log").FullName"
}

# Funcionamiento del script
Validar-Parametros
Crear-Recursos

if($id -and $nombre) {
    Write-Host "INFO: Obteniendo personajes por ID: $($id -join ',')"
    Obtener-Personaje-Por-ID $id
    Write-Host "INFO: Obteniendo personajes por nombre: $($nombre -join ',')"
    Obtener-Personaje-Por-Nombre $nombre
} elseif($id) {
    Write-Host "INFO: Obteniendo personajes por ID: $($id -join ',')"
    Obtener-Personaje-Por-ID $id
} elseif($nombre) {
    Write-Host "INFO: Obteniendo personajes por nombre: $($nombre -join ',')"
    Obtener-Personaje-Por-Nombre $nombre
}

Mostrar-Path-Archivos