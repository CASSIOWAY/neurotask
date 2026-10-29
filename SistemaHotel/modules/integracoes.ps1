# ===== MÓDULO DE INTEGRAÇÕES (Omnibees / Booking.com) =====


function Save-DadosIntegracoes($data) {
    Save-Integracoes $data
}

function Get-ReservasUnificadas {
    $locais = Get-DadosReservas
    $externas = Get-DadosIntegracoes

    $unificadas = @()

    if ($locais -and $locais.reservas) {
        foreach ($r in $locais.reservas) {
            $unificadas += [PSCustomObject]@{
                id_reserva = "INT-$($r.id)"
                origem = "local"
                canal = $r.canal
                plataforma = if ($r.canal -eq "direto") { "Reserva Direta" } else { $r.canal }
                nome_hospede = ""
                data_checkin = $r.data_checkin
                data_checkout = $r.data_checkout
                noites = $r.noites
                valor_total = $r.valor_total
                comissao = 0
                status = $r.status
                status_pagamento = $r.situacao_pagamento
                tipo_quarto = ""
                observacoes = $r.observacoes
            }
        }
    }

    if ($externas -and $externas.reservas_externas) {
        foreach ($r in $externas.reservas_externas) {
            $unificadas += [PSCustomObject]@{
                id_reserva = $r.id
                origem = $r.canal
                canal = $r.canal
                plataforma = $r.plataforma
                nome_hospede = $r.nome_hospede
                data_checkin = $r.data_checkin
                data_checkout = $r.data_checkout
                noites = $r.noites
                valor_total = $r.valor_total
                comissao = $r.comissao_valor
                status = $r.status
                status_pagamento = $r.status_pagamento
                tipo_quarto = $r.tipo_quarto
                observacoes = $r.observacoes
            }
        }
    }

    $unificadas | Sort-Object data_checkin
}

function Importar-ReservasCSV {
    param($caminhoCSV, $canal)

    if (-not (Test-Path $caminhoCSV)) {
        return @{sucesso = $false; erro = "Arquivo nao encontrado"; importadas = 0}
    }

    try {
        $csv = Import-Csv $caminhoCSV -Encoding UTF8
    } catch {
        return @{sucesso = $false; erro = "Erro ao ler CSV: $($_.Exception.Message)"; importadas = 0}
    }

    $integracoes = Get-DadosIntegracoes
    if (-not $integracoes) {
        return @{sucesso = $false; erro = "Nenhum dado de integração encontrado"; importadas = 0}
    }
    $importadas = 0; $ignoradas = 0

    foreach ($linha in $csv) {
        $idExterno = $linha.id_reserva_origem
        if (-not $idExterno) { $idExterno = "$canal-$([System.Guid]::NewGuid().ToString().Substring(0,8))" }

        $existente = @($integracoes.reservas_externas | Where-Object { $_.id_reserva_origem -eq $idExterno })
        if ($existente.Count -gt 0) { $ignoradas++; continue }

        $nova = [PSCustomObject]@{
            id = "$canal-$(Get-Date -Format 'yyyyMMdd')-$([System.Guid]::NewGuid().ToString().Substring(0,4))"
            canal = $canal
            plataforma = if ($canal -eq "booking") { "Booking.com" } elseif ($canal -eq "omnibees") { "Omnibees" } else { $canal }
            id_reserva_origem = $idExterno
            nome_hospede = $linha.nome_hospede
            email = $linha.email
            telefone = $linha.telefone
            data_checkin = $linha.data_checkin
            data_checkout = $linha.data_checkout
            noites = [int]($linha.noites -replace '\D','')
            adultos = [int]($linha.adultos -replace '\D','')
            criancas = [int]($linha.criancas -replace '\D','')
            tipo_quarto = $linha.tipo_quarto
            qtde_quartos = [int]($linha.qtde_quartos -replace '\D','')
            valor_total = [double]($linha.valor_total -replace '[^0-9.,]','' -replace ',','.')
            valor_diaria = [double]($linha.valor_diaria -replace '[^0-9.,]','' -replace ',','.')
            moeda = if ($linha.moeda) { $linha.moeda } else { "BRL" }
            comissao_percentual = [double]($linha.comissao_percentual -replace '[^0-9.,]','' -replace ',','.')
            comissao_valor = [double]($linha.comissao_valor -replace '[^0-9.,]','' -replace ',','.')
            status = if ($linha.status) { $linha.status } else { "pendente" }
            status_pagamento = if ($linha.status_pagamento) { $linha.status_pagamento } else { "pendente" }
            metodo_pagamento = if ($linha.metodo_pagamento) { $linha.metodo_pagamento } else { "credito" }
            observacoes = if ($linha.observacoes) { $linha.observacoes } else { "" }
            data_importacao = Get-Date -Format "yyyy-MM-dd"
            data_reserva_origem = if ($linha.data_reserva_origem) { $linha.data_reserva_origem } else { (Get-Date -Format "yyyy-MM-dd") }
            sync_status = "pendente"
        }
        $integracoes.reservas_externas += $nova
        $importadas++
    }

    $integracoes.historico_sincronia = @($integracoes.historico_sincronia) + @{
        data = Get-Date -Format "yyyy-MM-dd HH:mm"
        canal = $canal
        tipo = "importacao_csv"
        reservas_importadas = $importadas
        status = "sucesso"
    }
    Save-DadosIntegracoes $integracoes

    return @{sucesso = $true; importadas = $importadas; ignoradas = $ignoradas}
}

