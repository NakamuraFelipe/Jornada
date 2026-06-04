import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'service/dashboard_service.dart';
import 'models/dashboard_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Controle da visualização dinâmica
enum Visualizacao { cancelamentos, ranking, desempenho, alertas }

Visualizacao _visualizacaoSelecionada = Visualizacao.cancelamentos;

class DashPage extends StatefulWidget {
  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  // Filtros
  String filtroGrafico = 'Linha';
  String filtroPeriodo = 'Mes';
  String filtroLeadSituacao = 'Todos';
  String filtroEstado = 'Todos';
  String filtroCidade = 'Todas';
  String filtroBairro = 'Todos';
  String filtroCategoria = 'Todas';
  List<int> idsConsultoresSelecionados = [];
  String filtroGroupBy = 'bairro';
  DateTime? dataInicio;
  DateTime? dataFim;

  // Dados
  Map<String, dynamic> metricas = {};
  List<double> dadosGrafico = [];
  List<String> labelsGrafico = [];
  List<Map<String, dynamic>> consultoresTop = [];
  List<Alerta> alertas = [];
  Map<String, dynamic> meta = {};
  List<Map<String, dynamic>> cancelamentos = [];
  List<Map<String, dynamic>> rankingVendas = [];
  List<Map<String, dynamic>> desempenhoConsultores = [];
  List<Map<String, dynamic>> listaConsultores = [];

  // Opções de filtros
  List<String> estados = ['Todos'];
  List<dynamic> cidades = [];
  List<dynamic> bairros = [];
  List<String> categorias = ['Todas'];

  // Estados de loading
  bool isLoading = true;
  bool isLoadingGrafico = true;
  bool isLoadingConsultores = true;
  bool isLoadingAlertas = true;
  bool isLoadingCancelamentos = false;
  bool isLoadingRanking = false;
  bool isLoadingDesempenho = false;

  int? idUsuarioLogado;
  String? token;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    await _carregarUsuarioEToken();
  }

  Future<void> _carregarUsuarioEToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      idUsuarioLogado = prefs.getInt('id_usuario');

      if (token == null || token!.isEmpty) {
        _mostrarErro('Usuário não logado. Faça login novamente.');
        if (mounted) setState(() => isLoading = false);
        return;
      }

      // Se ID não estiver salvo, extrai do token
      if (idUsuarioLogado == null && token != null) {
        try {
          final parts = token!.split('.');
          if (parts.length >= 2) {
            String payloadBase64 = parts[1];
            while (payloadBase64.length % 4 != 0) payloadBase64 += '=';
            payloadBase64 = payloadBase64
                .replaceAll('-', '+')
                .replaceAll('_', '/');
            final bytes = base64.decode(payloadBase64);
            final payload = json.decode(utf8.decode(bytes));
            idUsuarioLogado = payload['id_usuario'] as int?;
            if (idUsuarioLogado != null) {
              await prefs.setInt('id_usuario', idUsuarioLogado!);
            }
          }
        } catch (e) {
          print('Erro ao extrair ID do token: $e');
        }
      }

      await Future.wait([
        _carregarMetricas(),
        _carregarGrafico(),
        _carregarTopConsultores(),
        _carregarAlertas(),
        _carregarOpcoesFiltros(),
        _carregarListaConsultores(),
      ]);

      // Pré-carrega a visualização inicial
      await _carregarCancelamentos();

      if (mounted) setState(() => isLoading = false);
    } catch (e) {
      print('Erro ao carregar dados: $e');
      _mostrarErro('Erro ao carregar dados');
      if (mounted) setState(() => isLoading = false);
    }
  }

Future<void> _carregarMetricas() async {
  print('🟢 Carregando métricas...');
  if (token == null) return;

  // Define a lista de IDs que será enviada
  final ids = idsConsultoresSelecionados.isNotEmpty
      ? idsConsultoresSelecionados
      : [idUsuarioLogado!];

  try {
    metricas = await DashboardService.getMetricas(
      token: token!,
      idsUsuario: ids,        // ← lista completa
      estado: filtroEstado != 'Todos' ? filtroEstado : null,
      cidade: filtroCidade != 'Todas' ? filtroCidade : null,
      bairro: filtroBairro != 'Todos' ? filtroBairro : null,
      categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
      dataInicio: dataInicio != null ? DateFormat('yyyy-MM-dd').format(dataInicio!) : null,
      dataFim: dataFim != null ? DateFormat('yyyy-MM-dd').format(dataFim!) : null,
    );
  } catch (e) {
    print('Erro métricas: $e');
    metricas = _getMetricasPadrao();
  }
}

