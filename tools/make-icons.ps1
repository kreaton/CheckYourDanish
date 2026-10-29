# Renders the app icon in every size into CheckYourDanish/wwwroot/icons:
# a letter tile with "Æ" on the dark app background, framed in Dannebrog red like the current letter box.
#   powershell -File tools\make-icons.ps1
Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot "..\CheckYourDanish\wwwroot\icons"
New-Item -ItemType Directory -Force $out | Out-Null

function New-RoundedRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    $path
}

# $tile is the letter tile's width as a share of the icon; maskable icons keep it inside the safe zone.
# $rounded gives the background its own rounded corners (favicons); iOS and maskable icons are rounded by the OS.
function New-Icon([int]$size, [double]$tile = 0.62, [bool]$rounded = $false) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = "AntiAlias"
    $g.TextRenderingHint = "AntiAliasGridFit"
    $g.InterpolationMode = "HighQualityBicubic"
    $g.Clear([System.Drawing.Color]::Transparent)

    $rect = New-Object System.Drawing.RectangleF 0, 0, $size, $size
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect,
        ([System.Drawing.Color]::FromArgb(0x26, 0x2F, 0x44)), ([System.Drawing.Color]::FromArgb(0x10, 0x14, 0x1C)), 90
    if ($rounded) {
        $g.FillPath($bg, (New-RoundedRect 0 0 $size $size ($size * 0.2)))
    } else {
        $g.FillRectangle($bg, $rect)
    }

    # The letter tile, a little taller than wide like the boxes in the game.
    $w = $size * $tile
    $h = $w * 1.12
    $x = ($size - $w) / 2
    $y = ($size - $h) / 2
    $tilePath = New-RoundedRect $x $y $w $h ($w * 0.18)
    $tileBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0x22, 0x2A, 0x39))
    $g.FillPath($tileBrush, $tilePath)
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(0xE0, 0x38, 0x4F)), ([Math]::Max(1.5, $w * 0.07))
    $g.DrawPath($pen, $tilePath)

    $font = New-Object System.Drawing.Font "Georgia", ([float]($h * 0.68)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = "Center"
    $format.LineAlignment = "Center"
    $textRect = New-Object System.Drawing.RectangleF $x, ($y + $h * 0.03), $w, $h
    # [char]0xC6 is "Æ", written as a code so Windows PowerShell can't misread the file encoding.
    $g.DrawString([string][char]0xC6, $font, [System.Drawing.Brushes]::White, $textRect, $format)

    $g.Dispose()
    $bmp
}

function Save-Png($bmp, [string]$name) {
    $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# iOS home screen (opaque, square: iOS rounds the corners itself).
Save-Png (New-Icon 180) "apple-touch-icon.png"
Save-Png (New-Icon 167) "apple-touch-icon-167.png"
Save-Png (New-Icon 152) "apple-touch-icon-152.png"

# Web app manifest (Windows/Android install) and a big master copy.
Save-Png (New-Icon 1024) "icon-1024.png"
Save-Png (New-Icon 512 0.62 $true) "icon-512.png"
Save-Png (New-Icon 192 0.62 $true) "icon-192.png"
Save-Png (New-Icon 512 0.5) "icon-512-maskable.png"

# Browser tab: a bigger tile so it reads at 16 px.
Save-Png (New-Icon 32 0.78 $true) "favicon-32.png"

# favicon.ico with 16, 32 and 48 px PNG images, for Windows and older browsers.
$images = foreach ($s in 16, 32, 48) {
    $bmp = New-Icon $s 0.78 $true
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    [pscustomobject]@{ Size = $s; Bytes = $ms.ToArray() }
}
$ico = New-Object System.IO.MemoryStream
$wr = New-Object System.IO.BinaryWriter $ico
$wr.Write([uint16]0); $wr.Write([uint16]1); $wr.Write([uint16]$images.Count)
$offset = 6 + 16 * $images.Count
foreach ($img in $images) {
    $wr.Write([byte]$img.Size); $wr.Write([byte]$img.Size); $wr.Write([byte]0); $wr.Write([byte]0)
    $wr.Write([uint16]1); $wr.Write([uint16]32)
    $wr.Write([uint32]$img.Bytes.Length); $wr.Write([uint32]$offset)
    $offset += $img.Bytes.Length
}
foreach ($img in $images) { $wr.Write($img.Bytes) }
$wr.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $out "..\favicon.ico"), $ico.ToArray())

Write-Host "Icons written to $out"
