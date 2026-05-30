# OGP画像生成スクリプト
# 使い方:
#   .\tools\generate-ogp.ps1 -Title "記事タイトル" -Subtitle "サブタイトル（任意）" -Output "assets/img/posts/filename.jpg"
#   .\tools\generate-ogp.ps1 -Title "記事タイトル" -Background "path/to/photo.jpg" -Output "assets/img/posts/filename.jpg"

param(
    [Parameter(Mandatory=$true)]
    [string]$Title,

    [string]$Subtitle = "",

    [string]$Background = "",

    [Parameter(Mandatory=$true)]
    [string]$Output,

    [int]$Width = 1200,
    [int]$Height = 630
)

Add-Type -AssemblyName System.Drawing

$bitmap   = New-Object System.Drawing.Bitmap($Width, $Height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode        = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint    = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$graphics.InterpolationMode    = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# --- 背景 ---
if ($Background -and (Test-Path $Background)) {
    $bgImage = [System.Drawing.Image]::FromFile((Resolve-Path $Background).Path)
    $graphics.DrawImage($bgImage, 0, 0, $Width, $Height)
    $bgImage.Dispose()
} else {
    # デフォルト：NZカラーのグラデーション背景
    $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)),
        (New-Object System.Drawing.Point($Width, $Height)),
        [System.Drawing.Color]::FromArgb(20, 55, 45),
        [System.Drawing.Color]::FromArgb(10, 25, 55)
    )
    $graphics.FillRectangle($gradBrush, 0, 0, $Width, $Height)
    $gradBrush.Dispose()
}

# --- 半透明オーバーレイ ---
$overlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(130, 0, 0, 0))
$graphics.FillRectangle($overlayBrush, 0, 0, $Width, $Height)
$overlayBrush.Dispose()

# --- フォント設定（Yu Gothic → Meiryo にフォールバック）---
$fontFamilies = @("Yu Gothic", "Yu Gothic UI", "Meiryo", "MS Gothic")
$selectedFamily = $fontFamilies | Where-Object {
    ([System.Drawing.FontFamily]::Families | Select-Object -ExpandProperty Name) -contains $_
} | Select-Object -First 1
if (-not $selectedFamily) { $selectedFamily = "Arial" }

$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

# --- タイトル ---
$titleFontSize = if ($Title.Length -le 20) { 52 } elseif ($Title.Length -le 30) { 44 } else { 36 }
$titleFont   = New-Object System.Drawing.Font($selectedFamily, $titleFontSize, [System.Drawing.FontStyle]::Bold)
$centerFormat = New-Object System.Drawing.StringFormat
$centerFormat.Alignment     = [System.Drawing.StringAlignment]::Center
$centerFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

$titleY = if ($Subtitle) { 140 } else { 180 }
$titleH = if ($Subtitle) { 260 } else { 300 }
$titleRect = New-Object System.Drawing.RectangleF(60, $titleY, ($Width - 120), $titleH)
$graphics.DrawString($Title, $titleFont, $whiteBrush, $titleRect, $centerFormat)
$titleFont.Dispose()

# --- サブタイトル（任意）---
if ($Subtitle) {
    $subtitleFont = New-Object System.Drawing.Font($selectedFamily, 30, [System.Drawing.FontStyle]::Regular)
    $subtitleRect = New-Object System.Drawing.RectangleF(60, 400, ($Width - 120), 140)
    $graphics.DrawString($Subtitle, $subtitleFont, $whiteBrush, $subtitleRect, $centerFormat)
    $subtitleFont.Dispose()
}

# --- "Kiwi Desk" ブランド（右下）---
$brandFont   = New-Object System.Drawing.Font($selectedFamily, 22, [System.Drawing.FontStyle]::Regular)
$rightFormat = New-Object System.Drawing.StringFormat
$rightFormat.Alignment = [System.Drawing.StringAlignment]::Far
$brandRect = New-Object System.Drawing.RectangleF(0, 570, ($Width - 30), 40)
$graphics.DrawString("Kiwi Desk", $brandFont, $whiteBrush, $brandRect, $rightFormat)
$brandFont.Dispose()

$whiteBrush.Dispose()
$graphics.Dispose()

# --- JPEG保存 ---
$outputPath = if ([System.IO.Path]::IsPathRooted($Output)) { $Output } else {
    Join-Path (Split-Path $PSScriptRoot -Parent) $Output
}
$null = New-Item -ItemType Directory -Force -Path (Split-Path $outputPath -Parent)

$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, 85L
)
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq "image/jpeg" } |
    Select-Object -First 1
$bitmap.Save($outputPath, $jpegCodec, $encoderParams)
$bitmap.Dispose()

Write-Host "Generated: $outputPath"