Future<void> _carregarGrafico() async {
  if (!mounted) return;
  setState(() => isLoadingGrafico = true);
  
  if (token == null) return;
  
  final ids = idsConsultoresSelecionados.isNotEmpty
      ? idsConsultoresSelecionados
      : [idUsuarioLogado!];

  try {
    final resultado = await DashboardService.getEvolucao(
      token: token!,
      periodo: filtroPeriodo,
      situacao: filtroLeadSituacao,
      idsUsuario: ids,          // ← lista completa
      estado: filtroEstado != 'Todos' ? filtroEstado : null,
      cidade: filtroCidade != 'Todas' ? filtroCidade : null,
      categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
      dataInicio: dataInicio != null ? DateFormat('yyyy-MM-dd').format(dataInicio!) : null,
      dataFim: dataFim != null ? DateFormat('yyyy-MM-dd').format(dataFim!) : null,
    );
    if (mounted) {
      setState(() {
        dadosGrafico = resultado['dados'];
        labelsGrafico = resultado['labels'];
      });
    }
  } catch (e) {
    print('Erro gráfico: $e');
  } finally {
    if (mounted) setState(() => isLoadingGrafico = false);
  }
}

  Future<void> _carregarTopConsultores() async {
    try {
      consultoresTop = await DashboardService.getTopConsultores(token: token!);
    } catch (e) {
      print('Erro top consultores: $e');
      consultoresTop = [];
    } finally {
      if (mounted) setState(() => isLoadingConsultores = false);
    }
  }

  Future<void> _carregarAlertas() async {
    setState(() => isLoadingAlertas = true);
    try {
      final resultado = await DashboardService.getAlertas(
        token: token!,
        idsUsuario: [idUsuarioLogado!],
      );
      if (mounted) {
        setState(() {
          alertas = (resultado['alertas'] as List)
              .map((a) => Alerta.fromJson(a))
              .toList();
          meta = resultado['meta'] ?? {};
        });
      }
    } catch (e) {
      print('Erro alertas: $e');
    } finally {
      if (mounted) setState(() => isLoadingAlertas = false);
    }
  }

  Future<void> _carregarCancelamentos() async {
    setState(() => isLoadingCancelamentos = true);
    try {
      cancelamentos = await DashboardService.getCancelamentos(
        token: token!,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        bairro: filtroBairro != 'Todos' ? filtroBairro : null,
        groupBy: filtroGroupBy,
        dataInicio: dataInicio != null
            ? DateFormat('yyyy-MM-dd').format(dataInicio!)
            : null,
        dataFim: dataFim != null
            ? DateFormat('yyyy-MM-dd').format(dataFim!)
            : null,
      );
    } catch (e) {
      print('Erro cancelamentos: $e');
      cancelamentos = [];
    } finally {
      if (mounted) setState(() => isLoadingCancelamentos = false);
    }
  }

  Future<void> _carregarRankingVendas() async {
    setState(() => isLoadingRanking = true);
    try {
      rankingVendas = await DashboardService.getRankingVendas(
        token: token!,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        bairro: filtroBairro != 'Todos' ? filtroBairro : null,
        categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
        dataInicio: dataInicio != null
            ? DateFormat('yyyy-MM-dd').format(dataInicio!)
            : null,
        dataFim: dataFim != null
            ? DateFormat('yyyy-MM-dd').format(dataFim!)
            : null,
      );
    } catch (e) {
      print('Erro ranking: $e');
      rankingVendas = [];
    } finally {
      if (mounted) setState(() => isLoadingRanking = false);
    }
  }

  Future<void> _carregarDesempenhoConsultores() async {
    if (idsConsultoresSelecionados.isEmpty) return;
    setState(() => isLoadingDesempenho = true);
    try {
      desempenhoConsultores = await DashboardService.getDesempenhoConsultores(
        token: token!,
        idsUsuario: idsConsultoresSelecionados,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        bairro: filtroBairro != 'Todos' ? filtroBairro : null,
        dataInicio: dataInicio != null
            ? DateFormat('yyyy-MM-dd').format(dataInicio!)
            : null,
        dataFim: dataFim != null
            ? DateFormat('yyyy-MM-dd').format(dataFim!)
            : null,
      );
    } catch (e) {
      print('Erro desempenho: $e');
      desempenhoConsultores = [];
    } finally {
      if (mounted) setState(() => isLoadingDesempenho = false);
    }
  }

  Future<void> _carregarOpcoesFiltros() async {
    try {
      final resultado = await DashboardService.getOpcoesFiltros(token: token!);
      if (mounted) {
        setState(() {
          estados = List<String>.from(resultado['estados']);
          cidades = resultado['cidades'];
          bairros = resultado['bairros'];
          categorias = List<String>.from(resultado['categorias']);
        });
      }
    } catch (e) {
      print('Erro filtros: $e');
    }
  }

  Future<void> _carregarListaConsultores() async {
    try {
      listaConsultores = await DashboardService.getListaConsultores(
        token: token!,
      );
    } catch (e) {
      print('Erro lista consultores: $e');
      listaConsultores = [];
    }
  }

  void _aplicarFiltros() {
    setState(() {
      _carregarMetricas();
      _carregarGrafico();
      _carregarAlertas();
      if (_visualizacaoSelecionada == Visualizacao.cancelamentos)
        _carregarCancelamentos();
      if (_visualizacaoSelecionada == Visualizacao.ranking)
        _carregarRankingVendas();
      if (_visualizacaoSelecionada == Visualizacao.desempenho)
        _carregarDesempenhoConsultores();
    });
  }

  List<String> getCidadesPorEstado() {
    if (filtroEstado == 'Todos') return ['Todas'];
    final cidadesDoEstado = cidades
        .where((c) => c['nome_estado'] == filtroEstado)
        .map((c) => c['nome_cidade'] as String)
        .toSet()
        .toList();
    cidadesDoEstado.sort();
    return ['Todas', ...cidadesDoEstado];
  }

  List<String> getBairrosPorCidade() {
    if (filtroCidade == 'Todas') return ['Todos'];
    final bairrosDaCidade = bairros
        .where((b) => b['nome_cidade'] == filtroCidade)
        .map((b) => b['nome_bairro'] as String)
        .toSet()
        .toList();
    bairrosDaCidade.sort();
    return ['Todos', ...bairrosDaCidade];
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  Map<String, dynamic> _getMetricasPadrao() {
    return {
      'fechado': 0,
      'abertos': 0,
      'conexao': 0,
      'negociacao': 0,
      'total': 0,
      'conversao': 0,
      'cobertura': 0,
      'variacao_fechados': 0,
      'leads_ano_atual': 0,
    };
  }

  double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _aplicarFiltros,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _abrirFiltros,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _aplicarFiltros(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildMetricasGrid(),
                    const SizedBox(height: 16),
                    _buildEvolucaoCard(),
                    const SizedBox(height: 16),
                    _buildVisualizacaoSelector(),
                    const SizedBox(height: 16),
                    _buildConteudoDinamico(),
                  ],
                ),
              ),
            ),
    );
  }

 Widget _buildMetricasGrid() {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.4,
    children: [
      _buildMetricaCard(
        title: 'Fechados',
        value: '${metricas['fechado'] ?? 0}',
        icon: Icons.check_circle,
        color: Colors.green,
        subtitle: 'leads convertidos',
      ),
      _buildMetricaCard(
        title: 'Abertos',
        value: '${metricas['abertos'] ?? 0}',
        icon: Icons.email_outlined,
        color: Colors.orange,
        subtitle: 'aguardando ação',
      ),
      _buildMetricaCard(
        title: 'Conexão',
        value: '${metricas['conexao'] ?? 0}',
        icon: Icons.people_outline,
        color: Colors.blue,
        subtitle: 'primeiro contato',
      ),
      _buildMetricaCard(
        title: 'Negociação',
        value: '${metricas['negociacao'] ?? 0}',
        icon: Icons.handshake_outlined,
        color: Colors.purple,
        subtitle: 'em negociação',
      ),
      _buildMetricaCard(
        title: 'Conversão',
        value: '${_toDouble(metricas['conversao']).toStringAsFixed(1)}%',
        icon: Icons.trending_up,
        color: Colors.teal,
        subtitle: 'taxa de sucesso',
      ),
      _buildMetricaCard(
        title: 'Total Leads',
        value: '${metricas['total'] ?? 0}',
        icon: Icons.people,
        color: Colors.redAccent,
        subtitle: 'cadastrados',
      ),
    ],
  );
}

