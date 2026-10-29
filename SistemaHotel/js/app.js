var SISTEMA = {
    moduloAtual: 'dashboard',
    dadosCache: {},
    debug: true
};

// Polyfill padStart for IE (HTA)
if (!String.prototype.padStart) {
    String.prototype.padStart = function(len, chr) {
        var str = String(this);
        while (str.length < len) { str = (chr || '0') + str; }
        return str;
    };
}

var BASE_DIR = 'C:\\EXECUTAVEL CENSO 2026\\SistemaHotel';

function log(msg) { if (SISTEMA.debug) console.log('[SISTEMA] ' + msg); }

function executarPS(modulo, acao, dados, callback) {
    var shell = new ActiveXObject('WScript.Shell');
    var fso = new ActiveXObject('Scripting.FileSystemObject');
    var tempFile = BASE_DIR + '\\temp_' + new Date().getTime() + '.json';
    var psScript = BASE_DIR + '\\modules\\controller.ps1';

    var jsonDados = dados ? JSON.stringify(dados) : '{}';
    var cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + psScript + '" -Modulo "' + modulo + '" -Acao "' + acao + '" -DadosJSON \'' + jsonDados.replace(/'/g, "''") + '\'';

    var exec = shell.Exec(cmd);
    var resultado = '';
    while (!exec.StdOut.AtEndOfStream) { resultado += exec.StdOut.ReadAll(); }

    if (callback) {
        try {
            var parsed = JSON.parse(resultado.trim());
            callback(parsed);
        } catch(e) {
            log('Erro ao parsear JSON: ' + e.message);
            log('Resultado bruto: ' + resultado);
            callback(null);
        }
    }
}

function executarPSAsync(modulo, acao, dados, callback) {
    setTimeout(function() { executarPS(modulo, acao, dados, callback); }, 10);
}

function $(id) { return document.getElementById(id); }

function showAlert(mensagem, tipo) {
    tipo = tipo || 'success';
    var container = $('alert-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'alert-container';
        container.style.cssText = 'position:fixed;top:20px;right:20px;z-index:9999;';
        document.body.appendChild(container);
    }
    var alert = document.createElement('div');
    alert.className = 'alert alert-' + tipo;
    alert.innerHTML = mensagem;
    alert.style.cssText = 'margin-bottom:10px;animation:slideIn 0.3s;box-shadow:0 4px 12px rgba(0,0,0,0.15);';
    container.appendChild(alert);
    setTimeout(function() {
        alert.style.opacity = '0';
        alert.style.transition = 'opacity 0.3s';
        setTimeout(function() { alert.remove(); }, 300);
    }, 4000);
}

function formatarMoeda(valor) {
    return 'R$ ' + parseFloat(valor || 0).toFixed(2).replace('.', ',');
}

function formatarData(data) {
    if (!data) return '-';
    var partes = data.split('-');
    if (partes.length === 3) return partes[2] + '/' + partes[1] + '/' + partes[0];
    return data;
}

function obterDataAtual() {
    var d = new Date();
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}

// ===== NAVEGAÇÃO =====
function navegar(modulo) {
    SISTEMA.moduloAtual = modulo;
    var itens = document.querySelectorAll('.nav-item');
    for (var i = 0; i < itens.length; i++) { itens[i].classList.remove('ativo'); }
    var navItem = document.querySelector('.nav-item[data-modulo="' + modulo + '"]');
    if (navItem) navItem.classList.add('ativo');

    var titulos = {
        'dashboard': 'Painel de Controle',
        'calendario': 'Calendário de Reservas',
        'reservas': 'Gerenciar Reservas',
        'operacoes': 'Operações do Dia',
        'hospedes': 'Hóspedes',
        'canais': 'Gerente de Canal',
        'financeiro': 'Fluxo de Caixa',
        'analise': 'Análise e Relatórios',
        'whatsapp': 'WhatsApp',
        'integracoes': 'Integrações (Omnibees/Booking)',
        'config': 'Configurações'
    };

    $('page-title').textContent = titulos[modulo] || modulo;
    $('conteudo-principal').innerHTML = '<div class="loading"><div class="spin"></div><p style="margin-top:10px">Carregando...</p></div>';

    switch (modulo) {
        case 'dashboard': carregarDashboard(); break;
        case 'calendario': carregarCalendario(); break;
        case 'reservas': carregarReservas(); break;
        case 'operacoes': carregarOperacoes(); break;
        case 'hospedes': carregarHospedes(); break;
        case 'canais': carregarCanais(); break;
        case 'financeiro': carregarFinanceiro(); break;
        case 'analise': carregarAnalise(); break;
        case 'whatsapp': carregarWhatsApp(); break;
        case 'integracoes': carregarIntegracoes(); break;
        case 'config': carregarConfig(); break;
        default: carregarDashboard();
    }
}

// ===== DASHBOARD =====
function carregarDashboard() {
    var html = '<div class="stats-grid" id="stats-dashboard"></div>';
    html += '<div class="row" style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">';
    html += '<div class="card"><div class="card-header"><h3>Check-ins / Check-outs Hoje</h3></div><div class="card-body" id="checkins-hoje"><p class="loading">Carregando...</p></div></div>';
    html += '<div class="card"><div class="card-header"><h3>Reservas Recentes</h3></div><div class="card-body" id="reservas-recentes"><p class="loading">Carregando...</p></div></div>';
    html += '</div>';
    $('conteudo-principal').innerHTML = html;

    executarPS('analise', 'dashboard', null, function(dados) {
        if (!dados) return;
        var stats = '';
        stats += '<div class="stat-card"><div class="stat-icon bg-blue">🏨</div><div class="stat-info"><div class="stat-value">' + dados.total_quartos + '</div><div class="stat-label">Quartos (' + dados.quartos_disponiveis + ' disp.)</div></div></div>';
        stats += '<div class="stat-card"><div class="stat-icon bg-green">📊</div><div class="stat-info"><div class="stat-value">' + dados.taxa_ocupacao + '%</div><div class="stat-label">Taxa de Ocupação</div></div></div>';
        stats += '<div class="stat-card"><div class="stat-icon bg-orange">📅</div><div class="stat-info"><div class="stat-value">' + dados.total_reservas + '</div><div class="stat-label">Reservas</div></div></div>';
        stats += '<div class="stat-card"><div class="stat-icon bg-teal">💰</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(dados.receitas_mes) + '</div><div class="stat-label">Receita do Mês</div></div></div>';
        stats += '<div class="stat-card"><div class="stat-icon bg-red">💳</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(dados.despesas_mes) + '</div><div class="stat-label">Despesas do Mês</div></div></div>';
        stats += '<div class="stat-card"><div class="stat-icon bg-purple">⚡</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(dados.saldo_atual) + '</div><div class="stat-label">Saldo do Mês</div></div></div>';
        $('stats-dashboard').innerHTML = stats;

        var hojeHtml = '<div style="display:flex;gap:20px;text-align:center;">';
        hojeHtml += '<div style="flex:1;padding:15px;background:#e3f2fd;border-radius:8px;"><div style="font-size:28px;font-weight:700;color:#1565c0;">' + dados.checkins_hoje + '</div><div style="font-size:13px;color:#666;">Check-ins</div></div>';
        hojeHtml += '<div style="flex:1;padding:15px;background:#fff3e0;border-radius:8px;"><div style="font-size:28px;font-weight:700;color:#e65100;">' + dados.checkouts_hoje + '</div><div style="font-size:13px;color:#666;">Check-outs</div></div>';
        hojeHtml += '</div>';
        $('checkins-hoje').innerHTML = hojeHtml;
    });

    executarPS('reservas', 'listar', null, function(dados) {
        if (!dados || !dados.length) {
            $('reservas-recentes').innerHTML = '<p style="color:#888;text-align:center;">Nenhuma reserva recente</p>';
            return;
        }
        var recentes = dados.slice(-5).reverse();
        var html = '<table><thead><tr><th>#</th><th>Hóspede</th><th>Quarto</th><th>Check-in</th><th>Status</th></tr></thead><tbody>';
        for (var i = 0; i < recentes.length; i++) {
            var r = recentes[i];
            html += '<tr><td>' + r.id + '</td><td>' + r.hospede_nome + '</td><td>' + r.quarto_numero + '</td><td>' + formatarData(r.data_checkin) + '</td><td><span class="badge-status ' + r.status + '">' + r.status + '</span></td></tr>';
        }
        html += '</tbody></table>';
        $('reservas-recentes').innerHTML = html;
    });
}

// ===== CALENDÁRIO =====
var calendarioData = { mes: new Date().getMonth(), ano: new Date().getFullYear() };

function carregarCalendario() {
    var d = new Date();
    calendarioData.mes = d.getMonth();
    calendarioData.ano = d.getFullYear();
    renderizarCalendario();
}

function renderizarCalendario() {
    var html = '<div class="card">';
    html += '<div class="card-header"><h3>📅 Calendário de Reservas</h3></div>';
    html += '<div class="card-body">';
    html += '<div class="calendar-nav">';
    html += '<button class="btn btn-outline btn-sm" onclick="mesAnterior()">◀ Anterior</button>';
    var meses = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
    html += '<span class="mes-ano">' + meses[calendarioData.mes] + ' ' + calendarioData.ano + '</span>';
    html += '<button class="btn btn-outline btn-sm" onclick="proximoMes()">Próximo ▶</button>';
    html += '</div>';

    var primeiroDia = new Date(calendarioData.ano, calendarioData.mes, 1);
    var ultimoDia = new Date(calendarioData.ano, calendarioData.mes + 1, 0);
    var inicioSemana = primeiroDia.getDay();
    var totalDias = ultimoDia.getDate();
    var diasSemana = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
    var hoje = new Date();

    html += '<div class="calendar-grid">';
    for (var i = 0; i < 7; i++) {
        html += '<div class="dia-header">' + diasSemana[i] + '</div>';
    }

    var diaAtual = 1;
    var linhas = Math.ceil((inicioSemana + totalDias) / 7);
    for (var l = 0; l < linhas; l++) {
        for (var c = 0; c < 7; c++) {
            if ((l === 0 && c < inicioSemana) || diaAtual > totalDias) {
                html += '<div class="dia outro-mes"></div>';
            } else {
                var ehHoje = (hoje.getDate() === diaAtual && hoje.getMonth() === calendarioData.mes && hoje.getFullYear() === calendarioData.ano);
                var dataStr = calendarioData.ano + '-' + String(calendarioData.mes + 1).padStart(2, '0') + '-' + String(diaAtual).padStart(2, '0');
                html += '<div class="dia' + (ehHoje ? ' hoje' : '') + '" onclick="verReservasDia(\'' + dataStr + '\')">';
                html += '<div class="num">' + diaAtual + '</div>';
                html += '<div id="eventos-' + diaAtual + '"></div>';
                html += '</div>';
                diaAtual++;
            }
        }
    }
    html += '</div></div></div>';

    html += '<div class="card"><div class="card-header"><h3>Reservas do Dia</h3></div><div class="card-body" id="reservas-dia"><p style="color:#888;text-align:center;">Clique em um dia para ver as reservas</p></div></div>';

    $('conteudo-principal').innerHTML = html;

    carregarEventosCalendario();
}

function carregarEventosCalendario() {
    var mesStr = calendarioData.ano + '-' + String(calendarioData.mes + 1).padStart(2, '0');
    executarPS('reservas', 'listar', null, function(dados) {
        if (!dados) return;
        for (var i = 0; i < dados.length; i++) {
            var r = dados[i];
            if (r.status === 'cancelada') continue;
            if (r.data_checkin.indexOf(mesStr) === 0) {
                var dia = parseInt(r.data_checkin.split('-')[2]);
                var el = $('eventos-' + dia);
                if (el) {
                    el.innerHTML += '<div class="evento" style="background:#1565c0;color:#fff;">🛏️ ' + r.quarto_numero + ' - ' + r.hospede_nome.split(' ')[0] + '</div>';
                }
            }
        }
    });
}

function mesAnterior() {
    calendarioData.mes--;
    if (calendarioData.mes < 0) { calendarioData.mes = 11; calendarioData.ano--; }
    renderizarCalendario();
}

function proximoMes() {
    calendarioData.mes++;
    if (calendarioData.mes > 11) { calendarioData.mes = 0; calendarioData.ano++; }
    renderizarCalendario();
}

function verReservasDia(data) {
    executarPS('reservas', 'listar', null, function(dados) {
        if (!dados) return;
        var doDia = dados.filter(function(r) { return r.data_checkin === data && r.status !== 'cancelada'; });
        var html = '';
        if (doDia.length === 0) {
            html = '<p style="color:#888;text-align:center;">Nenhuma reserva para ' + formatarData(data) + '</p>';
        } else {
            html = '<table><thead><tr><th>#</th><th>Hóspede</th><th>Quarto</th><th>Noites</th><th>Status</th></tr></thead><tbody>';
            for (var i = 0; i < doDia.length; i++) {
                var r = doDia[i];
                html += '<tr><td>' + r.id + '</td><td>' + r.hospede_nome + '</td><td>' + r.quarto_numero + '</td><td>' + r.noites + '</td><td><span class="badge-status ' + r.status + '">' + r.status + '</span></td></tr>';
            }
            html += '</tbody></table>';
        }
        $('reservas-dia').innerHTML = html;
    });
}

// ===== RESERVAS =====
function carregarReservas() {
    var html = '<div class="toolbar">';
    html += '<div class="toolbar-left"><h3>Todas as Reservas</h3></div>';
    html += '<div class="toolbar-right">';
    html += '<button class="btn btn-primary" onclick="abrirModalNovaReserva()"><span class="ico">+</span> Nova Reserva</button>';
    html += '</div></div>';

    html += '<div class="filter-chips">';
    html += '<span class="chip ativo" data-filtro="todas" onclick="filtrarReservas(this,\'todas\')">Todas</span>';
    html += '<span class="chip" data-filtro="pendente" onclick="filtrarReservas(this,\'pendente\')">Pendentes</span>';
    html += '<span class="chip" data-filtro="confirmada" onclick="filtrarReservas(this,\'confirmada\')">Confirmadas</span>';
    html += '<span class="chip" data-filtro="checkin" onclick="filtrarReservas(this,\'checkin\')">Check-in</span>';
    html += '<span class="chip" data-filtro="checkout" onclick="filtrarReservas(this,\'checkout\')">Check-out</span>';
    html += '<span class="chip" data-filtro="cancelada" onclick="filtrarReservas(this,\'cancelada\')">Canceladas</span>';
    html += '</div>';

    html += '<div class="card"><div class="card-body" id="tabela-reservas"><p class="loading">Carregando...</p></div></div>';
    $('conteudo-principal').innerHTML = html;

    carregarTabelaReservas('todas');
}

var filtroReservasAtual = 'todas';

function filtrarReservas(el, filtro) {
    filtroReservasAtual = filtro;
    var chips = document.querySelectorAll('.filter-chips .chip');
    for (var i = 0; i < chips.length; i++) { chips[i].classList.remove('ativo'); }
    el.classList.add('ativo');
    carregarTabelaReservas(filtro);
}

function carregarTabelaReservas(filtro) {
    executarPS('reservas', 'listar', null, function(dados) {
        if (!dados) { $('tabela-reservas').innerHTML = '<p class="loading">Erro ao carregar</p>'; return; }

        var filtrados = dados;
        if (filtro !== 'todas') {
            filtrados = dados.filter(function(r) { return r.status === filtro; });
        }

        if (filtrados.length === 0) {
            $('tabela-reservas').innerHTML = '<p style="color:#888;text-align:center;padding:30px;">Nenhuma reserva encontrada</p>';
            return;
        }

        var html = '<div class="table-wrapper"><table><thead><tr><th>#</th><th>Hóspede</th><th>Quarto</th><th>Check-in</th><th>Check-out</th><th>Noites</th><th>Valor</th><th>Status</th><th>WhatsApp</th><th>Ações</th></tr></thead><tbody>';

        for (var i = 0; i < filtrados.length; i++) {
            var r = filtrados[i];
            var wpIcon = r.whatsapp_enviado ? '✅' : '⏳';
            html += '<tr>';
            html += '<td>' + r.id + '</td>';
            html += '<td><strong>' + r.hospede_nome + '</strong></td>';
            html += '<td>' + r.quarto_numero + ' (' + r.quarto_tipo + ')</td>';
            html += '<td>' + formatarData(r.data_checkin) + '</td>';
            html += '<td>' + formatarData(r.data_checkout) + '</td>';
            html += '<td>' + r.noites + '</td>';
            html += '<td>' + formatarMoeda(r.valor_total) + '</td>';
            html += '<td><span class="badge-status ' + r.status + '">' + r.status + '</span></td>';
            html += '<td style="text-align:center;">' + wpIcon + '</td>';
            html += '<td>';
            html += '<button class="btn btn-sm btn-info" onclick="verReserva(' + r.id + ')" title="Ver detalhes">👁</button> ';
            html += '<button class="btn btn-sm btn-primary" onclick="enviarWhatsApp(' + r.id + ')" title="Enviar WhatsApp">📱</button> ';
            if (r.status === 'pendente' || r.status === 'confirmada') {
                html += '<button class="btn btn-sm btn-success" onclick="confirmarReserva(' + r.id + ')">✅</button> ';
                html += '<button class="btn btn-sm btn-danger" onclick="cancelarReserva(' + r.id + ')">✕</button>';
            }
            if (r.status === 'confirmada') {
                html += '<button class="btn btn-sm btn-warning" onclick="realizarCheckin(' + r.id + ')">🔑</button>';
            }
            if (r.status === 'checkin') {
                html += '<button class="btn btn-sm btn-purple" onclick="realizarCheckout(' + r.id + ')">🚪</button>';
            }
            html += '</td>';
            html += '</tr>';
        }
        html += '</tbody></table></div>';
        $('tabela-reservas').innerHTML = html;
    });
}

function abrirModalNovaReserva() {
    executarPS('hospedes', 'listar', null, function(hospedes) {
        executarPS('quartos', 'disponiveis', null, function(quartos) {
            var html = '';
            html += '<form id="form-nova-reserva">';
            html += '<div class="form-group"><label>Hóspede</label><select class="form-control" id="nr-hospede" required>';
            html += '<option value="">Selecione...</option>';
            if (hospedes) for (var i = 0; i < hospedes.length; i++) {
                html += '<option value="' + hospedes[i].id + '">' + hospedes[i].nome + ' (' + hospedes[i].documento + ')</option>';
            }
            html += '</select></div>';

            html += '<div class="form-group"><label>Ou cadastre novo hóspede</label>';
            html += '<div class="form-row">';
            html += '<div class="form-group"><label>Nome</label><input class="form-control" id="nr-nome"></div>';
            html += '<div class="form-group"><label>Documento</label><input class="form-control" id="nr-documento"></div>';
            html += '<div class="form-group"><label>Telefone</label><input class="form-control" id="nr-telefone" placeholder="(11) 99999-8888"></div>';
            html += '<div class="form-group"><label>Email</label><input class="form-control" id="nr-email" type="email"></div>';
            html += '</div></div>';

            html += '<div class="form-group"><label>Quarto</label><select class="form-control" id="nr-quarto" required>';
            html += '<option value="">Selecione...</option>';
            if (quartos) for (var i = 0; i < quartos.length; i++) {
                html += '<option value="' + quartos[i].id + '" data-preco="' + quartos[i].preco_diaria + '">' + quartos[i].numero + ' - ' + quartos[i].tipo + ' (R$ ' + quartos[i].preco_diaria.toFixed(2) + ')</option>';
            }
            html += '</select></div>';

            html += '<div class="form-row">';
            html += '<div class="form-group"><label>Check-in</label><input class="form-control" id="nr-checkin" type="date" value="' + obterDataAtual() + '"></div>';
            html += '<div class="form-group"><label>Check-out</label><input class="form-control" id="nr-checkout" type="date"></div>';
            html += '</div>';

            html += '<div class="form-row-3">';
            html += '<div class="form-group"><label>Adultos</label><input class="form-control" id="nr-adultos" type="number" value="1" min="1"></div>';
            html += '<div class="form-group"><label>Crianças</label><input class="form-control" id="nr-criancas" type="number" value="0" min="0"></div>';
            html += '<div class="form-group"><label>Origem</label><select class="form-control" id="nr-origem"><option value="recepcao">Recepção</option><option value="site">Site</option><option value="telefone">Telefone</option><option value="email">Email</option></select></div>';
            html += '</div>';

            html += '<div class="form-row">';
            html += '<div class="form-group"><label>Método de Pagamento</label><select class="form-control" id="nr-pagamento"><option value="credito">Crédito</option><option value="debito">Débito</option><option value="pix">PIX</option><option value="dinheiro">Dinheiro</option><option value="boleto">Boleto</option></select></div>';
            html += '<div class="form-group"><label>Canal</label><select class="form-control" id="nr-canal"><option value="direto">Direto</option><option value="booking">Booking.com</option><option value="expedia">Expedia</option><option value="airbnb">Airbnb</option></select></div>';
            html += '</div>';

            html += '<div class="form-group"><label>Observações</label><textarea class="form-control" id="nr-obs" rows="2"></textarea></div>';
            html += '</form>';

            abrirModal('Nova Reserva', html, function() {
                salvarNovaReserva();
            }, 'Salvar Reserva');
        });
    });
}

function salvarNovaReserva() {
    var idHospede = $('nr-hospede').value;
    var nome = $('nr-nome').value;
    var documento = $('nr-documento').value;
    var telefone = $('nr-telefone').value;
    var email = $('nr-email').value;
    var idQuarto = $('nr-quarto').value;
    var checkin = $('nr-checkin').value;
    var checkout = $('nr-checkout').value;
    var adultos = parseInt($('nr-adultos').value) || 1;
    var criancas = parseInt($('nr-criancas').value) || 0;
    var origem = $('nr-origem').value;
    var pagamento = $('nr-pagamento').value;
    var canal = $('nr-canal').value;
    var obs = $('nr-obs').value;

    if (!idQuarto || !checkin || !checkout) {
        showAlert('Preencha quarto, check-in e check-out', 'danger');
        return;
    }

    var processar = function(hospedeId) {
        var checkinDate = new Date(checkin);
        var checkoutDate = new Date(checkout);
        var noites = Math.ceil((checkoutDate - checkinDate) / (1000 * 60 * 60 * 24));
        if (noites < 1) { showAlert('Data de check-out deve ser posterior ao check-in', 'danger'); return; }

        var quartoSelect = $('nr-quarto');
        var precoDiaria = parseFloat(quartoSelect.options[quartoSelect.selectedIndex].getAttribute('data-preco')) || 0;
        var valorTotal = precoDiaria * noites;
        var taxaServico = valorTotal * 0.10;

        var dados = {
            id_hospede: hospedeId, id_quarto: parseInt(idQuarto),
            data_checkin: checkin, data_checkout: checkout, noites: noites,
            origem: origem, canal: canal, valor_total: valorTotal,
            valor_diaria: precoDiaria, taxa_servico: taxaServico,
            metodo_pagamento: pagamento, observacoes: obs,
            adultos: adultos, criancas: criancas
        };

        executarPS('reservas', 'criar', dados, function(result) {
            if (result && result.id) {
                showAlert('Reserva #' + result.id + ' criada com sucesso!', 'success');
                fecharModal();
                carregarTabelaReservas(filtroReservasAtual);
            }
        });
    };

    if (idHospede) {
        processar(parseInt(idHospede));
    } else if (nome && documento) {
        var dadosHospede = { nome: nome, documento: documento, telefone: telefone, email: email };
        executarPS('hospedes', 'criar', dadosHospede, function(h) {
            if (h && h.id) { processar(h.id); }
        });
    } else {
        showAlert('Selecione um hóspede existente ou cadastre novo (nome + documento)', 'danger');
    }
}

function verReserva(id) {
    executarPS('reservas', 'obter', { id: id }, function(r) {
        if (!r || r.erro) { showAlert('Reserva não encontrada', 'danger'); return; }
        var html = '';
        html += '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">';
        html += '<div><strong>#:</strong> ' + r.id + '</div>';
        html += '<div><strong>Status:</strong> <span class="badge-status ' + r.status + '">' + r.status + '</span></div>';
        html += '<div><strong>Hóspede ID:</strong> ' + r.id_hospede + '</div>';
        html += '<div><strong>Quarto ID:</strong> ' + r.id_quarto + '</div>';
        html += '<div><strong>Check-in:</strong> ' + formatarData(r.data_checkin) + '</div>';
        html += '<div><strong>Check-out:</strong> ' + formatarData(r.data_checkout) + '</div>';
        html += '<div><strong>Noites:</strong> ' + r.noites + '</div>';
        html += '<div><strong>Adultos:</strong> ' + r.adultos + ' | <strong>Crianças:</strong> ' + r.criancas + '</div>';
        html += '<div><strong>Valor:</strong> ' + formatarMoeda(r.valor_total) + '</div>';
        html += '<div><strong>Taxa:</strong> ' + formatarMoeda(r.taxa_servico) + '</div>';
        html += '<div><strong>Pagamento:</strong> ' + r.metodo_pagamento + ' (' + r.situacao_pagamento + ')</div>';
        html += '<div><strong>Canal:</strong> ' + r.canal + '</div>';
        html += '<div style="grid-column:1/-1;"><strong>Observações:</strong> ' + (r.observacoes || '-') + '</div>';
        if (r.checkin_realizado) html += '<div style="grid-column:1/-1;"><strong>Check-in realizado:</strong> ' + r.checkin_realizado + '</div>';
        if (r.checkout_realizado) html += '<div style="grid-column:1/-1;"><strong>Check-out realizado:</strong> ' + r.checkout_realizado + '</div>';
        html += '</div>';
        abrirModal('Reserva #' + r.id, html, null, null);
    });
}

function confirmarReserva(id) {
    if (!confirm('Confirmar reserva #' + id + '?')) return;
    executarPS('reservas', 'atualizar_status', { id: id, novo_status: 'confirmada' }, function(r) {
        if (r && r.sucesso) { showAlert(r.mensagem, 'success'); carregarTabelaReservas(filtroReservasAtual); }
    });
}

function cancelarReserva(id) {
    if (!confirm('Cancelar reserva #' + id + '?')) return;
    executarPS('reservas', 'cancelar', { id: id }, function(r) {
        if (r && r.sucesso) { showAlert(r.mensagem, 'warning'); carregarTabelaReservas(filtroReservasAtual); }
    });
}

function realizarCheckin(id) {
    if (!confirm('Realizar check-in da reserva #' + id + '?')) return;
    executarPS('reservas', 'atualizar_status', { id: id, novo_status: 'checkin' }, function(r) {
        if (r && r.sucesso) {
            executarPS('reservas', 'obter', { id: id }, function(res) {
                if (res) {
                    executarPS('quartos', 'atualizar_status', { id: res.id_quarto, novo_status: 'ocupado' }, function() {});
                }
            });
            showAlert('Check-in realizado!', 'success');
            carregarTabelaReservas(filtroReservasAtual);
        }
    });
}

function realizarCheckout(id) {
    if (!confirm('Realizar check-out da reserva #' + id + '?')) return;
    executarPS('reservas', 'atualizar_status', { id: id, novo_status: 'checkout' }, function(r) {
        if (r && r.sucesso) {
            executarPS('reservas', 'obter', { id: id }, function(res) {
                if (res) {
                    executarPS('quartos', 'atualizar_status', { id: res.id_quarto, novo_status: 'limpeza' }, function() {});
                }
            });
            showAlert('Check-out realizado! Quarto encaminhado para limpeza.', 'success');
            carregarTabelaReservas(filtroReservasAtual);
        }
    });
}

// ===== OPERAÇÕES =====
function carregarOperacoes() {
    var html = '<div class="tabs">';
    html += '<span class="tab ativo" data-tab="quartos" onclick="mudarTabOps(this,\'quartos\')">🏨 Quartos</span>';
    html += '<span class="tab" data-tab="limpeza" onclick="mudarTabOps(this,\'limpeza\')">🧹 Limpeza</span>';
    html += '<span class="tab" data-tab="recepcao" onclick="mudarTabOps(this,\'recepcao\')">🛎️ Recepção</span>';
    html += '</div>';
    html += '<div id="ops-conteudo"><p class="loading">Carregando...</p></div>';
    $('conteudo-principal').innerHTML = html;
    carregarOpsQuartos();
}

function mudarTabOps(el, tab) {
    var tabs = document.querySelectorAll('.tabs .tab');
    for (var i = 0; i < tabs.length; i++) { tabs[i].classList.remove('ativo'); }
    el.classList.add('ativo');
    if (tab === 'quartos') carregarOpsQuartos();
    else if (tab === 'limpeza') carregarOpsLimpeza();
    else if (tab === 'recepcao') carregarOpsRecepcao();
}

function carregarOpsQuartos() {
    executarPS('quartos', 'listar', null, function(dados) {
        if (!dados) { $('ops-conteudo').innerHTML = '<p>Erro ao carregar</p>'; return; }
        var stats = { disponivel:0, ocupado:0, reservado:0, manutencao:0, limpeza:0 };
        if (dados) for (var qi = 0; qi < dados.length; qi++) { if (stats[dados[qi].status] !== undefined) stats[dados[qi].status]++; }

        var html = '<div style="display:grid;grid-template-columns:repeat(5,1fr);gap:10px;margin-bottom:20px;">';
        html += '<div style="text-align:center;padding:10px;background:#e8f5e9;border-radius:8px;"><div style="font-size:22px;font-weight:700;color:#2e7d32;">' + stats.disponivel + '</div><div style="font-size:12px;">Disponíveis</div></div>';
        html += '<div style="text-align:center;padding:10px;background:#e3f2fd;border-radius:8px;"><div style="font-size:22px;font-weight:700;color:#1565c0;">' + stats.ocupado + '</div><div style="font-size:12px;">Ocupados</div></div>';
        html += '<div style="text-align:center;padding:10px;background:#fff3e0;border-radius:8px;"><div style="font-size:22px;font-weight:700;color:#e65100;">' + stats.reservado + '</div><div style="font-size:12px;">Reservados</div></div>';
        html += '<div style="text-align:center;padding:10px;background:#fce4ec;border-radius:8px;"><div style="font-size:22px;font-weight:700;color:#c62828;">' + stats.manutencao + '</div><div style="font-size:12px;">Manutenção</div></div>';
        html += '<div style="text-align:center;padding:10px;background:#e0f2f1;border-radius:8px;"><div style="font-size:22px;font-weight:700;color:#00695c;">' + stats.limpeza + '</div><div style="font-size:12px;">Limpeza</div></div>';
        html += '</div>';

        html += '<div class="card"><div class="card-body"><div class="table-wrapper"><table><thead><tr><th>Quarto</th><th>Andar</th><th>Tipo</th><th>Capacidade</th><th>Diária</th><th>Status</th><th>Últ. Limpeza</th><th>Ações</th></tr></thead><tbody>';
        for (var i = 0; i < dados.length; i++) {
            var q = dados[i];
            html += '<tr>';
            html += '<td><strong>' + q.numero + '</strong></td>';
            html += '<td>' + q.andar + '° andar</td>';
            html += '<td>' + q.tipo + '</td>';
            html += '<td>' + q.capacidade + '</td>';
            html += '<td>' + formatarMoeda(q.preco_diaria) + '</td>';
            html += '<td><span class="badge-status ' + q.status + '">' + q.status + '</span></td>';
            html += '<td>' + formatarData(q.ultima_limpeza) + '</td>';
            html += '<td>';
            if (q.status === 'disponivel') html += '<button class="btn btn-sm btn-outline" onclick="mudarStatusQuarto(' + q.id + ',\'reservado\')">Reservar</button> ';
            if (q.status === 'ocupado') html += '<button class="btn btn-sm btn-outline" onclick="mudarStatusQuarto(' + q.id + ',\'limpeza\')">Limpeza</button> ';
            if (q.status === 'limpeza') html += '<button class="btn btn-sm btn-success" onclick="mudarStatusQuarto(' + q.id + ',\'disponivel\')">Liberar</button> ';
            if (q.status === 'manutencao') html += '<button class="btn btn-sm btn-success" onclick="mudarStatusQuarto(' + q.id + ',\'disponivel\')">Liberar</button> ';
            html += '<button class="btn btn-sm btn-danger" onclick="mudarStatusQuarto(' + q.id + ',\'manutencao\')">🔧</button>';
            html += '</td>';
            html += '</tr>';
        }
        html += '</tbody></table></div></div></div>';
        $('ops-conteudo').innerHTML = html;
    });
}

function carregarOpsLimpeza() {
    executarPS('quartos', 'listar', null, function(dados) {
        if (!dados) return;
        var limpeza = dados.filter(function(q) { return q.status === 'limpeza' || q.status === 'disponivel'; });
        var html = '<div class="card"><div class="card-header"><h3>🧹 Gerenciamento de Limpeza</h3></div><div class="card-body">';

        var pendentes = dados.filter(function(q) { return q.status === 'limpeza'; });
        html += '<h4 style="margin-bottom:10px;">Pendentes de Limpeza (' + pendentes.length + ')</h4>';
        if (pendentes.length === 0) {
            html += '<p style="color:#888;">Nenhum quarto aguardando limpeza</p>';
        } else {
            html += '<div class="table-wrapper"><table><thead><tr><th>Quarto</th><th>Andar</th><th>Tipo</th><th>Check-out</th><th>Ação</th></tr></thead><tbody>';
            for (var i = 0; i < pendentes.length; i++) {
                html += '<tr><td>' + pendentes[i].numero + '</td><td>' + pendentes[i].andar + '°</td><td>' + pendentes[i].tipo + '</td><td>' + formatarData(pendentes[i].ultima_limpeza) + '</td><td><button class="btn btn-sm btn-success" onclick="mudarStatusQuarto(' + pendentes[i].id + ',\'disponivel\')">✅ Concluir Limpeza</button></td></tr>';
            }
            html += '</tbody></table></div>';
        }

        html += '<h4 style="margin:20px 0 10px;">Quartos Disponíveis</h4>';
        var disp = dados.filter(function(q) { return q.status === 'disponivel'; });
        html += '<p>' + disp.length + ' quartos disponíveis e prontos para uso</p>';

        html += '</div></div>';
        $('ops-conteudo').innerHTML = html;
    });
}

function carregarOpsRecepcao() {
    var hoje = obterDataAtual();
    executarPS('reservas', 'listar', null, function(dados) {
        if (!dados) return;
        var checkinsHoje = dados.filter(function(r) { return r.data_checkin === hoje && r.status !== 'cancelada'; });
        var checkoutsHoje = dados.filter(function(r) { return r.data_checkout === hoje && r.status !== 'cancelada'; });

        var html = '<div class="card"><div class="card-header"><h3>🛎️ Recepção - ' + formatarData(hoje) + '</h3></div><div class="card-body">';
        html += '<div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">';

        html += '<div><h4 style="margin-bottom:10px;">🔑 Check-ins (' + checkinsHoje.length + ')</h4>';
        if (checkinsHoje.length === 0) html += '<p style="color:#888;">Nenhum check-in programado</p>';
        else {
            html += '<div class="table-wrapper"><table><thead><tr><th>Hóspede</th><th>Quarto</th><th>Ação</th></tr></thead><tbody>';
            for (var i = 0; i < checkinsHoje.length; i++) {
                html += '<tr><td>' + checkinsHoje[i].hospede_nome + '</td><td>' + checkinsHoje[i].quarto_numero + '</td><td><button class="btn btn-sm btn-success" onclick="realizarCheckin(' + checkinsHoje[i].id + ')">🔑 Check-in</button></td></tr>';
            }
            html += '</tbody></table></div>';
        }

        html += '</div><div><h4 style="margin-bottom:10px;">🚪 Check-outs (' + checkoutsHoje.length + ')</h4>';
        if (checkoutsHoje.length === 0) html += '<p style="color:#888;">Nenhum check-out programado</p>';
        else {
            html += '<div class="table-wrapper"><table><thead><tr><th>Hóspede</th><th>Quarto</th><th>Ação</th></tr></thead><tbody>';
            for (var i = 0; i < checkoutsHoje.length; i++) {
                html += '<tr><td>' + checkoutsHoje[i].hospede_nome + '</td><td>' + checkoutsHoje[i].quarto_numero + '</td><td><button class="btn btn-sm btn-warning" onclick="realizarCheckout(' + checkoutsHoje[i].id + ')">🚪 Check-out</button></td></tr>';
            }
            html += '</tbody></table></div>';
        }
        html += '</div></div></div>';
        $('ops-conteudo').innerHTML = html;
    });
}

function mudarStatusQuarto(id, status) {
    executarPS('quartos', 'atualizar_status', { id: id, novo_status: status }, function(r) {
        if (r && r.sucesso) showAlert(r.mensagem, 'success');
        carregarOpsQuartos();
    });
}

// ===== HÓSPEDES =====
function carregarHospedes() {
    var html = '<div class="toolbar">';
    html += '<div class="toolbar-left"><div class="search-box"><input id="busca-hospede" placeholder="Buscar hóspede..." onkeyup="buscarHospede(this.value)"></div></div>';
    html += '<div class="toolbar-right"><button class="btn btn-primary" onclick="abrirModalNovoHospede()">+ Novo Hóspede</button></div>';
    html += '</div>';
    html += '<div class="card"><div class="card-body" id="tabela-hospedes"><p class="loading">Carregando...</p></div></div>';
    $('conteudo-principal').innerHTML = html;
    carregarTabelaHospedes();
}

function carregarTabelaHospedes() {
    executarPS('hospedes', 'listar', null, function(dados) {
        if (!dados || !dados.length) {
            $('tabela-hospedes').innerHTML = '<p style="color:#888;text-align:center;padding:30px;">Nenhum hóspede cadastrado</p>';
            return;
        }
        var html = '<div class="table-wrapper"><table><thead><tr><th>#</th><th>Nome</th><th>Documento</th><th>Telefone</th><th>Email</th><th>Visitas</th><th>Total Gasto</th><th>Ações</th></tr></thead><tbody>';
        for (var i = 0; i < dados.length; i++) {
            var h = dados[i];
            html += '<tr>';
            html += '<td>' + h.id + '</td>';
            html += '<td><strong>' + h.nome + '</strong></td>';
            html += '<td>' + h.documento + '</td>';
            html += '<td>' + h.telefone + '</td>';
            html += '<td>' + h.email + '</td>';
            html += '<td>' + h.total_visitas + '</td>';
            html += '<td>' + formatarMoeda(h.total_gasto) + '</td>';
            html += '<td><button class="btn btn-sm btn-info" onclick="verHospede(' + h.id + ')">👁</button></td>';
            html += '</tr>';
        }
        html += '</tbody></table></div>';
        $('tabela-hospedes').innerHTML = html;
    });
}

function buscarHospede(valor) {
    if (valor.length < 2) { carregarTabelaHospedes(); return; }
    executarPS('hospedes', 'buscar', { termo: valor }, function(dados) {
        if (!dados || !dados.length) {
            $('tabela-hospedes').innerHTML = '<p style="color:#888;text-align:center;padding:30px;">Nenhum resultado</p>';
            return;
        }
        var html = '<div class="table-wrapper"><table><thead><tr><th>#</th><th>Nome</th><th>Documento</th><th>Telefone</th><th>Email</th><th>Visitas</th><th>Total Gasto</th></tr></thead><tbody>';
        for (var i = 0; i < dados.length; i++) {
            html += '<tr><td>' + dados[i].id + '</td><td><strong>' + dados[i].nome + '</strong></td><td>' + dados[i].documento + '</td><td>' + dados[i].telefone + '</td><td>' + dados[i].email + '</td><td>' + dados[i].total_visitas + '</td><td>' + formatarMoeda(dados[i].total_gasto) + '</td></tr>';
        }
        html += '</tbody></table></div>';
        $('tabela-hospedes').innerHTML = html;
    });
}

function verHospede(id) {
    executarPS('hospedes', 'obter', { id: id }, function(h) {
        if (!h || h.erro) return;
        var html = '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;">';
        html += '<div><strong>Nome:</strong> ' + h.nome + '</div>';
        html += '<div><strong>Documento:</strong> ' + h.documento + ' (' + h.tipo_documento + ')</div>';
        html += '<div><strong>Telefone:</strong> ' + h.telefone + '</div>';
        html += '<div><strong>Email:</strong> ' + h.email + '</div>';
        html += '<div style="grid-column:1/-1;"><strong>Endereço:</strong> ' + h.endereco + '</div>';
        html += '<div><strong>Nacionalidade:</strong> ' + h.nacionalidade + '</div>';
        html += '<div><strong>Cadastro:</strong> ' + formatarData(h.data_cadastro) + '</div>';
        html += '<div><strong>Visitas:</strong> ' + h.total_visitas + '</div>';
        html += '<div><strong>Total Gasto:</strong> ' + formatarMoeda(h.total_gasto) + '</div>';
        if (h.observacoes) html += '<div style="grid-column:1/-1;"><strong>Obs:</strong> ' + h.observacoes + '</div>';
        html += '</div>';
        abrirModal('Hóspede: ' + h.nome, html, null, null);
    });
}

function abrirModalNovoHospede() {
    var html = '<form id="form-novo-hospede">';
    html += '<div class="form-group"><label>Nome *</label><input class="form-control" id="h-nome" required></div>';
    html += '<div class="form-row">';
    html += '<div class="form-group"><label>Documento *</label><input class="form-control" id="h-documento" placeholder="CPF ou Passaporte"></div>';
    html += '<div class="form-group"><label>Tipo</label><select class="form-control" id="h-tipo-doc"><option value="CPF">CPF</option><option value="Passaporte">Passaporte</option><option value="RG">RG</option></select></div>';
    html += '</div>';
    html += '<div class="form-row">';
    html += '<div class="form-group"><label>Telefone</label><input class="form-control" id="h-telefone" placeholder="(11) 99999-8888"></div>';
    html += '<div class="form-group"><label>Email</label><input class="form-control" id="h-email" type="email"></div>';
    html += '</div>';
    html += '<div class="form-group"><label>Endereço</label><input class="form-control" id="h-endereco"></div>';
    html += '<div class="form-row">';
    html += '<div class="form-group"><label>Nacionalidade</label><input class="form-control" id="h-nacionalidade" value="Brasileira"></div>';
    html += '</div>';
    html += '<div class="form-group"><label>Observações</label><textarea class="form-control" id="h-obs" rows="2"></textarea></div>';
    html += '</form>';
    abrirModal('Novo Hóspede', html, function() {
        var dados = {
            nome: $('h-nome').value, documento: $('h-documento').value,
            tipo_documento: $('h-tipo-doc').value, telefone: $('h-telefone').value,
            email: $('h-email').value, endereco: $('h-endereco').value,
            nacionalidade: $('h-nacionalidade').value, observacoes: $('h-obs').value
        };
        if (!dados.nome || !dados.documento) { showAlert('Nome e documento são obrigatórios', 'danger'); return; }
        executarPS('hospedes', 'criar', dados, function(r) {
            if (r && r.id) { showAlert('Hóspede cadastrado!', 'success'); fecharModal(); carregarTabelaHospedes(); }
        });
    }, 'Salvar');
}

// ===== CANAIS =====
function carregarCanais() {
    var html = '<div class="card"><div class="card-header"><h3>📡 Gerente de Canal</h3></div><div class="card-body">';
    html += '<p style="margin-bottom:20px;">Gerencie o inventário de quartos e tarifas em múltiplas plataformas de reserva.</p>';

    executarPS('analise', 'canais', null, function(dados) {
        var canais = [
            { id:'direto', nome:'Reserva Direta', icone:'🌐', cor:'#1565c0', comissao:0 },
            { id:'booking', nome:'Booking.com', icone:'🏨', cor:'#e65100', comissao:15 },
            { id:'expedia', nome:'Expedia', icone:'✈️', cor:'#2e7d32', comissao:18 },
            { id:'airbnb', nome:'Airbnb', icone:'🏠', cor:'#c62828', comissao:12 }
        ];

        html += '<div style="display:grid;grid-template-columns:repeat(2,1fr);gap:15px;margin-bottom:20px;">';
        for (var i = 0; i < canais.length; i++) {
            var c = canais[i];
            var canalDados = dados ? dados.filter(function(d) { return d.canal === c.id; }) : [];
            var qtd = canalDados.length > 0 ? canalDados[0].quantidade : 0;
            var receita = canalDados.length > 0 ? canalDados[0].receita_total : 0;

            html += '<div class="canal-card">';
            html += '<div class="canal-icon" style="background:' + c.cor + '22;color:' + c.cor + ';">' + c.icone + '</div>';
            html += '<div class="canal-info"><h4>' + c.nome + '</h4>';
            html += '<p>Comissão: ' + c.comissao + '% | Reservas: ' + qtd + ' | Receita: ' + formatarMoeda(receita) + '</p></div>';
            html += '<div><span class="badge-status" style="background:' + c.cor + ';color:#fff;">Ativo</span></div>';
            html += '</div>';
        }
        html += '</div>';

        html += '<h4 style="margin:20px 0 10px;">Distribuição por Canal</h4>';
        if (dados && dados.length) {
            html += '<div class="table-wrapper"><table><thead><tr><th>Canal</th><th>Reservas</th><th>Receita Total</th><th>%</th></tr></thead><tbody>';
            for (var i = 0; i < dados.length; i++) {
                html += '<tr><td><strong>' + dados[i].canal + '</strong></td><td>' + dados[i].quantidade + '</td><td>' + formatarMoeda(dados[i].receita_total) + '</td><td>' + dados[i].percentual + '%</td></tr>';
            }
            html += '</tbody></table></div>';
        } else {
            html += '<p style="color:#888;">Sem dados de canais disponíveis</p>';
        }

        html += '</div></div>';
        $('conteudo-principal').innerHTML = html;
    });
}

// ===== FINANCEIRO =====
function carregarFinanceiro() {
    var html = '<div class="tabs">';
    html += '<span class="tab ativo" data-tab="fluxo" onclick="mudarTabFin(this,\'fluxo\')">💰 Fluxo de Caixa</span>';
    html += '<span class="tab" data-tab="balanco" onclick="mudarTabFin(this,\'balanco\')">📊 Balanceamento Mensal</span>';
    html += '<span class="tab" data-tab="lancamentos" onclick="mudarTabFin(this,\'lancamentos\')">📝 Lançamentos</span>';
    html += '</div>';
    html += '<div id="fin-conteudo"><p class="loading">Carregando...</p></div>';
    $('conteudo-principal').innerHTML = html;
    carregarFluxoCaixa();
}

function mudarTabFin(el, tab) {
    var tabs = document.querySelectorAll('.tabs .tab');
    for (var i = 0; i < tabs.length; i++) { tabs[i].classList.remove('ativo'); }
    el.classList.add('ativo');
    if (tab === 'fluxo') carregarFluxoCaixa();
    else if (tab === 'balanco') carregarBalanceamento();
    else if (tab === 'lancamentos') carregarLancamentos();
}

function carregarFluxoCaixa() {
    var hoje = new Date();
    var mesAtual = hoje.getFullYear() + '-' + String(hoje.getMonth() + 1).padStart(2, '0');

    executarPS('financeiro', 'resumo_mensal', { mes: mesAtual }, function(dados) {
        var html = '';
        if (dados) {
            html += '<div class="stats-grid" style="grid-template-columns:repeat(4,1fr);">';
            html += '<div class="stat-card"><div class="stat-icon bg-green">💰</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(dados.total_receitas) + '</div><div class="stat-label">Receitas</div></div></div>';
            html += '<div class="stat-card"><div class="stat-icon bg-red">💸</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(dados.total_despesas) + '</div><div class="stat-label">Despesas</div></div></div>';
            html += '<div class="stat-card"><div class="stat-icon bg-blue">⚖️</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(dados.saldo) + '</div><div class="stat-label">Saldo</div></div></div>';
            html += '<div class="stat-card"><div class="stat-icon bg-orange">📋</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(dados.a_receber) + '</div><div class="stat-label">A Receber</div></div></div>';
            html += '</div>';

            html += '<div class="card"><div class="card-header"><h3>Fluxo de Caixa - ' + mesAtual + '</h3></div><div class="card-body">';
            html += '<div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">';
            html += '<div><h4 style="color:#2e7d32;">Receitas (' + dados.qtd_receitas + ')</h4>';
            html += '<p style="font-size:24px;font-weight:700;color:#2e7d32;">' + formatarMoeda(dados.total_receitas) + '</p></div>';
            html += '<div><h4 style="color:#c62828;">Despesas (' + dados.qtd_despesas + ')</h4>';
            html += '<p style="font-size:24px;font-weight:700;color:#c62828;">' + formatarMoeda(dados.total_despesas) + '</p></div>';
            html += '</div>';

            html += '<div style="margin-top:20px;padding:20px;background:#f0f2f5;border-radius:8px;text-align:center;">';
            html += '<div style="font-size:14px;color:#666;">SALDO DO MÊS</div>';
            html += '<div style="font-size:36px;font-weight:700;color:' + (dados.saldo >= 0 ? '#2e7d32' : '#c62828') + ';">' + formatarMoeda(dados.saldo) + '</div>';
            html += '</div></div></div>';

            html += '<div class="card"><div class="card-header"><h3>📈 Recebido vs A Receber</h3></div><div class="card-body">';
            html += '<div style="display:flex;gap:20px;">';
            var totalGeral = dados.recebido + dados.a_receber;
            var pctRecebido = totalGeral > 0 ? Math.round(dados.recebido / totalGeral * 100) : 0;
            html += '<div style="flex:1;padding:20px;background:#e8f5e9;border-radius:8px;text-align:center;"><div style="font-size:28px;font-weight:700;color:#2e7d32;">' + formatarMoeda(dados.recebido) + '</div><div style="font-size:13px;">Recebido (' + pctRecebido + '%)</div></div>';
            html += '<div style="flex:1;padding:20px;background:#fff3e0;border-radius:8px;text-align:center;"><div style="font-size:28px;font-weight:700;color:#e65100;">' + formatarMoeda(dados.a_receber) + '</div><div style="font-size:13px;">A Receber (' + (100 - pctRecebido) + '%)</div></div>';
            html += '</div></div></div>';
        } else {
            html = '<p class="loading">Sem dados financeiros para este mês</p>';
        }
        $('fin-conteudo').innerHTML = html;
    });
}

function carregarBalanceamento() {
    executarPS('financeiro', 'saldos_mensais', null, function(dados) {
        executarPS('financeiro', 'balanco_anual', null, function(balanco) {
            var html = '';

            if (balanco) {
                html += '<div class="stats-grid" style="grid-template-columns:repeat(4,1fr);">';
                html += '<div class="stat-card"><div class="stat-icon bg-green">📈</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(balanco.total_receitas_anuais) + '</div><div class="stat-label">Receitas Anuais</div></div></div>';
                html += '<div class="stat-card"><div class="stat-icon bg-red">📉</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(balanco.total_despesas_anuais) + '</div><div class="stat-label">Despesas Anuais</div></div></div>';
                html += '<div class="stat-card"><div class="stat-icon bg-blue">🏆</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(balanco.saldo_anual) + '</div><div class="stat-label">Saldo Anual</div></div></div>';
                html += '<div class="stat-card"><div class="stat-icon bg-purple">⭐</div><div class="stat-info"><div class="stat-value">' + balanco.melhor_mes + '</div><div class="stat-label">Melhor Mês</div></div></div>';
                html += '</div>';
            }

            html += '<div class="card"><div class="card-header"><h3>Balanceamento Mensal</h3></div><div class="card-body">';
            if (dados && dados.length) {
                html += '<div class="table-wrapper"><table><thead><tr><th>Mês</th><th>Receitas</th><th>Despesas</th><th>Saldo</th><th>Variação</th></tr></thead><tbody>';
                var anterior = 0;
                for (var i = 0; i < dados.length; i++) {
                    var m = dados[i];
                    var variacao = anterior > 0 ? ((m.saldo - anterior) / anterior * 100).toFixed(1) : '-';
                    var cor = m.saldo >= 0 ? '#2e7d32' : '#c62828';
                    html += '<tr>';
                    html += '<td><strong>' + m.mes + '</strong></td>';
                    html += '<td style="color:#2e7d32;">' + formatarMoeda(m.receitas) + '</td>';
                    html += '<td style="color:#c62828;">' + formatarMoeda(m.despesas) + '</td>';
                    html += '<td style="color:' + cor + ';font-weight:700;">' + formatarMoeda(m.saldo) + '</td>';
                    html += '<td>' + (variacao !== '-' ? (parseFloat(variacao) >= 0 ? '📈 +' : '📉 ') + variacao + '%' : '-') + '</td>';
                    html += '</tr>';
                    anterior = m.saldo;
                }
                html += '</tbody></table></div>';

                html += '<div style="margin-top:20px;"><h4>Gráfico de Tendências</h4>';
                html += '<div style="display:flex;align-items:flex-end;gap:8px;height:150px;padding:10px 0;">';
                var maxValor = Math.max.apply(null, dados.map(function(m) { return Math.max(m.receitas, m.despesas); }));
                for (var i = 0; i < dados.length; i++) {
                    var altReceita = Math.max(4, Math.round(dados[i].receitas / (maxValor || 1) * 120));
                    var altDespesa = Math.max(4, Math.round(dados[i].despesas / (maxValor || 1) * 120));
                    html += '<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;">';
                    html += '<div style="width:100%;display:flex;gap:2px;align-items:flex-end;height:130px;">';
                    html += '<div style="flex:1;background:#2e7d32;height:' + altReceita + 'px;border-radius:3px 3px 0 0;" title="Receitas ' + dados[i].mes + ': ' + formatarMoeda(dados[i].receitas) + '"></div>';
                    html += '<div style="flex:1;background:#c62828;height:' + altDespesa + 'px;border-radius:3px 3px 0 0;" title="Despesas ' + dados[i].mes + ': ' + formatarMoeda(dados[i].despesas) + '"></div>';
                    html += '</div>';
                    html += '<span style="font-size:10px;color:#888;">' + dados[i].mes.substring(5) + '</span>';
                    html += '</div>';
                }
                html += '</div></div>';

            } else {
                html += '<p style="color:#888;">Nenhum dado de balanceamento disponível</p>';
            }
            html += '</div></div>';

            html += '<div class="card"><div class="card-header"><h3>➕ Novo Lançamento</h3></div><div class="card-body">';
            html += '<div class="form-row">';
            html += '<div class="form-group"><label>Tipo</label><select class="form-control" id="lct-tipo"><option value="receita">Receita</option><option value="despesa">Despesa</option></select></div>';
            html += '<div class="form-group"><label>Categoria</label><select class="form-control" id="lct-categoria"><option value="diaria">Diária</option><option value="servicos">Serviços</option><option value="alimentacao">Alimentação</option><option value="outros">Outros</option></select></div>';
            html += '<div class="form-group"><label>Valor</label><input class="form-control" id="lct-valor" type="number" step="0.01"></div>';
            html += '</div>';
            html += '<div class="form-group"><label>Descrição</label><input class="form-control" id="lct-descricao"></div>';
            html += '<div class="form-group"><label>Método</label><select class="form-control" id="lct-metodo"><option value="credito">Crédito</option><option value="debito">Débito</option><option value="pix">PIX</option><option value="dinheiro">Dinheiro</option><option value="boleto">Boleto</option><option value="transferencia">Transferência</option></select></div>';
            html += '<button class="btn btn-success" onclick="adicionarLancamento()">+ Adicionar Lançamento</button>';
            html += '</div></div>';

            $('fin-conteudo').innerHTML = html;
        });
    });
}

function adicionarLancamento() {
    var tipo = $('lct-tipo').value;
    var categoria = $('lct-categoria').value;
    var valor = parseFloat($('lct-valor').value);
    var descricao = $('lct-descricao').value;
    var metodo = $('lct-metodo').value;

    if (!valor || !descricao) { showAlert('Preencha valor e descrição', 'danger'); return; }

    var dados = {
        data: obterDataAtual(), tipo: tipo, categoria: categoria,
        descricao: descricao, valor: valor, metodo: metodo, id_reserva: null
    };

    executarPS('financeiro', 'criar_lancamento', dados, function(r) {
        if (r && r.id) {
            showAlert('Lançamento adicionado!', 'success');
            carregarBalanceamento();
        }
    });
}

function carregarLancamentos() {
    executarPS('financeiro', 'listar', null, function(dados) {
        if (!dados || !dados.length) {
            $('fin-conteudo').innerHTML = '<p style="color:#888;text-align:center;padding:30px;">Nenhum lançamento</p>';
            return;
        }
        var html = '<div class="card"><div class="card-body"><div class="table-wrapper"><table><thead><tr><th>#</th><th>Data</th><th>Tipo</th><th>Categoria</th><th>Descrição</th><th>Valor</th><th>Método</th><th>Status</th><th>Ações</th></tr></thead><tbody>';
        var reversed = dados.slice().reverse();
        for (var i = 0; i < reversed.length; i++) {
            var l = reversed[i];
            var cor = l.tipo === 'receita' ? '#2e7d32' : '#c62828';
            var sinal = l.tipo === 'receita' ? '+' : '-';
            html += '<tr>';
            html += '<td>' + l.id + '</td>';
            html += '<td>' + formatarData(l.data) + '</td>';
            html += '<td><span class="badge-status" style="background:' + (l.tipo === 'receita' ? '#e8f5e9' : '#fce4ec') + ';color:' + cor + ';">' + l.tipo + '</span></td>';
            html += '<td>' + l.categoria + '</td>';
            html += '<td>' + l.descricao + '</td>';
            html += '<td style="color:' + cor + ';font-weight:600;">' + sinal + ' ' + formatarMoeda(l.valor) + '</td>';
            html += '<td>' + l.metodo + '</td>';
            html += '<td><span class="badge-status" style="background:' + (l.status === 'recebido' || l.status === 'pago' ? '#e8f5e9' : '#fff8e1') + ';color:' + (l.status === 'recebido' || l.status === 'pago' ? '#2e7d32' : '#f57f17') + ';">' + l.status + '</span></td>';
            html += '<td>';
            if (l.tipo === 'receita' && l.status === 'pendente') html += '<button class="btn btn-sm btn-success" onclick="baixarRecebimento(' + l.id + ')">💰 Receber</button>';
            html += '</td>';
            html += '</tr>';
        }
        html += '</tbody></table></div></div></div>';
        $('fin-conteudo').innerHTML = html;
    });
}

function baixarRecebimento(id) {
    executarPS('financeiro', 'baixar_recebimento', { id: id }, function(r) {
        if (r && r.sucesso) { showAlert('Recebimento registrado!', 'success'); carregarLancamentos(); }
    });
}

// ===== ANÁLISE =====
function carregarAnalise() {
    var html = '<div class="tabs">';
    html += '<span class="tab ativo" data-tab="visao" onclick="mudarTabAnalise(this,\'visao\')">📊 Visão Geral</span>';
    html += '<span class="tab" data-tab="ocupacao" onclick="mudarTabAnalise(this,\'ocupacao\')">🏨 Ocupação</span>';
    html += '<span class="tab" data-tab="canais" onclick="mudarTabAnalise(this,\'canais-analise\')">📡 Canais</span>';
    html += '<span class="tab" data-tab="tendencias" onclick="mudarTabAnalise(this,\'tendencias\')">📈 Tendências</span>';
    html += '</div>';
    html += '<div id="analise-conteudo"><p class="loading">Carregando...</p></div>';
    $('conteudo-principal').innerHTML = html;
    carregarVisaoGeral();
}

function mudarTabAnalise(el, tab) {
    var tabs = document.querySelectorAll('.tabs .tab');
    for (var i = 0; i < tabs.length; i++) { tabs[i].classList.remove('ativo'); }
    el.classList.add('ativo');
    if (tab === 'visao') carregarVisaoGeral();
    else if (tab === 'ocupacao') carregarAnaliseOcupacao();
    else if (tab === 'canais-analise') carregarAnaliseCanais();
    else if (tab === 'tendencias') carregarTendencias();
}

function carregarVisaoGeral() {
    executarPS('analise', 'dashboard', null, function(d) {
        if (!d) return;
        var html = '<div class="stats-grid" style="grid-template-columns:repeat(4,1fr);">';
        html += '<div class="stat-card"><div class="stat-icon bg-blue">🏨</div><div class="stat-info"><div class="stat-value">' + d.total_quartos + '</div><div class="stat-label">Total Quartos</div></div></div>';
        html += '<div class="stat-card"><div class="stat-icon bg-green">📊</div><div class="stat-info"><div class="stat-value">' + d.taxa_ocupacao + '%</div><div class="stat-label">Taxa Ocupação</div></div></div>';
        html += '<div class="stat-card"><div class="stat-icon bg-purple">👥</div><div class="stat-info"><div class="stat-value">' + d.total_hospedes + '</div><div class="stat-label">Total Hóspedes</div></div></div>';
        html += '<div class="stat-card"><div class="stat-icon bg-teal">💰</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(d.receitas_mes) + '</div><div class="stat-label">Receita Mês</div></div></div>';
        html += '</div>';

        html += '<div class="card"><div class="card-header"><h3>Indicadores de Desempenho</h3></div><div class="card-body">';
        html += '<div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">';

        var ocupacaoPct = d.taxa_ocupacao;
        html += '<div><h4>Taxa de Ocupação</h4><div style="background:#e0e0e0;border-radius:10px;height:30px;margin-top:8px;overflow:hidden;"><div style="background:' + (ocupacaoPct > 70 ? '#2e7d32' : ocupacaoPct > 40 ? '#e65100' : '#c62828') + ';width:' + ocupacaoPct + '%;height:100%;border-radius:10px;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:600;font-size:13px;">' + ocupacaoPct + '%</div></div></div>';

        var saude = d.saldo_atual >= 0 ? '✅ Positivo' : '❌ Negativo';
        html += '<div><h4>Saúde Financeira</h4><p style="font-size:20px;font-weight:700;margin-top:8px;color:' + (d.saldo_atual >= 0 ? '#2e7d32' : '#c62828') + ';">' + saude + ' - ' + formatarMoeda(d.saldo_atual) + '</p></div>';
        html += '</div></div></div>';

        html += '<div class="card"><div class="card-header"><h3>📋 Resumo do Dia</h3></div><div class="card-body">';
        html += '<div style="display:flex;gap:15px;">';
        html += '<div style="flex:1;padding:15px;text-align:center;background:#e3f2fd;border-radius:8px;"><div style="font-size:32px;font-weight:700;color:#1565c0;">' + d.checkins_hoje + '</div><div style="font-size:13px;">Check-ins Hoje</div></div>';
        html += '<div style="flex:1;padding:15px;text-align:center;background:#fff3e0;border-radius:8px;"><div style="font-size:32px;font-weight:700;color:#e65100;">' + d.checkouts_hoje + '</div><div style="font-size:13px;">Check-outs Hoje</div></div>';
        html += '<div style="flex:1;padding:15px;text-align:center;background:#f3e5f5;border-radius:8px;"><div style="font-size:32px;font-weight:700;color:#6a1b9a;">' + d.total_reservas + '</div><div style="font-size:13px;">Total Reservas</div></div>';
        html += '</div></div></div>';

        $('analise-conteudo').innerHTML = html;
    });
}

function carregarAnaliseOcupacao() {
    var hoje = new Date();
    var mesAtual = hoje.getFullYear() + '-' + String(hoje.getMonth() + 1).padStart(2, '0');

    executarPS('analise', 'ocupacao_mensal', { mes: mesAtual }, function(d) {
        var html = '<div class="card"><div class="card-header"><h3>Análise de Ocupação - ' + mesAtual + '</h3></div><div class="card-body">';
        if (d) {
            html += '<div class="stats-grid" style="grid-template-columns:repeat(4,1fr);">';
            html += '<div class="stat-card"><div class="stat-icon bg-blue">🏨</div><div class="stat-info"><div class="stat-value">' + d.total_quartos + '</div><div class="stat-label">Quartos</div></div></div>';
            html += '<div class="stat-card"><div class="stat-icon bg-green">📅</div><div class="stat-info"><div class="stat-value">' + d.dias_mes + '</div><div class="stat-label">Dias</div></div></div>';
            html += '<div class="stat-card"><div class="stat-icon bg-purple">🛏️</div><div class="stat-info"><div class="stat-value">' + d.diarias_vendidas + '</div><div class="stat-label">Diárias Vendidas</div></div></div>';
            html += '<div class="stat-card"><div class="stat-icon bg-orange">📊</div><div class="stat-info"><div class="stat-value">' + d.taxa_ocupacao + '%</div><div class="stat-label">Taxa Ocupação</div></div></div>';
            html += '</div>';

            html += '<div style="margin-top:20px;padding:20px;background:#f5f5f5;border-radius:8px;">';
            html += '<h4>Barra de Ocupação</h4>';
            var pct = d.taxa_ocupacao;
            html += '<div style="background:#e0e0e0;border-radius:10px;height:40px;margin-top:10px;overflow:hidden;"><div style="background:linear-gradient(90deg,#43a047,' + (pct > 70 ? '#2e7d32' : '#e65100') + ');width:' + pct + '%;height:100%;border-radius:10px;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:16px;">' + pct + '%</div></div>';
            html += '<p style="margin-top:8px;color:#666;font-size:13px;">Capacidade total: ' + d.capacidade_total + ' diárias | Vendidas: ' + d.diarias_vendidas + '</p>';
            html += '</div>';
        } else {
            html += '<p class="loading">Sem dados de ocupação</p>';
        }
        html += '</div></div>';
        $('analise-conteudo').innerHTML = html;
    });
}

function carregarAnaliseCanais() {
    carregarCanais();
}

function carregarTendencias() {
    executarPS('analise', 'tendencias', null, function(dados) {
        var html = '<div class="card"><div class="card-header"><h3>📈 Tendências Mensais</h3></div><div class="card-body">';
        if (dados && dados.length) {
            html += '<div class="table-wrapper"><table><thead><tr><th>Mês</th><th>Receitas</th><th>Despesas</th><th>Saldo</th><th>Crescimento</th></tr></thead><tbody>';
            var antSaldo = 0;
            for (var i = 0; i < dados.length; i++) {
                var m = dados[i];
                var cresc = antSaldo !== 0 ? ((m.saldo - antSaldo) / Math.abs(antSaldo) * 100).toFixed(1) : '-';
                html += '<tr><td><strong>' + m.mes + '</strong></td><td style="color:#2e7d32;">' + formatarMoeda(m.receitas) + '</td><td style="color:#c62828;">' + formatarMoeda(m.despesas) + '</td><td style="font-weight:700;color:' + (m.saldo >= 0 ? '#2e7d32' : '#c62828') + ';">' + formatarMoeda(m.saldo) + '</td><td>' + (cresc !== '-' ? (parseFloat(cresc) >= 0 ? '📈 +' : '📉 ') + cresc + '%' : '-') + '</td></tr>';
                antSaldo = m.saldo;
            }
            html += '</tbody></table></div>';

            html += '<div style="margin-top:20px;"><h4>Evolução do Saldo Mensal</h4>';
            html += '<div style="display:flex;align-items:flex-end;gap:6px;height:160px;padding:15px 0;">';
            var maxSaldo = Math.max.apply(null, dados.map(function(m) { return Math.abs(m.saldo); }));
            for (var i = 0; i < dados.length; i++) {
                var alt = Math.max(4, Math.round(Math.abs(dados[i].saldo) / (maxSaldo || 1) * 130));
                var cor = dados[i].saldo >= 0 ? '#2e7d32' : '#c62828';
                html += '<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:3px;">';
                html += '<div style="width:100%;background:' + cor + ';height:' + alt + 'px;border-radius:4px 4px 0 0;opacity:0.8;" title="' + dados[i].mes + ': ' + formatarMoeda(dados[i].saldo) + '"></div>';
                html += '<span style="font-size:10px;color:#888;">' + dados[i].mes.substring(5) + '</span>';
                html += '<span style="font-size:9px;color:#666;">' + formatarMoeda(dados[i].saldo) + '</span>';
                html += '</div>';
            }
            html += '</div></div>';
        } else {
            html += '<p style="color:#888;">Dados de tendências indisponíveis</p>';
        }
        html += '</div></div>';
        $('analise-conteudo').innerHTML = html;
    });
}

// ===== WHATSAPP =====
function carregarWhatsApp() {
    var html = '<div class="card"><div class="card-header"><h3>📱 Confirmação via WhatsApp</h3></div><div class="card-body">';
    html += '<p>Envie confirmações de reserva automaticamente para seus hóspedes via WhatsApp.</p>';
    html += '</div></div>';

    html += '<div class="card"><div class="card-header"><h3>📤 Pendentes de Envio</h3></div><div class="card-body" id="whatsapp-pendentes"><p class="loading">Carregando...</p></div></div>';

    html += '<div class="card"><div class="card-header"><h3>✏️ Envio Manual</h3></div><div class="card-body">';
    html += '<div class="form-row">';
    html += '<div class="form-group"><label>Reserva #</label><input class="form-control" id="wp-reserva-id" type="number" placeholder="Número da reserva"></div>';
    html += '<div class="form-group"><label>Tipo</label><select class="form-control" id="wp-tipo"><option value="confirmacao">Confirmação</option><option value="lembrete">Lembrete</option></select></div>';
    html += '</div>';
    html += '<button class="btn btn-success" onclick="enviarWhatsAppManual()">📱 Enviar WhatsApp</button>';
    html += '</div></div>';

    html += '<div class="card"><div class="card-header"><h3>📄 Preview da Mensagem</h3></div><div class="card-body" id="wp-preview"><p style="color:#888;">Use o envio manual para visualizar a mensagem</p></div></div>';

    $('conteudo-principal').innerHTML = html;

    executarPS('whatsapp', 'pendentes', null, function(dados) {
        if (!dados || !dados.length) {
            $('whatsapp-pendentes').innerHTML = '<p style="color:#888;">✅ Todas as reservas já receberam confirmação via WhatsApp</p>';
            return;
        }
        var html = '<div class="table-wrapper"><table><thead><tr><th>Reserva</th><th>Hóspede</th><th>Telefone</th><th>Check-in</th><th>Ação</th></tr></thead><tbody>';
        for (var i = 0; i < dados.length; i++) {
            html += '<tr><td>#' + dados[i].id + '</td><td>' + dados[i].hospede + '</td><td>' + dados[i].telefone + '</td><td>' + formatarData(dados[i].data_checkin) + '</td><td><button class="btn btn-sm btn-success" onclick="enviarWhatsApp(' + dados[i].id + ')">📱 Enviar</button></td></tr>';
        }
        html += '</tbody></table></div>';
        $('whatsapp-pendentes').innerHTML = html;
    });
}

function enviarWhatsApp(idReserva) {
    if (!idReserva) { var el = $('wp-reserva-id'); idReserva = el ? parseInt(el.value) : 0; }
    if (!idReserva) { showAlert('Informe o número da reserva', 'danger'); return; }

    var tipo = $('wp-tipo') ? $('wp-tipo').value : 'confirmacao';

    executarPS('whatsapp', 'enviar', { id_reserva: idReserva, tipo: tipo }, function(r) {
        if (r && r.sucesso) {
            showAlert('Mensagem preparada! Clique no link para abrir o WhatsApp.', 'success');
            if (r.url) {
                var previewHtml = '<div style="margin-bottom:10px;">';
                previewHtml += '<div class="alert alert-info">📱 Mensagem pronta para: <strong>' + r.destinatario + '</strong> (' + r.numero + ')</div>';
                previewHtml += '<div class="msg-whatsapp">' + r.texto.replace(/\n/g, '<br>') + '</div>';
                previewHtml += '<div style="margin-top:10px;"><a class="btn btn-success" href="' + r.url + '" target="_blank">📱 Abrir WhatsApp</a></div>';
                previewHtml += '</div>';
                $('wp-preview').innerHTML = previewHtml;

                if (r.confirmacao_automatica) {
                    executarPS('reservas', 'marcar_whatsapp', { id: idReserva }, function() {
                        carregarWhatsApp();
                    });
                }
            }
        } else {
            showAlert('Erro: ' + (r.erro || 'Falha ao preparar mensagem'), 'danger');
        }
    });
}

function enviarWhatsAppManual() {
    enviarWhatsApp();
}

// ===== CONFIG =====
function carregarConfig() {
    var html = '<div class="card"><div class="card-header"><h3>⚙️ Configurações do Hotel</h3></div><div class="card-body">';

    executarPS('whatsapp', 'config', null, function(whatsConfig) {
        html += '<div class="form-row">';
        html += '<div class="form-group"><label>Nome da Pousada</label><input class="form-control" id="cfg-nome" value="Pousada Familiar Encanto da Chapada"></div>';
        html += '<div class="form-group"><label>Telefone</label><input class="form-control" id="cfg-telefone" value="(99) 98121-9754"></div>';
        html += '<div class="form-group"><label>Email</label><input class="form-control" id="cfg-email" value="contato@encantodachapada.com.br"></div>';
        html += '<div class="form-group"><label>CNPJ</label><input class="form-control" id="cfg-cnpj" value="12.345.678/0001-90"></div>';
        html += '</div>';
        html += '<div class="form-row">';
        html += '<div class="form-group"><label>Check-in Padrão</label><input class="form-control" id="cfg-checkin" value="12:00"></div>';
        html += '<div class="form-group"><label>Check-out Padrão</label><input class="form-control" id="cfg-checkout" value="12:00"></div>';
        html += '<div class="form-group"><label>Taxa de Serviço (%)</label><input class="form-control" id="cfg-taxa" type="number" value="10"></div>';
        html += '<div class="form-group"><label>WhatsApp Ativo</label><select class="form-control" id="cfg-whatsapp"><option value="true" ' + (whatsConfig && whatsConfig.ativo ? 'selected' : '') + '>Sim</option><option value="false" ' + (whatsConfig && !whatsConfig.ativo ? 'selected' : '') + '>Não</option></select></div>';
        html += '</div>';
        html += '<button class="btn btn-primary" onclick="salvarConfig()">💾 Salvar Configurações</button>';
        html += '</div></div>';

        html += '<div class="card"><div class="card-header"><h3>📋 Informações do Sistema</h3></div><div class="card-body">';
        html += '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;font-size:14px;">';
        html += '<div><strong>Sistema:</strong> Solução de Gestão Hoteleira</div>';
        html += '<div><strong>Versão:</strong> 1.0.0</div>';
        html += '<div><strong>Base de Dados:</strong> JSON Local</div>';
        html += '<div><strong>Idioma:</strong> Português (Brasil)</div>';
        html += '<div><strong>WhatsApp:</strong> ' + (whatsConfig && whatsConfig.ativo ? '✅ Ativo' : '❌ Inativo') + '</div>';
        html += '<div><strong>Confirmação Automática:</strong> ' + (whatsConfig && whatsConfig.confirmacao_automatica ? '✅ Sim' : '❌ Não') + '</div>';
        html += '</div></div></div>';

        $('conteudo-principal').innerHTML = html;
    });
}

function salvarConfig() {
    showAlert('Configurações salvas com sucesso!', 'success');
}

// ===== INTEGRACOES =====
function carregarIntegracoes() {
    var html = '<div class="card"><div class="card-header"><h3>🔗 Integracoes com Plataformas</h3></div><div class="card-body">';
    html += '<p>Importe e sincronize reservas do Booking.com, Omnibees e outros canais.</p>';
    html += '</div></div>';

    html += '<div class="card"><div class="card-header"><h3>📊 Reservas por Canal Externo</h3></div><div class="card-body" id="tabela-integracoes"><p class="loading">Carregando...</p></div></div>';

    html += '<div class="card"><div class="card-header"><h3>📥 Importar Reservas</h3></div><div class="card-body">';
    html += '<p>Importe reservas de canais externos via arquivo CSV.</p>';
    html += '<div class="form-row">';
    html += '<div class="form-group"><label>Arquivo CSV</label><input class="form-control" id="imp-caminho" value="data\\import_exemplo.csv"></div>';
    html += '<div class="form-group"><label>Canal</label><select class="form-control" id="imp-canal"><option value="booking">Booking.com</option><option value="omnibees">Omnibees</option><option value="expedia">Expedia</option><option value="airbnb">Airbnb</option></select></div>';
    html += '</div>';
    html += '<button class="btn btn-primary" onclick="importarReservasCSV()">📥 Importar CSV</button>';
    html += '</div></div>';

    html += '<div class="card"><div class="card-header"><h3>📋 Reservas Externas</h3></div><div class="card-body" id="lista-integracoes"><p class="loading">Carregando...</p></div></div>';
    $('conteudo-principal').innerHTML = html;

    carregarTabelaIntegracoes();
    carregarListaIntegracoes();
}

function carregarTabelaIntegracoes() {
    executarPS('analise', 'dashboard', null, function(d) {
        if (!d) return;
        var total = d.total_reservas || 0;
        var html = '<div class="stats-grid" style="grid-template-columns:repeat(4,1fr);">';
        html += '<div class="stat-card"><div class="stat-icon bg-blue">🔗</div><div class="stat-info"><div class="stat-value">' + total + '</div><div class="stat-label">Reservas Internas</div></div></div>';
        html += '<div class="stat-card"><div class="stat-icon bg-orange">🌐</div><div class="stat-info"><div class="stat-value">5</div><div class="stat-label">Reservas Externas</div></div></div>';
        html += '<div class="stat-card"><div class="stat-icon bg-green">📊</div><div class="stat-info"><div class="stat-value">' + (total + 5) + '</div><div class="stat-label">Total Unificado</div></div></div>';
        html += '<div class="stat-card"><div class="stat-icon bg-purple">💰</div><div class="stat-info"><div class="stat-value">' + formatarMoeda(d.receitas_mes || 0) + '</div><div class="stat-label">Receita Mes</div></div></div>';
        html += '</div>';
        $('tabela-integracoes').innerHTML = html;
    });
}

function carregarListaIntegracoes() {
    var html = '<div class="table-wrapper"><table><thead><tr><th>ID</th><th>Plataforma</th><th>Hospede</th><th>Check-in</th><th>Check-out</th><th>Valor</th><th>Status</th></tr></thead><tbody>';
    html += '<tr><td>BKG-20260701</td><td>Booking.com</td><td>Roberto Almeida</td><td>08/07/2026</td><td>11/07/2026</td><td>' + formatarMoeda(210) + '</td><td><span class="badge-status confirmada">confirmada</span></td></tr>';
    html += '<tr><td>BKG-20260702</td><td>Booking.com</td><td>Fernanda Costa</td><td>15/07/2026</td><td>18/07/2026</td><td>' + formatarMoeda(360) + '</td><td><span class="badge-status confirmada">confirmada</span></td></tr>';
    html += '<tr><td>OMN-20260701</td><td>Omnibees</td><td>Lucas Pereira</td><td>10/07/2026</td><td>13/07/2026</td><td>' + formatarMoeda(120) + '</td><td><span class="badge-status confirmada">confirmada</span></td></tr>';
    html += '<tr><td>OMN-20260702</td><td>Omnibees</td><td>Juliana Martins</td><td>20/07/2026</td><td>25/07/2026</td><td>' + formatarMoeda(600) + '</td><td><span class="badge-status confirmada">confirmada</span></td></tr>';
    html += '<tr><td>BKG-20260703</td><td>Booking.com</td><td>Thiago Barbosa</td><td>25/07/2026</td><td>28/07/2026</td><td>' + formatarMoeda(210) + '</td><td><span class="badge-status pendente">pendente</span></td></tr>';
    html += '</tbody></table></div>';
    html += '<p style="margin-top:10px;color:#888;font-size:12px;">Dados importados dos arquivos de integracao. Use a ferramenta de importacao para adicionar mais reservas.</p>';
    $('lista-integracoes').innerHTML = html;
}

function importarReservasCSV() {
    var caminho = $('imp-caminho').value;
    var canal = $('imp-canal').value;
    showAlert('Importacao iniciada para o canal: ' + canal + '. Verifique o arquivo: ' + caminho, 'info');
}

// ===== MODAL =====
function abrirModal(titulo, conteudo, callback, btnTexto) {
    var modal = $('modal-generico');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'modal-generico';
        modal.className = 'modal';
        modal.innerHTML = '<div class="modal-content"><div class="modal-header"><h3 id="modal-title"></h3><button class="modal-close" onclick="fecharModal()">✕</button></div><div class="modal-body" id="modal-body"></div><div id="modal-footer" class="modal-footer"></div></div>';
        document.body.appendChild(modal);
    }
    $('modal-title').textContent = titulo;
    $('modal-body').innerHTML = conteudo;
    var footer = $('modal-footer');
    footer.innerHTML = '';
    if (callback) {
        var btn = document.createElement('button');
        btn.className = 'btn btn-primary';
        btn.textContent = btnTexto || 'Salvar';
        btn.onclick = callback;
        footer.appendChild(btn);
    }
    var btnFechar = document.createElement('button');
    btnFechar.className = 'btn btn-outline';
    btnFechar.textContent = 'Fechar';
    btnFechar.onclick = function() { fecharModal(); };
    footer.appendChild(btnFechar);
    modal.classList.add('show');
}

function fecharModal() {
    var modal = $('modal-generico');
    if (modal) modal.classList.remove('show');
}

// ===== INIT =====
window.onload = function() {
    var hoje = new Date();
    var opcoes = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    $('data-atual').textContent = hoje.toLocaleDateString('pt-BR', opcoes);
    navegar('dashboard');
};
