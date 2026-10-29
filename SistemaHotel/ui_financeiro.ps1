param($pnl)

Limpar-Panel $pnl
if (-not $global:uiDir) { $global:uiDir = Split-Path $PSCommandPath -Parent }

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(20, 20)
$tabControl.Size = New-Object System.Drawing.Size(($pnl.Width - 40), ($pnl.Height - 40))
$tabControl.Anchor = "Top, Left, Right, Bottom"
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)

function Adicionar-Lancamento {
    param($tipo)
    $fi = Get-DadosFinanceiro
    if (-not $fi) { $fi = @{lancamentos=@(); categorias_despesa=@(); categorias_receita=@()} }

    $formL = New-Object System.Windows.Forms.Form
    $formL.Text = if ($tipo -eq "despesa") { "Nova Despesa" } else { "Nova Receita" }
    $formL.Size = New-Object System.Drawing.Size(450, 350)
    $formL.StartPosition = "CenterParent"
    $formL.FormBorderStyle = "FixedDialog"
    $formL.MaximizeBox = $false; $formL.MinimizeBox = $false

    $y = 20
    $formL.Controls.Add((Nova-RichLabel "Data:" 20 $y 80 25 -bold))
    $dtL = New-Object System.Windows.Forms.DateTimePicker
    $dtL.Location = New-Object System.Drawing.Point(110, $y); $dtL.Size = New-Object System.Drawing.Size(130, 25)
    $dtL.Format = "Short"; $dtL.Value = (Get-Date)
    $formL.Controls.Add($dtL)

    $y = 60
    $formL.Controls.Add((Nova-RichLabel "Categoria:" 20 $y 80 25 -bold))
    $cmbCat = New-Object System.Windows.Forms.ComboBox
    $cmbCat.Location = New-Object System.Drawing.Point(110, $y); $cmbCat.Size = New-Object System.Drawing.Size(300, 25)
    $cmbCat.DropDownStyle = "DropDownList"
    $cmbCat.FlatStyle = "Flat"
    $cats = if ($tipo -eq "despesa") { $fi.categorias_despesa } else { $fi.categorias_receita }
    if ($cats) { $cats | ForEach-Object { $cmbCat.Items.Add($_) } }
    if ($cmbCat.Items.Count -gt 0) { $cmbCat.SelectedIndex = 0 }
    $formL.Controls.Add($cmbCat)

    $y = 100
    $formL.Controls.Add((Nova-RichLabel "Descricao:" 20 $y 80 25 -bold))
    $txtDesc = New-Object System.Windows.Forms.TextBox
    $txtDesc.Location = New-Object System.Drawing.Point(110, $y); $txtDesc.Size = New-Object System.Drawing.Size(300, 25)
    $formL.Controls.Add($txtDesc)

    $y = 140
    $formL.Controls.Add((Nova-RichLabel "Valor (R$):" 20 $y 80 25 -bold))
    $txtValor = New-Object System.Windows.Forms.TextBox
    $txtValor.Location = New-Object System.Drawing.Point(110, $y); $txtValor.Size = New-Object System.Drawing.Size(150, 25)
    $txtValor.Text = "0,00"
    $formL.Controls.Add($txtValor)

    $y = 180
    $formL.Controls.Add((Nova-RichLabel "Status:" 20 $y 80 25 -bold))
    $cmbStatus = New-Object System.Windows.Forms.ComboBox
    $cmbStatus.Location = New-Object System.Drawing.Point(110, $y); $cmbStatus.Size = New-Object System.Drawing.Size(150, 25)
    $cmbStatus.DropDownStyle = "DropDownList"
    $cmbStatus.FlatStyle = "Flat"
    if ($tipo -eq "despesa") { "pendente","pago" | ForEach-Object { $cmbStatus.Items.Add($_) }; $cmbStatus.SelectedIndex = 1 }
    else { "pendente","recebido" | ForEach-Object { $cmbStatus.Items.Add($_) }; $cmbStatus.SelectedIndex = 1 }
    $formL.Controls.Add($cmbStatus)

    $y = 240
    $btnSalvarL = Nova-Botao " Salvar" 100 $y 130 35 "#1565c0"
    $btnCancL = Nova-Botao " Cancelar" 250 $y 130 35 "#757575"
    $formL.Controls.AddRange(@($btnSalvarL, $btnCancL))
    $btnCancL.Add_Click({ $formL.Close() })
    $btnSalvarL.Add_Click({
        $desc = $txtDesc.Text.Trim()
        if (-not $desc) { [System.Windows.Forms.MessageBox]::Show("Informe a descricao", "Erro"); return }
        $valorStr = $txtValor.Text.Trim().Replace("R$","").Replace(" ","").Replace(".","").Replace(",",".")
        $valor = 0
        try { $valor = [math]::Round([double]$valorStr, 2) } catch { }
        if ($valor -le 0) { [System.Windows.Forms.MessageBox]::Show("Informe um valor valido", "Erro"); return }

        $dados = Get-DadosFinanceiro
        if (-not $dados) { $dados = @{lancamentos=@(); categorias_despesa=@(); categorias_receita=@()} }
        $ultId = if ($dados.lancamentos.Count -gt 0) { ($dados.lancamentos | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novo = [PSCustomObject]@{
            id = $ultId + 1
            data = $dtL.Value.ToString("yyyy-MM-dd")
            tipo = $tipo
            categoria = $cmbCat.Text
            descricao = $desc
            valor = $valor
            status = $cmbStatus.Text
            criado_em = (Get-Date -Format "yyyy-MM-dd HH:mm")
        }
        $dados.lancamentos += $novo
        Save-Financeiro $dados
        $formL.Close()
        & (Join-Path $global:uiDir "ui_financeiro.ps1") $pnl
    })
    $formL.ShowDialog()
}

# Tab Fluxo de Caixa
$tabFluxo = New-Object System.Windows.Forms.TabPage
$tabFluxo.Text = "  Fluxo de Caixa  "; $tabFluxo.BackColor = "#fff"
$mesAtual = (Get-Date -Format "yyyy-MM")
$f = Get-DadosFinanceiro
$lancMes = if ($f) { @($f.lancamentos | Where-Object { $_.data -like "$mesAtual-*" }) } else { @() }
$rec = [math]::Round(($lancMes | Where-Object { $_.tipo -eq "receita" } | Measure-Object -Property valor -Sum).Sum, 2)
$desp = [math]::Round(($lancMes | Where-Object { $_.tipo -eq "despesa" } | Measure-Object -Property valor -Sum).Sum, 2)
$saldo = [math]::Round($rec - $desp, 2)

$availableW = $tabControl.Width - 30

# Buttons row
$btnNovaRec = Nova-Botao "+ Nova Receita" 20 10 140 28 "#2e7d32" 9
$btnNovaDesp = Nova-Botao "+ Nova Despesa" 175 10 140 28 "#c62828" 9
$tabFluxo.Controls.AddRange(@($btnNovaRec, $btnNovaDesp))
$fnAdicionar = ${function:Adicionar-Lancamento}
$btnNovaRec.Add_Click({ & $fnAdicionar "receita" }.GetNewClosure())
$btnNovaDesp.Add_Click({ & $fnAdicionar "despesa" }.GetNewClosure())

$y = 48
$cardW = [math]::Min(260, [math]::Max(180, [int](($availableW - 80) / 3)))
$xGap = [math]::Max(20, [int](($availableW - $cardW * 3) / 4))
$tabFluxo.Controls.Add((Nova-StatCard "[+]" $(FormatarMoeda $rec) "Receitas do Mês" "#2e7d32" $xGap $y $cardW))
$tabFluxo.Controls.Add((Nova-StatCard "[-]" $(FormatarMoeda $desp) "Despesas do Mês" "#c62828" ($xGap * 2 + $cardW) $y $cardW))
$tabFluxo.Controls.Add((Nova-StatCard "[S]" $(FormatarMoeda $saldo) "Saldo do Mês" "#1565c0" ($xGap * 3 + $cardW * 2) $y $cardW))

$recebido = [math]::Round(($lancMes | Where-Object { $_.tipo -eq "receita" -and $_.status -eq "recebido" } | Measure-Object -Property valor -Sum).Sum, 2)
$aReceber = [math]::Round(($lancMes | Where-Object { $_.tipo -eq "receita" -and $_.status -eq "pendente" } | Measure-Object -Property valor -Sum).Sum, 2)

$yLabels = $y + 90
$tabFluxo.Controls.Add((Nova-RichLabel "Recebido: $(FormatarMoeda $recebido)" $xGap $yLabels 200 25 -size 11 -color "#2e7d32"))
$tabFluxo.Controls.Add((Nova-RichLabel "A Receber: $(FormatarMoeda $aReceber)" ($xGap * 2 + $cardW) $yLabels 200 25 -size 11 -color "#e65100"))
$tabFluxo.Controls.Add((Nova-RichLabel "Despesas: $(FormatarMoeda ($desp))" ($xGap * 3 + $cardW * 2) $yLabels 200 25 -size 11 -color "#c62828"))

$gridF = Nova-Table 20 ($yLabels + 35) ($availableW - 60) ([math]::Max(120, [int]($tabControl.Height - $yLabels - 120)))
$gridF.ColumnCount = 7
$gridF.Columns[0].HeaderText = "Data"; $gridF.Columns[1].HeaderText = "Tipo"
$gridF.Columns[2].HeaderText = "Categoria"; $gridF.Columns[3].HeaderText = "Descricao"
$gridF.Columns[4].HeaderText = "Valor"; $gridF.Columns[5].HeaderText = "Status"
$gridF.Columns[6].HeaderText = ""
$gridF.Columns[6].Width = 30
if ($lancMes) {
    $lancMes | Sort-Object data -Descending | ForEach-Object {
        $idx = $gridF.Rows.Add((FormatarData $_.data), $_.tipo, $_.categoria, $_.descricao, $(FormatarMoeda $_.valor), $_.status, "X")
        $gridF.Rows[$idx].Tag = $_.id
        if ($_.tipo -eq "despesa") { $gridF.Rows[$idx].DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40) }
    }
}
$cmsFin = New-Object System.Windows.Forms.ContextMenuStrip
$menuExcluirL = New-Object System.Windows.Forms.ToolStripMenuItem("Excluir Lancamento")
$menuExcluirL.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40)
$cmsFin.Items.Add($menuExcluirL)
$gridF.ContextMenuStrip = $cmsFin
$menuExcluirL.Add_Click({
    if ($gridF.SelectedRows.Count -eq 0) { return }
    $idxR = $gridF.SelectedRows[0].Index
    $resp = [System.Windows.Forms.MessageBox]::Show("Excluir lancamento?", "Confirmar Exclusao", "YesNo", "Warning")
    if ($resp -eq "Yes") {
        $dadosF = Get-DadosFinanceiro
        $alvo = @($dadosF.lancamentos | Where-Object { $_.id -eq $gridF.Rows[$idxR].Tag })
        if ($alvo.Count -gt 0) {
            $dadosF.lancamentos = @($dadosF.lancamentos | Where-Object { $_ -ne $alvo[0] })
            Save-Financeiro $dadosF
            & (Join-Path $global:uiDir "ui_financeiro.ps1") $pnl
        }
    }
})
$tabFluxo.Controls.Add($gridF)
$tabControl.Controls.Add($tabFluxo)

