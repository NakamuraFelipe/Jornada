import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'service/dashboard_service.dart';
import 'models/dashboard_models.dart';

class DashPage extends StatefulWidget {
  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> with SingleTickerProviderStateMixin {
  String filtroGrafico = 'Linha';
  String filtroPeriodo = 'Mes';
  String filtroLeadSituacao = 'Todos';
  String filtroEstado = 'Todos';
  String filtroCidade = 'Todas';
  String filtroBairro = 'Todos';
  String filtroCategoria = 'Todas';
  RangeValues filtroValor = const RangeValues(0, 100000);
  String filtroTempoExistencia = 'Todos';
  String filtroRiscoChurn = 'Todos';

  Map<String, dynamic> metricas = {};
  List<double> dadosGrafico = [];
  List<String> labelsGrafico = [];
  Map<String, int> leadsPorBairro = {};
  Map<String, double> conversaoPorBairro = {};
  List<Map<String, dynamic>> consultoresTop = [];
  List<Alerta> alertas = [];
  Map<String, dynamic> meta = {};

  List<String> estados = ['Todos'];
  List<dynamic> cidades = [];
  List<dynamic> bairros = [];
  List<String> categorias = ['Todas'];

  bool isLoadingMetricas = true;
  bool isLoadingGrafico = true;
  bool isLoadingBairros = true;
  bool isLoadingConsultores = true;
  bool isLoadingAlertas = true;
  bool isLoadingFiltros = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int? idUsuarioLogado = 8;

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
    _carregarTodosDados();
    _carregarOpcoesFiltros();
  }

  Future<void> _carregarTodosDados() async {
    await Future.wait([
      _carregarMetricas(),
      _carregarGrafico(),
      _carregarLeadsPorBairro(),
      _carregarTopConsultores(),
      _carregarAlertas(),
    ]);
    _animationController.forward();
  }

  Future<void> _carregarMetricas() async {
    setState(() => isLoadingMetricas = true);
    try {
      metricas = await DashboardService.getMetricas(
        idUsuario: idUsuarioLogado,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        bairro: filtroBairro != 'Todos' ? filtroBairro : null,
        categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
        valorMin: filtroValor.start,
        valorMax: filtroValor.end,
      );
    } catch (e) {
      print('Erro ao carregar métricas: $e');
      metricas = {
        'fechado': 2590,
        'abertos': 2723,
        'conexao': 1461,
        'negociacao': 450,
        'total': 6774,
        'conversao': 38.2,
        'cobertura': 68,
        'valor_total': 1250000,
        'media_anual': 42500,
        'variacao_fechados': 12.5,
      };
    } finally {
      setState(() => isLoadingMetricas = false);
    }
  }