function Exportar-InventarioCSV {
    $caminho = Join-Path $DataDir "export_inventario.csv"
    $q = Get-DadosQuartos
    $rows = @()
    if ($q) {
        foreach ($qr in $q.quartos) {
            $disp = if ($qr.status -eq "disponivel") { 1 } else { 0 }
            $rows += [PSCustomObject]@{
                id_quarto = $qr.numero
                tipo = $qr.tipo
                capacidade = $qr.capacidade
                disponivel = $disp
                preco_diaria = $qr.preco_diaria
                status = $qr.status
            }
        }
    }
    $rows | Export-Csv $caminho -NoTypeInformation -Encoding UTF8
    $caminho
}

function Importar-ReservasSimuladas {
    param($canaisParaImportar = @())

    $cfg = Get-DadosConfig
    $intCfg = if ($cfg -and $cfg.integracoes) { $cfg.integracoes } else { return @{sucesso=$false; erro="Nenhuma configuracao de integracao"; importadas=0} }

    $reservasData = Get-DadosReservas
    if (-not $reservasData) { $reservasData = @{reservas=@()} }

    $financeiroData = Get-DadosFinanceiro
    if (-not $financeiroData) { $financeiroData = @{lancamentos=@(); saldos_mensais=@(); categorias_receita=@(); categorias_despesa=@()} }

    $quartosData = Get-DadosQuartos
    $quartosDisp = @()
    if ($quartosData -and $quartosData.quartos -and $quartosData.quartos.Count -gt 0) {
        $quartosDisp = @($quartosData.quartos | Where-Object { $_.status -eq "disponivel" })
        if ($quartosDisp.Count -eq 0) { $quartosDisp = @($quartosData.quartos) }
    }

    $hoje = (Get-Date).Date
    $nomesSimulados = @(
        "Carlos Alberto Silva","Maria Aparecida Santos","Joao Pedro Oliveira","Ana Claudia Souza",
        "Paulo Roberto Lima","Fernanda Cristina Costa","Lucas Eduardo Pereira","Juliana Mendes Rocha",
        "Marcos Vinicius Alves","Patricia Gomes Barbosa","Ricardo Augusto Dias","Camila Ribeiro Martins",
        "Fernando Henrique Cardoso","Larissa Souza Melo","Thiago Monteiro Carvalho",
        "Bianca Oliveira Araujo","Rafael Nunes Barros","Amanda Freitas Campos",
        "Eduardo Henrique Moreira","Vanessa Rodrigues de Paula"
    )
    $emailsSimulados = @(
        "exemplo1@mail.com","exemplo2@mail.com","exemplo3@mail.com","exemplo4@mail.com"
    )
    $fonesSimulados = @(
        "(99) 98412-0001","(99) 98412-0002","(99) 98412-0003","(99) 98412-0004"
    )
    $docsSimulados = @(
        "123.456.789-01","987.654.321-00","111.222.333-44","555.666.777-88"
    )
    $obsCanais = @{
        "booking" = "Reserva via Booking.com | ID: BKG-HTLS"
        "expedia" = "Reserva via Expedia | ID: EXP-TRVL"
        "airbnb" = "Reserva via Airbnb | ID: ABNB-STAY"
        "omnibees" = "Reserva via Omnibees | ID: OMNI-HTL"
        "direto" = "Reserva direta recepcao"
    }
    $pagtos = @("credito","debito","pix","dinheiro","boleto")

    $importadas = 0
    $canaisProcessados = @()
    $ultimoIdR = if ($reservasData.reservas.Count -gt 0) { ($reservasData.reservas | Sort-Object id -Descending | Select-Object -First 1).id } else { 1000 }
    $ultimoIdH = 0
    $hospData = Get-DadosHospedes
    if (-not $hospData) { $hospData = @{hospedes=@()} }
    if ($hospData.hospedes.Count -gt 0) { $ultimoIdH = ($hospData.hospedes | Sort-Object id -Descending | Select-Object -First 1).id }
    $ultimoIdF = if ($financeiroData.lancamentos.Count -gt 0) { ($financeiroData.lancamentos | Sort-Object id -Descending | Select-Object -First 1).id } else { 1000 }

    if ($canaisParaImportar.Count -eq 0) {
        $canaisParaImportar = @("booking","expedia","airbnb","omnibees","direto")
    }

    $canaisInfo = @{
        "booking" = @{nome="Booking.com"; ico="B"}
        "expedia" = @{nome="Expedia"; ico="E"}
        "airbnb" = @{nome="Airbnb"; ico="A"}
        "omnibees" = @{nome="Omnibees"; ico="O"}
        "direto" = @{nome="Reserva Direta"; ico="D"}
    }

    foreach ($canalId in $canaisParaImportar) {
        $canalCfg = $intCfg.$canalId
        $ativo = if ($canalCfg) { $canalCfg.ativo } else { $false }
        if ($canalCfg -and -not $ativo) { continue }

        $comissao = if ($canalCfg) { [math]::Max(0, ($canalCfg.comissao_percentual -as [int])) } else { 0 }
        $qtdGerar = 1..3 | Get-Random

        $ci = $canaisInfo[$canalId]
        $canalNome = if ($ci) { $ci.nome } else { $canalId }

        for ($i = 0; $i -lt $qtdGerar; $i++) {
            $nomeIdx = (Get-Random -Minimum 0 -Maximum ($nomesSimulados.Count - 1))
            $nomeHosp = $nomesSimulados[$nomeIdx]

            $diasAteCheckin = 0..20 | Get-Random
            $dataCheckin = $hoje.AddDays($diasAteCheckin)
            $noites = 1..7 | Get-Random
            $dataCheckout = $dataCheckin.AddDays($noites)
            $adultos = 1..4 | Get-Random
            $criancas = @(0,0,0,1,1,2) | Get-Random

            $quartoId = 0
            $diaria = 0
            if ($quartosDisp.Count -gt 0) {
                $quarto = $quartosDisp[(Get-Random -Minimum 0 -Maximum ($quartosDisp.Count - 1))]
                $quartoId = $quarto.id
                $diaria = if ($quarto.preco_diaria -and $quarto.preco_diaria -gt 0) { $quarto.preco_diaria } else { 150 }
            } else {
                $quartoId = 1..6 | Get-Random
                $diaria = 150
            }

            $total = [math]::Round($diaria * $noites, 2)
            $taxaServico = [math]::Round($total * 0.1, 2)
            $metodoPag = $pagtos[(Get-Random -Minimum 0 -Maximum ($pagtos.Count - 1))]
            $statusList = @("pendente","confirmada","pendente","confirmada")
            if ($diasAteCheckin -eq 0) { $statusList = @("checkin","confirmada") }
            if ($diasAteCheckin -lt 0) { $statusList = @("pendente") }
            $status = $statusList[(Get-Random -Minimum 0 -Maximum ($statusList.Count - 1))]

            $obsBase = $obsCanais[$canalId]
            $obsCompleta = if ($obsBase) { "$obsBase | Nome: $nomeHosp" } else { "Reserva via $canalNome" }

            $ultimoIdR++
            $ultimoIdH++
            $ultimoIdF++

            $novoHosp = [PSCustomObject]@{
                id = $ultimoIdH; nome = $nomeHosp
                documento = $docsSimulados[(Get-Random -Minimum 0 -Maximum ($docsSimulados.Count - 1))]
                tipo_documento = "CPF"
                telefone = $fonesSimulados[(Get-Random -Minimum 0 -Maximum ($fonesSimulados.Count - 1))]
                email = $emailsSimulados[(Get-Random -Minimum 0 -Maximum ($emailsSimulados.Count - 1))]
                endereco = ""; nacionalidade = "Brasileira"
                data_cadastro = (Get-Date -Format "yyyy-MM-dd"); observacoes = ""
                total_visitas = 1; total_gasto = $total
            }
            $hospData.hospedes += $novoHosp

            $novaRes = [PSCustomObject]@{
                id = $ultimoIdR; id_hospede = $ultimoIdH; id_quarto = $quartoId
                data_checkin = $dataCheckin.ToString("yyyy-MM-dd")
                data_checkout = $dataCheckout.ToString("yyyy-MM-dd")
                noites = $noites; status = $status; origem = "integracao"; canal = $canalId
                valor_total = $total; valor_diaria = $diaria; desconto = 0
                taxa_servico = $taxaServico; metodo_pagamento = $metodoPag
                situacao_pagamento = if ($status -eq "confirmada") { "pago" } else { "pendente" }
                observacoes = $obsCompleta
                data_reserva = (Get-Date -Format "yyyy-MM-dd")
                checkin_realizado = $null; checkout_realizado = $null
                adultos = $adultos; criancas = $criancas; whatsapp_enviado = $false
            }
            $reservasData.reservas += $novaRes

            if ($status -ne "cancelada" -and $total -gt 0) {
                $comissaoValor = [math]::Round($total * $comissao / 100, 2)
                $liquido = [math]::Round($total - $comissaoValor, 2)
                $novoLanc = [PSCustomObject]@{
                    id = $ultimoIdF; data = (Get-Date -Format "yyyy-MM-dd")
                    tipo = "receita"; categoria = "hospedagem"
                    descricao = "Reserva #$ultimoIdR - $nomeHosp ($canalNome)"
                    valor = $total; status = "recebido"
                    reserva_id = $ultimoIdR; canal = $canalId
                    comissao_percentual = $comissao; comissao_valor = $comissaoValor
                    valor_liquido = $liquido; criado_em = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                }
                $financeiroData.lancamentos += $novoLanc
            }

            if ($comissao -gt 0 -and $total -gt 0) {
                $ultimoIdF++
                $comissaoValor = [math]::Round($total * $comissao / 100, 2)
                $novoCom = [PSCustomObject]@{
                    id = $ultimoIdF; data = (Get-Date -Format "yyyy-MM-dd")
                    tipo = "despesa"; categoria = "comissao"
                    descricao = "Comissao $canalNome - Reserva #$ultimoIdR"
                    valor = $comissaoValor; status = "pendente"
                    reserva_id = $ultimoIdR; canal = $canalId
                    criado_em = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                }
                $financeiroData.lancamentos += $novoCom
            }

            $importadas++
        }
        $canaisProcessados += $canalNome
    }

    Save-Hospedes $hospData
    Save-Reservas $reservasData
    Save-Financeiro $financeiroData

    $ext = Get-DadosIntegracoes
    if (-not $ext) { $ext = @{reservas_externas=@(); historico_sincronia=@()} }
    if (-not $ext.historico_sincronia) { $ext.historico_sincronia = @() }
    $ext.historico_sincronia += [PSCustomObject]@{
        data = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        canal = ($canaisProcessados -join ", ")
        tipo = "importacao_simulada"
        reservas_importadas = $importadas
        status = "sucesso"
        mensagem = "Importacao simulada concluida: $importadas reservas em $($canaisProcessados.Count) canais"
    }
    Save-Integracoes $ext

    $agora = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $cfgS = Get-DadosConfig
    if ($cfgS -and $cfgS.integracoes) {
        try { $cfgS.integracoes.ultima_sincronizacao_global = $agora } catch { }
        Save-Config $cfgS
    }

    @{sucesso=$true; importadas=$importadas; canais=$canaisProcessados; mensagem="Importadas $importadas reservas de canais: $($canaisProcessados -join ', ')"}
}

