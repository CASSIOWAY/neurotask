param($cpf)

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
$dllPath = Join-Path $scriptPath "cpf_click.dll"

if (Test-Path $dllPath) {
    Add-Type -Path $dllPath
} else {
    Add-Type -OutputAssembly $dllPath @"
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct RECT { public int left; public int top; public int right; public int bottom; }

[StructLayout(LayoutKind.Sequential)]
public struct MOUSEINPUT {
    public int dx; public int dy; public int mouseData; public int dwFlags; public int time; public IntPtr dwExtraInfo;
}

[StructLayout(LayoutKind.Explicit)]
public struct INPUTUNION {
    [FieldOffset(0)] public MOUSEINPUT mi;
}

[StructLayout(LayoutKind.Sequential)]
public struct INPUT {
    public int type; public INPUTUNION u;
}

public class Native {
    [DllImport("user32.dll")]
    public static extern int SendInput(int cInputs, INPUT[] pInputs, int cbSize);
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern int GetSystemMetrics(int nIndex);
    [DllImport("user32.dll")]
    public static extern IntPtr GetMessageExtraInfo();
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    public const int INPUT_MOUSE = 0;
    public const int MOUSEEVENTF_MOVE = 0x0001;
    public const int MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const int MOUSEEVENTF_LEFTUP = 0x0004;
    public const int MOUSEEVENTF_ABSOLUTE = 0x8000;
    public const int SM_CXSCREEN = 0;
    public const int SM_CYSCREEN = 1;
}
"@
}

# Find Chrome/Edge
$procs = Get-Process chrome -ErrorAction SilentlyContinue
$hwnd = [IntPtr]::Zero
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

$fgHwnd = [Native]::GetForegroundWindow()
if ($fgHwnd -ne $hwnd) {
    [Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 100
}

# Read stored coordinates (format: relX|relY|winLeft|winTop or absX|absY)
$posFile = Join-Path $scriptPath "cpf_pos.txt"
if (-not (Test-Path $posFile)) { exit 1 }
$posData = Get-Content $posFile -Raw -Encoding ASCII
$parts = $posData.Trim() -split '\|'
if ($parts.Count -lt 2) { exit 1 }
$cpfX = [int]$parts[0]
$cpfY = [int]$parts[1]

# If we have window-relative coords (4 parts), recalculate for window movement
if ($parts.Count -ge 4) {
    $relX = [int]$parts[0]; $relY = [int]$parts[1]
    $oldLeft = [int]$parts[2]; $oldTop = [int]$parts[3]
    $rect = New-Object RECT
    [Native]::GetWindowRect($hwnd, [ref]$rect)
    $curLeft = $rect.left; $curTop = $rect.top
    $offX = $curLeft - $oldLeft; $offY = $curTop - $oldTop
    $cpfX = $relX + $offX; $cpfY = $relY + $offY

    # Update stored window position for next run
    $newData = "$relX|$relY|$curLeft|$curTop"
    [System.IO.File]::WriteAllText($posFile, $newData, [System.Text.Encoding]::ASCII)
}

# Convert to absolute 0..65535
$sw = [Native]::GetSystemMetrics([Native]::SM_CXSCREEN)
$sh = [Native]::GetSystemMetrics([Native]::SM_CYSCREEN)
$ax = [int](($cpfX * 65535) / $sw)
$ay = [int](($cpfY * 65535) / $sh)

# Scroll to top of page so field is at calibrated position
$wshell = New-Object -ComObject "WScript.Shell"
$wshell.SendKeys("^{HOME}")  # Ctrl+Home = scroll to top in browser
Start-Sleep -Milliseconds 150

# Click at CPF coordinates via SendInput to focus the field
$cb = [System.Runtime.InteropServices.Marshal]::SizeOf([INPUT])
$inputs = New-Object INPUT[] 2
$inputs[0] = New-Object INPUT; $inputs[0].type = [Native]::INPUT_MOUSE
$inputs[0].u.mi = New-Object MOUSEINPUT
$inputs[0].u.mi.dx = $ax; $inputs[0].u.mi.dy = $ay
$inputs[0].u.mi.dwFlags = [Native]::MOUSEEVENTF_MOVE -bor [Native]::MOUSEEVENTF_ABSOLUTE -bor [Native]::MOUSEEVENTF_LEFTDOWN
$inputs[0].u.mi.dwExtraInfo = [Native]::GetMessageExtraInfo()
$inputs[1] = New-Object INPUT; $inputs[1].type = [Native]::INPUT_MOUSE
$inputs[1].u.mi = New-Object MOUSEINPUT
$inputs[1].u.mi.dwFlags = [Native]::MOUSEEVENTF_LEFTUP
$inputs[1].u.mi.dwExtraInfo = [Native]::GetMessageExtraInfo()
[Native]::SendInput(2, $inputs, $cb)
Start-Sleep -Milliseconds 200

# Second click to ensure field is active (some fields need two clicks)
$inputs2 = New-Object INPUT[] 2
$inputs2[0] = New-Object INPUT; $inputs2[0].type = [Native]::INPUT_MOUSE
$inputs2[0].u.mi = New-Object MOUSEINPUT
$inputs2[0].u.mi.dx = $ax; $inputs2[0].u.mi.dy = $ay
$inputs2[0].u.mi.dwFlags = [Native]::MOUSEEVENTF_MOVE -bor [Native]::MOUSEEVENTF_ABSOLUTE -bor [Native]::MOUSEEVENTF_LEFTDOWN
$inputs2[0].u.mi.dwExtraInfo = [Native]::GetMessageExtraInfo()
$inputs2[1] = New-Object INPUT; $inputs2[1].type = [Native]::INPUT_MOUSE
$inputs2[1].u.mi = New-Object MOUSEINPUT
$inputs2[1].u.mi.dwFlags = [Native]::MOUSEEVENTF_LEFTUP
$inputs2[1].u.mi.dwExtraInfo = [Native]::GetMessageExtraInfo()
[Native]::SendInput(2, $inputs2, $cb)
Start-Sleep -Milliseconds 400

# Reforca foco no Chrome antes de digitar
$fgHwnd2 = [Native]::GetForegroundWindow()
if ($fgHwnd2 -ne $hwnd) {
    [Native]::SetForegroundWindow($hwnd)
    Start-Sleep -Milliseconds 200
}

# Send Ctrl+A + Backspace + CPF + Enter
$wshell.SendKeys("^a{BACKSPACE}$cpf{ENTER}")
