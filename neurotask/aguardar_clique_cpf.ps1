param($cpf)

# Format CPF if 11 digits
if ($cpf.Length -eq 11) { $cpf = $cpf.Substring(0,3) + '.' + $cpf.Substring(3,3) + '.' + $cpf.Substring(6,3) + '-' + $cpf.Substring(9,2) }

$ctrlOut = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "ctrl_out.txt"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Native {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
}
"@

Add-Type -AssemblyName System.Windows.Forms

$wshell = New-Object -ComObject WScript.Shell

# Find Chrome and bring to foreground
$procs = Get-Process chrome -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" }
if ($procs) {
    [Native]::SetForegroundWindow($procs[0].MainWindowHandle)
    Start-Sleep -Milliseconds 100
    $wshell.AppActivate($procs[0].Id) | Out-Null
    Start-Sleep -Milliseconds 100
}

# Type CPF via clipboard paste + Enter
[System.Windows.Forms.Clipboard]::SetText($cpf)
Start-Sleep -Milliseconds 20
$wshell.SendKeys("^a{BACKSPACE}^v")
Start-Sleep -Milliseconds 50
$wshell.SendKeys("{ENTER}")
Start-Sleep -Milliseconds 200

# Monitor for panel response (wait indefinitely)
$respCode = -1
while ($respCode -lt 0) {
    Start-Sleep -Milliseconds 200
    if (-not (Test-Path $ctrlOut)) { continue }
    try {
        $d = Get-Content $ctrlOut -Raw -Encoding ASCII
        Remove-Item $ctrlOut -Force -ErrorAction SilentlyContinue
        $d = $d.Trim()
        if ($d -ne "") {
            $p = $d -split '\|'
            if ($p.Count -ge 2) { $respCode = [int]$p[1] }
        }
    } catch {}
}

exit $respCode
