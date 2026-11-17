param($pnl)
if (-not $pnl) { return }

try {
Limpar-Panel $pnl
Clear-Cache

$cfg = Get-DadosConfig
$hotel = if ($cfg) { $cfg.hotel } else { $null }
$w = if ($cfg) { $cfg.whatsapp } else { $null }

$pnl.Controls.Add((Nova-RichLabel "Configuracoes" 20 15 400 30 -bold -size 16))

$cardW = [math]::Min(700, ($pnl.Width - 40))
$cardX = [math]::Max(20, [int](($pnl.Width - $cardW) / 2))
$labelW = $cardW - 120

$pnlCard = New-Object System.Windows.Forms.Panel
$pnlCard.Location = New-Object System.Drawing.Point($cardX, 50)
$pnlCard.Size = New-Object System.Drawing.Size($cardW, 280)
$pnlCard.BackColor = "#fff"; $pnlCard.BorderStyle = "FixedSingle"
$pnlCard.Controls.Add((Nova-RichLabel "Dados da Pousada" 15 10 300 25 -bold -size 14))

$valLabels = @()
$info = @(
    @{l="Nome:"; v= if($hotel){$hotel.nome}else{""}},
    @{l="Endereco:"; v= if($hotel){$hotel.endereco}else{""}},
    @{l="Cidade:"; v= if($hotel){$hotel.cidade}else{""}},
    @{l="Estado:"; v= if($hotel){$hotel.estado}else{""}},
    @{l="Telefone:"; v= if($hotel){$hotel.telefone}else{""}},
    @{l="Email:"; v= if($hotel){$hotel.email}else{""}},
    @{l="Check-in:"; v= if($hotel){$hotel.checkin_padrao}else{"12:00"}},
    @{l="Check-out:"; v= if($hotel){$hotel.checkout_padrao}else{"12:00"}}
)
$yi = 45
foreach ($inf in $info) {
    $pnlCard.Controls.Add((Nova-RichLabel $inf.l 15 $yi 80 22 -size 10 -bold))
    $lblV = Nova-RichLabel $inf.v 100 $yi $labelW 22 -size 10 -color "#555"
    $pnlCard.Controls.Add($lblV)
    $valLabels += $lblV
    $yi += 27
}
$pnl.Controls.Add($pnlCard)

$pnlWhats = New-Object System.Windows.Forms.Panel
$pnlWhats.Location = New-Object System.Drawing.Point($cardX, 345)
$pnlWhats.Size = New-Object System.Drawing.Size($cardW, 120)
$pnlWhats.BackColor = "#fff"; $pnlWhats.BorderStyle = "FixedSingle"
$pnlWhats.Controls.Add((Nova-RichLabel "WhatsApp" 15 10 300 25 -bold -size 14))

$lblWNum = Nova-RichLabel $(if($w){$w.numero}else{""}) 100 45 $labelW 22 -size 10 -color "#555"
$pnlWhats.Controls.Add((Nova-RichLabel "Numero:" 15 45 80 22 -size 10 -bold))
$pnlWhats.Controls.Add($lblWNum)
$valLabels += $lblWNum

$lblWStatus = Nova-RichLabel $(if($w -and $w.ativo){"Ativo"}else{"Inativo"}) 100 72 $labelW 22 -size 10 -color $(if($w -and $w.ativo){"#2e7d32"}else{"#c62828"})
$pnlWhats.Controls.Add((Nova-RichLabel "Status:" 15 72 80 22 -size 10 -bold))
$pnlWhats.Controls.Add($lblWStatus)
$valLabels += $lblWStatus
$pnl.Controls.Add($pnlWhats)

$pnlInfo = New-Object System.Windows.Forms.Panel
$pnlInfo.Location = New-Object System.Drawing.Point($cardX, 480)
$pnlInfo.Size = New-Object System.Drawing.Size($cardW, 80)
$pnlInfo.BackColor = "#fff"; $pnlInfo.BorderStyle = "FixedSingle"
$pnlInfo.Controls.Add((Nova-RichLabel "Informacoes do Sistema" 15 10 300 25 -bold -size 14))
$lblSys = Nova-RichLabel "Versao: 1.0.0 | Base: JSON Local | Idioma: Portugues (Brasil)" 15 40 $labelW 25 -size 10 -color "#888"
$pnlInfo.Controls.Add($lblSys)
$pnl.Controls.Add($pnlInfo)

$pnl.Add_Resize({
    try {
        if (-not $pnlCard -or -not $pnlWhats -or -not $pnlInfo) { return }
        $newW = [math]::Min(700, ($pnl.Width - 40))
        $newX = [math]::Max(20, [int](($pnl.Width - $newW) / 2))
        $newLW = $newW - 120
        $pnlCard.Width = $newW; $pnlCard.Left = $newX
        $pnlWhats.Width = $newW; $pnlWhats.Left = $newX
        $pnlInfo.Width = $newW; $pnlInfo.Left = $newX
        if ($valLabels) { foreach ($lbl in $valLabels) { $lbl.Width = $newLW } }
    } catch {}
})

} catch {}