function Confirmar-AtualizarCanais {
    param($operacao = "atualizacao no sistema", $detalhes = "")
    $cfg = Get-DadosConfig
    $intCfg = if ($cfg -and $cfg.integracoes) { $cfg.integracoes } else { return }
    $urls = @{}
    if ($intCfg.booking -and $intCfg.booking.ativo) {
        $url = if ($intCfg.booking.painel_url) { $intCfg.booking.painel_url } else { "https://admin.booking.com" }
        $urls["Booking.com"] = $url
    }
    if ($intCfg.omnibees -and $intCfg.omnibees.ativo) {
        $url = if ($intCfg.omnibees.painel_url) { $intCfg.omnibees.painel_url } else { "https://hub.omnibees.com" }
        $urls["Omnibees"] = $url
    }
    if ($urls.Count -eq 0) { return }
    $msg = "Voce realizou uma $operacao no sistema local.`n`nDeseja atualizar tambem nas plataformas abaixo?"
    if ($detalhes) { $msg += "`n`nDetalhes: $detalhes" }
    $msg += "`n`nPlataformas: $($urls.Keys -join ', ')"
    $resp = [System.Windows.Forms.MessageBox]::Show($msg, "Atualizar Canais", "YesNo", "Question")
    if ($resp -eq "Yes") {
        foreach ($kv in $urls.GetEnumerator()) {
            try { Start-Process $kv.Value } catch { }
        }
        [System.Windows.Forms.MessageBox]::Show("Paginas abertas: $($urls.Keys -join ', ')`n`nApos concluir as alteracoes nas plataformas, volte ao sistema.", "Canais Abertos", "OK", "Information")
    }
}

