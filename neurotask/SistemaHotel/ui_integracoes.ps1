param($pnl)
if (-not $pnl) { return }

try {
Limpar-Panel $pnl

$lblTitulo = Nova-RichLabel "Integrações com Plataformas" 20 15 600 30 -bold -size 16
$pnl.Controls.Add($lblTitulo)
$pnl.Controls.Add((Nova-RichLabel "Importe e sincronize reservas do Booking.com, Omnibees e outros canais" 20 48 600 20 -size 10 -color "#888"))

$statsCanais = Get-EstatisticasCanais
$totalExt = 0; $totalComissao = 0
if ($statsCanais) {
    foreach ($c in $statsCanais.Keys) {
        if ($c -ne "direto") { $totalExt += $statsCanais[$c].quantidade; $totalComissao += $statsCanais[$c].comissao }
    }
}

$y = 80
$cardW = [math]::Min(320, [math]::Max(240, [int](($pnl.Width - 60) / 2)))
$pnl.Controls.Add((Nova-StatCard "[E]" $totalExt "Reservas de Canais Externos" "#1565c0" 20 $y $cardW))
$pnl.Controls.Add((Nova-StatCard "[C]" "$(FormatarMoeda $totalComissao)" "Total em Comissões" "#c62828" ($cardW + 25) $y $cardW))
$pnl.Controls.Add((Nova-StatCard "[D]" $statsCanais.direto.quantidade "Reservas Diretas" "#2e7d32" (($cardW + 25) * 2) $y $cardW))

$yCards = $y + 100
$canaisUI = @(
    @{id="booking"; nome="Booking.com"; cor="#e65100"; com=15; stats=$statsCanais.booking}
    @{id="omnibees"; nome="Omnibees"; cor="#1565c0"; com=18; stats=$statsCanais.omnibees}
    @{id="expedia"; nome="Expedia"; cor="#2e7d32"; com=18; stats=$statsCanais.expedia}
    @{id="airbnb"; nome="Airbnb"; cor="#c62828"; com=12; stats=$statsCanais.airbnb}
)

$xCard = 20
$cardPnlW = [math]::Min(360, [math]::Max(260, [int](($pnl.Width - 60) / 2)))
$cardGap = 20
foreach ($c in $canaisUI) {
    $s = $c.stats
    $qtd = if ($s) { $s.quantidade } else { 0 }
    $rec = if ($s) { $s.receita } else { 0 }
    $com = if ($s) { $s.comissao } else { 0 }
    $liq = if ($s) { $s.receita_liquida } else { 0 }

    $pnlCard = New-Object System.Windows.Forms.Panel
    $pnlCard.Location = New-Object System.Drawing.Point($xCard, $yCards)
    $pnlCard.Size = New-Object System.Drawing.Size($cardPnlW, 145)
    $pnlCard.BackColor = "#fff"; $pnlCard.BorderStyle = "FixedSingle"

    $accent = New-Object System.Windows.Forms.Panel
    $accent.Size = New-Object System.Drawing.Size(5, 145)
    $accent.Location = New-Object System.Drawing.Point(0, 0)
    $accent.BackColor = $c.cor
    $pnlCard.Controls.Add($accent)

    $lblNome = Nova-RichLabel $c.nome 18 12 150 25 -bold -size 13
    $pnlCard.Controls.Add($lblNome)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "  Conectado  "
    $lblStatus.Location = New-Object System.Drawing.Point(($cardPnlW - 105), 10)
    $lblStatus.Size = New-Object System.Drawing.Size(85, 22)
    $lblStatus.BackColor = [System.Drawing.Color]::FromArgb(232,245,233)
    $lblStatus.ForeColor = "#2e7d32"; $lblStatus.TextAlign = "MiddleCenter"
    $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $pnlCard.Controls.Add($lblStatus)

    $infoY = 45
    $pnlCard.Controls.Add((Nova-RichLabel "Reservas: $qtd  |  Receita: $(FormatarMoeda $rec)" 18 $infoY ($cardPnlW - 35) 20 -size 9 -color "#555"))
    $pnlCard.Controls.Add((Nova-RichLabel "Comissão: $(FormatarMoeda $com) ($($c.com)%)  |  Líquido: $(FormatarMoeda $liq)" 18 ($infoY+22) ($cardPnlW - 35) 20 -size 9 -color "#555"))
    $pnlCard.Controls.Add((Nova-RichLabel "Última sincronia: 05/07/2026 08:00" 18 ($infoY+44) ($cardPnlW - 35) 20 -size 8 -color "#aaa"))

    $btnSync = Nova-Botao " Sincronizar" 80 ($infoY+70) 120 28 "#1565c0" 9
    $btnSync.Tag = $c.id
    $btnSync.Add_Click({
        try {
            $canal = $this.Tag
            $result = Sync-ReservasExternas $canal
            $msg = if ($result.sucesso) { "Sincronizacao concluida! $($result.processadas) reservas processadas." } else { "Falha na sincronizacao." }
            [System.Windows.Forms.MessageBox]::Show($msg, "Sincronizacao $canal")
            & (Join-Path $PSScriptRoot "ui_integracoes.ps1") $pnl
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Erro ao sincronizar: $($_.Exception.Message)", "Erro")
        }
    })
    $pnlCard.Controls.Add($btnSync)
    $pnl.Controls.Add($pnlCard)

    $xCard += ($cardPnlW + $cardGap)
    if ($xCard + $cardPnlW -gt $pnl.Width) { $xCard = 20; $yCards += 160 }
}

$yImport = $yCards + 160
$pnlImport = New-Object System.Windows.Forms.Panel
$pnlImport.Location = New-Object System.Drawing.Point(20, $yImport)
$pnlImport.Size = New-Object System.Drawing.Size(($pnl.Width - 60), 110)
$pnlImport.BackColor = "#fff"; $pnlImport.BorderStyle = "FixedSingle"
$pnlImport.Controls.Add((Nova-RichLabel "Importar Reservas" 15 10 200 25 -bold -size 12))
$pnlImport.Controls.Add((Nova-RichLabel "Importe reservas de canais externos via arquivo CSV" 15 35 400 20 -size 10 -color "#888"))

$lblCaminho = Nova-RichLabel "Arquivo CSV:" 15 60 80 25 -size 10
$txtCaminho = New-Object System.Windows.Forms.TextBox
$txtCaminho.Location = New-Object System.Drawing.Point(95, 58); $txtCaminho.Size = New-Object System.Drawing.Size([math]::Min(350, ($pnl.Width - 220)), 25)
$txtCaminho.Text = Join-Path $PSScriptRoot "data\import_exemplo.csv"
$btnImportar = Nova-Botao " Importar CSV" 460 56 140 30 "#e65100"
$pnlImport.Controls.AddRange(@($lblCaminho, $txtCaminho, $btnImportar))

$cmbCanalImport = New-Object System.Windows.Forms.ComboBox
$cmbCanalImport.Location = New-Object System.Drawing.Point(95, 88); $cmbCanalImport.Size = New-Object System.Drawing.Size(150, 25)
$cmbCanalImport.DropDownStyle = "DropDownList"
$cmbCanalImport.Items.AddRange(@("booking", "omnibees", "expedia", "airbnb"))
$cmbCanalImport.SelectedIndex = 0
$pnlImport.Controls.Add($cmbCanalImport)
$pnlImport.Controls.Add((Nova-RichLabel "Canal:" 15 90 80 25 -size 10))

$btnImportar.Add_Click({
    try {
        $caminho = $txtCaminho.Text
        $canal = $cmbCanalImport.Text
        if (-not (Test-Path $caminho)) {
            [System.Windows.Forms.MessageBox]::Show("Arquivo não encontrado: $caminho", "Erro"); return
        }
        $result = Importar-ReservasCSV $caminho $canal
        if ($result.sucesso) {
            [System.Windows.Forms.MessageBox]::Show("Importação concluída! $($result.importadas) importadas, $($result.ignoradas) ignoradas.", "Sucesso")
            & (Join-Path $PSScriptRoot "ui_integracoes.ps1") $pnl
        } else {
            [System.Windows.Forms.MessageBox]::Show("Erro: $($result.erro)", "Erro")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao importar: $($_.Exception.Message)", "Erro")
    }
})
$pnl.Controls.Add($pnlImport)

$yGrid = $yImport + 120
$pnl.Controls.Add((Nova-RichLabel "Reservas de Canais Externos" 20 $yGrid 400 25 -bold -size 14))

$grid = Nova-Table 20 ($yGrid + 30) ($pnl.Width - 60) 250
$grid.ColumnCount = 9
$grid.Columns[0].HeaderText = "ID"; $grid.Columns[1].HeaderText = "Plataforma"
$grid.Columns[2].HeaderText = "Hóspede"; $grid.Columns[3].HeaderText = "Check-in"
$grid.Columns[4].HeaderText = "Check-out"; $grid.Columns[5].HeaderText = "Valor"
$grid.Columns[6].HeaderText = "Comissão"; $grid.Columns[7].HeaderText = "Status"
$grid.Columns[8].HeaderText = "Sync"
Set-ColAlignment $grid 5
Set-ColAlignment $grid 6

$externas = Get-DadosIntegracoes
if ($externas -and $externas.reservas_externas) {
    foreach ($r in $externas.reservas_externas) {
        $grid.Rows.Add($r.id_reserva_origem, $r.plataforma, $r.nome_hospede,
            (FormatarData $r.data_checkin), (FormatarData $r.data_checkout),
            $(FormatarMoeda $r.valor_total), $(FormatarMoeda $r.comissao_valor),
            $r.status, $r.sync_status)
    }
}
$pnl.Controls.Add($grid)

} catch {}
