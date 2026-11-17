# ===== BIBLIOTECA CENTRAL COM CACHE =====
$Cache = @{}
$DataDir = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent | Join-Path -ChildPath "data" } else { Join-Path (Get-Location) "data" }

function Get-JsonData($path) {
    if (-not $path -or -not (Test-Path $path)) { return $null }
    $key = $path.GetHashCode()
    if ($Cache.ContainsKey($key)) { return $Cache[$key] }
    try {
        $data = Get-Content $path -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        $Cache[$key] = $data
        return $data
    } catch { return $null }
}

function Save-JsonData($path, $data) {
    $key = $path.GetHashCode()
    try {
        if (Test-Path $path) { Copy-Item $path "$path.bak" -Force -ErrorAction SilentlyContinue }
        $data | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8 -Force
        $Cache[$key] = $data
    } catch { Write-Warning "Erro ao salvar $path" }
}

function Clear-Cache { $Cache = @{} }

function DataPath($file) { Join-Path $DataDir $file }

function Get-DadosReservas { Get-JsonData (DataPath "reservas.json") }
function Get-DadosQuartos { Get-JsonData (DataPath "quartos.json") }
function Get-DadosHospedes { Get-JsonData (DataPath "hospedes.json") }
function Get-DadosFinanceiro { Get-JsonData (DataPath "financeiro.json") }
function Get-DadosConfig { Get-JsonData (DataPath "config.json") }
function Get-DadosIntegracoes { Get-JsonData (DataPath "integracoes.json") }
function Get-DadosClientes { Get-JsonData (DataPath "clientes.json") }
function Get-DadosLimpeza { Get-JsonData (DataPath "limpeza.json") }

function Save-Reservas($d) { Save-JsonData (DataPath "reservas.json") $d }
function Save-Quartos($d) { Save-JsonData (DataPath "quartos.json") $d }
function Save-Hospedes($d) { Save-JsonData (DataPath "hospedes.json") $d }
function Save-Financeiro($d) { Save-JsonData (DataPath "financeiro.json") $d }
function Save-Integracoes($d) { Save-JsonData (DataPath "integracoes.json") $d }
function Save-Clientes($d) { Save-JsonData (DataPath "clientes.json") $d }
function Save-Limpeza($d) { Save-JsonData (DataPath "limpeza.json") $d }
function Save-Config($d) { Save-JsonData (DataPath "config.json") $d }

function FormatarMoeda($valor) {
    if (-not $valor) { return "R$ 0,00" }
    return "R$ $([math]::Round($valor, 2).ToString('N2'))"
}

function FormatarData($data) {
    if (-not $data) { return "-" }
    try { return ([DateTime]$data).ToString("dd/MM/yyyy") } catch { return $data }
}

# Cache de nomes de hospedes
$NomeCache = @{}
function Get-HospedeNome($id) {
    if (-not $id) { return "N/A" }
    if ($NomeCache.ContainsKey($id)) { return $NomeCache[$id] }
    $h = Get-DadosHospedes
    if ($h -and $h.hospedes) {
        $found = @($h.hospedes | Where-Object { $_.id -eq $id })
        if ($found) { $NomeCache[$id] = $found[0].nome; return $found[0].nome }
    }
    return "N/A"
}

function Get-QuartoNumero($id) {
    if (-not $id) { return "-" }
    $q = Get-DadosQuartos
    if ($q -and $q.quartos) {
        $found = @($q.quartos | Where-Object { $_.id -eq $id })
        if ($found) { return $found[0].numero }
    }
    return "$id"
}

function Get-QuartoInfo($id) {
    if (-not $id) { return $null }
    $q = Get-DadosQuartos
    if ($q -and $q.quartos) {
        $found = @($q.quartos | Where-Object { $_.id -eq $id })
        if ($found) { return $found[0] }
    }
    return $null
}

function Nova-Table {
    param($x, $y, $w, $h)
    $w = [math]::Max(50, [int]$w)
    $h = [math]::Max(50, [int]$h)
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point($x, $y)
    $grid.Size = New-Object System.Drawing.Size($w, $h)
    $grid.AllowUserToAddRows = $false; $grid.AllowUserToDeleteRows = $false
    $grid.ReadOnly = $true; $grid.RowHeadersVisible = $false
    $grid.AutoSizeColumnsMode = "Fill"; $grid.SelectionMode = "FullRowSelect"
    $grid.BackgroundColor = [System.Drawing.Color]::White; $grid.BorderStyle = "Fixed3D"
    $grid.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $grid.ColumnHeadersHeight = 35
    $grid.RowTemplate.Height = 30
    $grid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#f8f9ff")
    $grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1a237e")
    $grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#fff")
    $grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $grid
}

function Add-TableCols($grid, $headers) {
    $grid.ColumnCount = $headers.Count
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $grid.Columns[$i].HeaderText = $headers[$i]
    }
}

function Set-ColAlignment($grid, $colIndex, [System.Windows.Forms.DataGridViewContentAlignment]$align = "MiddleRight") {
    if ($colIndex -lt $grid.ColumnCount) {
        $grid.Columns[$colIndex].DefaultCellStyle.Alignment = $align
    }
}