  Future<void> _carregarGrafico() async {
    setState(() => isLoadingGrafico = true);
    try {
      final resultado = await DashboardService.getEvolucao(
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
      _carregarDadosMockGrafico();
    } finally {
      setState(() => isLoadingGrafico = false);
    }
  }

  void _carregarDadosMockGrafico() {
    switch (filtroPeriodo) {
      case 'Dia':
        labelsGrafico = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        dadosGrafico = [12, 19, 15, 22, 28, 35, 42];
        break;
      case 'Semana':
        labelsGrafico = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
        dadosGrafico = [85, 92, 88, 105];
        break;
      case 'Ano':
        labelsGrafico = ['2021', '2022', '2023', '2024', '2025'];
        dadosGrafico = [3850, 4120, 4580, 5120, 5890];
        break;
      default:
        labelsGrafico = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        dadosGrafico = [320, 345, 368, 392, 415, 438, 452, 478, 495, 512, 538, 560];
    }
  }

  Future<void> _carregarLeadsPorBairro() async {
    setState(() => isLoadingBairros = true);
    try {
      final resultado = await DashboardService.getLeadsPorBairro(
        idUsuario: idUsuarioLogado,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
      );
      leadsPorBairro = resultado['leads_por_bairro'];
      conversaoPorBairro = resultado['conversao_por_bairro'];
    } catch (e) {
      print('Erro ao carregar leads por bairro: $e');
      leadsPorBairro = {
        'Centro': 45,
        'Jardins': 38,
        'Pinheiros': 32,
        'Vila Mariana': 28,
        'Moema': 25,
      };
      conversaoPorBairro = {
        'Centro': 0.33,
        'Jardins': 0.42,
        'Pinheiros': 0.38,
        'Vila Mariana': 0.29,
        'Moema': 0.48,
      };
    } finally {
      setState(() => isLoadingBairros = false);
    }
  }

  Future<void> _carregarTopConsultores() async {
    setState(() => isLoadingConsultores = true);
    try {
      consultoresTop = await DashboardService.getTopConsultores(limit: 5);
    } catch (e) {
      print('Erro ao carregar top consultores: $e');
      consultoresTop = [
        {'nome': 'João Silva', 'visitas': 45, 'fechados': 12, 'valor': 45000, 'taxa_conversao': 26.7},
        {'nome': 'Maria Santos', 'visitas': 38, 'fechados': 10, 'valor': 38000, 'taxa_conversao': 26.3},
        {'nome': 'Carlos Oliveira', 'visitas': 52, 'fechados': 9, 'valor': 35000, 'taxa_conversao': 17.3},
        {'nome': 'Ana Paula', 'visitas': 41, 'fechados': 11, 'valor': 42000, 'taxa_conversao': 26.8},
        {'nome': 'Pedro Mendes', 'visitas': 33, 'fechados': 7, 'valor': 28000, 'taxa_conversao': 21.2},
      ];
    } finally {
      setState(() => isLoadingConsultores = false);
    }
  }

  Future<void> _carregarAlertas() async {
    setState(() => isLoadingAlertas = true);
    try {
      final resultado = await DashboardService.getAlertas(idUsuario: idUsuarioLogado);
      alertas = (resultado['alertas'] as List)
          .map((a) => Alerta.fromJson(a))
          .toList();
      meta = resultado['meta'] ?? {};
    } catch (e) {
      print('Erro ao carregar alertas: $e');
      // ✅ Fallback garante que meta nunca fica com valores null
      meta = {
        'atual': 320000.0,
        'meta': 500000.0,
        'progresso': 64.0,
        'dias_restantes': 10,
      };
    } finally {
      setState(() => isLoadingAlertas = false);
    }
  }

  Future<void> _carregarOpcoesFiltros() async {
    setState(() => isLoadingFiltros = true);
    try {
      final resultado = await DashboardService.getOpcoesFiltros();
      estados = List<String>.from(resultado['estados']);
      cidades = resultado['cidades'];
      bairros = resultado['bairros'];
      categorias = List<String>.from(resultado['categorias']);
    } catch (e) {
      print('Erro ao carregar opções de filtros: $e');
      estados = ['Todos', 'SP', 'RJ', 'MG'];
      categorias = ['Todas', 'imovel', 'veiculo', 'servico', 'bens_moveis'];
    } finally {
      setState(() => isLoadingFiltros = false);
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> calcularMetricas() => metricas;

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
                          const Text('📍 LOCALIZAÇÃO',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text('📊 TIPO DE GRÁFICO',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _buildFiltroBottomSheet(
                            value: filtroGrafico,
                            items: const ['Linha', 'Barra'],
                            onChanged: (value) =>
                                setModalState(() => filtroGrafico = value),
                            icons: {
                              'Linha': Icons.show_chart,
                              'Barra': Icons.bar_chart,
                            },
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text('📅 PERÍODO',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _buildFiltroBottomSheet(
                            value: filtroPeriodo,
                            items: const ['Dia', 'Semana', 'Mes', 'Ano'],
                            onChanged: (value) =>
                                setModalState(() => filtroPeriodo = value),
                            icons: {
                              'Dia': Icons.today,
                              'Semana': Icons.date_range,
                              'Mes': Icons.calendar_month,
                              'Ano': Icons.timeline,
                            },
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text('🏷️ SITUAÇÃO DO LEAD',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _buildFiltroChip(
                            items: const ['Todos', 'aberta', 'conexao', 'negociacao', 'fechada'],
                            selectedValue: filtroLeadSituacao,
                            onChanged: (value) =>
                                setModalState(() => filtroLeadSituacao = value),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text('🏷️ CATEGORIA',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _buildFiltroChip(
                            items: categorias,
                            selectedValue: filtroCategoria,
                            onChanged: (value) =>
                                setModalState(() => filtroCategoria = value),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const Text('💰 VALOR DA PROPOSTA',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          RangeSlider(
                            values: filtroValor,
                            min: 0,
                            max: 100000,
                            divisions: 10,
                            labels: RangeLabels(
                              'R\$ ${filtroValor.start.toStringAsFixed(0)}',
                              'R\$ ${filtroValor.end.toStringAsFixed(0)}',
                            ),
                            onChanged: (values) =>
                                setModalState(() => filtroValor = values),
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
                              filtroValor = const RangeValues(0, 100000);
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
                            setState(() {
                              _animationController.reset();
                              _carregarTodosDados();
                            });
                            Navigator.pop(context);
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
    Map<String, Color>? colors,
  }) {
    return Wrap(
      spacing: 8,
      children: items.map((item) {
        final isSelected = item == selectedValue;
        Color chipColor;
        if (colors != null && colors.containsKey(item)) {
          chipColor = colors[item]!;
        } else {
          chipColor = const Color(0xFFE53935);
        }
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onChanged(item),
          backgroundColor: Colors.grey[100],
          selectedColor: chipColor.withOpacity(0.2),
          checkmarkColor: chipColor,
          labelStyle: TextStyle(
            color: isSelected ? chipColor : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFiltroBottomSheet({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    required Map<String, IconData> icons,
    Map<String, Color>? colors,
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
          Color itemColor;
          if (colors != null && colors.containsKey(item)) {
            itemColor = colors[item]!;
          } else {
            itemColor = const Color(0xFFE53935);
          }
          return InkWell(
            onTap: () => onChanged(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? itemColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icons[item], size: 20,
                      color: isSelected ? itemColor : Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? itemColor : Colors.grey[800],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, size: 18, color: itemColor),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ✅ Helper para evitar divisão por null — usado nos cards de meta
  double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final metricas = calcularMetricas();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _animationController.reset();
                _carregarTodosDados();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Cards de métricas superiores
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildListDelegate([
                isLoadingMetricas
                    ? _buildShimmerCard()
                    : _buildMetricaCard(
                        title: 'Fechados',
                        value: '${metricas['fechado'] ?? 0}',
                        variacao:
                            '${metricas['variacao_fechados'] != null && metricas['variacao_fechados'] > 0 ? '+' : ''}${_toDouble(metricas['variacao_fechados']).toStringAsFixed(1)}%',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                isLoadingMetricas
                    ? _buildShimmerCard()
                    : _buildMetricaCard(
                        title: 'Abertos',
                        value: '${metricas['abertos'] ?? 0}',
                        variacao: '+8%',
                        icon: Icons.email_outlined,
                        color: Colors.orange,
                      ),
                isLoadingMetricas
                    ? _buildShimmerCard()
                    : _buildMetricaCard(
                        title: 'Conversão',
                        value:
                            '${_toDouble(metricas['conversao']).toStringAsFixed(1)}%',
                        variacao: '+2%',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                isLoadingMetricas
                    ? _buildShimmerCard()
                    : _buildMetricaCard(
                        title: 'Cobertura',
                        value:
                            '${_toDouble(metricas['cobertura']).toStringAsFixed(1)}%',
                        variacao: '+5%',
                        icon: Icons.map,
                        color: Colors.purple,
                      ),
              ]),
            ),
          ),

          // Gráfico Principal
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                              'Evolução de Vendas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$filtroPeriodo - $filtroLeadSituacao',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                          : _buildGrafico(dadosGrafico, labelsGrafico),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Leads por Bairro
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                      final maxValor = leadsPorBairro.values
                          .reduce((a, b) => a > b ? a : b);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(entry.key,
                                  style: const TextStyle(fontSize: 14)),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            conversao > 0.4
                                                ? Colors.green
                                                : Colors.blue,
                                          ),
                                          minHeight: 8,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${entry.value}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                      );
                    }).toList(),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Ver todos os bairros →'),
                    ),
                  ),
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
                // Top Consultores
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 16),
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
                      const SizedBox(height: 8),
                      if (isLoadingConsultores)
                        const Center(child: CircularProgressIndicator())
                      else if (consultoresTop.isEmpty)
                        const Center(child: Text('Nenhum dado disponível'))
                      else
                        ...consultoresTop.take(3).map((c) {
                          // ✅ Proteção contra null no valor do consultor
                          final valor = _toDouble(c['valor']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.grey[200],
                                  child: Text(
                                    (c['nome'] as String? ?? '?')[0],
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        c['nome'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${c['fechados'] ?? 0} fechados',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  // ✅ CORRIGIDO: proteção contra null
                                  'R\$ ${(valor / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 4),
                      if (!isLoadingConsultores && consultoresTop.isNotEmpty)
                        Center(
                          child: Text(
                            'Média: ${(_toDouble(consultoresTop.map((c) => _toDouble(c['visitas'])).reduce((a, b) => a + b)) / consultoresTop.length).toStringAsFixed(0)} visitas | '
                            '${(_toDouble(consultoresTop.map((c) => _toDouble(c['taxa_conversao'])).reduce((a, b) => a + b)) / consultoresTop.length).toStringAsFixed(1)}% conversão',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),

                // Alertas e Ações
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active,
                              color: Colors.red[700], size: 16),
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
                      const SizedBox(height: 8),
                      if (isLoadingAlertas)
                        const Center(child: CircularProgressIndicator())
                      else if (alertas.isEmpty)
                        const Center(
                            child: Text('Nenhum alerta no momento'))
                      else
                        ...alertas.map((alerta) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(alerta.getIconData(),
                                    size: 12, color: alerta.getColor()),
                                const SizedBox(width: 6),
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
                        }).toList(),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Meta mensal',
                              style: TextStyle(fontSize: 10)),
                          Text(
                            // ✅ CORRIGIDO: usa _toDouble para evitar null / 1000
                            'R\$ ${(_toDouble(meta['atual']) / 1000).toStringAsFixed(0)}k'
                            ' / R\$ ${(_toDouble(meta['meta']) / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      LinearProgressIndicator(
                        // ✅ CORRIGIDO: usa _toDouble para evitar null / 100
                        value: _toDouble(meta['progresso']) / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.green),
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
                ),
              ]),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFiltros,
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.filter_list),
        label: const Text('Filtrar Dados'),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 40, height: 20, color: Colors.grey[300]),
          const SizedBox(height: 4),
          Container(width: 30, height: 12, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildMetricaCard({
    required String title,
    required String value,
    required String variacao,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: variacao.startsWith('+')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  variacao,
                  style: TextStyle(
                    fontSize: 8,
                    color: variacao.startsWith('+')
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildGrafico(List<double> dados, List<String> labels) {
    if (dados.isEmpty) {
      return const Center(child: Text('Sem dados para exibir'));
    }

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
                    if (value.toInt() >= 0 &&
                        value.toInt() < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(labels[value.toInt()],
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              ),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFFE53935).withOpacity(0.1),
                ),
              ),
            ],
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
                    if (value.toInt() >= 0 &&
                        value.toInt() < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(labels[value.toInt()],
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600])),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ),
              ),
              topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: dados.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: const Color(0xFFE53935),
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        );

      default:
        return const Center(child: Text('Selecione um tipo de gráfico'));
    }
  }
}