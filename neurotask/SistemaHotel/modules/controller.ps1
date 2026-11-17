param(
    [string]$Modulo = "dashboard",
    [string]$Acao = "listar",
    [string]$DadosJSON = ""
)

$ModulesDir = $PSScriptRoot

$Modulos = @{
    "reservas"   = Join-Path $ModulesDir "reservas.ps1"
    "quartos"    = Join-Path $ModulesDir "quartos.ps1"
    "hospedes"   = Join-Path $ModulesDir "hospedes.ps1"
    "financeiro" = Join-Path $ModulesDir "financeiro.ps1"
    "analise"    = Join-Path $ModulesDir "analise.ps1"
    "whatsapp"   = Join-Path $ModulesDir "whatsapp.ps1"
}

if ($Modulos.ContainsKey($Modulo)) {
    $result = & $Modulos[$Modulo] -Acao $Acao -DadosJSON $DadosJSON
    $result
} else {
    @{erro = "Módulo '$Modulo' não encontrado. Módulos disponíveis: $($Modulos.Keys -join ', ')"} | ConvertTo-Json -Compress
}