function Nova-StatusBadge {
    param($status)
    $cores = @{
        "disponivel" = "#e8f5e9,#2e7d32"; "ocupado" = "#e3f2fd,#1565c0"
        "reservado" = "#fff3e0,#e65100"; "manutencao" = "#fce4ec,#c62828"
        "limpeza" = "#e0f2f1,#00695c"; "pendente" = "#fff8e1,#f57f17"
        "confirmada" = "#e8f5e9,#2e7d32"; "checkin" = "#e3f2fd,#1565c0"
        "checkout" = "#f3e5f5,#6a1b9a"; "cancelada" = "#fce4ec,#c62828"
        "pago" = "#e8f5e9,#2e7d32"; "recebido" = "#e8f5e9,#2e7d32"
        "pendente_pag" = "#fff8e1,#f57f17"
    }
    $c = if ($cores[$status]) { $cores[$status].Split(',') } else { @("#e0e0e0","#666") }
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = " $status "
    $lbl.AutoSize = $true
    $lbl.Padding = New-Object System.Windows.Forms.Padding(5, 2, 5, 2)
    $lbl.BackColor = [System.Drawing.Color]::FromArgb(255,
        [System.Drawing.ColorTranslator]::FromHtml($c[0]).R,
        [System.Drawing.ColorTranslator]::FromHtml($c[0]).G,
        [System.Drawing.ColorTranslator]::FromHtml($c[0]).B)
    $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($c[1])
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lbl
}

function Nova-StatCard {
    param($icon, $valor, $label, $cor, $x, $y, $w=200)
    $w = [math]::Max(100, [int]$w)
    $corObj = if ($cor -is [string]) { try { [System.Drawing.ColorTranslator]::FromHtml($cor) } catch { "#1565c0" } } else { "#1565c0" }
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location = New-Object System.Drawing.Point($x, $y)
    $pnl.Size = New-Object System.Drawing.Size($w, 80)
    $pnl.BackColor = "#fff"
    $pnl.BorderStyle = "FixedSingle"

    $lblIcon = New-Object System.Windows.Forms.Label
    $lblIcon.Text = $icon
    $lblIcon.Location = New-Object System.Drawing.Point(8, 15)
    $lblIcon.Size = New-Object System.Drawing.Size(48, 50)
    $lblIcon.Font = New-Object System.Drawing.Font("Segoe UI", 18)
    $lblIcon.TextAlign = "MiddleCenter"
    $lblIcon.AutoSize = $false
    $lblIcon.ForeColor = $corObj

    $lblValor = New-Object System.Windows.Forms.Label
    $lblValor.Text = $valor
    $lblValor.Location = New-Object System.Drawing.Point([math]::Max(58, [int](($w - 200) / 2 + 58)), 10)
    $lblValor.Size = New-Object System.Drawing.Size([math]::Max(120, ($w - 76)), 35)
    $lblValor.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblValor.AutoSize = $false
    $lblValor.ForeColor = $corObj
    $lblValor.TextAlign = "MiddleLeft"

    $lblLabel = New-Object System.Windows.Forms.Label
    $lblLabel.Text = $label
    $lblLabel.Location = New-Object System.Drawing.Point([math]::Max(58, [int](($w - 200) / 2 + 58)), 46)
    $lblLabel.Size = New-Object System.Drawing.Size([math]::Max(120, ($w - 76)), 25)
    $lblLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblLabel.AutoSize = $false
    $lblLabel.ForeColor = "#888"
    $lblLabel.TextAlign = "MiddleLeft"

    $pnl.Controls.AddRange(@($lblIcon, $lblValor, $lblLabel))
    $pnl
}

function Nova-Botao {
    param($texto, $x, $y, $w=120, $h=32, $cor="#1565c0", $fonteSize=10)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $texto
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.FlatStyle = "Flat"
    $btn.BackColor = $cor
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", $fonteSize)
    $btn.Cursor = "Hand"
    $btn.FlatAppearance.BorderSize = 0
    $corOriginal = $cor
    $corHover = "#0d47a1"
    $btn.Add_MouseEnter({ $this.BackColor = $corHover }.GetNewClosure())
    $btn.Add_MouseLeave({ $this.BackColor = $corOriginal }.GetNewClosure())
    $btn
}

function Nova-RichLabel {
    param($texto, $x, $y, $w, $h, [switch]$bold, $size=10, $color="#333")
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $texto
    $lbl.Location = New-Object System.Drawing.Point($x, $y)
    $lbl.Size = New-Object System.Drawing.Size($w, $h)
    $fsize = [math]::Max(6, [int]$size)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", $fsize, $(if($bold){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular}))
    if ($color -is [string]) {
        try { $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($color) } catch { $lbl.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51) }
    } else { $lbl.ForeColor = [System.Drawing.Color]::FromArgb(51, 51, 51) }
    $lbl
}

function Nova-Card {
    param($titulo, $x, $y, $w, $h, $conteudo)
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location = New-Object System.Drawing.Point($x, $y)
    $pnl.Size = New-Object System.Drawing.Size($w, $h)
    $pnl.BackColor = "#fff"
    $pnl.BorderStyle = "FixedSingle"

    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = "Top"
    $header.Height = 40
    $header.BackColor = "#fafafa"

    $lblTitulo = New-Object System.Windows.Forms.Label
    $lblTitulo.Text = $titulo
    $lblTitulo.Location = New-Object System.Drawing.Point(15, 8)
    $lblTitulo.AutoSize = $true
    $lblTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lblTitulo.ForeColor = "#333"

    $header.Controls.Add($lblTitulo)
    $pnl.Controls.Add($header)
    if ($conteudo) { $pnl.Controls.Add($conteudo) }
    $pnl
}

