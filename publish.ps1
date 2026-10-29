<#
  Publica o NeuroTask no GitHub e sobe a branch main.

  O token NÃO fica salvo em lugar nenhum: ele é usado apenas no comando do git
  via cabeçalho HTTP temporário e nunca é gravado no .git/config.

  Uso:
    .\publish.ps1 -Token "ghp_xxx" -User "seu-usuario"
    .\publish.ps1                      # pergunta interativamente (digitacao oculta)

  Requer: git instalado.
#>
param(
  [string]$Token,
  [string]$User,
  [string]$Repo = "neurotask",
  [switch]$Private
)

$ErrorActionPreference = "Stop"

if (-not $Token) {
  $sec = Read-Host "Cole o Personal Access Token" -AsSecureString
  $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}
if (-not $User) { $User = Read-Host "Seu usuario do GitHub" }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "Git nao encontrado. Instale com: winget install --id Git.Git"
}

$headers = @{
  Authorization  = "Bearer $Token"
  Accept         = "application/vnd.github+json"
  "User-Agent"   = "neurotask-publish"
  "X-GitHub-Api-Version" = "2022-11-28"
}

# 1) garante repositorio local e commit
if (-not (Test-Path ".git")) { git init -b main | Out-Null }
git add -A
$dirty = git status --porcelain
if ($dirty) {
  git commit -m "Atualiza site NeuroTask" | Out-Null
  Write-Output "Commit criado com as alteracoes pendentes."
}

# 2) cria o repositorio no GitHub (se ja existir, segue)
$body = @{
  name        = $Repo
  description = "NeuroTask — micro-desafios de 60-180s e recompensas baseadas em dopamina."
  private     = [bool]$Private
} | ConvertTo-Json

try {
  $r = Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/repos" `
       -Headers $headers -ContentType "application/json" -Body $body
  Write-Output ""
  Write-Output "✅ Repositorio criado: $($r.html_url)"
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code -eq 422) {
    Write-Output "Repositorio '$Repo' ja existe — seguindo para o push."
  } else {
    Write-Output "Erro ao criar repositorio (HTTP $code). Verifique o token e as permissoes."
    throw
  }
}

# 3) push (token vai por cabecalho temporario, nao fica salvo)
$env:GIT_TERMINAL_PROMPT = "0"
$authHeader = "Authorization: Bearer $Token"
Write-Output "Enviando branch main..."
git -c http.extraHeader="$authHeader" push -u origin main

Write-Output ""
Write-Output "=========================================================="
Write-Output "  Repositorio:  https://github.com/$User/$Repo"
Write-Output "  Site (Pages): https://$User.github.io/$Repo/"
Write-Output "=========================================================="
Write-Output ""
Write-Output "Para o site ir ao ar, escolha UMA opcao:"
Write-Output ""
Write-Output "[GitHub Pages]"
Write-Output "  No repo: Settings > Pages > Source: 'Deploy from a branch' > main / (root) > Save"
Write-Output ""
Write-Output "[Deploy automatico - Netlify ou Cloudflare]"
Write-Output "  1. No repo: Settings > Secrets and variables > Actions > New secret"
Write-Output "     Netlify:     NETLIFY_AUTH_TOKEN + NETLIFY_SITE_ID"
Write-Output "     Cloudflare:  CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID"
Write-Output "  2. Em Actions, rode o workflow 'Deploy ...' (ou faca um novo push)."
