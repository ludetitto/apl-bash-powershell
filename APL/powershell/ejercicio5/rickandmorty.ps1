param(
    [string[]]$id,
    [string[]]$nombre,
    [switch]$help
)

# Función para validar los parámetros de entrada
function Validar-Parametros {
    if($help) {
        Write-Host "Uso: .\ejercicio5.ps1 -id <id_personajes> -nombre <nombre_personajes>"
        exit 0
    }
    if(-not $id -and -not $nombre) {
        Write-Host "Error: Debe proporcionar -id o -nombre"
        exit 1
    }
}

# Función para crear los archivos necesarios
function Crear-Recursos {
    if(-Not (Test-Path "characters_cache.json")) {
        "[]" | Out-File -FilePath "characters_cache.json" -Encoding UTF8
    }
    "" | Out-File -FilePath "api_tracking.log" -Encoding UTF8 -Force
}

# Función para mostrar la información de un personaje
function Mostrar-Personaje {
    param(
        [Parameter(Mandatory=$true)]
        $personaje
    )
    Write-Host "Character info: Id: $($personaje.id) Name: $($personaje.name) Status: $($personaje.status) Species: $($personaje.species) Gender: $($personaje.gender) Origin: $($personaje.origin.name) Location: $($personaje.location.name) Episodes: $($personaje.episode.Count)"
}

# Función para buscar personajes en la caché, una vez que se sabe que fue consultado previamente a la API
function Buscar-En-Cache {
    param(
        [string[]]$tipo,
        [string]$valor
    )

    $cache = Get-Content "characters_cache.json" | ConvertFrom-Json -ErrorAction SilentlyContinue
    if($tipo -eq "ID") {
        $personajes = $cache | Where-Object { $_.id -eq [int]$valor }
    } else {
        $personajes = $cache | Where-Object { $_.name -like "*$valor*" }
    }

    if($personajes) {
        foreach($p in $personajes) { Mostrar-Personaje $p }
        return $true
    }
    return $false
}

# Función para guardar personajes en la caché
function Guardar-En-Cache {
    param(
        [Parameter(Mandatory=$true)]
        $personaje
    )

    $cache = Get-Content "characters_cache.json" | ConvertFrom-Json -ErrorAction SilentlyContinue
    if(-Not $cache) {
        $cache = @()
    }
    $cache += $personaje
    $cache | ConvertTo-Json -Depth 10 | Set-Content "characters_cache.json"
}

# Funcion para obtener personajes por ID
function Obtener-Personaje-Por-ID {
    param(
        [string]$ids
    )
    
    $idArray = $ids -split ","
    foreach($id in $idArray) {
        $id = $id.Trim()
        if(-not $id) { continue }
        
        if(Buscar-En-Cache "ID" $id) {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ID:$id" | Add-Content "api_tracking.log"
            continue
        }

        $uri = "https://rickandmortyapi.com/api/character/$id"
        $response = Invoke-RestMethod -Uri $uri -ErrorAction SilentlyContinue
        
        if($response) {
            Mostrar-Personaje $response
            Guardar-En-Cache $response
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ID:$id" | Add-Content "api_tracking.log"
        }
    }
}

# Funcion para obtener personajes por nombre
function Obtener-Personaje-Por-Nombre {
    param(
        [string]$nombre
    )

    $nombreArray = $nombres -split ","
    foreach($nombre in $nombreArray) {
        $nombre = $nombre.Trim()
        if(-not $nombre) { continue }
        
        if(Buscar-En-Cache "NOMBRE" $nombre) {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] NOMBRE:$nombre" | Add-Content "api_tracking.log"
            continue
        }

        $uri = "https://rickandmortyapi.com/api/character/?name=$nombre"
        $response = Invoke-RestMethod -Uri $uri -ErrorAction SilentlyContinue
        
        if($response.results) {
            foreach($personaje in $response.results) {
                Mostrar-Personaje $personaje
                Guardar-En-Cache $personaje
            }
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] NOMBRE:$nombre" | Add-Content "api_tracking.log"
        }
    }
}

# Funcion para borrar los archivos temporales
function Borrar-Temporales {
    Remove-Item "temp.json" -ErrorAction SilentlyContinue
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

if($id -is [array]) {
    $id = $id -join ","
}
if($nombre -is [array]) {
    $nombre = $nombre -join ","
}

if($id -and $nombre) {
    Write-Host "INFO: Obteniendo personajes por ID: $id"
    Obtener-Personaje-Por-ID $id
    Write-Host "INFO: Obteniendo personajes por nombre: $nombre"
    Obtener-Personaje-Por-Nombre $nombre
} elseif($id) {
    Write-Host "INFO: Obteniendo personajes por ID: $id"
    Obtener-Personaje-Por-ID $id
} elseif($nombre) {
    Write-Host "INFO: Obteniendo personajes por nombre: $nombre"
    Obtener-Personaje-Por-Nombre $nombre
}

Borrar-Temporales
Mostrar-Path-Archivos