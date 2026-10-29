param($pnl)

Limpar-Panel $pnl

$lblTitulo = Nova-RichLabel "Hóspedes" 20 15 200 30 -bold -size 16
$pnl.Controls.Add($lblTitulo)

$btnNovo = Nova-Botao "+ Novo Hóspede" ($pnl.Width - 400) 15 120 32 "#2e7d32"
$btnNovo.Anchor = "Top, Right"
$pnl.Controls.Add($btnNovo)

$btnFicha = Nova-Botao "Ficha Cadastro" ($pnl.Width - 270) 15 120 32 "#1565c0"
$btnFicha.Anchor = "Top, Right"
$pnl.Controls.Add($btnFicha)

$btnFichaBranco = Nova-Botao "Ficha em Branco" ($pnl.Width - 140) 15 120 32 "#757575"
$btnFichaBranco.Anchor = "Top, Right"
$pnl.Controls.Add($btnFichaBranco)

$lblBusca = Nova-RichLabel "Buscar:" 20 55 50 25 -size 10
$txtBusca = New-Object System.Windows.Forms.TextBox
$txtBusca.Location = New-Object System.Drawing.Point(75, 55)
$txtBusca.Size = New-Object System.Drawing.Size([math]::Min(300, ($pnl.Width - 200)), 25)
$txtBusca.Anchor = "Top, Left, Right"
$pnl.Controls.AddRange(@($lblBusca, $txtBusca))

$gridY = 90
$grid = Nova-Table 20 $gridY ($pnl.Width - 60) ($pnl.Height - $gridY - 40)
$grid.Anchor = "Top, Left, Right, Bottom"
$grid.ColumnCount = 7
$grid.Columns[0].HeaderText = "#"; $grid.Columns[1].HeaderText = "Nome"
$grid.Columns[2].HeaderText = "Documento"; $grid.Columns[3].HeaderText = "Telefone"
$grid.Columns[4].HeaderText = "Email"; $grid.Columns[5].HeaderText = "Visitas"
$grid.Columns[6].HeaderText = "Total Gasto"

function CarregarHospedes {
    param($filtro)
    $grid.Rows.Clear()
    $h = Get-DadosHospedes
    if (-not $h) { return }
    $lista = $h.hospedes
    if ($filtro) {
        $f = $filtro.ToLower()
        $lista = @($lista | Where-Object { $_.nome.ToLower().Contains($f) -or $_.documento.Contains($f) -or $_.telefone.Contains($f) })
    }
    foreach ($hp in $lista) {
        $idx = $grid.Rows.Add($hp.id, $hp.nome, $hp.documento, $hp.telefone, $hp.email, $hp.total_visitas, $(FormatarMoeda $hp.total_gasto))
        $grid.Rows[$idx].Tag = $hp
    }
}

$cmsHosp = New-Object System.Windows.Forms.ContextMenuStrip
$menuFichaH = New-Object System.Windows.Forms.ToolStripMenuItem("Ficha de Cadastro")
$menuFichaH.ForeColor = [System.Drawing.Color]::FromArgb(21, 101, 192)
$cmsHosp.Items.Add($menuFichaH)
$menuExcluirHosp = New-Object System.Windows.Forms.ToolStripMenuItem("Excluir Hospede")
$menuExcluirHosp.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40)
$cmsHosp.Items.Add($menuExcluirHosp)
$grid.ContextMenuStrip = $cmsHosp

$menuFichaH.Add_Click({
    if ($grid.SelectedRows.Count -eq 0) { return }
    $hAlvo = $grid.SelectedRows[0].Tag
    if (-not $hAlvo) { return }
    Nova-FichaCadastro $hAlvo
})

$menuExcluirHosp.Add_Click({
    if ($grid.SelectedRows.Count -eq 0) { return }
    $hAlvo = $grid.SelectedRows[0].Tag
    if (-not $hAlvo) { return }
    $resp = [System.Windows.Forms.MessageBox]::Show("Excluir hospede #$($hAlvo.id) - $($hAlvo.nome)?", "Confirmar Exclusao", "YesNo", "Warning")
    if ($resp -eq "Yes") {
        $dados = Get-DadosHospedes
        $dados.hospedes = @($dados.hospedes | Where-Object { $_.id -ne $hAlvo.id })
        Save-Hospedes $dados
        CarregarHospedes $null
    }
})

