param($pnl)

Limpar-Panel $pnl

$d = Get-DadosReservas
$h = Get-DadosHospedes
$q = Get-DadosQuartos

$lblTitulo = Nova-RichLabel "Todas as Reservas" 15 15 300 30 -bold -size 16
$pnl.Controls.Add($lblTitulo)

$btnNova = Nova-Botao "+ Nova Reserva" ($pnl.Width - 290) 15 130 32 "#2e7d32"
$btnNova.Anchor = "Top, Right"
$pnl.Controls.Add($btnNova)

$btnNF = Nova-Botao "NF-e" ($pnl.Width - 150) 15 130 32 "#1565c0"
$btnNF.Anchor = "Top, Right"
$pnl.Controls.Add($btnNF)

$lblFiltro = Nova-RichLabel "Filtrar:" 20 55 50 25 -size 10
$pnl.Controls.Add($lblFiltro)

$chkUnificado = New-Object System.Windows.Forms.CheckBox
$chkUnificado.Text = "Unificado (locais + externas)"
$chkUnificado.Location = New-Object System.Drawing.Point(($pnl.Width - 280), 55)
$chkUnificado.Size = New-Object System.Drawing.Size(240, 25)
$chkUnificado.Anchor = "Top, Right"
$pnl.Controls.Add($chkUnificado)

$filtros = @("Todas","Pendente","Confirmada","Check-in","Check-out","Cancelada")
$fx = 75
$fy = 55
foreach ($f in $filtros) {
    $btnF = Nova-Botao $f $fx $fy 95 28 "#757575" 9
    $btnF.Tag = $f.ToLower()
    $btnF.Add_Click({ 
        $tag = $this.Tag
        $grid = @($pnl.Controls | Where-Object { $_ -is [System.Windows.Forms.DataGridView] })[0]
        if (-not $grid) { return }
        $grid.Rows.Clear()
        $chkU = @($pnl.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] })[0]
        $unif = ($chkU -and $chkU.Checked)
        if ($unif) {
            $todas = Get-ReservasUnificadasView
            $reservas = if ($tag -eq "todas") { $todas } else { @($todas | Where-Object { $_.status -eq $tag }) }
            foreach ($r in $reservas) {
                $grid.Rows.Add($r.id, $r.hospede, $r.quarto, (FormatarData $r.checkin), (FormatarData $r.checkout), $r.noites, $(FormatarMoeda $r.valor), $r.status, $r.origem)
            }
        } else {
            $dados = Get-DadosReservas
            $reservas = if ($tag -eq "todas") { $dados.reservas } else { @($dados.reservas | Where-Object { $_.status -eq $tag }) }
            foreach ($r in $reservas) {
                $grid.Rows.Add($r.id, (Get-HospedeNome $r.id_hospede), (Get-QuartoNumero $r.id_quarto), (FormatarData $r.data_checkin), (FormatarData $r.data_checkout), $r.noites, $(FormatarMoeda $r.valor_total), $r.status, "local")
            }
        }
    })
    $pnl.Controls.Add($btnF)
    $fx += 100
    if ($fx + 105 -gt $pnl.Width) { $fx = 75; $fy += 35 }
}

$chkUnificado.Add_CheckedChanged({
    $grid = @($pnl.Controls | Where-Object { $_ -is [System.Windows.Forms.DataGridView] })[0]
    if (-not $grid) { return }
    $grid.Rows.Clear()
    if ($this.Checked) {
        $grid.ColumnCount = 9
        $grid.Columns[0].HeaderText = "#"; $grid.Columns[1].HeaderText = "Hospede"
        $grid.Columns[2].HeaderText = "Quarto"; $grid.Columns[3].HeaderText = "Check-in"
        $grid.Columns[4].HeaderText = "Check-out"; $grid.Columns[5].HeaderText = "Noites"
        $grid.Columns[6].HeaderText = "Valor"; $grid.Columns[7].HeaderText = "Status"
        $grid.Columns[8].HeaderText = "Canal"
        $grid.Columns[8].MinimumWidth = 80
        $todas = Get-ReservasUnificadasView
        foreach ($r in $todas) {
            $grid.Rows.Add($r.id, $r.hospede, $r.quarto, (FormatarData $r.checkin), (FormatarData $r.checkout), $r.noites, $(FormatarMoeda $r.valor), $r.status, $r.origem)
        }
    } else {
        $grid.ColumnCount = 8
        $grid.Columns[0].HeaderText = "#"; $grid.Columns[1].HeaderText = "Hospede"
        $grid.Columns[2].HeaderText = "Quarto"; $grid.Columns[3].HeaderText = "Check-in"
        $grid.Columns[4].HeaderText = "Check-out"; $grid.Columns[5].HeaderText = "Noites"
        $grid.Columns[6].HeaderText = "Valor"; $grid.Columns[7].HeaderText = "Status"
        $dados = Get-DadosReservas
        if ($dados -and $dados.reservas) {
            foreach ($r in $dados.reservas) {
                $grid.Rows.Add($r.id, (Get-HospedeNome $r.id_hospede), (Get-QuartoNumero $r.id_quarto), (FormatarData $r.data_checkin), (FormatarData $r.data_checkout), $r.noites, $(FormatarMoeda $r.valor_total), $r.status)
            }
        }
    }
})

