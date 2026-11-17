param($pnl)

Limpar-Panel $pnl

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(15, 15)
$tabControl.Size = New-Object System.Drawing.Size(($pnl.Width - 50), ($pnl.Height - 40))
$tabControl.Anchor = "Top, Left, Right, Bottom"
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$tabW = $tabControl.Width - 20

# Tab Visao Geral
$tabVisao = New-Object System.Windows.Forms.TabPage
$tabVisao.Text = "  Visão Geral  "; $tabVisao.BackColor = "#fff"
$d = Get-DadosReservas; $q = Get-DadosQuartos; $h = Get-DadosHospedes; $f = Get-DadosFinanceiro
$totalQ = if ($q) { $q.quartos.Count } else { 0 }
$ocup = @($q.quartos | Where-Object { $_.status -eq "ocupado" }).Count
$resv = @($q.quartos | Where-Object { $_.status -eq "reservado" }).Count
$taxa = if ($totalQ -gt 0) { [math]::Round(($ocup + $resv) / $totalQ * 100, 1) } else { 0 }
$totalH = if ($h) { $h.hospedes.Count } else { 0 }
$mesAtual = (Get-Date -Format "yyyy-MM")
$lancM = if ($f) { @($f.lancamentos | Where-Object { $_.data -like "$mesAtual-*" }) } else { @() }
$recM = [math]::Round(($lancM | Where-Object { $_.tipo -eq "receita" } | Measure-Object -Property valor -Sum).Sum, 2)

$y = 15
$cardW = [math]::Min(240, [math]::Max(170, [int](($tabW - 80) / 4)))
$xCards = @(20, ($cardW + 30), (($cardW + 30) * 2), (($cardW + 30) * 3))
$tabVisao.Controls.Add((Nova-StatCard "[Q]" $totalQ "Total Quartos" "#1565c0" $xCards[0] $y $cardW))
$tabVisao.Controls.Add((Nova-StatCard "[%]" "$taxa%" "Taxa de Ocupação" "#2e7d32" $xCards[1] $y $cardW))
$tabVisao.Controls.Add((Nova-StatCard "[H]" $totalH "Total de Hóspedes" "#6a1b9a" $xCards[2] $y $cardW))
$tabVisao.Controls.Add((Nova-StatCard "[+]" $(FormatarMoeda $recM) "Receita do Mês" "#00838f" $xCards[3] $y $cardW))

$yGrid = $y + 100
$gridV = Nova-Table 20 $yGrid ($tabW - 40) 300
$gridV.ColumnCount = 5
$gridV.Columns[0].HeaderText = "Indicador"; $gridV.Columns[1].HeaderText = "Valor"
$gridV.Columns[2].HeaderText = "Indicador"; $gridV.Columns[3].HeaderText = "Valor"
$hoje = Get-Date -Format "yyyy-MM-dd"
$gridV.Rows.Add("Quartos Disponiveis", (@($q.quartos | Where-Object { $_.status -eq "disponivel" }).Count), "Total Reservas", ($d.reservas.Count))
$gridV.Rows.Add("Quartos Ocupados", $ocup, "Check-ins Hoje", (@($d.reservas | Where-Object { $_.data_checkin -eq $hoje -and $_.status -ne "cancelada" }).Count))
$gridV.Rows.Add("Quartos Reservados", $resv, "Check-outs Hoje", (@($d.reservas | Where-Object { $_.data_checkout -eq $hoje -and $_.status -ne "cancelada" }).Count))
$tabVisao.Controls.Add($gridV)
$tabControl.Controls.Add($tabVisao)

# Tab Tendencias
$tabTend = New-Object System.Windows.Forms.TabPage
$tabTend.Text = "  Tendências  "; $tabTend.BackColor = "#fff"
$gridT = Nova-Table 15 15 ($tabW - 40) 300
$gridT.ColumnCount = 4
$gridT.Columns[0].HeaderText = "Mes"; $gridT.Columns[1].HeaderText = "Receitas"
$gridT.Columns[2].HeaderText = "Despesas"; $gridT.Columns[3].HeaderText = "Saldo"
if ($f -and $f.saldos_mensais) {
    foreach ($s in ($f.saldos_mensais | Sort-Object mes)) {
        $gridT.Rows.Add($s.mes, $(FormatarMoeda $s.receitas), $(FormatarMoeda $s.despesas), $(FormatarMoeda $s.saldo))
    }
}
$tabTend.Controls.Add($gridT)
$tabControl.Controls.Add($tabTend)

