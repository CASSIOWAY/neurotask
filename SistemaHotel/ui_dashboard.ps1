param($pnl)

Limpar-Panel $pnl

$d = Get-DadosReservas
$q = Get-DadosQuartos
$h = Get-DadosHospedes
$f = Get-DadosFinanceiro

$totalQ = if ($q) { $q.quartos.Count } else { 0 }
$disp = @($q.quartos | Where-Object { $_.status -eq "disponivel" }).Count
$ocup = @($q.quartos | Where-Object { $_.status -eq "ocupado" }).Count
$resv = @($q.quartos | Where-Object { $_.status -eq "reservado" }).Count
$taxa = if ($totalQ -gt 0) { [math]::Round(($ocup + $resv) / $totalQ * 100, 1) } else { 0 }

$totalR = if ($d) { $d.reservas.Count } else { 0 }
$totalH = if ($h) { $h.hospedes.Count } else { 0 }

# Reservas de canais externos
. (Join-Path $PSScriptRoot "modules\integracoes.ps1")
$ext = Get-DadosIntegracoes
$totalExt = if ($ext -and $ext.reservas_externas) { $ext.reservas_externas.Count } else { 0 }
$totalGeral = $totalR + $totalExt

$mesAtual = (Get-Date -Format "yyyy-MM")
$lancF = if ($f) { $f.lancamentos | Where-Object { $_ -and $_.data -like "$mesAtual-*" } } else { @() }
$recMes = [math]::Round(($lancF | Where-Object { $_.tipo -eq "receita" } | Measure-Object -Property valor -Sum).Sum, 2)
$despMes = [math]::Round(($lancF | Where-Object { $_.tipo -eq "despesa" } | Measure-Object -Property valor -Sum).Sum, 2)
$saldoMes = [math]::Round($recMes - $despMes, 2)

$y = 15
$stats = @(
    @{ico="[Q]";val=$totalQ;lb="($disp disp.) Quartos";cr="#1565c0"},
    @{ico="[%]";val="$taxa%";lb="Taxa de Ocupação";cr="#2e7d32"},
    @{ico="[R]";val=$totalGeral;lb="Reservas ($totalExt externas)";cr="#e65100"},
    @{ico="[+]";val=FormatarMoeda($recMes);lb="Receita do Mês";cr="#00838f"},
    @{ico="[-]";val=FormatarMoeda($despMes);lb="Despesas do Mês";cr="#c62828"},
    @{ico="[S]";val=FormatarMoeda($saldoMes);lb="Saldo do Mês";cr="#6a1b9a"}
)
$xPos = 20
foreach ($s in $stats) {
    $cardW = [math]::Min(210, [math]::Max(160, [int]((($pnl.Width - 60) / $stats.Count))))
    $pnl.Controls.Add((Nova-StatCard $s.ico $s.val $s.lb $s.cr $xPos $y $cardW))
    $xPos += ($cardW + 12)
    if ($xPos + $cardW + 20 -gt $pnl.Width) { $xPos = 20; $y += 90 }
}

$y2 = $y + 100
$checkW = [math]::Min(500, [int](($pnl.Width - 60) * 0.48))
$pnlCheck = Nova-Card "Check-ins / Check-outs Hoje" 20 $y2 $checkW 100
$pnlCheck.Anchor = "Top, Left, Right"
$pnlCheckInner = New-Object System.Windows.Forms.Panel
$pnlCheckInner.Location = New-Object System.Drawing.Point(10, 45)
$pnlCheckInner.Size = New-Object System.Drawing.Size(($checkW - 40), 50)
$hoje = Get-Date -Format "yyyy-MM-dd"
$checkins = @($d.reservas | Where-Object { $_.data_checkin -eq $hoje -and $_.status -ne "cancelada" }).Count
$checkouts = @($d.reservas | Where-Object { $_.data_checkout -eq $hoje -and $_.status -ne "cancelada" }).Count

$lblCI = New-Object System.Windows.Forms.Label
$lblCI.Text = "Check-ins: $checkins"
$lblCI.Location = New-Object System.Drawing.Point(20, 5)
$lblCI.Size = New-Object System.Drawing.Size(200, 40)
$lblCI.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblCI.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#1565c0")

$lblCO = New-Object System.Windows.Forms.Label
$lblCO.Text = "Check-outs: $checkouts"
$lblCO.Location = New-Object System.Drawing.Point(250, 5)
$lblCO.Size = New-Object System.Drawing.Size(200, 40)
$lblCO.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblCO.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#e65100")

$pnlCheckInner.Controls.AddRange(@($lblCI, $lblCO))
$pnlCheck.Controls.Add($pnlCheckInner)
$pnl.Controls.Add($pnlCheck)

$pnlRecentes = Nova-Card "Reservas Recentes (Todas as fontes)" ($checkW + 30) $y2 ($pnl.Width - $checkW - 60) 300
$pnlRecentes.Anchor = "Top, Left, Right"
$gridRecentes = Nova-Table 10 45 ($pnl.Width - $checkW - 80) 240
$gridRecentes.Anchor = "Top, Left, Right, Bottom"
$gridRecentes.ColumnCount = 6
$gridRecentes.Columns[0].HeaderText = "Origem"; $gridRecentes.Columns[1].HeaderText = "Hóspede"
$gridRecentes.Columns[2].HeaderText = "Check-in"; $gridRecentes.Columns[3].HeaderText = "Noites"
$gridRecentes.Columns[4].HeaderText = "Valor"; $gridRecentes.Columns[5].HeaderText = "Status"

$todas = Get-ReservasUnificadas
if ($todas) {
    $recentes = $todas | Sort-Object data_checkin | Select-Object -First 6
    foreach ($r in $recentes) {
        $origem = if ($r.origem -eq "local") { "Interno" } else { $r.origem }
        $nome = if ($r.nome_hospede) { $r.nome_hospede } else { (Get-HospedeNome $r.id_hospede) }
        $gridRecentes.Rows.Add($origem, $nome, (FormatarData $r.data_checkin), $r.noites, $(FormatarMoeda $r.valor_total), $r.status)
    }
}
$pnlRecentes.Controls.Add($gridRecentes)
$pnl.Controls.Add($pnlRecentes)



