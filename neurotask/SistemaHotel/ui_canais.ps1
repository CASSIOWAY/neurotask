param($pnl)

if (-not $pnl) { return }

Limpar-Panel $pnl
if (-not $global:uiDir) { $global:uiDir = Split-Path $PSCommandPath -Parent }

$lblTitulo = Nova-RichLabel "Motor de Reservas e Gestor de Canais" 15 15 500 30 -bold -size 16
$pnl.Controls.Add($lblTitulo)

$lblDesc = Nova-RichLabel "Configure e monitore reservas de todas as plataformas conectadas" 15 50 600 20 -size 10 -color "#888"
$pnl.Controls.Add($lblDesc)

$d = Get-DadosReservas
$cfg = Get-DadosConfig
$intCfg = if ($cfg -and $cfg.integracoes) { $cfg.integracoes } else { @{} }
$ultSyncGlobal = if ($intCfg) { $intCfg.ultima_sincronizacao_global } else { "" }

function Abrir-ConfigCanal {
    param($canalId, $canalNome, $comDefault)
    $cfgC = Get-DadosConfig
    $int = if ($cfgC -and $cfgC.integracoes) { $cfgC.integracoes } else { @{} }
    $dados = if ($int.$canalId) { $int.$canalId } else { @{ativo=$false; api_url=""; api_key=""; usuario=""; senha=""; comissao_percentual=$comDefault; auto_importar=$false; ultima_sincronizacao=""} }

    $formC = New-Object System.Windows.Forms.Form
    $formC.Text = "Configurar $canalNome"
    $formC.Size = New-Object System.Drawing.Size(460, 480)
    $formC.StartPosition = "CenterParent"
    $formC.FormBorderStyle = "FixedDialog"
    $formC.MaximizeBox = $false; $formC.MinimizeBox = $false

    $y = 20
    $chkAtivo = New-Object System.Windows.Forms.CheckBox
    $chkAtivo.Text = "Canal Ativo"
    $chkAtivo.Location = New-Object System.Drawing.Point(20, $y)
    $chkAtivo.Size = New-Object System.Drawing.Size(200, 25)
    $chkAtivo.Checked = if ($dados.ativo) { $true } else { $false }
    $formC.Controls.Add($chkAtivo)

    $y = 55
    $formC.Controls.Add((Nova-RichLabel "API URL:" 20 $y 100 25))
    $txtURL = New-Object System.Windows.Forms.TextBox
    $txtURL.Location = New-Object System.Drawing.Point(120, $y); $txtURL.Size = New-Object System.Drawing.Size(300, 25)
    $txtURL.Text = if ($dados.api_url) { $dados.api_url } else { "" }
    $formC.Controls.Add($txtURL)

    $y = 90
    $formC.Controls.Add((Nova-RichLabel "API Key:" 20 $y 100 25))
    $txtKey = New-Object System.Windows.Forms.TextBox
    $txtKey.Location = New-Object System.Drawing.Point(120, $y); $txtKey.Size = New-Object System.Drawing.Size(300, 25)
    $txtKey.Text = if ($dados.api_key) { $dados.api_key } else { "" }
    $formC.Controls.Add($txtKey)

    $y = 125
    $formC.Controls.Add((Nova-RichLabel "Usuario:" 20 $y 100 25))
    $txtUser = New-Object System.Windows.Forms.TextBox
    $txtUser.Location = New-Object System.Drawing.Point(120, $y); $txtUser.Size = New-Object System.Drawing.Size(300, 25)
    $txtUser.Text = if ($dados.usuario) { $dados.usuario } else { "" }
    $formC.Controls.Add($txtUser)

    $y = 160
    $formC.Controls.Add((Nova-RichLabel "Senha:" 20 $y 100 25))
    $txtPass = New-Object System.Windows.Forms.TextBox
    $txtPass.Location = New-Object System.Drawing.Point(120, $y); $txtPass.Size = New-Object System.Drawing.Size(300, 25)
    $txtPass.PasswordChar = "*"
    $txtPass.Text = if ($dados.senha) { $dados.senha } else { "" }
    $formC.Controls.Add($txtPass)

    $y = 195
    $formC.Controls.Add((Nova-RichLabel "Comissao (%):" 20 $y 100 25))
    $txtCom = New-Object System.Windows.Forms.TextBox
    $txtCom.Location = New-Object System.Drawing.Point(120, $y); $txtCom.Size = New-Object System.Drawing.Size(60, 25)
    $txtCom.Text = if ($dados.comissao_percentual) { "$($dados.comissao_percentual)" } else { "0" }
    $formC.Controls.Add($txtCom)

    $y = 230
    $chkAuto = New-Object System.Windows.Forms.CheckBox
    $chkAuto.Text = "Importar automaticamente"
    $chkAuto.Location = New-Object System.Drawing.Point(20, $y)
    $chkAuto.Size = New-Object System.Drawing.Size(250, 25)
    $chkAuto.Checked = if ($dados.auto_importar) { $true } else { $false }
    $formC.Controls.Add($chkAuto)

    $y = 270
    $formC.Controls.Add((Nova-RichLabel "Painel URL:" 20 $y 100 25))
    $txtPainel = New-Object System.Windows.Forms.TextBox
    $txtPainel.Location = New-Object System.Drawing.Point(120, $y); $txtPainel.Size = New-Object System.Drawing.Size(300, 25)
    $txtPainel.Text = if ($dados.painel_url) { $dados.painel_url } else { "" }
    $formC.Controls.Add($txtPainel)

    $y = 305
    $lblSync = Nova-RichLabel "" 20 $y 400 20 -size 9 -color "#888"
    $ultSync = if ($dados.ultima_sincronizacao -and $dados.ultima_sincronizacao -ne "") { $dados.ultima_sincronizacao } else { "Nunca" }
    $lblSync.Text = "Ultima sincronizacao: $ultSync"
    $formC.Controls.Add($lblSync)

    $y = 345
    $btnSalvarC = Nova-Botao " Salvar Configuracao" 80 $y 180 35 "#1565c0"
    $btnTestar = Nova-Botao " Testar Conexao" 280 $y 140 35 "#2e7d32"
    $formC.Controls.AddRange(@($btnSalvarC, $btnTestar))

    $btnSalvarC.Add_Click({
        $cfgS = Get-DadosConfig
        if (-not $cfgS) { $cfgS = @{integracoes=@{}} }
        if (-not $cfgS.integracoes) { $cfgS.integracoes = @{} }
        $__com = ($txtCom.Text -replace '\D','') -as [int]
        if (-not $__com) { $__com = 0 }
        $cfgS.integracoes.$canalId = [PSCustomObject]@{
            ativo = if ($chkAtivo.Checked) { $true } else { $false }
            api_url = $txtURL.Text.Trim()
            api_key = $txtKey.Text.Trim()
            usuario = $txtUser.Text.Trim()
            senha = $txtPass.Text.Trim()
            comissao_percentual = [math]::Max(0, $__com)
            auto_importar = [bool]$chkAuto.Checked
            painel_url = $txtPainel.Text.Trim()
            ultima_sincronizacao = $dados.ultima_sincronizacao
        }
        Save-Config $cfgS
        $formC.Close()
        & (Join-Path $global:uiDir "ui_canais.ps1") $global:pnlContent
    })

    $btnTestar.Add_Click({
        $url = $txtURL.Text.Trim()
        if (-not $url) { [System.Windows.Forms.MessageBox]::Show("Informe a URL da API", "Teste"); return }
        [System.Windows.Forms.MessageBox]::Show("Teste de conexao com $canalNome realizado com sucesso!`nURL: $url`nStatus: OK (simulado)", "Conexao OK")
    })
    $formC.ShowDialog()
}

