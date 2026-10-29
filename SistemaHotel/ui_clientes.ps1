param($pnl)

Limpar-Panel $pnl

$lblTitulo = Nova-RichLabel "Clientes" 20 15 200 30 -bold -size 16
$pnl.Controls.Add($lblTitulo)

$lblDesc = Nova-RichLabel "Cadastro de clientes para disparo de campanhas via WhatsApp" 20 48 600 20 -size 10 -color "#888"
$pnl.Controls.Add($lblDesc)

$btnNovo = Nova-Botao "+ Novo Cliente" ($pnl.Width - 300) 15 130 32 "#2e7d32"
$btnNovo.Anchor = "Top, Right"
$btnDisparo = Nova-Botao " Disparo WhatsApp" ($pnl.Width - 155) 15 140 32 "#25D366"
$btnDisparo.Anchor = "Top, Right"
$btnDisparo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$pnl.Controls.AddRange(@($btnNovo, $btnDisparo))

$lblBusca = Nova-RichLabel "Buscar:" 20 80 50 25 -size 10
$txtBusca = New-Object System.Windows.Forms.TextBox
$txtBusca.Location = New-Object System.Drawing.Point(75, 80)
$txtBusca.Size = New-Object System.Drawing.Size([math]::Min(300, ($pnl.Width - 200)), 25)
$txtBusca.Anchor = "Top, Left, Right"
$pnl.Controls.AddRange(@($lblBusca, $txtBusca))

$gridY = 115
$grid = Nova-Table 20 $gridY ($pnl.Width - 60) ($pnl.Height - $gridY - 40)
$grid.Anchor = "Top, Left, Right, Bottom"
$grid.ColumnCount = 7
$grid.Columns[0].HeaderText = "#"; $grid.Columns[1].HeaderText = "Nome"
$grid.Columns[2].HeaderText = "Telefone"; $grid.Columns[3].HeaderText = "Email"
$grid.Columns[4].HeaderText = "Data Cadastro"; $grid.Columns[5].HeaderText = "WhatsApp"
$grid.Columns[6].HeaderText = "Ativo"

function CarregarClientes {
    param($filtro)
    $grid.Rows.Clear()
    $d = Get-DadosClientes
    if (-not $d -or -not $d.clientes) { return }
    $lista = $d.clientes
    if ($filtro) {
        $f = $filtro.ToLower()
        $lista = @($lista | Where-Object { $_.nome.ToLower().Contains($f) -or $_.telefone.Contains($f) -or $_.email.ToLower().Contains($f) })
    }
    foreach ($c in $lista) {
        $wpp = if ($c.whatsapp_opt_in) { "[SIM]" } else { "[NAO]" }
        $ativo = if ($c.ativo) { "[SIM]" } else { "[NAO]" }
        $idx = $grid.Rows.Add($c.id, $c.nome, $c.telefone, $c.email, $c.data_cadastro, $wpp, $ativo)
        $grid.Rows[$idx].Tag = $c
    }
}

$cmsCli = New-Object System.Windows.Forms.ContextMenuStrip
$menuExcluirCli = New-Object System.Windows.Forms.ToolStripMenuItem("Excluir Cliente")
$menuExcluirCli.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40)
$cmsCli.Items.Add($menuExcluirCli)
$grid.ContextMenuStrip = $cmsCli

$menuExcluirCli.Add_Click({
    if ($grid.SelectedRows.Count -eq 0) { return }
    $cAlvo = $grid.SelectedRows[0].Tag
    if (-not $cAlvo) { return }
    $resp = [System.Windows.Forms.MessageBox]::Show("Excluir cliente #$($cAlvo.id) - $($cAlvo.nome)?", "Confirmar Exclusao", "YesNo", "Warning")
    if ($resp -eq "Yes") {
        $dados = Get-DadosClientes
        $dados.clientes = @($dados.clientes | Where-Object { $_.id -ne $cAlvo.id })
        Save-Clientes $dados
        CarregarClientes $null
    }
})

CarregarClientes $null
$pnl.Controls.Add($grid)

$txtBusca.Add_TextChanged({
    if ($this.Text.Length -ge 2) { CarregarClientes $this.Text } else { CarregarClientes $null }
})