function Get-EstatisticasCanais {
    $externas = Get-DadosIntegracoes
    $financeiro = Get-DadosFinanceiro
    $locais = Get-DadosReservas

    $stats = @{}
    $canaisInfo = @("direto","booking","omnibees","expedia","airbnb")

    foreach ($c in $canaisInfo) {
        $qtd = 0; $receita = 0; $comissao = 0

        if ($locais -and $locais.reservas) {
            $rCanal = @($locais.reservas | Where-Object { $_.canal -eq $c -and $_.status -ne "cancelada" })
            $qtd += $rCanal.Count
            $receita += ($rCanal | Measure-Object -Property valor_total -Sum).Sum
        }

        if ($externas -and $externas.reservas_externas) {
            $rExt = @($externas.reservas_externas | Where-Object { $_.canal -eq $c })
            $qtd += $rExt.Count
            $receita += ($rExt | Measure-Object -Property valor_total -Sum).Sum
            $comissao += ($rExt | Measure-Object -Property comissao_valor -Sum).Sum
        }

        $stats[$c] = @{
            quantidade = $qtd
            receita = [math]::Round(($receita + 0), 2)
            comissao = [math]::Round(($comissao + 0), 2)
            receita_liquida = [math]::Round(($receita - $comissao + 0), 2)
        }
    }
    $stats
}

