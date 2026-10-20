$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$w = 1200; $h = 630
$bmp = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = "AntiAlias"
$g.TextRenderingHint = "AntiAliasGridFit"

$rect = New-Object System.Drawing.Rectangle(0, 0, $w, $h)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  $rect, [System.Drawing.Color]::FromArgb(11,11,20), [System.Drawing.Color]::FromArgb(20,20,36), 45)
$g.FillRectangle($bg, 0, 0, $w, $h)

# brilho sutil
$glow = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  $rect, [System.Drawing.Color]::FromArgb(124,92,255), [System.Drawing.Color]::FromArgb(0,224,198), 45)
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$path.AddEllipse(-180, -120, 620, 620)
$g.FillPath($glow, $path)

# estrela
$star = New-Object System.Drawing.Drawing2D.GraphicsPath
$pts = @()
for ($i = 0; $i -lt 10; $i++) {
  $ang = [Math]::PI / 2 + $i * [Math]::PI / 5
  $rad = if ($i % 2 -eq 0) { 58 } else { 26 }
  $x = 118 + [Math]::Cos($ang) * $rad
  $y = 138 - [Math]::Sin($ang) * $rad
  $pts += New-Object System.Drawing.PointF($x, $y)
}
$star.AddPolygon($pts)
$starBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.RectangleF(50,70,136,136)),
  [System.Drawing.Color]::FromArgb(124,92,255), [System.Drawing.Color]::FromArgb(0,224,198), 45)
$g.FillPath($starBrush, $star)

$fontName = "Segoe UI"
$fBrand = New-Object System.Drawing.Font($fontName, 30, [System.Drawing.FontStyle]::Bold)
$fTitle = New-Object System.Drawing.Font($fontName, 50, [System.Drawing.FontStyle]::Bold)
$fSub   = New-Object System.Drawing.Font($fontName, 24, [System.Drawing.FontStyle]::Regular)
$white  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(238,240,255))
$teal   = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0,224,198))

$g.DrawString("NeuroTask", $fBrand, $teal, 190, 118)
$g.DrawString("Transforme qualquer caos", $fTitle, $white, 112, 225)
$g.DrawString("em clareza e recompensa", $fTitle, $white, 112, 288)
$g.DrawString("em 120 segundos.", $fTitle, $white, 112, 351)

$g.DrawString("Micro-desafios de 60-180s  |  Recompensas instantaneas  |  Streaks", $fSub, $teal, 112, 462)
$g.DrawString("Comece agora, sem cadastro:  seu-neurotask.com", $fSub, $white, 112, 508)

$bmp.Save("C:\EXECUTAVEL CENSO 2026\neurotask\og.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output "og.png gerado"