$availW = if ($global:pnlContent) { $global:pnlContent.Width - 60 } else { 500 }
$gridY = $fy + 35
$grid = Nova-Table 20 $gridY $availW ($pnl.Height - $gridY - 30)
$grid.Anchor = "Top, Left, Right, Bottom"
$grid.ColumnCount = 8
$grid.Columns[0].HeaderText = "#"; $grid.Columns[1].HeaderText = "Hospede"
$grid.Columns[2].HeaderText = "Quarto"; $grid.Columns[3].HeaderText = "Check-in"
$grid.Columns[4].HeaderText = "Check-out"; $grid.Columns[5].HeaderText = "Noites"
$grid.Columns[6].HeaderText = "Valor"; $grid.Columns[7].HeaderText = "Status"
$grid.Columns[0].MinimumWidth = 50; $grid.Columns[1].MinimumWidth = 150
$grid.Columns[2].MinimumWidth = 100; $grid.Columns[3].MinimumWidth = 100
$grid.Columns[4].MinimumWidth = 100; $grid.Columns[5].MinimumWidth = 60
$grid.Columns[6].MinimumWidth = 80; $grid.Columns[7].MinimumWidth = 90

if ($d -and $d.reservas) {
    foreach ($r in $d.reservas) {
        $grid.Rows.Add($r.id, (Get-HospedeNome $r.id_hospede), (Get-QuartoNumero $r.id_quarto), (FormatarData $r.data_checkin), (FormatarData $r.data_checkout), $r.noites, $(FormatarMoeda $r.valor_total), $r.status)
    }
}
$pnl.Controls.Add($grid)

