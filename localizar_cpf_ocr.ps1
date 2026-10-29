param($outFile)

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptPath "ocr_config.txt"

# Read API key
$apiKey = ""
if (Test-Path $configFile) {
    $apiKey = (Get-Content $configFile -Raw -Encoding ASCII).Trim()
}
if ([string]::IsNullOrEmpty($apiKey)) { exit 1 }

# Find Chrome/Edge window
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
public struct RECT { public int left; public int top; public int right; public int bottom; }
"@

$hwnd = [IntPtr]::Zero
$procs = Get-Process chrome -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    if ($p.MainWindowTitle -match "INEP|Educacenso") { $hwnd = $p.MainWindowHandle; break }
}
if ($hwnd -eq [IntPtr]::Zero) {
    $procs = Get-Process msedge -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        if ($p.MainWindowTitle -match "INEP|Educacenso") { $hwnd = $p.MainWindowHandle; break }
    }
}
if ($hwnd -eq [IntPtr]::Zero) { exit 1 }

$rc = New-Object RECT
[Win32]::GetWindowRect($hwnd, [ref]$rc)
if ($rc.right -le $rc.left -or $rc.bottom -le $rc.top) { exit 1 }

# Capture Chrome window screenshot
Add-Type -AssemblyName System.Drawing
$w = $rc.right - $rc.left
$h = $rc.bottom - $rc.top
$bounds = [System.Drawing.Rectangle]::new($rc.left, $rc.top, $w, $h)
$bitmap = New-Object System.Drawing.Bitmap $w, $h
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$graphics.Dispose()

# Convert to base64
$ms = New-Object System.IO.MemoryStream
$bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$base64 = [Convert]::ToBase64String($ms.ToArray())
$ms.Dispose()
$bitmap.Dispose()

# Call Google Cloud Vision API
$body = @{
    requests = @(@{
        image = @{ content = $base64 }
        features = @(@{ type = "TEXT_DETECTION"; maxResults = 15 })
    })
} | ConvertTo-Json -Depth 10 -Compress

try {
    $response = Invoke-RestMethod -Uri "https://vision.googleapis.com/v1/images:annotate?key=$apiKey" `
        -Method Post -ContentType "application/json" -Body $body -TimeoutSec 30
} catch { exit 1 }

if (-not $response.responses[0].textAnnotations) { exit 1 }

# Find "CPF" in detected text
$cpfRelX = -1; $cpfRelY = -1
foreach ($ann in $response.responses[0].textAnnotations) {
    $desc = ($ann.description -replace '\s', '').ToUpperInvariant()
    if ($desc -eq "CPF" -and $ann.boundingPoly.vertices) {
        $xs = @(); $ys = @()
        $valid = $true
        foreach ($v in $ann.boundingPoly.vertices) {
            if ($null -eq $v.x -or $null -eq $v.y) { $valid = $false; break }
            $xs += [int]$v.x
            $ys += [int]$v.y
        }
        if (-not $valid) { continue }
        $minX = ($xs | Measure-Object -Minimum).Minimum
        $maxX = ($xs | Measure-Object -Maximum).Maximum
        $avgY = ($ys | Measure-Object -Average).Average
        $labelW = $maxX - $minX
        # CPF input field is typically to the right of the label
        $fieldX = $minX + $labelW + 10
        $fieldY = [int]$avgY
        # Verify it's within window bounds
        if ($fieldX -ge 0 -and $fieldX -lt $w -and $fieldY -ge 0 -and $fieldY -lt $h) {
            $cpfRelX = $fieldX
            $cpfRelY = $fieldY
            break
        }
    }
    # Also try "CPF:" with colon
    if ($desc -eq "CPF:" -and $ann.boundingPoly.vertices) {
        $xs = @(); $ys = @()
        $valid = $true
        foreach ($v in $ann.boundingPoly.vertices) {
            if ($null -eq $v.x -or $null -eq $v.y) { $valid = $false; break }
            $xs += [int]$v.x
            $ys += [int]$v.y
        }
        if (-not $valid) { continue }
        $maxX = ($xs | Measure-Object -Maximum).Maximum
        $avgY = ($ys | Measure-Object -Average).Average
        $fieldX = $maxX + 10
        $fieldY = [int]$avgY
        if ($fieldX -ge 0 -and $fieldX -lt $w -and $fieldY -ge 0 -and $fieldY -lt $h) {
            $cpfRelX = $fieldX
            $cpfRelY = $fieldY
            break
        }
    }
}

if ($cpfRelX -lt 0) { exit 1 }

# Output in same format as get_cursor_pos.ps1
"$cpfRelX|$cpfRelY|$($rc.left)|$($rc.top)" | Out-File -FilePath $outFile -Encoding ASCII -NoNewline
exit 0
