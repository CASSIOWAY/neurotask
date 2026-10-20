# Setup — Repositório Git + Deploy Automático

Este repositório já vem pronto para deploy automático. Siga o caminho escolhido.

---

## Pré-requisito: instalar o Git

Sem Git, use o `deploy.ps1` (deploy direto sem git, seção **B**).
Para o deploy automático a cada push, instale o Git:

```powershell
winget install --id Git.Git -e --source winget --silent `
  --accept-package-agreements --accept-source-agreements
```

Reabra o terminal e confirme: `git --version`.

---

## A) Deploy Automático (push → publica sozinho)

### Passo 1 — Criar o repositório local

Dentro da pasta `neurotask`:

```powershell
git init
git add .
git commit -m "NeuroTask MVP: micro-desafios + recompensas + SEO"
```

### Passo 2 — Criar o repositório no GitHub

1. Acesse https://github.com/new
2. Nome: `neurotask`
3. **Private** ou **Public** — depois escolha **Public** para SEO.
4. **Não** marque "Add README" (já temos arquivos).

### Passo 3 — Conectar e enviar

```powershell
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/neurotask.git
git push -u origin main
```

> Prefira autenticação por **token (PAT)** ou **SSH** em vez de senha.
> Configure com: `git config --global credential.helper manager`

### Passo 4 — Escolher o provedor e adicionar os Secrets

#### Opção Cloudflare Pages
1. Crie a conta em https://dash.cloudflare.com/
2. Copie o **Account ID** (painel → Workers & Pages).
3. Crie um **API Token** com a permissão `Cloudflare Pages: Edit`
   (https://dash.cloudflare.com/profile/api-tokens).
4. No GitHub: **Settings → Secrets and variables → Actions → New repository secret**:
   - `CLOUDFLARE_API_TOKEN` = seu token
   - `CLOUDFLARE_ACCOUNT_ID` = seu account id
5. Faça um push (ou rode `Deploy Cloudflare Pages` em **Actions → Run workflow**).
   O primeiro deploy publica em `neurotask.pages.dev`.

#### Opção Netlify
1. Crie a conta em https://app.netlify.com/
2. Crie um **Personal Access Token** (User settings → Applications → New token).
3. Crie o site (ou use um existente) e copie o **Site ID**
   (Site settings → General → Site information → Site ID).
4. No GitHub, adicione os secrets:
   - `NETLIFY_AUTH_TOKEN`
   - `NETLIFY_SITE_ID`
5. Push → a Action `Deploy Netlify` publica automaticamente.

> Mantenha **apenas um** workflow ativo (desative o outro renomeando
> para `.yml.disabled`) para não publicar nos dois ao mesmo tempo.

### Passo 5 — Domínio próprio
- Cloudflare: **Custom domains** no projeto.
- Netlify: **Domain settings → Add custom domain**.
- Lembre de trocar `SEU-DOMINIO.com` em `index.html`, `robots.txt` e `sitemap.xml`.

---

## B) Deploy direto sem Git (PowerShell)

Se não puder usar git, a Netlify aceita um ZIP via API:

```powershell
.\deploy.ps1 -Token "SEU_TOKEN" -SiteId "SEU_SITE_ID"
```

Isso empacota a pasta e publica. Repita a cada mudança (é manual, mas funciona).

---

## Como funciona o pipeline

```
git push (branch main)
        │
        ├── .github/workflows/deploy-cloudflare.yml  →  wrangler pages deploy
        │
        └── .github/workflows/deploy-netlify.yml     →  nwtgck/actions-netlify
```

Cada push dispara o deploy; o site estático vai ao ar em segundos, com HTTPS e CDN.

---

## Checklist final

- [ ] `git push` funcionando
- [ ] Um dos workflows ativo
- [ ] Secrets configurados
- [ ] Domínio próprio apontado
- [ ] `SEU-DOMINIO.com` substituído nos 3 arquivos
- [ ] Search Console + Bing com o sitemap
