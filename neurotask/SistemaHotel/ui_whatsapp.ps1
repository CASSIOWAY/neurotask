param($pnl)

Limpar-Panel $pnl

$lblTitulo = Nova-RichLabel "Confirmação via WhatsApp" 20 15 400 30 -bold -size 16
$pnl.Controls.Add($lblTitulo)
$lblDesc = Nova-RichLabel "Envie confirmações de reserva automaticamente para os hóspedes" 20 48 500 20 -size 10 -color "#888"
$pnl.Controls.Add($lblDesc)

$lblManual = Nova-RichLabel "Envio Manual" 20 80 200 25 -bold -size 12
$pnl.Controls.Add($lblManual)

$inputY = 110
$lblReserva = Nova-RichLabel "Reserva #:" 20 $inputY 80 25 -size 10
$txtReserva = New-Object System.Windows.Forms.TextBox
$txtReserva.Location = New-Object System.Drawing.Point(100, $inputY); $txtReserva.Size = New-Object System.Drawing.Size(100, 25)
$lblTipo = Nova-RichLabel "Tipo:" 220 $inputY 50 25 -size 10
$cmbTipo = New-Object System.Windows.Forms.ComboBox
$cmbTipo.Location = New-Object System.Drawing.Point(260, $inputY); $cmbTipo.Size = New-Object System.Drawing.Size(145, 25)
$cmbTipo.DropDownStyle = "DropDownList"
$cmbTipo.FlatStyle = "Flat"
$cmbTipo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cmbTipo.Items.AddRange(@("Confirmação", "Lembrete"))
$cmbTipo.SelectedIndex = 0
$pnl.Controls.AddRange(@($lblReserva, $txtReserva, $lblTipo, $cmbTipo))

$btnEnviar = Nova-Botao " Enviar WhatsApp" 410 $inputY 160 32 "#25D366"
$btnEnviar.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$pnl.Controls.Add($btnEnviar)

$pendY = $inputY + 45
$lblPendentes = Nova-RichLabel "Pendentes de Envio" 20 $pendY 300 25 -bold -size 12
$pnl.Controls.Add($lblPendentes)

$gridY = $pendY + 30
$grid = Nova-Table 20 $gridY ($pnl.Width - 60) ($pnl.Height - $gridY - 30)
$grid.Anchor = "Top, Left, Right, Bottom"
$grid.ColumnCount = 5
$grid.Columns[0].HeaderText = "Reserva"; $grid.Columns[1].HeaderText = "Hóspede"
$grid.Columns[2].HeaderText = "Telefone"; $grid.Columns[3].HeaderText = "Check-in"
$grid.Columns[4].HeaderText = "Status"

$d = Get-DadosReservas
if ($d -and $d.reservas) {
    $pendentes = @($d.reservas | Where-Object { $_.whatsapp_enviado -eq $false -and $_.status -ne "cancelada" -and $_.status -ne "checkout" })
    foreach ($r in $pendentes) {
        $nome = Get-HospedeNome $r.id_hospede
        $tel = "N/A"
        $h = Get-DadosHospedes
        if ($h) { $nh = @($h.hospedes | Where-Object { $_.id -eq $r.id_hospede }); if ($nh) { $tel = $nh[0].telefone } }
        $grid.Rows.Add("#$($r.id)", $nome, $tel, (FormatarData $r.data_checkin), $r.status)
    }
}
$pnl.Controls.Add($grid)

$btnEnviar.Add_Click({
    $id = ($txtReserva.Text -as [int])
    if (-not $id) {     [System.Windows.Forms.MessageBox]::Show("Informe o número da reserva", "Erro"); return }

    $reservas = Get-DadosReservas; $hospedes = Get-DadosHospedes; $quartos = Get-DadosQuartos; $cfg = Get-DadosConfig
    $r = @($reservas.reservas | Where-Object { $_.id -eq $id })
    if (-not $r) { [System.Windows.Forms.MessageBox]::Show("Reserva não encontrada", "Erro"); return }
    $r = $r[0]
    $hp = @($hospedes.hospedes | Where-Object { $_.id -eq $r.id_hospede })
    $qr = @($quartos.quartos | Where-Object { $_.id -eq $r.id_quarto })
    if (-not $hp -or -not $qr) { [System.Windows.Forms.MessageBox]::Show("Dados incompletos", "Erro"); return }
    $hp = $hp[0]; $qr = $qr[0]

    $tel = $hp.telefone -replace '\D',''
    $msg = "Confirmação de Reserva #$($r.id)%0A%0A"
    $msg += "Ola, $($hp.nome)! Sua reserva foi confirmada!%0A%0A"
    $msg += "Check-in: $($r.data_checkin) (12:00)%0ACheck-out: $($r.data_checkout) (12:00)%0A"
    $msg += "Noites: $($r.noites) | Quarto: $($qr.numero)%0A"
    $msg += "Valor: R$ $([math]::Round($r.valor_total,2))%0A%0A"
    $msg += "WhatsApp: (99) 98121-9754"
    $url = "https://api.whatsapp.com/send?phone=55$tel&text=$msg"

    foreach ($rv in $reservas.reservas) { if ($rv.id -eq $id) { $rv.whatsapp_enviado = $true; break } }
    Save-Reservas $reservas

    [System.Windows.Forms.MessageBox]::Show("Mensagem preparada! Clique em OK para abrir o WhatsApp.", "Sucesso")
    Start-Process $url
    & (Join-Path $PSScriptRoot "ui_whatsapp.ps1") $pnl
})



