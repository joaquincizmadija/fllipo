
####################################################################################################
#                                      JUMPSCARE PERSONALIZADO
#                                      Windows 10 / Windows 11
####################################################################################################

# ================================================================================================
# 1. CONFIGURACIÓN: COLOCÁ AQUÍ TUS ENLACES DE GITHUB
# ================================================================================================

# IMAGEN: Pegá aquí el enlace RAW de tu imagen.

# IMAGEN DE GITHUB
$image = "https://raw.githubusercontent.com/joaquincizmadija/fllipo/main/jumpscares/chicobv/1713512540801.jpg"

# AUDIO DE GITHUB
$wav = "https://raw.githubusercontent.com/joaquincizmadija/fllipo/main/jumpscares/chicobv/female_scream.wav"

# RUTAS TEMPORALES
$imagePath = Join-Path $env:TEMP "jumpscare_image.jpg"
$wavPath = Join-Path $env:TEMP "jumpscare_sound.wav"

# ================================================================================================
# 3. DESCARGAR ARCHIVOS
# ================================================================================================

try {
    Write-Host "Descargando imagen..."
    Invoke-WebRequest -Uri $image -OutFile $imagePath -ErrorAction Stop

    Write-Host "Descargando audio..."
    Invoke-WebRequest -Uri $wav -OutFile $wavPath -ErrorAction Stop

    if (!(Test-Path $imagePath) -or !(Test-Path $wavPath)) {
        throw "No se pudieron descargar los archivos."
    }
}
catch {
    Write-Host "Error al descargar los archivos: $_" -ForegroundColor Red
    exit
}

# ================================================================================================
# 4. FUNCIÓN PARA CAMBIAR EL FONDO DE PANTALLA
# ================================================================================================

function Set-WallPaper {

    param (
        [Parameter(Mandatory=$true)]
        [string]$Image,

        [ValidateSet('Fill','Fit','Stretch','Tile','Center','Span')]
        [string]$Style = 'Fill'
    )

    $WallpaperStyle = switch ($Style) {
        "Fill"    { "10" }
        "Fit"     { "6" }
        "Stretch" { "2" }
        "Tile"    { "0" }
        "Center"  { "0" }
        "Span"    { "22" }
    }

    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" `
        -Name WallpaperStyle -Value $WallpaperStyle

    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" `
        -Name TileWallpaper -Value $(if ($Style -eq "Tile") { "1" } else { "0" })

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WallpaperParams {
    [DllImport("User32.dll", CharSet = CharSet.Unicode)]
    public static extern int SystemParametersInfo(
        int uAction,
        int uParam,
        string lpvParam,
        int fuWinIni
    );
}
"@

    [WallpaperParams]::SystemParametersInfo(
        0x0014,
        0,
        $Image,
        0x01 -bor 0x02
    ) | Out-Null
}

# ================================================================================================
# 5. ESPERAR MOVIMIENTO DEL MOUSE
# ================================================================================================

function Pause-Script {

    Add-Type -AssemblyName System.Windows.Forms

    $originalPOS = [System.Windows.Forms.Cursor]::Position

    Write-Host "JumpScare preparado. Esperando movimiento del mouse..."

    while ($true) {

        $currentPOS = [System.Windows.Forms.Cursor]::Position

        if (
            $currentPOS.X -ne $originalPOS.X -or
            $currentPOS.Y -ne $originalPOS.Y
        ) {
            break
        }

        Start-Sleep -Milliseconds 300
    }
}

# ================================================================================================
# 6. REPRODUCIR AUDIO
# ================================================================================================

function Play-WAV {

    $PlayWav = New-Object System.Media.SoundPlayer

    $PlayWav.SoundLocation = $wavPath

    $PlayWav.Load()

    $PlayWav.PlaySync()
}

# ================================================================================================
# 7. EJECUCIÓN DEL JUMPSCARE
# ================================================================================================

try {

    # Esperar movimiento del mouse
    Pause-Script

    # Cambiar fondo de pantalla
    Set-WallPaper -Image $imagePath -Style Fill

    # Reproducir sonido
    Play-WAV

    Write-Host "JumpScare finalizado."

}
catch {
    Write-Host "Error durante la ejecución: $_" -ForegroundColor Red
}

# ================================================================================================
# 8. FINALIZACIÓN
# ================================================================================================

# Eliminar únicamente los archivos descargados por este script.

Remove-Item $imagePath, $wavPath -Force -ErrorAction SilentlyContinue
