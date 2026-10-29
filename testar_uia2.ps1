# Diagnostic v2: find Chrome render widget host and search its accessibility tree

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindowEx(IntPtr hWndParent, IntPtr hWndChildAfter, string lpszClass, string lpszWindow);
    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(IntPtr hWndParent, EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
}
"@

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# Find the correct Chrome window
$targetHwnd = [IntPtr]::Zero
$enumProc = [Win32+EnumWindowsProc]{
    param($hWnd, $lParam)
    $sb = New-Object System.Text.StringBuilder 512
    [Win32]::GetWindowText($hWnd, $sb, 512)
    $title = $sb.ToString()
    if ($title -match "Educacenso|INEP|SIG.*Aluno|Cadastro.*Aluno") {
        $script:targetHwnd = $hWnd
    }
    return $true
}
[Win32]::EnumWindows($enumProc, [IntPtr]::Zero)

if ($targetHwnd -eq [IntPtr]::Zero) { Write-Host "Janela nao encontrada"; exit 1 }
Write-Host "Janela principal: hwnd=$targetHwnd"

# List child windows
Write-Host ""
Write-Host "Filhos:"
$childProc = [Win32+EnumWindowsProc]{
    param($hWnd, $lParam)
    $sb = New-Object System.Text.StringBuilder 512
    [Win32]::GetWindowText($hWnd, $sb, 512)
    $title = $sb.ToString()
    $className = New-Object System.Text.StringBuilder 256
    # Can't get class name easily in PowerShell, skip
    if ($title -ne "") { Write-Host "  hwnd=$hWnd title='$title'" }
    return $true
}
[Win32]::EnumChildWindows($targetHwnd, $childProc, [IntPtr]::Zero)

# Try UIA on main window with TreeScope.Descendants
Write-Host ""
Write-Host "UIA na janela principal (Descendants):"
$element = [System.Windows.Automation.AutomationElement]::FromHandle($targetHwnd)
try {
    $allCondition = [System.Windows.Automation.Condition]::TrueCondition
    $all = $element.FindAll([System.Windows.Automation.TreeScope]::Descendants, $allCondition)
    Write-Host "  Total elementos: $($all.Count)"
    for ($i = 0; $i -lt [Math]::Min($all.Count, 30); $i++) {
        $name = $all[$i].Current.Name
        $ctrl = $all[$i].Current.ControlType.ProgrammaticName
        $rect = $all[$i].Current.BoundingRectangle
        if ($name -ne "" -and $rect.Width -gt 0) {
            Write-Host "  [$i] '$name' ($ctrl) rect=$($rect.Left),$($rect.Top) $($rect.Width)x$($rect.Height)"
        }
    }
    
    # Search specifically for "CPF" in all descendants
    Write-Host ""
    Write-Host "Buscando 'CPF'..."
    $found = $false
    for ($i = 0; $i -lt $all.Count; $i++) {
        $name = $all[$i].Current.Name
        if ($name -match "CPF" -or $name -match "cpf") {
            $rect = $all[$i].Current.BoundingRectangle
            $ctrl = $all[$i].Current.ControlType.ProgrammaticName
            Write-Host "  ENCONTRADO: '$name' ($ctrl) rect=$($rect.Left),$($rect.Top) $($rect.Width)x$($rect.Height)"
            $found = $true
        }
    }
    if (-not $found) { Write-Host "  Nao encontrou 'CPF' em $($all.Count) elementos" }
} catch {
    Write-Host "  ERRO: $_"
}

# Try to find render widget host
$renderHwnd = [Win32]::FindWindowEx($targetHwnd, [IntPtr]::Zero, "Chrome_RenderWidgetHostHWND", $null)
if ($renderHwnd -ne [IntPtr]::Zero) {
    Write-Host ""
    Write-Host "RenderWidgetHost encontrado: hwnd=$renderHwnd"
    $renderElement = [System.Windows.Automation.AutomationElement]::FromHandle($renderHwnd)
    if ($renderElement -ne $null) {
        try {
            $renderAll = $renderElement.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
            Write-Host "  Elementos no render: $($renderAll.Count)"
            for ($i = 0; $i -lt [Math]::Min($renderAll.Count, 20); $i++) {
                $name = $renderAll[$i].Current.Name
                $ctrl = $renderAll[$i].Current.ControlType.ProgrammaticName
                $rect = $renderAll[$i].Current.BoundingRectangle
                if ($name -ne "" -and $rect.Width -gt 0) {
                    Write-Host "  [$i] '$name' ($ctrl)"
                }
            }
        } catch { Write-Host "  ERRO no render: $_" }
    }
} else {
    Write-Host "RenderWidgetHost nao encontrado (pode ser Chrome novo)" 
}
