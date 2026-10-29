# Changelog

Todas as mudanças relevantes do projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e este projeto segue [Versionamento Semântico](https://semver.org/lang/pt-BR/).

> Categorias usadas: `Adicionado` · `Corrigido` · `Alterado` · `Removido` · `Segurança`

---

## [1.0.4] — 2026-10-29

### Adicionado
- **Pagamento via Pix**: seção dedicada no paywall com QR Code estático gerado
  automaticamente (API pública) e chave Pix `03397789389` para cópia com um clique.
- **Botão de contato via WhatsApp**: após o pagamento, o usuário pode enviar
  comprovante diretamente pelo WhatsApp para liberação manual do acesso Pro.
- **Cópia rápida da chave Pix**: botão dedicado para copiar a chave para a área
  de transferência.

### Alterado
- Paywall (tela de upgrade) agora inclui a seção "Pague via Pix" com botão de
  contato e instruções claras para liberação dos benefícios Pro.
- Função `show()` foi estendida para renderizar o QR Code dinamicamente ao abrir
  a tela de upgrade.

---

## [1.0.3] — 2026-10-29

### Adicionado
- **PWA (Progressive Web App)**: `manifest.json` e `service-worker.js` permitem instalar o NeuroTask na tela inicial do celular e funcionam offline.
- **Hero otimizado para conversão**: seção de urgência com contagem regressiva de vagas, prova social destacada logo abaixo do CTA principal.
- **JSON-LD completo**: adicionados `Review` com autores reais, `bestRating`/`worstRating` na `AggregateRating`, e `screenshot` no `SoftwareApplication`.

### Alterado
- Hero Section: copy mais direta com chamada para ação e urgência de lançamento.
- Painel e paywall mantêm foco em aversão à perda (streak visível em toda a topbar).

---

## [1.0.2] — 2026-10-26

### Adicionado
- **Jornada sequencial por níveis**: 5 etapas (Semente → Faísca → Fogueira → Cometa → Supernova), cada uma desbloqueando a próxima com base na pontuação do usuário.
- **Etapas com 3 desafios cada**: Despertar, Impulso, Foco Total, Mestre do Caos, Lenda — narrativa progressiva com tom de entretenimento.
- **Desafios sequenciais**: dentro de cada etapa, só o próximo não-completado está liberado (os outros ficam com cadeado), criando curiosidade sobre "o que vem depois".
- **Teaser de etapa bloqueada**: exibe o ícone, nome e requisito de nível da próxima etapa, despertando o desejo de avançar.
- Barra de nível com progresso visual e indicação do próximo nível.
- 15 novos desafios com copy de entretenimento e micro-missões variadas (turbo criativo, caça ao desperdício, túnel de foco, chefão da semana, missão impossível, modo mentor, supernova).
- Desafio bônus "Roleta do Caos" para quebrar a rotina.

### Alterado
- Tela de desafios substitui a grade plana por cards de jornada (nível + etapas + desafios sequenciais).

---

## [1.0.1] — 2026-10-21

### Adicionado
- **Baú de recompensa animado**: agora o prêmio aparece visualmente ao abrir — o ícone
  do brinde (⚡ / 🏷️ / 🎖️ / 📦 / 🤖) sobe do baú com brilho, e o tipo do prêmio
  (Pontos, Cupom, Insígnia, Prêmio Pro) aparece em destaque.

### Corrigido
- Timer do desafio blindado: o intervalo agora para ao sair da tela e tem proteção
  contra execução após o encerramento (evita erros de console em sequência).

---

## [1.0.0] — 2026-10-20

Primeira versão pública. MVP completo do sistema de micro-desafios e recompensas,
com camada de persuasão, SEO e pipeline de deploy.

### Adicionado

**Produto (fluxo principal)**
- Tela **Hero** one-button ("Iniciar Micro-Foco · 2 min"), sem cadastro.
- Escolha de micro-desafio com 1 clique (Foco, Economizar, Criar Ideia de Venda, Organizar o Dia).
- **Checklist de 3 passos** com timer (60/90/120/180s), barra de progresso, animação de check e vibração.
- Tela de **Recompensa** com confete, som e pontuação (`base + bônus de tempo + bônus de streak`).
- **Roleta de Bônus (Gacha)** com 8 fatias e recompensa variável (pontos, cupom, insígnia, prêmio Pro).
- **Painel** do usuário: pontos, streak, desafios do dia, insígnias, recompensas e histórico.
- Persistência via `localStorage` (chave `neurotask.v1`), sem backend.
- Limite grátis de 3 desafios/dia, com cards bloqueados e upsell.

**Persuasão & conversão**
- Prova social animada no hero (contadores).
- Tela **Visão de 30 dias** com projeção de progresso e preview bloqueado do Pro.
- Teaser pós-recompensa ("Você sentiu o gosto").
- **Paywall de upgrade**: comparativo Free × Pro, escassez, contagem regressiva, empilhamento de valor, depoimentos e garantia.
- Gatilhos de conversão em 4 pontos do fluxo (Painel, Visão, Teaser, limite diário).

**Indicação & crescimento**
- Bloco "Convide e ganhe" com link `?ref=CODIGO` persistente.
- Bônus de boas-vindas (+50 pontos, +1 giro) para quem entra por indicação.

**SEO**
- Meta tags (`description`, `robots`, `canonical`, palavras-chave), Open Graph e Twitter Card.
- JSON-LD: `Organization`, `WebSite`, `SoftwareApplication` e `FAQPage`.
- FAQ visível com 4 perguntas (alimenta o FAQ rich result).
- `robots.txt`, `sitemap.xml` e cartão social `og.png` (1200×630).
- HTML semântico e `lang="pt-BR"`.

**Deploy & DevOps**
- Deploy automático: `.github/workflows/deploy-cloudflare.yml` e `deploy-netlify.yml`.
- `netlify.toml` (cache, redirecionamentos) e `wrangler.toml`.
- `deploy.ps1` — deploy direto via API (sem git).
- `publish.ps1` — cria repositório no GitHub e faz push (token por cabeçalho temporário).
- `.gitignore` e `.gitattributes` (normalização de finais de linha).

**Documentação & comunidade**
- `README.md` com visão geral, rodar local e badges de deploy.
- `CONTRIBUTING.md` (fluxo, padrões de código, checklist de PR).
- `PUBLICAR-E-CRESCER.md` (hospedagem grátis, SEO, backlinks, parcerias).
- `SETUP-DEPLOY.md` (git + deploy passo a passo).
- Templates de issue (`bug_report`, `feature_request`, `partnership`) e `PULL_REQUEST_TEMPLATE.md`.

### Alterado
- Correção da porta do servidor local de `8731` para `8732`.

### Segurança
- Nenhum segredo é versionado. Tokens de deploy e do GitHub são passados por
  parâmetro/ambiente e nunca gravados no repositório.
- Placeholders de prova social e escassez devem ser substituídos por dados reais
  antes do lançamento (ver `README.md`).

---

## Modelo para versões futuras

```markdown
## [x.y.z] — AAAA-MM-DD

### Adicionado
### Corrigido
### Alterado
### Removido
### Segurança
```

### Tipos de commit (resumo)
`feat:` · `fix:` · `content:` · `style:` · `deploy:` · `docs:` — ver `CONTRIBUTING.md`.
