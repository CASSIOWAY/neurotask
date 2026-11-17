<#
  Deploy direto (sem git) do NeuroTask para a Netlify via API.
  Funciona só com PowerShell — não precisa de git nem de node.

  Uso:
    .\deploy.ps1 -Token "SEU_TOKEN" -SiteId "SEU_SITE_ID"

  O token e o site id ficam em: https://app.netlify.com/user/applications
#>
param(
  [Parameter(Mandatory = $true)][string]$Token,
  [Parameter(Mandatory = $true)][string]$SiteId,
  [string]$Dir = "."
)

$ErrorActionPreference = "Stop"
$zip = Join-Path $env:TEMP "neurotask-deploy.zip"

if (Test-Path $zip) { Remove-Item $zip -Force }

# Empacota a pasta inteira (site estático)
Compress-Archive -Path (Join-Path $Dir '*') -DestinationPath $zip -Force
$bytes = [System.IO.File]::ReadAllBytes($zip)
Write-Output "Pacote: $($bytes.Length / 1KB) KB"

# Envia o ZIP para a API da Netlify
$headers = @{ Authorization = "Bearer $Token" }
$url = "https://api.netlify.com/api/v1/sites/$SiteId/deploys"

Write-Output "Enviando deploy..."
$resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -ContentType "application/zip" -Body $bytes

Write-Output ""
Write-Output "✅ Deploy enviado!"
Write-Output "   URL:    $($resp.url)"
Write-Output "   Admin:  $($resp.admin_url)"
Write-Output "   Estado: $($resp.state)"

Remove-Item $zip -Force -ErrorAction SilentlyContinue
