param(
    [string]$Acao = "enviar",
    [string]$DadosJSON = ""
)


function Get-MensagemConfirmacao($reserva, $hospede, $quarto, $config) {
    $hotel = $config.hotel
    $checkin = [DateTime]$reserva.data_checkin
    $checkout = [DateTime]$reserva.data_checkout

    $mensagem = @"
*$($hotel.nome)* - Confirmação de Reserva #$($reserva.id)

Olá, $($hospede.nome)! Sua reserva foi confirmada com sucesso!

*Dados da Reserva:*
ðŸ“… Check-in: $($reserva.data_checkin) (a partir das $($hotel.checkin_padrao))
ðŸ“… Check-out: $($reserva.data_checkout) (até as $($hotel.checkout_padrao))
ðŸŒ™ Noites: $($reserva.noites)
ðŸ›ï¸ Quarto: $($quarto.numero) - $($quarto.tipo)
ðŸ‘¤ Adultos: $($reserva.adultos) | Crianças: $($reserva.criancas)

*Valores:*
ðŸ’° Diária: R$ $($reserva.valor_diaria.ToString('N2'))
ðŸ’µ Total: R$ $($reserva.valor_total.ToString('N2'))
ðŸ’³ Pagamento: $($reserva.metodo_pagamento)
ðŸ“‹ Situação: $($reserva.situacao_pagamento)

*Informações do Hotel:*
ðŸ“ $($hotel.endereco)
ðŸ“ž $($hotel.telefone)
ðŸ“§ $($hotel.email)
ðŸŒ $($hotel.website)

*Políticas:*
â° Check-in a partir das $($hotel.checkin_padrao)
â° Check-out até as $($hotel.checkout_padrao)
ðŸ…¿ï¸ Estacionamento gratuito
ðŸ“¶ Wi-Fi cortesia

Agradecemos a preferência e esperamos por você!
$($hotel.nome)
"@
    return $mensagem
}

function Get-MensagemLembrete($reserva, $hospede, $quarto, $config) {
    $hotel = $config.hotel
    $checkin = [DateTime]$reserva.data_checkin
    $diff = ($checkin - (Get-Date)).Days

    $mensagem = @"
*$($hotel.nome)* - Lembrete de Check-in

Olá, $($hospede.nome)! Lembramos que seu check-in será em $diff dia(s).

*Reserva #$($reserva.id)*
ðŸ“… Data: $($reserva.data_checkin)
ðŸ›ï¸ Quarto: $($quarto.numero)
ðŸŒ™ Noites: $($reserva.noites)

Estamos prontos para receber você! ðŸ˜Š
"@
    return $mensagem
}

switch ($Acao) {
    "enviar" {
        $dados = $DadosJSON | ConvertFrom-Json
        $config = Get-DadosConfig
        $reservas = Get-DadosReservas
        $hospedes = Get-DadosHospedes
        $quartos = Get-DadosQuartos

        if (-not $config -or -not $config.whatsapp.ativo) {
            @{sucesso = $false; erro = "WhatsApp não configurado ou desativado"} | ConvertTo-Json
            return
        }

        $reserva = $reservas.reservas | Where-Object { $_.id -eq $dados.id_reserva }
        if (-not $reserva) {
            @{sucesso = $false; erro = "Reserva não encontrada"} | ConvertTo-Json
            return
        }

        $hospede = $hospedes.hospedes | Where-Object { $_.id -eq $reserva.id_hospede }
        $quarto = $quartos.quartos | Where-Object { $_.id -eq $reserva.id_quarto }

        if (-not $hospede) {
            @{sucesso = $false; erro = "Hóspede não encontrado"} | ConvertTo-Json
            return
        }

        $whatsapp = $config.whatsapp
        $numero = $hospede.telefone -replace '\D', ''

        if ($dados.tipo -eq "confirmacao") {
            $mensagem = Get-MensagemConfirmacao $reserva $hospede $quarto $config
        } else {
            $mensagem = Get-MensagemLembrete $reserva $hospede $quarto $config
        }

        if ($numero -match '^\d{10,13}$') {
            $url = "$($whatsapp.api_url)?phone=55$numero&text=$( [System.Web.HttpUtility]::UrlEncode($mensagem) )"

            for ($i = 0; $i -lt $reservas.reservas.Count; $i++) {
                if ($reservas.reservas[$i].id -eq $reserva.id) {
                    $reservas.reservas[$i].whatsapp_enviado = $true
                    break
                }
            }
            Save-Reservas $reservas

            [PSCustomObject]@{
                sucesso = $true
                mensagem = "Mensagem preparada para envio via WhatsApp"
                url = $url
                destinatario = $hospede.nome
                numero = $hospede.telefone
                texto = $mensagem
                confirmacao_automatica = $whatsapp.confirmacao_automatica
            } | ConvertTo-Json -Depth 3
        } else {
            @{sucesso = $false; erro = "Número de telefone inválido: $($hospede.telefone)"} | ConvertTo-Json
        }
    }

    "gerar_mensagem" {
        $dados = $DadosJSON | ConvertFrom-Json
        $config = Get-DadosConfig
        $reservas = Get-DadosReservas
        $hospedes = Get-DadosHospedes
        $quartos = Get-DadosQuartos

        $reserva = $reservas.reservas | Where-Object { $_.id -eq $dados.id_reserva }
        if (-not $reserva) {
            @{erro = "Reserva não encontrada"} | ConvertTo-Json
            return
        }

        $hospede = $hospedes.hospedes | Where-Object { $_.id -eq $reserva.id_hospede }
        $quarto = $quartos.quartos | Where-Object { $_.id -eq $reserva.id_quarto }

        if (-not $hospede -or -not $quarto) {
            @{erro = "Dados incompletos"} | ConvertTo-Json
            return
        }

        $mensagem = Get-MensagemConfirmacao $reserva $hospede $quarto $config
        @{
            mensagem = $mensagem
            destinatario = $hospede.nome
            telefone = $hospede.telefone
        } | ConvertTo-Json -Depth 2
    }

    "config" {
        $config = Get-DadosConfig
        if ($config) {
            $config.whatsapp | ConvertTo-Json
        } else {
            @{erro = "Configuração não encontrada"} | ConvertTo-Json
        }
    }

    "pendentes" {
        $reservas = Get-DadosReservas
        $hospedes = Get-DadosHospedes
        if (-not $reservas) { @() | ConvertTo-Json -Compress; return }

        $pendentes = $reservas.reservas | Where-Object {
            $_.whatsapp_enviado -eq $false -and
            $_.status -ne "cancelada" -and $_.status -ne "no_show" -and
            $_.status -ne "checkout"
        }

        $result = $pendentes | ForEach-Object {
            $r = $_
            $h = $hospedes.hospedes | Where-Object { $_.id -eq $r.id_hospede }
            [PSCustomObject]@{
                id = $r.id
                hospede = if ($h) { $h.nome } else { "N/A" }
                telefone = if ($h) { $h.telefone } else { "N/A" }
                data_checkin = $r.data_checkin
                status = $r.status
            }
        }
        $result | ConvertTo-Json -Depth 2
    }
}



