#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 4                                    #
#                                                       #
#   Integrantes:                                        #
#       Vignardel Francisco                             #
#       Lucia de Titto                                  #
#       Samuel                                          #
#       Francisco Vladimir                              #
#                                                       #
#-------------------------------------------------------#

<#
.SYNOPSIS
    Demonio que monitorea un directorio y detecta archivos con palabras clave.

.DESCRIPTION
    Ejecuta un proceso en segundo plano que vigila un directorio usando FileSystemWatcher.
    Cada vez que se crea o modifica un archivo, busca palabras clave dentro de él y registra
    las coincidencias en un archivo de log con fecha, operación y tamaño.
    El demonio puede detenerse ejecutando el script nuevamente con el flag -Kill.

.PARAMETER Directorio
    Ruta del directorio a monitorear. Acepta rutas relativas y absolutas.

.PARAMETER Palabras
    Palabras clave separadas por coma a buscar dentro de los archivos. Ej: password,token,api_key

.PARAMETER Log
    Ruta del archivo de log donde se registran las coincidencias encontradas.

.PARAMETER Kill
    Detiene el demonio activo para el directorio indicado. Solo se usa junto con -Directorio.

.EXAMPLE
    mkdir descargas
    .\demonio.ps1 -Directorio descargas -Palabras "password,token,api_key" -Log monitoreo.log
    "mi password es 1234" | Out-File descargas/credenciales.txt
    Get-Content monitoreo.log
    .\demonio.ps1 -Directorio descargas -Kill
#>

[CmdletBinding(DefaultParameterSetName = 'Iniciar')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Iniciar')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Matar')]
    [ValidateScript({
        if (-not (Test-Path $_ -PathType Container)) {
            throw "El directorio '$_' no existe."
        }
        $true
    })]
    [string]$Directorio,

    [Parameter(Mandatory = $true, ParameterSetName = 'Iniciar')]
    [string]$Palabras,

    [Parameter(Mandatory = $true, ParameterSetName = 'Iniciar')]
    [string]$Log,

    [Parameter(Mandatory = $true, ParameterSetName = 'Matar')]
    [switch]$Kill,

    # Variable interna: el proceso padre la pasa al hijo para que sepa que ya es el daemon
    [Parameter(DontShow)]
    [switch]$ModoDemonio
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Capturar la ruta del script aquí (dentro de funciones $PSCommandPath puede variar)
$rutaScript = $PSCommandPath

