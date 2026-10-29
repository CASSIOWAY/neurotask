$regBook = @(Get-ChildItem "C:\Users\USER\Desktop" | Where-Object { $_.Name -like "*endere*" -and $_.Length -gt 10000 } | Sort-Object Length -Descending | Select-Object -First 1).FullName
Write-Host ("Using: {0}" -f $regBook)
$lines = Get-Content -LiteralPath $regBook -Encoding UTF8

# Look at first 40 lines
Write-Host "=== First 40 lines ==="
for ($i = 0; $i -lt [Math]::Min(40, $lines.Count); $i++) {
    Write-Host ("{0}: [{1}]" -f $i, $lines[$i].Replace("`t","\t"))
}

# Test pattern matching
Write-Host "`n=== Pattern tests ==="
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^TURMA:\s*$') {
        Write-Host ("Line {0}: MATCH TURMA" -f $i)
        $j = $i + 1
        while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
        if ($j -lt $lines.Count) {
            Write-Host ("  Turma name at line {0}: [{1}]" -f $j, $lines[$j].Trim())
        }
        break  # just first one for now
    }
}

# Test N INTERNO match on the actual student header
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^N\W+INTERNO') {
        Write-Host ("Line {0}: MATCH N INTERNO: [{1}]" -f $i, $lines[$i].Replace("`t","\t"))
        # Check next non-empty line
        $j = $i + 1
        while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
        if ($j -lt $lines.Count) {
            Write-Host ("  Next line {0}: [{1}]" -f $j, $lines[$j].Replace("`t","\t"))
            $parts = $lines[$j] -split "`t"
            for ($k = 0; $k -lt $parts.Count; $k++) {
                Write-Host ("    Part[{0}]: [{1}]" -f $k, $parts[$k])
            }
        }
        break
    }
}

# Test ENDERECO match
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^ENDER') {
        Write-Host ("Line {0}: MATCH ENDER: [{1}]" -f $i, $lines[$i].Replace("`t","\t"))
        break
    }
}