$btnNovo.Add_Click({
    $formNovo = New-Object System.Windows.Forms.Form
    $formNovo.Text = "Novo Cliente"
    $formNovo.Size = New-Object System.Drawing.Size(450, 340)
    $formNovo.StartPosition = "CenterParent"
    $formNovo.FormBorderStyle = "FixedDialog"
    $formNovo.MaximizeBox = $false; $formNovo.MinimizeBox = $false

    $yf = 15
    $formNovo.Controls.Add((Nova-RichLabel "Nome:" 15 $yf 100 25))
    $txtNome = New-Object System.Windows.Forms.TextBox
    $txtNome.Location = New-Object System.Drawing.Point(120, $yf); $txtNome.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtNome)

    $yf = 50
    $formNovo.Controls.Add((Nova-RichLabel "Telefone:" 15 $yf 100 25))
    $txtTel = New-Object System.Windows.Forms.TextBox
    $txtTel.Location = New-Object System.Drawing.Point(120, $yf); $txtTel.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtTel)

    $yf = 85
    $formNovo.Controls.Add((Nova-RichLabel "Email:" 15 $yf 100 25))
    $txtEmail = New-Object System.Windows.Forms.TextBox
    $txtEmail.Location = New-Object System.Drawing.Point(120, $yf); $txtEmail.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtEmail)

    $yf = 120
    $formNovo.Controls.Add((Nova-RichLabel "Observações:" 15 $yf 100 25))
    $txtObs = New-Object System.Windows.Forms.TextBox
    $txtObs.Location = New-Object System.Drawing.Point(120, $yf); $txtObs.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtObs)

    $yf = 155
    $chkOptIn = New-Object System.Windows.Forms.CheckBox
    $chkOptIn.Text = "Aceita receber mensagens via WhatsApp"
    $chkOptIn.Location = New-Object System.Drawing.Point(120, $yf)
    $chkOptIn.Size = New-Object System.Drawing.Size(300, 25)
    $chkOptIn.Checked = $true
    $formNovo.Controls.Add($chkOptIn)

    $yf = 200
    $btnSalvar = Nova-Botao "Salvar" 150 $yf 120 35 "#1565c0"
    $btnCancelar = Nova-Botao "Cancelar" 290 $yf 120 35 "#757575"
    $formNovo.Controls.AddRange(@($btnSalvar, $btnCancelar))

    $btnCancelar.Add_Click({ $formNovo.Close() })
    $btnSalvar.Add_Click({
        if (-not $txtNome.Text -or -not $txtTel.Text) {
            [System.Windows.Forms.MessageBox]::Show("Nome e telefone obrigatórios", "Erro"); return
        }
        $d = Get-DadosClientes
        if (-not $d) { $d = @{clientes = @()} }
        $ultimoId = if ($d.clientes.Count -gt 0) { ($d.clientes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novo = [PSCustomObject]@{
            id = $ultimoId + 1; nome = $txtNome.Text; telefone = $txtTel.Text
            email = $txtEmail.Text; data_cadastro = (Get-Date -Format "yyyy-MM-dd")
            observacoes = $txtObs.Text; ativo = $true
            whatsapp_opt_in = $chkOptIn.Checked
        }
        $d.clientes += $novo
        Save-Clientes $d
        $formNovo.Close()
        CarregarClientes $null
        [System.Windows.Forms.MessageBox]::Show("Cliente cadastrado com sucesso!", "Sucesso")
    })
    $formNovo.ShowDialog()
})

