$srcMatch = Get-ChildItem "C:\Users\USER\Desktop\ALUNOS COM DEFICI*" | Select-Object -First 1 -ExpandProperty FullName
if (-not $srcMatch) { Write-Host "Arquivo ALUNOS COM DEFICIENCIA nao encontrado no Desktop"; exit 1 }
$src = $srcMatch
$dst = "C:\EXECUTAVEL CENSO 2026\especiais.txt"

$content = Get-Content $src -Raw -Encoding UTF8
$lines = $content -split "`r`n|`n"

# Find student start lines (NN\t or NN. where NN is 2 digits)
$studentStarts = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "^\d{2}[\t\.]") { $studentStarts += $i }
}

# Known column headers mapped by tab position (from the header lines)
$colKeyAt = @()
$colKeyAt += "" # 0 - NOME
$colKeyAt += "" # 1 - IDADE
$colKeyAt += "" # 2 - ANO
$colKeyAt += "" # 3 - TURNO
$colKeyAt += "CEGUEIRA"
$colKeyAt += "BAIXA_VISAO"
$colKeyAt += "VISAO_MONOCULAR"
$colKeyAt += "SURDEZ"
$colKeyAt += "DEF_AUDITIVA"
$colKeyAt += "SURDO_CEGUEIRA"
$colKeyAt += "DEF_FISICA"
$colKeyAt += "DEF_INTELECTUAL"
$colKeyAt += "DEF_INTEL_SINDROME_DOWN"
$colKeyAt += "DEF_MULTIPLA"
$colKeyAt += "ALTAS_HABILIDADES"
$colKeyAt += "TEA"
$colKeyAt += "DISCALCULIA"
$colKeyAt += "DISGRAFIA"
$colKeyAt += "DISLALIA"
$colKeyAt += "DISLEXIA"
$colKeyAt += "TDAH"
$colKeyAt += "TPAC"
$colKeyAt += "RECURSO"
$colKeyAt += "CADEIRANTE"
$colKeyAt += "BPC"
$colKeyAt += "AEE_PROPIA"
$colKeyAt += "AEE_OUTRA"
$colKeyAt += "AEE_APAE"
$colKeyAt += "CLINICA_AUTISTA"
$colKeyAt += "TRANSPORTE"
$colKeyAt += "APOIO_PI_AT"
$colKeyAt += "APOIO_COMPART"
$colKeyAt += "TOTAL"

$colDisplay = @{
    "CEGUEIRA" = "Cegueira"
    "BAIXA_VISAO" = "Baixa Visao"
    "VISAO_MONOCULAR" = "Visao Monocular"
    "SURDEZ" = "Surdez"
    "DEF_AUDITIVA" = "Def. Auditiva"
    "SURDO_CEGUEIRA" = "Surdocegueira"
    "DEF_FISICA" = "Def. Fisica"
    "DEF_INTELECTUAL" = "Def. Intelectual"
    "DEF_INTEL_SINDROME_DOWN" = "D.I./Sindrome Down"
    "DEF_MULTIPLA" = "Def. Multipla"
    "ALTAS_HABILIDADES" = "Altas Habilidades"
    "TEA" = "TEA (Autismo)"
    "DISCALCULIA" = "Discalculia"
    "DISGRAFIA" = "Disgrafia"
    "DISLALIA" = "Dislalia"
    "DISLEXIA" = "Dislexia"
    "TDAH" = "TDAH"
    "TPAC" = "TPAC"
    "CADEIRANTE" = "Cadeirante"
    "BPC" = "Possui BPC"
}

$recursoMap = @{
    "A" = "Auxilio Ledor"
    "B" = "Tradutor Libras"
    "C" = "Prova superampl"
    "D" = "Prova Video Libras"
    "E" = "Auxilio transcricao"
    "F" = "Leitura labial"
    "G" = "CD audio"
    "H" = "Material Braille"
    "I" = "Guia-interprete"
    "J" = "Prova ampliada"
    "K" = "Portugues 2a lingua"
    "L" = "Nenhum"
}

$results = @()