$btnNova.Add_Click({
    $formNova = New-Object System.Windows.Forms.Form
    $formNova.Text = "Nova Reserva"
    $formNova.Size = New-Object System.Drawing.Size(520, 500)
    $formNova.StartPosition = "CenterParent"
    $formNova.FormBorderStyle = "FixedDialog"
    $formNova.MaximizeBox = $false; $formNova.MinimizeBox = $false

    $yf = 15
    $formNova.Controls.Add((Nova-RichLabel "Nome do Hóspede:" 15 $yf 130 25 -bold))
    $txtNomeHosp = New-Object System.Windows.Forms.TextBox
    $txtNomeHosp.Location = New-Object System.Drawing.Point(150, $yf); $txtNomeHosp.Size = New-Object System.Drawing.Size(345, 25)
    $formNova.Controls.Add($txtNomeHosp)

    $yf = 55
    $formNova.Controls.Add((Nova-RichLabel "Documento:" 15 $yf 130 25))
    $txtDoc = New-Object System.Windows.Forms.TextBox
    $txtDoc.Location = New-Object System.Drawing.Point(150, $yf); $txtDoc.Size = New-Object System.Drawing.Size(345, 25)
    $formNova.Controls.Add($txtDoc)

    $yf = 95
    $formNova.Controls.Add((Nova-RichLabel "Telefone:" 15 $yf 130 25))
    $txtTel = New-Object System.Windows.Forms.TextBox
    $txtTel.Location = New-Object System.Drawing.Point(150, $yf); $txtTel.Size = New-Object System.Drawing.Size(160, 25)
    $formNova.Controls.Add($txtTel)
    $formNova.Controls.Add((Nova-RichLabel "Email:" 330 $yf 50 25))
    $txtEmail = New-Object System.Windows.Forms.TextBox
    $txtEmail.Location = New-Object System.Drawing.Point(380, $yf); $txtEmail.Size = New-Object System.Drawing.Size(115, 25)
    $formNova.Controls.Add($txtEmail)

    $yf = 135
    $formNova.Controls.Add((Nova-RichLabel "Quarto/Acomodação:" 15 $yf 170 25 -bold))
    $cmbQ = New-Object System.Windows.Forms.ComboBox
    $cmbQ.Location = New-Object System.Drawing.Point(150, $yf); $cmbQ.Size = New-Object System.Drawing.Size(345, 25)
    $cmbQ.DropDownStyle = "DropDownList"
    $cmbQ.Items.AddRange(@("01","02","03","04","05","06"))
    $formNova.Controls.Add($cmbQ)

    $yf = 175
    $formNova.Controls.Add((Nova-RichLabel "Check-in:" 15 $yf 80 25))
    $dtCI = New-Object System.Windows.Forms.DateTimePicker
    $dtCI.Location = New-Object System.Drawing.Point(95, $yf); $dtCI.Size = New-Object System.Drawing.Size(150, 25)
    $dtCI.Format = "Short"
    $formNova.Controls.Add((Nova-RichLabel "Check-out:" 270 $yf 90 25))
    $dtCO = New-Object System.Windows.Forms.DateTimePicker
    $dtCO.Location = New-Object System.Drawing.Point(355, $yf); $dtCO.Size = New-Object System.Drawing.Size(140, 25)
    $dtCO.Format = "Short"
    $formNova.Controls.AddRange(@($dtCI, $dtCO))

    $yf = 215
    $formNova.Controls.Add((Nova-RichLabel "Pagamento:" 15 $yf 100 25))
    $cmbPag = New-Object System.Windows.Forms.ComboBox
    $cmbPag.Location = New-Object System.Drawing.Point(120, $yf); $cmbPag.Size = New-Object System.Drawing.Size(150, 25)
    $cmbPag.DropDownStyle = "DropDownList"
    "credito","debito","pix","dinheiro","boleto" | ForEach-Object { $cmbPag.Items.Add($_) }
    $formNova.Controls.Add((Nova-RichLabel "Canal:" 290 $yf 100 25))
    $cmbCanal = New-Object System.Windows.Forms.ComboBox
    $cmbCanal.Location = New-Object System.Drawing.Point(370, $yf); $cmbCanal.Size = New-Object System.Drawing.Size(145, 25)
    $cmbCanal.DropDownStyle = "DropDownList"
    $cmbCanal.FlatStyle = "Flat"
    "direto","booking","expedia","airbnb" | ForEach-Object { $cmbCanal.Items.Add($_) }
    $cmbCanal.SelectedIndex = 0
    $formNova.Controls.AddRange(@($cmbPag, $cmbCanal))

    $yf = 255
    $formNova.Controls.Add((Nova-RichLabel "Observações:" 15 $yf 100 25))
    $txtObs = New-Object System.Windows.Forms.TextBox
    $txtObs.Location = New-Object System.Drawing.Point(120, $yf); $txtObs.Size = New-Object System.Drawing.Size(375, 55)
    $txtObs.Multiline = $true
    $formNova.Controls.Add($txtObs)

    $yf = 320
    $lblObs2 = Nova-RichLabel "Cadastrar também como:" 15 $yf 200 20 -size 10 -bold
    $formNova.Controls.Add($lblObs2)

    $yf = 340
    $chkCliente = New-Object System.Windows.Forms.CheckBox
    $chkCliente.Text = "Cliente (para disparo de campanhas via WhatsApp)"
    $chkCliente.Location = New-Object System.Drawing.Point(25, $yf)
    $chkCliente.Size = New-Object System.Drawing.Size(470, 25)
    $chkCliente.Checked = $false
    $formNova.Controls.Add($chkCliente)

    $yf = 390
    $btnSalvar = Nova-Botao "Salvar Reserva" 140 $yf 190 35 "#1565c0"
    $btnCancelar = Nova-Botao "Cancelar" 345 $yf 130 35 "#757575"
    $formNova.Controls.AddRange(@($btnSalvar, $btnCancelar))

    $btnCancelar.Add_Click({ $formNova.Close() })
    $btnSalvar.Add_Click({
        $nomeHosp = $txtNomeHosp.Text.Trim()
        if (-not $nomeHosp) { [System.Windows.Forms.MessageBox]::Show("Informe o nome do hospede", "Erro"); return }
        if ($cmbQ.SelectedIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Selecione um quarto", "Erro"); return }
        if ($dtCI.Value -ge $dtCO.Value) { [System.Windows.Forms.MessageBox]::Show("Check-out deve ser apos check-in", "Erro"); return }

        $qId = [int]$cmbQ.SelectedItem
        $noites = ($dtCO.Value - $dtCI.Value).Days

        $conflitos = Verificar-DisponibilidadeQuarto $qId ($dtCI.Value.ToString("yyyy-MM-dd")) ($dtCO.Value.ToString("yyyy-MM-dd"))
        if ($conflitos.Count -gt 0) {
            $msg = "Quarto $qId ja esta ocupado neste periodo!`n`nConflitos encontrados:"
            foreach ($cf in $conflitos) { $msg += "`n  - #$($cf.id): $(Get-HospedeNome $cf.id_hospede) ($(FormatarData $cf.data_checkin) a $(FormatarData $cf.data_checkout))" }
            $msg += "`n`nDeseja continuar mesmo assim?"
            $resp = [System.Windows.Forms.MessageBox]::Show($msg, "Conflito de Datas", "YesNo", "Warning")
            if ($resp -eq "No") { return }
        }

        $qInfo = Get-QuartoInfo $qId
        $diaria = if ($qInfo) { $qInfo.preco_diaria } else { 0 }
        $total = $diaria * $noites

        $hosp = Get-DadosHospedes
        if (-not $hosp) { $hosp = @{hospedes = @()} }
        $ultimoIdH = if ($hosp.hospedes.Count -gt 0) { ($hosp.hospedes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novoHosp = [PSCustomObject]@{
            id = $ultimoIdH + 1; nome = $nomeHosp
            documento = $txtDoc.Text.Trim(); tipo_documento = "CPF"
            telefone = $txtTel.Text.Trim(); email = $txtEmail.Text.Trim()
            endereco = ""; nacionalidade = "Brasileira"
            data_cadastro = (Get-Date -Format "yyyy-MM-dd"); observacoes = ""
            total_visitas = 1; total_gasto = [math]::Round($total, 2)
        }
        $hosp.hospedes += $novoHosp
        Save-Hospedes $hosp

        if ($chkCliente.Checked) {
            $cli = Get-DadosClientes
            if (-not $cli) { $cli = @{clientes = @()} }
            $ultimoIdC = if ($cli.clientes.Count -gt 0) { ($cli.clientes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
            $novoCli = [PSCustomObject]@{
                id = $ultimoIdC + 1; nome = $nomeHosp
                telefone = $txtTel.Text.Trim(); email = $txtEmail.Text.Trim()
                data_cadastro = (Get-Date -Format "yyyy-MM-dd")
                observacoes = "Cadastrado automaticamente via reserva #$(($ultimoIdH + 1))"
                ativo = $true
                whatsapp_opt_in = ($txtTel.Text.Trim().Length -gt 0)
            }
            $cli.clientes += $novoCli
            Save-Clientes $cli
        }

        $data = Get-DadosReservas
        $ultimoId = if ($data.reservas.Count -gt 0) { ($data.reservas | Sort-Object id -Descending | Select-Object -First 1).id } else { 1000 }
        $nova = [PSCustomObject]@{
            id = $ultimoId + 1; id_hospede = $novoHosp.id; id_quarto = $qId
            data_checkin = $dtCI.Value.ToString("yyyy-MM-dd"); data_checkout = $dtCO.Value.ToString("yyyy-MM-dd")
            noites = $noites; status = "pendente"; origem = "recepcao"; canal = $cmbCanal.Text
            valor_total = [math]::Round($total, 2); valor_diaria = $diaria; desconto = 0
            taxa_servico = [math]::Round($total * 0.1, 2); metodo_pagamento = $cmbPag.Text
            situacao_pagamento = "pendente"; observacoes = $txtObs.Text
            data_reserva = (Get-Date -Format "yyyy-MM-dd")
            checkin_realizado = $null; checkout_realizado = $null
            adultos = 2; criancas = 0; whatsapp_enviado = $false
        }
        $data.reservas += $nova
        Save-Reservas $data
        $formNova.Close()
        [System.Windows.Forms.MessageBox]::Show("Reserva #$($nova.id) criada com sucesso!`nHospede cadastrado: $nomeHosp", "Sucesso")
        Confirmar-AtualizarCanais "criacao de reserva" "Reserva #$($nova.id) - $nomeHosp (Q:$qId, $([math]::Round($total,2)))"
    })
    $formNova.ShowDialog()
})

$btnNF.Add_Click({
    Start-Process "https://www.nfse.gov.br/EmissorNacional/Login?ReturnUrl=%2fEmissorNacional"
})


