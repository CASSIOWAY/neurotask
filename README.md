# NeuroTask · HabitFlow

[![Deploy Netlify](https://github.com/SEU-USUARIO/neurotask/actions/workflows/deploy-netlify.yml/badge.svg)](https://github.com/SEU-USUARIO/neurotask/actions/workflows/deploy-netlify.yml)
[![Deploy Cloudflare Pages](https://github.com/SEU-USUARIO/neurotask/actions/workflows/deploy-cloudflare.yml/badge.svg)](https://github.com/SEU-USUARIO/neurotask/actions/workflows/deploy-cloudflare.yml)
![HTML](https://img.shields.io/badge/HTML-E34F26?logo=html5&logoColor=white)
![JS puro](https://img.shields.io/badge/JS-vanilla-F7DF1E?logo=javascript&logoColor=black)
![Sem build](https://img.shields.io/badge/build-none-00E0C6)

> Sistema de Execução & Micro-Recompensas baseado em dopamina.
> Micro-desafios de **60 a 180 segundos** → checklist de 3 passos → recompensa instantânea → roleta/baú bônus → streaks.

MVP autocontido em **HTML + CSS + JS puro**. Sem build, sem dependências, sem backend.
Persistência via `localStorage` (funciona offline, sem cadastro).

---

## ▶️ Como rodar

**Opção 1 — abrir direto:** dê dois cliques em `index.html`.

**Opção 2 — servidor local (recomendado):**
```powershell
powershell -ExecutionPolicy Bypass -File .\serve.ps1
```
Depois abra `http://localhost:8732/`.

---

## 🗂️ Estrutura

| Arquivo | Papel |
|---|---|
| `index.html` | Estrutura das telas (hero, desafios, execução, recompensa, roleta, painel) |
| `styles.css` | Tema escuro/neon, animações, responsivo, `prefers-reduced-motion` |
| `app.js` | Toda a lógica: estado, streak, timer, checklist, recompensas, roleta, confete, som |
| `serve.ps1` | Mini-servidor HTTP para testar localmente (só Windows/PowerShell) |
| `robots.txt` | Diz aos buscadores o que indexar + local do sitemap |
| `sitemap.xml` | Mapa do site para o Google/Bing |
| `og.png` | Cartão de compartilhamento (1200×630) para redes sociais |
| `make-og.ps1` | Gera o `og.png` (rode se quiser recriar o cartão) |
| `PUBLICAR-E-CRESCER.md` | **Guia completo**: hospedagem grátis, SEO, backlinks, parcerias |
| `CONTRIBUTING.md` | Como contribuir: fluxo, padrões de código e checklist de PR |

---

## 🔁 Fluxo implementado

1. **Hero one-button** — CTA único "Iniciar Micro-Foco · 2 min", sem cadastro.
2. **Escolha do micro-desafio** — 4 dores: Foco, Economizar, Criar Ideia de Venda, Organizar o Dia.
3. **Checklist de 3 passos** — com timer (60/90/120/180s), barra de progresso, animação de check, haptics.
4. **Recompensa** — animação + confete + som + pontos (`base + bônus de tempo + bônus de streak`).
5. **Roleta de Bônus (Gacha)** — 1 giro por desafio; recompensa variável (pontos, cupom, insígnia, prêmio Pro).
6. **Painel** — pontos, sequência (streak), desafios do dia, insígnias, recompensas, histórico e upsell Pro.

## 🧲 Camada de persuasão & conversão

Projetada para **deslumbrar o imaginário** e cobrar no momento certo:

| Gatilho | Onde | Psicologia |
|---|---|---|
| **Prova social animada** | Hero | Contadores (`+12.400 pessoas`, `4,9/5`, `3,2M vitórias`) — autoridade/pertencimento |
| **Visão de 30 dias** | Tela `Visão` | Projeta streak, micro-vitórias e pontos no futuro → desejo pelo "eu de depois" |
| **Teaser pós-recompensa** | Tela `Recompensa` | "Você sentiu o gosto. Isso foi 1 de 4." → lacuna de curiosidade |
| **Escassez** | Paywall | "Restam N vagas com 50% off" (diminui a cada visita) |
| **Urgência** | Paywall | Contagem regressiva de 24h (persistida) |
| **Empilhamento de valor** | Paywall | Benefícios somados (R$ 117/mês) vs preço (R$ 19,90) |
| **Comparativo Free × Pro** | Paywall | Efeito de ancoragem |
| **Prova social qualitativa** | Paywall | 4 depoimentos |
| **Reversão de risco** | Paywall | Garantia de 7 dias |
| **Aversão à perda** | Topbar + Painel | Streak sempre visível |

**Pontos de conversão (paywall):**
- Botão "R$ 19,90/mês" no Painel → tela de upgrade.
- Botão "Ver minha visão de 30 dias" → visão (grátis) → CTA para o upgrade.
- Teaser na tela de recompensa → upgrade.
- **Limite grátis de 3/dia atingido** → upgrade (o momento de maior desejo: o usuário já sentiu a dopamina).

### ⚠️ Antes de ir ao ar (importante)

Os números de prova social, os depoimentos e o contador de vagas são **placeholders de demonstração** (`TESTIMONIALS`, `SEATS_START`, `OFFER_HOURS` no topo de `app.js`). Substitua por dados reais da sua base e, para a escassez/urgência, por regras de oferta genuínas — persuasão funciona muito melhor (e é ética) quando é verdadeira.

---

## ⚙️ Pontos de configuração (tudo no topo de `app.js`)

- `CHALLENGES` — os micro-desafios (ícone, título, descrição, tempo, 3 passos).
- `REWARD_POOL` — pool de recompensas com peso (`w`) e tier (`free` / `premium`).
- `WHEEL_SLICES` — fatias da roleta.
- `BADGES` — insígnias e requisitos.
- `FREE_DAILY_LIMIT` — hoje em `3` (limite grátis diário).

---

## 💰 Regras de negócio atuais

- **Grátis:** 3 micro-desafios/dia + recompensas `free`.
- **Pro (R$ 19,90/mês):** desafios ilimitados, recompensas `premium` (dicas de monetização, templates, créditos de IA).
  - Botão **"R$ 19,90/mês"** no painel alterna o estado `pro` (simulação — em produção, integrate com Stripe/Pagar.me).
- **Pontuação:** `10 base + bônus de tempo (até ~10) + bônus de streak (2/dia, máx 10)`.

---

## 🚀 Publicando no Polsia (construtor de sites)

O Polsia (assim como Wix/WordPress) aceita conteúdo de duas formas. Escolha uma:

### A) Embutir como bloco HTML/iframe (mais rápida)
1. No editor do Polsia, adicione um bloco **"HTML personalizado"** / **"embed"**.
2. Se o Polsia hospedar arquivos estáticos, faça upload de `index.html`, `styles.css` e `app.js` e aponte o iframe para a URL do `index.html`.
3. Se não hospedar, suba os 3 arquivos em qualquer hospedagem estática (Netlify, Vercel, GitHub Pages) e use:
   ```html
   <iframe src="https://SEU-DOMINIO/neurotask/index.html"
           style="width:100%;height:100vh;border:0" loading="lazy"></iframe>
   ```

### B) Recriar a página no editor visual
- Use o `index.html` como referência de estrutura e o `styles.css` como guia de estilo (cores: `--violet #7c5cff`, `--teal #00e0c6`, fundo `#0b0b14`).
- Para as telas dinâmicas (checklist, roleta, painel), o caminho mais fiel é manter o `app.js` e embuti-lo via **HTML personalizado** (opção A), pois a lógica depende de JS.

> **Atenção:** `localStorage` funciona dentro de iframe apenas se o domínio do iframe for sempre o mesmo. Se o Polsia servir em subdomínios diferentes, prefira a opção B com o JS embutido no domínio principal.

---

## 🗺️ Roadmap (fora do MVP atual)

- [ ] **Notificação de volta diária** — lembrete para não quebrar o streak (push/web push).
- [ ] **Contas + backend real** — sincronizar streak e pontos entre dispositivos.
- [ ] **Checkout real** — Stripe/Pagar.me para o Pro.
- [ ] **B2B / marcas** — cupons patrocinados no pool de recompensas (a marca paga por exposição e lead).
- [ ] **Relatórios de evolução por IA** — análise do histórico e sugestões personalizadas.
- [ ] **Comunidade VIP** — área de membros.

---

## 🧠 Notas de UX (o que já está aplicado)

- **Aversão à perda:** streak visível em toda a topbar e no painel.
- **Recompensa variável:** roleta com probabilidades diferentes por fatia (efeito caça-níquel positivo).
- **Feedback fisiológico:** confete, som de conquista (WebAudio), vibração em mobile, barra de progresso com glow.
- **Zero atrito:** nenhum formulário; primeiro uso já é jogável.