for ($s = 0; $s -lt $studentStarts.Count; $s++) {
    $start = $studentStarts[$s]
    $end = if ($s + 1 -lt $studentStarts.Count) { $studentStarts[$s + 1] - 1 } else { $lines.Count - 1 }
    
    # Extract name from first line
    $firstLine = $lines[$start]
    $parts = $firstLine -split "`t"
    if ($parts.Count -lt 2) { continue }
    $name = $parts[1].Trim()
    if ($name -eq "" -or $name -eq "ALUNOS" -or $name -match "^\d+$") { continue }
    
    # Build raw text for this block (strip the first line's name)
    $rawBlock = ""
    for ($j = $start; $j -le $end; $j++) {
        $rawBlock += $lines[$j] + "`n"
    }
    
    # Analyze the block with simple heuristics
    $defs = @()
    $recursos = @()
    $hasTransporte = $false
    $aeeItems = @()
    $apoioItem = ""
    
    # Map content at tab positions
    $blockLines = $rawBlock.Trim() -split "`n"
    
    # For each line that has tabs, analyze each field
    # Use a simple state machine to track which columns we've seen
    $dataLines = @()
    foreach ($bl in $blockLines) {
        if ($bl.Trim() -ne "") { $dataLines += $bl }
    }
    
    # Skip the first data line (which is the name/id line)
    # and analyze the remaining lines
    for ($dl = 1; $dl -lt $dataLines.Count; $dl++) {
        $fields = $dataLines[$dl] -split "`t"
        
        for ($f = 0; $f -lt $fields.Count; $f++) {
            $val = $fields[$f].Trim()
            if ($val -eq "") { continue }
            
            # The tab position in the X/A/E lines starts at column 4 (CEGUEIRA)
            # because the first 4 columns (NOME,IDADE,ANO,TURNO) are in the first line
            $absPos = $f + 4
            
            if ($absPos -ge $colKeyAt.Count) { continue }
            $colKey = $colKeyAt[$absPos]
            if ($colKey -eq "") { continue }
            
            $isX = ($val -eq "X" -or $val -eq "x")
            $isAE = ($val -match "^(A|E|AE|A/E)$")
            $isCode = ($val -match "^[A-Z]+$" -and $val.Length -le 3)
            $isPI = ($val -eq "PI" -or $val -eq "AT" -or $val -eq "PI/AT")
            
            # Check if this is a disability column (4-21)
            if ($isX -and $absPos -ge 4 -and $absPos -le 21) {
                $dName = $colDisplay[$colKey]
                if ($dName -and $defs -notcontains $dName) { $defs += $dName }
            }
            # Cadeirante and BPC are also "disabilities" to display
            if ($isX -and ($colKey -eq "CADEIRANTE" -or $colKey -eq "BPC")) {
                $dName = $colDisplay[$colKey]
                if ($dName -and $defs -notcontains $dName) { $defs += $dName }
            }
            # Transport
            if ($isX -and $colKey -eq "TRANSPORTE") { $hasTransporte = $true }
            # Transport also commonly indicated by standalone X on its own line
            if ($isX -and $absPos -eq 29) { $hasTransporte = $true }
            
            # AEE markers
            if ($isAE -and ($colKey -match "AEE" -or $colKey -eq "CLINICA_AUTISTA")) {
                $aeeLabel = switch ($colKey) {
                    "AEE_PROPIA" { "Propria" }
                    "AEE_OUTRA" { "Outra" }
                    "AEE_APAE" { "APAE" }
                    "CLINICA_AUTISTA" { "Clinica Autista" }
                }
                if ($aeeLabel -and $aeeItems -notcontains $aeeLabel) { $aeeItems += $aeeLabel }
            }
            
            # Resource codes - single letters in column 22
            if ($colKey -eq "RECURSO" -and $val -match "^[A-Z-]+$") {
                foreach ($ch in $val.ToCharArray()) {
                    $c = $ch.ToString()
                    if ($c -eq "-") { $c = "L" } # dash means Nenhum/same as L
                    if ($recursoMap.ContainsKey($c) -and $recursos -notcontains $recursoMap[$c]) {
                        $recursos += $recursoMap[$c]
                    }
                }
            }
            
            # Apoio
            if ($isPI) { $apoioItem = $val }
        }
    }
    
    # Also check for AEE markers in the raw text (A, E, AE, A/E not inside a field)
    if ($rawBlock -match "`tA\t") { <# AEE Propria #> }
    if ($rawBlock -match "`tE\t") { <# AEE Outra/Clinica #> }
    
    # Look for "A" and "E" as standalone codes anywhere in the block as AEE indicators
    # This is a fallback for when tab positions are ambiguous
    if ($aeeItems.Count -eq 0) {
        # Simple check: if the block contains "AE" or "A E" pattern, assume AEE
        $upper = $rawBlock.ToUpper()
        $aeeFound = @{}
        # A in column 25 = Propria, E in column 25-28 = various
        # This is hard to parse without exact tab positions. Use simple heuristics.
    }
    
    # Also check for X on its own line (transport indicator)
    # In the data, student blocks often end with a line containing just "X"
    if ($rawBlock -match "^\s*X\s*`$" -or $rawBlock -match "`n\s*X\s*`$") {
        if (-not $hasTransporte) { $hasTransporte = $true }
    }
    
    # Build record
    $defStr = if ($defs.Count -gt 0) { $defs -join ", " } else { "" }
    $recursoStr = if ($recursos.Count -gt 0) { $recursos -join ", " } else { "" }
    $transpStr = if ($hasTransporte) { "Sim" } else { "" }
    $aeeStr = if ($aeeItems.Count -gt 0) { $aeeItems -join ", " } else { "" }
    $apoioStr = $apoioItem
    
    $record = $name + "|" + $defStr + "|" + $recursoStr + "|" + $transpStr + "|" + $aeeStr + "|" + $apoioStr
    $results += $record
}

# Deduplicate by name
$seen = @{}
$final = @()
foreach ($r in $results) {
    $n = ($r -split "\|")[0]
    if ($seen.ContainsKey($n)) { continue }
    $seen[$n] = $true
    $final += $r
}

$final | Set-Content -Path $dst -Encoding UTF8
Write-Host "Gerados $($final.Count) registros de alunos especiais em: $dst"
