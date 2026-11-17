param($pnl)

Limpar-Panel $pnl

$lblTitulo = Nova-RichLabel "Operações do Dia" 20 15 400 30 -bold -size 16
$pnl.Controls.Add($lblTitulo)

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(20, 50)
$tabControl.Size = New-Object System.Drawing.Size(($pnl.Width - 40), ($pnl.Height - 70))
$tabControl.Anchor = "Top, Left, Right, Bottom"
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$tabW = $tabControl.Width - 20

# Tab Quartos
$tabQuartos = New-Object System.Windows.Forms.TabPage
$tabQuartos.Text = "  Quartos  "; $tabQuartos.BackColor = "#fff"
$gridQ = Nova-Table 10 10 $tabW ($tabControl.Height - 80)
$gridQ.ColumnCount = 7
$gridQ.Columns[0].HeaderText = "Quarto"; $gridQ.Columns[1].HeaderText = "Andar"
$gridQ.Columns[2].HeaderText = "Tipo"; $gridQ.Columns[3].HeaderText = "Capacidade"
$gridQ.Columns[4].HeaderText = "Diaria"; $gridQ.Columns[5].HeaderText = "Status"
$gridQ.Columns[6].HeaderText = "Ult. Limpeza"
$q = Get-DadosQuartos
if ($q -and $q.quartos) {
    foreach ($qr in $q.quartos) {
        $gridQ.Rows.Add($qr.numero, "$($qr.andar)o", $qr.tipo, $qr.capacidade, $(FormatarMoeda $qr.preco_diaria), $qr.status, (FormatarData $qr.ultima_limpeza))
    }
}
$tabQuartos.Controls.Add($gridQ)
$tabControl.Controls.Add($tabQuartos)

# Tab Limpeza
$tabLimpeza = New-Object System.Windows.Forms.TabPage
$tabLimpeza.Text = "  Limpeza  "; $tabLimpeza.BackColor = "#fff"

$lblFiltroL = Nova-RichLabel "Filtrar data:" 10 10 80 25 -size 10
$dtFiltroL = New-Object System.Windows.Forms.DateTimePicker
$dtFiltroL.Location = New-Object System.Drawing.Point(95, 10); $dtFiltroL.Size = New-Object System.Drawing.Size(140, 25)
$dtFiltroL.Format = "Short"; $dtFiltroL.Value = (Get-Date)
$tabLimpeza.Controls.AddRange(@($lblFiltroL, $dtFiltroL))

$btnNovaLimpeza = Nova-Botao "+ Nova Limpeza" ($tabW - 120) 8 110 30 "#ff8f00" 9
$tabLimpeza.Controls.Add($btnNovaLimpeza)

$gridL = Nova-Table 10 45 $tabW ($tabControl.Height - 115)
$gridL.ColumnCount = 5
$gridL.Columns[0].HeaderText = "#"; $gridL.Columns[1].HeaderText = "Quarto"
$gridL.Columns[2].HeaderText = "Horario"; $gridL.Columns[3].HeaderText = "Obs"
$gridL.Columns[4].HeaderText = "Status"

$cmsLimp = New-Object System.Windows.Forms.ContextMenuStrip
$menuConcluirL = New-Object System.Windows.Forms.ToolStripMenuItem("Concluir Limpeza")
$menuConcluirL.ForeColor = [System.Drawing.Color]::FromArgb(46, 125, 50)
$cmsLimp.Items.Add($menuConcluirL)
$gridL.ContextMenuStrip = $cmsLimp