function Sincronizar-Canal {
    param($canalId, $canalNome)
    $resp = [System.Windows.Forms.MessageBox]::Show("Importar reservas simuladas de $canalNome agora?`nNovos hospedes, reservas e lancamentos financeiros serao criados.", "Sincronizar $canalNome", "YesNo", "Question")
    if ($resp -eq "Yes") {
        $resultado = Importar-ReservasSimuladas -canaisParaImportar @($canalId)
        if ($resultado -and $resultado.sucesso) {
            [System.Windows.Forms.MessageBox]::Show("Importacao concluida via $canalNome!`nReservas importadas: $($resultado.importadas)", "Sucesso")
        } elseif ($resultado -and $resultado.erro) {
            [System.Windows.Forms.MessageBox]::Show("Erro: $($resultado.erro)", "Falha")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Erro inesperado ao importar reservas.", "Falha")
        }
        & (Join-Path $global:uiDir "ui_canais.ps1") $global:pnlContent
    }
}

$canaisInfo = @(
    @{id="direto"; nome="Reserva Direta"; ico="[D]"; com=0; cor="#1565c0"; api="Sistema local"}
    @{id="booking"; nome="Booking.com"; ico="[B]"; com=15; cor="#e65100"; api="https://distribution-xml.booking.com"}
    @{id="expedia"; nome="Expedia"; ico="[E]"; com=18; cor="#2e7d32"; api="https://api.expediapartnercentral.com"}
    @{id="airbnb"; nome="Airbnb"; ico="[A]"; com=12; cor="#c62828"; api="https://api.airbnb.com"}
    @{id="omnibees"; nome="Omnibees"; ico="[O]"; com=15; cor="#6a1b9a"; api="https://api.omnibees.com"}
)

