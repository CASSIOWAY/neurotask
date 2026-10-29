param($pnl)

Limpar-Panel $pnl

if (-not $pnl -or $pnl.Width -le 0 -or $pnl.Height -le 0) {
    $lblErr = New-Object System.Windows.Forms.Label
    $lblErr.Text = "Painel nao disponivel para renderizacao"
    $lblErr.TextAlign = "MiddleCenter"
    $lblErr.Size = New-Object System.Drawing.Size(400, 50)
    $lblErr.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40)
    $pnl.Controls.Add($lblErr) | Out-Null
    return
}

if (-not $global:uiDir) { $global:uiDir = $PSScriptRoot }
$uiDir = $global:uiDir

$feriadosFixos = @{
    "01-01" = "Confraternizacao Universal"
    "21-04" = "Tiradentes"
    "01-05" = "Dia do Trabalho"
    "07-09" = "Independencia"
    "12-10" = "Nossa Sra. Aparecida"
    "02-11" = "Finados"
    "15-11" = "Proclamacao da Republica"
    "20-11" = "Consciencia Negra"
    "25-12" = "Natal"
}
try {
    $a = (Get-Date).Year
    $g = $a % 19
    $d = (19 * $g + 24) % 30
    $e = (2 * ($a % 4) + 4 * ($a % 7) + 6 * $d + 5) % 7
    $dias = 22 + $d + $e
    if ($d -eq 29 -and $e -eq 6) { $dias -= 7 }
    if ($d -eq 28 -and $e -eq 6 -and $g -gt 10) { $dias -= 7 }
    if ($dias -le 31) { $pascoa = [DateTime]"$a-03-$($dias.ToString('00'))" }
    else { $pascoa = [DateTime]"$a-04-$(( $dias - 31 ).ToString('00'))" }
} catch { $pascoa = [DateTime]"$a-04-05" }
$feriadosMoveis = @{
    $pascoa.AddDays(-48).ToString("MM-dd") = "Carnaval"
    $pascoa.AddDays(-47).ToString("MM-dd") = "Carnaval"
    $pascoa.AddDays(-2).ToString("MM-dd") = "Sexta-Feira Santa"
    $pascoa.ToString("MM-dd") = "Pascoa"
    $pascoa.AddDays(60).ToString("MM-dd") = "Corpus Christi"
}
$feriados = @{}
foreach ($kv in $feriadosFixos.GetEnumerator()) { $feriados[$kv.Key] = $kv.Value }
foreach ($kv in $feriadosMoveis.GetEnumerator()) { $feriados[$kv.Key] = $kv.Value }

$d = Get-DadosReservas
$global:calDados = $d
$h = Get-DadosHospedes
if (-not $global:calMesOffset) { $global:calMesOffset = 0 }
$mesAtual = (Get-Date).AddMonths($global:calMesOffset)
$global:calMesAtual = $mesAtual
$primeiroDia = Get-Date "$($mesAtual.Year)-$($mesAtual.Month)-01"
$ultimoDia = $primeiroDia.AddMonths(1).AddDays(-1)
$diasNoMes = $ultimoDia.Day
$inicioSemana = [int]$primeiroDia.DayOfWeek
$diasSemana = @("Dom","Seg","Ter","Qua","Qui","Sex","Sab")
$hoje = (Get-Date).Day
$mesmoMesAtual = ($mesAtual.Month -eq (Get-Date).Month -and $mesAtual.Year -eq (Get-Date).Year)

if ($global:calShowBars -eq $null) { $global:calShowBars = $true }
$lblMes = Nova-RichLabel "$($mesAtual.ToString('MMMM/yyyy').ToUpper())" 20 15 400 30 -bold -size 16
$lblMes.Cursor = "Hand"
$lblMes.Add_Click({ $global:calShowBars = -not $global:calShowBars; & (Join-Path $global:uiDir "ui_calendario.ps1") $global:pnlContent })
$pnl.Controls.Add($lblMes)

$btnAnt = Nova-Botao " < Anterior" ($pnl.Width - 220) 15 110 28 "#1565c0" 9
$btnAnt.Anchor = "Top, Right"
$btnAnt.Add_Click({ $global:calMesOffset--; & (Join-Path $global:uiDir "ui_calendario.ps1") $global:pnlContent })
$pnl.Controls.Add($btnAnt)

$btnProx = Nova-Botao "Proximo > " ($pnl.Width - 105) 15 90 28 "#1565c0" 9
$btnProx.Anchor = "Top, Right"
$btnProx.Add_Click({ $global:calMesOffset++; & (Join-Path $global:uiDir "ui_calendario.ps1") $global:pnlContent })
$pnl.Controls.Add($btnProx)

$legY = 48
$legX = 20
$coresLegenda = @(
    @{cor="#2e7d32"; txt="Disponivel"}
    @{cor="#1565c0"; txt="Ocupado"}
    @{cor="#e65100"; txt="Reservado"}
    @{cor="#ff8f00"; txt="Manutencao"}
    @{cor="#c62828"; txt="Feriado"}
)
foreach ($leg in $coresLegenda) {
    $pnlCor = New-Object System.Windows.Forms.Panel
    $pnlCor.Size = New-Object System.Drawing.Size(12, 12)
    $pnlCor.Location = New-Object System.Drawing.Point($legX, ($legY + 2))
    $pnlCor.BackColor = [System.Drawing.ColorTranslator]::FromHtml($leg.cor)
    $pnl.Controls.Add($pnlCor)
    $pnl.Controls.Add((Nova-RichLabel $leg.txt ($legX + 16) $legY 100 16 -size 8 -color "#666"))
    $legX += 120
}

$colW = [math]::Max(80, [math]::Floor(($pnl.Width - 50) / 7))
$colGap = [math]::Max(2, [int]($colW * 0.04))
$cellW = $colW - $colGap
$cellH = [math]::Min(75, [math]::Max(50, [int](($pnl.Height - 240) / 6)))

$headerY = 68
$x = 20
foreach ($ds in $diasSemana) {
    $pnl.Controls.Add((Nova-RichLabel $ds $x $headerY $cellW 20 -bold -size 10 -color "#888"))
    $x += $colW
}

$reservasPorDia = @{}
$ocupacaoDia = @{}
if ($d -and $d.reservas) {
    foreach ($r in $d.reservas) {
        if ($r.status -eq "cancelada") { continue }
        $ci = if ($r.data_checkin) { try { [DateTime]$r.data_checkin } catch { $null } } else { $null }
        $co = if ($r.data_checkout) { try { [DateTime]$r.data_checkout } catch { $null } } else { $null }
        if (-not $ci -or -not $co) { continue }

        if ($ci.Month -eq $mesAtual.Month -and $ci.Year -eq $mesAtual.Year) {
            $chave = $ci.Day
            if (-not $reservasPorDia[$chave]) { $reservasPorDia[$chave] = @() }
            $hospNome = Get-HospedeNome $r.id_hospede
            $qNum = Get-QuartoNumero $r.id_quarto
            $reservasPorDia[$chave] += @{quarto=$qNum; hospede=$hospNome; status=$r.status; id=$r.id; checkin=$r.data_checkin; checkout=$r.data_checkout}
        }

        $diaIni = if ($ci.Month -eq $mesAtual.Month -and $ci.Year -eq $mesAtual.Year) { $ci.Day } else { 1 }
        $diaFim = if ($co.Month -eq $mesAtual.Month -and $co.Year -eq $mesAtual.Year) { $co.Day } else { $diasNoMes }
        for ($d = $diaIni; $d -le $diaFim; $d++) {
            if (-not $ocupacaoDia[$d]) { $ocupacaoDia[$d] = @() }
            $ocupacaoDia[$d] += $r
        }
    }
}