function CarregarLimpeza {
    param($dataFiltro)
    $gridL.Rows.Clear()
    $tudo = Get-DadosLimpeza
    $dataStr = if ($dataFiltro) { $dataFiltro.ToString("yyyy-MM-dd") } else { (Get-Date -Format "yyyy-MM-dd") }
    $lista = @()
    if ($tudo -and $tudo.limpezas) {
        $lista = @($tudo.limpezas | Where-Object { $_.data -eq $dataStr })
    }
    if ($lista.Count -eq 0) {
        $gridL.Rows.Add("-", "Nenhuma limpeza agendada", "", "", "")
        return
    }
    foreach ($l in $lista) {
        $qNum = Get-QuartoNumero $l.id_quarto
        $idx = $gridL.Rows.Add($l.id, $qNum, $l.horario, $l.observacoes, $l.status)
        $gridL.Rows[$idx].Tag = $l
    }
}

CarregarLimpeza $dtFiltroL.Value

$dtFiltroL.Add_ValueChanged({ CarregarLimpeza $this.Value })

$menuConcluirL.Add_Click({
    if ($gridL.SelectedRows.Count -eq 0) { return }
    $alvo = $gridL.SelectedRows[0].Tag
    if (-not $alvo) { return }
    $resp = [System.Windows.Forms.MessageBox]::Show("Concluir limpeza #$($alvo.id)?", "Confirmar", "YesNo", "Question")
    if ($resp -eq "Yes") {
        $dados = Get-DadosLimpeza
        foreach ($l in $dados.limpezas) { if ($l.id -eq $alvo.id) { $l.status = "finalizada"; break } }
        Save-Limpeza $dados
        CarregarLimpeza $dtFiltroL.Value
    }
})

