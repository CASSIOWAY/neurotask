Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$DataDir = Join-Path $PSScriptRoot "data"
$ModulesDir = Join-Path $PSScriptRoot "modules"

. (Join-Path $PSScriptRoot "modules\lib.ps1")
. (Join-Path $PSScriptRoot "modules\integracoes.ps1")

$uiModulos = @{
    "dashboard"   = Join-Path $PSScriptRoot "ui_dashboard.ps1"
    "calendario"  = Join-Path $PSScriptRoot "ui_calendario.ps1"
    "reservas"    = Join-Path $PSScriptRoot "ui_reservas.ps1"
    "operacoes"   = Join-Path $PSScriptRoot "ui_operacoes.ps1"
    "hospedes"    = Join-Path $PSScriptRoot "ui_hospedes.ps1"
    "clientes"    = Join-Path $PSScriptRoot "ui_clientes.ps1"
    "canais"      = Join-Path $PSScriptRoot "ui_canais.ps1"
    "financeiro"  = Join-Path $PSScriptRoot "ui_financeiro.ps1"
    "analise"     = Join-Path $PSScriptRoot "ui_analise.ps1"
    "whatsapp"    = Join-Path $PSScriptRoot "ui_whatsapp.ps1"
    "integracoes" = Join-Path $PSScriptRoot "ui_integracoes.ps1"
    "config"      = Join-Path $PSScriptRoot "ui_config.ps1"
}

$global:moduloAtual = "dashboard"
$global:form = $null
$global:pnlContent = $null
$global:lblTitulo = $null
$global:menuBotoes = @{}

function Set-Modulo {
    param($modulo)
    $global:moduloAtual = $modulo
    $global:lblTitulo.Text = $modulosNomes[$modulo]
    $global:pnlContent.Controls.Clear()
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Carregando..."; $lbl.TextAlign = "MiddleCenter"
    $lbl.Size = $global:pnlContent.Size; $lbl.ForeColor = [System.Drawing.Color]::FromArgb(136, 136, 136)
    $global:pnlContent.Controls.Add($lbl)
    $global:form.Refresh()

    foreach ($kv in $global:menuBotoes.GetEnumerator()) {
        $kv.Value.BackColor = if ($kv.Key -eq $modulo) { "#1565c0" } else { "#1a237e" }
        $kv.Value.ForeColor = "#ffffff"
        $kv.Value.Font = if ($kv.Key -eq $modulo) { $fontMenuAtivo } else { $fontMenu }
    }

    if ($uiModulos.ContainsKey($modulo)) {
        try {
            & $uiModulos[$modulo] $global:pnlContent
        } catch {
            $global:pnlContent.Controls.Clear()
            $lblErro = New-Object System.Windows.Forms.Label
            $lblErro.Text = "Erro ao carregar módulo: $($_.Exception.Message)"
            $lblErro.TextAlign = "MiddleCenter"
            $lblErro.Size = $global:pnlContent.Size
            $lblErro.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40)
            $lblErro.Font = New-Object System.Drawing.Font("Segoe UI", 11)
            $global:pnlContent.Controls.Add($lblErro)
        }
    }
}

$fontMenu = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$fontMenuAtivo = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)

$modulosNomes = @{
    "dashboard"   = "Painel de Controle"
    "calendario"  = "Calendário de Reservas"
    "reservas"    = "Gerenciar Reservas"
    "operacoes"   = "Operações do Dia"
    "hospedes"    = "Hóspedes"
    "clientes"    = "Clientes"
    "canais"      = "Gerente de Canal"
    "financeiro"  = "Fluxo de Caixa"
    "analise"     = "Análise e Relatórios"
    "whatsapp"    = "WhatsApp"
    "integracoes" = "Integrações (Omnibees/Booking)"
    "config"      = "Configurações"
}

