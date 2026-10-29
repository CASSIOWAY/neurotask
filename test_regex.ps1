$line1 = "N" + [char]166 + " INTERNO	DATA MATR" + [char]205 + "C.	ALUNO	DATA NASCIM.	DATA DE SA" + [char]205 + "DA:"
$line2 = "TURMA:"
$line3 = "ENDERE" + [char]199 + "O: RUA MACEIO"
$line4 = "1 ANO A MATUTINO 2025"

Write-Host "Line1: $line1"
Write-Host "Line2: $line2"
Write-Host "Line3: $line3"

Write-Host ("Match N INTERNO: {0}" -f ($line1 -match '^N[º°]\s*INTERNO'))
Write-Host ("Match ENDEREÇO: {0}" -f ($line3 -match '^ENDEREÇO:'))
Write-Host ("Match TURMA: {0}" -f ($line2 -match '^TURMA:\s*$'))
Write-Host ("Match TURMA line4: {0}" -f ($line2 -match '^TURMA:\s*$'))
Write-Host ("Normalizar: {0}" -f (($line4 -replace '\s*2025\s*$','') -replace '[º°]',''))

# Test the actual file
$lines = Get-Content "C:\Users\USER\Desktop\Banco de dados endereço.txt" -Encoding UTF8 -TotalCount 50
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^TURMA:\s*$') {
        Write-Host ("Found TURMA at line {0}: {1}" -f ($i+1), $lines[$i])
        $j = $i + 1
        while ($j -lt $lines.Count -and $lines[$j].Trim() -eq '') { $j++ }
        if ($j -lt $lines.Count) {
            Write-Host ("  Turma name at line {0}: [{1}]" -f ($j+1), $lines[$j].Trim())
        }
    }
}