function Limpar-Panel {
    param($panel)
    if (-not $panel) { return }
    try { $panel.Controls.Clear() } catch {}
}

function Nova-Imprimir {
    param($texto, $titulo="Documento")
    if (-not $texto) { return }
    try {
        $pd = New-Object System.Drawing.Printing.PrintDocument
        $pd.DocumentName = $titulo
        $pd.DefaultPageSettings.Margins = New-Object System.Drawing.Printing.Margins(60, 60, 60, 60)
        $pd.DefaultPageSettings.Landscape = $false

        $fonteTitulo = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $fonteTexto = New-Object System.Drawing.Font("Segoe UI", 9)
        $fonteSep = New-Object System.Drawing.Font("Segoe UI", 8)
        $fonteRodape = New-Object System.Drawing.Font("Segoe UI", 7)
        $linhas = $texto -split "`r`n"
        $paginaAtual = 0
        $indiceLinha = 0
        $numLinhas = $linhas.Count

        function Draw-Justified($g, $texto, $fonte, $brush, $rect) {
            if ([string]::IsNullOrEmpty($texto)) { return }
            $palavras = $texto -split ' '
            if ($palavras.Count -le 1) {
                $g.DrawString($texto, $fonte, $brush, $rect.Location)
                return
            }
            $largaTotal = $rect.Width
            $sf = New-Object System.Drawing.StringFormat
            $sf.Alignment = "Left"
            $sf.LineAlignment = "Near"
            $sf.Trimming = "None"
            $sf.FormatFlags = "NoWrap"
            $g.DrawString($texto, $fonte, $brush, $rect, $sf)
        }

        $pd.Add_PrintPage({
            param($sender, $e)
            if (-not $e.Graphics) { $e.HasMorePages = $false; return }
            $paginaAtual++
            $g = $e.Graphics
            $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
            $margemEsq = $e.MarginBounds.Left
            $margemSup = $e.MarginBounds.Top
            $largUtil = $e.MarginBounds.Width
            $altUtil = $e.MarginBounds.Height
            $y = $margemSup

            $sfCenter = New-Object System.Drawing.StringFormat
            $sfCenter.Alignment = "Center"; $sfCenter.LineAlignment = "Near"
            $sfLeft = New-Object System.Drawing.StringFormat
            $sfLeft.Alignment = "Left"; $sfLeft.LineAlignment = "Near"
            $sfRight = New-Object System.Drawing.StringFormat
            $sfRight.Alignment = "Far"; $sfRight.LineAlignment = "Near"

            while ($indiceLinha -lt $numLinhas) {
                $linha = $linhas[$indiceLinha]
                $indiceLinha++

                if ($y + $fonteTexto.Height * 1.5 -gt $margemSup + $altUtil) {
                    $indiceLinha--
                    $e.HasMorePages = $true
                    $g.DrawString("Continua...", $fonteRodape, [System.Drawing.Brushes]::Gray, $e.MarginBounds.Right - 60, $e.MarginBounds.Bottom + 5)
                    return
                }

                $ehSep = $linha -match '^[=\-*#_\.\s]{5,}$'
                $ehTitulo = $indiceLinha -eq 1 -or ($linha.Length -gt 0 -and $linha -eq $linha.ToUpper() -and $linha.Length -gt 3)

                if ($ehSep) {
                    $g.DrawString("$($linha[0])" -join (' ' * 200), $fonteSep, [System.Drawing.Brushes]::LightGray, $margemEsq, $y)
                    $y += 6
                } elseif ($indiceLinha -eq 1) {
                    $rectT = New-Object System.Drawing.RectangleF($margemEsq, $y, $largUtil, 30)
                    $g.DrawString($linha, $fonteTitulo, [System.Drawing.Brushes]::Black, $rectT, $sfCenter)
                    $y += 32
                } else {
                    $rect = New-Object System.Drawing.RectangleF($margemEsq, $y, $largUtil, 20)
                    Draw-Justified $g $linha $fonteTexto ([System.Drawing.Brushes]::Black) $rect
                    $y += $fonteTexto.Height + 3
                }
            }

            $g.DrawString("Pagina $paginaAtual", $fonteRodape, [System.Drawing.Brushes]::Gray, $e.MarginBounds.Right - 40, $e.MarginBounds.Bottom + 5)
            $e.HasMorePages = $false
        }.GetNewClosure())

        $prev = New-Object System.Windows.Forms.PrintPreviewDialog
        $prev.Document = $pd
        $prev.WindowState = "Maximized"
        $prev.PrintPreviewControl.Zoom = 1.0
        $prev.ShowIcon = $false
        $prev.Text = "Visualizacao de Impressao - $titulo"
        $prev.ShowDialog()
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao imprimir: $($_.Exception.Message)", "Impressao")
    }
}

