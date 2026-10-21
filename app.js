/* ============================================================
   NeuroTask / HabitFlow — motor do produto
   Persistência: localStorage (sem backend, sem cadastro)
   ============================================================ */
(function () {
  "use strict";

  /* ---------------- Dados ---------------- */

  var CHALLENGES = [
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
      welcomeClaimed: false
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

    CHALLENGES.forEach(function (c) {
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "ch-card" + (limitReached ? " locked" : "");
      btn.innerHTML =
        '<span class="ch-time">' + c.time + "s</span>" +
        '<span class="ch-ico">' + c.icon + "</span>" +
        "<h3>" + c.title + "</h3>" +
        "<p>" + c.desc + "</p>";
      btn.addEventListener("click", function () {
        if (limitReached) return;
        soundClick();
        startChallenge(c);
      });
      grid.appendChild(btn);
    });

    var remaining = state.pro ? "ilimitados" : Math.max(0, FREE_DAILY_LIMIT - state.challengesToday);
    $("#daily-note").textContent = state.pro
      ? "Plano Pro ativo — desafios ilimitados hoje."
      : "Você tem " + remaining + " micro-desafio(s) grátis restante(s) hoje. Pro libera ilimitado.";
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

    // recalcula as etiquetas da roleta se a janela mudar de tamanho
    window.addEventListener("resize", function () {
      if (document.getElementById("screen-chest").classList.contains("active")) buildWheel();
    });
  }

  document.addEventListener("DOMContentLoaded", init);
})();
