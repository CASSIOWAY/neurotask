$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $scriptPath "SistemaHotel.ps1"

if (-not (Test-Path $mainScript)) {
    Write-Host "ERRO: Arquivo principal não encontrado!" -ForegroundColor Red
    Write-Host "Caminho: $mainScript" -ForegroundColor Red
    $null = Read-Host "Pressione Enter para sair"
    exit
}

# Oculta a janela do console
try {
    $consoleHandle = (Get-Process -Id $pid).MainWindowHandle
    if ($consoleHandle -ne [IntPtr]::Zero) {
        $windowCode = @'
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
        $win32 = Add-Type -MemberDefinition $windowCode -Name "Win32Show" -Namespace Win32 -PassThru
        $win32::ShowWindow($consoleHandle, 0) | Out-Null
    }
} catch {}

try {
    & $mainScript
}
catch {
    try { $win32::ShowWindow($consoleHandle, 1) | Out-Null } catch {}
    Write-Host "Erro ao iniciar o sistema:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    $null = Read-Host "Pressione Enter para continuar..."
}



