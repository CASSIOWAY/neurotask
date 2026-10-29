# Contribuindo com o NeuroTask

Obrigado pelo interesse em contribuir! Este guia curto garante que tudo continue consistente.

O NeuroTask é um **site 100% estático** (HTML + CSS + JS puro), **sem build**, **sem dependências**. Agradecemos contribuições em código, conteúdo, tradução, SEO e parcerias.

---

## 1. Como o projeto está organizado

```
neurotask/
├── index.html              # Telas (hero, desafios, recompensa, roleta, painel…)
├── styles.css              # Tema, animações, responsivo
├── app.js                  # Toda a lógica (estado, recompensas, roleta, SEO)
├── og.png                  # Cartão de compartilhamento (1200×630)
├── robots.txt             # Instruções para buscadores
├── sitemap.xml             # Mapa do site
├── netlify.toml            # Deploy (Netlify)
├── wrangler.toml           # Deploy (Cloudflare Pages)
├── deploy.ps1              # Deploy direto via API (sem git)
├── .github/workflows/      # Deploy automático
├── PUBLICAR-E-CRESCER.md   # Guia de hospedagem, SEO e parcerias
├── SETUP-DEPLOY.md         # Guia de git + deploy
└── README.md               # Visão geral
```

---

## 2. Rodando localmente

Não precisa instalar nada além de um navegador.

**Opção A** — abrir direto: dê dois cliques em `index.html`.

**Opção B** — servidor local:
```powershell
powershell -ExecutionPolicy Bypass -File .\serve.ps1
```
Depois abra `http://localhost:8732/`.

> Não há `npm install`, `build` ou `node_modules`. Se precisar de um novo recurso,
> prefira resolver dentro do `app.js` com JavaScript puro.

---

## 3. Fluxo de contribuição

1. **Fork** o repositório e crie uma branch a partir de `main`:
   ```powershell
   git checkout -b minha-contribuicao
   ```
2. Faça suas alterações.
3. Teste no navegador (não deve haver erros no console).
4. Envie com uma mensagem clara:
   ```powershell
   git add .
   git commit -m "tipo: descrição curta"
   git push origin minha-contribuicao
   ```
5. Abra um **Pull Request** para `main`.

---

## 4. Padrões de código

### JavaScript (`app.js`)
- **JavaScript puro**, sem frameworks nem dependências.
- **Identificadores em inglês** (`state`, `renderChallenges`, `pickReward`).
- **Textos visíveis ao usuário em português (pt-BR)**.
- Use `"use strict";` e `var`/`function` no estilo já adotado (compatível com navegadores antigos).
- Nunca exponha segredos (tokens, chaves) no front-end.
- Persistência via `localStorage`, chave `neurotask.v1`. Ao adicionar campos, inclua-os no `defaultState()` para não quebrar quem já usa.

### CSS (`styles.css`)
- Use as variáveis de `:root` (`--violet`, `--teal`, `--bg`, etc.). Não invente cores soltas.
- Mobile-first; respeite `prefers-reduced-motion`.
- Prefira classes semânticas e reutilizáveis.

### HTML (`index.html`)
- HTML semântico (`header`, `main`, `section`, `details`).
- Todo texto novo deve ter versão em pt-BR.
- Ao adicionar conteúdo, mantenha o JSON-LD e o FAQ atualizados (afeta SEO).

### Dados editáveis
Os conteúdos ficam no **topo do `app.js`**: `CHALLENGES`, `REWARD_POOL`, `WHEEL_SLICES`, `BADGES`, `TESTIMONIALS`, `VALUE_STACK`. Para mudar textos do produto, edite lá — não espalhe strings pelo código.

---

## 5. Convenções de commit

Use um prefixo com o tipo:

| Prefixo | Quando usar |
|---|---|
| `feat:` | Nova funcionalidade (ex.: novo tipo de recompensa) |
| `fix:` | Correção de bug |
| `content:` | Textos, copy, SEO, FAQ |
| `style:` | CSS / aparência |
| `deploy:` | Configuração de deploy |
| `docs:` | Documentação (README, CONTRIBUTING) |

Exemplo: `feat: adiciona nova insígnia de streak`

---

## 6. Checklist antes de abrir o PR

- [ ] Abriu o site e testou o fluxo completo (desafio → recompensa → roleta).
- [ ] Nenhum erro no console do navegador.
- [ ] Funciona no celular (largura ~375px).
- [ ] Não adicionei dependências nem build.
- [ ] Textos em pt-BR, sem placeholders visíveis.
- [ ] Atualizei o README/CONTRIBUTING se mudei a estrutura.
- [ ] Emojis e tons de interface seguem o padrão já existente.

---

## 7. Reportando problemas ou pedindo melhorias

Abra uma **Issue** descrevendo:
- O que você esperava vs. o que aconteceu
- Passos para reproduzir
- Navegador e dispositivo
- Screenshot, se ajudar

Para **ideias de parcerias** (marcas patrocinando recompensas), descreva o modelo
proposto (CPC, CPL ou comissão) em uma Issue com a tag `parceria`.

---

## 8. Conduta

Seja respeitoso e construtivo. Este é um projeto de produto real — evite spam,
promoção não solicitada ou conteúdo enganoso. A persuasão do produto deve ser
sempre **honesta**: prova social e escassez só com dados reais.

---

Obrigado por ajudar a transformar caos em clareza! 🚀