function New-SistemaForm {
    $global:form = New-Object System.Windows.Forms.Form
    $form.Text = "Pousada Familiar Encanto da Chapada - Sistema de Gestão Hoteleira"
    $form.Size = New-Object System.Drawing.Size(1280, 800)
    $form.StartPosition = "CenterScreen"
    $form.MinimumSize = New-Object System.Drawing.Size(900, 600)
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Command powershell.exe).Source)
    $form.BackColor = "#f0f2f5"

    $pnlSidebar = New-Object System.Windows.Forms.Panel
    $pnlSidebar.Size = New-Object System.Drawing.Size(230, $form.ClientSize.Height)
    $pnlSidebar.Dock = "Left"
    $pnlSidebar.BackColor = "#1a237e"

    $pnlHeader = New-Object System.Windows.Forms.Panel
    $pnlHeader.Size = New-Object System.Drawing.Size(230, 80)
    $pnlHeader.Dock = "Top"
    $pnlHeader.BackColor = "#151b54"

    $lblTituloSidebar = New-Object System.Windows.Forms.Label
    $lblTituloSidebar.Text = "Pousada Familiar`nEncanto da Chapada"
    $lblTituloSidebar.Location = New-Object System.Drawing.Point(15, 12)
    $lblTituloSidebar.Size = New-Object System.Drawing.Size(200, 55)
    $lblTituloSidebar.ForeColor = "#ffffff"
    $lblTituloSidebar.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)

    $pnlHeader.Controls.Add($lblTituloSidebar)
    $pnlSidebar.Controls.Add($pnlHeader)

    $pnlMenu = New-Object System.Windows.Forms.Panel
    $pnlMenu.Location = New-Object System.Drawing.Point(0, 80)
    $pnlMenu.Size = New-Object System.Drawing.Size(230, ($form.ClientSize.Height - 80))
    $pnlMenu.BackColor = "#1a237e"
    $pnlSidebar.Controls.Add($pnlMenu)

    $itensMenu = @(
        @{mod="dashboard";   txt="Dashboard";         ico=">>"}
        @{mod="calendario";  txt="Calendario";        ico="[]"}
        @{mod="reservas";    txt="Reservas";          ico="++"}
        @{mod="operacoes";   txt="Operações";         ico="<>"}
        @{mod="hospedes";    txt="Hóspedes";          ico="@@"}
        @{mod="clientes";    txt="Clientes";          ico="[C]"}
        @{mod="canais";      txt="Canais";            ico="##"}
        @{mod="financeiro";  txt="Fluxo de Caixa";    ico="$$"}
        @{mod="analise";     txt="Análise";           ico="%%"}
        @{mod="whatsapp";    txt="WhatsApp";          ico="!!"}
        @{mod="integracoes"; txt="Integrações";       ico="&&"}
        @{mod="config";      txt="Configurações";     ico="**"}
    )

    $y = 10
    foreach ($item in $itensMenu) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = "  $($item.ico)  $($item.txt)"
        $btn.Location = New-Object System.Drawing.Point(10, $y)
        $btn.Size = New-Object System.Drawing.Size(210, 38)
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 0
        $btn.TextAlign = "MiddleLeft"
        $btn.Font = $fontMenu
        $btn.ForeColor = "#ffffff"
        $btn.BackColor = "#1a237e"
        $btn.Cursor = "Hand"
        $btn.Tag = $item.mod
        $btn.Add_Click({ Set-Modulo $this.Tag })
        $pnlMenu.Controls.Add($btn)
        $global:menuBotoes[$item.mod] = $btn
        $y += 42
    }

    $pnlTopo = New-Object System.Windows.Forms.Panel
    $pnlTopo.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 230), 50)
    $pnlTopo.Location = New-Object System.Drawing.Point(230, 0)
    $pnlTopo.BackColor = "#ffffff"
    $pnlTopo.BorderStyle = "FixedSingle"

    $global:lblTitulo = New-Object System.Windows.Forms.Label
    $global:lblTitulo.Text = "Painel de Controle"
    $global:lblTitulo.Location = New-Object System.Drawing.Point(20, 12)
    $global:lblTitulo.Size = New-Object System.Drawing.Size(500, 28)
    $global:lblTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $global:lblTitulo.ForeColor = "#333"
    $pnlTopo.Controls.Add($global:lblTitulo)

    $lblData = New-Object System.Windows.Forms.Label
    $lblData.Text = (Get-Date -Format "dddd, dd/MM/yyyy").ToUpper()
    $lblData.Location = New-Object System.Drawing.Point(($pnlTopo.Width - 280), 15)
    $lblData.Size = New-Object System.Drawing.Size(260, 20)
    $lblData.TextAlign = "MiddleRight"
    $lblData.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblData.ForeColor = "#888"
    $pnlTopo.Controls.Add($lblData)

    $btnFechar = New-Object System.Windows.Forms.Button
    $btnFechar.Text = "Sair"
    $btnFechar.Location = New-Object System.Drawing.Point(($pnlTopo.Width - 75), 10)
    $btnFechar.Size = New-Object System.Drawing.Size(60, 30)
    $btnFechar.FlatStyle = "Flat"
    $btnFechar.FlatAppearance.BorderSize = 0
    $btnFechar.BackColor = "#c62828"
    $btnFechar.ForeColor = "#ffffff"
    $btnFechar.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnFechar.Cursor = "Hand"
    $btnFechar.Add_Click({ $global:form.Close() })
    $pnlTopo.Controls.Add($btnFechar)

    $global:pnlContent = New-Object System.Windows.Forms.Panel
    $global:pnlContent.Location = New-Object System.Drawing.Point(230, 50)
    $global:pnlContent.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 240), ($form.ClientSize.Height - 60))
    $global:pnlContent.AutoScroll = $true
    $global:pnlContent.BackColor = "#f0f2f5"

    $form.Controls.AddRange(@($pnlSidebar, $pnlTopo, $global:pnlContent))

    $form.Add_Resize({
        try {
            $pnlSidebar.Height = $form.ClientSize.Height
            $pnlMenu.Height = $form.ClientSize.Height - 80
            $pnlTopo.Width = $form.ClientSize.Width - 230
            $global:pnlContent.Size = New-Object System.Drawing.Size(($form.ClientSize.Width - 240), ($form.ClientSize.Height - 60))
            $lblData.Location = New-Object System.Drawing.Point(($pnlTopo.Width - 280), 15)
            $btnFechar.Location = New-Object System.Drawing.Point(($pnlTopo.Width - 75), 10)
        } catch {}
    })

    $form
}

