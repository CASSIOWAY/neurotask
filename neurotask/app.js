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
        { id: "despertar-1", title: "Beber um copo de água", desc: "Hidrate-se ao acordar", time: 60 },
        { id: "despertar-2", title: "Respirar fundo 3 vezes", desc: "Respiração consciente", time: 60 },
        { id: "despertar-3", title: "Listar 3 prioridades", desc: "Escreva o que importa hoje", time: 60 }
      ]
    },
    {
      id: "impulso",
      name: "Impulso",
      icon: "⚡",
      sub: "Ganhe força nos primeiros passos",
      desc: "Desafios para criar momentum no dia.",
      unlockLevel: 2,
      reward: "Streak protection liberada",
      challenges: [
        { id: "impulso-1", title: "Fazer a cama", desc: "Comece o dia com ordem", time: 120 },
        { id: "impulso-2", title: "Tomar café da manhã", desc: "Alimente-se bem", time: 120 },
        { id: "impulso-3", title: "Primeira tarefa importante", desc: "Comece o projeto principal", time: 120 }
      ]
    },
    {
      id: "foco",
      name: "Foco",
      icon: "🎯",
      sub: "Mantenha a concentração",
      desc: "Desafios de atenção plena e produtividade.",
      unlockLevel: 3,
      reward: "Cashback básico",
      challenges: [
        { id: "foco-1", title: "Trabalhar 25 min sem distrações", desc: "Método Pomodoro", time: 180 },
        { id: "foco-2", title: "Ler 5 páginas de um livro", desc: "Cultive o hábito da leitura", time: 180 },
        { id: "foco-3", title: "Planejar o amanhã", desc: "Organize seu dia seguinte", time: 180 }
      ]
    },
    {
      id: "mestre",
      name: "Mestre",
      icon: "👑",
      sub: "Domine seus hábitos",
      desc: "Desafios avançados para quem já tem consistência.",
      unlockLevel: 4,
      reward: "Templates prontos",
      challenges: [
        { id: "mestre-1", title: "Revisar metas semanais", desc: "Avalie seu progresso", time: 180 },
        { id: "mestre-2", title: "Criar novo hábito", desc: "Comece algo novo hoje", time: 180 },
        { id: "mestre-3", title: "Ensinar algo para alguém", desc: "Compartilhe conhecimento", time: 180 }
      ]
    },
    {
      id: "legenda",
      name: "Lenda",
      icon: "🏆",
      sub: "Seja a melhor versão de você",
      desc: "Desafios elite para quem quer ir além.",
      unlockLevel: 5,
      reward: "Comunidade VIP vitalícia",
      challenges: [
        { id: "legenda-1", title: "Meditar 10 minutos", desc: "Pratique a atenção plena", time: 180 },
        { id: "legenda-2", title: "Fazer exercício físico", desc: "Movimente o corpo", time: 180 },
        { id: "legenda-3", title: "Agradecer a 3 pessoas", desc: "Pratique a gratidão", time: 180 }
      ]
    }
  ];

  /* ---- Roleta (Wheel) ---- */
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

  /* ---- Proteção Streak (Protection Slices) ---- */
  var WHEEL_PROTECTION_SLICES = [
    { label: "Proteção Streak", color: "#9c27b0", kind: "protect", emoji: "🛡️", needPro: false },
    { label: "+50 ⚡ (PRO)", color: "#e91e63", kind: "points", value: 50, emoji: "💎", needPro: true },
    { label: "Roleta Premium", color: "#ffd700", kind: "coupon", emoji: "👑", needPro: true }
  ];

  /* ---- Badges ---- */
  var BADGES = [
    { id: "primeiro", icon: "🌱", name: "Primeira Vitória", need: 1 },
    { id: "tres", icon: "🔥", name: "Trinca", need: 3 },
    { id: "dez", icon: "⚡", name: "Dopamina Alta", need: 10 },
    { id: "streak3", icon: "📅", name: "3 Dias Seguidos", need: "streak3" },
    { id: "streak7", icon: "👑", name: "Imparável (7 dias)", need: "streak7" },
    { id: "challenge50", icon: "🏅", name: "Maratonista", need: 50 },
    { id: "wheel100", icon: "📜", name: "Colecionador de Premiações", need: 100 },
    { id: "pro30days", icon: "👑", name: "VIP 30 Dias", need: "pro30days" }
  ];

  /* ---- Pagamento Pix ---- */
  var PIX_KEY = "f62808ea-c9d5-4941-b752-20fe41e41e81";

  /* ---- Códigos de ativação ---- */
  var PAID_CODES = [
    { code: "NEURO-2026-10-29-ABCD", email: "cliente@exemplo.com", used: false }
  ];

  /* ---- Configurações ---- */
  var OFFER_HOURS = 24;
  var SEATS_START = 42;
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
      stageUnlockedTeaser: null,
      streakProtected: false,
      streakProtectedUntil: null,
      userEmail: null
    };
  }

  /* ---------------- Helpers DOM ---------------- */

  function $(sel) { return document.querySelector(sel); }
  function $$(sel) { return document.querySelectorAll(sel); }

  /* ---------------- Persistência ---------------- */

  function save() {
    try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
  }
  function load() {
    try { return JSON.parse(localStorage.getItem(KEY) || "null"); } catch (e) { return null; }
  }

  /* ---------------- Estado Global ---------------- */

  var state = load() || defaultState();
  var active = null;

  /* ---------------- Renderização Topbar ---------------- */

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

  /* ---------------- Streak ---------------- */

  function registerActivityDay() {
    var today = todayStr();
    if (state.lastActiveDay === today) return;
    if (state.lastActiveDay === yesterdayStr()) {
      state.streak += 1;
    } else {
      state.streak = 1;
    }
    state.lastActiveDay = today;
  }

  /* ---------------- Desafios ---------------- */

  function getChallengeById(id) {
    for (var s = 0; s < STAGES.length; s++) {
      for (var c = 0; c < STAGES[s].challenges.length; c++) {
        if (STAGES[s].challenges[c].id === id) return STAGES[s].challenges[c];
      }
    }
    return null;
  }

  function completeChallengeId(id) {
    if (state.completedChallenges.indexOf(id) !== -1) return false;
    state.completedChallenges.push(id);
    return true;
  }

  function stageIsComplete(stage) {
    return stage.challenges.every(function (c) {
      return state.completedChallenges.indexOf(c.id) !== -1;
    });
  }

  function unlockStage(id) {
    if (state.unlockedStages.indexOf(id) === -1) {
      state.unlockedStages.push(id);
    }
  }

  function isStageUnlocked(id) {
    return state.unlockedStages.indexOf(id) !== -1;
  }

  function renderChallenges() {
    var grid = $("#challenge-grid");
    grid.innerHTML = "";
    var today = todayStr();
    if (state.dayStamp !== today) {
      state.challengesToday = 0;
      state.dayStamp = today;
      save();
    }

    STAGES.forEach(function (stage) {
      if (!isStageUnlocked(stage.id)) return;
      stage.challenges.forEach(function (ch) {
        var done = state.completedChallenges.indexOf(ch.id) !== -1;
        var card = document.createElement("div");
        card.className = "challenge-card" + (done ? " done" : "");
        card.innerHTML =
          '<div class="challenge-icon">' + ch.icon + '</div>' +
          '<div class="challenge-info">' +
          '<div class="challenge-title">' + ch.title + '</div>' +
          '<div class="challenge-desc">' + ch.desc + '</div>' +
          '<div class="challenge-time">' + ch.time + 's</div>' +
          '</div>';
        card.addEventListener("click", function () {
          if (done) return;
          if (!canPlay()) { goUpgrade(); return; }
          startChallenge(ch);
        });
        grid.appendChild(card);
      });
    });
  }

  function canPlay() {
    if (state.pro) return true;
    return state.challengesToday < FREE_DAILY_LIMIT;
  }

  function startChallenge(ch) {
    active = {
      ch: ch,
      id: ch.id,
      title: ch.title,
      desc: ch.desc,
      time: ch.time,
      remaining: ch.time,
      startTime: Date.now(),
      done: {},
      interval: null
    };

    $("#exec-ch-title").textContent = ch.title;
    $("#exec-ch-desc").textContent = ch.desc;
    $("#exec-ch-icon").textContent = "";
    $("#exec-timer-num").textContent = ch.time;
    $("#exec-progress-fill").style.width = "0%";
    $("#btn-complete").disabled = true;
    setRing(0);

    var list = $("#exec-steps");
    list.innerHTML = "";
    ch.steps || (ch.steps = []);
    ch.steps.forEach(function (step, i) {
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
    var total = active.ch.steps.length;
    var doneCount = Object.keys(active.done).length;
    $("#exec-progress-fill").style.width = (doneCount / total * 100) + "%";
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
      $("#exec-timer-num").textContent = active.remaining;
      setRing(active.remaining / active.ch.time);
    }, 1000);
  }

  function completeChallenge() {
    if (!active) return;
    stopTimer();

    var c = active.ch;
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

    var justCompleted = completeChallengeId(c.id);
    var stage = STAGES.find(function (s) {
      return s.challenges.some(function (x) { return x.id === c.id; });
    });
    if (justCompleted && stage && stageIsComplete(stage)) {
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
      else if (b.need === "pro30days") ok = state.pro && state.totalCompleted >= 30;
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

    var btn = $("#btn-spin");
    btn.disabled = true;
    btn.classList.add("spinning");
    btn.textContent = "GIRANDO…";

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
      btn.disabled = false;
      btn.classList.remove("spinning");
      btn.textContent = "GIRAR";
      landOnSlice(WHEEL_SLICES[idx]);
    }, 4300);
  }

  function landOnSlice(slice) {
    var title = "", desc = "", tag = "";
    if (slice.kind === "points") {
      if (slice.needPro && !state.pro) {
        title = "🔒 Prêmio PRO!";
        desc = "Este prêmio é exclusivo para assinantes Pro. Ative o Pro para ganhar!";
      } else {
        state.points += slice.value;
        title = "+" + slice.value + " pontos!";
        desc = "Energia extra somada ao seu saldo. Continue assim.";
      }
      tag = "PONTOS";
    } else if (slice.kind === "protect") {
      state.streakProtected = true;
      state.streakProtectedUntil = todayStr();
      title = "🛡️ Streak Protegida!";
      desc = "Seu streak não será resetado mesmo se ficar um dia sem usar o app. Durando até amanhã.";
      tag = "PROTEÇÃO";
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

    $$(".wheel-wrap").forEach(function (w) { w.classList.add("spin-out"); });
    setTimeout(function () {
      $$(".wheel-wrap").forEach(function (w) { w.classList.add("hidden"); w.classList.remove("spin-out"); });
      var result = $("#chest-result");
      result.classList.remove("hidden");
      result.classList.remove("revealed");
      void result.offsetWidth;
      result.classList.add("revealed");

      var chest = $("#chest");
      chest.classList.remove("open");
      void chest.offsetWidth;
      chest.classList.add("open");

      soundWin();
      vibrate([50, 40, 90]);
      confetti(90);

      if (!state.pro) {
        setTimeout(function () {
          show("screen-upgrade");
          renderPixQr();
          toast("💡 Quer continuar girando a roleta? Ative o Pro!");
        }, 1500);
      }
    }, 500);
  }

  /* ---------------- Pix pagamento ---------------- */

  function renderPixQr() {
    var img = document.getElementById("pix-qr-img");
    if (!img) return;
    img.innerHTML = "";
    new QRCode(img, {
      text: PIX_KEY,
      width: 200,
      height: 200,
      colorDark: "#000000",
      colorLight: "#ffffff",
      correctLevel: QRCode.CorrectLevel.H
    });
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

  function contactPix() {
    var msg = encodeURIComponent(
      "Olá! Paguei a assinatura NeuroTask Pro via Pix (chave: " + PIX_KEY + "). Por favor, libere meu acesso Pro."
    );
    var subject = encodeURIComponent("NeuroTask Pro - Comprovante de Pagamento Pix");
    window.open("mailto:cassioway@gmail.com?subject=" + subject + "&body=" + msg, "_blank");
  }

  $("#copy-pix").addEventListener("click", function (e) {
    e.preventDefault();
    soundClick();
    copyPixKey();
  });

  $("#btn-contact-pix").addEventListener("click", function (e) {
    e.preventDefault();
    soundClick();
    contactPix();
  });

  var _show = show;
  show = function (id) {
    _show.call(this, id);
    if (id === "screen-upgrade") {
      renderPixQr();
    }
  };

  /* ---------------- Onboarding / Triagem Lúdica ---------------- */

  var onboardingState = {
    age: null,
    tests: { a: null, b: null, c: null },
    currentStep: 0
  };

  function showOnboardingScreen(screenId) {
    $$(".onboarding-content").forEach(function (el) { el.classList.remove("active"); });
    var el = document.getElementById(screenId);
    if (el) el.classList.add("active");
  }

  function initOnboarding() {
    var hasProfile = localStorage.getItem("neurotask.profile");
    if (!hasProfile) {
      show("screen-onboarding");
      showOnboardingScreen("onboarding-age-selector");

      $$(".age-card").forEach(function (card) {
        card.addEventListener("click", function () {
          $$(".age-card").forEach(function (c) { c.classList.remove("selected"); });
          card.classList.add("selected");
          onboardingState.age = card.getAttribute("data-age");
          document.getElementById("btn-age-next").disabled = false;
        });
      });

      document.getElementById("btn-age-next").addEventListener("click", function () {
        if (!onboardingState.age) return;
        showOnboardingScreen("onboarding-test-a");
        startTestA();
      });

      initTestA();
      initTestB();
      initTestC();
    }
  }

  /* ---------- Teste A: Atenção Seletiva (Go/No-Go) ---------- */
  var testA = {
    score: 0,
    errors: 0,
    timeLeft: 30,
    timer: null,
    isRunning: false
  };

  function initTestA() {
    var container = document.getElementById("game-a-container");
    var cells = [];
    for (var i = 0; i < 16; i++) {
      var cell = document.createElement("div");
      cell.className = "game-cell";
      cell.dataset.index = i;
      cell.addEventListener("click", function () { handleCellA(this); });
      container.appendChild(cell);
      cells.push(cell);
    }
    testA.cells = cells;
  }

  function startTestA() {
    testA.score = 0;
    testA.errors = 0;
    testA.timeLeft = 30;
    testA.isRunning = true;
    document.getElementById("test-a-score").textContent = "0";
    document.getElementById("test-a-errors").textContent = "0";
    document.getElementById("test-a-time").textContent = "30";
    document.getElementById("btn-test-a-next").disabled = true;

    testA.timer = setInterval(function () {
      testA.timeLeft--;
      document.getElementById("test-a-time").textContent = testA.timeLeft;
      if (testA.timeLeft <= 0) {
        clearInterval(testA.timer);
        testA.isRunning = false;
        endTestA();
      }
    }, 1000);

    spawnTargetA();
  }

  function spawnTargetA() {
    if (!testA.isRunning) return;
    testA.cells.forEach(function (c) {
      c.className = "game-cell";
      c.onclick = null;
    });

    var idx = Math.floor(Math.random() * testA.cells.length);
    var cell = testA.cells[idx];
    var type = Math.random();

    if (type < 0.4) {
      cell.classList.add("target");
      cell.textContent = "🟢";
      cell.onclick = function () {
        testA.score++;
        document.getElementById("test-a-score").textContent = testA.score;
        cell.classList.add("clicked");
        setTimeout(spawnTargetA, 400);
      };
    } else if (type < 0.7) {
      cell.classList.add("distractor");
      cell.textContent = "🔴";
      cell.onclick = function () {
        testA.errors++;
        document.getElementById("test-a-errors").textContent = testA.errors;
        cell.classList.add("wrong");
        setTimeout(function () { cell.classList.remove("wrong"); cell.className = "game-cell"; cell.onclick = null; }, 400);
        setTimeout(spawnTargetA, 400);
      };
    } else {
      cell.classList.add("distractor-shape");
      cell.textContent = "⬛";
      cell.onclick = function () {
        testA.errors++;
        document.getElementById("test-a-errors").textContent = testA.errors;
        cell.classList.add("wrong");
        setTimeout(function () { cell.classList.remove("wrong"); cell.className = "game-cell"; cell.onclick = null; }, 400);
        setTimeout(spawnTargetA, 400);
      };
    }
  }

  function handleCellA(cell) {
    if (cell.classList.contains("target")) {
      testA.score++;
      document.getElementById("test-a-score").textContent = testA.score;
    } else {
      testA.errors++;
      document.getElementById("test-a-errors").textContent = testA.errors;
    }
  }

  function endTestA() {
    testA.isRunning = false;
    document.getElementById("btn-test-a-next").disabled = false;
    onboardingState.tests.a = {
      score: testA.score,
      errors: testA.errors,
      timeLeft: testA.timeLeft
    };
  }

  /* ---------- Teste B: Memória de Trabalho ---------- */
  var testB = {
    level: 1,
    sequence: [],
    currentIndex: 0,
    userSequence: [],
    isShowing: false,
    attempts: 1
  };

  function initTestB() {
    var grid = document.getElementById("grid-b");
    for (var i = 0; i < 9; i++) {
      var cell = document.createElement("div");
      cell.className = "grid-cell";
      cell.dataset.index = i;
      cell.addEventListener("click", function () { handleCellB(parseInt(this.dataset.index)); });
      grid.appendChild(cell);
    }
    testB.cells = grid.querySelectorAll(".grid-cell");
  }

  function startTestB() {
    testB.level = 1;
    testB.attempts = 1;
    testB.userSequence = [];
    document.getElementById("test-b-level").textContent = "1";
    document.getElementById("test-b-attempts").textContent = "1";
    document.getElementById("grid-b-controls").style.display = "none";
    document.getElementById("btn-test-b-next").disabled = true;
    runTestBSequence();
  }

  function runTestBSequence() {
    testB.sequence = [];
    for (var i = 0; i < Math.min(3 + testB.level, 9); i++) {
      testB.sequence.push(Math.floor(Math.random() * 9));
    }
    testB.currentIndex = 0;
    testB.isShowing = true;
    testB.cells.forEach(function (c) { c.classList.remove("active"); c.style.cursor = "default"; });

    var i = 0;
    var interval = setInterval(function () {
      if (i >= testB.sequence.length) {
        clearInterval(interval);
        testB.isShowing = false;
        testB.cells.forEach(function (c) { c.style.cursor = "pointer"; });
        document.getElementById("grid-b-controls").style.display = "block";
        testB.userSequence = [];
        return;
      }
      var cellIdx = testB.sequence[i];
      testB.cells[cellIdx].classList.add("active");
      setTimeout(function () {
        testB.cells[cellIdx].classList.remove("active");
      }, 600);
      i++;
    }, 900);
  }

  function handleCellB(index) {
    if (testB.isShowing) return;
    testB.userSequence.push(index);
    testB.cells[index].classList.add("selected");
    setTimeout(function () { testB.cells[index].classList.remove("selected"); }, 300);

    if (testB.userSequence.length === testB.sequence.length) {
      var correct = testB.userSequence.every(function (v, idx) { return v === testB.sequence[idx]; });
      if (correct) {
        testB.level++;
        document.getElementById("test-b-level").textContent = testB.level;
        setTimeout(runTestBSequence, 800);
      } else {
        testB.attempts++;
        document.getElementById("test-b-attempts").textContent = testB.attempts;
        if (testB.attempts >= 3) {
          endTestB();
        } else {
          setTimeout(runTestBSequence, 800);
        }
      }
    }
  }

  function endTestB() {
    testB.isShowing = false;
    document.getElementById("btn-test-b-next").disabled = false;
    onboardingState.tests.b = {
      level: testB.level,
      attempts: testB.attempts
    };
  }

  /* ---------- Teste C: Labirinto ---------- */
  var testC = {
    timeLeft: 30,
    attempts: 1,
    timer: null,
    isRunning: false,
    playerPos: { x: 0, y: 0 },
    goalPos: { x: 2, y: 2 },
    walls: [],
    timerId: null
  };

  function initTestC() {
    var container = document.getElementById("maze-c");
    container.innerHTML = "";
    testC.walls = [];

    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 3; x++) {
        var cell = document.createElement("div");
        cell.className = "maze-cell";
        cell.style.width = "32px";
        cell.style.height = "32px";
        cell.style.border = "2px solid var(--line)";
        cell.style.background = "var(--bg)";
        cell.style.display = "grid";
        cell.style.placeItems = "center";
        cell.style.position = "relative";
        cell.dataset.x = x;
        cell.dataset.y = y;
        container.appendChild(cell);
      }
    }

    testC.playerPos = { x: 0, y: 0 };
    testC.goalPos = { x: 2, y: 2 };

    drawMazeC();
  }

  function drawMazeC() {
    var container = document.getElementById("maze-c");
    var cells = container.querySelectorAll(".maze-cell");

    cells.forEach(function (cell) {
      var x = parseInt(cell.dataset.x);
      var y = parseInt(cell.dataset.y);
      cell.innerHTML = "";
      cell.className = "maze-cell";
      cell.style.background = "var(--bg)";

      if (x === testC.goalPos.x && y === testC.goalPos.y) {
        cell.innerHTML = "🏁";
        cell.style.background = "var(--teal)";
        cell.style.color = "#fff";
      }

      if (x === testC.playerPos.x && y === testC.playerPos.y) {
        cell.innerHTML = "😎";
        cell.style.background = "var(--gold)";
      }

      if (testC.walls.some(function (w) { return w.x === x && w.y === y; })) {
        cell.style.background = "linear-gradient(135deg,#7c5cff,#00e0c6)";
      }
    });
  }

  function startTestC() {
    testC.timeLeft = 30;
    testC.attempts = 1;
    testC.isRunning = true;
    document.getElementById("test-c-time").textContent = "30";
    document.getElementById("test-c-attempts").textContent = "1";
    document.getElementById("btn-test-c-next").disabled = true;

    resetMazeC();

    testC.timerId = setInterval(function () {
      testC.timeLeft--;
      document.getElementById("test-c-time").textContent = testC.timeLeft;
      if (testC.timeLeft <= 0) {
        clearInterval(testC.timerId);
        testC.isRunning = false;
        endTestC();
      }
    }, 1000);

    changeMazeWallsC();
    setInterval(changeMazeWallsC, 5000);
  }

  function resetMazeC() {
    testC.playerPos = { x: 0, y: 0 };
    drawMazeC();

    document.addEventListener("keydown", handleMazeKeys);
  }

  function handleMazeKeys(e) {
    if (!testC.isRunning) return;
    var x = testC.playerPos.x;
    var y = testC.playerPos.y;
    var nx = x, ny = y;

    if (e.key === "ArrowLeft") nx--;
    if (e.key === "ArrowRight") nx++;
    if (e.key === "ArrowUp") ny--;
    if (e.key === "ArrowDown") ny++;

    if (nx >= 0 && nx < 3 && ny >= 0 && ny < 3) {
      var isWall = testC.walls.some(function (w) { return w.x === nx && w.y === ny; });
      if (!isWall) {
        testC.playerPos = { x: nx, y: ny };
        drawMazeC();

        if (nx === testC.goalPos.x && ny === testC.goalPos.y) {
          clearInterval(testC.timerId);
          testC.isRunning = false;
          document.getElementById("btn-test-c-next").disabled = false;
          onboardingState.tests.c = {
            timeLeft: testC.timeLeft,
            attempts: testC.attempts
          };
          document.removeEventListener("keydown", handleMazeKeys);
        }
      }
    }
  }

  function changeMazeWallsC() {
    if (!testC.isRunning) return;
    testC.walls = [];
    var count = Math.floor(Math.random() * 3) + 1;
    for (var i = 0; i < count; i++) {
      var wx = Math.floor(Math.random() * 3);
      var wy = Math.floor(Math.random() * 3);
      if ((wx !== testC.playerPos.x || wy !== testC.playerPos.y) &&
          (wx !== testC.goalPos.x || wy !== testC.goalPos.y)) {
        testC.walls.push({ x: wx, y: wy });
      }
    }
    drawMazeC();
  }

  function endTestC() {
    testC.isRunning = false;
    document.getElementById("btn-test-c-next").disabled = false;
    onboardingState.tests.c = {
      timeLeft: testC.timeLeft,
      attempts: testC.attempts
    };
    document.removeEventListener("keydown", handleMazeKeys);
  }

  /* ---------- Algoritmo de recomendação ---------- */

  function computeProfile() {
    var tA = onboardingState.tests.a;
    var tB = onboardingState.tests.b;
    var tC = onboardingState.tests.c;

    var attentionScore = Math.min(100, Math.round((tA.score / (tA.score + tA.errors + 1)) * 100));
    var memoryScore = Math.min(100, Math.round((tB.level / 6) * 100));
    var planningScore = Math.min(100, Math.round((tC.timeLeft / 30) * 100));

    var avgScore = Math.round((attentionScore + memoryScore + planningScore) / 3);

    var profile = {
      age: onboardingState.age,
      attention: attentionScore,
      memory: memoryScore,
      planning: planningScore,
      overall: avgScore,
      missions: []
    };

    if (avgScore >= 70) {
      profile.missions.push({
        title: "Desafio Diário Avançado",
        icon: "🚀",
        text: "Complete 5 micro-desafios por dia"
      });
    } else if (avgScore >= 40) {
      profile.missions.push({
        title: "Desafio Diário Padrão",
        icon: "🎯",
        text: "Complete 3 micro-desafios por dia"
      });
    } else {
      profile.missions.push({
        title: "Desafio Diário Suave",
        icon: "🌱",
        text: "Complete 1 micro-desafio por dia"
      });
    }

    if (attentionScore < 50) {
      profile.missions.push({
        title: "Treinamento de Foco",
        icon: "🎯",
        text: "Pratique atenção plena 5 min por dia"
      });
    }

    if (memoryScore < 50) {
      profile.missions.push({
        title: "Treinamento de Memória",
        icon: "🧠",
        text: "Jogue o jogo da memória 2x por semana"
      });
    }

    if (planningScore < 50) {
      profile.missions.push({
        title: "Treinamento de Planejamento",
        icon: "📅",
        text: "Planeje seu dia na noite anterior"
      });
    }

    return profile;
  }

  function renderProfile(profile) {
    var icons = { child: "👦", teen: "🦾", adult: "🧠" };
    var names = { child: "Explorador", teen: "Ciber-herói", adult: "Mestre da Produtividade" };
    var descs = {
      child: "Você é curioso e aprende rápido com brincadeiras.",
      teen: "Seu cérebro é rápido e competitivo, perfeito para desafios.",
      adult: "Você é focado e produtivo, valoriza eficiência."
    };

    document.getElementById("profile-icon").textContent = icons[onboardingState.age] || "🧠";
    document.getElementById("profile-name").textContent = names[onboardingState.age] || "Usuário";
    document.getElementById("profile-desc").textContent = descs[onboardingState.age] || "";
    document.getElementById("stat-attention").textContent = profile.attention + "%";
    document.getElementById("stat-memory").textContent = profile.memory + "%";
    document.getElementById("stat-planning").textContent = profile.planning + "%";
    document.getElementById("mission-text").textContent = profile.missions[0].text;
    document.getElementById("mission-emoji").textContent = profile.missions[0].icon;
  }

  /* ---------- Finais ---------- */

  document.getElementById("btn-test-a-next").addEventListener("click", function () {
    showOnboardingScreen("onboarding-test-b");
    startTestB();
  });

  document.getElementById("btn-test-b-next").addEventListener("click", function () {
    showOnboardingScreen("onboarding-test-c");
    startTestC();
  });

  document.getElementById("btn-test-c-next").addEventListener("click", function () {
    var profile = computeProfile();
    localStorage.setItem("neurotask.profile", JSON.stringify(profile));
    renderProfile(profile);
    showOnboardingScreen("onboarding-result");
  });

  document.getElementById("btn-profile-done").addEventListener("click", function () {
    show("screen-hero");
  });

  document.getElementById("btn-profile-edit").addEventListener("click", function () {
    showOnboardingScreen("onboarding-age-selector");
  });

  /* ---------------- Inicialização atualizada ---------------- */

  var originalInit = init;
  init = function () {
    originalInit();
    initOnboarding();
  };

  document.addEventListener("DOMContentLoaded", init);
})();