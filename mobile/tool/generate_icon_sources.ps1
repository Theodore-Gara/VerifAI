# Composes the two source images that flutter_launcher_icons expands into every
# platform icon. Run this only when the logo artwork changes; then run:
#
#   dart run flutter_launcher_icons
#
# The logo ships as transparent art that fills its own canvas edge to edge, so
# it has to be centred onto a square of the brand background here. It cannot be
# handed to flutter_launcher_icons directly: the tool refuses non-square images
# and would have no background colour to fill with.
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [string]$OutDir = (Join-Path $PSScriptRoot '..\assets\icon'),
    [string]$Background = '#0E1B2A',
    [int]$Canvas = 1024
)

# Art width as a fraction of the canvas.
#
# $MasterScale is for iOS, web and the legacy Android icon, which are a single
# opaque PNG with the fill baked in. 0.78 leaves a margin that survives iOS
# rounding the corners into a squircle.
#
# $ForegroundSafeCircle is for the Android adaptive foreground, which the
# launcher masks to an arbitrary shape. The foreground layer is 108x108dp and
# only the inner 66x66dp is guaranteed to survive every mask, so the safe zone
# is 66/108 of the canvas, not 66%. The art is fitted to the inscribed circle
# of that safe zone rather than to its width, so a rectangular logo cannot have
# its corners clipped by a circular mask.
$MasterScale = 0.78
$ForegroundSafeCircle = 66 / 108

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
if ($Canvas -lt 16) { throw "Canvas must be at least 16" }

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$art = [System.Drawing.Bitmap]::FromFile($Source)
$bg = [System.Drawing.ColorTranslator]::FromHtml($Background)

function New-Centered([System.Drawing.Bitmap]$art, [int]$side, [double]$artWidth, [int]$bgAlpha) {
    $artHeight = $artWidth * $art.Height / $art.Width
    $bmp = New-Object System.Drawing.Bitmap($side, $side, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::FromArgb($bgAlpha, $bg))
    $x = [int][math]::Round(($side - $artWidth) / 2)
    $y = [int][math]::Round(($side - $artHeight) / 2)
    $g.DrawImage($art, (New-Object System.Drawing.Rectangle($x, $y, [int][math]::Round($artWidth), [int][math]::Round($artHeight))))
    $g.Dispose()
    return $bmp
}

# Opaque master: background fills edge to edge, art centred and scaled to width.
# Alpha must be 255 or iOS rejects the icon and the web icons render black.
$master = New-Centered $art $Canvas ($Canvas * $MasterScale) 255
$masterPath = Join-Path $OutDir 'app_icon.png'
$master.Save($masterPath, [System.Drawing.Imaging.ImageFormat]::Png)
$master.Dispose()

# Adaptive foreground: transparent, art fitted to the safe circle.
# A w:h rectangle inscribed in a circle of diameter D has width D*w/hypot(w,h).
$diag = [math]::Sqrt($art.Width * $art.Width + $art.Height * $art.Height)
$fgWidth = $Canvas * $ForegroundSafeCircle * $art.Width / $diag
$fg = New-Centered $art $Canvas $fgWidth 0
$fgPath = Join-Path $OutDir 'app_icon_foreground.png'
$fg.Save($fgPath, [System.Drawing.Imaging.ImageFormat]::Png)
$fg.Dispose()

$art.Dispose()

Write-Output "source        $Source"
Write-Output "background    $Background"
Write-Output "master        $masterPath  ${Canvas}x${Canvas}  art width $([int][math]::Round($Canvas * $MasterScale))px"
Write-Output "foreground    $fgPath  ${Canvas}x${Canvas}  art width $([int][math]::Round($fgWidth))px fitted to safe circle $ForegroundSafeCircle"
