import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './models/usuario_logado.dart';
import '../constants.dart';

const _kPrimary   = Color(0xFFD32F2F);
const _kPrimaryLt = Color(0xFFFFEBEE);
const _kGrey      = Color(0xFFF5F5F5);

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class BuscarLead extends StatefulWidget {
  const BuscarLead({super.key});
  @override
  State<BuscarLead> createState() => _BuscarLeadState();
}

class _BuscarLeadState extends State<BuscarLead> {
  String? _token;
  bool _carregandoToken = true;
  bool _carregando      = false;
  bool _filtrosVisiveis = false;

  List<MeusLeadsModel> _leads = [];

  final _nomeCtrl        = TextEditingController();
  final _responsavelCtrl = TextEditingController();

  String? _filtroPais;
  String? _filtroEstado;
  String? _filtroCidade;
  String? _filtroRua;
  String? _filtroCategoria;
  String? _filtroEstadoLead;

  List<String> _paises  = [];
  List<String> _estados = [];
  List<String> _cidades = [];
  List<String> _ruas    = [];

  Timer? _debounce;

  static const _categorias  = ['imovel', 'veiculo', 'servico', 'bens_moveis'];
  static const _estadosLead = ['aberta', 'conexao', 'negociacao', 'fechada'];

  @override
  void initState() {
    super.initState();
    _carregarToken();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nomeCtrl.dispose();
    _responsavelCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString('usuario_logado');
    if (json != null) {
      _token = UsuarioLogado.fromJson(jsonDecode(json)).token;
    }
    setState(() => _carregandoToken = false);
    await _carregarOpcoesFiltros();
    _buscar();
  }