$btnDisparo.Add_Click({
    $d = Get-DadosClientes
    if (-not $d -or -not $d.clientes) {
        [System.Windows.Forms.MessageBox]::Show("Nenhum cliente cadastrado.", "Aviso"); return
    }
    $contatos = @($d.clientes | Where-Object { $_.whatsapp_opt_in -eq $true -and $_.ativo -eq $true })
    if ($contatos.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhum cliente com WhatsApp ativo.", "Aviso"); return
    }

    $formMsg = New-Object System.Windows.Forms.Form
    $formMsg.Text = "Disparo em Massa - WhatsApp"
    $formMsg.Size = New-Object System.Drawing.Size(600, 500)
    $formMsg.StartPosition = "CenterParent"
    $formMsg.FormBorderStyle = "FixedDialog"
    $formMsg.MaximizeBox = $false; $formMsg.MinimizeBox = $false

    $lblInfo = Nova-RichLabel "Enviar mensagem para $($contatos.Count) contato(s) com WhatsApp ativo:" 15 15 550 25 -size 10 -color "#888"
    $formMsg.Controls.Add($lblInfo)

    $lblModelo = Nova-RichLabel "Modelo da Mensagem:" 15 50 200 25 -bold -size 12
    $formMsg.Controls.Add($lblModelo)

    $cmbModelo = New-Object System.Windows.Forms.ComboBox
    $cmbModelo.Location = New-Object System.Drawing.Point(15, 80)
    $cmbModelo.Size = New-Object System.Drawing.Size(550, 25)
    $cmbModelo.DropDownStyle = "DropDownList"
    $cmbModelo.Items.AddRange(@("Divulgação - Promoção", "Divulgação - Novidades", "Lembrete de Reserva", "Mensagem Personalizada"))
    $cmbModelo.SelectedIndex = 0
    $formMsg.Controls.Add($cmbModelo)

    $lblMsg = Nova-RichLabel "Mensagem:" 15 115 200 25 -bold -size 12
    $formMsg.Controls.Add($lblMsg)

    $txtMsg = New-Object System.Windows.Forms.TextBox
    $txtMsg.Location = New-Object System.Drawing.Point(15, 145)
    $txtMsg.Size = New-Object System.Drawing.Size(550, 200)
    $txtMsg.Multiline = $true
    $txtMsg.ScrollBars = "Vertical"
    $txtMsg.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $txtMsg.Text = "Olá, [NOME]!`n`nTemos novidades para você!`n`nConfira nossas promoções especiais para o mês.`n`nAproveite e garanta já sua estadia!`n`nWhatsApp: [TELEFONE]"
    $formMsg.Controls.Add($txtMsg)

    $cmbModelo.Add_SelectedIndexChanged({
        switch ($cmbModelo.SelectedIndex) {
            0 { $txtMsg.Text = "Olá, [NOME]!`n`nTemos novidades para você!`n`nConfira nossas promoções especiais para o mês.`n`nAproveite e garanta já sua estadia!`n`nWhatsApp: [TELEFONE]" }
            1 { $txtMsg.Text = "Olá, [NOME]!`n`nEstamos com novidades imperdíveis!`n`nNovos pacotes, quartos reformados e muito mais.`n`nVisite nosso site e confira!`n`nWhatsApp: [TELEFONE]" }
            2 { $txtMsg.Text = "Olá, [NOME]!`n`nPassando para lembrá-lo(a) de sua reserva.`n`nEstamos ansiosos para recebê-lo(a)!`n`nQualquer dúvida, estamos à disposição.`n`nWhatsApp: [TELEFONE]" }
            3 { $txtMsg.Text = "Olá, [NOME]!`n`n[Digite aqui sua mensagem personalizada]" }
        }
    })

    $lblNomes = Nova-RichLabel "Selecione os contatos:" 15 360 550 25 -bold -size 12
    $formMsg.Controls.Add($lblNomes)

    $chkList = New-Object System.Windows.Forms.CheckedListBox
    $chkList.Location = New-Object System.Drawing.Point(15, 390)
    $chkList.Size = New-Object System.Drawing.Size(550, 80)
    $chkList.CheckOnClick = $true
    foreach ($c in $contatos) {
        [void]$chkList.Items.Add("$($c.nome) - $($c.telefone)", $true)
    }
    $formMsg.Controls.Add($chkList)

    $btnEnviar = Nova-Botao " Enviar para Selecionados" 200 435 180 35 "#25D366"
    $btnEnviar.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnCancelar = Nova-Botao "Cancelar" 400 435 120 35 "#757575"
    $formMsg.Controls.AddRange(@($btnEnviar, $btnCancelar))

    $btnCancelar.Add_Click({ $formMsg.Close() })
    $btnEnviar.Add_Click({
        $modelo = $txtMsg.Text
        if (-not $modelo) { [System.Windows.Forms.MessageBox]::Show("Digite uma mensagem", "Erro"); return }
        $enviados = 0
        $falhas = 0
        for ($i = 0; $i -lt $chkList.Items.Count; $i++) {
            if ($chkList.GetItemChecked($i) -and $i -lt $contatos.Count) {
                $c = $contatos[$i]
                $tel = $c.telefone -replace '\D',''
                if ($tel.Length -ge 10) {
                    $msgPessoal = $modelo -replace '\[NOME\]', $c.nome
                    $msgUrl = [System.Web.HttpUtility]::UrlEncode($msgPessoal)
                    $url = "https://api.whatsapp.com/send?phone=55$tel&text=$msgUrl"
                    Start-Process $url
                    Start-Sleep -Milliseconds 800
                    $enviados++
                } else {
                    $falhas++
                }
            }
        }
        $formMsg.Close()
        CarregarClientes $null
        [System.Windows.Forms.MessageBox]::Show("Processo concluído!`n$enviados mensagem(ns) enviada(s)`n$falhas falha(s) de telefone", "Resultado")
    })
    $formMsg.ShowDialog()
})