# Tab Balanco
$tabBalanco = New-Object System.Windows.Forms.TabPage
$tabBalanco.Text = "  Balanço  "; $tabBalanco.BackColor = "#fff"

$lblBIni = Nova-RichLabel "De:" 15 12 30 25 -size 10
$dtBIni = New-Object System.Windows.Forms.DateTimePicker
$dtBIni.Location = New-Object System.Drawing.Point(50, 12); $dtBIni.Size = New-Object System.Drawing.Size(130, 25)
$dtBIni.Format = "Short"; $dtBIni.Value = (Get-Date).AddMonths(-1)
$lblBFim = Nova-RichLabel "Ate:" 195 12 30 25 -size 10
$dtBFim = New-Object System.Windows.Forms.DateTimePicker
$dtBFim.Location = New-Object System.Drawing.Point(230, 12); $dtBFim.Size = New-Object System.Drawing.Size(130, 25)
$dtBFim.Format = "Short"; $dtBFim.Value = (Get-Date)

$btnImpB = Nova-Botao " Imprimir Balanco" ($tabW - 140) 10 140 28 "#1565c0" 9
$btnImpB.Anchor = "Top, Right"
$tabBalanco.Controls.AddRange(@($lblBIni, $dtBIni, $lblBFim, $dtBFim, $btnImpB))

$lblTotalRec = Nova-RichLabel "" 15 45 200 20 -size 10 -color "#2e7d32"
$lblTotalDes = Nova-RichLabel "" 230 45 200 20 -size 10 -color "#c62828"
$lblSaldo = Nova-RichLabel "" 460 45 200 20 -bold -size 10 -color "#1565c0"
$tabBalanco.Controls.AddRange(@($lblTotalRec, $lblTotalDes, $lblSaldo))

function CarregarBalanco {
    param($dIni, $dFim)
    $fi = Get-DadosFinanceiro
    $gridB.Rows.Clear()
    $rec = 0; $des = 0
    if ($fi -and $fi.lancamentos) {
        $filtrados = @($fi.lancamentos | Where-Object { $_.data -ge $dIni.ToString("yyyy-MM-dd") -and $_.data -le $dFim.ToString("yyyy-MM-dd") } | Sort-Object data)
        foreach ($l in $filtrados) {
            $v = [math]::Round($l.valor, 2)
            $gridB.Rows.Add($l.data, $l.descricao, $l.categoria, $l.tipo, $(FormatarMoeda $v))
            if ($l.tipo -eq "receita") { $rec += $v } else { $des += $v }
        }
    }
    if ($gridB.Rows.Count -eq 0) { $gridB.Rows.Add("-", "Nenhum lancamento no periodo", "", "", "") }
    $lblTotalRec.Text = "Receitas: $(FormatarMoeda $rec)"
    $lblTotalDes.Text = "Despesas: $(FormatarMoeda $des)"
    $saldo = $rec - $des
    $lblSaldo.Text = "Saldo: $(FormatarMoeda $saldo)"
}

$gridB = Nova-Table 15 75 ($tabW - 40) ($tabControl.Height - 180)
$gridB.Anchor = "Top, Left, Right, Bottom"
$gridB.ColumnCount = 5
$gridB.Columns[0].HeaderText = "Data"; $gridB.Columns[1].HeaderText = "Descricao"
$gridB.Columns[2].HeaderText = "Categoria"; $gridB.Columns[3].HeaderText = "Tipo"
$gridB.Columns[4].HeaderText = "Valor"
$tabBalanco.Controls.Add($gridB)

$dtBIni.Add_ValueChanged({ CarregarBalanco $dtBIni.Value $dtBFim.Value })
$dtBFim.Add_ValueChanged({ CarregarBalanco $dtBIni.Value $dtBFim.Value })
CarregarBalanco $dtBIni.Value $dtBFim.Value