function Nova-FichaCadastro {
    param($hospede)
    $cfg = Get-DadosConfig
    $h = if ($cfg -and $cfg.hotel) { $cfg.hotel } else { $null }
    $hotelNome = if ($h) { $h.nome } else { "Pousada Familiar Encanto da Chapada" }
    $hotelEnd = if ($h) { "$($h.endereco), $($h.cidade) - $($h.estado)" } else { "R. Ricardo Martins, 694, Carolina - MA" }
    $hotelTel = if ($h) { $h.telefone } else { "(99) 98121-9754" }

    $reservas = Get-DadosReservas
    $ultReserva = if ($reservas -and $reservas.reservas) {
        @($reservas.reservas | Where-Object { $_.id_hospede -eq $hospede.id } | Sort-Object data_reserva -Descending | Select-Object -First 1)
    } else { $null }
    if ($ultReserva -is [array]) { $ultReserva = $ultReserva[0] }

    function Add-Helper($parent, $html) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $html
        $lbl.AutoSize = $false
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", $html.Split('|')[1])
        $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($html.Split('|')[2])
        $lbl.Location = New-Object System.Drawing.Point((($html.Split('|')[3]) -as [int]), (($html.Split('|')[4]) -as [int]))
        $lbl.Size = New-Object System.Drawing.Size((($html.Split('|')[5]) -as [int]), (($html.Split('|')[6]) -as [int]))
        $lbl.TextAlign = "TopLeft"
        $parent.Controls.Add($lbl)
        return $lbl
    }

    $formFicha = New-Object System.Windows.Forms.Form
    $formFicha.Text = "FNRH - $($hospede.nome)"
    $formFicha.Size = New-Object System.Drawing.Size(750, 820)
    $formFicha.StartPosition = "CenterParent"
    $formFicha.FormBorderStyle = "FixedDialog"
    $formFicha.MaximizeBox = $false; $formFicha.MinimizeBox = $false
    $formFicha.BackColor = [System.Drawing.Color]::White

    $pnlScroll = New-Object System.Windows.Forms.Panel
    $pnlScroll.Location = New-Object System.Drawing.Point(10, 10)
    $pnlScroll.Size = New-Object System.Drawing.Size(710, 730)
    $pnlScroll.AutoScroll = $true
    $formFicha.Controls.Add($pnlScroll)

    $pnlFicha = New-Object System.Windows.Forms.Panel
    $pnlFicha.Size = New-Object System.Drawing.Size(690, 1700)
    $pnlFicha.BorderStyle = "FixedSingle"
    $pnlScroll.Controls.Add($pnlFicha)

    $y = 15

    # ---- Header ----
    $pnlHeader = New-Object System.Windows.Forms.Panel
    $pnlHeader.Location = New-Object System.Drawing.Point(0, 0)
    $pnlHeader.Size = New-Object System.Drawing.Size(688, 110)
    $pnlHeader.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 126)
    $pnlFicha.Controls.Add($pnlHeader)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "FICHA NACIONAL DE REGISTRO DE HÓSPEDES (FNRH)"
    $lbl.Location = New-Object System.Drawing.Point(15, 10)
    $lbl.Size = New-Object System.Drawing.Size(660, 22)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::White
    $lbl.TextAlign = "MiddleCenter"
    $pnlHeader.Controls.Add($lbl)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $hotelNome.ToUpper()
    $lbl.Location = New-Object System.Drawing.Point(15, 32)
    $lbl.Size = New-Object System.Drawing.Size(660, 20)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(187, 222, 251)
    $lbl.TextAlign = "MiddleCenter"
    $pnlHeader.Controls.Add($lbl)

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "$hotelEnd  |  Tel: $hotelTel"
    $lbl.Location = New-Object System.Drawing.Point(15, 55)
    $lbl.Size = New-Object System.Drawing.Size(660, 18)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(227, 242, 253)
    $lbl.TextAlign = "MiddleCenter"
    $pnlHeader.Controls.Add($lbl)

    # Line after header
    $y = 120
    Add-Helper $pnlFicha "____________________________________________________________________________________________________|8|#ccc|15|$y|660|2" | Out-Null

    # ============================================================
    # SECTION 1 - INFORMAÇÕES DA HOSPEDAGEM
    # ============================================================
    $y = 130
    Add-Helper $pnlFicha "🔑 1. INFORMAÇÕES DA HOSPEDAGEM|11|#1a237e|15|$y|660|22" | Out-Null

    $y = 160
    $lbl = Add-Helper $pnlFicha "UH Nº (Quarto):  _________________________________|10|#333|20|$y|300|22" $null
    $quartoNum = if ($ultReserva) { Get-QuartoNumero $ultReserva.id_quarto } else { "" }
    $lbl.Text = "UH Nº (Quarto):  $(if ($quartoNum) { $quartoNum } else { '_________________________' })"

    $lbl = Add-Helper $pnlFicha "Nº de Acompanhantes:  _________________________|10|#333|340|$y|300|22" $null
    $acomp = if ($ultReserva) { ([int]$ultReserva.adultos - 1) + [int]$ultReserva.criancas } else { 0 }
    $lbl.Text = "Nº de Acompanhantes:  $(if ($ultReserva) { $acomp } else { '_________________' })"

    $y = 195
    $entrada = if ($ultReserva) { $ultReserva.data_checkin } else { Get-Date -Format "yyyy-MM-dd" }
    $lbl = Add-Helper $pnlFicha "Data de Entrada:  $(if ($ultReserva) { (Get-Date $entrada -Format 'dd/MM/yyyy') } else { '__/__/____' })  |  Hora: $(if ($ultReserva -and $ultReserva.checkin_realizado) { (Get-Date $ultReserva.checkin_realizado -Format 'HH:mm') } else { '__:__' }) |10|#333|20|$y|300|22" $null

    $saida = if ($ultReserva) { $ultReserva.data_checkout } else { Get-Date -Format "yyyy-MM-dd" }
    $lbl2 = Add-Helper $pnlFicha "Data de Saída:  $(if ($ultReserva) { (Get-Date $saida -Format 'dd/MM/yyyy') } else { '__/__/____' })  |  Hora: $(if ($ultReserva -and $ultReserva.checkout_realizado) { (Get-Date $ultReserva.checkout_realizado -Format 'HH:mm') } else { '__:__' }) |10|#333|20|$($y + 25)|660|22" $null

    $y = 250
    Add-Helper $pnlFicha "____________________________________________________________________________________________________|8|#ccc|15|$y|660|2" | Out-Null

    # ============================================================
    # SECTION 2 - INFORMAÇÕES DO HÓSPEDE
    # ============================================================
    $y = 260
    Add-Helper $pnlFicha "👤 2. INFORMAÇÕES DO HÓSPEDE|11|#1a237e|15|$y|660|22" | Out-Null

    $y = 290
    Add-Helper $pnlFicha "Nome Completo: __________________________________________________________________________|10|#333|20|$y|640|22" $null
    $lblNome = $pnlFicha.Controls[$pnlFicha.Controls.Count - 1]
    $lblNome.Text = "Nome Completo:  $($hospede.nome)"

    $y = 320
    Add-Helper $pnlFicha "Data de Nascimento:  __/__/____  |  Idade:  ____  |  Sexo:  (  ) M  (  ) F|10|#333|20|$y|640|22" $null

    $y = 350
    $cpf = if ($hospede.documento -and $hospede.tipo_documento -eq "CPF") { $hospede.documento } else { "___________________________" }
    Add-Helper $pnlFicha "CPF:  $cpf  |  Profissão:  _______________________________|10|#333|20|$y|640|22" $null
    $lblDoc = $pnlFicha.Controls[$pnlFicha.Controls.Count - 1]

    $y = 380
    Add-Helper $pnlFicha "Documento de Identidade (RG):  _______________________  |  Órgão Expedidor:  ______________|10|#333|20|$y|640|22" $null

    $y = 410
    Add-Helper $pnlFicha "Telefone/Whatsapp:  $($hospede.telefone)  |  E-mail:  $($hospede.email)|10|#333|20|$y|640|22" $null

    $y = 450
    Add-Helper $pnlFicha "____________________________________________________________________________________________________|8|#ccc|15|$y|660|2" | Out-Null

    # ============================================================
    # SECTION 3 - ENDEREÇO RESIDENCIAL
    # ============================================================
    $y = 460
    Add-Helper $pnlFicha "🏠 3. ENDEREÇO RESIDENCIAL|11|#1a237e|15|$y|660|22" | Out-Null

    $y = 490
    Add-Helper $pnlFicha "Endereço (Rua/Av, Nº):  ________________________________________________________|10|#333|20|$y|640|22" $null

    $y = 520
    Add-Helper $pnlFicha "Bairro:  ______________________________  |  CEP:  ______________________________|10|#333|20|$y|640|22" $null

    $y = 550
    Add-Helper $pnlFicha "Cidade:  _________________________________  |  Estado:  _______________________________|10|#333|20|$y|640|22" $null

    $y = 590
    Add-Helper $pnlFicha "____________________________________________________________________________________________________|8|#ccc|15|$y|660|2" | Out-Null

    # ============================================================
    # SECTION 4 - DADOS DA VIAGEM
    # ============================================================
    $y = 600
    Add-Helper $pnlFicha "🚗 4. DADOS DA VIAGEM|11|#1a237e|15|$y|660|22" | Out-Null

    $y = 630
    Add-Helper $pnlFicha "Último Destino (Cidade/Estado):  ___________________________________________________________|10|#333|20|$y|640|22" $null

    $y = 660
    Add-Helper $pnlFicha "Próximo Destino (Cidade/Estado):  __________________________________________________________|10|#333|20|$y|640|22" $null

    $y = 695
    Add-Helper $pnlFicha "Motivo da Viagem:|10|#333|20|$y|200|22" $null
    $y = 720
    @("Férias / Lazer","Negócios / Trabalho","Congresso / Evento","Estudos","Saúde","Outro") | ForEach-Object {
        Add-Helper $pnlFicha "(  ) $_|10|#333|30|$y|300|20" $null
        if ($_ -in @("Férias / Lazer","Negócios / Trabalho","Congresso / Evento")) { $y += 22 }
    }
    $y += 5
    Add-Helper $pnlFicha "Meio de Transporte:|10|#333|20|$y|200|22" $null
    $y += 22
    @("Automóvel / Carro","Motocicleta","Ônibus","Avião","Outro") | ForEach-Object {
        Add-Helper $pnlFicha "(  ) $_|10|#333|30|$y|300|20" $null
        $y += 22
    }

    $y += 10
    Add-Helper $pnlFicha "____________________________________________________________________________________________________|8|#ccc|15|$y|660|2" | Out-Null

    # ============================================================
    # SECTION 5 - CONFIRMAÇÃO E ASSINATURA
    # ============================================================
    $y += 10
    Add-Helper $pnlFicha "✍️ 5. CONFIRMAÇÃO E ASSINATURA|11|#1a237e|15|$y|660|22" | Out-Null

    $y += 30
    Add-Helper $pnlFicha "Declaro que as informações prestadas nesta ficha são verdadeiras e estou ciente das normas de estadia da pousada.|10|#333|20|$y|640|20" $null

    $y += 35
    Add-Helper $pnlFicha "Carolina - MA, ____ de ________________________ de 20____.|10|#333|20|$y|640|22" $null

    $y += 60
    Add-Helper $pnlFicha "___________________________________________________________________________|10|#333|60|$y|500|2" $null
    $y += 5
    Add-Helper $pnlFicha "Assinatura do Hóspede|9|#999|60|$y|500|20" $null

    $y += 40
    Add-Helper $pnlFicha "___________________________________________________________________________|10|#333|60|$y|500|2" $null
    $y += 5
    Add-Helper $pnlFicha "Assinatura do Recepcionista|9|#999|60|$y|500|20" $null

    $y += 45
    $lblRodape = New-Object System.Windows.Forms.Label
    $lblRodape.Text = "Emitido em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')  |  Documento gerado pelo sistema de gestão"
    $lblRodape.Location = New-Object System.Drawing.Point(15, $y)
    $lblRodape.Size = New-Object System.Drawing.Size(660, 20)
    $lblRodape.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblRodape.ForeColor = [System.Drawing.Color]::FromArgb(153, 153, 153)
    $lblRodape.TextAlign = "MiddleCenter"
    $pnlFicha.Controls.Add($lblRodape)

    $btnPrintF = Nova-Botao " Imprimir FNRH" 270 755 160 35 "#1565c0"
    $btnCloseF = Nova-Botao " Fechar" 450 755 120 35 "#757575"
    $formFicha.Controls.AddRange(@($btnPrintF, $btnCloseF))
    $btnCloseF.Add_Click({ $formFicha.Close() })
    $btnPrintF.Add_Click({
        $sep = "========================================"
        $textoP = @()
        $textoP += $sep
        $textoP += "  FICHA NACIONAL DE REGISTRO DE HOSPEDES (FNRH)"
        $textoP += "  $hotelNome".ToUpper()
        $textoP += "  $hotelEnd"
        $textoP += "  Tel: $hotelTel"
        $textoP += $sep
        $textoP += "  1. INFORMACOES DA HOSPEDAGEM"
        $textoP += "  ----------------------------------------"
        $textoP += "  UH N (Quarto):         $quartoNum"
        $textoP += "  N de Acompanhantes:    $acomp"
        $textoP += "  Data de Entrada:       $entrada"
        $textoP += "  Data de Saida:         $saida"
        $textoP += ""
        $textoP += "  2. INFORMACOES DO HOSPEDE"
        $textoP += "  ----------------------------------------"
        $textoP += "  Nome:                  $($hospede.nome)"
        $textoP += "  CPF:                   $cpf"
        $textoP += "  Telefone:              $($hospede.telefone)"
        $textoP += "  Email:                 $($hospede.email)"
        $textoP += ""
        $textoP += "  3. ENDERECO RESIDENCIAL"
        $textoP += "  ----------------------------------------"
        $textoP += "  Endereco:              $($hospede.endereco)"
        $textoP += ""
        $textoP += "  4. DADOS DA VIAGEM"
        $textoP += "  ----------------------------------------"
        $textoP += ""
        $textoP += "  5. CONFIRMACAO E ASSINATURA"
        $textoP += "  ----------------------------------------"
        $textoP += "  Declaro que as informacoes prestadas nesta"
        $textoP += "  ficha sao verdadeiras e estou ciente das"
        $textoP += "  normas de estadia da pousada."
        $textoP += ""
        $textoP += "  Carolina - MA, ____ de ____________ de 20____."
        $textoP += ""
        $textoP += "  Assinatura do Hospede: ___________________________"
        $textoP += "  Assinatura do Recepcionista: _____________________"
        $textoP += ""
        $textoP += $sep
        $textoP += "  Emitido em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
        Nova-Imprimir ($textoP -join "`r`n") "FNRH - $($hospede.nome)"
    })
    $formFicha.ShowDialog()
}

