import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'service/dashboard_service.dart';
import 'models/dashboard_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashPage extends StatefulWidget {
  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> with SingleTickerProviderStateMixin {
  // Filtros
  String filtroGrafico = 'Linha';
  String filtroPeriodo = 'Mes';
  String filtroLeadSituacao = 'Todos';
  String filtroEstado = 'Todos';
  String filtroCidade = 'Todas';
  String filtroBairro = 'Todos';
  String filtroCategoria = 'Todas';

  // Dados
  Map<String, dynamic> metricas = {};
  List<double> dadosGrafico = [];
  List<String> labelsGrafico = [];
  Map<String, int> leadsPorBairro = {};
  Map<String, double> conversaoPorBairro = {};
  List<Map<String, dynamic>> consultoresTop = [];
  List<Alerta> alertas = [];
  Map<String, dynamic> meta = {};

  // Opções de filtros
  List<String> estados = ['Todos'];
  List<dynamic> cidades = [];
  List<dynamic> bairros = [];
  List<String> categorias = ['Todas'];

  // Estados de loading
  bool isLoading = true;
  bool isLoadingGrafico = true;
  bool isLoadingBairros = true;
  bool isLoadingConsultores = true;
  bool isLoadingAlertas = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int? idUsuarioLogado;
  String? token;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
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
      
      if (token != null && token!.isNotEmpty) {
        await _carregarTodosDados();
        await _carregarOpcoesFiltros();
      } else {
        _mostrarErro('Usuário não logado. Faça login novamente.');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Erro ao carregar token: $e');
      _mostrarErro('Erro ao carregar dados do usuário');
      setState(() => isLoading = false);
    }
  }

  Future<void> _carregarTodosDados() async {
    setState(() => isLoading = true);
    
    await Future.wait([
      _carregarMetricas(),
      _carregarGrafico(),
      _carregarLeadsPorBairro(),
      _carregarTopConsultores(),
      _carregarAlertas(),
    ]);
    
    _animationController.forward();
    setState(() => isLoading = false);
  }

  Future<void> _carregarMetricas() async {
    print('Chamando getMetricas com token: $token');
    print('URL: ${DashboardService.baseUrl}/metricas');
    try {
      metricas = await DashboardService.getMetricas(
        token: token!,
        idUsuario: idUsuarioLogado,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        bairro: filtroBairro != 'Todos' ? filtroBairro : null,
        categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
      );
    } catch (e) {
      print('Erro ao carregar métricas: $e');
      metricas = _getMetricasPadrao();
    }
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

  Future<void> _carregarGrafico() async {
    setState(() => isLoadingGrafico = true);
    try {
      final resultado = await DashboardService.getEvolucao(
        token: token!,
        periodo: filtroPeriodo,
        situacao: filtroLeadSituacao,
        idUsuario: idUsuarioLogado,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
      );
      dadosGrafico = resultado['dados'];
      labelsGrafico = resultado['labels'];
    } catch (e) {
      print('Erro ao carregar gráfico: $e');
      dadosGrafico = [];
      labelsGrafico = [];
    } finally {
      setState(() => isLoadingGrafico = false);
    }
  }

  Future<void> _carregarLeadsPorBairro() async {
    setState(() => isLoadingBairros = true);
    try {
      final resultado = await DashboardService.getLeadsPorBairro(
        token: token!,
        idUsuario: idUsuarioLogado,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
      );
      leadsPorBairro = resultado['leads_por_bairro'] ?? {};
      conversaoPorBairro = resultado['conversao_por_bairro'] ?? {};
    } catch (e) {
      print('Erro ao carregar leads por bairro: $e');
      leadsPorBairro = {};
      conversaoPorBairro = {};
    } finally {
      setState(() => isLoadingBairros = false);
    }
  }

  Future<void> _carregarTopConsultores() async {
    setState(() => isLoadingConsultores = true);
    try {
      consultoresTop = await DashboardService.getTopConsultores(token: token!);
    } catch (e) {
      print('Erro ao carregar top consultores: $e');
      consultoresTop = [];
    } finally {
      setState(() => isLoadingConsultores = false);
    }
  }

  Future<void> _carregarAlertas() async {
    setState(() => isLoadingAlertas = true);
    try {
      final resultado = await DashboardService.getAlertas(
        token: token!,
        idUsuario: idUsuarioLogado,
      );
      alertas = (resultado['alertas'] as List)
          .map((a) => Alerta.fromJson(a))
          .toList();
      meta = resultado['meta'] ?? {};
    } catch (e) {
      print('Erro ao carregar alertas: $e');
      alertas = [];
      meta = {
        'atual': 0,
        'meta': 0,
        'progresso': 0,
        'dias_restantes': 0,
      };
    } finally {
      setState(() => isLoadingAlertas = false);
    }
  }

  Future<void> _carregarOpcoesFiltros() async {
    try {
      final resultado = await DashboardService.getOpcoesFiltros(token: token!);
      estados = List<String>.from(resultado['estados']);
      cidades = resultado['cidades'];
      bairros = resultado['bairros'];
      categorias = List<String>.from(resultado['categorias']);
    } catch (e) {
      print('Erro ao carregar opções de filtros: $e');
    }
  }

  List<String> getCidadesPorEstado() {
    if (filtroEstado == 'Todos') return ['Todas'];
    final cidadesDoEstado = cidades
        .where((c) => c['nome_estado'] == filtroEstado)
        .map((c) => c['nome_cidade'] as String)
        .toList();
    return ['Todas', ...cidadesDoEstado];
  }

  List<String> getBairrosPorCidade() {
    if (filtroCidade == 'Todas') return ['Todos'];
    final bairrosDaCidade = bairros
        .where((b) => b['nome_cidade'] == filtroCidade)
        .map((b) => b['nome_bairro'] as String)
        .toList();
    return ['Todos', ...bairrosDaCidade];
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  void _aplicarFiltros() {
    setState(() {
      _animationController.reset();
      _carregarTodosDados();
    });
  }

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
              height: MediaQuery.of(context).size.height * 0.8,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFiltroSecao(
                            titulo: '📍 LOCALIZAÇÃO',
                            icone: Icons.location_on,
                            children: [
                              _buildFiltroDropdown(
                                value: filtroEstado,
                                items: estados,
                                label: 'Estado',
                                onChanged: (value) {
                                  setModalState(() {
                                    filtroEstado = value;
                                    filtroCidade = 'Todas';
                                    filtroBairro = 'Todos';
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildFiltroDropdown(
                                value: filtroCidade,
                                items: getCidadesPorEstado(),
                                label: 'Cidade',
                                onChanged: (value) {
                                  setModalState(() {
                                    filtroCidade = value;
                                    filtroBairro = 'Todos';
                                  });
                                },
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
                            titulo: '📅 PERÍODO',
                            icone: Icons.calendar_today,
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
                                items: const ['Todos', 'aberta', 'conexao', 'negociacao', 'fechada'],
                                selectedValue: filtroLeadSituacao,
                                onChanged: (value) =>
                                    setModalState(() => filtroLeadSituacao = value),
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
                                onChanged: (value) =>
                                    setModalState(() => filtroCategoria = value),
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
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Aplicar Filtros'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
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
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
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
      case 'aberta': return 'Aberta';
      case 'conexao': return 'Conexão';
      case 'negociacao': return 'Negociação';
      case 'fechada': return 'Fechada';
      default: return label;
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
                color: isSelected ? const Color(0xFFE53935).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icons[item], size: 20,
                      color: isSelected ? const Color(0xFFE53935) : Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? const Color(0xFFE53935) : Colors.grey[800],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 18, color: const Color(0xFFE53935)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE53935),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _aplicarFiltros(),
          tooltip: 'Atualizar',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Notificações',
        ),
      ],
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async => _aplicarFiltros(),
            child: CustomScrollView(
              slivers: [
                // Cards de métricas
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildListDelegate([
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
                        title: 'Conversão',
                        value: '${_toDouble(metricas['conversao']).toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                        subtitle: 'taxa de sucesso',
                      ),
                      _buildMetricaCard(
                        title: 'Total Leads',
                        value: '${metricas['total'] ?? 0}',
                        icon: Icons.people,
                        color: Colors.purple,
                        subtitle: 'cadastrados',
                      ),
                    ]),
                  ),
                ),

                // Gráfico de evolução
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(16),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      filtroGrafico == 'Linha' ? Icons.show_chart : Icons.bar_chart,
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
                    ),
                  ),
                ),

                // Leads por localização
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: _buildCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Leads por Localização',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isLoadingBairros)
                          const Center(child: CircularProgressIndicator())
                        else if (leadsPorBairro.isEmpty)
                          const Center(child: Text('Nenhum dado disponível'))
                        else
                          ...leadsPorBairro.entries.take(5).map((entry) {
                            final conversao = conversaoPorBairro[entry.key] ?? 0;
                            final maxValor = leadsPorBairro.values.reduce((a, b) => a > b ? a : b);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: LinearProgressIndicator(
                                                    value: entry.value / maxValor,
                                                    backgroundColor: Colors.grey[200],
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      conversao > 0.4 ? Colors.green : Colors.blue,
                                                    ),
                                                    minHeight: 8,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  width: 35,
                                                  child: Text(
                                                    '${entry.value}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '${(conversao * 100).toStringAsFixed(0)}% conversão',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),

                // Top Consultores e Alertas
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildTopConsultoresCard(),
                      _buildAlertasCard(),
                    ]),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _abrirFiltros,
      backgroundColor: const Color(0xFFE53935),
      icon: const Icon(Icons.filter_list),
      label: const Text('Filtrar'),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  );
}
  Widget _buildMetricaCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _buildCardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildTopConsultoresCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[700], size: 16),
              const SizedBox(width: 4),
              Text(
                'Top Consultores',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingConsultores)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (consultoresTop.isEmpty)
            const Expanded(child: Center(child: Text('Nenhum dado disponível')))
          else
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: consultoresTop.take(3).length,
                itemBuilder: (context, index) {
                  final c = consultoresTop[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            (c['nome'] as String? ?? '?')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c['nome'] ?? '',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${c['fechados'] ?? 0} fechados • ${c['visitas'] ?? 0} visitas',
                                style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${c['taxa_conversao'] ?? 0}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertasCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.red[700], size: 16),
              const SizedBox(width: 4),
              Text(
                'Ações Prioritárias',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingAlertas)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (alertas.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Nenhum alerta no momento', style: TextStyle(fontSize: 12)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alertas.length,
                itemBuilder: (context, index) {
                  final alerta = alertas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(alerta.getIconData(), size: 14, color: alerta.getColor()),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alerta.mensagem,
                            style: const TextStyle(fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Meta mensal', style: TextStyle(fontSize: 10)),
              Text(
                '${meta['atual'] ?? 0} / ${meta['meta'] ?? 0} leads',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (_toDouble(meta['progresso']) / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 2),
          Text(
            'Faltam ${meta['dias_restantes'] ?? 0} dias',
            style: TextStyle(fontSize: 8, color: Colors.grey[600]),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
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

  String _getPeriodoLabel() {
    switch (filtroPeriodo) {
      case 'Dia': return 'Últimos 7 dias';
      case 'Semana': return 'Últimas 4 semanas';
      case 'Ano': return 'Últimos 5 anos';
      default: return 'Mês atual';
    }
  }

  double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  Widget _buildGrafico(List<double> dados, List<String> labels) {
    if (dados.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

    final maxY = dados.reduce((a, b) => a > b ? a : b);
    final minY = dados.reduce((a, b) => a < b ? a : b);

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
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    );
                  },
                  reservedSize: 35,
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: dados.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value);
                }).toList(),
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
            minY: minY > 0 ? 0 : minY,
            maxY: maxY + (maxY * 0.1),
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
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    );
                  },
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
          ),
        );

      default:
        return const Center(child: Text('Selecione um tipo de gráfico'));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}