$btnImpB.Add_Click({
    $fi = Get-DadosFinanceiro
    $dIni = $dtBIni.Value.ToString("yyyy-MM-dd"); $dFim = $dtBFim.Value.ToString("yyyy-MM-dd")
    $linhas = @()
    $linhas += "RELATORIO DE BALANCO"
    $linhas += "Periodo: $(FormatarData $dIni) a $(FormatarData $dFim)"
    $linhas += "----------------------------------------"
    $linhas += "Data       | Descricao               | Categoria    | Tipo      | Valor"
    $linhas += "----------------------------------------"
    $rec = 0; $des = 0
    if ($fi -and $fi.lancamentos) {
        $filtrados = @($fi.lancamentos | Where-Object { $_.data -ge $dIni -and $_.data -le $dFim } | Sort-Object data)
        foreach ($l in $filtrados) {
            $v = [math]::Round($l.valor, 2)
            $linhas += "$($l.data) | $($l.descricao) | $($l.categoria) | $($l.tipo) | $(FormatarMoeda $v)"
            if ($l.tipo -eq "receita") { $rec += $v } else { $des += $v }
        }
    }
    $linhas += "----------------------------------------"
    $linhas += "Receitas: $(FormatarMoeda $rec)"
    $linhas += "Despesas: $(FormatarMoeda $des)"
    $linhas += "SALDO:    $(FormatarMoeda ($rec - $des))"
    Nova-Imprimir ($linhas -join "`r`n") "Balanco Financeiro"
})

$tabControl.Controls.Add($tabBalanco)

# Tab Hospedes (Relatorio)
$tabHospRel = New-Object System.Windows.Forms.TabPage
$tabHospRel.Text = "  Hóspedes  "; $tabHospRel.BackColor = "#fff"

$lblHIni = Nova-RichLabel "De:" 15 15 30 25 -size 10
$dtHIni = New-Object System.Windows.Forms.DateTimePicker
$dtHIni.Location = New-Object System.Drawing.Point(50, 15); $dtHIni.Size = New-Object System.Drawing.Size(130, 25)
$dtHIni.Format = "Short"; $dtHIni.Value = (Get-Date).AddMonths(-1)
$lblHFim = Nova-RichLabel "Ate:" 200 15 30 25 -size 10
$dtHFim = New-Object System.Windows.Forms.DateTimePicker
$dtHFim.Location = New-Object System.Drawing.Point(235, 15); $dtHFim.Size = New-Object System.Drawing.Size(130, 25)
$dtHFim.Format = "Short"; $dtHFim.Value = (Get-Date)
$lblTotalHRel = Nova-RichLabel "" 420 15 200 20 -size 10 -color "#1565c0"
$tabHospRel.Controls.AddRange(@($lblHIni, $dtHIni, $lblHFim, $dtHFim, $lblTotalHRel))

$gridHRel = Nova-Table 15 50 ($tabW - 40) ($tabControl.Height - 200)
$gridHRel.Anchor = "Top, Left, Right, Bottom"
$gridHRel.ColumnCount = 8
$gridHRel.Columns[0].HeaderText = "Hospede"; $gridHRel.Columns[1].HeaderText = "Documento"
$gridHRel.Columns[2].HeaderText = "Telefone"; $gridHRel.Columns[3].HeaderText = "Quarto"
$gridHRel.Columns[4].HeaderText = "Check-in"; $gridHRel.Columns[5].HeaderText = "Check-out"
$gridHRel.Columns[6].HeaderText = "Noites"; $gridHRel.Columns[7].HeaderText = "Valor"

$cmsHRel = New-Object System.Windows.Forms.ContextMenuStrip
$menuFicha = New-Object System.Windows.Forms.ToolStripMenuItem("Ficha de Cadastro")
$menuFicha.ForeColor = [System.Drawing.Color]::FromArgb(21, 101, 192)
$cmsHRel.Items.Add($menuFicha)
$gridHRel.ContextMenuStrip = $cmsHRel

