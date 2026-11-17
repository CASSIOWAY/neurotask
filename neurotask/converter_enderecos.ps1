# converter_enderecos.ps1 (ASCII-safe patterns)
$regBook  = @(Get-ChildItem "C:\Users\USER\Desktop" | Where-Object { $_.Name -like "*NOVOS*EN*" -and $_.Length -gt 10000 } | Sort-Object Length -Descending | Select-Object -First 1).FullName
if (-not $regBook) { $regBook = @(Get-ChildItem "C:\Users\USER\Desktop" | Where-Object { $_.Name -like "*endere*" -and $_.Length -gt 10000 } | Sort-Object Length -Descending | Select-Object -First 1).FullName }
$dadosFile = Join-Path $PSScriptRoot "dados.txt"
$outputFile = Join-Path $PSScriptRoot "enderecos.txt"
if (-not $regBook) { throw "Arquivo de enderecos nao encontrado no Desktop" }
Write-Host ("Usando: {0}" -f $regBook)

function NormalizarNome($s) {
    $s = $s -replace '[^\p{L}\p{N} ]', ''
    $s = $s -replace '\s+', ' '
    return $s.ToUpper().Trim()
}

function NormalizarTurma($t) {
    $t = $t -replace '\s*2025\s*$', ''
    $t = $t -replace '[^a-zA-Z0-9 ]', ' '
    $t = $t -replace '\s+', ' '
    return $t.Trim()
}

function ExtrairEndereco($endLine) {
    $addr = $endLine
    $addr = $addr -replace '^ENDERE[^a-zA-Z0-9]O:\s*', ''
    $addr = $addr -replace '[ \t]*NACIONALIDADE:.*$', ''
    $addr = $addr.Trim()
    $logradouro = ""; $numero = ""; $bairro = ""; $cep = ""; $cidade = "ARAGUAINA"; $uf = "TO"

    if ($addr -match 'BAIRRO:\s*(.*?)(?:,\s*CEP:|$)') { $bairro = $matches[1].Trim() }
    if ($addr -match 'CEP:\s*([\d\.\-]+)') { $cep = $matches[1].Trim() -replace '[^0-9\.\-].*$', '' }
    if ($addr -match 'N[^a-zA-Z0-9]\s*(\d+)') { $numero = $matches[1] }

    $beforeNum = $addr -replace ',?\s*N[^a-zA-Z0-9]\s*\d+.*', ''
    $beforeNum = $beforeNum -replace ',?\s*BAIRRO:.*', ''
    $beforeNum = $beforeNum -replace ',?\s*CEP:.*', ''
    $logradouro = $beforeNum.Trim()
    $logradouro = $logradouro -replace '^ENDERE[^a-zA-Z0-9]O:\s*', ''
    $logradouro = $logradouro.Trim() -replace ',$', ''
    $logradouro = $logradouro.Trim()

    if ($addr -match 'CEP:\s*[\d\.\-]+,\s*(.+?)$') {
        $cidadeUf = $matches[1].Trim()
        if ($cidadeUf -match '^(.+?)\s*-\s*([A-Z]+)$') { $cidade = $matches[1].Trim(); $uf = $matches[2] }
    }

    return @{Logradouro=$logradouro; Numero=$numero; Bairro=$bairro; CEP=$cep; Cidade=$cidade; UF=$uf}
}

# --- 1. Ler dados.txt e montar mapa nome -> {CPF, turma} ---
Write-Host "Lendo dados.txt..."
$dadosLines = Get-Content $dadosFile -Encoding UTF8

$cpfMap = @{}; $currentDadosTurma = ""; $inStudentSection = $false
foreach ($line in $dadosLines) {
    if ($line -match 'Unidade ensino:.*Turma:\s*(.+?)\s*$') {
        $currentDadosTurma = NormalizarTurma($matches[1].Trim())
        $inStudentSection = $false; continue
    }
    if ($line -match '^ORDEM\s+NOME') { $inStudentSection = $true; continue }
    if ($inStudentSection) {
        $parts = $line -split "`t"
        if ($parts.Length -ge 4 -and $parts[0] -match '^\d+$') {
            $nome = $parts[1].Trim(); $cpf = $parts[3].Trim()
            if ($cpf -match '\d') {
                $key = NormalizarNome($nome)
                if (-not $cpfMap.ContainsKey($key)) { $cpfMap[$key] = @{CPF=$cpf; Turma=$currentDadosTurma; Nome=$nome} }
            }
        }
    }
}
Write-Host ("  {0} alunos unicos em dados.txt" -f $cpfMap.Count)