# ---------- UI ----------
function registrar_error { param([string]$mensaje) Write-Host "[ERROR] $mensaje" -ForegroundColor Red }
function registrar_info  { param([string]$mensaje) Write-Host "[INFO]  $mensaje" -ForegroundColor Green }
function registrar_aviso { param([string]$mensaje) Write-Host "[AVISO] $mensaje" -ForegroundColor Yellow }
function marca_tiempo    { (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }

# ---------- Auxiliares ----------

# Convierte una ruta relativa en absoluta
function ruta_absoluta {
    param([string]$ruta)
    if ([string]::IsNullOrWhiteSpace($ruta)) { return '' }
    return [IO.Path]::GetFullPath($ruta)
}

# Genera la ruta única del archivo PID para este directorio (hash evita colisiones entre directorios)
function ruta_archivo_pid {
    param([string]$rutaDirectorio)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($rutaDirectorio)
    $hash  = [System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
    $hashStr = ($hash | ForEach-Object { $_.ToString('x2') }) -join ''
    return [IO.Path]::Combine([IO.Path]::GetTempPath(), "demonio_$hashStr.pid")
}

# Verifica si el daemon está corriendo: devuelve su PID o $null si no existe
function pid_del_daemon_activo {
    param([string]$rutaDirectorio)
    $archivoPid = ruta_archivo_pid $rutaDirectorio
    if (-not (Test-Path $archivoPid)) { return $null }  # no existe el archivo PID → no hay daemon
    $pidGuardado = (Get-Content $archivoPid -Raw).Trim()
    try {
        Get-Process -Id $pidGuardado -ErrorAction Stop | Out-Null
        return $pidGuardado  # el proceso sigue vivo → devuelve su PID
    } catch {
        Remove-Item $archivoPid -Force -ErrorAction SilentlyContinue  # el proceso ya no existe → limpia el archivo PID
        return $null
    }
}

# ---------- Log ----------
function escribir_linea_log {
    param([string]$linea, [string]$rutaLog)
    Add-Content -LiteralPath $rutaLog -Value $linea -Encoding UTF8
}

# ---------- Tamaño ----------
function obtener_tamanio_en_bytes {
    param([string]$rutaArchivo)
    try { return (Get-Item -LiteralPath $rutaArchivo).Length } catch { return '?' }
}

# ---------- Escaneo ----------

# Verifica si un archivo es binario leyendo sus primeros bytes
function es_archivo_binario {
    param([string]$rutaArchivo)
    try {
        $stream = [IO.File]::Open($rutaArchivo, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            $buffer = New-Object byte[] 8192
            $leidos = $stream.Read($buffer, 0, 8192)
            for ($i = 0; $i -lt $leidos; $i++) {
                if ($buffer[$i] -eq 0) { return $true }
            }
            return $false
        } finally { $stream.Dispose() }
    } catch { return $true }
}

# Busca las palabras clave dentro de un archivo y si las encuentra registra la coincidencia en el log
function buscar_palabras_clave_en_archivo {
    param([string]$rutaArchivo, [string]$tipoOperacion, [string[]]$palabrasClave, [string]$rutaLog)
    if (-not (Test-Path $rutaArchivo -PathType Leaf)) { return }
    if (es_archivo_binario $rutaArchivo) { return }  # saltar binarios
    $tamanioBytes = obtener_tamanio_en_bytes $rutaArchivo
    try {
        $contenido = Get-Content -LiteralPath $rutaArchivo -Raw -ErrorAction Stop
    } catch { return }
    foreach ($palabraClave in $palabrasClave) {
        if ([string]::IsNullOrWhiteSpace($palabraClave)) { continue }
        # -match sin distinción de mayúsculas/minúsculas (comportamiento por defecto en PowerShell)
        if ($contenido -match [regex]::Escape($palabraClave)) {
            $linea = "[{0}] Operación: {1,-10} | Archivo: '{2}' | Palabra: '{3}' | Tamaño: {4} bytes" -f `
                (marca_tiempo), $tipoOperacion, $rutaArchivo, $palabraClave, $tamanioBytes
            escribir_linea_log $linea $rutaLog
        }
    }
}

# Escanea los archivos que ya estaban en el directorio al momento de iniciar el daemon
function escanear_archivos_preexistentes {
    param([string]$rutaDirectorio, [string[]]$palabrasClave, [string]$rutaLog)
    $cantidadArchivos = 0
    escribir_linea_log ("[{0}] Procesando archivos existentes en '{1}' ..." -f (marca_tiempo), $rutaDirectorio) $rutaLog
    Get-ChildItem -LiteralPath $rutaDirectorio -File -ErrorAction SilentlyContinue | ForEach-Object {
        buscar_palabras_clave_en_archivo $_.FullName 'EXISTENTE' $palabrasClave $rutaLog
        $cantidadArchivos++
    }
    escribir_linea_log ("[{0}] {1} archivos existentes procesados." -f (marca_tiempo), $cantidadArchivos) $rutaLog
}

# ---------- Bucle del daemon ----------

# Bucle infinito que espera eventos de FileSystemWatcher y los procesa uno a uno
function iniciar_bucle_de_monitoreo {
    param([string]$rutaDirectorio, [string[]]$palabrasClave, [string]$rutaLog)

    escribir_linea_log ("[{0}] Demonio iniciado | Directorio: '{1}' | Palabras: {2}" -f `
        (marca_tiempo), $rutaDirectorio, ($palabrasClave -join ', ')) $rutaLog

    escanear_archivos_preexistentes $rutaDirectorio $palabrasClave $rutaLog

    # FileSystemWatcher es el equivalente a inotifywait en PowerShell
    $watcher = New-Object IO.FileSystemWatcher
    $watcher.Path                  = $rutaDirectorio
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents   = $true

    $archivoPid = ruta_archivo_pid $rutaDirectorio

    # Espera eventos indefinidamente hasta que se elimine el archivo PID (señal de kill)
    while (Test-Path $archivoPid) {
        # WaitForChanged bloquea hasta detectar un cambio o hasta que se cumpla el timeout (1 segundo)
        $evento = $watcher.WaitForChanged([IO.WatcherChangeTypes]::All, 1000)
        if ($evento.TimedOut) { continue }
        $rutaArchivo    = Join-Path $rutaDirectorio $evento.Name
        $tipoOperacion  = $evento.ChangeType.ToString().ToUpper()
        buscar_palabras_clave_en_archivo $rutaArchivo $tipoOperacion $palabrasClave $rutaLog
    }

    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    escribir_linea_log ("[{0}] Demonio detenido." -f (marca_tiempo)) $rutaLog
}

# ---------- Matar daemon ----------
function detener_daemon {
    param([string]$rutaDirectorio)
    $pidActivo = pid_del_daemon_activo $rutaDirectorio
    if ($null -eq $pidActivo) {
        registrar_aviso "No hay daemon corriendo para '$rutaDirectorio'."
        exit 1
    }
    try {
        Stop-Process -Id $pidActivo -Force -ErrorAction Stop
        Remove-Item (ruta_archivo_pid $rutaDirectorio) -Force -ErrorAction SilentlyContinue
        registrar_info "Daemon detenido (PID: $pidActivo)."
    } catch {
        registrar_error "No se pudo detener el proceso (PID: $pidActivo): $_"
        exit 1
    }
}

# ---------- Lanzar daemon ----------

# Lanza el daemon en segundo plano y guarda su PID para poder matarlo después
function lanzar_daemon {
    param([string]$rutaDirectorio, [string]$palabrasCrudas, [string]$rutaLog)

    # Detectar el ejecutable de PowerShell disponible
    $ejecutablePwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    $ejecutable = if ($ejecutablePwsh) { $ejecutablePwsh.Source } else { 'powershell' }

    $argumentos = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$rutaScript`"",
        '-Directorio', "`"$rutaDirectorio`"",
        '-Palabras', "`"$palabrasCrudas`"",
        '-Log', "`"$rutaLog`"",
        '-ModoDemonio'
    )

    $procesoDemonio    = Start-Process -FilePath $ejecutable -ArgumentList $argumentos -PassThru
    $pidProcesoDemonio = $procesoDemonio.Id

    # Guardar el PID del hijo para poder matarlo después con -Kill
    $pidProcesoDemonio | Out-File -FilePath (ruta_archivo_pid $rutaDirectorio) -Encoding ascii -Force
    registrar_info "Daemon iniciado en segundo plano (PID: $pidProcesoDemonio)."
}

# ---------- Main ----------

# Convertir rutas a absolutas
$Directorio = ruta_absoluta $Directorio

# Modo kill: detener el daemon
if ($Kill) {
    detener_daemon $Directorio
    exit 0
}

$archivoLog = ruta_absoluta $Log

# Modo daemon (hijo relanzado): variable interna que indica que ya es el proceso en segundo plano
if ($ModoDemonio) {
    # El hijo recibe las palabras como string separado por coma (así las pasó el padre)
    $palabrasClave = ($Palabras -join ',') -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    # Limpia el archivo PID al salir (por cualquier causa, incluso errores)
    try {
        iniciar_bucle_de_monitoreo $Directorio $palabrasClave $archivoLog
    } finally {
        Remove-Item (ruta_archivo_pid $Directorio) -Force -ErrorAction SilentlyContinue
    }
    exit 0
}

# Aplanar el array de palabras (PowerShell puede recibir "a,b,c" como un elemento o como varios)
$palabrasClave = ($Palabras -join ',') -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

# Crear el directorio del log si no existe, y el archivo log vacío
$dirLog = Split-Path $archivoLog -Parent
if ($dirLog -and -not (Test-Path $dirLog)) {
    New-Item -ItemType Directory -Path $dirLog -Force | Out-Null
}
try {
    '' | Out-File -LiteralPath $archivoLog -Encoding UTF8 -Force
} catch {
    registrar_error "No puedo escribir en '$archivoLog'."
    exit 1
}

# Prevenir demonios duplicados para el mismo directorio
$pidExistente = pid_del_daemon_activo $Directorio
if ($null -ne $pidExistente) {
    registrar_error "Ya hay un daemon para este directorio (PID: $pidExistente)."
    exit 1
}

# Pasar las palabras como string unido por coma al proceso hijo
lanzar_daemon $Directorio ($palabrasClave -join ',') $archivoLog