# Tab Balanceamento Mensal
$tabBalancoM = New-Object System.Windows.Forms.TabPage
$tabBalancoM.Text = "  Balanceamento Mensal  "; $tabBalancoM.BackColor = "#fff"
$saldos = if ($f) { $f.saldos_mensais } else { @() }
$gridB = Nova-Table 15 15 $availableW 300
$gridB.ColumnCount = 4
$gridB.Columns[0].HeaderText = "Mes"; $gridB.Columns[1].HeaderText = "Receitas"
$gridB.Columns[2].HeaderText = "Despesas"; $gridB.Columns[3].HeaderText = "Saldo"
if ($saldos) {
    foreach ($s in ($saldos | Sort-Object mes)) {
        $gridB.Rows.Add($s.mes, $(FormatarMoeda $s.receitas), $(FormatarMoeda $s.despesas), $(FormatarMoeda $s.saldo))
    }
}
$tabBalancoM.Controls.Add($gridB)
$tabControl.Controls.Add($tabBalancoM)

# Tab Categorias
$tabCats = New-Object System.Windows.Forms.TabPage
$tabCats.Text = "  Categorias  "; $tabCats.BackColor = "#fff"
$fiC = Get-DadosFinanceiro
$yC = 15
$tabCats.Controls.Add((Nova-RichLabel "Categorias de Receita:" 20 $yC 300 25 -bold -size 12))
$yC += 30
$listaRec = if ($fiC -and $fiC.categorias_receita) { $fiC.categorias_receita -join ", " } else { "(nenhuma)" }
$tabCats.Controls.Add((Nova-RichLabel $listaRec 20 $yC 500 60 -size 10 -color "#555"))
$yC += 70
$tabCats.Controls.Add((Nova-RichLabel "Categorias de Despesa:" 20 $yC 300 25 -bold -size 12))
$yC += 30
$listaDesp = @()
if ($fiC -and $fiC.categorias_despesa) {
    foreach ($cd in $fiC.categorias_despesa) {
        $nomeExib = @{
            "pessoal"="Pessoal (salarios, encargos)"
            "servicos"="Servicos (agua, luz, internet)"
            "suprimentos"="Suprimentos (limpeza, amenidades)"
            "manutencao"="Manutencao geral"
            "impostos"="Impostos e taxas"
            "marketing"="Marketing e propaganda"
            "comissao"="Comissao de canais"
            "servico_diarista"="Servico de Diarista"
            "compras"="Compras"
            "manutencao_predial"="Manutencao Predial"
            "outros"="Outros"
        }
        $listaDesp += "$cd ($($nomeExib[$cd]))"
    }
}
$tabCats.Controls.Add((Nova-RichLabel ($listaDesp -join "`n") 20 $yC 500 200 -size 10 -color "#555"))
$tabControl.Controls.Add($tabCats)

$pnl.Controls.Add($tabControl)