$fnAbrir = ${function:Abrir-ConfigCanal}
$fnSinc = ${function:Sincronizar-Canal}

$yCard = 85
$cardW = [math]::Min(280, [math]::Max(220, [int](($pnl.Width - 60) / 3)))
$xGap = 15
$xCard = $xGap
foreach ($c in $canaisInfo) {
    $qtd = 0; $rec = 0
    if ($d -and $d.reservas) {
        $resa = @($d.reservas | Where-Object { $_.canal -eq $c.id -and $_.status -ne "cancelada" })
        $qtd = $resa.Count
        $rec = ($resa | Measure-Object -Property valor_total -Sum).Sum
        if (-not $rec) { $rec = 0 }
    }

    $cCfg = if ($intCfg -and $intCfg.$($c.id)) { $intCfg.$($c.id) } else { $null }
    $ativo = if ($cCfg) { $cCfg.ativo } else { $false }

    $pnlCard = New-Object System.Windows.Forms.Panel
    $pnlCard.Location = New-Object System.Drawing.Point($xCard, $yCard)
    $pnlCard.Size = New-Object System.Drawing.Size($cardW, 140)
    $pnlCard.BackColor = "#fff"; $pnlCard.BorderStyle = "FixedSingle"

    $pnlCard.Controls.Add((Nova-RichLabel $c.ico 10 10 35 35 -size 20 -color $c.cor))
    $pnlCard.Controls.Add((Nova-RichLabel $c.nome 50 10 ($cardW - 60) 25 -bold -size 12))
    $pnlCard.Controls.Add((Nova-RichLabel "Comissao: $($c.com)% | Reservas: $qtd | Receita: $(FormatarMoeda $rec)" 50 35 ($cardW - 60) 30 -size 8 -color "#888"))
    $pnlCard.Controls.Add((Nova-RichLabel "API: $($c.api)" 10 60 ($cardW - 20) 18 -size 7 -color "#aaa"))

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = if ($ativo) { " Conectado " } else { " Desativado " }
    $lblStatus.Location = New-Object System.Drawing.Point(($cardW - 80), 10)
    $lblStatus.Size = New-Object System.Drawing.Size(65, 20)
    if ($ativo) {
        $lblStatus.BackColor = [System.Drawing.Color]::FromArgb(46, 125, 50)
    } else {
        $lblStatus.BackColor = [System.Drawing.Color]::FromArgb(158, 158, 158)
    }
    $lblStatus.ForeColor = "#fff"; $lblStatus.TextAlign = "MiddleCenter"
    $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $pnlCard.Controls.Add($lblStatus)

    $btnConfig = Nova-Botao "Config" 10 85 70 25 "#546e7a" 7
    $btnSync = Nova-Botao "Sinc" 85 85 60 25 "#1565c0" 7
    $btnConfig.Add_Click({ & $fnAbrir $c.id $c.nome $c.com }.GetNewClosure())
    $btnSync.Add_Click({ & $fnSinc $c.id $c.nome }.GetNewClosure())
    $pnlCard.Controls.AddRange(@($btnConfig, $btnSync))

    $pnl.Controls.Add($pnlCard)

    $xCard += ($cardW + $xGap)
    if ($xCard + $cardW -gt $pnl.Width) { $xCard = $xGap; $yCard += 155 }
}

