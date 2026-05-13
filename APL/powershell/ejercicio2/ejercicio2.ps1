#!/usr/bin/env pwsh

#-------------------------------------------------------#
#               Virtualizacion de Hardware              #
#                                                       #
#   APL1                                                #
#   Nro ejercicio: 2                                    #
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
    Normaliza el contenido de un archivo de texto.

.DESCRIPTION
    Corrige espacios duplicados, aplica mayúsculas al inicio de oraciones y párrafos,
    balancea signos de puntuación españoles (agrega '¿' y '¡' faltantes) y ajusta
    el espaciado correcto después de puntos, comas y signos de exclamación/interrogación.

.PARAMETER archivo
    Ruta del archivo de texto a procesar (obligatorio).

.PARAMETER salida
    Ruta del archivo donde se guardará el resultado (opcional).
    Si no se informa, el resultado se muestra por pantalla.

.EXAMPLE
    .\ejercicio2.ps1 -archivo archivo.txt
    Procesa el archivo y muestra el resultado por pantalla.

.EXAMPLE
    .\ejercicio2.ps1 -archivo archivo.txt -salida texto_corregido.txt
    Procesa el archivo y guarda el resultado en texto_corregido.txt.
#>

[CmdletBinding(PositionalBinding=$false)]
param (
    [Alias('a')]
    [string]$archivo,

    [Alias('s')]
    [string]$salida
)

if (-not $archivo) {
    Write-Host "Error: Falta el parámetro obligatorio '-archivo'." -ForegroundColor Red
    Write-Host "Usa 'Get-Help .\$($MyInvocation.MyCommand.Name)' para ver las opciones."
    exit 1
}

#Validar que el archivo de entrada exista realmente
if (-not (Test-Path -Path $archivo -PathType Leaf)) {
    Write-Host "Error: El archivo '$archivo' no existe." -ForegroundColor Red
    exit 1
}

function Normalizar-Texto {
    param (
        [string]$RutaArchivo,
        [string]$RutaSalida
    )

    # Lee línea por línea como hace sed por defecto
    $lineasOriginales = Get-Content -Path $RutaArchivo
    $lineasFase1 = @()

    foreach ($linea in $lineasOriginales) {
        $l = $linea -replace ' +', ' '
        $l = $l -replace '^ ', ''
        $l = $l -replace ' ([.,;.?!])', '$1'
        $l = $l -replace '\.{4,}', '...'
        
        $l = $l -replace '(?<=^|[,.;:!¡?]+[ \t]*)([^¿?.,;:!¡\s][^¿?.,;:!¡]*)\?', '¿$1?'
	$l = $l -replace '(?<=^|[,.;:!¡?]+[ \t]*)([^¡!.,;:?¿\s][^¡!.,;:?¿]*)!', '¡$1!'
        
        $l = $l -replace '\.{3} *', '... '
        $l = $l -replace '([,?!]) *', '$1 '
	#Agrego esta linea para evitar que le agregue espacio entre puntos suspensivos mirando a los caracteres vecinos 
	$l = $l -replace '(?<!\.)\.(?!\.)[ \t]*', '. '
       
        $l = $l.Replace("'", '"')
        $l = $l -replace ' $', ''
        
        $lineasFase1 += $l
    }

    #Se une con salto de lineas para trabajarlo como parrafos
    $textoSed = $lineasFase1 -join "`n"

    #Separa por bloques de líneas vacías
    $parrafos = [System.Text.RegularExpressions.Regex]::Split($textoSed, '\n\s*\n')
    $parrafosProcesados = @()

    foreach ($p in $parrafos) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }

        #Saco los espacios y salto de linea al final
        $p = $p -replace '[\s\n]+$', ''

        # Si encuentra un "¡" y ningun "!" después de él
        if ($p -match '¡[^!]*$') {
            $p = ($p -replace '[.!?]*$', '') + '!'
        }
        # Si encuentra un "¿" y ningun "?" después de él
        elseif ($p -match '¿[^?]*$') {
            $p = ($p -replace '[.!?]*$', '') + '?'
        }
        # Si todo estaba bien cerrado, verifico que tenga punto final
        elseif ($p -notmatch '[.!?]$') {
            $p += '.'
        }

        $parrafosProcesados += $p
    }

    #Se unen todos los parrafos para ponerle las mayusculas
    $textoAwk1 = $parrafosProcesados -join "`n`n"

    $lineasAwk2 = $textoAwk1 -split '\n'
    $mayus = $true
    $lineasFinales = @()

    foreach ($linea in $lineasAwk2) {
        # awk: if (length($0) == 0) { mayus = 1; print ""; next }
        if ($linea.Length -eq 0 -or $linea -match '^\r?$') {
            $mayus = $true
            $lineasFinales += ""
            continue
        }

        $chars = $linea.ToCharArray()
        $lineaArmada = ""

        for ($i = 0; $i -lt $chars.Length; $i++) {
            $c = $chars[$i]
            
            if ($mayus -and $c -match '[a-zA-ZáéíóúÁÉÍÓÚñÑ]') {
                $lineaArmada += [string]::new($c).ToUpper()
                $mayus = $false
            }
            else {
                $lineaArmada += $c
                if ($c -match '[.!?]') {
                    $mayus = $true
                }
            }
        }
        $lineasFinales += $lineaArmada
    }

    # Generar salida
    $textoFinal = $lineasFinales -join "`n"
    if ([string]::IsNullOrWhiteSpace($RutaSalida)) {
        Write-Output $textoFinal
    } else {
        $textoFinal | Out-File -FilePath $RutaSalida -Encoding UTF8
        Write-Host "Proceso completado. Texto guardado en '$RutaSalida'." -ForegroundColor Green
    }
}

Normalizar-Texto -RutaArchivo $archivo -RutaSalida $salida