Widget _buildMetricaCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required String subtitle,
}) {
  final isMulti = idsConsultoresSelecionados.length > 1;
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: _buildCardDecoration(),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha com ícone e valor lado a lado
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Título e opcional "(combinado)"
        Row(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            if (isMulti) ...[
              const SizedBox(width: 4),
              Text(
                '(combinado)',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    ),
  );
}

  Widget _buildEvolucaoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolução de Leads',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPeriodoLabel(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      filtroGrafico == 'Linha'
                          ? Icons.show_chart
                          : Icons.bar_chart,
                      size: 14,
                      color: const Color(0xFFE53935),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      filtroGrafico,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: isLoadingGrafico
                ? const Center(child: CircularProgressIndicator())
                : dadosGrafico.isEmpty
                ? const Center(child: Text('Sem dados para exibir'))
                : _buildGrafico(dadosGrafico, labelsGrafico),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizacaoSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSelectorItem(
            Visualizacao.cancelamentos,
            'Cancelamentos',
            Icons.cancel,
            'Vendas canceladas',
          ),
          _buildSelectorItem(
            Visualizacao.ranking,
            'Ranking Vendas',
            Icons.leaderboard,
            'Mais vendidos',
          ),
          _buildSelectorItem(
            Visualizacao.desempenho,
            'Desempenho',
            Icons.people,
            'Consultores',
          ),
          _buildSelectorItem(
            Visualizacao.alertas,
            'Ações',
            Icons.notifications_active,
            'Prioridades',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorItem(
    Visualizacao tipo,
    String label,
    IconData icon,
    String subtitulo,
  ) {
    final isSelected = _visualizacaoSelecionada == tipo;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _visualizacaoSelecionada = tipo;
            if (tipo == Visualizacao.cancelamentos) _carregarCancelamentos();
            if (tipo == Visualizacao.ranking) _carregarRankingVendas();
            if (tipo == Visualizacao.desempenho &&
                idsConsultoresSelecionados.isNotEmpty)
              _carregarDesempenhoConsultores();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE53935).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFFE53935) : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFFE53935)
                      : Colors.grey[800],
                ),
              ),
              Text(
                subtitulo,
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesempenhoResumo() {
    if (desempenhoConsultores.isEmpty) return const SizedBox.shrink();

    int totalLeads = 0;
    int totalVendas = 0;
    double totalTicket = 0;
    for (var item in desempenhoConsultores) {
      totalLeads += item['total_leads'] as int;
      totalVendas += item['total_vendas'] as int;
      totalTicket += item['ticket_medio'] as double;
    }
    double ticketMedio = totalTicket / desempenhoConsultores.length;
    double conversaoGeral = totalLeads > 0
        ? (totalVendas / totalLeads) * 100
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFE53935).withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResumoItem(
              'Total Leads',
              totalLeads,
              Icons.people,
              Colors.blue,
            ),
            _buildResumoItem(
              'Total Vendas',
              totalVendas,
              Icons.shopping_cart,
              Colors.green,
            ),
            _buildResumoItem(
              'Ticket Médio',
              'R\$ ${ticketMedio.toStringAsFixed(2)}',
              Icons.monetization_on,
              Colors.orange,
            ),
            _buildResumoItem(
              'Conversão',
              '${conversaoGeral.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoDinamico() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTituloLista(),
        if (_visualizacaoSelecionada == Visualizacao.desempenho &&
            idsConsultoresSelecionados.length > 1)
          _buildDesempenhoResumo(), // ← resumo combinado (só quando >1 consultor)
        _buildListaDinamica(),
      ],
    );
  }

  Widget _buildListaDinamica() {
    switch (_visualizacaoSelecionada) {
      case Visualizacao.cancelamentos:
        return _buildCancelamentosList();
      case Visualizacao.ranking:
        return _buildRankingVendasList();
      case Visualizacao.desempenho:
        return _buildDesempenhoList();
      case Visualizacao.alertas:
        return _buildAlertasList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCancelamentosList() {
    if (isLoadingCancelamentos)
      return const Center(child: CircularProgressIndicator());
    if (cancelamentos.isEmpty)
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nenhum cancelamento encontrado'),
        ),
      );
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cancelamentos.length,
      itemBuilder: (_, i) {
        final item = cancelamentos[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              item['localizacao'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Total: ${item['total_vendas']} | Canceladas: ${item['canceladas']}',
            ),
            trailing: Chip(
              label: Text('${item['taxa_cancelamento']}%'),
              backgroundColor: (item['taxa_cancelamento'] as double) > 30
                  ? Colors.red[100]
                  : Colors.green[100],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankingVendasList() {
    if (isLoadingRanking)
      return const Center(child: CircularProgressIndicator());
    if (rankingVendas.isEmpty)
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nenhuma venda encontrada'),
        ),
      );
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankingVendas.length,
      itemBuilder: (_, i) {
        final item = rankingVendas[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(item['bairro']),
            subtitle: Text('Categoria: ${item['categoria']}'),
            trailing: Chip(
              label: Text('${item['vendas']} vendas'),
              backgroundColor: Colors.green[100],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesempenhoList() {
    if (idsConsultoresSelecionados.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Selecione consultores no filtro'),
            ],
          ),
        ),
      );
    }
    if (isLoadingDesempenho)
      return const Center(child: CircularProgressIndicator());
    if (desempenhoConsultores.isEmpty)
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nenhum dado de desempenho'),
        ),
      );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Consultor')),
          DataColumn(label: Text('Leads')),
          DataColumn(label: Text('Vendas')),
          DataColumn(label: Text('Conversão')),
          DataColumn(label: Text('Visitas')),
          DataColumn(label: Text('Ticket Médio')),
        ],
        rows: desempenhoConsultores.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['nome'])),
              DataCell(Text(item['total_leads'].toString())),
              DataCell(Text(item['total_vendas'].toString())),
              DataCell(Text('${item['taxa_conversao']}%')),
              DataCell(Text(item['total_visitas'].toString())),
              DataCell(
                Text(
                  'R\$ ${(item['ticket_medio'] as double).toStringAsFixed(2)}',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlertasList() {
    if (isLoadingAlertas)
      return const Center(child: CircularProgressIndicator());
    if (alertas.isEmpty)
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Nenhum alerta no momento'),
        ),
      );
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alertas.length,
      itemBuilder: (_, i) {
        final alerta = alertas[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(alerta.getIconData(), color: alerta.getColor()),
            title: Text(alerta.mensagem),
            subtitle: Text('Tipo: ${alerta.tipo}'),
          ),
        );
      },
    );
  }

