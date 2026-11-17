# Diagnostic script: check UIA can find the CPF field

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
}
"@

Write-Host "=== Janelas abertas ==="
$enumProc = [Win32+EnumWindowsProc]{
    param($hWnd, $lParam)
    $sb = New-Object System.Text.StringBuilder 512
    [Win32]::GetWindowText($hWnd, $sb, 512)
    $title = $sb.ToString()
    if ($title -ne "") { Write-Host "  $title" }
    return $true
}
[Win32]::EnumWindows($enumProc, [IntPtr]::Zero)

Write-Host ""
Write-Host "=== Chrome com Educacenso/INEP ==="
$foundHwnd = [IntPtr]::Zero
$enumProc2 = [Win32+EnumWindowsProc]{
    param($hWnd, $lParam)
    $sb = New-Object System.Text.StringBuilder 512
    [Win32]::GetWindowText($hWnd, $sb, 512)
    $title = $sb.ToString()
    if ($title -match "INEP|Educacenso|Educa") {
        Write-Host "  ENCONTRADO: $title (hwnd=$hWnd)"
        $script:foundHwnd = $hWnd
    }
    return $true
}
[Win32]::EnumWindows($enumProc2, [IntPtr]::Zero)

if ($foundHwnd -eq [IntPtr]::Zero) {
    Write-Host "  NENHUMA janela com Educacenso/INEP encontrada!"
    Write-Host "  (talvez o site esteja numa aba com outro titulo)"
    exit 1
}

Write-Host ""
Write-Host "=== Explorando arvore de acessibilidade ==="
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$element = [System.Windows.Automation.AutomationElement]::FromHandle($foundHwnd)
if ($element -eq $null) { Write-Host "  ERRO: nao foi possivel obter elemento UIA"; exit 1 }

Write-Host "  Nome: $($element.Current.Name)"
Write-Host "  Class: $($element.Current.ClassName)"
Write-Host "  ControlType: $($element.Current.ControlType.ProgrammaticName)"

$foundCpf = $false
$totalElements = 0

function Search-CPF {
    param($el, $depth)
    if ($depth -gt 10) { return }
    
    $name = ""
    $ctrlType = ""
    $rect = [System.Windows.Automation.Rect]::Empty
    try { 
        $name = $el.Current.Name
        $ctrlType = $el.Current.ControlType.ProgrammaticName
        $rect = $el.Current.BoundingRectangle
        $script:totalElements++
    } catch { return }
    
    if ($name -match "cpf" -and $rect.Width -gt 0 -and $rect.Height -gt 0) {
        Write-Host "  [$depth] CPF ENCONTRADO:"
        Write-Host "       Name: '$name'"
        Write-Host "       Type: $ctrlType"
        Write-Host "       Rect: left=$($rect.Left) top=$($rect.Top) w=$($rect.Width) h=$($rect.Height)"
        $script:foundCpf = $true
    }
    
    if ($depth -le 8 -and ($name -match "cpf|aluno|documento|cadastro" -or $depth -le 2)) {
        try {
            $children = $el.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
            if ($children -ne $null) {
                for ($i = 0; $i -lt [Math]::Min($children.Count, 50); $i++) {
                    Search-CPF $children[$i] ($depth + 1)
                }
            }
        } catch {}
    }
}

Search-CPF $element 0

if (-not $foundCpf) {
    Write-Host ""
    Write-Host "  CPF nao encontrado na arvore de acessibilidade."
    Write-Host "  Total de elementos explorados: $totalElements"
    Write-Host ""
    Write-Host "  Possiveis causas:"
    Write-Host "  1. A pagina com o campo CPF nao esta aberta/focada"
    Write-Host "  2. O Chrome nao esta com acessibilidade habilitada"
    Write-Host "  3. O texto 'CPF' esta em iframe ou shadow DOM"
    Write-Host ""
    Write-Host "  Ative a acessibilidade do Chrome para teste:"
    Write-Host "  1. chrome://accessibility/"
    Write-Host "  2. Marque 'Global accessibility mode'"
    Write-Host "  3. Atualize a pagina"
}