# --- 2. Ler Livro de Matricula e extrair registros ---
Write-Host "Lendo livro de matricula..."
$lines = Get-Content -LiteralPath $regBook -Encoding UTF8
$records = @(); $currentTurma = ""; $currentNome = ""; $state = "buscaTurma"

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($state -eq "buscaTurma") {
        if ($line -match '^TURMA:\s*$') {
            $j = $i + 1
            while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
            if ($j -lt $lines.Count) {
                $currentTurma = NormalizarTurma($lines[$j].Trim())
                $state = "dentroTurma"; $i = $j
            }
        }
        continue
    }
    if ($state -eq "dentroTurma") {
        if ($line -match '^TURMA:\s*$') { $state = "buscaTurma"; $i--; continue }
        if ($line -match '^UNIDADE DE ENSINO:') { $state = "buscaTurma"; continue }
        if ($line -match '^N[^a-zA-Z0-9]+INTERNO') {
            $j = $i + 1
            while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
            if ($j -lt $lines.Count) {
                $parts = $lines[$j] -split "`t"
                if ($parts.Length -ge 3) { $currentNome = $parts[2].Trim(); $state = "dentroAluno" }
            }
            $i = $j
        }
        continue
    }
    if ($state -eq "dentroAluno") {
        if ($line -match '^ENDER') {
            $addrInfo = ExtrairEndereco($line)
            $nomeKey = NormalizarNome($currentNome)
            $cpf = ""; $turmaPO = $currentTurma; $nomePO = $currentNome
            if ($cpfMap.ContainsKey($nomeKey)) { $m = $cpfMap[$nomeKey]; $cpf = $m.CPF; $turmaPO = $m.Turma; $nomePO = $m.Nome }
            if ($addrInfo.Logradouro -ne "" -or $addrInfo.Bairro -ne "") {
                $records += @{Turma=$turmaPO; Nome=$nomePO; CPF=$cpf; Logradouro=$addrInfo.Logradouro; Numero=$addrInfo.Numero; Bairro=$addrInfo.Bairro; Cidade=$addrInfo.Cidade; UF=$addrInfo.UF; CEP=$addrInfo.CEP}
            }
            $currentNome = ""; $state = "dentroTurma"
        }
        continue
    }
}

Write-Host ("  {0} registros extraidos" -f $records.Count)
$comCpf = ($records | Where-Object { $_.CPF -ne "" }).Count
Write-Host ("  {0} com CPF" -f $comCpf)

# --- 3. Deduplicar (mesmo nome, manter o que tem CPF) ---
Write-Host "Deduplicando..."
$seen = @{}; $deduped = @()
foreach ($rec in $records) {
    $key = NormalizarNome($rec.Nome)
    if ($seen.ContainsKey($key)) {
        $existing = $seen[$key]
        if ($rec.CPF -ne "" -and $existing.CPF -eq "") { $seen[$key] = $rec }
    } else {
        $seen[$key] = $rec
    }
}
$deduped = $seen.Values
Write-Host ("  {0} apos dedup (eram {1})" -f $deduped.Count, $records.Count)
$comCpf = ($deduped | Where-Object { $_.CPF -ne "" }).Count
Write-Host ("  {0} com CPF" -f $comCpf)

# --- 4. Gerar enderecos.txt ---
Write-Host "Gerando enderecos.txt..."
$outputLines = @()
foreach ($rec in $deduped) {
    $outputLines += "{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|{8}" -f $rec.Turma, $rec.Nome, $rec.CPF, $rec.Logradouro, $rec.Numero, $rec.Bairro, $rec.Cidade, $rec.UF, $rec.CEP
}
$outputLines = $outputLines | Sort-Object
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($outputFile, $outputLines, $utf8NoBom)
Write-Host ("OK! {0} linhas -> {1}" -f $outputLines.Count, $outputFile)
if ($outputLines.Count -gt 0) { $outputLines | Select-Object -First 5 }
