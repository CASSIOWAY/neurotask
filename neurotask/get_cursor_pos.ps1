param($outFile)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
}
public struct POINT { public int X; public int Y; }
public struct RECT { public int left; public int top; public int right; public int bottom; }
"@

$pt = New-Object POINT
[Win32]::GetCursorPos([ref]$pt)

# Find Chrome/Edge window to capture its position
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

if ($hwnd -ne [IntPtr]::Zero) {
    $rc = New-Object RECT
    [Win32]::GetWindowRect($hwnd, [ref]$rc)
    # Store: relX|relY|winLeft|winTop
    $relX = $pt.X - $rc.left
    $relY = $pt.Y - $rc.top
    "$relX|$relY|$rc.left|$rc.top" | Out-File -FilePath $outFile -Encoding ASCII -NoNewline
} else {
    # Fallback: absolute coordinates
    "$($pt.X)|$($pt.Y)" | Out-File -FilePath $outFile -Encoding ASCII -NoNewline
}