  Future<void> _carregarOpcoesFiltros() async {
    try {
      final resp = await http.get(
        Uri.parse('$kBaseUrl/all_leads/filtros'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _paises  = List<String>.from(data['paises']  ?? []);
          _estados = List<String>.from(data['estados'] ?? []);
          _cidades = List<String>.from(data['cidades'] ?? []);
          _ruas    = List<String>.from(data['ruas']    ?? []);
        });
      }
    } catch (_) {}
  }

  void _agendarBusca() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _buscar);
  }

  Future<void> _buscar() async {
    if (_token == null) return;
    setState(() => _carregando = true);
    try {
      final params = <String, String>{};
      if (_nomeCtrl.text.trim().isNotEmpty)
        params['nome_local'] = _nomeCtrl.text.trim();
      if (_responsavelCtrl.text.trim().isNotEmpty)
        params['nome_responsavel'] = _responsavelCtrl.text.trim();
      if (_filtroPais       != null) params['pais']           = _filtroPais!;
      if (_filtroEstado     != null) params['estado']         = _filtroEstado!;
      if (_filtroCidade     != null) params['cidade']         = _filtroCidade!;
      if (_filtroRua        != null) params['rua']            = _filtroRua!;
      if (_filtroCategoria  != null) params['categoria_venda']= _filtroCategoria!;
      if (_filtroEstadoLead != null) params['estado_lead']    = _filtroEstadoLead!;

      final uri = Uri.parse('$kBaseUrl/all_leads')
          .replace(queryParameters: params);
      final resp = await http.get(uri,
          headers: {'Authorization': 'Bearer $_token'});

      if (resp.statusCode == 200) {
        final parsed = jsonDecode(resp.body);
        if (parsed is List) {
          setState(() {
            _leads = parsed
                .map((e) => MeusLeadsModel.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList();
          });
        }
      } else {
        setState(() => _leads = []);
      }
    } catch (e) {
      debugPrint('[BuscarLead] Erro: $e');
      setState(() => _leads = []);
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _limparFiltros() {
    setState(() {
      _nomeCtrl.clear();
      _responsavelCtrl.clear();
      _filtroPais       = null;
      _filtroEstado     = null;
      _filtroCidade     = null;
      _filtroRua        = null;
      _filtroCategoria  = null;
      _filtroEstadoLead = null;
    });
    _buscar();
  }

  bool get _temFiltroAtivo =>
      _nomeCtrl.text.isNotEmpty ||
      _responsavelCtrl.text.isNotEmpty ||
      _filtroPais != null ||
      _filtroEstado != null ||
      _filtroCidade != null ||
      _filtroRua != null ||
      _filtroCategoria != null ||
      _filtroEstadoLead != null;

  // ── Navegar para visitas ──────────────────────────────────────────────────
  void _irParaVisitas(MeusLeadsModel lead) {
    if (lead.idLead == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead sem ID válido')),
      );
      return;
    }
    Navigator.pushNamed(context, '/visitas', arguments: {
      'id_lead':        lead.idLead!,
      'nome_local':     lead.nomeLocalOrDash,
      'id_localizacao': lead.idLocalizacao,
    });
  }

  // ── Detalhes ──────────────────────────────────────────────────────────────
  void _mostrarDetalhes(MeusLeadsModel lead) {
    final e = lead.endereco;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.95,
        minChildSize: 0.35,
        expand: false,
        builder: (_, sc) => SingleChildScrollView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimaryLt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business,
                      color: _kPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.nomeLocalOrDash,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      if (lead.estadoLead != null)
                        _estadoChip(lead.estadoLead!),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // ✅ Botão Ver Visitas em destaque
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _irParaVisitas(lead);
                  },
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Ver / Registrar Visitas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),

              _secao('Localização', Icons.location_on),
              _detalhe('Endereço',
                  '${e.ruaOrDash}, ${e.numeroOrDash}${e.complementoOrEmpty}'),
              _detalhe('Cidade / Estado',
                  '${e.cidadeOrDash} / ${e.estadoOrDash}'),
              _detalhe('País', e.paisOrDash),

              const SizedBox(height: 12),
              const Divider(),

              _secao('Informações', Icons.info_outline),
              _detalhe('Responsável', lead.nomeResponsavelOrDash),
              _detalhe('Consultor',   lead.nomeConsultorOrDash),
              if (lead.categoriaVenda != null)
                _detalhe('Categoria', lead.categoriaVenda!),
              if (lead.valorProposta != null)
                _detalhe('Proposta',
                    'R\$ ${lead.valorProposta!.toStringAsFixed(2)}'),

              const SizedBox(height: 12),
              const Divider(),

              _secao('Datas', Icons.calendar_today),
              _detalhe('Criado em',     lead.dataCriacaoFormatted),
              _detalhe('Última visita', lead.ultimaVisitaFormatted),
              if (lead.previsaoContato != null)
                _detalhe('Próxima visita', lead.previsaoContato!),

              if (lead.observacoes?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                const Divider(),
                _secao('Observações', Icons.notes),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(lead.observacoes!,
                      style: const TextStyle(height: 1.5)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _secao(String titulo, IconData icon) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                  letterSpacing: 0.5)),
        ]),
      );

  Widget _detalhe(String label, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(valor,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _estadoChip(String estado) {
    final cores = {
      'fechada':    Colors.green,
      'negociacao': Colors.blue,
      'conexao':    Colors.orange,
      'aberta':     Colors.grey,
    };
    final cor = cores[estado] ?? Colors.grey;
    final label = {
      'fechada': 'Fechada', 'negociacao': 'Negociação',
      'conexao': 'Conexão', 'aberta': 'Aberta',
    }[estado] ?? estado;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_carregandoToken) {
      return const Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: _kPrimary)));
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: const Text('Buscar Leads',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_temFiltroAtivo)
              TextButton.icon(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.filter_alt_off,
                    color: Colors.white, size: 18),
                label: const Text('Limpar',
                    style:
                        TextStyle(color: Colors.white, fontSize: 13)),
              ),
            IconButton(
              icon: Icon(
                _filtrosVisiveis
                    ? Icons.tune
                    : Icons.tune_outlined,
                color: Colors.white,
              ),
              tooltip: 'Filtros',
              onPressed: () => setState(
                  () => _filtrosVisiveis = !_filtrosVisiveis),
            ),
          ],
        ),
        body: Column(
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _filtrosVisiveis
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildFiltros(),
              secondChild: const SizedBox.shrink(),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(children: [
                Text(
                  _carregando
                      ? 'Buscando...'
                      : '${_leads.length} lead${_leads.length != 1 ? 's' : ''} encontrado${_leads.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (_carregando)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _carregando && _leads.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: _kPrimary))
                  : _leads.isEmpty
                      ? _buildVazio()
                      : RefreshIndicator(
                          onRefresh: _buscar,
                          color: _kPrimary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                14, 12, 14, 80),
                            itemCount: _leads.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_leads[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kPrimary, width: 2),
    );

    InputDecoration dec(String label, IconData icon) => InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _kPrimary, size: 18),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: border,
          focusedBorder: focusBorder,
          filled: true,
          fillColor: Colors.white,
        );

    Widget dropdown(
      String label,
      IconData icon,
      String? value,
      List<String> items,
      ValueChanged<String?> onChanged,
    ) =>
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: dec(label, icon),
          items: [
            DropdownMenuItem(
                value: null,
                child: Text('Todos',
                    style:
                        TextStyle(color: Colors.grey.shade500))),
            ...items.map(
                (s) => DropdownMenuItem(value: s, child: Text(s))),
          ],
          onChanged: (v) {
            onChanged(v);
            _agendarBusca();
          },
        );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _nomeCtrl,
                onChanged: (_) => _agendarBusca(),
                decoration: dec('Nome do local', Icons.business),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _responsavelCtrl,
                onChanged: (_) => _agendarBusca(),
                decoration: dec('Responsável', Icons.person),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: dropdown('País', Icons.public, _filtroPais,
                  _paises, (v) => setState(() => _filtroPais = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: dropdown('Estado', Icons.map, _filtroEstado,
                  _estados,
                  (v) => setState(() => _filtroEstado = v)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: dropdown(
                  'Cidade', Icons.location_city, _filtroCidade,
                  _cidades,
                  (v) => setState(() => _filtroCidade = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: dropdown('Rua', Icons.signpost, _filtroRua,
                  _ruas, (v) => setState(() => _filtroRua = v)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: dropdown(
                  'Categoria', Icons.category, _filtroCategoria,
                  _categorias,
                  (v) => setState(() => _filtroCategoria = v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: dropdown(
                  'Situação', Icons.flag, _filtroEstadoLead,
                  _estadosLead,
                  (v) => setState(() => _filtroEstadoLead = v)),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _buscar,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Aplicar Filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(MeusLeadsModel l) {
    final e      = l.endereco;
    final letra  = l.nomeLocalOrDash.characters.first.toUpperCase();
    final estado = l.estadoLead ?? 'aberta';

    final corEstado = {
      'fechada':    Colors.green,
      'negociacao': Colors.blue,
      'conexao':    Colors.orange,
      'aberta':     Colors.grey,
    }[estado] ?? Colors.grey;

    final labelEstado = {
      'fechada': 'Fechada', 'negociacao': 'Negociação',
      'conexao': 'Conexão', 'aberta': 'Aberta',
    }[estado] ?? estado;

    return GestureDetector(
      onTap: () => _mostrarDetalhes(l),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPrimaryLt,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(letra,
                    style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(l.nomeLocalOrDash,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: corEstado.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(labelEstado,
                            style: TextStyle(
                                fontSize: 10,
                                color: corEstado,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '${e.ruaOrDash}, ${e.numeroOrDash} — ${e.cidadeOrDash}/${e.estadoOrDash}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (l.nomeResponsavelOrDash != '-') ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.person_outline,
                            size: 12,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(l.nomeResponsavelOrDash,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ✅ Botão de visitas inline no card
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _irParaVisitas(l),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month,
                          color: _kPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Visitas',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVazio() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _temFiltroAtivo
                  ? 'Nenhum lead com esses filtros'
                  : 'Nenhum lead encontrado',
              style: TextStyle(
                  fontSize: 15, color: Colors.grey.shade500),
            ),
            if (_temFiltroAtivo) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _limparFiltros,
                icon: const Icon(Icons.filter_alt_off,
                    color: _kPrimary),
                label: const Text('Limpar filtros',
                    style: TextStyle(color: _kPrimary)),
              ),
            ],
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class MeusLeadsModel {
  final int?     idLead;
  final String?  nomeLocal;
  final String?  categoriaVenda;
  final String?  estadoLead;
  final int?     idLocalizacao;
  final Endereco endereco;
  final String?  nomeConsultor;
  final String?  nomeResponsavel;
  final String?  ultimaVisita;
  final String?  previsaoContato;
  final String?  dataCriacao;
  final double?  valorProposta;
  final String?  observacoes;

  MeusLeadsModel({
    required this.idLead,
    required this.nomeLocal,
    required this.categoriaVenda,
    required this.estadoLead,
    required this.idLocalizacao,
    required this.endereco,
    required this.nomeConsultor,
    required this.nomeResponsavel,
    required this.ultimaVisita,
    required this.previsaoContato,
    required this.dataCriacao,
    required this.valorProposta,
    required this.observacoes,
  });

  factory MeusLeadsModel.fromJson(Map<String, dynamic> j) =>
      MeusLeadsModel(
        idLead:         _toInt(j['id_lead']),
        nomeLocal:      j['nome_local']?.toString(),
        categoriaVenda: j['categoria_venda']?.toString(),
        estadoLead:     j['estado_lead']?.toString(),
        idLocalizacao:  _toInt(j['id_localizacao']),
        endereco:       Endereco.fromJson(j),
        nomeConsultor:  j['nome_consultor']?.toString(),
        nomeResponsavel:j['nome_responsavel']?.toString(),
        ultimaVisita:   j['ultima_visita']?.toString(),
        previsaoContato:j['previsao_contato']?.toString(),
        dataCriacao:    j['data_criacao']?.toString(),
        valorProposta:  j['valor_proposta'] == null
            ? null
            : double.tryParse(j['valor_proposta'].toString()),
        observacoes: j['observacoes']?.toString(),
      );

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  String get nomeLocalOrDash =>
      (nomeLocal?.trim().isEmpty ?? true) ? '-' : nomeLocal!;
  String get nomeConsultorOrDash =>
      (nomeConsultor?.trim().isEmpty ?? true) ? '-' : nomeConsultor!;
  String get nomeResponsavelOrDash =>
      (nomeResponsavel?.trim().isEmpty ?? true)
          ? '-'
          : nomeResponsavel!;
  String get estadoLeadOrDash =>
      (estadoLead?.trim().isEmpty ?? true) ? '-' : estadoLead!;
  String get dataCriacaoFormatted  => _fmt(dataCriacao);
  String get ultimaVisitaFormatted => _fmt(ultimaVisita);

  static String _fmt(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return iso; }
  }
}

class Endereco {
  final String? rua, numero, complemento, cidade, estado, pais;

  Endereco(
      {this.rua,
      this.numero,
      this.complemento,
      this.cidade,
      this.estado,
      this.pais});

  factory Endereco.fromJson(Map<String, dynamic> j) => Endereco(
        rua:         j['nome_rua']?.toString(),
        numero:      j['numero']?.toString(),
        complemento: j['complemento']?.toString(),
        cidade:      j['nome_cidade']?.toString(),
        estado:      j['uf']?.toString(),
        pais:        j['nome_pais']?.toString(),
      );

  String get ruaOrDash    => _v(rua);
  String get numeroOrDash => _v(numero);
  String get cidadeOrDash => _v(cidade);
  String get estadoOrDash => _v(estado);
  String get paisOrDash   => _v(pais);
  String get complementoOrEmpty =>
      (complemento?.trim().isEmpty ?? true) ? '' : ' — $complemento';

  String _v(String? v) =>
      (v?.trim().isEmpty ?? true) ? '-' : v!;
}