function Nova-FichaEmBranco {
    $cfg = Get-DadosConfig
    $h = if ($cfg -and $cfg.hotel) { $cfg.hotel } else { $null }
    $hotelNome = if ($h) { $h.nome } else { "Pousada Familiar Encanto da Chapada" }
    $hotelEnd = if ($h) { "$($h.endereco), $($h.cidade) - $($h.estado)" } else { "R. Ricardo Martins, 694, Carolina - MA" }
    $hotelTel = if ($h) { $h.telefone } else { "(99) 98121-9754" }

    $formFicha = New-Object System.Windows.Forms.Form
    $formFicha.Text = "FNRH - Em Branco"
    $formFicha.Size = New-Object System.Drawing.Size(750, 820)
    $formFicha.StartPosition = "CenterParent"
    $formFicha.FormBorderStyle = "FixedDialog"
    $formFicha.MaximizeBox = $false; $formFicha.MinimizeBox = $false
    $formFicha.BackColor = [System.Drawing.Color]::White

    $pnlScroll = New-Object System.Windows.Forms.Panel
    $pnlScroll.Location = New-Object System.Drawing.Point(10, 10)
    $pnlScroll.Size = New-Object System.Drawing.Size(710, 730)
    $pnlScroll.AutoScroll = $true
    $formFicha.Controls.Add($pnlScroll)

    $pnlFicha = New-Object System.Windows.Forms.Panel
    $pnlFicha.Size = New-Object System.Drawing.Size(690, 1700)
    $pnlFicha.BorderStyle = "FixedSingle"
    $pnlScroll.Controls.Add($pnlFicha)

    function Add-BlankLine($parent, $x, $y, $w) {
        $l = New-Object System.Windows.Forms.Label
        $l.BorderStyle = "FixedSingle"
        $l.Location = New-Object System.Drawing.Point($x, $y)
        $l.Size = New-Object System.Drawing.Size($w, 1)
        $l.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
        $parent.Controls.Add($l)
    }
    function Add-Label($parent, $text, $x, $y, $w, $h, $fs, $bold, $color) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $text
        $lbl.Location = New-Object System.Drawing.Point($x, $y)
        $lbl.Size = New-Object System.Drawing.Size($w, $h)
        if ($bold) { $lbl.Font = New-Object System.Drawing.Font("Segoe UI", $fs, [System.Drawing.FontStyle]::Bold) } else { $lbl.Font = New-Object System.Drawing.Font("Segoe UI", $fs) }
        $lbl.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($color)
        $parent.Controls.Add($lbl)
    }

    $y = 15
    # ---- Header ----
    $pnlHeader = New-Object System.Windows.Forms.Panel
    $pnlHeader.Location = New-Object System.Drawing.Point(0, 0)
    $pnlHeader.Size = New-Object System.Drawing.Size(688, 110)
    $pnlHeader.BackColor = [System.Drawing.Color]::FromArgb(26, 35, 126)
    $pnlFicha.Controls.Add($pnlHeader)

    Add-Label $pnlHeader "FICHA NACIONAL DE REGISTRO DE HÓSPEDES (FNRH)" 15 10 660 22 11 $true "#ffffff"
    Add-Label $pnlHeader $hotelNome.ToUpper() 15 32 660 20 10 $true "#bbdefb"
    Add-Label $pnlHeader "$hotelEnd  |  Tel: $hotelTel" 15 55 660 18 8 $false "#e3f2fd"

    $y = 120
    $sep = New-Object System.Windows.Forms.Label
    $sep.BorderStyle = "Fixed3D"; $sep.Location = New-Object System.Drawing.Point(15, $y); $sep.Size = New-Object System.Drawing.Size(660, 2)
    $pnlFicha.Controls.Add($sep)

    $y += 15
    Add-Label $pnlFicha "🔑 1. INFORMAÇÕES DA HOSPEDAGEM" 15 $y 660 22 11 $true "#1a237e"
    $y += 35
    Add-Label $pnlFicha "UH Nº (Quarto):  _________________________" 20 $y 300 22 10 $false "#333"
    Add-Label $pnlFicha "Nº de Acompanhantes:  _________________________" 340 $y 300 22 10 $false "#333"
    $y += 35
    Add-Label $pnlFicha "Data de Entrada:  __/__/____  |  Hora:  __:__" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "Data de Saída:  __/__/____  |  Hora:  __:__" 20 $y 640 22 10 $false "#333"

    $y += 40
    $sep = New-Object System.Windows.Forms.Label
    $sep.BorderStyle = "Fixed3D"; $sep.Location = New-Object System.Drawing.Point(15, $y); $sep.Size = New-Object System.Drawing.Size(660, 2)
    $pnlFicha.Controls.Add($sep)

    $y += 15
    Add-Label $pnlFicha "👤 2. INFORMAÇÕES DO HÓSPEDE" 15 $y 660 22 11 $true "#1a237e"
    $y += 35
    Add-Label $pnlFicha "Nome Completo:  _______________________________________________________________" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "Data de Nascimento:  __/__/____  |  Idade:  ____  |  Sexo:  (  ) M  (  ) F" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "CPF:  ___________________________  |  Profissão:  _______________________________" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "Documento de Identidade (RG):  _______________________  |  Órgão Expedidor:  ______________" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "Telefone/Whatsapp:  (____) ________________________  |  E-mail:  ____________________________" 20 $y 640 22 10 $false "#333"

    $y += 40
    $sep = New-Object System.Windows.Forms.Label
    $sep.BorderStyle = "Fixed3D"; $sep.Location = New-Object System.Drawing.Point(15, $y); $sep.Size = New-Object System.Drawing.Size(660, 2)
    $pnlFicha.Controls.Add($sep)

    $y += 15
    Add-Label $pnlFicha "🏠 3. ENDEREÇO RESIDENCIAL" 15 $y 660 22 11 $true "#1a237e"
    $y += 35
    Add-Label $pnlFicha "Endereço (Rua/Av, Nº):  ________________________________________________________" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "Bairro:  ______________________________  |  CEP:  ______________________________" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "Cidade:  _________________________________  |  Estado:  _______________________________" 20 $y 640 22 10 $false "#333"

    $y += 40
    $sep = New-Object System.Windows.Forms.Label
    $sep.BorderStyle = "Fixed3D"; $sep.Location = New-Object System.Drawing.Point(15, $y); $sep.Size = New-Object System.Drawing.Size(660, 2)
    $pnlFicha.Controls.Add($sep)

    $y += 15
    Add-Label $pnlFicha "🚗 4. DADOS DA VIAGEM" 15 $y 660 22 11 $true "#1a237e"
    $y += 35
    Add-Label $pnlFicha "Último Destino (Cidade/Estado):  ___________________________________________________________" 20 $y 640 22 10 $false "#333"
    $y += 30
    Add-Label $pnlFicha "Próximo Destino (Cidade/Estado):  __________________________________________________________" 20 $y 640 22 10 $false "#333"

    $y += 35
    Add-Label $pnlFicha "Motivo da Viagem:" 20 $y 200 22 10 $false "#333"
    $y += 25
    @("Férias / Lazer","Negócios / Trabalho","Congresso / Evento","Estudos","Saúde","Outro") | ForEach-Object {
        Add-Label $pnlFicha "(  ) $_" 30 $y 300 20 10 $false "#333"
        if ($_ -in @("Férias / Lazer","Negócios / Trabalho","Congresso / Evento")) { $y += 22 }
    }
    $y += 30
    Add-Label $pnlFicha "Meio de Transporte:" 20 $y 200 22 10 $false "#333"
    $y += 25
    @("Automóvel / Carro","Motocicleta","Ônibus","Avião","Outro") | ForEach-Object {
        Add-Label $pnlFicha "(  ) $_" 30 $y 300 20 10 $false "#333"
        $y += 22
    }

    $y += 30
    $sep = New-Object System.Windows.Forms.Label
    $sep.BorderStyle = "Fixed3D"; $sep.Location = New-Object System.Drawing.Point(15, $y); $sep.Size = New-Object System.Drawing.Size(660, 2)
    $pnlFicha.Controls.Add($sep)

    $y += 15
    Add-Label $pnlFicha "✍️ 5. CONFIRMAÇÃO E ASSINATURA" 15 $y 660 22 11 $true "#1a237e"

    $y += 35
    Add-Label $pnlFicha "Declaro que as informações prestadas nesta ficha são verdadeiras e estou ciente das normas de estadia da pousada." 20 $y 640 20 10 $false "#333"

    $y += 35
    Add-Label $pnlFicha "Carolina - MA, ____ de ________________________ de 20____." 20 $y 640 22 10 $false "#333"

    $y += 60
    Add-BlankLine $pnlFicha 60 $y 500
    $y += 5
    Add-Label $pnlFicha "Assinatura do Hóspede" 60 $y 500 20 9 $false "#999"

    $y += 40
    Add-BlankLine $pnlFicha 60 $y 500
    $y += 5
    Add-Label $pnlFicha "Assinatura do Recepcionista" 60 $y 500 20 9 $false "#999"

    $y += 50
    Add-Label $pnlFicha "Emitido em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')  |  Ficha para preenchimento manual" 15 $y 660 20 8 $false "#999"

    $btnPrintF = Nova-Botao " Imprimir FNRH" 270 755 160 35 "#1565c0"
    $btnCloseF = Nova-Botao " Fechar" 450 755 120 35 "#757575"
    $formFicha.Controls.AddRange(@($btnPrintF, $btnCloseF))
    $btnCloseF.Add_Click({ $formFicha.Close() })
    $btnPrintF.Add_Click({
        $sep = "========================================"
        $textoP = @()
        $textoP += $sep
        $textoP += "  FICHA NACIONAL DE REGISTRO DE HOSPEDES (FNRH)"
        $textoP += "  $hotelNome".ToUpper()
        $textoP += "  $hotelEnd"
        $textoP += "  Tel: $hotelTel"
        $textoP += $sep
        $textoP += "  1. INFORMACOES DA HOSPEDAGEM"
        $textoP += "  ----------------------------------------"
        $textoP += "  UH N (Quarto):         _________________"
        $textoP += "  N de Acompanhantes:    _________________"
        $textoP += "  Data de Entrada:       __/__/____ __:__"
        $textoP += "  Data de Saida:         __/__/____ __:__"
        $textoP += ""
        $textoP += "  2. INFORMACOES DO HOSPEDE"
        $textoP += "  ----------------------------------------"
        $textoP += "  Nome:                  _________________"
        $textoP += "  CPF:                   _________________"
        $textoP += "  Telefone:              _________________"
        $textoP += "  Email:                 _________________"
        $textoP += ""
        $textoP += "  3. ENDERECO RESIDENCIAL"
        $textoP += "  ----------------------------------------"
        $textoP += "  Endereco:              _________________"
        $textoP += ""
        $textoP += "  4. DADOS DA VIAGEM"
        $textoP += "  ----------------------------------------"
        $textoP += ""
        $textoP += "  5. CONFIRMACAO E ASSINATURA"
        $textoP += "  ----------------------------------------"
        $textoP += "  Declaro que as informacoes prestadas nesta"
        $textoP += "  ficha sao verdadeiras e estou ciente das"
        $textoP += "  normas de estadia da pousada."
        $textoP += ""
        $textoP += "  Carolina - MA, ____ de ____________ de 20____."
        $textoP += ""
        $textoP += "  Assinatura do Hospede: ___________________"
        $textoP += "  Assinatura do Recepcionista: _____________"
        $textoP += ""
        $textoP += $sep
        $textoP += "  Ficha para preenchimento manual"
        Nova-Imprimir ($textoP -join "`r`n") "FNRH - Em Branco"
    })
    $formFicha.ShowDialog()
}