# Sync All Button
$ySyncAll = $yCard + 10
$btnSyncAll = Nova-Botao " Sincronizar Todos os Canais" 20 $ySyncAll 250 32 "#1565c0" 10
$btnSyncAll.Add_Click({
    $canaisAtivos = @()
    foreach ($c in $canaisInfo) {
        $cCfg2 = if ($intCfg.$($c.id)) { $intCfg.$($c.id) } else { $null }
        if ($cCfg2 -and $cCfg2.ativo) { $canaisAtivos += $c.id }
    }
    if ($canaisAtivos.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhum canal ativo configurado. Ative pelo menos um canal nas configuracoes.", "Atencao", "OK", "Warning")
        return
    }
    $resp = [System.Windows.Forms.MessageBox]::Show("Importar reservas simuladas de $($canaisAtivos.Count) canais ativos agora?`nNovos hospedes, reservas e lancamentos serao gerados.", "Importar de Todos os Canais", "YesNo", "Question")
    if ($resp -eq "Yes") {
        $resultado = Importar-ReservasSimuladas -canaisParaImportar $canaisAtivos
        if ($resultado -and $resultado.sucesso) {
            [System.Windows.Forms.MessageBox]::Show($resultado.mensagem, "Importacao Global Concluida")
        } elseif ($resultado -and $resultado.erro) {
            [System.Windows.Forms.MessageBox]::Show("Erro: $($resultado.erro)", "Falha")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Erro inesperado ao importar reservas.", "Falha")
        }
        & (Join-Path $global:uiDir "ui_canais.ps1") $global:pnlContent
    }
})
$pnl.Controls.Add($btnSyncAll)

$lblUltSync = Nova-RichLabel "" ($pnl.Width - 350) ($ySyncAll + 5) 300 20 -size 9 -color "#888"
$lblUltSync.Text = "Ultima sincronizacao global: $(if ($ultSyncGlobal -and $ultSyncGlobal -ne '') { $ultSyncGlobal } else { 'Nunca' })"
$pnl.Controls.Add($lblUltSync)

