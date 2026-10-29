$src = "C:\Users\USER\Desktop\banco de dados transporte.txt"
$dst = "C:\EXECUTAVEL CENSO 2026\transporte.txt"

if (-not (Test-Path $src)) { Write-Host "Arquivo nao encontrado: $src"; exit 1 }

$content = Get-Content $src -Raw -Encoding UTF8
$lines = $content -split "`r`n|`n|`r"

$currentZone = ""
$results = New-Object System.Collections.ArrayList

foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "") { continue }
    
    if ($trimmed -eq "ZONA URBANA") { $currentZone = "URBANA"; continue }
    if ($trimmed -eq "ZONA RURAL") { $currentZone = "RURAL"; continue }
    
    if ($currentZone -and $trimmed -match "^\d+`t") {
        $parts = $trimmed -split "`t"
        if ($parts.Count -ge 2) {
            $name = $parts[1].Trim() -replace '"', ''
            [void]$results.Add($name + "|" + $currentZone + "|")
        }
    }
}

$seen = @{}
$dedup = $results | Where-Object { $seen[$_] -eq $null; $seen[$_] = 1; $true }
$dedup | Set-Content -Path $dst -Encoding UTF8
Write-Host "Gerados $($dedup.Count) registros de transporte em: $dst"