function Sync-ReservasExternas {
    param($canal)

    $integracoes = Get-DadosIntegracoes
    if (-not $integracoes) {
        return @{sucesso = $false; erro = "Nenhum dado de integração encontrado"; processadas = 0}
    }
    $pendentes = @($integracoes.reservas_externas | Where-Object { $_.canal -eq $canal -and $_.sync_status -eq "pendente" })
    $atualizadas = 0

    foreach ($r in $pendentes) {
        foreach ($rv in $integracoes.reservas_externas) {
            if ($rv.id -eq $r.id) { $rv.sync_status = "sincronizado"; $atualizadas++; break }
        }
    }

    $integracoes.historico_sincronia = @($integracoes.historico_sincronia) + @{
        data = Get-Date -Format "yyyy-MM-dd HH:mm"
        canal = $canal
        tipo = "sincronizacao"
        reservas_processadas = $atualizadas
        status = "sucesso"
    }
    Save-DadosIntegracoes $integracoes
    @{sucesso = $true; processadas = $atualizadas}
}

function Verificar-DisponibilidadeQuarto {
    param($quartoId, $dataEntrada, $dataSaida, $excluirReservaId = $null)
    if (-not $quartoId -or -not $dataEntrada -or -not $dataSaida) { return @() }
    $d = Get-DadosReservas
    if (-not $d -or -not $d.reservas) { return @() }
    $dtEnt = try { [DateTime]$dataEntrada } catch { return @() }
    $dtSai = try { [DateTime]$dataSaida } catch { return @() }
    $conflitos = @()
    foreach ($r in $d.reservas) {
        if ($r.status -eq "cancelada" -or $r.status -eq "checkout") { continue }
        if ($excluirReservaId -and $r.id -eq $excluirReservaId) { continue }
        if ($r.id_quarto -ne $quartoId) { continue }
        $rCI = try { [DateTime]$r.data_checkin } catch { continue }
        $rCO = try { [DateTime]$r.data_checkout } catch { continue }
        if ($dtEnt -lt $rCO -and $dtSai -gt $rCI) {
            $conflitos += $r
        }
    }
    $conflitos
}