$global:form = New-SistemaForm
Set-Modulo "dashboard"

# Startup alert: check-in de hoje e reservas pendentes
try {
    $dadosRes = Get-DadosReservas
    $hoje = (Get-Date).Date
    if ($dadosRes -and $dadosRes.reservas) {
        $checkinHoje = @($dadosRes.reservas | Where-Object {
            $_.data_checkin -and $_.status -ne "cancelada" -and $_.status -ne "finalizada" -and
            $(try { (Get-Date $_.data_checkin).Date -eq $hoje } catch { $false })
        })
        $pendentes = @($dadosRes.reservas | Where-Object { $_.status -eq "reservado" -or $_.status -eq "pendente" })
        $msg = @()
        if ($checkinHoje.Count -gt 0) {
            $msg += "Check-in HOJE ($($checkinHoje.Count) hóspede$(if($checkinHoje.Count -ne 1){'s'})):"
            foreach ($r in $checkinHoje) {
                $hosp = if ($r.hospede_nome) { $r.hospede_nome } else { "N/I" }
                $quarto = if ($r.quarto) { $r.quarto } else { "N/I" }
                $msg += "  - $hosp (Quarto $quarto)"
            }
            $msg += ""
        }
        if ($pendentes.Count -gt 0) {
            $msg += "Reservas pendentes ($($pendentes.Count)):"
            foreach ($r in $pendentes) {
                $hosp = if ($r.hospede_nome) { $r.hospede_nome } else { "N/I" }
                $quarto = if ($r.quarto) { $r.quarto } else { "N/I" }
                $entrada = if ($r.data_checkin) { $r.data_checkin } else { "N/I" }
                $msg += "  - $hosp (Q: $quarto, Entrada: $entrada)"
            }
            $msg += ""
        }
        if ($msg.Count -gt 0) {
            $msg += "Acesse o módulo Reservas para mais detalhes."
            $form.Add_Shown({
                [System.Windows.Forms.MessageBox]::Show(
                    ($msg -join "`n"),
                    "Resumo do Dia - $(Get-Date -Format 'dd/MM/yyyy')",
                    "OK",
                    "Information"
                )
            }.GetNewClosure())
        }
    }
} catch { }

# Auto-import from active channels on startup
try {
    $cfgAI = Get-DadosConfig
    if ($cfgAI -and $cfgAI.integracoes) {
        $canaisAuto = @()
        foreach ($kv in $cfgAI.integracoes.GetEnumerator()) {
            if ($kv.Key -in @("exportar_inventario_automatico","intervalo_sincronizacao_minutos","ultima_sincronizacao_global")) { continue }
            if ($kv.Value -and $kv.Value.ativo -and $kv.Value.auto_importar) {
                $canaisAuto += $kv.Key
            }
        }
        if ($canaisAuto.Count -gt 0) {
            $form.Add_Shown({
                $respAI = [System.Windows.Forms.MessageBox]::Show(
                    "Canais com importacao automatica ativa: $($canaisAuto -join ', ')`n`nDeseja importar reservas agora?",
                    "Importacao Automatica",
                    "YesNo",
                    "Question"
                )
                if ($respAI -eq "Yes") {
                    $resultAI = Importar-ReservasSimuladas -canaisParaImportar $canaisAuto
                    if ($resultAI.sucesso) {
                        [System.Windows.Forms.MessageBox]::Show($resultAI.mensagem, "Importacao Concluida")
                    }
                }
            }.GetNewClosure())
        }
    }
} catch { }

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($global:form)



