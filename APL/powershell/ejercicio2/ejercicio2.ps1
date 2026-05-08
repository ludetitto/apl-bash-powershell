param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Debe proporcionar la ruta a un archivo."
    )]

    [ValidateScript({
        if (!(Test-Path $_ -PathType Leaf)) {
            throw "El archivo '$_' no existe."
        }

        return $true
    })]

    [string]$Archivo
)

function Normalizar-Texto {
    param([string]$RutaArchivo)
    $texto = Get-Content -Path $RutaArchivo -Raw -Encoding UTF8

   
    $texto = $texto -replace ' +', ' ' `
                    -replace '(?m)^ ', '' `
                    -replace ' ([.,;?!])', '$1' `
                    -replace '\.{4,}', '...' `
                    -replace "(^|[,.;:!¡]+\s*)([^¿?.,;:!¡]+)\?", '$1¿$2?' `
                    -replace "(^|[,.;:?¿]+\s*)([^¡!.,;:?¿]+)!", '$1¡$2!' `
                    -replace '\.{3} *', '... ' `
                    -replace '([,?!]) *', '$1 ' `
                    -replace "'", '"' `
                    -replace '(?m) $', ''

    $parrafos = $texto -split "\r?\n\r?\n"
    
    $parrafosProcesados = foreach ($p in $parrafos) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        
        $p = $p.TrimEnd()

        if ($p -match '¡[^!]*$') {
            $p = ($p -replace '[.!?]*$', '') + '!'
        }
        elseif ($p -match '¿[^?]*$') {
            $p = ($p -replace '[.!?]*$', '') + '?'
        }
        elseif ($p -notmatch '[.!?]$' -and $p.Length -gt 0) {
            $p = $p + '.'
        }
        $p
    }
    
    
    $texto = $parrafosProcesados -join "`r`n`r`n"

    
    
    $evaluador = [System.Text.RegularExpressions.MatchEvaluator] {
        param($match)
        $match.Value.ToUpper()
    }
    
    $patron = '(?<=^|[\r\n]+|[.!?]\s+)[a-záéíóúñ]'
    $texto = [regex]::Replace($texto, $patron, $evaluador, 'IgnoreCase')

    Set-Content -Path "texto_corregido.txt" -Value $texto -Encoding UTF8
    Write-Host "Archivo normalizado guardado en 'texto_corregido.txt'" -ForegroundColor Green
}

Normalizar-Texto -RutaArchivo $Archivo
