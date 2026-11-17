# Publicar & Crescer o NeuroTask

Guia prático: onde hospedar de graça, como aparecer no Google e como conquistar parceiros e tráfego.

---

## 1. Hospedagem gratuita (comparativo 2026)

O NeuroTask é **100% estático** (HTML/CSS/JS). Qualquer um destes serve.

| Serviço | Plano grátis | Uso comercial? | CDN global | Domínio próprio | Limite principal | Nota |
|---|---|---|---|---|---|---|
| **Cloudflare Pages** ⭐ | Grátis p/ sempre | ✅ Sim | ✅ | ✅ | Banda ilimitada (fair use) | **Melhor escolha**: rápida, barata de verdade, aceita comercial |
| **GitHub Pages** | Grátis | ✅ Sim | ✅ | ✅ | 1 GB / 100 GB por mês | Ideal se você já usa git |
| **Netlify** | Free (300 créditos) | ✅ Sim | ✅ | ✅ | ~15 GB de banda/mês | Deploy por arrastar pasta |
| **Render** | Free | ✅ Sim | ✅ | ✅ | 100 GB/mês | Simples |
| **Firebase Hosting** | Grátis | ✅ Sim | ✅ | ✅ | 10 GB / 3600 GB transf | Integra com Google |
| **Surge.sh** | Grátis | ✅ Sim | ✅ | ✅ | Ilimitado | CLI de 1 comando |
| **Vercel Hobby** | Grátis | ❌ **Não-comercial** | ✅ | ✅ | 100 GB/mês | **Evite** para produto que cobra (viola os termos) |
| **Tiiny.host** | Grátis | ✅ Sim | ✅ | ✅ | 5 GB | Upload de ZIP |

> ⚠️ **Vercel Hobby é "non-commercial use only"**. Como o NeuroTask vende o plano Pro, use **Cloudflare Pages, GitHub Pages ou Netlify** para ficar em conformidade.

### Recomendação
**Cloudflare Pages** como principal (banda ilimitada + CDN + HTTPS grátis + aceita uso comercial). Deixe o **GitHub Pages** como espelho de segurança.

---

## 2. Domínio

- **Cloudflare Registrar** — vende domínio **pelo custo** (sem margem). Ideal para `.com`/`.dev`.
- **Registro.br** — para `.com.br` (identidade brasileira, bom para SEO local). Custa ~R$ 40–50/ano.
- **Namecheap / Porkbun** — alternativas baratas (~$10/ano para `.com`).

> Dica: um `.com.br` + conteúdo em português costuma ranquear bem para buscas no Brasil.

---

## 3. Passo a passo para publicar (Cloudflare Pages)

