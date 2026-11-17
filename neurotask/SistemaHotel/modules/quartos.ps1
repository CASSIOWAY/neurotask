param(
    [string]$Acao = "listar",
    [string]$DadosJSON = ""
)


switch ($Acao) {
    "listar" {
        $data = Get-DadosQuartos
        if ($data) { $data.quartos | ConvertTo-Json -Depth 3 }
    }
    "tipos" {
        $data = Get-DadosQuartos
        if ($data) { $data.tipos_quarto | ConvertTo-Json -Depth 2 }
    }
    "estatisticas" {
        $data = Get-DadosQuartos
        if (-not $data -or -not $data.quartos) { "{}" | ConvertTo-Json; return }
        $total = $data.quartos.Count
        $disp = @($data.quartos | Where-Object { $_.status -eq "disponivel" }).Count
        $ocup = @($data.quartos | Where-Object { $_.status -eq "ocupado" }).Count
        $resv = @($data.quartos | Where-Object { $_.status -eq "reservado" }).Count
        $manut = @($data.quartos | Where-Object { $_.status -eq "manutencao" }).Count
        $taxa = if ($total -gt 0) { [math]::Round(($ocup + $resv) / $total * 100, 1) } else { 0 }
        @{total=$total; disponiveis=$disp; ocupados=$ocup; reservados=$resv; manutencao=$manut; taxa_ocupacao=$taxa} | ConvertTo-Json
    }
    "atualizar-status" {
        try { $dados = $DadosJSON | ConvertFrom-Json } catch { "{}" | ConvertTo-Json; return }
        $data = Get-DadosQuartos
        if (-not $data -or -not $data.quartos) { "{}" | ConvertTo-Json; return }
        foreach ($q in $data.quartos) {
            if ($q.id -eq $dados.id) { $q.status = $dados.status; break }
        }
        Save-Quartos $data
        @{status="ok"} | ConvertTo-Json
    }
}



