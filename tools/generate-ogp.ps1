# OGP画像生成スクリプト
#
# 使い方:
#   cd C:\Users\khina\Quenich.github.io
#   .\tools\generate-ogp.ps1 -Title "タイトル" -Subtitle "サブ" -Background "assets\img\backgrounds\nz1.jpg" -Output "assets\img\posts\filename.jpg"
#
# -Background を省略すると assets\img\backgrounds\ 内の画像をランダムに使用
# 背景フォルダに画像がなければグラデーションにフォールバック

param(
    [Parameter(Mandatory=$true)]
    [string]$Title,

    [string]$Subtitle = "",

    [string]$Background = "",

    [Parameter(Mandatory=$true)]
    [string]$Output,

    # オーバーレイの濃さ 0(透明)〜255(不透明)。写真が明るいなら上げる
    [int]$Overlay = 145,

    [int]$Width  = 1200,
    [int]$Height = 630
)

Add-Type -AssemblyName System.Drawing

$bitmap   = New-Object System.Drawing.Bitmap($Width, $Height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# --- 背景の解決 ---
$bgRoot = Join-Path (Split-Path $PSScriptRoot -Parent) "assets\img\backgrounds"

# 1. 明示指定があれば優先
# 2. なければ backgrounds/ からランダム
# 3. 画像がなければグラデーション
if ($Background -and (Test-Path $Background)) {
    $bgPath = (Resolve-Path $Background).Path
} elseif (Test-Path $bgRoot) {
    $bgFiles = Get-ChildItem $bgRoot -Include "*.jpg","*.jpeg","*.png" -Recurse
    if ($bgFiles.Count -gt 0) {
        $bgPath = ($bgFiles | Get-Random).FullName
    }
}

if ($bgPath) {
    $bgImage = [System.Drawing.Image]::FromFile($bgPath)

    # アスペクト比を保ちながらクロップして全面に敷く
    $srcRatio = $bgImage.Width  / $bgImage.Height
    $dstRatio = $Width / $Height
    if ($srcRatio -gt $dstRatio) {
        # 横が余る → 高さ合わせでクロップ
        $srcH = $bgImage.Height
        $srcW = [int]($srcH * $dstRatio)
        $srcX = [int](($bgImage.Width - $srcW) / 2)
        $srcRect = New-Object System.Drawing.Rectangle($srcX, 0, $srcW, $srcH)
    } else {
        # 縦が余る → 幅合わせでクロップ
        $srcW = $bgImage.Width
        $srcH = [int]($srcW / $dstRatio)
        $srcY = [int](($bgImage.Height - $srcH) / 2)
        $srcRect = New-Object System.Drawing.Rectangle(0, $srcY, $srcW, $srcH)
    }
    $dstRect = New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)
    $graphics.DrawImage($bgImage, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $bgImage.Dispose()
} else {
    # グラデーションフォールバック
    $gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point(0, 0)),
        (New-Object System.Drawing.Point($Width, $Height)),
        [System.Drawing.Color]::FromArgb(20, 55, 45),
        [System.Drawing.Color]::FromArgb(10, 25, 55)
    )
    $graphics.FillRectangle($gradBrush, 0, 0, $Width, $Height)
    $gradBrush.Dispose()
}

# --- 半透明オーバーレイ（グラデーション：下を少し暗くしてテキストを読みやすく）---
$overlayTop    = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb([int]($Overlay * 0.85), 0, 0, 0))
$overlayBottom = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb([int]($Overlay * 1.15), 0, 0, 0))
# 上半分
$graphics.FillRectangle($overlayTop, 0, 0, $Width, [int]($Height * 0.6))
# 下半分（ブランド名エリアを少し暗く）
$graphics.FillRectangle($overlayBottom, 0, [int]($Height * 0.6), $Width, [int]($Height * 0.4))
$overlayTop.Dispose()
$overlayBottom.Dispose()

# --- フォント設定 ---
$fontFamilies = @("Yu Gothic", "Yu Gothic UI", "Meiryo", "MS Gothic")
$selectedFamily = $fontFamilies | Where-Object {
    ([System.Drawing.FontFamily]::Families | Select-Object -ExpandProperty Name) -contains $_
} | Select-Object -First 1
if (-not $selectedFamily) { $selectedFamily = "Arial" }

$whiteBrush  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 0, 0, 0))

$centerFormat = New-Object System.Drawing.StringFormat
$centerFormat.Alignment     = [System.Drawing.StringAlignment]::Center
$centerFormat.LineAlignment = [System.Drawing.StringAlignment]::Center

# ドロップシャドウを付けて描画するヘルパー
function Draw-TextWithShadow($g, $text, $font, $x, $y, $w, $h, $fmt, $shadow, $white) {
    $shadowRect = New-Object System.Drawing.RectangleF(($x + 2), ($y + 2), $w, $h)
    $textRect   = New-Object System.Drawing.RectangleF($x, $y, $w, $h)
    $g.DrawString($text, $font, $shadow, $shadowRect, $fmt)
    $g.DrawString($text, $font, $white,  $textRect,   $fmt)
}

# --- タイトル ---
$titleFontSize = if ($Title.Length -le 18) { 54 } elseif ($Title.Length -le 26) { 46 } else { 37 }
$titleFont = New-Object System.Drawing.Font($selectedFamily, $titleFontSize, [System.Drawing.FontStyle]::Bold)

$titleY = if ($Subtitle) { 130 } else { 170 }
$titleH = if ($Subtitle) { 270 } else { 310 }
Draw-TextWithShadow $graphics $Title $titleFont 70 $titleY ($Width - 140) $titleH $centerFormat $shadowBrush $whiteBrush
$titleFont.Dispose()

# --- サブタイトル（任意）---
if ($Subtitle) {
    # 区切り線
    $lineY  = 408
    $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 1.5)
    $graphics.DrawLine($linePen, 80, $lineY, ($Width - 80), $lineY)
    $linePen.Dispose()

    $subtitleFont = New-Object System.Drawing.Font($selectedFamily, 28, [System.Drawing.FontStyle]::Bold)
    Draw-TextWithShadow $graphics $Subtitle $subtitleFont 70 415 ($Width - 140) 130 $centerFormat $shadowBrush $whiteBrush
    $subtitleFont.Dispose()
}

# --- "Kiwi Desk" ブランド（右下）---
$brandFont   = New-Object System.Drawing.Font($selectedFamily, 21, [System.Drawing.FontStyle]::Regular)
$rightFormat = New-Object System.Drawing.StringFormat
$rightFormat.Alignment = [System.Drawing.StringAlignment]::Far
$brandRect = New-Object System.Drawing.RectangleF(0, 574, ($Width - 32), 38)
$graphics.DrawString("Kiwi Desk", $brandFont, $whiteBrush, $brandRect, $rightFormat)
$brandFont.Dispose()

$whiteBrush.Dispose()
$shadowBrush.Dispose()
$graphics.Dispose()

# --- JPEG保存 ---
$outputPath = if ([System.IO.Path]::IsPathRooted($Output)) { $Output } else {
    Join-Path (Split-Path $PSScriptRoot -Parent) $Output
}
$null = New-Item -ItemType Directory -Force -Path (Split-Path $outputPath -Parent)

$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, 88L
)
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
$bitmap.Save($outputPath, $jpegCodec, $encoderParams)
$bitmap.Dispose()

$bgUsed = if ($bgPath) { Split-Path $bgPath -Leaf } else { "gradient" }
Write-Host "Generated: $outputPath  [bg: $bgUsed]"
