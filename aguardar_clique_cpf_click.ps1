param($cpf)

$ctrlOut = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "ctrl_out.txt"

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Native {
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder className, int count);
}
"@

Add-Type -AssemblyName System.Windows.Forms

$wshell = New-Object -ComObject WScript.Shell
$prevBtn = 0
$typed = $false

while (-not $typed) {
    if (Test-Path $ctrlOut) {
        Start-Sleep -Milliseconds 50
        try {
            $data = Get-Content $ctrlOut -Raw -Encoding ASCII
            Remove-Item $ctrlOut -Force -ErrorAction SilentlyContinue
            $data = $data.Trim()
            if ($data -ne "") {
                $parts = $data -split '\|'
                if ($parts.Count -ge 2) { exit [int]$parts[1] }
            }
        } catch {}
    }

    $curBtn = [Native]::GetAsyncKeyState(0x01) -band 0x8000
    if ($curBtn -ne 0 -and $prevBtn -eq 0) {
        Start-Sleep -Milliseconds 100
        $hwnd = [Native]::GetForegroundWindow()
        $sb = New-Object System.Text.StringBuilder 256
        [Native]::GetClassName($hwnd, $sb, 256) | Out-Null
        $class = $sb.ToString()
        if ($class -notmatch "HTA|mshta|IEFrame") {
            [System.Windows.Forms.Clipboard]::SetText($cpf)
            Start-Sleep -Milliseconds 20
            $wshell.SendKeys("^a{BACKSPACE}^v")
            Start-Sleep -Milliseconds 30
            $wshell.SendKeys("{ENTER}")
            $typed = $true
        }
    }
    $prevBtn = $curBtn
    Start-Sleep -Milliseconds 40
}

while ($true) {
    if (Test-Path $ctrlOut) {
        Start-Sleep -Milliseconds 50
        try {
            $data = Get-Content $ctrlOut -Raw -Encoding ASCII
            Remove-Item $ctrlOut -Force -ErrorAction SilentlyContinue
            $data = $data.Trim()
            if ($data -ne "") {
                $parts = $data -split '\|'
                if ($parts.Count -ge 2) { exit [int]$parts[1] }
            }
        } catch {}
    }
    Start-Sleep -Milliseconds 50
}
