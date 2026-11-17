
# ########################################################################
# Title       : JumpScare
# Author      : Adaptacion para Flipper Zero
# Version     : 1.0
# Target      : Windows 10 / 11
# Mode        : HID
# ########################################################################

<#
.DESCRIPTION
Descarga una imagen y un sonido desde GitHub.
Espera el movimiento del mouse.
Cambia el fondo de pantalla y reproduce el sonido.
#>

# ------------------------------------------------------------------------
# DESCARGA DE ARCHIVOS
# ------------------------------------------------------------------------

$image = "https://raw.githubusercontent.com/joaquincizmadija/fllipo/main/jumpscares/chicobv/1713512540801.jpg"

$wav = "https://raw.githubusercontent.com/joaquincizmadija/fllipo/main/jumpscares/chicobv/female_scream.wav"

$imagePath = Join-Path $env:TEMP "jumpscare_image.jpg"
$wavPath = Join-Path $env:TEMP "jumpscare_sound.wav"

Write-Host "Descargando imagen..."
Invoke-WebRequest -Uri $image -OutFile $imagePath

Write-Host "Descargando sonido..."
Invoke-WebRequest -Uri $wav -OutFile $wavPath

if (!(Test-Path $imagePath) -or !(Test-Path $wavPath)) {
    throw "No se pudieron descargar los archivos."
}

# ------------------------------------------------------------------------
# CAMBIAR FONDO DE PANTALLA
# ------------------------------------------------------------------------

Function Set-WallPaper {

    param (
        [Parameter(Mandatory=$true)]
        [string]$Image,

        [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
        [string]$Style = 'Center'
    )

    $WallpaperStyle = switch ($Style) {
        "Fill"    { "10" }
        "Fit"     { "6" }
        "Stretch" { "2" }
        "Tile"    { "0" }
        "Center"  { "0" }
        "Span"    { "22" }
    }

    $TileWallpaper = if ($Style -eq "Tile") { "1" } else { "0" }

    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" `
        -Name WallpaperStyle -Value $WallpaperStyle

    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" `
        -Name TileWallpaper -Value $TileWallpaper

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class JumpScareWallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int SystemParametersInfo(
        int action, int param, string image, int flags
    );
}
"@

    [JumpScareWallpaper]::SystemParametersInfo(
        0x0014, 0, $Image, 0x01 -bor 0x02
    ) | Out-Null
}

# ------------------------------------------------------------------------
# ESPERAR MOVIMIENTO DEL MOUSE
# ------------------------------------------------------------------------

Function Pause-Script {

    Add-Type -AssemblyName System.Windows.Forms

    Write-Host "Esperando movimiento del mouse..."

    $originalPOS = [System.Windows.Forms.Cursor]::Position

    while ($true) {

        Start-Sleep -Seconds 1

        $currentPOS = [System.Windows.Forms.Cursor]::Position

        if (
            $currentPOS.X -ne $originalPOS.X -or
            $currentPOS.Y -ne $originalPOS.Y
        ) {
            break
        }
    }
}

# ------------------------------------------------------------------------
# REPRODUCIR ARCHIVO WAV
# ------------------------------------------------------------------------

Function Play-WAV {

    $PlayWav = New-Object System.Media.SoundPlayer
    $PlayWav.SoundLocation = $wavPath
    $PlayWav.Load()
    $PlayWav.PlaySync()
}

# ------------------------------------------------------------------------
# EJECUCION PRINCIPAL
# ------------------------------------------------------------------------

Pause-Script

Write-Host "Movimiento detectado."
Write-Host "Cambiando fondo de pantalla..."

Set-WallPaper -Image $imagePath -Style Center

Write-Host "Reproduciendo sonido..."

Play-WAV

Write-Host "JumpScare finalizado."

# ------------------------------------------------------------------------
# LIMPIEZA: SOLO ARCHIVOS CREADOS POR ESTE SCRIPT
# ------------------------------------------------------------------------

Remove-Item $imagePath -Force -ErrorAction SilentlyContinue
Remove-Item $wavPath -Force -ErrorAction SilentlyContinue
