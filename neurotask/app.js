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

  function todayStr() {
    var d = new Date();
    return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
  }

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
    var timeBonus = Math.max(0, Math.round((c.time - elapsed) / 10));
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
    void stage.offsetWidth;
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

  /* ---------------- Inicialização ---------------- */

  function init() {
    renderTopbar();
    renderChallenges();
    animateCounters();
    buildWheel();
    show("screen-hero");
  }

  document.addEventListener("DOMContentLoaded", init);
})();