$y = $headerY + 24
$dia = 1
for ($l = 0; $l -lt 6; $l++) {
    for ($c = 0; $c -lt 7; $c++) {
        if (($l -eq 0 -and $c -lt $inicioSemana) -or $dia -gt $diasNoMes) {
        } else {
            $bx = 20 + ($c * $colW)
            $by = $y

            $pnlDia = New-Object System.Windows.Forms.Panel
            $pnlDia.Location = New-Object System.Drawing.Point($bx, $by)
            $pnlDia.Size = New-Object System.Drawing.Size($cellW, $cellH)
            $pnlDia.BorderStyle = "FixedSingle"
            $pnlDia.Tag = $dia

            $ehFeriado = $feriados["$($mesAtual.Month.ToString('00'))-$($dia.ToString('00'))"]

            $statusCorDia = "disponivel"
            if ($ehFeriado) {
                $statusCorDia = "feriado"
            } else {
                $ocup = $ocupacaoDia[$dia]
                if ($ocup) {
                    foreach ($ro in $ocup) {
                        if ($ro.status -eq "checkin" -or $ro.status -eq "ocupado") { $statusCorDia = "ocupado"; break }
                        if ($ro.status -eq "reservado" -or $ro.status -eq "confirmada" -or $ro.status -eq "pendente") { $statusCorDia = "reservado" }
                        if ($ro.status -eq "limpeza") { if ($statusCorDia -eq "disponivel") { $statusCorDia = "manutencao" } }
                    }
                }
            }
            $mapaCoresFundo = @{
                "disponivel" = "#e8f5e9"
                "ocupado"    = "#bbdefb"
                "reservado"  = "#fff3e0"
                "manutencao" = "#fff8e1"
                "feriado"    = "#ffebee"
            }
            $hojeCor = if ($mesmoMesAtual -and $dia -eq $hoje) { [System.Drawing.ColorTranslator]::FromHtml("#e3f2fd") } else { [System.Drawing.ColorTranslator]::FromHtml($mapaCoresFundo[$statusCorDia]) }
            $pnlDia.BackColor = $hojeCor

            $lblNum = New-Object System.Windows.Forms.Label
            $lblNum.Text = "$dia"
            $lblNum.Location = New-Object System.Drawing.Point(3, 2)
            $lblNum.Size = New-Object System.Drawing.Size(28, 20)
            $lblNum.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $lblNum.ForeColor = if ($ehFeriado) { [System.Drawing.Color]::FromArgb(198, 40, 40) } elseif ($mesmoMesAtual -and $dia -eq $hoje) { [System.Drawing.Color]::FromArgb(21, 101, 192) } else { [System.Drawing.Color]::FromArgb(51, 51, 51) }
            $lblNum.BackColor = [System.Drawing.Color]::Transparent
            $lblNum.TextAlign = "MiddleCenter"
            $pnlDia.Controls.Add($lblNum)

            if ($ehFeriado) {
                $lblFer = New-Object System.Windows.Forms.Label
                $lblFer.Text = $ehFeriado
                $lblFer.Location = New-Object System.Drawing.Point(30, 3)
                $lblFer.Size = New-Object System.Drawing.Size(($cellW - 34), 16)
                $lblFer.Font = New-Object System.Drawing.Font("Segoe UI", 6, [System.Drawing.FontStyle]::Bold)
                $lblFer.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#c62828")
                $lblFer.TextAlign = "MiddleLeft"
                $pnlDia.Controls.Add($lblFer)
            }

            $ocup = $ocupacaoDia[$dia]
            if ($ocup) {
                $totalOcup = $ocup.Count
                $yd = 24
                if ($global:calShowBars) {
                    $barColors = @{checkin="#2e7d32"; ocupado="#1565c0"; reservado="#e65100"; pendente="#757575"; confirmada="#2e7d32"; limpeza="#ff8f00"}
                    $statusCores = @()
                    foreach ($ro in $ocup) {
                        $cor = $barColors[$ro.status]
                        if (-not $cor) { $cor = "#757575" }
                        if ($statusCores -notcontains $cor) { $statusCores += $cor }
                    }

                    if ($statusCores.Count -eq 1) {
                        $bar = New-Object System.Windows.Forms.Panel
                        $bar.Location = New-Object System.Drawing.Point(2, $yd)
                        $bar.Size = New-Object System.Drawing.Size(($cellW - 4), 6)
                        $bar.BackColor = [System.Drawing.ColorTranslator]::FromHtml($statusCores[0])
                        $pnlDia.Controls.Add($bar)
                        $yd += 10
                    } else {
                        $segW = [math]::Max(4, [int](($cellW - 4) / $statusCores.Count))
                        $sx = 2
                        foreach ($sc in $statusCores) {
                            $bar = New-Object System.Windows.Forms.Panel
                            $bar.Location = New-Object System.Drawing.Point($sx, $yd)
                            $bar.Size = New-Object System.Drawing.Size($segW, 6)
                            $bar.BackColor = [System.Drawing.ColorTranslator]::FromHtml($sc)
                            $pnlDia.Controls.Add($bar)
                            $sx += $segW
                        }
                        $yd += 10
                    }
                }

                $lblOcup = New-Object System.Windows.Forms.Label
                $lblOcup.Text = "$totalOcup quarto(s)"
                $lblOcup.Location = New-Object System.Drawing.Point(3, $yd)
                $lblOcup.Size = New-Object System.Drawing.Size(($cellW - 6), 16)
                $lblOcup.Font = New-Object System.Drawing.Font("Segoe UI", 7)
                $lblOcup.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#555")
                $pnlDia.Controls.Add($lblOcup)
                $yd += 15

                $eventos = $reservasPorDia[$dia]
                if ($eventos) {
                    $maxEv = 2
                    $evMostrados = 0
                    foreach ($ev in $eventos) {
                        if ($evMostrados -ge $maxEv) { break }
                        $lblEv = New-Object System.Windows.Forms.Label
                        $lblEv.Text = "$($ev.quarto): $($ev.hospede)"
                        $lblEv.Location = New-Object System.Drawing.Point(3, $yd)
                        $lblEv.Size = New-Object System.Drawing.Size(($cellW - 6), 15)
                        $lblEv.Font = New-Object System.Drawing.Font("Segoe UI", 6)
                        $lblEv.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($barColors[$ev.status])
                        $pnlDia.Controls.Add($lblEv)
                        $yd += 15
                        $evMostrados++
                    }
                    if ($eventos.Count -gt $maxEv) {
                        $pnlDia.Controls.Add((Nova-RichLabel "+$($eventos.Count - $maxEv) mais" 3 $yd ($cellW - 6) 14 -size 6 -color "#c62828"))
                    }
                }
            } else {
                $lblVazio = New-Object System.Windows.Forms.Label
                $lblVazio.Text = "Disponivel"
                $lblVazio.Location = New-Object System.Drawing.Point(3, 24)
                $lblVazio.Size = New-Object System.Drawing.Size(($cellW - 6), 16)
                $lblVazio.Font = New-Object System.Drawing.Font("Segoe UI", 7)
                $lblVazio.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#aaa")
                $pnlDia.Controls.Add($lblVazio)
            }

            $diaData = "$($mesAtual.Year)-$($mesAtual.Month.ToString('00'))-$($dia.ToString('00'))"
            $dayClickHandler = {
                try {
                    $dd = $this.Tag
                    if (-not $dd) { return }
                    $ma = $global:calMesAtual
                    if (-not $ma) { return }
                    $dataStr = "$($ma.Year)-$($ma.Month.ToString('00'))-$($dd.ToString('00'))"
                    $dataExib = "$($dd.ToString('00'))/$($ma.Month.ToString('00'))/$($ma.Year)"

                    $formDia = New-Object System.Windows.Forms.Form
                    $formDia.Text = "Reservas - $dataExib"
                    $formDia.Size = New-Object System.Drawing.Size(520, 500)
                    $formDia.StartPosition = "CenterParent"
                    $formDia.FormBorderStyle = "FixedDialog"
                    $formDia.MaximizeBox = $false

                    $formDia.Controls.Add((Nova-RichLabel "Reservas para $dataExib" 15 15 400 25 -bold -size 14))

                    $gridDia = Nova-Table 15 45 475 160
                    $gridDia.ColumnCount = 5
                    $gridDia.Columns[0].HeaderText = "Hospede"; $gridDia.Columns[1].HeaderText = "Quarto"
                    $gridDia.Columns[2].HeaderText = "Check-out"; $gridDia.Columns[3].HeaderText = "Status"
                    $gridDia.Columns[4].HeaderText = "Valor"

                    $calD = $global:calDados
                    $resDia = @()
                    if ($calD -and $calD.reservas) {
                        $resDia = @($calD.reservas | Where-Object {
                            $_.status -ne "cancelada" -and
                            $_.data_checkin -le $dataStr -and
                            $_.data_checkout -gt $dataStr
                        })
                    }
                foreach ($rd in $resDia) {
                    $hN = Get-HospedeNome $rd.id_hospede
                    $qN = Get-QuartoNumero $rd.id_quarto
                    $idx = $gridDia.Rows.Add($hN, $qN, $(FormatarData $rd.data_checkout), $rd.status, $(FormatarMoeda $rd.valor_total))
                    $gridDia.Rows[$idx].Tag = $rd
                }
                if ($resDia.Count -eq 0) {
                    $gridDia.Rows.Add("Nenhuma reserva para esta data", "", "", "", "")
                }

                $gridDia.Add_CellDoubleClick({ $menuEditar.PerformClick() })
                $cmsDia = New-Object System.Windows.Forms.ContextMenuStrip
                $menuEditar = New-Object System.Windows.Forms.ToolStripMenuItem("Editar Reserva")
                $menuCancelar = New-Object System.Windows.Forms.ToolStripMenuItem("Cancelar Reserva")
                $menuCancelar.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40)
                $menuCliDia = New-Object System.Windows.Forms.ToolStripMenuItem("Cadastrar Cliente")
                $menuCliDia.ForeColor = [System.Drawing.Color]::FromArgb(46, 125, 50)
                $cmsDia.Items.AddRange(@($menuEditar, $menuCancelar, $menuCliDia))
                $gridDia.ContextMenuStrip = $cmsDia

                $menuEditar.Add_Click({
                    if ($gridDia.SelectedRows.Count -eq 0) { return }
                    $rd = $gridDia.SelectedRows[0].Tag
                    if (-not $rd) { return }
                    $formEdit = New-Object System.Windows.Forms.Form
                    $formEdit.Text = "Editar Reserva #$($rd.id)"
                    $formEdit.Size = New-Object System.Drawing.Size(520, 450)
                    $formEdit.StartPosition = "CenterParent"
                    $formEdit.FormBorderStyle = "FixedDialog"
                    $formEdit.MaximizeBox = $false; $formEdit.MinimizeBox = $false
                    $yf = 15
                    $formEdit.Controls.Add((Nova-RichLabel "Hospede:" 15 $yf 110 25 -bold))
                    $lblNome = Nova-RichLabel (Get-HospedeNome $rd.id_hospede) 135 $yf 360 25 -size 11 -color "#1565c0"
                    $formEdit.Controls.Add($lblNome)
                    $yf = 50
                    $formEdit.Controls.Add((Nova-RichLabel "Status:" 15 $yf 110 25 -bold))
                    $cmbStatus = New-Object System.Windows.Forms.ComboBox
                    $cmbStatus.Location = New-Object System.Drawing.Point(135, $yf); $cmbStatus.Size = New-Object System.Drawing.Size(150, 25)
                    $cmbStatus.DropDownStyle = "DropDownList"
                    "pendente","confirmada","em_andamento","finalizada","cancelada" | ForEach-Object { $cmbStatus.Items.Add($_); if ($_ -eq $rd.status) { $cmbStatus.SelectedItem = $_ } }
                    $formEdit.Controls.Add($cmbStatus)
                    $yf = 85
                    $formEdit.Controls.Add((Nova-RichLabel "Quarto:" 15 $yf 110 25 -bold))
                    $cmbQEdit = New-Object System.Windows.Forms.ComboBox
                    $cmbQEdit.Location = New-Object System.Drawing.Point(135, $yf); $cmbQEdit.Size = New-Object System.Drawing.Size(360, 25)
                    $cmbQEdit.DropDownStyle = "DropDownList"
                    $cmbQEdit.Items.AddRange(@("01","02","03","04","05","06"))
                    $cmbQEdit.SelectedIndex = [math]::Max(0, [int]$rd.id_quarto - 1)
                    $formEdit.Controls.Add($cmbQEdit)
                    $yf = 120
                    $formEdit.Controls.Add((Nova-RichLabel "Check-out:" 15 $yf 110 25 -bold))
                    $dtCOEdit = New-Object System.Windows.Forms.DateTimePicker
                    $dtCOEdit.Location = New-Object System.Drawing.Point(135, $yf); $dtCOEdit.Size = New-Object System.Drawing.Size(150, 25)
                    $dtCOEdit.Format = "Short"
                    try { $dtCOEdit.Value = [DateTime]$rd.data_checkout } catch {}
                    $formEdit.Controls.Add($dtCOEdit)
                    $yf = 155
                    $formEdit.Controls.Add((Nova-RichLabel "Valor Total:" 15 $yf 110 25 -bold))
                    $txtValorEdit = New-Object System.Windows.Forms.TextBox
                    $txtValorEdit.Location = New-Object System.Drawing.Point(135, $yf); $txtValorEdit.Size = New-Object System.Drawing.Size(120, 25)
                    $txtValorEdit.Text = $rd.valor_total
                    $formEdit.Controls.Add($txtValorEdit)
                    $formEdit.Controls.Add((Nova-RichLabel "Desconto:" 280 $yf 80 25))
                    $txtDescEdit = New-Object System.Windows.Forms.TextBox
                    $txtDescEdit.Location = New-Object System.Drawing.Point(360, $yf); $txtDescEdit.Size = New-Object System.Drawing.Size(80, 25)
                    $txtDescEdit.Text = $rd.desconto
                    $formEdit.Controls.Add($txtDescEdit)
                    $yf = 190
                    $formEdit.Controls.Add((Nova-RichLabel "Pagamento:" 15 $yf 100 25))
                    $cmbPagEdit = New-Object System.Windows.Forms.ComboBox
                    $cmbPagEdit.Location = New-Object System.Drawing.Point(120, $yf); $cmbPagEdit.Size = New-Object System.Drawing.Size(150, 25)
                    $cmbPagEdit.DropDownStyle = "DropDownList"
                    "credito","debito","pix","dinheiro","boleto" | ForEach-Object { $cmbPagEdit.Items.Add($_); if ($_ -eq $rd.metodo_pagamento) { $cmbPagEdit.SelectedItem = $_ } }
                    $formEdit.Controls.Add((Nova-RichLabel "Canal:" 290 $yf 100 25))
                    $cmbCanalEdit = New-Object System.Windows.Forms.ComboBox
                    $cmbCanalEdit.Location = New-Object System.Drawing.Point(370, $yf); $cmbCanalEdit.Size = New-Object System.Drawing.Size(145, 25)
                    $cmbCanalEdit.DropDownStyle = "DropDownList"
                    $cmbCanalEdit.FlatStyle = "Flat"
                    $cmbCanalEdit.Font = New-Object System.Drawing.Font("Segoe UI", 9)
                    "direto","booking","expedia","airbnb" | ForEach-Object { $cmbCanalEdit.Items.Add($_); if ($_ -eq $rd.canal) { $cmbCanalEdit.SelectedItem = $_ } }
                    $formEdit.Controls.AddRange(@($cmbPagEdit, $cmbCanalEdit))
                    $yf = 230
                    $formEdit.Controls.Add((Nova-RichLabel "Observacoes:" 15 $yf 100 25))
                    $txtObsEdit = New-Object System.Windows.Forms.TextBox
                    $txtObsEdit.Location = New-Object System.Drawing.Point(120, $yf); $txtObsEdit.Size = New-Object System.Drawing.Size(375, 55)
                    $txtObsEdit.Multiline = $true; $txtObsEdit.Text = $rd.observacoes
                    $formEdit.Controls.Add($txtObsEdit)
                    $yf = 310
                    $btnSalvarEdit = Nova-Botao "Salvar Alteracoes" 100 $yf 170 35 "#1565c0"
                    $btnCancelarEdit = Nova-Botao "Cancelar" 290 $yf 120 35 "#757575"
                    $formEdit.Controls.AddRange(@($btnSalvarEdit, $btnCancelarEdit))
                    $btnCancelarEdit.Add_Click({ $formEdit.Close() })
                    $btnSalvarEdit.Add_Click({
                        $data2 = Get-DadosReservas
                        $alvo = @($data2.reservas | Where-Object { $_.id -eq $rd.id })
                        if (-not $alvo) { [System.Windows.Forms.MessageBox]::Show("Reserva nao encontrada", "Erro"); return }
                        $r2 = $alvo[0]
                        $novaQ = [int]$cmbQEdit.SelectedItem
                        $novoCO = $dtCOEdit.Value.ToString("yyyy-MM-dd")

                        $conflitos = Verificar-DisponibilidadeQuarto $novaQ $r2.data_checkin $novoCO -excluirReservaId $r2.id
                        if ($conflitos.Count -gt 0) {
                            $msg = "Quarto $novaQ ja esta ocupado neste periodo!`n`nConflitos:"
                            foreach ($cf in $conflitos) { $msg += "`n  - #$($cf.id): $(Get-HospedeNome $cf.id_hospede)" }
                            $msg += "`n`nContinuar?"
                            if (([System.Windows.Forms.MessageBox]::Show($msg, "Conflito", "YesNo", "Warning")) -eq "No") { return }
                        }

                        $r2.status = $cmbStatus.Text
                        $r2.id_quarto = $novaQ
                        $r2.data_checkout = $novoCO
                        $r2.noites = ($dtCOEdit.Value - [DateTime]$r2.data_checkin).Days
                        try { $r2.valor_total = [math]::Round([double]($txtValorEdit.Text -replace '[^0-9.,]','' -replace ',','.'), 2) } catch { $r2.valor_total = 0 }
                        try { $r2.desconto = [math]::Round([double]($txtDescEdit.Text -replace '[^0-9.,]','' -replace ',','.'), 2) } catch { $r2.desconto = 0 }
                        $r2.metodo_pagamento = $cmbPagEdit.Text
                        $r2.canal = $cmbCanalEdit.Text
                        $r2.observacoes = $txtObsEdit.Text
                        Save-Reservas $data2
                        $formEdit.Close()
                        [System.Windows.Forms.MessageBox]::Show("Reserva #$($rd.id) atualizada!", "Sucesso")
                        try { Confirmar-AtualizarCanais "atualizacao de reserva" "Reserva #$($rd.id) - Dados alterados no calendario" } catch { }
                        & $RefreshDia
                    })
                    $formEdit.ShowDialog()
                })
                $menuCancelar.Add_Click({
                    if ($gridDia.SelectedRows.Count -eq 0) { return }
                    $rd = $gridDia.SelectedRows[0].Tag
                    if (-not $rd) { return }
                    $resp = [System.Windows.Forms.MessageBox]::Show("Cancelar reserva #$($rd.id) de $(Get-HospedeNome $rd.id_hospede)?", "Confirmar Cancelamento", "YesNo", "Warning")
                    if ($resp -eq "Yes") {
                        $data2 = Get-DadosReservas
                        $alvo = @($data2.reservas | Where-Object { $_.id -eq $rd.id })
                        if ($alvo) { $alvo[0].status = "cancelada"; Save-Reservas $data2 }
                        & $RefreshDia
                    }
                })
                $menuCliDia.Add_Click({
                    $formCli = New-Object System.Windows.Forms.Form
                    $formCli.Text = "Novo Cliente"
                    $formCli.Size = New-Object System.Drawing.Size(420, 320)
                    $formCli.StartPosition = "CenterParent"
                    $formCli.FormBorderStyle = "FixedDialog"
                    $formCli.MaximizeBox = $false; $formCli.MinimizeBox = $false
                    $yC = 20
                    $formCli.Controls.Add((Nova-RichLabel "Nome:" 20 $yC 80 25 -bold))
                    $txtNomeC = New-Object System.Windows.Forms.TextBox
                    $txtNomeC.Location = New-Object System.Drawing.Point(110, $yC); $txtNomeC.Size = New-Object System.Drawing.Size(280, 25)
                    $formCli.Controls.Add($txtNomeC)
                    $yC = 60
                    $formCli.Controls.Add((Nova-RichLabel "Telefone:" 20 $yC 80 25 -bold))
                    $txtTelC = New-Object System.Windows.Forms.TextBox
                    $txtTelC.Location = New-Object System.Drawing.Point(110, $yC); $txtTelC.Size = New-Object System.Drawing.Size(160, 25)
                    $formCli.Controls.Add($txtTelC)
                    $formCli.Controls.Add((Nova-RichLabel "Email:" 290 $yC 60 25))
                    $txtEmailC = New-Object System.Windows.Forms.TextBox
                    $txtEmailC.Location = New-Object System.Drawing.Point(345, $yC); $txtEmailC.Size = New-Object System.Drawing.Size(45, 25)
                    $formCli.Controls.Add($txtEmailC)
                    $yC = 100
                    $formCli.Controls.Add((Nova-RichLabel "Obs:" 20 $yC 80 25))
                    $txtObsC = New-Object System.Windows.Forms.TextBox
                    $txtObsC.Location = New-Object System.Drawing.Point(110, $yC); $txtObsC.Size = New-Object System.Drawing.Size(280, 80)
                    $txtObsC.Multiline = $true
                    $formCli.Controls.Add($txtObsC)
                    $yC = 200
                    $btnSalvarCo = Nova-Botao "Salvar" 100 $yC 120 35 "#1565c0"
                    $btnCancCo = Nova-Botao "Cancelar" 240 $yC 120 35 "#757575"
                    $formCli.Controls.AddRange(@($btnSalvarCo, $btnCancCo))
                    $btnCancCo.Add_Click({ $formCli.Close() })
                    $btnSalvarCo.Add_Click({
                        $nCo = $txtNomeC.Text.Trim()
                        if (-not $nCo) { [System.Windows.Forms.MessageBox]::Show("Informe o nome", "Erro"); return }
                        $cliData = Get-DadosClientes
                        if (-not $cliData) { $cliData = @{clientes = @()} }
                        $ultIdCo = if ($cliData.clientes.Count -gt 0) { ($cliData.clientes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
                        $novoCli = [PSCustomObject]@{
                            id = $ultIdCo + 1; nome = $nCo; telefone = $txtTelC.Text.Trim()
                            email = $txtEmailC.Text.Trim(); data_cadastro = (Get-Date -Format "yyyy-MM-dd")
                            observacoes = $txtObsC.Text; ativo = $true; whatsapp_opt_in = ($txtTelC.Text.Trim().Length -gt 0)
                        }
                        $cliData.clientes += $novoCli
                        Save-Clientes $cliData
                        $formCli.Close()
                        [System.Windows.Forms.MessageBox]::Show("Cliente #$($ultIdCo + 1) cadastrado!", "Sucesso")
                    })
                    $formCli.ShowDialog()
                })
                $limpezaData = Get-DadosLimpeza
                $limpDia = @()
                if ($limpezaData -and $limpezaData.limpezas) {
                    $limpDia = @($limpezaData.limpezas | Where-Object { $_.data -eq $dataStr -and $_.status -ne "finalizada" })
                }
                $lblLimpeza = Nova-RichLabel "Limpeza agendada:" 15 215 200 20 -bold -size 10
                $formDia.Controls.Add($lblLimpeza)
                $gridLimp = Nova-Table 15 235 475 60
                $gridLimp.ColumnCount = 4
                $gridLimp.Columns[0].HeaderText = "Horario"; $gridLimp.Columns[1].HeaderText = "Quarto"
                $gridLimp.Columns[2].HeaderText = "Obs"; $gridLimp.Columns[3].HeaderText = "Status"
                if ($limpDia.Count -gt 0) {
                    foreach ($lp in $limpDia) {
                        $qNumL = Get-QuartoNumero $lp.id_quarto
                        $gridLimp.Rows.Add($lp.horario, $qNumL, $lp.observacoes, $lp.status)
                    }
                } else {
                    $gridLimp.Rows.Add("-", "Nenhuma limpeza agendada", "", "")
                }
                $formDia.Controls.Add($gridLimp)
                $formDia.Controls.Add($gridDia)

                $RefreshDia = {
                    $calD = Get-DadosReservas
                    $novosDia = @($calD.reservas | Where-Object {
                        $_.status -ne "cancelada" -and
                        $_.data_checkin -le $dataStr -and
                        $_.data_checkout -gt $dataStr
                    })
                    $gridDia.Rows.Clear()
                    $gridDia.SuspendLayout()
                    if ($novosDia.Count -eq 0) {
                        $gridDia.Rows.Add("Nenhuma reserva para esta data", "", "", "", "")
                    } else {
                        foreach ($rd in $novosDia) {
                            $hN = Get-HospedeNome $rd.id_hospede
                            $qN = Get-QuartoNumero $rd.id_quarto
                            $idx = $gridDia.Rows.Add($hN, $qN, (FormatarData $rd.data_checkout), $rd.status, (FormatarMoeda $rd.valor_total))
                            $gridDia.Rows[$idx].Tag = $rd
                        }
                    }
                    $gridDia.ResumeLayout()
                    $limpezaRefresh = Get-DadosLimpeza
                    $limpRefresh = @()
                    if ($limpezaRefresh -and $limpezaRefresh.limpezas) {
                        $limpRefresh = @($limpezaRefresh.limpezas | Where-Object { $_.data -eq $dataStr -and $_.status -ne "finalizada" })
                    }
                    $gridLimp.Rows.Clear()
                    $gridLimp.SuspendLayout()
                    if ($limpRefresh.Count -gt 0) {
                        foreach ($lp in $limpRefresh) {
                            $gridLimp.Rows.Add($lp.horario, (Get-QuartoNumero $lp.id_quarto), $lp.observacoes, $lp.status)
                        }
                    } else { $gridLimp.Rows.Add("-", "Nenhuma limpeza agendada", "", "") }
                    $gridLimp.ResumeLayout()
                }

                $btnNovaData = Nova-Botao "Nova Reserva p/ $dataExib" 15 310 230 35 "#2e7d32" 9
                $btnNovaData.Add_Click({
                    $formNova = New-Object System.Windows.Forms.Form
                    $formNova.Text = "Nova Reserva - $dataExib"
                    $formNova.Size = New-Object System.Drawing.Size(520, 480)
                    $formNova.StartPosition = "CenterParent"
                    $formNova.FormBorderStyle = "FixedDialog"
                    $formNova.MaximizeBox = $false; $formNova.MinimizeBox = $false

                    $yf = 15
                    $formNova.Controls.Add((Nova-RichLabel "Nome do Hóspede:" 15 $yf 130 25 -bold))
                    $txtNome = New-Object System.Windows.Forms.TextBox
                    $txtNome.Location = New-Object System.Drawing.Point(150, $yf); $txtNome.Size = New-Object System.Drawing.Size(345, 25)
                    $formNova.Controls.Add($txtNome)

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
                    $formNova.Controls.Add((Nova-RichLabel "Check-out:" 15 $yf 110 25 -bold))
                    $dtCO = New-Object System.Windows.Forms.DateTimePicker
                    $dtCO.Location = New-Object System.Drawing.Point(135, $yf); $dtCO.Size = New-Object System.Drawing.Size(150, 25)
                    $dtCO.Format = "Short"
                    $formNova.Controls.Add($dtCO)

                    $yf = 210
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
                    $cmbCanal.Font = New-Object System.Drawing.Font("Segoe UI", 9)
                    "direto","booking","expedia","airbnb" | ForEach-Object { $cmbCanal.Items.Add($_) }
                    $cmbCanal.SelectedIndex = 0
                    $formNova.Controls.AddRange(@($cmbPag, $cmbCanal))

                    $yf = 250
                    $formNova.Controls.Add((Nova-RichLabel "Observações:" 15 $yf 100 25))
                    $txtObs = New-Object System.Windows.Forms.TextBox
                    $txtObs.Location = New-Object System.Drawing.Point(120, $yf); $txtObs.Size = New-Object System.Drawing.Size(375, 55)
                    $txtObs.Multiline = $true
                    $formNova.Controls.Add($txtObs)

                    $yf = 320
                    $chkCliente = New-Object System.Windows.Forms.CheckBox
                    $chkCliente.Text = "Salvar também como cliente (campanhas WhatsApp)"
                    $chkCliente.Location = New-Object System.Drawing.Point(25, $yf)
                    $chkCliente.Size = New-Object System.Drawing.Size(470, 25)
                    $chkCliente.Checked = $false
                    $formNova.Controls.Add($chkCliente)

                    $yf = 360
                    $btnSalvar = Nova-Botao "Salvar Reserva" 140 $yf 190 35 "#1565c0"
                    $btnCancelar = Nova-Botao "Cancelar" 345 $yf 130 35 "#757575"
                    $formNova.Controls.AddRange(@($btnSalvar, $btnCancelar))
                    $btnCancelar.Add_Click({ $formNova.Close() })
                    $btnSalvar.Add_Click({
                        $nomeHosp = $txtNome.Text.Trim()
                        if (-not $nomeHosp) { [System.Windows.Forms.MessageBox]::Show("Informe o nome do hospede", "Erro"); return }
                        if ($cmbQ.SelectedIndex -lt 0) { [System.Windows.Forms.MessageBox]::Show("Selecione um quarto", "Erro"); return }
                        if ($dtCO.Value -le (Get-Date $dataStr)) { [System.Windows.Forms.MessageBox]::Show("Check-out deve ser apos check-in", "Erro"); return }

                        $qId = [int]$cmbQ.SelectedItem
                        $noites = ($dtCO.Value - (Get-Date $dataStr)).Days

                        $conflitos = Verificar-DisponibilidadeQuarto $qId $dataStr ($dtCO.Value.ToString("yyyy-MM-dd"))
                        if ($conflitos.Count -gt 0) {
                            $msg = "Quarto $qId ja esta ocupado neste periodo!`n`nConflitos:"
                            foreach ($cf in $conflitos) { $msg += "`n  - #$($cf.id): $(Get-HospedeNome $cf.id_hospede)" }
                            $msg += "`n`nContinuar?"
                            if (([System.Windows.Forms.MessageBox]::Show($msg, "Conflito", "YesNo", "Warning")) -eq "No") { return }
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
                            telefone = $txtTel.Text.Trim(); email = $txtEmail.Text.Trim(); endereco = ""
                            nacionalidade = "Brasileira"; data_cadastro = (Get-Date -Format "yyyy-MM-dd")
                            observacoes = ""; total_visitas = 1; total_gasto = [math]::Round($total, 2)
                        }
                        $hosp.hospedes += $novoHosp
                        Save-Hospedes $hosp

                        if ($chkCliente.Checked) {
                            $cli = Get-DadosClientes
                            if (-not $cli) { $cli = @{clientes = @()} }
                            $ultimoIdC = if ($cli.clientes.Count -gt 0) { ($cli.clientes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
                            $novoCli = [PSCustomObject]@{
                                id = $ultimoIdC + 1; nome = $nomeHosp; telefone = $txtTel.Text.Trim()
                                email = $txtEmail.Text.Trim(); data_cadastro = (Get-Date -Format "yyyy-MM-dd")
                                observacoes = "Cadastro via calendário"; ativo = $true
                                whatsapp_opt_in = ($txtTel.Text.Trim().Length -gt 0)
                            }
                            $cli.clientes += $novoCli
                            Save-Clientes $cli
                        }

                        $data = Get-DadosReservas
                        $ultimoId = if ($data.reservas.Count -gt 0) { ($data.reservas | Sort-Object id -Descending | Select-Object -First 1).id } else { 1000 }
                        $nova = [PSCustomObject]@{
                            id = $ultimoId + 1; id_hospede = $novoHosp.id; id_quarto = $qId
                            data_checkin = $dataStr; data_checkout = $dtCO.Value.ToString("yyyy-MM-dd")
                            noites = $noites; status = "pendente"; origem = "recepcao"
                            canal = $cmbCanal.Text; valor_total = [math]::Round($total, 2)
                            valor_diaria = $diaria; desconto = 0; taxa_servico = [math]::Round($total * 0.1, 2)
                            metodo_pagamento = $cmbPag.Text; situacao_pagamento = "pendente"
                            observacoes = $txtObs.Text; data_reserva = (Get-Date -Format "yyyy-MM-dd")
                            checkin_realizado = $null; checkout_realizado = $null
                            adultos = 2; criancas = 0; whatsapp_enviado = $false
                        }
                        $data.reservas += $nova
                        Save-Reservas $data
                        $formNova.Close()
                        [System.Windows.Forms.MessageBox]::Show("Reserva #$($nova.id) criada para $dataExib!", "Sucesso")
                        try { Confirmar-AtualizarCanais "criacao de reserva" "Reserva #$($nova.id) - $nomeHosp ($dataExib, Q:$qId)" } catch { }
                        & $RefreshDia
                    })
                    $formNova.ShowDialog()
                })
                $btnCliente = Nova-Botao "Cadastrar Cliente" 310 355 100 30 "#2e7d32" 8
                $btnCliente.Add_Click({
                    $formCli = New-Object System.Windows.Forms.Form
                    $formCli.Text = "Novo Cliente - $dataExib"
                    $formCli.Size = New-Object System.Drawing.Size(420, 320)
                    $formCli.StartPosition = "CenterParent"
                    $formCli.FormBorderStyle = "FixedDialog"
                    $formCli.MaximizeBox = $false; $formCli.MinimizeBox = $false
                    $yC = 20
                    $formCli.Controls.Add((Nova-RichLabel "Nome:" 20 $yC 80 25 -bold))
                    $txtNomeC = New-Object System.Windows.Forms.TextBox
                    $txtNomeC.Location = New-Object System.Drawing.Point(110, $yC); $txtNomeC.Size = New-Object System.Drawing.Size(280, 25)
                    $formCli.Controls.Add($txtNomeC)
                    $yC = 60
                    $formCli.Controls.Add((Nova-RichLabel "Telefone:" 20 $yC 80 25 -bold))
                    $txtTelC = New-Object System.Windows.Forms.TextBox
                    $txtTelC.Location = New-Object System.Drawing.Point(110, $yC); $txtTelC.Size = New-Object System.Drawing.Size(160, 25)
                    $formCli.Controls.Add($txtTelC)
                    $formCli.Controls.Add((Nova-RichLabel "Email:" 290 $yC 60 25))
                    $txtEmailC = New-Object System.Windows.Forms.TextBox
                    $txtEmailC.Location = New-Object System.Drawing.Point(345, $yC); $txtEmailC.Size = New-Object System.Drawing.Size(45, 25)
                    $formCli.Controls.Add($txtEmailC)
                    $yC = 100
                    $formCli.Controls.Add((Nova-RichLabel "Obs:" 20 $yC 80 25))
                    $txtObsC = New-Object System.Windows.Forms.TextBox
                    $txtObsC.Location = New-Object System.Drawing.Point(110, $yC); $txtObsC.Size = New-Object System.Drawing.Size(280, 80)
                    $txtObsC.Multiline = $true
                    $formCli.Controls.Add($txtObsC)
                    $yC = 200
                    $btnSalvarC = Nova-Botao "Salvar" 100 $yC 120 35 "#1565c0"
                    $btnCancC = Nova-Botao "Cancelar" 240 $yC 120 35 "#757575"
                    $formCli.Controls.AddRange(@($btnSalvarC, $btnCancC))
                    $btnCancC.Add_Click({ $formCli.Close() })
                    $btnSalvarC.Add_Click({
                        $nC = $txtNomeC.Text.Trim()
                        if (-not $nC) { [System.Windows.Forms.MessageBox]::Show("Informe o nome", "Erro"); return }
                        $cliData = Get-DadosClientes
                        if (-not $cliData) { $cliData = @{clientes = @()} }
                        $ultIdC = if ($cliData.clientes.Count -gt 0) { ($cliData.clientes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
                        $novoCli = [PSCustomObject]@{
                            id = $ultIdC + 1; nome = $nC; telefone = $txtTelC.Text.Trim()
                            email = $txtEmailC.Text.Trim(); data_cadastro = (Get-Date -Format "yyyy-MM-dd")
                            observacoes = $txtObsC.Text; ativo = $true; whatsapp_opt_in = ($txtTelC.Text.Trim().Length -gt 0)
                        }
                        $cliData.clientes += $novoCli
                        Save-Clientes $cliData
                        $formCli.Close()
                        $formDia.Close()
                        [System.Windows.Forms.MessageBox]::Show("Cliente #$($ultIdC + 1) cadastrado!", "Sucesso")
                        & (Join-Path $global:uiDir "ui_calendario.ps1") $global:pnlContent
                    })
                    $formCli.ShowDialog()
                })
                $btnLimpeza = Nova-Botao "Agendar Limpeza" 260 310 140 35 "#ff8f00" 9
                $btnLimpeza.Add_Click({
                    $formLimp = New-Object System.Windows.Forms.Form
                    $formLimp.Text = "Agendar Limpeza - $dataExib"
                    $formLimp.Size = New-Object System.Drawing.Size(400, 280)
                    $formLimp.StartPosition = "CenterParent"
                    $formLimp.FormBorderStyle = "FixedDialog"
                    $formLimp.MaximizeBox = $false; $formLimp.MinimizeBox = $false
                    $yL = 20
                    $formLimp.Controls.Add((Nova-RichLabel "Quarto:" 20 $yL 80 25 -bold))
                    $cmbQL = New-Object System.Windows.Forms.ComboBox
                    $cmbQL.Location = New-Object System.Drawing.Point(110, $yL); $cmbQL.Size = New-Object System.Drawing.Size(260, 25)
                    $cmbQL.DropDownStyle = "DropDownList"
                    $cmbQL.Items.AddRange(@("01","02","03","04","05","06"))
                    $cmbQL.SelectedIndex = 0
                    $formLimp.Controls.Add($cmbQL)
                    $yL = 60
                    $formLimp.Controls.Add((Nova-RichLabel "Horario:" 20 $yL 80 25 -bold))
                    $dtHora = New-Object System.Windows.Forms.DateTimePicker
                    $dtHora.Location = New-Object System.Drawing.Point(110, $yL); $dtHora.Size = New-Object System.Drawing.Size(110, 25)
                    $dtHora.Format = "Time"; $dtHora.ShowUpDown = $true
                    $dtHora.Value = (Get-Date).Date.AddHours(8)
                    $formLimp.Controls.Add($dtHora)
                    $yL = 100
                    $formLimp.Controls.Add((Nova-RichLabel "Observacoes:" 20 $yL 90 25))
                    $txtObsL = New-Object System.Windows.Forms.TextBox
                    $txtObsL.Location = New-Object System.Drawing.Point(110, $yL); $txtObsL.Size = New-Object System.Drawing.Size(260, 25)
                    $formLimp.Controls.Add($txtObsL)
                    $yL = 150
                    $btnSalvarL = Nova-Botao "Agendar" 80 $yL 120 35 "#ff8f00"
                    $btnCancL = Nova-Botao "Cancelar" 220 $yL 120 35 "#757575"
                    $formLimp.Controls.AddRange(@($btnSalvarL, $btnCancL))
                    $btnCancL.Add_Click({ $formLimp.Close() })
                    $btnSalvarL.Add_Click({
                        $qIdL = [int]$cmbQL.SelectedItem
                        $horaStr = $dtHora.Value.ToString("HH:mm")
                        $dadosL = Get-DadosLimpeza
                        if (-not $dadosL) { $dadosL = @{limpezas = @()} }
                        $ultIdL = if ($dadosL.limpezas.Count -gt 0) { ($dadosL.limpezas | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
                        $novaL = [PSCustomObject]@{
                            id = $ultIdL + 1; id_quarto = $qIdL; data = $dataStr
                            horario = $horaStr; observacoes = $txtObsL.Text
                            status = "pendente"; criada_em = (Get-Date -Format "yyyy-MM-dd HH:mm")
                        }
                        $dadosL.limpezas += $novaL
                        Save-Limpeza $dadosL
                        $formLimp.Close()
                        [System.Windows.Forms.MessageBox]::Show("Limpeza #$($ultIdL + 1) agendada para $dataExib as $horaStr!", "Sucesso")
                        & $RefreshDia
                    })
                    $formLimp.ShowDialog()
                })
                $formDia.Controls.Add($btnNovaData)
                $formDia.Controls.Add($btnLimpeza)
                $formDia.Controls.Add($btnCliente)

                $btnFecharDia = Nova-Botao "Fechar" 415 355 90 30 "#757575" 8
                $btnFecharDia.Add_Click({ $formDia.Close() })
                $formDia.Controls.Add($btnFecharDia)
                $formDia.ShowDialog()
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Erro ao abrir o dia: $($_.Exception.Message)", "Erro")
                }
            }

            $pnlDia.Add_Click($dayClickHandler)
            foreach ($__child in $pnlDia.Controls) {
                $__child.Tag = $dia
                $__child.Cursor = "Hand"
                $__child.Add_Click($dayClickHandler)
            }

            $pnl.Controls.Add($pnlDia)
            $dia++
        }
    }
    $y += ($cellH + 5)
    if ($dia -gt $diasNoMes) { break }
}

$yLista = $y + 10
$pnlReservas = New-Object System.Windows.Forms.Panel
$pnlReservas.Location = New-Object System.Drawing.Point(20, $yLista)
$pnlReservas.Size = New-Object System.Drawing.Size(($pnl.Width - 40), ($pnl.Height - $yLista - 20))
$pnlReservas.Anchor = "Top, Left, Right, Bottom"

$gridYheader = 5
$totalDoMes = if ($d -and $d.reservas) { @($d.reservas | Where-Object { $_.status -ne "cancelada" -and $_.data_checkin -like "$($mesAtual.Year)-$($mesAtual.Month.ToString('00'))-*" }).Count } else { 0 }
$recDoMes = if ($d -and $d.reservas) { [math]::Round((@($d.reservas | Where-Object { $_.status -ne "cancelada" -and $_.data_checkin -like "$($mesAtual.Year)-$($mesAtual.Month.ToString('00'))-*" }) | Measure-Object -Property valor_total -Sum).Sum, 2) } else { 0 }

$lblReservasMes = Nova-RichLabel "Reservas do Mes  [$totalDoMes reservas  |  $(FormatarMoeda $recDoMes)]" 5 $gridYheader 600 25 -bold -size 14
$pnlReservas.Controls.Add($lblReservasMes)

$gridReservas = Nova-Table 5 ($gridYheader + 28) ([math]::Max(300, ($pnlReservas.Width - 12))) ($pnlReservas.Height - $gridYheader - 35)
$gridReservas.Anchor = "Top, Left, Right, Bottom"
$gridReservas.ColumnCount = 7
$gridReservas.Columns[0].HeaderText = "#"; $gridReservas.Columns[0].MinimumWidth = 40
$gridReservas.Columns[1].HeaderText = "Hospede"; $gridReservas.Columns[1].MinimumWidth = 120
$gridReservas.Columns[2].HeaderText = "Check-in"; $gridReservas.Columns[2].MinimumWidth = 80
$gridReservas.Columns[3].HeaderText = "Check-out"; $gridReservas.Columns[3].MinimumWidth = 80
$gridReservas.Columns[4].HeaderText = "Quarto"; $gridReservas.Columns[4].MinimumWidth = 60
$gridReservas.Columns[5].HeaderText = "Valor"; $gridReservas.Columns[5].MinimumWidth = 80
$gridReservas.Columns[6].HeaderText = "Status"; $gridReservas.Columns[6].MinimumWidth = 70
if ($d -and $d.reservas) {
    $reservasMes = @($d.reservas | Where-Object { $_.status -ne "cancelada" -and $_.data_checkin -like "$($mesAtual.Year)-$($mesAtual.Month.ToString('00'))-*" } | Sort-Object data_checkin)
    foreach ($r in $reservasMes) {
        $hospNome = Get-HospedeNome $r.id_hospede
        $qNum = Get-QuartoNumero $r.id_quarto
        $idxM = $gridReservas.Rows.Add($r.id, $hospNome, (FormatarData $r.data_checkin), (FormatarData $r.data_checkout), $qNum, $(FormatarMoeda $r.valor_total), $r.status)
        $gridReservas.Rows[$idxM].Tag = $r
    }
}

$RefreshMesGrid = {
    $dataM = Get-DadosReservas
    $totalNovo = if ($dataM -and $dataM.reservas) { @($dataM.reservas | Where-Object { $_.status -ne "cancelada" -and $_.data_checkin -like "$($mesAtual.Year)-$($mesAtual.Month.ToString('00'))-*" }).Count } else { 0 }
    $recNovo = if ($dataM -and $dataM.reservas) { [math]::Round((@($dataM.reservas | Where-Object { $_.status -ne "cancelada" -and $_.data_checkin -like "$($mesAtual.Year)-$($mesAtual.Month.ToString('00'))-*" }) | Measure-Object -Property valor_total -Sum).Sum, 2) } else { 0 }
    $lblReservasMes.Text = "Reservas do Mes  [$totalNovo reservas  |  $(FormatarMoeda $recNovo)]"
    $reservasAtualizadas = @($dataM.reservas | Where-Object { $_.status -ne "cancelada" -and $_.data_checkin -like "$($mesAtual.Year)-$($mesAtual.Month.ToString('00'))-*" } | Sort-Object data_checkin)
    $gridReservas.Rows.Clear()
    $gridReservas.SuspendLayout()
    foreach ($r in $reservasAtualizadas) {
        $hN = Get-HospedeNome $r.id_hospede
        $qN = Get-QuartoNumero $r.id_quarto
        $idxM = $gridReservas.Rows.Add($r.id, $hN, (FormatarData $r.data_checkin), (FormatarData $r.data_checkout), $qN, $(FormatarMoeda $r.valor_total), $r.status)
        $gridReservas.Rows[$idxM].Tag = $r
    }
    $gridReservas.ResumeLayout()
}

$gridReservas.Add_CellDoubleClick({ $menuEditarMes.PerformClick() })
$cmsMes = New-Object System.Windows.Forms.ContextMenuStrip
$menuEditarMes = New-Object System.Windows.Forms.ToolStripMenuItem("Editar Reserva")
$menuCancelarMes = New-Object System.Windows.Forms.ToolStripMenuItem("Cancelar Reserva")
$menuCancelarMes.ForeColor = [System.Drawing.Color]::FromArgb(198, 40, 40)
$menuCliMes = New-Object System.Windows.Forms.ToolStripMenuItem("Cadastrar Cliente")
$menuCliMes.ForeColor = [System.Drawing.Color]::FromArgb(46, 125, 50)
$cmsMes.Items.AddRange(@($menuEditarMes, $menuCancelarMes, $menuCliMes))
$gridReservas.ContextMenuStrip = $cmsMes

$menuEditarMes.Add_Click({
    if ($gridReservas.SelectedRows.Count -eq 0) { return }
    $rm = $gridReservas.SelectedRows[0].Tag
    if (-not $rm) { return }
    $formEdit = New-Object System.Windows.Forms.Form
    $formEdit.Text = "Editar Reserva #$($rm.id)"
    $formEdit.Size = New-Object System.Drawing.Size(520, 450)
    $formEdit.StartPosition = "CenterParent"
    $formEdit.FormBorderStyle = "FixedDialog"
    $formEdit.MaximizeBox = $false; $formEdit.MinimizeBox = $false
    $yf = 15
    $formEdit.Controls.Add((Nova-RichLabel "Hospede:" 15 $yf 110 25 -bold))
    $lblNomeM = Nova-RichLabel (Get-HospedeNome $rm.id_hospede) 135 $yf 360 25 -size 11 -color "#1565c0"
    $formEdit.Controls.Add($lblNomeM)
    $yf = 50
    $formEdit.Controls.Add((Nova-RichLabel "Status:" 15 $yf 110 25 -bold))
    $cmbStatusM = New-Object System.Windows.Forms.ComboBox
    $cmbStatusM.Location = New-Object System.Drawing.Point(135, $yf); $cmbStatusM.Size = New-Object System.Drawing.Size(150, 25)
    $cmbStatusM.DropDownStyle = "DropDownList"
    "pendente","confirmada","em_andamento","finalizada","cancelada" | ForEach-Object { $cmbStatusM.Items.Add($_); if ($_ -eq $rm.status) { $cmbStatusM.SelectedItem = $_ } }
    $formEdit.Controls.Add($cmbStatusM)
    $yf = 85
    $formEdit.Controls.Add((Nova-RichLabel "Quarto:" 15 $yf 110 25 -bold))
    $cmbQM = New-Object System.Windows.Forms.ComboBox
    $cmbQM.Location = New-Object System.Drawing.Point(135, $yf); $cmbQM.Size = New-Object System.Drawing.Size(360, 25)
    $cmbQM.DropDownStyle = "DropDownList"
    $cmbQM.Items.AddRange(@("01","02","03","04","05","06"))
    $cmbQM.SelectedIndex = [math]::Max(0, [int]$rm.id_quarto - 1)
    $formEdit.Controls.Add($cmbQM)
    $yf = 120
    $formEdit.Controls.Add((Nova-RichLabel "Check-out:" 15 $yf 110 25 -bold))
    $dtCOM = New-Object System.Windows.Forms.DateTimePicker
    $dtCOM.Location = New-Object System.Drawing.Point(135, $yf); $dtCOM.Size = New-Object System.Drawing.Size(150, 25)
    $dtCOM.Format = "Short"
    try { $dtCOM.Value = [DateTime]$rm.data_checkout } catch {}
    $formEdit.Controls.Add($dtCOM)
    $yf = 155
    $formEdit.Controls.Add((Nova-RichLabel "Valor Total:" 15 $yf 110 25 -bold))
    $txtValM = New-Object System.Windows.Forms.TextBox
    $txtValM.Location = New-Object System.Drawing.Point(135, $yf); $txtValM.Size = New-Object System.Drawing.Size(120, 25)
    $txtValM.Text = $rm.valor_total
    $formEdit.Controls.Add($txtValM)
    $formEdit.Controls.Add((Nova-RichLabel "Desconto:" 280 $yf 80 25))
    $txtDescM = New-Object System.Windows.Forms.TextBox
    $txtDescM.Location = New-Object System.Drawing.Point(360, $yf); $txtDescM.Size = New-Object System.Drawing.Size(80, 25)
    $txtDescM.Text = $rm.desconto
    $formEdit.Controls.Add($txtDescM)
    $yf = 190
    $formEdit.Controls.Add((Nova-RichLabel "Pagamento:" 15 $yf 100 25))
    $cmbPagM = New-Object System.Windows.Forms.ComboBox
    $cmbPagM.Location = New-Object System.Drawing.Point(120, $yf); $cmbPagM.Size = New-Object System.Drawing.Size(150, 25)
    $cmbPagM.DropDownStyle = "DropDownList"
    "credito","debito","pix","dinheiro","boleto" | ForEach-Object { $cmbPagM.Items.Add($_); if ($_ -eq $rm.metodo_pagamento) { $cmbPagM.SelectedItem = $_ } }
    $formEdit.Controls.Add((Nova-RichLabel "Canal:" 290 $yf 100 25))
    $cmbCanalM = New-Object System.Windows.Forms.ComboBox
    $cmbCanalM.Location = New-Object System.Drawing.Point(370, $yf); $cmbCanalM.Size = New-Object System.Drawing.Size(145, 25)
    $cmbCanalM.DropDownStyle = "DropDownList"
    $cmbCanalM.FlatStyle = "Flat"
    $cmbCanalM.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    "direto","booking","expedia","airbnb" | ForEach-Object { $cmbCanalM.Items.Add($_); if ($_ -eq $rm.canal) { $cmbCanalM.SelectedItem = $_ } }
    $formEdit.Controls.AddRange(@($cmbPagM, $cmbCanalM))
    $yf = 230
    $formEdit.Controls.Add((Nova-RichLabel "Observacoes:" 15 $yf 100 25))
    $txtObsM = New-Object System.Windows.Forms.TextBox
    $txtObsM.Location = New-Object System.Drawing.Point(120, $yf); $txtObsM.Size = New-Object System.Drawing.Size(375, 55)
    $txtObsM.Multiline = $true; $txtObsM.Text = $rm.observacoes
    $formEdit.Controls.Add($txtObsM)
    $yf = 310
    $btnSalvM = Nova-Botao "Salvar Alteracoes" 100 $yf 170 35 "#1565c0"
    $btnCancM = Nova-Botao "Cancelar" 290 $yf 120 35 "#757575"
    $formEdit.Controls.AddRange(@($btnSalvM, $btnCancM))
    $btnCancM.Add_Click({ $formEdit.Close() })
    $btnSalvM.Add_Click({
        $dataM = Get-DadosReservas
        $alvoM = @($dataM.reservas | Where-Object { $_.id -eq $rm.id })
        if (-not $alvoM) { [System.Windows.Forms.MessageBox]::Show("Reserva nao encontrada", "Erro"); return }
        $rM = $alvoM[0]
        $novaQM = [int]$cmbQM.SelectedItem
        $novoCOM = $dtCOM.Value.ToString("yyyy-MM-dd")

        $conflitos = Verificar-DisponibilidadeQuarto $novaQM $rM.data_checkin $novoCOM -excluirReservaId $rM.id
        if ($conflitos.Count -gt 0) {
            $msg = "Quarto $novaQM ja esta ocupado neste periodo!`n`nConflitos:"
            foreach ($cf in $conflitos) { $msg += "`n  - #$($cf.id): $(Get-HospedeNome $cf.id_hospede)" }
            $msg += "`n`nContinuar?"
            if (([System.Windows.Forms.MessageBox]::Show($msg, "Conflito", "YesNo", "Warning")) -eq "No") { return }
        }

        $rM.status = $cmbStatusM.Text
        $rM.id_quarto = $novaQM
        $rM.data_checkout = $novoCOM
        $rM.noites = ($dtCOM.Value - [DateTime]$rM.data_checkin).Days
        try { $rM.valor_total = [math]::Round([double]($txtValM.Text -replace '[^0-9.,]','' -replace ',','.'), 2) } catch { $rM.valor_total = 0 }
        try { $rM.desconto = [math]::Round([double]($txtDescM.Text -replace '[^0-9.,]','' -replace ',','.'), 2) } catch { $rM.desconto = 0 }
        $rM.metodo_pagamento = $cmbPagM.Text
        $rM.canal = $cmbCanalM.Text
        $rM.observacoes = $txtObsM.Text
        Save-Reservas $dataM
        $formEdit.Close()
        [System.Windows.Forms.MessageBox]::Show("Reserva #$($rm.id) atualizada!", "Sucesso")
        try { Confirmar-AtualizarCanais "atualizacao de reserva" "Reserva #$($rm.id) - Dados alterados na visao mensal" } catch { }
        & (Join-Path $global:uiDir "ui_calendario.ps1") $global:pnlContent
    })
    $formEdit.ShowDialog()
})
$menuCancelarMes.Add_Click({
    if ($gridReservas.SelectedRows.Count -eq 0) { return }
    $rm = $gridReservas.SelectedRows[0].Tag
    if (-not $rm) { return }
    $resp = [System.Windows.Forms.MessageBox]::Show("Cancelar reserva #$($rm.id) de $(Get-HospedeNome $rm.id_hospede)?", "Confirmar Cancelamento", "YesNo", "Warning")
    if ($resp -eq "Yes") {
        $dataM = Get-DadosReservas
        $alvoM = @($dataM.reservas | Where-Object { $_.id -eq $rm.id })
        if ($alvoM) { $alvoM[0].status = "cancelada"; Save-Reservas $dataM }
        & (Join-Path $global:uiDir "ui_calendario.ps1") $global:pnlContent
    }
})
$menuCliMes.Add_Click({
    $formCliM = New-Object System.Windows.Forms.Form
    $formCliM.Text = "Novo Cliente"
    $formCliM.Size = New-Object System.Drawing.Size(420, 320)
    $formCliM.StartPosition = "CenterParent"
    $formCliM.FormBorderStyle = "FixedDialog"
    $formCliM.MaximizeBox = $false; $formCliM.MinimizeBox = $false
    $yC = 20
    $formCliM.Controls.Add((Nova-RichLabel "Nome:" 20 $yC 80 25 -bold))
    $txtNomeCM = New-Object System.Windows.Forms.TextBox
    $txtNomeCM.Location = New-Object System.Drawing.Point(110, $yC); $txtNomeCM.Size = New-Object System.Drawing.Size(280, 25)
    $formCliM.Controls.Add($txtNomeCM)
    $yC = 60
    $formCliM.Controls.Add((Nova-RichLabel "Telefone:" 20 $yC 80 25 -bold))
    $txtTelCM = New-Object System.Windows.Forms.TextBox
    $txtTelCM.Location = New-Object System.Drawing.Point(110, $yC); $txtTelCM.Size = New-Object System.Drawing.Size(160, 25)
    $formCliM.Controls.Add($txtTelCM)
    $formCliM.Controls.Add((Nova-RichLabel "Email:" 290 $yC 60 25))
    $txtEmailCM = New-Object System.Windows.Forms.TextBox
    $txtEmailCM.Location = New-Object System.Drawing.Point(345, $yC); $txtEmailCM.Size = New-Object System.Drawing.Size(45, 25)
    $formCliM.Controls.Add($txtEmailCM)
    $yC = 100
    $formCliM.Controls.Add((Nova-RichLabel "Obs:" 20 $yC 80 25))
    $txtObsCM = New-Object System.Windows.Forms.TextBox
    $txtObsCM.Location = New-Object System.Drawing.Point(110, $yC); $txtObsCM.Size = New-Object System.Drawing.Size(280, 80)
    $txtObsCM.Multiline = $true
    $formCliM.Controls.Add($txtObsCM)
    $yC = 200
    $btnSalvarCoM = Nova-Botao "Salvar" 100 $yC 120 35 "#1565c0"
    $btnCancCoM = Nova-Botao "Cancelar" 240 $yC 120 35 "#757575"
    $formCliM.Controls.AddRange(@($btnSalvarCoM, $btnCancCoM))
    $btnCancCoM.Add_Click({ $formCliM.Close() })
    $btnSalvarCoM.Add_Click({
        $nCoM = $txtNomeCM.Text.Trim()
        if (-not $nCoM) { [System.Windows.Forms.MessageBox]::Show("Informe o nome", "Erro"); return }
        $cliDataM = Get-DadosClientes
        if (-not $cliDataM) { $cliDataM = @{clientes = @()} }
        $ultIdCoM = if ($cliDataM.clientes.Count -gt 0) { ($cliDataM.clientes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novoCliM = [PSCustomObject]@{
            id = $ultIdCoM + 1; nome = $nCoM; telefone = $txtTelCM.Text.Trim()
            email = $txtEmailCM.Text.Trim(); data_cadastro = (Get-Date -Format "yyyy-MM-dd")
            observacoes = $txtObsCM.Text; ativo = $true; whatsapp_opt_in = ($txtTelCM.Text.Trim().Length -gt 0)
        }
        $cliDataM.clientes += $novoCliM
        Save-Clientes $cliDataM
        $formCliM.Close()
        [System.Windows.Forms.MessageBox]::Show("Cliente #$($ultIdCoM + 1) cadastrado!", "Sucesso")
    })
    $formCliM.ShowDialog()
})

$pnlReservas.Controls.Add($gridReservas)
$pnl.Controls.Add($pnlReservas)