$yGrid = $ySyncAll + 50
if ($d -and $d.reservas) {
    $lblDist = Nova-RichLabel "Comparativo de Produtividade por Canal" 20 $yGrid 400 25 -bold -size 14
    $pnl.Controls.Add($lblDist)

    $btnPrintCanais = Nova-Botao " Imprimir Relatorio" ($pnl.Width - 150) ($yGrid + 2) 140 25 "#1565c0" 9
    $btnPrintCanais.Anchor = "Top, Right"
    $pnl.Controls.Add($btnPrintCanais)

    $grid = Nova-Table 20 ($yGrid + 30) ($pnl.Width - 60) ($pnl.Height - $yGrid - 160)
    $grid.Anchor = "Top, Left, Right, Bottom"
    $grid.ColumnCount = 9
    $grid.Columns[0].HeaderText = "Canal"
    $grid.Columns[1].HeaderText = "Reservas"
    $grid.Columns[2].HeaderText = "Receita Bruta"
    $grid.Columns[3].HeaderText = "Ticket Medio"
    $grid.Columns[4].HeaderText = "Noites"
    $grid.Columns[5].HeaderText = "Comissao"
    $grid.Columns[6].HeaderText = "Custo Comiss."
    $grid.Columns[7].HeaderText = "Receita Liquida"
    $grid.Columns[8].HeaderText = "%"

    $dadosGrafico = @()
    $totalRec = 0; $totalCom = 0; $totalNoites = 0; $totalRes = 0

    $grid.Columns[1].DefaultCellStyle.Alignment = "MiddleRight"
    $grid.Columns[2].DefaultCellStyle.Alignment = "MiddleRight"
    $grid.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"
    $grid.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"
    $grid.Columns[5].DefaultCellStyle.Alignment = "MiddleCenter"
    $grid.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"
    $grid.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"
    $grid.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"

    foreach ($c in $canaisInfo) {
        $resa = @($d.reservas | Where-Object { $_.canal -eq $c.id -and $_.status -ne "cancelada" })
        $qtd = $resa.Count
        $recBruta = ($resa | Measure-Object -Property valor_total -Sum).Sum
        $noites = ($resa | Measure-Object -Property noites -Sum).Sum
        if (-not $recBruta) { $recBruta = 0 }
        if (-not $noites) { $noites = 0 }
        $ticketMedio = if ($qtd -gt 0) { $recBruta / $qtd } else { 0 }
        $comissao = if ($c.com -gt 0 -and $recBruta -gt 0) { $recBruta * $c.com / 100 } else { 0 }
        $recLiq = $recBruta - $comissao
        $pct = if ($dadosGrafico.Count -gt 0) { 0 } else { 0 }

        $grid.Rows.Add($c.nome, $qtd, $(FormatarMoeda $recBruta), $(FormatarMoeda $ticketMedio), $noites, "$($c.com)%", $(FormatarMoeda $comissao), $(FormatarMoeda $recLiq))
        $totalRec += $recBruta; $totalCom += $comissao; $totalNoites += $noites; $totalRes += $qtd
        $dadosGrafico += @{nome=$c.nome; qtd=$qtd; rec=$recBruta; cor=$c.cor}
    }

    $grid.Rows.Add("TOTAL", $totalRes, $(FormatarMoeda $totalRec), "", $totalNoites, "", $(FormatarMoeda $totalCom), $(FormatarMoeda ($totalRec - $totalCom)))
    $grid.Rows[$grid.Rows.Count - 1].DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $grid.Rows[$grid.Rows.Count - 1].DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $pnl.Controls.Add($grid)

    # Bar chart
    $chartY = $grid.Bottom + 10
    $chartH = 70
    $maxVal = ($dadosGrafico | Measure-Object -Property rec -Maximum).Maximum
    if ($maxVal -le 0) { $maxVal = 1 }
    $chartW = $pnl.Width - 80
    $barArea = $chartW / [math]::Max(1, $dadosGrafico.Count)
    $idxBar = 0
    foreach ($dg in $dadosGrafico) {
        $recBar = if ($dg.rec) { $dg.rec } else { 0 }
        $barH = [math]::Max(8, [int](($recBar / $maxVal) * ($chartH - 20)))
        $pnlBar = New-Object System.Windows.Forms.Panel
        $pnlBar.Location = New-Object System.Drawing.Point(30 + ($barArea * $idxBar), $chartY + ($chartH - 10 - $barH))
        $pnlBar.Size = New-Object System.Drawing.Size([math]::Max(40, $barArea - 10), $barH)
        $pnlBar.BackColor = [System.Drawing.ColorTranslator]::FromHtml($dg.cor)
        $pnl.Controls.Add($pnlBar)
        $pnl.Controls.Add((Nova-RichLabel $dg.nome (30 + ($barArea * $idxBar)) ($chartY + $chartH - 5) ([math]::Max(40, $barArea - 10)) 16 -size 7 -color "#888"))
        $idxBar++
    }

    $btnPrintCanais.Add_Click({
        $pgDados = $dadosGrafico
        $pgTotalRec = $totalRec; $pgTotalCom = $totalCom; $pgTotalNoites = $totalNoites; $pgTotalRes = $totalRes
        $linhas = @()
        $linhas += "RELATORIO COMPARATIVO DE CANAIS"
        $linhas += "========================================"
        $linhas += "Canal              | Reservas | Receita     | Comissao | Liq. Receber"
        $linhas += "----------------------------------------"
        foreach ($dg2 in $pgDados) {
            $ci2 = @($canaisInfo | Where-Object { $_.nome -eq $dg2.nome })
            $comV2 = 0
            if ($ci2.Count -gt 0 -and $ci2[0].com -gt 0 -and $dg2.rec -gt 0) { $comV2 = $dg2.rec * $ci2[0].com / 100 }
            $liq2 = $dg2.rec - $comV2
            $linhas += "$($dg2.nome.PadRight(18)) | $($dg2.qtd) | $(FormatarMoeda $dg2.rec) | $(FormatarMoeda $comV2) | $(FormatarMoeda $liq2)"
        }
        $linhas += "----------------------------------------"
        $linhas += "TOTAL              | $pgTotalRes | $(FormatarMoeda $pgTotalRec) | $(FormatarMoeda $pgTotalCom) | $(FormatarMoeda ($pgTotalRec - $pgTotalCom))"
        $linhas += "========================================"
        $linhas += "Emitido em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
        Nova-Imprimir ($linhas -join "`r`n") "Comparativo de Canais"
    })
}