$btnNovaLimpeza.Add_Click({
    $formL = New-Object System.Windows.Forms.Form
    $formL.Text = "Agendar Limpeza"
    $formL.Size = New-Object System.Drawing.Size(400, 280)
    $formL.StartPosition = "CenterParent"
    $formL.FormBorderStyle = "FixedDialog"
    $formL.MaximizeBox = $false; $formL.MinimizeBox = $false
    $yL = 20
    $lblData = Nova-RichLabel "Data:" 20 $yL 80 25 -bold
    $formL.Controls.Add($lblData)
    $dtL = New-Object System.Windows.Forms.DateTimePicker
    $dtL.Location = New-Object System.Drawing.Point(110, $yL); $dtL.Size = New-Object System.Drawing.Size(140, 25)
    $dtL.Format = "Short"; $dtL.Value = (Get-Date)
    $formL.Controls.Add($dtL)
    $yL = 60
    $lblQuarto = Nova-RichLabel "Quarto:" 20 $yL 80 25 -bold
    $formL.Controls.Add($lblQuarto)
    $cmbQL = New-Object System.Windows.Forms.ComboBox
    $cmbQL.Location = New-Object System.Drawing.Point(110, $yL); $cmbQL.Size = New-Object System.Drawing.Size(260, 25)
    $cmbQL.DropDownStyle = "DropDownList"
    $cmbQL.Items.AddRange(@("01","02","03","04","05","06"))
    $formL.Controls.Add($cmbQL)
    $yL = 100
    $lblHorario = Nova-RichLabel "Horário:" 20 $yL 80 25 -bold
    $formL.Controls.Add($lblHorario)
    $dtHoraL = New-Object System.Windows.Forms.DateTimePicker
    $dtHoraL.Location = New-Object System.Drawing.Point(110, $yL); $dtHoraL.Size = New-Object System.Drawing.Size(110, 25)
    $dtHoraL.Format = "Time"; $dtHoraL.ShowUpDown = $true
    $dtHoraL.Value = (Get-Date).Date.AddHours(8)
    $formL.Controls.Add($dtHoraL)
    $yL = 140
    $formL.Controls.Add((Nova-RichLabel "Observações:" 20 $yL 90 25))
    $txtObsL = New-Object System.Windows.Forms.TextBox
    $txtObsL.Location = New-Object System.Drawing.Point(110, $yL); $txtObsL.Size = New-Object System.Drawing.Size(260, 25)
    $formL.Controls.Add($txtObsL)
    $yL = 190
    $btnSL = Nova-Botao "Agendar" 80 $yL 120 35 "#ff8f00"
    $btnSL.ForeColor = [System.Drawing.Color]::White
    $btnCL = Nova-Botao "Cancelar" 220 $yL 120 35 "#757575"
    $btnCL.ForeColor = [System.Drawing.Color]::White
    $formL.Controls.AddRange(@($btnSL, $btnCL))
    $btnCL.Add_Click({ $formL.Close() })
    $btnSL.Add_Click({
        if ($cmbQL.SelectedIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Selecione um quarto", "Erro"); return }
        $qIdL = [int]$cmbQL.SelectedItem
        $hStr = $dtHoraL.Value.ToString("HH:mm")
        $dStr = $dtL.Value.ToString("yyyy-MM-dd")
        $dadosL = Get-DadosLimpeza
        if (-not $dadosL) { $dadosL = @{limpezas = @()} }
        $ultIdL = if ($dadosL.limpezas.Count -gt 0) { ($dadosL.limpezas | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novaL = [PSCustomObject]@{
            id = $ultIdL + 1; id_quarto = $qIdL; data = $dStr
            horario = $hStr; observacoes = $txtObsL.Text
            status = "pendente"; criada_em = (Get-Date -Format "yyyy-MM-dd HH:mm")
        }
        $dadosL.limpezas += $novaL
        Save-Limpeza $dadosL
        $formL.Close()
        CarregarLimpeza $dtFiltroL.Value
        [System.Windows.Forms.MessageBox]::Show("Limpeza #$($ultIdL + 1) agendada!", "Sucesso")
    })
    $formL.ShowDialog()
})

$tabLimpeza.Controls.Add($gridL)
$tabControl.Controls.Add($tabLimpeza)

# Tab Recepcao
$tabRecep = New-Object System.Windows.Forms.TabPage
$tabRecep.Text = "  Recepção  "; $tabRecep.BackColor = "#fff"
$hoje = Get-Date -Format "yyyy-MM-dd"
$d = Get-DadosReservas

$lblCheckins = Nova-RichLabel "Check-ins de hoje:" 10 10 300 25 -bold -size 12 -color "#1565c0"
$tabRecep.Controls.Add($lblCheckins)
$gridCI = Nova-Table 10 40 $tabW 120
$gridCI.ColumnCount = 3
$gridCI.Columns[0].HeaderText = "Hóspede"; $gridCI.Columns[1].HeaderText = "Quarto"; $gridCI.Columns[2].HeaderText = "Reserva"
if ($d -and $d.reservas) {
    $cis = @($d.reservas | Where-Object { $_.data_checkin -eq $hoje -and $_.status -ne "cancelada" })
    foreach ($r in $cis) {
        $gridCI.Rows.Add((Get-HospedeNome $r.id_hospede), (Get-QuartoNumero $r.id_quarto), "#$($r.id)")
    }
}
$tabRecep.Controls.Add($gridCI)

$lblCheckouts = Nova-RichLabel "Check-outs de hoje:" 10 170 300 25 -bold -size 12 -color "#e65100"
$tabRecep.Controls.Add($lblCheckouts)
$gridCO = Nova-Table 10 200 $tabW 120
$gridCO.ColumnCount = 3
$gridCO.Columns[0].HeaderText = "Hóspede"; $gridCO.Columns[1].HeaderText = "Quarto"; $gridCO.Columns[2].HeaderText = "Reserva"
if ($d -and $d.reservas) {
    $cos = @($d.reservas | Where-Object { $_.data_checkout -eq $hoje -and $_.status -ne "cancelada" })
    foreach ($r in $cos) {
        $gridCO.Rows.Add((Get-HospedeNome $r.id_hospede), (Get-QuartoNumero $r.id_quarto), "#$($r.id)")
    }
}
$tabRecep.Controls.Add($gridCO)
$tabControl.Controls.Add($tabRecep)

$pnl.Controls.Add($tabControl)