function Get-ReservasUnificadasView {
    $locais = Get-DadosReservas
    $externas = Get-DadosIntegracoes
    $todas = @()
    if ($locais -and $locais.reservas) {
        foreach ($r in $locais.reservas) {
            $todas += [PSCustomObject]@{
                id = $r.id; origem = "local"; canal = if ($r.canal) { $r.canal } else { "direto" }
                hospede = (Get-HospedeNome $r.id_hospede)
                quarto = (Get-QuartoNumero $r.id_quarto)
                checkin = $r.data_checkin; checkout = $r.data_checkout
                noites = $r.noites; valor = $r.valor_total; status = $r.status
                pagamento = $r.situacao_pagamento; metodo = $r.metodo_pagamento
                observacoes = $r.observacoes; data_reserva = $r.data_reserva
            }
        }
    }
    if ($externas -and $externas.reservas_externas) {
        foreach ($r in $externas.reservas_externas) {
            $todas += [PSCustomObject]@{
                id = $r.id; origem = $r.canal; canal = $r.canal
                hospede = if ($r.nome_hospede) { $r.nome_hospede } else { "N/I" }
                quarto = if ($r.tipo_quarto) { $r.tipo_quarto } else { "-" }
                checkin = $r.data_checkin; checkout = $r.data_checkout
                noites = $r.noites; valor = $r.valor_total; status = $r.status
                pagamento = $r.status_pagamento; metodo = $r.metodo_pagamento
                observacoes = $r.observacoes; data_reserva = $r.data_reserva_origem
            }
        }
    }
    $todas | Sort-Object checkin
}