$btnImpRel = Nova-Botao " Imprimir Listagem" ($tabW - 140) 15 140 28 "#2e7d32" 9
$btnImpRel.Anchor = "Top, Right"
$tabHospRel.Controls.Add($btnImpRel)

function CarregarRelHospedes {
    param($dIni, $dFim)
    $gridHRel.Rows.Clear()
    $hospData = Get-DadosHospedes; $resData = Get-DadosReservas
    $cont = 0
    if ($hospData -and $hospData.hospedes -and $resData -and $resData.reservas) {
        $dIniStr = $dIni.ToString("yyyy-MM-dd"); $dFimStr = $dFim.ToString("yyyy-MM-dd")
        $resPeriodo = @($resData.reservas | Where-Object { $_.data_checkin -le $dFimStr -and $_.data_checkout -ge $dIniStr -and $_.status -ne "cancelada" })
        foreach ($r in $resPeriodo) {
            $hp = @($hospData.hospedes | Where-Object { $_.id -eq $r.id_hospede })
            if (-not $hp) { continue }
            $hp = $hp[0]
            $qNum = Get-QuartoNumero $r.id_quarto
            $gridHRel.Rows.Add($hp.nome, $hp.documento, $hp.telefone, $qNum, $(FormatarData $r.data_checkin), $(FormatarData $r.data_checkout), $r.noites, $(FormatarMoeda $r.valor_total))
            $cont++
        }
    }
    if ($gridHRel.Rows.Count -eq 0) { $gridHRel.Rows.Add("Nenhum hospede no periodo", "", "", "", "", "", "", "") }
    $lblTotalHRel.Text = "Total de hospedes no periodo: $cont"
}

$dtHIni.Add_ValueChanged({ CarregarRelHospedes $dtHIni.Value $dtHFim.Value })
$dtHFim.Add_ValueChanged({ CarregarRelHospedes $dtHIni.Value $dtHFim.Value })
CarregarRelHospedes $dtHIni.Value $dtHFim.Value

$menuFicha.Add_Click({
    if ($gridHRel.SelectedRows.Count -eq 0) { return }
    $nomeH = $gridHRel.SelectedRows[0].Cells[0].Value
    $docH = $gridHRel.SelectedRows[0].Cells[1].Value
    $telH = $gridHRel.SelectedRows[0].Cells[2].Value
    $hospData = Get-DadosHospedes
    if ($hospData -and $hospData.hospedes) {
        $hp = @($hospData.hospedes | Where-Object { $_.nome -eq $nomeH -and $_.documento -eq $docH })
        if ($hp) { Nova-FichaCadastro $hp[0] }
    }
})

$btnImpRel.Add_Click({
    $linhas = @()
    $linhas += "RELATORIO DE HOSPEDES"
    $linhas += "Periodo: $(FormatarData $dtHIni.Value) a $(FormatarData $dtHFim.Value)"
    $linhas += "----------------------------------------"
    $linhas += "Hospede          | Documento    | Quarto | Check-in   | Check-out  | Noites | Valor"
    $linhas += "----------------------------------------"
    for ($i = 0; $i -lt $gridHRel.Rows.Count; $i++) {
        if ($gridHRel.Rows[$i].Cells[0].Value -and $gridHRel.Rows[$i].Cells[0].Value -ne "Nenhum hospede no periodo") {
            $linhas += "$($gridHRel.Rows[$i].Cells[0].Value) | $($gridHRel.Rows[$i].Cells[1].Value) | $($gridHRel.Rows[$i].Cells[3].Value) | $($gridHRel.Rows[$i].Cells[4].Value) | $($gridHRel.Rows[$i].Cells[5].Value) | $($gridHRel.Rows[$i].Cells[6].Value) | $($gridHRel.Rows[$i].Cells[7].Value)"
        }
    }
    $total = $gridHRel.Rows.Count
    $linhas += "----------------------------------------"
    $linhas += "Total: $total hospedes no periodo"
    Nova-Imprimir ($linhas -join "`r`n") "Listagem de Hospedes"
})

$tabHospRel.Controls.Add($gridHRel)
$tabControl.Controls.Add($tabHospRel)

$pnl.Controls.Add($tabControl)