1. Crie a conta em [pages.cloudflare.com](https://pages.cloudflare.com/).
2. **Direct Upload** → arraste a pasta `neurotask` (não precisa de git).
3. Nome do projeto: `neurotask` → nasce em `neurotask.pages.dev`.
4. Em **Custom domains**, adicione seu domínio.
5. **Substitua** `SEU-DOMINIO.com` em:
   - `index.html` (canonical, OG, JSON-LD)
   - `robots.txt` (Sitemap)
   - `sitemap.xml` (URL)
6. Configure o certificado HTTPS (automático na Cloudflare).

### Deploy pelo Netlify (alternativa em 30 segundos)
1. [netlify.com](https://www.netlify.com/) → **Add new site → Deploy manually**.
2. Arraste a pasta `neurotask`.
3. Pronto: `nome-aleatorio.netlify.app`. Troque em **Domain settings**.

---

## 4. SEO — Checklist

Já implementado no código ✅
- [x] `<title>` e `<meta description>` otimizados
- [x] `canonical`
- [x] Open Graph + Twitter Card
- [x] JSON-LD: `Organization`, `WebSite`, `SoftwareApplication` (com oferta/avaliação), `FAQPage`
- [x] Seção de **FAQ visível** (4 perguntas) — alimenta o FAQ rich result
- [x] HTML semântico (`header`, `main`, `section`, `details`, `h1/h2`)
- [x] `lang="pt-BR"`
- [x] `robots.txt` + `sitemap.xml`

Falta fazer (ação sua):
- [ ] **Google Search Console** — verificar propriedade e enviar o `sitemap.xml`.
- [ ] **Bing Webmaster** — mesma coisa (o Bing alimenta buscas do Edge/Copilot).
- [ ] Gerar o `sitemap.xml` com as URLs finais (depois do domínio).

### Palavras-chave alvo (conteúdo)
`como ter foco`, `acabar com a procrastinação`, `como criar hábitos`, `organizar o dia`, `produtividade`, `técnica de micro-tarefas`, `gamificação de hábitos`, `economizar dinheiro rápido`, `ideia de venda`.

### Link building / backlinks (o que realmente move ranking)
1. **Guest posts**: escreva 1 artigo em blogs de produtividade com link para o NeuroTask.
2. **HARO / Connectively**: responda jornalistas buscando fontes sobre "foco/produtividade" e seja linkado.
3. **Diretórios de produto**: submeta em:
   - [Product Hunt](https://www.producthunt.com/)
   - [BetaList](https://betalist.com/)
   - [There's An AI For That](https://theresanaiforthat.com/)
   - [AlternativeTo](https://alternativeto.net/)
   - [Uneed](https://uneed.best/) · [FazPi](https://fazpi.com.br/)
   - [Softonic](https://en.softonic.com/) · [Alternative.me](https://alternative.me/)
4. **Comunidades**: Reddit (r/productivity, r/getdisciplined), fóruns, grupos de estudo/concursos.
5. **Perfis sociais** com link na bio (Instagram, TikTok, YouTube, LinkedIn, X).

### Conteúdo que vira tráfego
- Vídeos curtos (Reels/TikTok/Shorts): "Faça isso em 60 segundos e destrave seu foco".
- Série: "Desafio 30 dias de streak" — as pessoas adoram acompanhar.
- Post de bastidores: construa em público (build in public) no LinkedIn/X.

---

## 5. Parcerias

### A) Marcas patrocinadoras das recompensas (B2B)
O pool de recompensas (`REWARD_POOL` em `app.js`) aceita cupons de parceiros. A marca **paga pela exposição e pelo lead pré-qualificado**.
- Abordagem: "Colocamos sua oferta na Roleta de Bônus, com cashback que devolve valor ao usuário. Você paga por engajamento, não por impressão."
- Modelos: **CPC** (por clique), **CPL** (por lead), **comissão por venda** (afiliado).

### B) Programa de afiliados
Venda o Pro com comissão recorrente (ex.: 30% no 1º ano). Ferramentas grátis: **Rakuten Advertising**, **Awin**, **Elo7**, ou um link com `?aff=ID`.

### C) Influenciadores de nicho
Produtividade, concursos, finanças pessoais, empreendedorismo. Ofereça **código exclusivo** + comissão. Microinfluenciadores (5–50 mil) convertem mais.

### D) Integrações / co-marketing
- Notion, Trello, Google Calendar (templates que "plugam" o NeuroTask).
- Cross-promo com apps complementares (cada um divulga o outro para o mesmo público).

### E) Licenciamento B2B
Venda o sistema "white-label" para empresas (treinamento de equipes), escolas e cursos. Entrada recorrente maior.

---

## 6. Aquisição rápida (hacks de lançamento)

1. **Product Hunt** — lance numa terça/quarta de manhã (horário dos EUA). Peça upvotes no dia.
2. **Referral no app** — implementado abaixo ✅.
3. **Lead magnet** — "Baixe o checklist de 3 passos em PDF" em troca do e-mail.
4. **Desafio público** — "30 dias de streak" com comunidade no WhatsApp/Telegram/Discord.

---

## 7. Ordem de execução sugerida

1. Publicar na Cloudflare Pages (15 min).
2. Registrar domínio `.com.br` (30 min).
3. Trocar `SEU-DOMINIO.com` nos 3 arquivos.
4. Submeter ao Search Console + Bing (10 min).
5. Lançar no Product Hunt + diretórios.
6. Criar 3 vídeos curtos + 1 guest post.
7. Abrir 5 conversas com marcas para patrocinar recompensas.
