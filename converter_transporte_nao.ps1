$srcCenso = "C:\Users\USER\Desktop\DADOS INFORMADOS CENSO.txt"
$srcTransp = "C:\EXECUTAVEL CENSO 2026\transporte.txt"
$dst = "C:\EXECUTAVEL CENSO 2026\transporte_nao.txt"

if (-not (Test-Path $srcCenso)) { Write-Host "Arquivo nao encontrado: $srcCenso"; exit 1 }
if (-not (Test-Path $srcTransp)) { Write-Host "Arquivo nao encontrado: $srcTransp"; exit 1 }

# Load transporte.txt (quem DEVE ter transporte)
$transpContent = [System.IO.File]::ReadAllText($srcTransp, [System.Text.Encoding]::UTF8)
$transpLines = $transpContent -split "`r`n|`n|`r"
$deveTerTransporte = @{}
foreach ($line in $transpLines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "" -or $trimmed -notmatch "\|") { continue }
    $parts = $trimmed -split "\|"
    $nome = $parts[0].Trim()
    if ($nome -ne "") {
        $key = $nome.ToUpper().Trim() -replace '[^\w\s]', '' -replace '\s+', ' '
        $deveTerTransporte[$key] = $nome
    }
}
Write-Host "Registros em transporte.txt (quem DEVE ter transporte): $($deveTerTransporte.Count)"

# Load DADOS INFORMADOS CENSO.txt
$censoContent = [System.IO.File]::ReadAllText($srcCenso, [System.Text.Encoding]::UTF8)
$censoLines = $censoContent -split "`r`n|`n|`r"

# Build lookup: normalized name -> (zona, turma, transport, cpf)
$censoLookup = @{}
foreach ($line in $censoLines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "") { continue }
    if ($trimmed -match "^Ordem") { continue }
    if ($trimmed -match "^Fonte:") { continue }
    if ($trimmed -match "^Emitido em") { continue }
    if ($trimmed -match "^Nota:") { continue }
    if ($trimmed -match "^Dados cadastrais") { continue }

    $parts = $trimmed -split "`t"
    if ($parts.Count -ge 28) {
        $nome = $parts[4].Trim()
        $zona = $parts[18].Trim()
        $turma = $parts[23].Trim()
        $transporte = $parts[27].Trim()
        $cpf = $parts[9].Trim()
        if ($nome -eq "") { continue }
        $key = $nome.ToUpper().Trim() -replace '[^\w\s]', '' -replace '\s+', ' '
        $isNao = $transporte -cmatch "^N" -and $transporte.Length -le 4
        $zonaUpper = "URBANA"
        if ($zona -cmatch "^R") { $zonaUpper = "RURAL" }
        if (-not $censoLookup.ContainsKey($key) -or $censoLookup[$key].transporte -ne "Sim") {
            $censoLookup[$key] = @{ nome = $nome; zona = $zonaUpper; turma = $turma; transporte = $(if ($isNao) { "Nao" } else { "Sim" }); cpf = $cpf }
        }
    }
}

# Cross-reference: alunos que DEVEM ter transporte mas tem "Nao" no censo
$results = New-Object System.Collections.ArrayList
$seen = @{}

foreach ($key in $deveTerTransporte.Keys) {
    $nomeOriginal = $deveTerTransporte[$key]
    if ($censoLookup.ContainsKey($key)) {
        $info = $censoLookup[$key]
        if ($info.transporte -eq "Nao") {
            $dedupKey = $key
            if (-not $seen.ContainsKey($dedupKey)) {
                $seen[$dedupKey] = $true
                $cpf = $info.cpf
                if ($cpf -eq "--") { $cpf = "" }
                [void]$results.Add($nomeOriginal + "|" + $info.zona + "|" + $info.turma + "|" + $cpf + "|")
            }
        }
    } else {
        $dedupKey = $key
        if (-not $seen.ContainsKey($dedupKey)) {
            $seen[$dedupKey] = $true
            [void]$results.Add($nomeOriginal + "|URBANA|NAO ENCONTRADO NO CENSO||")
        }
    }
}

$results | Set-Content -Path $dst -Encoding UTF8
Write-Host "Alunos que DEVEM ter transporte mas estao como NAO no censo: $($results.Count)"