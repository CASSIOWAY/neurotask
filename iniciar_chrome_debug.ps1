# Inicia uma instancia SEPARADA do Chrome para o robo
# Nao interfere com o Chrome existente do usuario

$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$robotProfile = "$env:LOCALAPPDATA\Chrome_Robot_Profile"

if (-not (Test-Path $chromePath)) {
    $chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chromePath)) {
    Write-Host "Chrome nao encontrado"
    exit 1
}

# Check if robot Chrome is already running with debug port
try {
    $resp = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "Chrome com debug ja esta rodando ($($resp.Count) abas)"
    exit 0
} catch {
    # Not running, launch new instance
}

# Ensure profile directory exists
if (-not (Test-Path $robotProfile)) { New-Item -ItemType Directory -Path $robotProfile -Force | Out-Null }

$args = @(
    "--remote-debugging-port=9222",
    "--remote-allow-origins=*",
    "--no-first-run",
    "--no-default-browser-check",
    "--user-data-dir=$robotProfile",
    "--new-window",
    "https://educacenso.inep.gov.br/"
)

Write-Host "Iniciando Chrome do robo (perfil separado)..."
Start-Process -FilePath $chromePath -ArgumentList $args
Start-Sleep -Seconds 5

# Verify
try {
    $resp = Invoke-RestMethod -Uri "http://127.0.0.1:9222/json" -TimeoutSec 3 -ErrorAction Stop
    Write-Host "Chrome do robo iniciado na porta 9222 ($($resp.Count) abas)"
} catch {
    Write-Host "ERRO: Chrome nao responde na porta 9222."
    exit 1
}
