param(
    [string]$Acao = "dashboard",
    [string]$DadosJSON = ""
)


switch ($Acao) {
    "dashboard" {
        $reservas = Get-DadosReservas
        $quartos = Get-DadosQuartos
        $hospedes = Get-DadosHospedes
        $financeiro = Get-DadosFinanceiro

        $totalReservas = if ($reservas) { $reservas.reservas.Count } else { 0 }
        $totalQuartos = if ($quartos) { $quartos.quartos.Count } else { 0 }
        $ocupados = if ($quartos) { @($quartos.quartos | Where-Object { $_.status -eq "ocupado" }).Count } else { 0 }
        $reservados = if ($quartos) { @($quartos.quartos | Where-Object { $_.status -eq "reservado" }).Count } else { 0 }
        $disponiveis = if ($quartos) { @($quartos.quartos | Where-Object { $_.status -eq "disponivel" }).Count } else { 0 }
        $taxaOcupacao = if ($totalQuartos -gt 0) { [math]::Round(($ocupados + $reservados) / $totalQuartos * 100, 1) } else { 0 }
        $totalHospedes = if ($hospedes) { $hospedes.hospedes.Count } else { 0 }

        $receitasMes = 0; $despesasMes = 0; $saldoAtual = 0
        if ($financeiro) {
            $mesAtual = (Get-Date -Format "yyyy-MM")
            $lancamentosMes = @($financeiro.lancamentos | Where-Object { $_.data -like "$mesAtual-*" })
            $receitasMes = [math]::Round(($lancamentosMes | Where-Object { $_.tipo -eq "receita" } | Measure-Object -Property valor -Sum).Sum, 2)
            $despesasMes = [math]::Round(($lancamentosMes | Where-Object { $_.tipo -eq "despesa" } | Measure-Object -Property valor -Sum).Sum, 2)
            $saldoAtual = [math]::Round($receitasMes - $despesasMes, 2)
        }

        $hoje = Get-Date -Format "yyyy-MM-dd"
        $checkinsHoje = if ($reservas) { @($reservas.reservas | Where-Object { $_.data_checkin -eq $hoje -and $_.status -ne "cancelada" }).Count } else { 0 }
        $checkoutsHoje = if ($reservas) { @($reservas.reservas | Where-Object { $_.data_checkout -eq $hoje -and $_.status -ne "cancelada" }).Count } else { 0 }

        [PSCustomObject]@{
            total_quartos = $totalQuartos
            quartos_disponiveis = $disponiveis
            quartos_ocupados = $ocupados
            quartos_reservados = $reservados
            taxa_ocupacao = $taxaOcupacao
            total_reservas = $totalReservas
            total_hospedes = $totalHospedes
            receitas_mes = $receitasMes
            despesas_mes = $despesasMes
            saldo_atual = $saldoAtual
            checkins_hoje = $checkinsHoje
            checkouts_hoje = $checkoutsHoje
        } | ConvertTo-Json
    }

    "ocupacao_mensal" {
        $reservas = Get-DadosReservas
        $quartos = Get-DadosQuartos
        if (-not $reservas -or -not $quartos) { "[]" | ConvertTo-Json; return }
        $totalQuartos = $quartos.quartos.Count
        $meses = @("2026-01","2026-02","2026-03","2026-04","2026-05","2026-06","2026-07")
        $result = foreach ($mes in $meses) {
            $reservasMes = @($reservas.reservas | Where-Object { $_.data_checkin -like "$mes-*" -and $_.status -ne "cancelada" })
            $noitesVendidas = ($reservasMes | Measure-Object -Property noites -Sum).Sum
            $diasMes = [DateTime]::DaysInMonth($mes.Split('-')[0], $mes.Split('-')[1])
            $capacidade = $totalQuartos * $diasMes
            $taxa = if ($capacidade -gt 0) { [math]::Round($noitesVendidas / $capacidade * 100, 1) } else { 0 }
            [PSCustomObject]@{mes=$mes; taxa_ocupacao=$taxa; noites_vendidas=$noitesVendidas; capacidade_total=$capacidade}
        }
        $result | ConvertTo-Json -Depth 2
    }

    "receitas_mensais" {
        $financeiro = Get-DadosFinanceiro
        if (-not $financeiro) { "[]" | ConvertTo-Json; return }
        $financeiro.saldos_mensais | ConvertTo-Json -Depth 2
    }
}



