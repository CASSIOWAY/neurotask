param(
    [string]$Acao = "listar",
    [string]$DadosJSON = ""
)


switch ($Acao) {
    "listar" {
        $data = Get-DadosHospedes
        if ($data) { $data.hospedes | ConvertTo-Json -Depth 3 }
    }
    "obter" {
        $data = Get-DadosHospedes
        $dados = $DadosJSON | ConvertFrom-Json
        $hosp = @($data.hospedes | Where-Object { $_.id -eq $dados.id })
        if ($hosp) { $hosp[0] | ConvertTo-Json -Depth 3 } else { @{erro="Não encontrado"} | ConvertTo-Json }
    }
    "criar" {
        $data = Get-DadosHospedes
        $dados = $DadosJSON | ConvertFrom-Json
        $ultimoId = if ($data.hospedes.Count -gt 0) { ($data.hospedes | Sort-Object id -Descending | Select-Object -First 1).id } else { 0 }
        $novo = [PSCustomObject]@{
            id = $ultimoId + 1
            nome = $dados.nome; documento = $dados.documento; telefone = $dados.telefone
            email = $dados.email; endereco = $dados.endereco
            data_cadastro = (Get-Date -Format "yyyy-MM-dd")
            observacoes = if ($dados.observacoes) { $dados.observacoes } else { "" }
        }
        $data.hospedes += $novo
        Save-Hospedes $data
        $novo | ConvertTo-Json -Depth 3
    }
}