Widget _buildGrafico(List<double> dados, List<String> labels) {
  if (dados.isEmpty) return const Center(child: Text('Sem dados para exibir'));

  final maxY = dados.reduce((a, b) => a > b ? a : b);
  // Define um teto com 10% de folga, mas nunca abaixo de 1 se houver dados
  final yMax = maxY > 0 ? maxY + (maxY * 0.1) : 1.0;

  switch (filtroGrafico) {
    case 'Linha':
      return LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()],
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                reservedSize: 35,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: dados.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              color: const Color(0xFFE53935),
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE53935).withOpacity(0.1),
              ),
            ),
          ],
          minY: 0,
          maxY: yMax,
        ),
      );

    case 'Barra':
      return BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()],
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) =>
                    Text(value.toInt().toString(), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                reservedSize: 35,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: dados.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  color: const Color(0xFFE53935),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          minY: 0,
          maxY: yMax,
        ),
      );

    default:
      return const Center(child: Text('Selecione um tipo de gráfico'));
  }
}

  String _getPeriodoLabel() {
    switch (filtroPeriodo) {
      case 'Dia':
        return 'Últimos 7 dias';
      case 'Semana':
        return 'Últimas 4 semanas';
      case 'Ano':
        return 'Últimos 5 anos';
      default:
        return 'Mês atual';
    }
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ==================== FILTROS (mantido igual) ====================

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Filtros Avançados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildFiltroSecao(
                            titulo: '👥 CONSULTORES',
                            icone: Icons.people,
                            children: [
                              _buildMultiSelectConsultores(setModalState),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltroSecao(
                            titulo: '📍 LOCALIZAÇÃO',
                            icone: Icons.location_on,
                            children: [
                              _buildFiltroDropdown(
                                value: filtroEstado,
                                items: estados,
                                label: 'Estado',
                                onChanged: (value) => setModalState(() {
                                  filtroEstado = value;
                                  filtroCidade = 'Todas';
                                  filtroBairro = 'Todos';
                                }),
                              ),
                              const SizedBox(height: 8),
                              _buildFiltroDropdown(
                                value: filtroCidade,
                                items: getCidadesPorEstado(),
                                label: 'Cidade',
                                onChanged: (value) => setModalState(() {
                                  filtroCidade = value;
                                  filtroBairro = 'Todos';
                                }),
                              ),
                              const SizedBox(height: 8),
                              _buildFiltroDropdown(
                                value: filtroBairro,
                                items: getBairrosPorCidade(),
                                label: 'Bairro',
                                onChanged: (value) =>
                                    setModalState(() => filtroBairro = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltroSecao(
                            titulo: '📅 PERÍODO',
                            icone: Icons.calendar_today,
                            children: [_buildDateRangePicker(setModalState)],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltroSecao(
                            titulo: '📊 TIPO DE GRÁFICO',
                            icone: Icons.show_chart,
                            children: [
                              _buildFiltroOpcao(
                                value: filtroGrafico,
                                items: const ['Linha', 'Barra'],
                                icons: {
                                  'Linha': Icons.show_chart,
                                  'Barra': Icons.bar_chart,
                                },
                                onChanged: (value) =>
                                    setModalState(() => filtroGrafico = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltroSecao(
                            titulo: '📈 PERÍODO DO GRÁFICO',
                            icone: Icons.timeline,
                            children: [
                              _buildFiltroOpcao(
                                value: filtroPeriodo,
                                items: const ['Dia', 'Semana', 'Mes', 'Ano'],
                                icons: {
                                  'Dia': Icons.today,
                                  'Semana': Icons.date_range,
                                  'Mes': Icons.calendar_month,
                                  'Ano': Icons.timeline,
                                },
                                onChanged: (value) =>
                                    setModalState(() => filtroPeriodo = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltroSecao(
                            titulo: '🏷️ SITUAÇÃO DO LEAD',
                            icone: Icons.label,
                            children: [
                              _buildFiltroChip(
                                items: const [
                                  'Todos',
                                  'aberta',
                                  'conexao',
                                  'negociacao',
                                  'fechada',
                                ],
                                selectedValue: filtroLeadSituacao,
                                onChanged: (value) => setModalState(
                                  () => filtroLeadSituacao = value,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltroSecao(
                            titulo: '📂 CATEGORIA',
                            icone: Icons.category,
                            children: [
                              _buildFiltroChip(
                                items: categorias,
                                selectedValue: filtroCategoria,
                                onChanged: (value) => setModalState(
                                  () => filtroCategoria = value,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildFiltroSecao(
                            titulo: '🔍 AGRUPAR CANCELAMENTOS POR',
                            icone: Icons.group_work,
                            children: [
                              _buildFiltroOpcao(
                                value:
                                    filtroGroupBy[0].toUpperCase() +
                                    filtroGroupBy.substring(1),
                                items: const ['Bairro', 'Cidade', 'Estado'],
                                icons: {
                                  'Bairro': Icons.location_city,
                                  'Cidade': Icons.location_city,
                                  'Estado': Icons.map,
                                },
                                onChanged: (value) => setModalState(
                                  () => filtroGroupBy = value.toLowerCase(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              filtroEstado = 'Todos';
                              filtroCidade = 'Todas';
                              filtroBairro = 'Todos';
                              filtroGrafico = 'Linha';
                              filtroPeriodo = 'Mes';
                              filtroLeadSituacao = 'Todos';
                              filtroCategoria = 'Todas';
                              idsConsultoresSelecionados = [];
                              dataInicio = null;
                              dataFim = null;
                              filtroGroupBy = 'bairro';
                            });
                          },
                          child: const Text('Limpar Filtros'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _aplicarFiltros();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aplicar Filtros'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMultiSelectConsultores(Function(void Function()) setModalState) {
    if (listaConsultores.isEmpty)
      return const Center(child: CircularProgressIndicator());
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: listaConsultores.length,
        itemBuilder: (context, index) {
          final consultor = listaConsultores[index];
          final isSelected = idsConsultoresSelecionados.contains(
            consultor['id_usuario'],
          );
          return CheckboxListTile(
            title: Text(consultor['nome_usuario']),
            subtitle: Text(consultor['cargo']),
            value: isSelected,
            onChanged: (selected) {
              setModalState(() {
                if (selected == true) {
                  idsConsultoresSelecionados.add(consultor['id_usuario']);
                } else {
                  idsConsultoresSelecionados.remove(consultor['id_usuario']);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }

  Widget _buildDateRangePicker(Function(void Function()) setModalState) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: dataInicio ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) setModalState(() => dataInicio = date);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dataInicio != null
                      ? DateFormat('dd/MM/yyyy').format(dataInicio!)
                      : 'Data Início',
                  style: TextStyle(
                    color: dataInicio != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: dataFim ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) setModalState(() => dataFim = date);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dataFim != null
                      ? DateFormat('dd/MM/yyyy').format(dataFim!)
                      : 'Data Fim',
                  style: TextStyle(
                    color: dataFim != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
        if (dataInicio != null || dataFim != null)
          TextButton(
            onPressed: () => setModalState(() {
              dataInicio = null;
              dataFim = null;
            }),
            child: const Text('Limpar datas'),
          ),
      ],
    );
  }

  Widget _buildFiltroSecao({
    required String titulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildFiltroDropdown({
    required String value,
    required List<String> items,
    required String label,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(label),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) => onChanged(value!),
      ),
    );
  }

  Widget _buildFiltroChip({
    required List<String> items,
    required String selectedValue,
    required Function(String) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selectedValue;
        return FilterChip(
          label: Text(_formatarChipLabel(item)),
          selected: isSelected,
          onSelected: (_) => onChanged(item),
          backgroundColor: Colors.grey[100],
          selectedColor: const Color(0xFFE53935).withOpacity(0.2),
          checkmarkColor: const Color(0xFFE53935),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFFE53935) : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  String _formatarChipLabel(String label) {
    switch (label) {
      case 'aberta':
        return 'Aberta';
      case 'conexao':
        return 'Conexão';
      case 'negociacao':
        return 'Negociação';
      case 'fechada':
        return 'Fechada';
      default:
        return label;
    }
  }

  Widget _buildFiltroOpcao({
    required String value,
    required List<String> items,
    required Map<String, IconData> icons,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.map((item) {
          final isSelected = value == item;
          return InkWell(
            onTap: () => onChanged(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE53935).withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    icons[item],
                    size: 20,
                    color: isSelected
                        ? const Color(0xFFE53935)
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : Colors.grey[800],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: const Color(0xFFE53935),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResumoItem(
    String titulo,
    dynamic valor,
    IconData icone,
    Color cor,
  ) {
    return Column(
      children: [
        Icon(icone, color: cor, size: 24),
        const SizedBox(height: 8),
        Text(
          valor.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(titulo, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTituloLista() {
    String titulo = '';
    switch (_visualizacaoSelecionada) {
      case Visualizacao.cancelamentos:
        titulo = '📉 Cancelamentos por Localização';
        break;
      case Visualizacao.ranking:
        titulo = '🏆 Ranking de Vendas';
        break;
      case Visualizacao.desempenho:
        titulo = '📊 Desempenho dos Consultores';
        break;
      case Visualizacao.alertas:
        titulo = '⚠️ Ações Prioritárias';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE53935),
        ),
      ),
    );
  }

  Widget _buildRankingResumo() {
    if (rankingVendas.isEmpty) return const SizedBox.shrink();

    int totalVendas = 0;
    int totalItens = rankingVendas.length;
    Map<String, int> categoriasCount = {};

    for (var item in rankingVendas) {
      int vendas = item['vendas'] as int;
      totalVendas += vendas;
      String cat = item['categoria'] ?? 'Outros';
      categoriasCount[cat] = (categoriasCount[cat] ?? 0) + vendas;
    }

    // Encontra a categoria mais vendida
    String topCategoria = '';
    int topVendas = 0;
    categoriasCount.forEach((cat, vendas) {
      if (vendas > topVendas) {
        topVendas = vendas;
        topCategoria = cat;
      }
    });

    double mediaVendas = totalVendas / totalItens;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFE53935).withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResumoItem(
              'Total Vendas',
              totalVendas,
              Icons.shopping_cart,
              Colors.green,
            ),
            _buildResumoItem(
              'Média por Local',
              mediaVendas.toStringAsFixed(1),
              Icons.bar_chart,
              Colors.blue,
            ),
            _buildResumoItem(
              'Categoria Top',
              topCategoria,
              Icons.category,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
