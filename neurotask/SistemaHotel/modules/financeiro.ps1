param(
    [string]$Acao = "listar",
    [string]$DadosJSON = ""
)


switch ($Acao) {
    "listar" {
        $data = Get-DadosFinanceiro
        if ($data) { $data.lancamentos | ConvertTo-Json -Depth 3 }
    }
    "saldos" {
        $data = Get-DadosFinanceiro
        if ($data) { $data.saldos_mensais | ConvertTo-Json -Depth 2 }
    }
    "dashboard" {
        $data = Get-DadosFinanceiro
        if (-not $data) { "{}" | ConvertTo-Json; return }
        $mesAtual = (Get-Date -Format "yyyy-MM")
        $lancF = @($data.lancamentos | Where-Object { $_ -and $_.data -like "$mesAtual-*" })
        $recMes = [math]::Round(($lancF | Where-Object { $_.tipo -eq "receita" } | Measure-Object -Property valor -Sum).Sum, 2)
        $despMes = [math]::Round(($lancF | Where-Object { $_.tipo -eq "despesa" } | Measure-Object -Property valor -Sum).Sum, 2)
        $saldoMes = [math]::Round($recMes - $despMes, 2)
        @{receitas_mes=$recMes; despesas_mes=$despMes; saldo_mes=$saldoMes} | ConvertTo-Json
    }
}



