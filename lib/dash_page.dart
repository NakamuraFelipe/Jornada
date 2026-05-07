import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'service/dashboard_service.dart';
import 'models/dashboard_models.dart';
import 'models/usuario_logado.dart'; // 🔥 IMPORT ADICIONADO

class DashPage extends StatefulWidget {
  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage>
    with SingleTickerProviderStateMixin {
  // Filtros
  String filtroGrafico = 'Linha';
  String filtroPeriodo = 'Mes';
  String filtroLeadSituacao = 'Todos';
  String filtroEstado = 'Todos';
  String filtroCidade = 'Todas';
  String filtroBairro = 'Todos';
  String filtroCategoria = 'Todas';

  // Novos filtros
  List<int> idsConsultoresSelecionados = [];
  String filtroGroupBy = 'bairro';
  DateTime? dataInicio;
  DateTime? dataFim;

  // Aba selecionada
  int selectedTabIndex = 0;

  // Dados
  Map<String, dynamic> metricas = {};
  List<double> dadosGrafico = [];
  List<String> labelsGrafico = [];
  Map<String, int> leadsPorBairro = {};
  Map<String, double> conversaoPorBairro = {};
  List<Map<String, dynamic>> consultoresTop = [];
  List<Alerta> alertas = [];
  Map<String, dynamic> meta = {};

  // Novos dados
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
  bool isLoadingBairros = true;
  bool isLoadingConsultores = true;
  bool isLoadingAlertas = true;
  bool isLoadingCancelamentos = false;
  bool isLoadingRanking = false;
  bool isLoadingDesempenho = false;

  int? idUsuarioLogado;
  String? token;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _carregarDadosIniciais();
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {
        selectedTabIndex = _tabController.index;
      });
      if (selectedTabIndex == 1) _carregarCancelamentos();
      if (selectedTabIndex == 2) _carregarRankingVendas();
      if (selectedTabIndex == 3 && idsConsultoresSelecionados.isNotEmpty)
        _carregarDesempenhoConsultores();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    await _carregarUsuarioEToken();
  }

  // 🔥 CORREÇÃO PRINCIPAL: obtém o id_usuario do objeto 'usuario_logado'
  Future<void> _carregarUsuarioEToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');

      // Lê o objeto completo do usuário logado
      final usuarioJson = prefs.getString('usuario_logado');
      if (usuarioJson != null) {
        final usuario = UsuarioLogado.fromJson(jsonDecode(usuarioJson));
        idUsuarioLogado = usuario.idUsuario;
        print('✅ ID USUARIO obtido do objeto salvo: $idUsuarioLogado');
      } else {
        idUsuarioLogado = null;
        print('❌ Objeto usuario_logado não encontrado no SharedPreferences');
      }

      if (token == null || token!.isEmpty) {
        print('❌ Token não encontrado!');
        _mostrarErro('Usuário não logado. Faça login novamente.');
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      // Se ainda não tem id, tenta extrair do token (fallback)
      if (idUsuarioLogado == null) {
        try {
          final parts = token!.split('.');
          if (parts.length == 3) {
            final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
            );
            idUsuarioLogado = payload['id_usuario'] as int?;
            print('✅ ID USUARIO extraído do token: $idUsuarioLogado');
          }
        } catch (e) {
          print('⚠️ Falha ao extrair ID do token: $e');
        }
      }

      print('=== INICIANDO CARREGAMENTO DO DASHBOARD ===');
      print(
        'TOKEN CARREGADO: ${token != null ? "Token existe (${token!.length} chars)" : "Token NULO"}',
      );
      print('ID USUARIO: $idUsuarioLogado');

      // Carregar todos os dados em paralelo
      await Future.wait([
        _carregarMetricas(),
        _carregarGrafico(),
        _carregarLeadsPorBairro(),
        _carregarTopConsultores(),
        _carregarAlertas(),
        _carregarOpcoesFiltros(),
        _carregarListaConsultores(),
      ]);

      print('=== TODOS OS DADOS CARREGADOS COM SUCESSO ===');

      if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Erro ao carregar dados: $e');
      _mostrarErro('Erro ao carregar dados do usuário');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _carregarMetricas() async {
    print('🟢 Carregando métricas...');

    if (token == null || idUsuarioLogado == null) {
      print('❌ Token ou ID nulo ao carregar métricas');
      return;
    }

    try {
      final resultado = await DashboardService.getMetricas(
        token: token!,
        idsUsuario: idsConsultoresSelecionados.isEmpty
            ? [idUsuarioLogado!]
            : idsConsultoresSelecionados,
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

      print(
        '✅ Métricas recebidas: total=${resultado['total']}, fechados=${resultado['fechado']}',
      );

      if (mounted) {
        setState(() {
          metricas = resultado;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar métricas: $e');
      if (mounted) {
        setState(() {
          metricas = _getMetricasPadrao();
        });
      }
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
    print('🟢 Carregando gráfico...');

    if (token == null || idUsuarioLogado == null) {
      print('❌ Token ou ID nulo ao carregar gráfico');
      return;
    }

    if (mounted) {
      setState(() => isLoadingGrafico = true);
    }

    try {
      final resultado = await DashboardService.getEvolucao(
        token: token!,
        periodo: filtroPeriodo,
        situacao: filtroLeadSituacao,
        idsUsuario: idsConsultoresSelecionados.isEmpty
            ? [idUsuarioLogado!]
            : idsConsultoresSelecionados,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
        dataInicio: dataInicio != null
            ? DateFormat('yyyy-MM-dd').format(dataInicio!)
            : null,
        dataFim: dataFim != null
            ? DateFormat('yyyy-MM-dd').format(dataFim!)
            : null,
      );

      print('✅ Gráfico recebido: ${resultado['dados'].length} pontos');

      if (mounted) {
        setState(() {
          dadosGrafico = resultado['dados'];
          labelsGrafico = resultado['labels'];
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar gráfico: $e');
      if (mounted) {
        setState(() {
          dadosGrafico = [];
          labelsGrafico = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingGrafico = false);
      }
    }
  }

  Future<void> _carregarLeadsPorBairro() async {
    print('🟢 Carregando leads por bairro...');

    if (token == null || idUsuarioLogado == null) {
      print('❌ Token ou ID nulo ao carregar leads por bairro');
      return;
    }

    if (mounted) {
      setState(() => isLoadingBairros = true);
    }

    try {
      final resultado = await DashboardService.getLeadsPorBairro(
        token: token!,
        idsUsuario: idsConsultoresSelecionados.isEmpty
            ? [idUsuarioLogado!]
            : idsConsultoresSelecionados,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
      );

      print(
        '✅ Leads por bairro: ${resultado['leads_por_bairro'].length} bairros',
      );

      if (mounted) {
        setState(() {
          leadsPorBairro = resultado['leads_por_bairro'] ?? {};
          conversaoPorBairro = resultado['conversao_por_bairro'] ?? {};
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar leads por bairro: $e');
      if (mounted) {
        setState(() {
          leadsPorBairro = {};
          conversaoPorBairro = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingBairros = false);
      }
    }
  }

  Future<void> _carregarTopConsultores() async {
    print('🟢 Carregando top consultores...');

    if (token == null) {
      print('❌ Token é NULO!');
      return;
    }

    if (mounted) {
      setState(() => isLoadingConsultores = true);
    }

    try {
      final resultado = await DashboardService.getTopConsultores(token: token!);

      print('✅ Top consultores: ${resultado.length} consultores');

      if (mounted) {
        setState(() {
          consultoresTop = resultado;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar top consultores: $e');
      if (mounted) {
        setState(() {
          consultoresTop = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingConsultores = false);
      }
    }
  }

  Future<void> _carregarAlertas() async {
    print('🟢 Carregando alertas...');

    if (token == null || idUsuarioLogado == null) {
      print('❌ Token ou ID nulo ao carregar alertas');
      return;
    }

    if (mounted) {
      setState(() => isLoadingAlertas = true);
    }

    try {
      final resultado = await DashboardService.getAlertas(
        token: token!,
        idsUsuario: idsConsultoresSelecionados.isEmpty
            ? [idUsuarioLogado!]
            : idsConsultoresSelecionados,
      );

      print('✅ Alertas: ${resultado['alertas'].length} alertas');

      if (mounted) {
        setState(() {
          alertas = (resultado['alertas'] as List)
              .map((a) => Alerta.fromJson(a))
              .toList();
          meta = resultado['meta'] ?? {};
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar alertas: $e');
      if (mounted) {
        setState(() {
          alertas = [];
          meta = {'atual': 0, 'meta': 0, 'progresso': 0, 'dias_restantes': 0};
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoadingAlertas = false);
      }
    }
  }

  Future<void> _carregarCancelamentos() async {
    if (!mounted) return;
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
      print('✅ Cancelamentos: ${cancelamentos.length} registros');
    } catch (e) {
      print('❌ Erro ao carregar cancelamentos: $e');
      cancelamentos = [];
    } finally {
      if (mounted) setState(() => isLoadingCancelamentos = false);
    }
  }

  Future<void> _carregarRankingVendas() async {
    if (!mounted) return;
    setState(() => isLoadingRanking = true);
    try {
      rankingVendas = await DashboardService.getRankingVendas(
        token: token!,
        estado: filtroEstado != 'Todos' ? filtroEstado : null,
        cidade: filtroCidade != 'Todas' ? filtroCidade : null,
        categoria: filtroCategoria != 'Todas' ? filtroCategoria : null,
      );
      print('✅ Ranking vendas: ${rankingVendas.length} registros');
    } catch (e) {
      print('❌ Erro ao carregar ranking de vendas: $e');
      rankingVendas = [];
    } finally {
      if (mounted) setState(() => isLoadingRanking = false);
    }
  }

  Future<void> _carregarDesempenhoConsultores() async {
    if (idsConsultoresSelecionados.isEmpty) return;
    if (!mounted) return;

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
      print(
        '✅ Desempenho consultores: ${desempenhoConsultores.length} registros',
      );
    } catch (e) {
      print('❌ Erro ao carregar desempenho dos consultores: $e');
      desempenhoConsultores = [];
    } finally {
      if (mounted) setState(() => isLoadingDesempenho = false);
    }
  }

  Future<void> _carregarOpcoesFiltros() async {
    print('🟢 Carregando opções de filtros...');
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
      print(
        '✅ Opções de filtros carregadas: ${estados.length} estados, ${categorias.length} categorias',
      );
    } catch (e) {
      print('❌ Erro ao carregar opções de filtros: $e');
    }
  }

  Future<void> _carregarListaConsultores() async {
    print('🟢 Carregando lista de consultores...');
    try {
      listaConsultores = await DashboardService.getListaConsultores(
        token: token!,
      );
      print(
        '✅ Lista de consultores carregada: ${listaConsultores.length} consultores',
      );
    } catch (e) {
      print('❌ Erro ao carregar lista de consultores: $e');
      listaConsultores = [];
    }
  }

  List<String> getCidadesPorEstado() {
    if (filtroEstado == 'Todos') return ['Todas'];
    final cidadesDoEstado = cidades
        .where((c) => c['nome_estado'] == filtroEstado)
        .map((c) => c['nome_cidade'] as String)
        .toSet() // Remove duplicatas
        .toList();

    // Ordena alfabeticamente
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

  void _aplicarFiltros() {
    print('🔄 Aplicando filtros...');
    setState(() {
      _carregarMetricas();
      _carregarGrafico();
      _carregarLeadsPorBairro();
      _carregarAlertas();
      if (selectedTabIndex == 1) _carregarCancelamentos();
      if (selectedTabIndex == 2) _carregarRankingVendas();
      if (selectedTabIndex == 3) _carregarDesempenhoConsultores();
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                    filtroCidade = value ?? 'Todas';
                                    filtroBairro = 'Todos';
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildFiltroDropdown(
                                value: filtroBairro,
                                items: getBairrosPorCidade(),
                                label: 'Bairro',
                                onChanged: (value) => setModalState(
                                  () => filtroBairro = value ?? 'Todos',
                                ),
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
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  Widget _buildMultiSelectConsultores(Function(void Function()) setModalState) {
    if (listaConsultores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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
            if (date != null) {
              setModalState(() => dataInicio = date);
            }
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
            if (date != null) {
              setModalState(() => dataFim = date);
            }
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
            onPressed: () {
              setModalState(() {
                dataInicio = null;
                dataFim = null;
              });
            },
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
            onPressed: () => _aplicarFiltros(),
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _abrirFiltros,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _aplicarFiltros(),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Geral', icon: Icon(Icons.dashboard)),
                        Tab(text: 'Cancelamentos', icon: Icon(Icons.cancel)),
                        Tab(
                          text: 'Ranking Vendas',
                          icon: Icon(Icons.leaderboard),
                        ),
                        Tab(text: 'Desempenho', icon: Icon(Icons.people)),
                      ],
                      labelColor: const Color(0xFFE53935),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFFE53935),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGeralTab(),
                        _buildCancelamentosTab(),
                        _buildRankingVendasTab(),
                        _buildDesempenhoConsultoresTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGeralTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
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
                title: 'Conversão',
                value:
                    '${_toDouble(metricas['conversao']).toStringAsFixed(1)}%',
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
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
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
          ),
          const SizedBox(height: 16),
          Container(
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
                    final maxValor = leadsPorBairro.values.reduce(
                      (a, b) => a > b ? a : b,
                    );
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  conversao > 0.4
                                                      ? Colors.green
                                                      : Colors.blue,
                                                ),
                                            minHeight: 8,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [_buildTopConsultoresCard(), _buildAlertasCard()],
          ),
        ],
      ),
    );
  }

  Widget _buildCancelamentosTab() {
    return RefreshIndicator(
      onRefresh: () async => _carregarCancelamentos(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isLoadingCancelamentos)
              const Center(child: CircularProgressIndicator())
            else if (cancelamentos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhum cancelamento encontrado'),
                    ],
                  ),
                ),
              )
            else
              ...cancelamentos.map(
                (item) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      item['localizacao'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Total de vendas: ${item['total_vendas']}'),
                        Text('Canceladas: ${item['canceladas']}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (item['taxa_cancelamento'] as double) > 30
                            ? Colors.red[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${item['taxa_cancelamento']}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (item['taxa_cancelamento'] as double) > 30
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingVendasTab() {
    return RefreshIndicator(
      onRefresh: () async => _carregarRankingVendas(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isLoadingRanking)
              const Center(child: CircularProgressIndicator())
            else if (rankingVendas.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.leaderboard, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhuma venda encontrada'),
                    ],
                  ),
                ),
              )
            else
              ...rankingVendas.asMap().entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      entry.value['bairro'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Categoria: ${entry.value['categoria']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value['vendas']} vendas',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesempenhoConsultoresTab() {
    if (idsConsultoresSelecionados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhum consultor selecionado',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _abrirFiltros,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text('Selecionar Consultores'),
            ),
          ],
        ),
      );
    }

    if (isLoadingDesempenho) {
      return const Center(child: CircularProgressIndicator());
    }

    if (desempenhoConsultores.isEmpty) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nenhum dado de desempenho encontrado'),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _carregarDesempenhoConsultores(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Resumo Geral',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildResumoItem(
                          'Total Leads',
                          desempenhoConsultores.fold<int>(
                            0,
                            (sum, item) => sum + (item['total_leads'] as int),
                          ),
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildResumoItem(
                          'Total Vendas',
                          desempenhoConsultores.fold<int>(
                            0,
                            (sum, item) => sum + (item['total_vendas'] as int),
                          ),
                          Icons.shopping_cart,
                          Colors.green,
                        ),
                        _buildResumoItem(
                          'Ticket Médio',
                          'R\$ ${(desempenhoConsultores.fold<double>(0, (sum, item) => sum + (item['ticket_medio'] as double)) / desempenhoConsultores.length).toStringAsFixed(2)}',
                          Icons.monetization_on,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Consultor',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Leads',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Vendas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Conversão',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Visitas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Ticket Médio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: desempenhoConsultores.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['nome'])),
                        DataCell(Text(item['total_leads'].toString())),
                        DataCell(Text(item['total_vendas'].toString())),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (item['taxa_conversao'] as double) > 50
                                  ? Colors.green[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item['taxa_conversao']}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (item['taxa_conversao'] as double) > 50
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(item['total_visitas'].toString())),
                        DataCell(
                          Text(
                            'R\$ ${(item['ticket_medio'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
            const Center(child: CircularProgressIndicator())
          else if (consultoresTop.isEmpty)
            const Center(child: Text('Nenhum dado disponível'))
          else
            ...consultoresTop
                .take(3)
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            (c['nome'] as String? ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${c['fechados'] ?? 0} fechados • ${c['visitas'] ?? 0} visitas',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
              Icon(
                Icons.notifications_active,
                color: Colors.red[700],
                size: 16,
              ),
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
            const Center(child: CircularProgressIndicator())
          else if (alertas.isEmpty)
            const Center(
              child: Text(
                'Nenhum alerta no momento',
                style: TextStyle(fontSize: 12),
              ),
            )
          else
            ...alertas.map(
              (alerta) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      alerta.getIconData(),
                      size: 14,
                      color: alerta.getColor(),
                    ),
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
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
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
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
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
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
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
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
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
}
