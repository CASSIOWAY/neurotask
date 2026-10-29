# comparar_enderecos.ps1 — lista alunos SEM endereco
function NormalizarNome($s) {
    $s = $s -replace '[^\p{L}\p{N} ]', ''
    $s = $s -replace '\s+', ' '
    return $s.ToUpper().Trim()
}

$dados = Get-Content (Join-Path $PSScriptRoot "dados.txt") -Encoding UTF8
$alunosDados = @{}; $inSec = $false
foreach ($line in $dados) {
    if ($line -match '^ORDEM\s+NOME') { $inSec = $true; continue }
    if ($line -match '^Unidade ensino:') { $inSec = $false; continue }
    if ($inSec) {
        $parts = $line -split "`t"
        if ($parts.Length -ge 2 -and $parts[0] -match '^\d+$') {
            $nome = $parts[1].Trim(); $cpf = $parts[3].Trim()
            $key = NormalizarNome($nome)
            if (-not $alunosDados.ContainsKey($key)) {
                $alunosDados[$key] = @{Nome=$nome; CPF=$cpf}
            }
        }
    }
}

$endLines = Get-Content (Join-Path $PSScriptRoot "enderecos.txt") -Encoding UTF8
$endMap = @{}
foreach ($el in $endLines) {
    $p = $el -split '\|'
    if ($p.Length -ge 2) {
        $key = NormalizarNome($p[1])
        if (-not $endMap.ContainsKey($key)) { $endMap[$key] = $true }
    }
}

$missing = @()
foreach ($key in $alunosDados.Keys) {
    if (-not $endMap.ContainsKey($key)) {
        $missing += $alunosDados[$key]
    }
}

Write-Host ("Total alunos em dados.txt: {0}" -f $alunosDados.Count)
Write-Host ("Com endereco: {0}" -f ($alunosDados.Count - $missing.Count))
Write-Host ("SEM ENDERECO: {0}" -f $missing.Count)
Write-Host ""

if ($missing.Count -gt 0) {
    Write-Host "----- ALUNOS SEM ENDERECO -----"
    $missing | Sort-Object Nome | ForEach-Object { Write-Host ("$($_.Nome)  |  CPF: $($_.CPF)") }
}
