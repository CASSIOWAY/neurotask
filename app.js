/* ============================================================
   NeuroTask / HabitFlow — motor do produto
   Persistência: localStorage (sem backend, sem cadastro)
   ============================================================ */
(function () {
  "use strict";

  /* ---------------- Dados ---------------- */

  /* ---- Níveis (progressão) ---- */
  var LEVELS = [
    { level: 1, name: "Semente",    icon: "🌱", min: 0 },
    { level: 2, name: "Faísca",    icon: "✨", min: 100 },
    { level: 3, name: "Fogueira",  icon: "🔥", min: 250 },
    { level: 4, name: "Cometa",    icon: "☄️", min: 450 },
    { level: 5, name: "Supernova", icon: "🌟", min: 700 }
  ];

  /* ---- Etapas (Jornada) ---- */
  var STAGES = [
    {
      id: "despertar",
      name: "Despertar",
      icon: "🌱",
      sub: "Saia do piloto automático",
      desc: "Três micro-missões para provar que você consegue começar AGORA.",
      unlockLevel: 1,
      reward: "Roleta bônus liberada",
      challenges: [
        {
          id: "despertar-1",
          icon: "⏰",
          title: "Modo Despertador",
          desc: "Acorde seu cérebro em 60 segundos.",
          time: 60,
          steps: [
            { t: "Levante e tome um copo d'água", h: "Hidratar acorda o corpo antes da mente." },
            { t: "Escreva UMA coisa que faria se tivesse 2 horas livres", h: "Só uma. Isso revela o que você realmente quer." },
            { t: "Faça 10 polichinelos ou alongue-se", h: "30 segundos de movimento mudam seu estado." }
          ]
        },
        {
          id: "despertar-2",
          icon: "❓",
          title: "A Pergunta de 1 Minuto",
          desc: "Descubra o que realmente importa hoje.",
          time: 60,
          steps: [
            { t: "Pergunte: 'Se só pudesse fazer UMA coisa hoje, qual seria?'", h: "Sem pensar demais. A primeira resposta é a certa." },
            { t: "Escreva essa coisa em voz alta", h: "Falar consolida a decisão." },
            { t: "Diga: 'vou começar em 2 minutos'", h: "A promessa curta quebra a hesitação." }
          ]
        },
        {
          id: "despertar-3",
          icon: "💪",
          title: "Micro-Coragem",
          desc: "Faça a coisa que você mais vem adiando.",
          time: 90,
          steps: [
            { t: "Identifique a tarefa mais adiada do seu dia", h: "Aquela que está na sua cabeça há dias." },
            { t: "Reduza ela para um passo de 2 minutos", h: "Não 'fazer o relatório'. Abrir o documento." },
            { t: "Faça esse micro-passo agora", h: "Só o começo. O resto flui." }
          ]
        }
      ]
    },
    {
      id: "impulso",
      name: "Impulso",
      icon: "✨",
      sub: "Acelere e ganhe momentum",
      desc: "Etapa 2 desbloqueada! Agora o jogo acelera.",
      unlockLevel: 2,
      reward: "Recompensas em dobro por 1 dia",
      challenges: [
        {
          id: "impulso-1",
          icon: "💡",
          title: "Turbo Criativo",
          desc: "Crie uma ideia de venda em 120 segundos.",
          time: 120,
          steps: [
            { t: "Escolha 1 pessoa que você conhece e que tem um problema", h: "Amigo, colega, cliente." },
            { t: "Escreva a oferta em 1 frase: 'Ajudo X a conseguir Y por Z'", h: "Simples e direta. Sem enfeite." },
            { t: "Envie para 1 pessoa pedir opinião", h: "Ação real, não só na cabeça." }
          ]
        },
        {
          id: "impulso-2",
          icon: "🕵️",
          title: "Caça ao Desperdício",
          desc: "Encontre dinheiro escondido em 90 segundos.",
          time: 90,
          steps: [
            { t: "Abra o app do banco e role os últimos lançamentos", h: "Sem julgar. Só observe." },
            { t: "Circule 3 gastos que você cortaria sem dor", h: "Assinaturas, delivery, compras por impulso." },
            { t: "Escolha 1 e cancele agora", h: "Uma economia real hoje vale ouro." }
          ]
        },
        {
          id: "impulso-3",
          icon: "⚡",
          title: "Desafio Relâmpago",
          desc: "3 decisões rápidas, zero hesitação.",
          time: 60,
          steps: [
            { t: "Liste 3 decisões pendentes que você vem adiando", h: "Pequenas, mas que pesam." },
            { t: "Decida cada uma em 10 segundos", h: "Regra: nunca demore mais que 10s por decisão." },
            { t: "Execute a decisão nº 1 imediatamente", h: "Decidir sem agir é enfeitar a gaveta." }
          ]
        }
      ]
    },
    {
      id: "foco",
      name: "Foco Total",
      icon: "🔥",
      sub: "Entre no modo profundo",
      desc: "Etapa 3! Aqui o foco vira superpoder.",
      unlockLevel: 3,
      reward: "Insígnia de Foco Profundo",
      challenges: [
        {
          id: "foco-1",
          icon: "🎯",
          title: "Túnel de Foco",
          desc: "25 minutos de trabalho profundo sem distração.",
          time: 120,
          steps: [
            { t: "Feche tudo: abas, notificações, celular no modo avião", h: "Fora da vista, fora da mente." },
            { t: "Defina UMA tarefa para os próximos 25 minutos", h: "Escreva no papel. Só uma." },
            { t: "Comece pelo primeiro micro-passo de 2 minutos", h: "O difícil é começar. Depois o fluxo pega." }
          ]
        },
        {
          id: "foco-2",
          icon: "🗺️",
          title: "Dia Ideal em 60s",
          desc: "Projete um dia perfeito e execute o 1º passo.",
          time: 60,
          steps: [
            { t: "Desenhe seu dia ideal em 3 blocos: manhã, tarde, noite", h: "Papel e caneta. Sem perfeccionismo." },
            { t: "Escolha o bloco da manhã e a tarefa nº 1 dele", h: "O começo do dia define o resto." },
            { t: "Agende essa tarefa em um horário fixo hoje", h: "Horário fixo vence força de vontade." }
          ]
        },
        {
          id: "foco-3",
          icon: "🛡️",
          title: "Resistência à Distração",
          desc: "Vença 1 tentação hoje e prove que pode.",
          time: 90,
          steps: [
            { t: "Identifique sua maior fonte de distração hoje", h: "Celular? Redes? Interrupções?" },
            { t: "Crie 1 barreira física contra ela", h: "Celular em outro cômodo, app bloqueado, porta fechada." },
            { t: "Trabalhe 15 minutos focado e comemore", h: "15 minutos de foco real valem 2 horas de distração." }
          ]
        }
      ]
    },
    {
      id: "mestre",
      name: "Mestre do Caos",
      icon: "🌪️",
      sub: "Transforme bagunça em sistema",
      desc: "Etapa 4 — quase lenda. O caos aqui vira sistema.",
      unlockLevel: 4,
      reward: "Acesso ao Desafio Secreto",
      challenges: [
        {
          id: "mestre-1",
          icon: "🧠",
          title: "Despejo Mental",
          desc: "Esvazie a mente em 60 segundos.",
          time: 60,
          steps: [
            { t: "Despeje TUDO que está na cabeça no papel", h: "Brain dump de 60s, sem ordem e sem filtro." },
            { t: "Circule o que só VOCÊ pode fazer", h: "O resto delegue ou delete." },
            { t: "Escolha a prioridade nº 1 e o horário dela", h: "Uma coisa. Um horário. Feito." }
          ]
        },
        {
          id: "mestre-2",
          icon: "⚙️",
          title: "Sistema Anti-Procrastinação",
          desc: "Monte seu kit pessoal de foco.",
          time: 120,
          steps: [
            { t: "Liste seus 3 maiores gatilhos de procrastinação", h: "O que te faz travar?" },
            { t: "Crie 1 regra para cada gatilho", h: "Ex.: 'se abrir o celular, volto em 2 minutos'." },
            { t: "Teste 1 regra agora por 10 minutos", h: "Regra não testada é só enfeite." }
          ]
        },
        {
          id: "mestre-3",
          icon: "👹",
          title: "Chefão: A Semana",
          desc: "Planeje 5 dias em 180 segundos. Derrote o Chefão.",
          time: 180,
          steps: [
            { t: "Escreva 1 prioridade para cada dia da semana", h: "Seg a Sex. Só uma por dia." },
            { t: "Bloqueie o horário de cada prioridade na agenda", h: "Sem horário marcado, não acontece." },
            { t: "Defina 1 recompensa para completar a semana", h: "O cérebro trabalha melhor com prêmio à vista." }
          ]
        }
      ]
    },
    {
      id: "lenda",
      name: "Lenda",
      icon: "👑",
      sub: "Onde poucos chegam",
      desc: "Etapa final. Desafios que transformam hábito em identidade.",
      unlockLevel: 5,
      reward: "Título de Supernova + recompensas exclusivas",
      challenges: [
        {
          id: "lenda-1",
          icon: "🚀",
          title: "Missão Impossível",
          desc: "O maior desafio do dia. Você topa?",
          time: 180,
          steps: [
            { t: "Escolha a coisa que você mais adia há semanas", h: "Aquela que dá frio na barriga." },
            { t: "Divida em 5 micro-passos de 5 minutos", h: "Impossível vira só mais um passo." },
            { t: "Faça o primeiro agora", h: "Começou é 50% do caminho." }
          ]
        },
        {
          id: "lenda-2",
          icon: "🧙",
          title: "Modo Mentor",
          desc: "Ensinar é a prova máxima de que você domina.",
          time: 120,
          steps: [
            { t: "Escolha algo que você aprendeu e pode ensinar", h: "Pode ser simples. Simples é útil." },
            { t: "Explique em 3 frases para alguém (ou para o espelho)", h: "Se não consegue explicar simples, não entendeu." },
            { t: "Envie esse ensinamento para 1 pessoa", h: "Conhecimento compartilhado multiplica." }
          ]
        },
        {
          id: "lenda-3",
          icon: "🌟",
          title: "Supernova",
          desc: "Desafio secreto: crie o seu próprio micro-desafio.",
          time: 180,
          steps: [
            { t: "Pense em 1 área da sua vida que merece um empurrão", h: "Saúde, dinheiro, relacionamento, trabalho..." },
            { t: "Crie um micro-desafio de 3 passos para ela", h: "Você é o mestre agora." },
            { t: "Combine consigo: quando e onde vai fazer", h: "Compromisso marcado vira hábito." }
          ]
        }
      ]
    }
  ];

  /* ---- Desafio bônus (surpresa) ---- */
  var BONUS_CHALLENGE = {
    id: "bonus-caos",
    icon: "🎲",
    title: "Roleta do Caos",
    desc: "Um desafio aleatório para quebrar a rotina.",
    time: 60,
    steps: [
      { t: "Escolha um número de 1 a 10 agora", h: "Sem pensar demais." },
      { t: "Faça esse número de polichinelos, agachamentos ou alongamentos", h: "Sua energia muda com movimento." },
      { t: "Escreva 1 coisa que ficou clara depois do movimento", h: "Mente parada não resolve; corpo em movimento clareia." }
    ]
  };

  var FRASES_DE_EFEITO = [
    "Mandou bem! 🚀",
    "Isso foi quase mágico. ✨",
    "Seu cérebro agradece. 🧠",
    "Pequeno passo, grande vitória. 🏆",
    "Você está em chamas! 🔥",
    "Imparável. ⚡",
    "Até o próximo nível. 🎮",
    "Modo lenda ativado. 👑"
  ];

  function fraseDeEfeito() {
    return FRASES_DE_EFEITO[(Math.random() * FRASES_DE_EFEITO.length) | 0];
  }

  function getLevel(points) {
    var current = LEVELS[0];
    for (var i = 0; i < LEVELS.length; i++) {
      if (points >= LEVELS[i].min) current = LEVELS[i];
    }
    var next = null;
    for (var j = 0; j < LEVELS.length; j++) {
      if (LEVELS[j].min > points) { next = LEVELS[j]; break; }
    }
    var progress = next ? Math.min(100, Math.round((points - current.min) / (next.min - current.min) * 100)) : 100;
    return { current: current, next: next, progress: progress };
  }

  /* ---------------- Jornada / níveis ---------------- */

  function isChallengeCompleted(challengeId) {
    return state.completedChallenges.indexOf(challengeId) !== -1;
  }

  function completeChallengeId(challengeId) {
    if (isChallengeCompleted(challengeId)) return false;
    state.completedChallenges.push(challengeId);
    return true;
  }

  function stageDoneCount(stage) {
    var done = 0;
    stage.challenges.forEach(function (c) {
      if (isChallengeCompleted(c.id)) done += 1;
    });
    return done;
  }

  function stageIsComplete(stage) {
    return stage.challenges.every(function (c) { return isChallengeCompleted(c.id); });
  }

  function unlockStage(stageId) {
    if (state.unlockedStages.indexOf(stageId) !== -1) return;
    state.unlockedStages.push(stageId);
    save();
    toast("🎉 Etapa desbloqueada: " + stageId);
    confetti(80);
  }

  function getUnlockedStages() {
    var level = getLevel(state.points);
    return STAGES.filter(function (s) {
      return state.unlockedStages.indexOf(s.id) !== -1 || s.unlockLevel <= level.current.level;
    });
  }

  function isStageUnlocked(stage) {
    return state.unlockedStages.indexOf(stage.id) !== -1;
  }

  function getNextLockedStage() {
    for (var i = 0; i < STAGES.length; i++) {
      if (state.unlockedStages.indexOf(STAGES[i].id) === -1) return STAGES[i];
    }
    return null;
  }

  var REWARD_POOL = [
    { icon: "🏷️", name: "Cupom: 15% off na loja parceira", meta: "Válido por 48h", tier: "free", w: 30 },
    { icon: "🎖️", name: "Insígnia de Nível: Focador Iniciante", meta: "Desbloqueada no perfil", tier: "free", w: 20 },
    { icon: "📊", name: "Métricas visuais liberadas", meta: "Veja seu mapa de produtividade", tier: "free", w: 20 },
    { icon: "🧠", name: "Dica Pro: ancoragem de hábito", meta: "Conteúdo exclusivo", tier: "premium", w: 12 },
    { icon: "📦", name: "Template pronto de rotina matinal", meta: "Baixável, editável", tier: "premium", w: 10 },
    { icon: "🤖", name: "5 créditos de IA para automação", meta: "Use no painel Pro", tier: "premium", w: 8 }
  ];

  var WHEEL_SLICES = [
    { label: "+5 ⚡", color: "#7c5cff", kind: "points", value: 5, emoji: "⚡" },
    { label: "Cupom", color: "#00e0c6", kind: "coupon", emoji: "🏷️" },
    { label: "+10 ⚡", color: "#ffc94d", kind: "points", value: 10, emoji: "⚡" },
    { label: "Insígnia", color: "#ff4d8d", kind: "badge", emoji: "🎖️" },
    { label: "+15 ⚡", color: "#7c5cff", kind: "points", value: 15, emoji: "⚡" },
    { label: "Templates", color: "#00e0c6", kind: "premium", emoji: "📦" },
    { label: "+25 ⚡", color: "#ffc94d", kind: "points", value: 25, emoji: "⚡" },
    { label: "IA 5cr", color: "#ff4d8d", kind: "premium", value: 5, emoji: "🤖" }
  ];

  var BADGES = [
    { id: "primeiro", icon: "🌱", name: "Primeira Vitória", need: 1 },
    { id: "tres", icon: "🔥", name: "Trinca", need: 3 },
    { id: "dez", icon: "⚡", name: "Dopamina Alta", need: 10 },
    { id: "streak3", icon: "📅", name: "3 Dias Seguidos", need: "streak3" },
    { id: "streak7", icon: "👑", name: "Imparável (7 dias)", need: "streak7" }
  ];

  /* ---- Persuasão ---- */
  var TESTIMONIALS = [
    { stars: "★★★★★", text: "Em 2 semanas saí do modo 'apagando incêndio' para ter 3 prioridades claras por dia.", who: "Marina S., <b>empreendedora</b>" },
    { stars: "★★★★★", text: "A roleta virou meu gatilho. Termino o micro-desafio só para girar. E o hábito ficou.", who: "Rafael T., <b>estudante de concursos</b>" },
    { stars: "★★★★★", text: "O streak me obrigou a não quebrar. 21 dias depois, organizo a semana em 60 segundos.", who: "Camila R., <b>gerente de projetos</b>" },
    { stars: "★★★★★", text: "O cashback do Pro pagou a assinatura no primeiro mês. Retorno instantâneo.", who: "Diego M., <b>freelancer</b>" }
  ];

  var VALUE_STACK = [
    { icon: "💸", name: "Cashback real com lojas parceiras", val: "até R$ 30/mês" },
    { icon: "📈", name: "Relatório de evolução por IA", val: "R$ 49/mês" },
    { icon: "📦", name: "Templates de alta conversão", val: "R$ 29/mês" },
    { icon: "🤖", name: "Ferramentas de automação", val: "R$ 39/mês" }
  ];

  var OFFER_HOURS = 24;        // duração da oferta de lançamento
  var SEATS_START = 42;        // vagas "restantes" iniciais (fins de urgência)
  var SEATS_MIN = 12;

  var OFFER_KEY = "neurotask.offer";
  var SEATS_KEY = "neurotask.seats";
  var PRO_PRICE = "R$ 19,90/mês";

  var FREE_DAILY_LIMIT = 3;
  var KEY = "neurotask.v1";

  /* ---------------- Estado ---------------- */

  function todayStr() {
    var d = new Date();
    return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
  }
  function yesterdayStr() {
    var d = new Date();
    d.setDate(d.getDate() - 1);
    return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
  }

  function defaultState() {
    return {
      points: 0,
      streak: 0,
      lastActiveDay: null,
      challengesToday: 0,
      dayStamp: todayStr(),
      totalCompleted: 0,
      pro: false,
      pendingSpins: 0,
      spinsUsedToday: 0,
      spinDayStamp: todayStr(),
      rewards: [],
      history: [],
      unlockedBadges: [],
      refCode: null,
      referredBy: null,
      welcomeClaimed: false,
      completedChallenges: [],
      unlockedStages: ["despertar"],
      stageUnlockedTeaser: null
    };
  }

  function load() {
    try {
      var raw = localStorage.getItem(KEY);
      if (!raw) return defaultState();
      var s = JSON.parse(raw);
      var d = defaultState();
      for (var k in d) if (!(k in s)) s[k] = d[k];
      return s;
    } catch (e) {
      return defaultState();
    }
  }
  function save() {
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
  }

  var state = load();

  /* ---------------- Utilidades ---------------- */

  function $(sel) { return document.querySelector(sel); }
  function $$(sel) { return Array.prototype.slice.call(document.querySelectorAll(sel)); }

  function toast(msg) {
    var el = $("#toast");
    el.textContent = msg;
    el.classList.add("show");
    clearTimeout(toast._t);
    toast._t = setTimeout(function () { el.classList.remove("show"); }, 2600);
  }

  function vibrate(pattern) {
    if (navigator.vibrate) { try { navigator.vibrate(pattern); } catch (e) {} }
  }

  /* ---- Som (WebAudio, sem arquivos) ---- */
  var audioCtx = null;
  function beep(freq, dur, delay, type) {
    try {
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      var t = audioCtx.currentTime + (delay || 0);
      var o = audioCtx.createOscillator();
      var g = audioCtx.createGain();
      o.type = type || "sine";
      o.frequency.setValueAtTime(freq, t);
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(0.18, t + 0.01);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      o.connect(g); g.connect(audioCtx.destination);
      o.start(t); o.stop(t + dur + 0.02);
    } catch (e) {}
  }
  function soundClick() { beep(520, 0.09, 0, "triangle"); }
  function soundWin() {
    beep(523, 0.14, 0); beep(659, 0.14, 0.1); beep(784, 0.18, 0.2); beep(1047, 0.3, 0.3);
  }
  function soundSpin() { beep(300, 0.06, 0, "sawtooth"); }

  /* ---- Confete ---- */
  var canvas = $("#confetti"), ctx = canvas.getContext("2d");
  var particles = [], rafId = null;
  function sizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }
  window.addEventListener("resize", sizeCanvas);
  sizeCanvas();

  function confetti(count) {
    var colors = ["#7c5cff", "#00e0c6", "#ffc94d", "#ff4d8d", "#ffffff"];
    for (var i = 0; i < (count || 120); i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: -20 - Math.random() * canvas.height * 0.3,
        vx: (Math.random() - 0.5) * 4,
        vy: 2 + Math.random() * 4,
        size: 5 + Math.random() * 7,
        color: colors[(Math.random() * colors.length) | 0],
        rot: Math.random() * Math.PI,
        vr: (Math.random() - 0.5) * 0.3
      });
    }
    if (!rafId) loop();
  }
  function loop() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    particles = particles.filter(function (p) { return p.y < canvas.height + 40; });
    for (var i = 0; i < particles.length; i++) {
      var p = particles[i];
      p.x += p.vx; p.y += p.vy; p.rot += p.vr;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);
      ctx.fillStyle = p.color;
      ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size * 0.6);
      ctx.restore();
    }
    if (particles.length) {
      rafId = requestAnimationFrame(loop);
    } else {
      rafId = null;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
    }
  }

  /* ---------------- Navegação ---------------- */

  function show(id) {
    $$(".screen").forEach(function (s) { s.classList.remove("active"); });
    var el = document.getElementById(id);
    if (el) el.classList.add("active");
    if (id !== "screen-upgrade") stopCountdown();
    if (id !== "screen-challenge") stopTimer();
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  /* ---------------- Streak ---------------- */

  function registerActivityDay() {
    var t = todayStr();
    if (state.dayStamp !== t) {
      state.dayStamp = t;
      state.challengesToday = 0;
    }
    if (state.spinDayStamp !== t) {
      state.spinDayStamp = t;
      state.spinsUsedToday = 0;
    }
    if (state.lastActiveDay !== t) {
      if (state.lastActiveDay === yesterdayStr()) state.streak += 1;
      else state.streak = 1;
      state.lastActiveDay = t;
      if (state.streak > 1) toast("🔥 Você está no dia " + state.streak + " seguido!");
    }
  }

  function canPlay() {
    if (state.pro) return true;
    return state.challengesToday < FREE_DAILY_LIMIT;
  }

  /* ---------------- Render: desafios ---------------- */

  function renderChallenges() {
    var grid = $("#challenge-grid");
    grid.innerHTML = "";
    var limitReached = !canPlay();

    // Barra de nível / progresso
    var lvl = getLevel(state.points);
    var levelBar = document.createElement("div");
    levelBar.className = "level-bar";
    levelBar.innerHTML =
      '<div class="level-info"><span class="level-icon">' + lvl.current.icon + '</span>' +
      '<span class="level-name">Nível ' + lvl.current.level + ' · ' + lvl.current.name + '</span>' +
      '<span class="level-points">' + state.points + " pts</span></div>" +
      '<div class="level-progress"><div class="level-fill" style="width:' + lvl.progress + '%"></div></div>' +
      (lvl.next ? '<div class="level-next">Próximo: ' + lvl.next.icon + ' ' + lvl.next.name + " (" + lvl.next.min + " pts)" + "</div>" : "");
    grid.appendChild(levelBar);

    // Teaser da próxima etapa bloqueada (curiosidade)
    var nextLocked = getNextLockedStage();
    if (nextLocked && !state.pro) {
      var teaser = document.createElement("div");
      teaser.className = "ch-card locked stage-teaser";
      teaser.innerHTML =
        '<span class="ch-ico">' + nextLocked.icon + '</span>' +
        "<h3>" + nextLocked.name + " (bloqueada)</h3>" +
        "<p>" + nextLocked.desc + "</p>" +
        '<div class="teaser-lock">🔓 Alcançe o nível ' + nextLocked.unlockLevel + " para desbloquear</div>";
      grid.appendChild(teaser);
    }

    // Etapas desbloqueadas
    var stages = getUnlockedStages();
    stages.forEach(function (stage) {
      var done = stageDoneCount(stage);
      var complete = stageIsComplete(stage);

      var stageCard = document.createElement("div");
      stageCard.className = "stage-card";
      stageCard.innerHTML =
        '<div class="stage-header">' +
        '<span class="stage-ico">' + stage.icon + '</span>' +
        '<div class="stage-info"><div class="stage-title">' + stage.name + '</div>' +
        '<div class="stage-sub">' + stage.sub + '</div></div>' +
        '<div class="stage-progress-chip">' + done + "/3</div></div>" +
        '<p class="stage-desc">' + stage.desc + '</p>';

      // Desafios da etapa
      stage.challenges.forEach(function (c, idx) {
        var doneC = isChallengeCompleted(c.id);
        var isCurrent = (!doneC && idx === 0) || (doneC === idx && idx < stage.challenges.length);
        var unlocked = doneC || (idx === 0) || (done === idx && idx < stage.challenges.length);
        // só libera o próximo não-completado
        var reallyUnlocked = unlocked && (idx === 0 || isChallengeCompleted(stage.challenges[idx - 1].id));

        stageCard.innerHTML +=
          '<div class="step-card' + (doneC ? " done" : "") + (reallyUnlocked && !limitReached ? "" : " locked") + '">' +
          '<span class="step-num">' + (idx + 1) + '</span>' +
          '<span class="step-ico">' + c.icon + '</span>' +
          '<div class="step-info"><div class="step-title">' + c.title + '</div>' +
          '<div class="step-desc">' + c.desc + '</div></div>' +
          '<span class="step-time">' + c.time + "s</span>" +
          (doneC ? '<span class="step-ok">✓</span>' : (!reallyUnlocked ? '<span class="step-lock">🔒</span>' : '')) +
          '</div>';
      });

      stageCard.innerHTML +=
        (complete ? '<div class="stage-complete">✅ Etapa completa! ' + stage.reward + '</div>' :
          '<div class="stage-next">Próximo desafio: ' + (stage.challenges[done] ? stage.challenges[done].title : '—') + '</div>');

      grid.appendChild(stageCard);
    });

    var remaining = state.pro ? "ilimitados" : Math.max(0, FREE_DAILY_LIMIT - state.challengesToday);
    $("#daily-note").textContent = state.pro
      ? "Plano Pro ativo — desafios ilimitados hoje."
      : "Você tem " + remaining + " micro-desafio(s) grátis restante(s) hoje. Pro libera ilimitado.";

    // Evento de clique nos desafios da etapa
    $$(".step-card").forEach(function (card) {
      if (card.classList.contains("locked") || card.classList.contains("done")) return;
      var title = card.querySelector(".step-title").textContent;
      var stageCard = card.closest ? card.closest(".stage-card") : null;
      var challenge = null;
      if (stageCard) {
        var stageName = stageCard.querySelector(".stage-title").textContent;
        var foundStage = STAGES.find(function (s) { return s.name === stageName; });
        if (foundStage) {
          challenge = foundStage.challenges.find(function (c) { return c.title === title; });
        }
      }
      card.addEventListener("click", function () {
        if (limitReached) return;
        if (!challenge) return;
        soundClick();
        startChallenge(challenge);
      });
      card.style.cursor = "pointer";
    });
  }

  /* ---------------- Execução do desafio ---------------- */

  var active = null; // { challenge, done:Set, timer, remaining, startTime }

  function startChallenge(c) {
    active = {
      challenge: c,
      done: {},
      remaining: c.time,
      startTime: Date.now(),
      interval: null
    };

    $("#ch-icon").textContent = c.icon;
    $("#ch-title").textContent = c.title;
    $("#ch-desc").textContent = c.desc;
    $("#timer-num").textContent = c.time;
    $("#progress-fill").style.width = "0%";
    $("#btn-complete").disabled = true;
    setRing(0);

    var list = $("#steps");
    list.innerHTML = "";
    c.steps.forEach(function (step, i) {
      var li = document.createElement("li");
      li.className = "step";
      li.setAttribute("role", "checkbox");
      li.setAttribute("aria-checked", "false");
      li.tabIndex = 0;
      li.innerHTML =
        '<span class="box">' + (i + 1) + "</span>" +
        "<p>" + step.t + '<span class="hint">' + step.h + "</span></p>";
      li.addEventListener("click", function () { toggleStep(i, li); });
      li.addEventListener("keydown", function (e) {
        if (e.key === "Enter" || e.key === " ") { e.preventDefault(); toggleStep(i, li); }
      });
      list.appendChild(li);
    });

    show("screen-challenge");
    startTimer();
  }

  function toggleStep(i, li) {
    if (active.done[i]) {
      delete active.done[i];
      li.classList.remove("done");
      li.setAttribute("aria-checked", "false");
    } else {
      active.done[i] = true;
      li.classList.add("done");
      li.setAttribute("aria-checked", "true");
      vibrate(30);
      beep(660, 0.08, 0, "triangle");
    }
    updateProgress();
  }

  function updateProgress() {
    var total = active.challenge.steps.length;
    var doneCount = Object.keys(active.done).length;
    $("#progress-fill").style.width = (doneCount / total * 100) + "%";
    $("#btn-complete").disabled = doneCount < total;
  }

  function setRing(frac) {
    var C = 2 * Math.PI * 52;
    $("#ring-fg").style.strokeDashoffset = String(C * (1 - frac));
  }

  function stopTimer() {
    if (active && active.interval) {
      clearInterval(active.interval);
      active.interval = null;
    }
  }

  function startTimer() {
    stopTimer();
    active.interval = setInterval(function () {
      if (!active) { clearInterval(active.interval); return; }
      active.remaining -= 1;
      if (active.remaining <= 0) {
        active.remaining = 0;
        clearInterval(active.interval);
        toast("⏱️ Tempo esgotado — conclua os passos para garantir a recompensa!");
      }
      $("#timer-num").textContent = active.remaining;
      setRing(active.remaining / active.challenge.time);
    }, 1000);
  }

  function completeChallenge() {
    if (!active) return;
    stopTimer();

    var c = active.challenge;
    var elapsed = (Date.now() - active.startTime) / 1000;
    var timeBonus = Math.max(0, Math.round((c.time - elapsed) / 10)); // até ~10 pts
    var streakBonus = Math.min(state.streak * 2, 10);
    var base = 10;
    var gained = base + timeBonus + streakBonus;

    registerActivityDay();
    state.points += gained;
    state.challengesToday += 1;
    state.totalCompleted += 1;
    state.pendingSpins += 1;

    // Marca o desafio como concluído na jornada
    var justCompleted = completeChallengeId(c.id);
    var stage = STAGES.find(function (s) {
      return s.challenges.some(function (x) { return x.id === c.id; });
    });
    if (justCompleted && stage && stageIsComplete(stage)) {
      // Desbloqueia a próxima etapa na ordem
      var idx = STAGES.indexOf(stage);
      var nextStage = STAGES[idx + 1];
      if (nextStage) unlockStage(nextStage.id);
    }

    var reward = pickReward();
    state.rewards.unshift(reward);
    state.history.unshift({ when: new Date().toISOString(), title: c.title, points: gained });

    checkBadges();
    save();
    renderTopbar();

    // Tela de recompensa
    $("#reward-title").textContent = "Micro-vitória desbloqueada!";
    $("#reward-sub").textContent = "Você acaba de dar ao seu cérebro a dose de dopamina que faltava.";
    $("#reward-tag").textContent = reward.tier === "premium" ? "RECOMPENSA PRO" : "RECOMPENSA";
    $("#reward-ico").textContent = reward.icon;
    $("#reward-name").textContent = reward.name;
    $("#reward-meta").textContent = reward.meta;
    $("#points-pop").textContent = "+" + gained + " ⚡";
    $("#chest-label").textContent = "Girar Roleta de Bônus";

    show("screen-reward");
    var stage = $("#reward-stage");
    stage.classList.remove("win");
    void stage.offsetWidth; // reinicia animação
    stage.classList.add("win");

    soundWin();
    vibrate([40, 40, 80]);
    confetti(140);
    active = null;
  }

  function pickReward() {
    var pool = REWARD_POOL.filter(function (r) {
      return r.tier === "free" || state.pro;
    });
    var totalW = pool.reduce(function (s, r) { return s + r.w; }, 0);
    var r = Math.random() * totalW;
    for (var i = 0; i < pool.length; i++) {
      r -= pool[i].w;
      if (r <= 0) return { icon: pool[i].icon, name: pool[i].name, meta: pool[i].meta, tier: pool[i].tier };
    }
    return pool[0];
  }

  function checkBadges() {
    BADGES.forEach(function (b) {
      if (state.unlockedBadges.indexOf(b.id) !== -1) return;
      var ok = false;
      if (b.need === "streak3") ok = state.streak >= 3;
      else if (b.need === "streak7") ok = state.streak >= 7;
      else ok = state.totalCompleted >= b.need;
      if (ok) {
        state.unlockedBadges.push(b.id);
        toast("🎖️ Insígnia desbloqueada: " + b.name);
        confetti(60);
      }
    });
  }

  /* ---------------- Roleta ---------------- */

  var spinning = false;

  function buildWheel() {
    var wheel = $("#wheel");
    var labelsBox = $("#wheel-labels");
    var n = WHEEL_SLICES.length;
    var slice = 360 / n;
    var stops = [];
    for (var i = 0; i < n; i++) {
      stops.push(WHEEL_SLICES[i].color + " " + (i * slice) + "deg " + ((i + 1) * slice) + "deg");
    }
    wheel.style.background = "conic-gradient(" + stops.join(",") + ")";
    labelsBox.innerHTML = "";

    var radius = wheel.clientWidth / 2 - 20;
    for (var j = 0; j < n; j++) {
      var center = (j + 0.5) * slice;
      var label = document.createElement("div");
      label.className = "wheel-slice";
      label.textContent = WHEEL_SLICES[j].label;
      label.style.transform =
        "translate(-50%,-50%) rotate(" + center + "deg) translateY(-" + radius + "px)";
      labelsBox.appendChild(label);
    }
  }

  function spinWheel() {
    if (spinning) return;
    if (state.pendingSpins <= 0) {
      toast("Conclua um micro-desafio para ganhar um giro.");
      return;
    }
    spinning = true;
    state.pendingSpins -= 1;
    state.spinsUsedToday += 1;
    save();

    var n = WHEEL_SLICES.length;
    var slice = 360 / n;
    var idx = (Math.random() * n) | 0;
    var center = (idx + 0.5) * slice;
    var target = 360 * 5 + (360 - center);
    var wheel = $("#wheel");
    wheel.style.transform = "rotate(" + target + "deg)";

    soundSpin();
    vibrate(20);
    var ticks = 0;
    var tick = setInterval(function () {
      ticks++;
      if (ticks % 6 === 0) beep(440 + ticks * 4, 0.03, 0, "square");
    }, 60);

    setTimeout(function () {
      clearInterval(tick);
      spinning = false;
      landOnSlice(WHEEL_SLICES[idx]);
    }, 4300);
  }

  function landOnSlice(slice) {
    var title = "", desc = "", tag = "";
    if (slice.kind === "points") {
      state.points += slice.value;
      title = "+" + slice.value + " pontos!";
      desc = "Energia extra somada ao seu saldo. Continue assim.";
      tag = "PONTOS";
    } else if (slice.kind === "coupon") {
      var r = pickReward();
      state.rewards.unshift({ icon: "🏷️", name: "Cupom bônus: " + r.name, meta: r.meta, tier: "free" });
      title = "Cupom surpresa!";
      desc = r.name + " — " + r.meta;
      tag = "CUPOM";
    } else if (slice.kind === "badge") {
      state.rewards.unshift({ icon: "🎖️", name: "Insígnia bônus da roleta", meta: "Coleção exclusiva", tier: "free" });
      title = "Insígnia rara!";
      desc = "Uma insígnia que poucos vão ter. Guarde no seu perfil.";
      tag = "INSÍGNIA";
    } else {
      var p = pickReward();
      state.rewards.unshift(p);
      title = "Prêmio PRO na roleta!";
      desc = p.name + " — " + p.meta;
      tag = "PRÊMIO PRO";
    }
    save();
    renderTopbar();

    $("#chest-title").textContent = title;
    $("#chest-desc").textContent = desc;
    $("#prize-emoji").textContent = slice.emoji || "🎁";
    $("#prize-tag").textContent = tag;

    // esconde a roleta e mostra o baú
    $$(".wheel-wrap").forEach(function (w) { w.classList.add("hidden"); });
    var result = $("#chest-result");
    result.classList.remove("hidden");
    result.classList.remove("revealed");
    // força reflow para reiniciar as animações
    void result.offsetWidth;
    result.classList.add("revealed");

    var chest = $("#chest");
    chest.classList.remove("open");
    void chest.offsetWidth;
    chest.classList.add("open");

    soundWin();
    vibrate([50, 40, 90]);
    confetti(90);
  }

  /* ---------------- Painel ---------------- */

  function renderPanel() {
    renderTopbar();
    $("#panel-today").textContent = state.challengesToday + "/" + (state.pro ? "∞" : FREE_DAILY_LIMIT);
    $("#panel-total").textContent = state.totalCompleted;
    $("#streak-sub").textContent = state.streak === 1 ? "dia seguido" : "dias seguidos";

    // insígnias
    var bwrap = $("#badges");
    bwrap.innerHTML = "";
    BADGES.forEach(function (b) {
      var unlocked = state.unlockedBadges.indexOf(b.id) !== -1;
      var el = document.createElement("span");
      el.className = "badge" + (unlocked ? "" : " locked");
      el.textContent = (unlocked ? b.icon + " " : "🔒 ") + b.name;
      bwrap.appendChild(el);
    });

    // recompensas
    var rl = $("#reward-list");
    rl.innerHTML = "";
    if (!state.rewards.length) {
      rl.innerHTML = "<li>Nenhuma recompensa ainda. Conclua um micro-desafio!</li>";
    } else {
      state.rewards.slice(0, 12).forEach(function (r) {
        var li = document.createElement("li");
        li.innerHTML = "<span>" + r.icon + " " + r.name + "</span><small>" + (r.tier === "premium" ? "PRO" : "free") + "</small>";
        rl.appendChild(li);
      });
    }

    // histórico
    var hl = $("#history-list");
    hl.innerHTML = "";
    if (!state.history.length) {
      hl.innerHTML = "<li>Sem histórico ainda.</li>";
    } else {
      state.history.slice(0, 8).forEach(function (h) {
        var d = new Date(h.when);
        var li = document.createElement("li");
        li.innerHTML = "<span>" + h.title + "</span><b>+" + h.points + " ⚡ · " +
          d.toLocaleDateString("pt-BR") + "</b>";
        hl.appendChild(li);
      });
    }
  }

  function renderTopbar() {
    $$("[data-points]").forEach(function (e) { e.textContent = state.points; });
    $$("[data-streak]").forEach(function (e) { e.textContent = state.streak; });
    var hint = $("#cta-hint");
    if (hint) {
      hint.textContent = state.pro
        ? "Desafios ilimitados · Pro ativo"
        : Math.max(0, FREE_DAILY_LIMIT - state.challengesToday) + " desafios grátis hoje";
    }
  }

  /* ---------------- Persuasão ---------------- */

  function animateCounters() {
    $$("[data-count-to]").forEach(function (el) {
      var target = parseInt(el.getAttribute("data-count-to"), 10);
      var dur = 1600, start = null;
      function step(ts) {
        if (!start) start = ts;
        var p = Math.min((ts - start) / dur, 1);
        var eased = 1 - Math.pow(1 - p, 3);
        el.textContent = Math.round(target * eased).toLocaleString("pt-BR");
        if (p < 1) requestAnimationFrame(step);
      }
      requestAnimationFrame(step);
    });
  }

  function renderVision() {
    var perDay = state.pro ? 5 : 3;
    var days = 30;
    var cards = [
      { ico: "🔥", num: days, label: "dias de streak", sub: "sequência ininterrupta" },
      { ico: "🏆", num: days * perDay, label: "micro-vitórias", sub: "pequenas, constantes, poderosas" },
      { ico: "⚡", num: days * perDay * 25, label: "pontos acumulados", sub: "energia virando progresso" },
      { ico: "🎁", num: days * perDay, label: "recompensas", sub: "cada vitória tem um prêmio" }
    ];
    var g = $("#vision-grid");
    g.innerHTML = "";
    cards.forEach(function (c) {
      var el = document.createElement("div");
      el.className = "v-card";
      el.innerHTML =
        '<div class="v-ico">' + c.ico + "</div>" +
        '<div class="v-num">' + c.num.toLocaleString("pt-BR") + "</div>" +
        '<span class="v-label">' + c.label + "</span>" +
        '<span class="v-sub">' + c.sub + "</span>";
      g.appendChild(el);
    });

    var story = $("#vision-story");
    story.innerHTML =
      "<h3>Hoje você deu <b>" + state.totalCompleted + "</b> micro-passo(s).</h3>" +
      "<p>Multiplique por 30 dias e serão <b>" + (state.totalCompleted * 30) + "</b> micro-vitórias. " +
      "Não é sobre o tamanho do passo — é sobre nunca mais parar no meio. O cérebro prefere o NeuroTask porque " +
      "cada 120 segundos entrega uma recompensa, e a recompensa pede o próximo.</p>" +
      (state.pro ? "" :
        "<p><b>Com o Pro</b>, cada dia vale 5 desafios em vez de 3 — e o cashback devolve parte do valor em dinheiro real.</p>");
  }

  function offerDeadline() {
    var t = null;
    try { t = parseInt(localStorage.getItem(OFFER_KEY), 10); } catch (e) {}
    if (!t) {
      t = Date.now() + OFFER_HOURS * 3600 * 1000;
      try { localStorage.setItem(OFFER_KEY, String(t)); } catch (e) {}
    }
    return t;
  }

  function remainingSeats() {
    var s = null;
    try { s = parseInt(localStorage.getItem(SEATS_KEY), 10); } catch (e) {}
    if (!s) s = SEATS_START;
    s = Math.max(SEATS_MIN, s - 1);
    try { localStorage.setItem(SEATS_KEY, String(s)); } catch (e) {}
    return s;
  }

  var cdInterval = null;
  function startCountdown() {
    if (cdInterval) clearInterval(cdInterval);
    var deadline = offerDeadline();
    var el = $("#cd-time"), wrap = $("#countdown");
    function tick() {
      var diff = Math.max(0, deadline - Date.now());
      var h = Math.floor(diff / 3600000);
      var m = Math.floor((diff % 3600000) / 60000);
      var s = Math.floor((diff % 60000) / 1000);
      el.textContent = (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
      wrap.classList.toggle("urgent", diff < 60 * 60 * 1000);
    }
    tick();
    cdInterval = setInterval(tick, 1000);
  }
  function stopCountdown() { if (cdInterval) { clearInterval(cdInterval); cdInterval = null; } }

  function renderUpgrade() {
    var btn = $("#btn-buy-pro");
    var label = btn.querySelector(".cta-label");
    if (state.pro) {
      $("#scarcity").innerHTML = "✅ Você já é Pro. Benefícios liberados.";
      label.textContent = "Seu Pro está ativo";
      btn.disabled = true;
    } else {
      $("#scarcity").innerHTML =
        "🔥 Restam <b>" + remainingSeats() + "</b> vagas com 50% de desconto na oferta de lançamento";
      label.textContent = "Quero o Pro · " + PRO_PRICE;
      btn.disabled = false;
    }

    var t = $("#testimonials");
    t.innerHTML = "";
    TESTIMONIALS.forEach(function (x) {
      var el = document.createElement("div");
      el.className = "tst";
      el.innerHTML =
        '<div class="stars">' + x.stars + "</div>" +
        "<p>&ldquo;" + x.text + "&rdquo;</p>" +
        '<div class="who">' + x.who + "</div>";
      t.appendChild(el);
    });

    var v = $("#value-stack");
    var html = VALUE_STACK.map(function (x) {
      return '<div class="vs-item"><span class="vs-ico">' + x.icon + "</span>" +
        '<span class="vs-name">' + x.name + "</span>" +
        '<span class="vs-val">' + x.val + "</span></div>";
    }).join("");
    var total = state.pro ? "incluído" : "R$ 117/mês";
    html += '<div class="vs-total"><div><b>' + total + "</b><br><span>valor total dos benefícios</span></div>" +
      '<div style="text-align:right"><b>19,90</b><br><span>você paga por mês</span></div></div>';
    v.innerHTML = html;

    startCountdown();
  }

  function goUpgrade() {
    soundClick();
    renderUpgrade();
    show("screen-upgrade");
  }

  /* ---------------- Indicação ---------------- */

  function genRefCode() {
    if (state.refCode) return state.refCode;
    var seed = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
    state.refCode = "NT-" + seed.toUpperCase();
    save();
    return state.refCode;
  }

  function handleReferral() {
    var params = new URLSearchParams(window.location.search);
    var ref = params.get("ref");
    if (ref && ref !== state.refCode && !state.welcomeClaimed) {
      state.referredBy = ref;
      state.welcomeClaimed = true;
      state.points += 50;
      state.pendingSpins += 1;
      save();
      renderTopbar();
      toast("🎁 Bônus de boas-vindas: +50 ⚡ e +1 giro (indicado por " + ref + ")");
      confetti(80);
    }
  }

  function renderReferral() {
    var code = genRefCode();
    var url = window.location.origin + window.location.pathname + "?ref=" + encodeURIComponent(code);
    $("#ref-url").value = url;
    var msg = state.referredBy
      ? "Você entrou pelo link de <b>" + state.referredBy + "</b>. Compartilhe o seu e ganhe Pro grátis."
      : "Compartilhe seu link e ganhe <b>3 dias Pro</b> por amigo que ativar.";
    $("#ref-count").innerHTML = msg;
  }

  /* ---------------- DESAFIO SIMPLES (One-Click) ---------------- */

  var CHALLENGES_DATA = [
    {
      id: "foco",
      icon: "🎯",
      title: "Preciso de Foco",
      desc: "Trave a distração e entre em modo profundo agora.",
      time: 120,
      steps: [
        { t: "Feche tudo que não é essencial", h: "Abas, notificações, celular no modo avião." },
        { t: "Defina UMA coisa para os próximos 25 min", h: "Escreva no papel. Só uma." },
        { t: "Comece pelo primeiro micro-passo de 2 min", h: "Não pense no projeto inteiro. Só no começo." }
      ]
    },
    {
      id: "economizar",
      icon: "💰",
      title: "Preciso Economizar",
      desc: "Descubra para onde o dinheiro está escorrendo.",
      time: 90,
      steps: [
        { t: "Abra o app do banco e olhe os últimos 10 lançamentos", h: "Sem julgar. Só observar." },
        { t: "Marque 3 gastos que você cortaria sem dor", h: "Assinaturas, delivery, impulso." },
        { t: "Agende 1 transferência automática para a poupança", h: "R$ 10 já vale. O hábito vale mais." }
      ]
    },
    {
      id: "ideia",
      icon: "💡",
      title: "Criar Ideia de Venda",
      desc: "Saia do bloqueio criativo com uma oferta concreta.",
      time: 180,
      steps: [
        { t: "Escreva a dor de 1 pessoa específica em 1 frase", h: "Quem sofre? O que dói?" },
        { t: "Liste 3 formas de resolver isso em até 7 dias", h: "Feias valem. quantidade antes de qualidade." },
        { t: "Escolha 1 e escreva a oferta em 1 frase", h: "\"Eu ajudo X a conseguir Y por Z\"." }
      ]
    },
    {
      id: "dia",
      icon: "🗂️",
      title: "Organizar Meu Dia",
      desc: "Transforme a sobrecarga em 3 prioridades claras.",
      time: 60,
      steps: [
        { t: "Despeje tudo que está na sua cabeça em uma lista", h: "Brain dump de 60 segundos, sem ordem." },
        { t: "Marque o que só VOCÊ pode fazer", h: "Delegue ou delete o resto." },
        { t: "Escolha a prioridade nº 1 e o horário dela", h: "Uma coisa. Um horário. Feito." }
      ]
    }
  ];

  var activeChallenge = null;

  function renderChallengesSimple() {
    var grid = document.getElementById("challenge-grid");
    grid.innerHTML = "";
    CHALLENGES_DATA.forEach(function (c) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "ch-card";
      btn.innerHTML =
        '<span class="ch-time">' + c.time + "s</span>" +
        '<span class="ch-ico">' + c.icon + "</span>" +
        "<h3>" + c.title + "</h3>" +
        "<p>" + c.desc + "</p>";
      btn.onclick = function () { startChallengeSimple(c); };
      grid.appendChild(btn);
    });
    var daily = document.getElementById("daily-note");
    if (daily) daily.textContent = state.pro
      ? "Plano Pro ativo — desafios ilimitados hoje."
      : "Você tem " + Math.max(0, FREE_DAILY_LIMIT - state.challengesToday) + " desafio(s) grátis restante(s) hoje. Pro libera ilimitado.";
  }

  function startChallengeSimple(c) {
    activeChallenge = c;
    document.getElementById("exec-ch-icon").textContent = c.icon;
    document.getElementById("exec-ch-title").textContent = c.title;
    document.getElementById("exec-ch-desc").textContent = c.desc;
    document.getElementById("exec-timer-num").textContent = c.time;
    document.getElementById("exec-progress-fill").style.width = "0%";
    document.getElementById("exec-btn-complete").disabled = true;

    var list = document.getElementById("exec-steps");
    list.innerHTML = "";
    c.steps.forEach(function (step, i) {
      var li = document.createElement("li");
      li.className = "step";
      li.innerHTML =
        '<span class="box">' + (i + 1) + "</span>" +
        "<p>" + step.t + '<span class="hint">' + step.h + "</span></p>";
      li.onclick = function () { toggleExecStep(i, li); };
      list.appendChild(li);
    });

    show("screen-challenge-exec");
    startChallengeTimerSimple(c.time);
  }

  var execTimer = null;
  var execRemaining = 0;
  var execDone = {};

  function startChallengeTimerSimple(time) {
    execRemaining = time;
    document.getElementById("exec-timer-num").textContent = execRemaining;
    execDone = {};
    updateExecProgress();
    if (execTimer) clearInterval(execTimer);
    execTimer = setInterval(function () {
      execRemaining -= 1;
      document.getElementById("exec-timer-num").textContent = execRemaining;
      updateExecProgress();
      if (execRemaining <= 0) {
        clearInterval(execTimer);
        execTimer = null;
        toast("⏱️ Tempo esgotado — conclua os passos para garantir a recompensa!");
      }
    }, 1000);
  }

  function updateExecProgress() {
    var ring = document.getElementById("exec-ring-fg");
    var fill = document.getElementById("exec-progress-fill");
    var total = activeChallenge.time;
    var frac = execRemaining / total;
    var C = 2 * Math.PI * 52;
    ring.style.strokeDashoffset = String(C * (1 - frac));
    fill.style.width = Math.round((1 - frac) * 100) + "%";
  }

  function toggleExecStep(i, li) {
    if (execDone[i]) {
      delete execDone[i];
      li.classList.remove("done");
    } else {
      execDone[i] = true;
      li.classList.add("done");
    }
    updateExecCompleteBtn();
  }

  function updateExecCompleteBtn() {
    var btn = document.getElementById("exec-btn-complete");
    var doneCount = Object.keys(execDone).length;
    btn.disabled = doneCount < activeChallenge.steps.length;
  }

  function completeChallengeFromScreen() {
    if (!activeChallenge) return;
    if (execTimer) clearInterval(execTimer);

    var gained = 10 + Math.min(state.streak * 2, 10) + Math.round((execRemaining / activeChallenge.time) * 10);
    state.points += gained;
    state.challengesToday += 1;
    state.totalCompleted += 1;
    state.pendingSpins += 1;
    save();

    var reward = pickReward();
    state.rewards.unshift(reward);
    state.history.unshift({ when: new Date().toISOString(), title: activeChallenge.title, points: gained });

    renderTopbar();
    save();

    document.getElementById("reward-title").textContent = "Micro-vitória desbloqueada!";
    document.getElementById("reward-sub").textContent = "Você acaba de dar ao seu cérebro a dose de dopamina que faltava.";
    document.getElementById("reward-tag").textContent = reward.tier === "premium" ? "RECOMPENSA PRO" : "RECOMPENSA";
    document.getElementById("reward-ico").textContent = reward.icon;
    document.getElementById("reward-name").textContent = reward.name;
    document.getElementById("reward-meta").textContent = reward.meta;
    document.getElementById("points-pop").textContent = "+" + gained + " ⚡";
    document.getElementById("chest-label").textContent = "Girar Roleta de Bônus";

    show("screen-reward");
    soundWin();
    vibrate([40, 40, 80]);
    confetti(140);
    activeChallenge = null;
  }

  /* ---------------- Wiring ---------------- */

  function init() {
    renderTopbar();
    renderChallenges();
    animateCounters();
    handleReferral();
    renderReferral();

    $("#cta-start").addEventListener("click", function () {
      soundClick();
      if (!canPlay()) { goUpgrade(); return; }
      renderChallenges();
      show("screen-challenges");
    });

    $("#cta-vision").addEventListener("click", function () {
      soundClick();
      renderVision();
      show("screen-vision");
    });

    $("#btn-vision-upgrade").addEventListener("click", goUpgrade);

    $("#btn-teaser").addEventListener("click", goUpgrade);

    $("#btn-buy-pro").addEventListener("click", function () {
      if (state.pro) return;
      state.pro = true;
      save();
      renderTopbar();
      toast("🎉 Bem-vindo ao Pro! Desafios ilimitados e cashback liberados.");
      soundWin();
      confetti(160);
      renderPanel();
      show("screen-panel");
    });

    $("#btn-skip-upgrade").addEventListener("click", function () {
      soundClick();
      stopCountdown();
      show("screen-hero");
    });

    $$("[data-back]").forEach(function (b) {
      b.addEventListener("click", function () {
        soundClick();
        var target = b.getAttribute("data-back");
        if (target === "screen-challenges") renderChallenges();
        if (target === "screen-panel") renderPanel();
        show(target);
      });
    });

    $("#btn-panel").addEventListener("click", function () {
      soundClick();
      renderPanel();
      renderReferral();
      show("screen-panel");
    });

    $("#btn-copy-ref").addEventListener("click", function () {
      var input = $("#ref-url");
      input.select();
      var done = function () { toast("Link copiado! Cole para um amigo."); };
      if (navigator.clipboard) {
        navigator.clipboard.writeText(input.value).then(done, function () { document.execCommand("copy"); done(); });
      } else {
        document.execCommand("copy");
        done();
      }
    });

    $("#btn-complete").addEventListener("click", completeChallenge);

    $("#btn-chest").addEventListener("click", function () {
      soundClick();
      show("screen-chest");
      // a tela já está visível; mede a largura real e monta a roleta
      buildWheel();
      $("#chest-result").classList.add("hidden");
      $$(".wheel-wrap").forEach(function (w) { w.classList.remove("hidden"); });
      $("#wheel").style.transform = "rotate(0deg)";
      $("#chest-note").textContent = "Giros disponíveis: " + state.pendingSpins + " · 1 por desafio concluído.";
    });

    $("#btn-spin").addEventListener("click", spinWheel);

    $("#btn-chest-close").addEventListener("click", function () {
      soundClick();
      show("screen-hero");
    });

    $("#btn-again").addEventListener("click", function () {
      soundClick();
      if (!canPlay()) { goUpgrade(); return; }
      renderChallenges();
      show("screen-challenges");
    });

    $("#btn-pro").addEventListener("click", function () {
      soundClick();
      goUpgrade();
    });

    $("#btn-ativar-pro").addEventListener("click", function (e) {
      e.preventDefault();
      soundClick();
      var email = document.getElementById("pix-email-admin").value.trim();
      var codigo = document.getElementById("pix-code-admin").value.trim();
      if (!email || !codigo) {
        toast("Preencha e-mail e código");
        return;
      }
      // Simples validação: se digitou, libera (você pode validar contra JSON real se quiser)
      state.pro = true;
      state.userEmail = email;
      save();
      renderTopbar();
      renderPanel();
      show("screen-panel");
      soundWin();
      confetti(160);
      toast("🎉 Bem-vindo ao Pro! Desafios ilimitados e cashback liberados.");
    });

    // recalcula as etiquetas da roleta se a janela mudar de tamanho
    window.addEventListener("resize", function () {
      if (document.getElementById("screen-chest").classList.contains("active")) buildWheel();
    });

    /* ---------------- Pix pagamento ---------------- */
    var PIX_KEY = "f62808ea-c9d5-4941-b752-20fe41e41e81";
    var WHATSAPP = "5563991291661";

    // Códigos de ativação válidos (adicionar manualmente quando cliente paga)
    var PAID_CODES = [
      { code: "NEURO-2026-10-29-ABCD", email: "cliente@exemplo.com", used: false }
    ];

    function renderPixQr() {
      var img = document.getElementById("pix-qr-img");
      if (!img) return;
      var url = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=" + encodeURIComponent(PIX_KEY);
      img.src = url;
    }

    function copyPixKey() {
      var key = PIX_KEY;
      if (navigator.clipboard) {
        navigator.clipboard.writeText(key).then(function () {
          toast("Chave Pix copiada: " + key);
        }, function () {
          document.execCommand("copy");
          toast("Chave Pix copiada: " + key);
        });
      } else {
        document.execCommand("copy");
        toast("Chave Pix copiada: " + key);
      }
    }

    function solicitCodigoPix() {
      var phone = document.getElementById("pix-phone").value.trim();
      var email = document.getElementById("pix-email").value.trim();

      if (!telefone) {
        toast("Digite seu telefone primeiro");
        document.getElementById("pix-phone").focus();
        return;
      }
      if (!email) {
        toast("Digite seu e-mail primeiro");
        document.getElementById("pix-email").focus();
        return;
      }

      // Gerar código de ativação
      var code = "NEURO-" + Date.now().toString(36).toUpperCase() + "-" + Math.random().toString(36).toUpperCase().substr(0, 4);
      PAID_CODES.push({ code: code, email: email, telefone: phone, used: false });

      var msg = encodeURIComponent(
        "Olá! Paguei o NeuroTask Pro via Pix.\nMeu telefone: " + phone + "\nMeu e-mail: " + email + "\nMeu código de ativação é: " + code + "\nPor favor, confirme e libere meu acesso Pro."
      );
      window.open("https://wa.me/" + WHATSAPP + "?text=" + msg, "_blank");

      // Mostrar campo para digitar código recebido
      document.getElementById("pix-code-input").style.display = "block";
      toast("Mensagem enviada pelo WhatsApp. Aguarde o código de ativação.");
    }

    function ativarProPorCodigo() {
      var email = document.getElementById("pix-email").value.trim();
      var codigo = document.getElementById("pix-code").value.trim();

      if (!email) {
        toast("Digite seu e-mail primeiro");
        return;
      }
      if (!codigo) {
        toast("Digite o código de ativação");
        return;
      }

      // Validar código
      var encontrado = PAID_CODES.find(function (c) {
        return c.code.toUpperCase() === codigo.toUpperCase() &&
               c.email.toLowerCase() === email.toLowerCase() &&
               c.used !== true;
      });

      if (!encontrado) {
        toast("Código ou e-mail inválido. Verifique e tente novamente.");
        return;
      }

      // Marcar como usado e ativar Pro
      encontrado.used = true;
      state.pro = true;
      state.userEmail = email;
      save();
      renderTopbar();
      renderPanel();
      show("screen-panel");
      soundWin();
      confetti(160);
      toast("🎉 Bem-vindo ao Pro! Desafios ilimitados e cashback liberados.");
    }

    $("#copy-pix").addEventListener("click", function (e) {
      e.preventDefault();
      soundClick();
      copyPixKey();
    });

    $("#btn-request-code").addEventListener("click", function (e) {
      e.preventDefault();
      soundClick();
      solicitCodigoPix();
    });

    $("#btn-ativar-pro").addEventListener("click", function (e) {
      e.preventDefault();
      soundClick();
      ativarProPorCodigo();
    });

    // renderiza QR Code quando a tela upgrade for exibida
    var _show = show;
    show = function (id) {
      _show.call(this, id);
      if (id === "screen-upgrade") {
        renderPixQr();
      }
    };
  }

  document.addEventListener("DOMContentLoaded", init);
})();
