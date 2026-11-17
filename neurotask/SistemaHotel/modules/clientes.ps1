param(
    [string]$Acao = "listar",
    [string]$DadosJSON = ""
)

switch ($Acao) {
    "listar" {
        $data = Get-DadosClientes
        if ($data) { $data.clientes | ConvertTo-Json -Depth 3 }
    }
    "obter" {
        $data = Get-DadosClientes
        $dados = $DadosJSON | ConvertFrom-Json
        $cli = @($data.clientes | Where-Object { $_.id -eq $dados.id })
        if ($cli) { $cli[0] | ConvertTo-Json -Depth 3 } else { @{erro="Não encontrado"} | ConvertTo-Json }
    }
    "criar" {
        $data = Get-DadosClientes
        if (-not $data) { $data = @{clientes = @()} }
        $dados = $DadosJSON | ConvertFrom-Json
        $ultimoId = if ($data.clientes.Count -gt 0) { ($data.clientes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novo = [PSCustomObject]@{
            id = $ultimoId + 1
            nome = $dados.nome; telefone = $dados.telefone; email = $dados.email
            data_cadastro = (Get-Date -Format "yyyy-MM-dd")
            observacoes = if ($dados.observacoes) { $dados.observacoes } else { "" }
            ativo = if ($dados.ativo -eq $false) { $false } else { $true }
            whatsapp_opt_in = if ($dados.whatsapp_opt_in -eq $false) { $false } else { $true }
        }
        $data.clientes += $novo
        Save-Clientes $data
        $novo | ConvertTo-Json -Depth 3
    }
    "atualizar" {
        $data = Get-DadosClientes
        $dados = $DadosJSON | ConvertFrom-Json
        for ($i = 0; $i -lt $data.clientes.Count; $i++) {
            if ($data.clientes[$i].id -eq $dados.id) {
                if ($dados.nome) { $data.clientes[$i].nome = $dados.nome }
                if ($dados.telefone) { $data.clientes[$i].telefone = $dados.telefone }
                if ($dados.email) { $data.clientes[$i].email = $dados.email }
                if ($dados.observacoes -ne $null) { $data.clientes[$i].observacoes = $dados.observacoes }
                if ($dados.ativo -ne $null) { $data.clientes[$i].ativo = [bool]$dados.ativo }
                if ($dados.whatsapp_opt_in -ne $null) { $data.clientes[$i].whatsapp_opt_in = [bool]$dados.whatsapp_opt_in }
                break
            }
        }
        Save-Clientes $data
        @{sucesso = $true} | ConvertTo-Json
    }
    "excluir" {
        $data = Get-DadosClientes
        $dados = $DadosJSON | ConvertFrom-Json
        $data.clientes = @($data.clientes | Where-Object { $_.id -ne $dados.id })
        Save-Clientes $data
        @{sucesso = $true} | ConvertTo-Json
    }
}