CarregarHospedes $null
$pnl.Controls.Add($grid)

$txtBusca.Add_TextChanged({
    if ($this.Text.Length -ge 2) { CarregarHospedes $this.Text } else { CarregarHospedes $null }
})

$btnNovo.Add_Click({
    $formNovo = New-Object System.Windows.Forms.Form
    $formNovo.Text = "Novo Hóspede"
    $formNovo.Size = New-Object System.Drawing.Size(450, 350)
    $formNovo.StartPosition = "CenterParent"
    $formNovo.FormBorderStyle = "FixedDialog"
    $formNovo.MaximizeBox = $false; $formNovo.MinimizeBox = $false

    $yf = 15
    $formNovo.Controls.Add((Nova-RichLabel "Nome:" 15 $yf 100 25))
    $txtNome = New-Object System.Windows.Forms.TextBox
    $txtNome.Location = New-Object System.Drawing.Point(120, $yf); $txtNome.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtNome)

    $yf = 50
    $formNovo.Controls.Add((Nova-RichLabel "Documento:" 15 $yf 100 25))
    $txtDoc = New-Object System.Windows.Forms.TextBox
    $txtDoc.Location = New-Object System.Drawing.Point(120, $yf); $txtDoc.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtDoc)

    $yf = 85
    $formNovo.Controls.Add((Nova-RichLabel "Telefone:" 15 $yf 100 25))
    $txtTel = New-Object System.Windows.Forms.TextBox
    $txtTel.Location = New-Object System.Drawing.Point(120, $yf); $txtTel.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtTel)

    $yf = 120
    $formNovo.Controls.Add((Nova-RichLabel "Email:" 15 $yf 100 25))
    $txtEmail = New-Object System.Windows.Forms.TextBox
    $txtEmail.Location = New-Object System.Drawing.Point(120, $yf); $txtEmail.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtEmail)

    $yf = 155
    $formNovo.Controls.Add((Nova-RichLabel "Endereço:" 15 $yf 100 25))
    $txtEnd = New-Object System.Windows.Forms.TextBox
    $txtEnd.Location = New-Object System.Drawing.Point(120, $yf); $txtEnd.Size = New-Object System.Drawing.Size(300, 25)
    $formNovo.Controls.Add($txtEnd)

    $yf = 200
    $btnSalvar = Nova-Botao "Salvar" 150 $yf 120 35 "#1565c0"
    $btnCancelar = Nova-Botao "Cancelar" 290 $yf 120 35 "#757575"
    $formNovo.Controls.AddRange(@($btnSalvar, $btnCancelar))

    $btnCancelar.Add_Click({ $formNovo.Close() })
    $btnSalvar.Add_Click({
        if (-not $txtNome.Text -or -not $txtDoc.Text) {
            [System.Windows.Forms.MessageBox]::Show("Nome e documento obrigatórios", "Erro"); return
        }
        $hosp = Get-DadosHospedes
        $ultimoId = if ($hosp.hospedes.Count -gt 0) { ($hosp.hospedes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novo = [PSCustomObject]@{
            id = $ultimoId + 1; nome = $txtNome.Text; documento = $txtDoc.Text
            tipo_documento = "CPF"; telefone = $txtTel.Text; email = $txtEmail.Text
            endereco = $txtEnd.Text; nacionalidade = "Brasileira"
            data_cadastro = (Get-Date -Format "yyyy-MM-dd"); observacoes = ""
            total_visitas = 0; total_gasto = 0
        }
        $hosp.hospedes += $novo
        Save-Hospedes $hosp
        $formNovo.Close()
        CarregarHospedes $null
        [System.Windows.Forms.MessageBox]::Show("Hóspede cadastrado!", "Sucesso")
    })
    $formNovo.ShowDialog()
})

$btnFicha.Add_Click({
    if ($grid.SelectedRows.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Selecione um hospede na lista", "Aviso"); return }
    $hAlvo = $grid.SelectedRows[0].Tag
    if (-not $hAlvo) { return }
    Nova-FichaCadastro $hAlvo
})

$btnFichaBranco.Add_Click({
    Nova-FichaEmBranco
})



