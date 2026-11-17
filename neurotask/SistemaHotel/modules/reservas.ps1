param(
    [string]$Acao = "listar",
    [string]$DadosJSON = ""
)


switch ($Acao) {
    "listar" {
        $data = Get-DadosReservas
        $quartosData = Get-DadosQuartos
        $hospedesData = Get-DadosHospedes

        $result = $data.reservas | ForEach-Object {
            $r = $_
            $quarto = @($quartosData.quartos | Where-Object { $_.id -eq $r.id_quarto })
            $hospede = @($hospedesData.hospedes | Where-Object { $_.id -eq $r.id_hospede })
            [PSCustomObject]@{
                id = $r.id
                hospede_nome = if ($hospede) { $hospede[0].nome } else { "N/A" }
                quarto_numero = if ($quarto) { $quarto[0].numero } else { "N/A" }
                quarto_tipo = if ($quarto) { $quarto[0].tipo } else { "N/A" }
                data_checkin = $r.data_checkin
                data_checkout = $r.data_checkout
                noites = $r.noites
                status = $r.status
                origem = $r.origem
                canal = $r.canal
                valor_total = $r.valor_total
                situacao_pagamento = $r.situacao_pagamento
                adultos = $r.adultos
                criancas = $r.criancas
                whatsapp_enviado = $r.whatsapp_enviado
            }
        }
        $result | ConvertTo-Json -Depth 3
    }

    "obter" {
        $data = Get-DadosReservas
        $dados = $DadosJSON | ConvertFrom-Json
        $reserva = @($data.reservas | Where-Object { $_.id -eq $dados.id })
        if ($reserva) {
            $reserva[0] | ConvertTo-Json -Depth 5
        } else {
            @{erro = "Reserva não encontrada"} | ConvertTo-Json
        }
    }

    "criar" {
        $data = Get-DadosReservas
        $dados = $DadosJSON | ConvertFrom-Json
        $ultimoId = if ($data.reservas.Count -gt 0) { ($data.reservas | Sort-Object id -Descending | Select-Object -First 1).id } else { 1000 }
        $novaReserva = [PSCustomObject]@{
            id = $ultimoId + 1
            id_hospede = $dados.id_hospede
            id_quarto = $dados.id_quarto
            data_checkin = $dados.data_checkin
            data_checkout = $dados.data_checkout
            noites = $dados.noites
            status = "pendente"
            origem = $dados.origem
            canal = $dados.canal
            valor_total = $dados.valor_total
            valor_diaria = $dados.valor_diaria
            desconto = if ($dados.desconto) { $dados.desconto } else { 0 }
            taxa_servico = $dados.taxa_servico
            metodo_pagamento = $dados.metodo_pagamento
            situacao_pagamento = "pendente"
            observacoes = if ($dados.observacoes) { $dados.observacoes } else { "" }
            data_reserva = (Get-Date -Format "yyyy-MM-dd")
            checkin_realizado = $null
            checkout_realizado = $null
            adultos = $dados.adultos
            criancas = if ($dados.criancas) { $dados.criancas } else { 0 }
            whatsapp_enviado = $false
        }
        $data.reservas += $novaReserva
        Save-Reservas $data
        $novaReserva | ConvertTo-Json -Depth 5
    }

    "atualizar_status" {
        $data = Get-DadosReservas
        $dados = $DadosJSON | ConvertFrom-Json
        for ($i = 0; $i -lt $data.reservas.Count; $i++) {
            if ($data.reservas[$i].id -eq $dados.id) {
                $data.reservas[$i].status = $dados.novo_status
                if ($dados.novo_status -eq "checkin" -and -not $data.reservas[$i].checkin_realizado) {
                    $data.reservas[$i].checkin_realizado = Get-Date -Format "yyyy-MM-dd HH:mm"
                }
                if ($dados.novo_status -eq "checkout") {
                    $data.reservas[$i].checkout_realizado = Get-Date -Format "yyyy-MM-dd HH:mm"
                }
                Save-Reservas $data
                @{sucesso = $true; mensagem = "Status atualizado para $($dados.novo_status)"} | ConvertTo-Json
                return
            }
        }
        @{erro = "Reserva não encontrada"} | ConvertTo-Json
    }

    "cancelar" {
        $data = Get-DadosReservas
        $dados = $DadosJSON | ConvertFrom-Json
        for ($i = 0; $i -lt $data.reservas.Count; $i++) {
            if ($data.reservas[$i].id -eq $dados.id) {
                $data.reservas[$i].status = "cancelada"
                Save-Reservas $data
                @{sucesso = $true; mensagem = "Reserva cancelada"} | ConvertTo-Json
                return
            }
        }
        @{erro = "Reserva não encontrada"} | ConvertTo-Json
    }

    "marcar_whatsapp" {
        $data = Get-DadosReservas
        $dados = $DadosJSON | ConvertFrom-Json
        for ($i = 0; $i -lt $data.reservas.Count; $i++) {
            if ($data.reservas[$i].id -eq $dados.id) {
                $data.reservas[$i].whatsapp_enviado = $true
                Save-Reservas $data
                @{sucesso = $true; mensagem = "WhatsApp marcado como enviado"} | ConvertTo-Json
                return
            }
        }
        @{erro = "Reserva não encontrada"} | ConvertTo-Json
    }

    "estatisticas" {
        $data = Get-DadosReservas
        $total = $data.reservas.Count
        $confirmadas = @($data.reservas | Where-Object { $_.status -eq "confirmada" }).Count
        $checkin = @($data.reservas | Where-Object { $_.status -eq "checkin" }).Count
        $pendentes = @($data.reservas | Where-Object { $_.status -eq "pendente" }).Count
        $canceladas = @($data.reservas | Where-Object { $_.status -eq "cancelada" }).Count
        $totalValor = ($data.reservas | Where-Object { $_.status -ne "cancelada" } | Measure-Object -Property valor_total -Sum).Sum

        [PSCustomObject]@{
            total = $total
            confirmadas = $confirmadas
            checkin = $checkin
            pendentes = $pendentes
            canceladas = $canceladas
            total_valor = [math]::Round($totalValor, 2)
            whatsapp_enviados = @($data.reservas | Where-Object { $_.whatsapp_enviado -eq $true }).Count
        } | ConvertTo-Json
    }
}



