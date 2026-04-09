// ignore_for_file: unused_import
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ==================== MODELS ====================
class Address {
  final String? cep;
  final String pais;
  final String estado;
  final String cidade;
  final String bairro;
  final String rua;
  final String numero;
  final String? complemento;

  Address({
    this.cep,
    required this.pais,
    required this.estado,
    required this.cidade,
    required this.bairro,
    required this.rua,
    required this.numero,
    this.complemento,
  });

  Map<String, dynamic> toJson() => {
    'cep': cep,
    'pais': pais,
    'estado': estado,
    'cidade': cidade,
    'bairro': bairro,
    'rua': rua,
    'numero': numero,
    'complemento': complemento,
  };

  String resumo() {
    return '$rua, $numero${complemento != null ? ' - $complemento' : ''}, $bairro, $cidade - $estado, $pais${cep != null ? ', CEP: $cep' : ''}';
  }
}

class Lead {
  final String nome_local;
  final String responsavel;
  final String telefone;
  final Address endereco;
  final String status;
  final String? categoria;
  final String? observacao;
  final double? valor;

  Lead({
    required this.nome_local,
    required this.responsavel,
    required this.telefone,
    required this.endereco,
    required this.status,
    this.categoria,
    this.observacao,
    this.valor,
  });

  Map<String, dynamic> toJson() => {
    'nome_local': nome_local,
    'nome_responsavel': responsavel,
    'telefone': telefone,
    'endereco': endereco.toJson(),
    'estado_leads': status,
    'categoria_venda': categoria,
    'observacao': observacao,
    'valor_proposta': valor,
  };
}

/// ==================== CONSTANTES ====================
const kPrimary = Color(0xFFD32F2F);

/// ==================== ADDRESS DIALOG ====================
class AddressDialog extends StatefulWidget {
  const AddressDialog({super.key});

  @override
  State<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final String apiKey = 'AIzaSyCWaK80DL4E84s-qMKXl1tM-7o7BSMc-DY';

  // ── Sugestões ──
  List<dynamic> sugestoesPais   = [];
  List<dynamic> sugestoesEstado = [];
  List<dynamic> sugestoesCidade = [];
  List<dynamic> sugestoesBairro = [];
  List<dynamic> sugestoesRua    = [];

  // ── Estado de seleção ──
  String? paisIso;       // ex: "BR"
  String? estadoPlaceId;
  String? cidadePlaceId;
  double? cidadeLat;
  double? cidadeLng;
  double? bairroLat;
  double? bairroLng;

  // ── Controllers ──
  final _paisCtrl        = TextEditingController();
  final _estadoCtrl      = TextEditingController();
  final _cidadeCtrl      = TextEditingController();
  final _bairroCtrl      = TextEditingController();
  final _ruaCtrl         = TextEditingController();
  final _numeroCtrl      = TextEditingController();
  final _complementoCtrl = TextEditingController();

  @override
  void dispose() {
    _paisCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  /// Limpa campos e sugestões dos níveis abaixo do alterado
  void _limparAbaixoDe(String nivel) {
    setState(() {
      switch (nivel) {
        case 'pais':
          _estadoCtrl.clear(); sugestoesEstado = []; estadoPlaceId = null;
          _cidadeCtrl.clear(); sugestoesCidade = []; cidadePlaceId = null;
          cidadeLat = null; cidadeLng = null;
          _bairroCtrl.clear(); sugestoesBairro = []; bairroLat = null; bairroLng = null;
          _ruaCtrl.clear(); sugestoesRua = [];
          break;
        case 'estado':
          _cidadeCtrl.clear(); sugestoesCidade = []; cidadePlaceId = null;
          cidadeLat = null; cidadeLng = null;
          _bairroCtrl.clear(); sugestoesBairro = []; bairroLat = null; bairroLng = null;
          _ruaCtrl.clear(); sugestoesRua = [];
          break;
        case 'cidade':
          _bairroCtrl.clear(); sugestoesBairro = []; bairroLat = null; bairroLng = null;
          _ruaCtrl.clear(); sugestoesRua = [];
          break;
        case 'bairro':
          _ruaCtrl.clear(); sugestoesRua = [];
          break;
      }
    });
  }

  InputDecoration _dec(String label, IconData icon, {bool enabled = true}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: enabled ? kPrimary : Colors.grey),
      filled: !enabled,
      fillColor: Colors.grey.shade100,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: enabled ? Colors.black87 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _hint(String msg) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6, top: 2),
    child: Text(msg, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
  );

  Widget _buildSugestoes(List<dynamic> lista, Function(dynamic) aoSelecionar) {
    if (lista.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.only(top: 2, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: lista.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (_, i) {
          final s = lista[i];
          final texto = s['structured_formatting']?['main_text'] ?? s['description'] ?? '';
          final subtexto = s['structured_formatting']?['secondary_text'] ?? '';
          return InkWell(
            onTap: () => aoSelecionar(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.place, size: 14, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        if (subtexto.isNotEmpty)
                          Text(subtexto, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PAÍS
  // ─────────────────────────────────────────────

  Future<void> buscarPaises(String input) async {
    if (input.length < 2) { setState(() => sugestoesPais = []); return; }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&types=(regions)'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    debugPrint('🌍 [PAÍS] Buscando: "$input"');
    debugPrint('🌍 [PAÍS] URL: $url');

    try {
      final resp = await http.get(url);
      debugPrint('🌍 [PAÍS] HTTP ${resp.statusCode}');
      debugPrint('🌍 [PAÍS] Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final dados = json.decode(resp.body);
        final status = dados['status'];
        debugPrint('🌍 [PAÍS] API status: $status');
        if (status == 'REQUEST_DENIED') {
          debugPrint('🌍 [PAÍS] ⚠️ CHAVE INVÁLIDA OU SEM PERMISSÃO: ${dados['error_message']}');
        }
        final predictions = (dados['predictions'] as List? ?? []);
        // prioriza type "country", mas mostra qualquer coisa se não encontrar
        final paises = predictions.where((p) => (p['types'] as List).contains('country')).toList();
        setState(() => sugestoesPais = paises.isNotEmpty ? paises : predictions.take(5).toList());
        debugPrint('🌍 [PAÍS] ${sugestoesPais.length} resultado(s) exibido(s)');
      }
    } catch (e) {
      debugPrint('🌍 [PAÍS] Erro: $e');
    }
  }

  Future<void> selecionarPais(dynamic s) async {
    final nome = s['structured_formatting']?['main_text'] ?? s['description'];
    setState(() { _paisCtrl.text = nome; sugestoesPais = []; });
    _limparAbaixoDe('pais');

    // Extrai código ISO para filtrar estados/cidades corretamente
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${s['place_id']}'
        '&fields=address_components'
        '&key=$apiKey&language=pt_BR',
      );
      final resp = await http.get(url);
      final comps = json.decode(resp.body)['result']?['address_components'] as List? ?? [];
      for (var c in comps) {
        if ((c['types'] as List).contains('country')) {
          paisIso = c['short_name'];
          debugPrint('🌍 [PAÍS] ISO selecionado: $paisIso');
        }
      }
    } catch (e) { debugPrint('🌍 [PAÍS] Erro detalhes: $e'); }
  }

  // ─────────────────────────────────────────────
  // ESTADO
  // ─────────────────────────────────────────────

  Future<void> buscarEstados(String input) async {
    if (input.length < 2) { setState(() => sugestoesEstado = []); return; }
    if (paisIso == null) { debugPrint('⚠️ [ESTADO] País não selecionado'); return; }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&types=administrative_area_level_1'
      '&components=country:${paisIso!.toLowerCase()}'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    debugPrint('🗺️ [ESTADO] Buscando: "$input" (país: $paisIso)');
    debugPrint('🗺️ [ESTADO] URL: $url');

    try {
      final resp = await http.get(url);
      debugPrint('🗺️ [ESTADO] HTTP ${resp.statusCode}');
      debugPrint('🗺️ [ESTADO] Body: ${resp.body}');
      if (resp.statusCode == 200) {
        final dados = json.decode(resp.body);
        debugPrint('🗺️ [ESTADO] API status: ${dados['status']}');
        setState(() => sugestoesEstado = dados['predictions'] ?? []);
      }
    } catch (e) { debugPrint('🗺️ [ESTADO] Erro: $e'); }
  }

  void selecionarEstado(dynamic s) {
    final nome = s['structured_formatting']?['main_text'] ?? s['description'];
    estadoPlaceId = s['place_id'];
    setState(() { _estadoCtrl.text = nome; sugestoesEstado = []; });
    _limparAbaixoDe('estado');
    debugPrint('🗺️ [ESTADO] Selecionado: $nome');
  }

  // ─────────────────────────────────────────────
  // CIDADE
  // ─────────────────────────────────────────────

  Future<void> buscarCidades(String input) async {
    if (input.length < 2) { setState(() => sugestoesCidade = []); return; }
    if (paisIso == null) { debugPrint('⚠️ [CIDADE] País não selecionado'); return; }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&types=(cities)'
      '&components=country:${paisIso!.toLowerCase()}'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    debugPrint('🏙️ [CIDADE] Buscando: "$input"');
    debugPrint('🏙️ [CIDADE] URL: $url');

    try {
      final resp = await http.get(url);
      debugPrint('🏙️ [CIDADE] HTTP ${resp.statusCode}');
      debugPrint('🏙️ [CIDADE] Body: ${resp.body}');
      if (resp.statusCode == 200) {
        final dados = json.decode(resp.body);
        debugPrint('🏙️ [CIDADE] API status: ${dados['status']}');
        setState(() => sugestoesCidade = dados['predictions'] ?? []);
      }
    } catch (e) { debugPrint('🏙️ [CIDADE] Erro: $e'); }
  }

  Future<void> selecionarCidade(dynamic s) async {
    final nome = s['structured_formatting']?['main_text'] ?? s['description'];
    cidadePlaceId = s['place_id'];
    setState(() { _cidadeCtrl.text = nome; sugestoesCidade = []; });
    _limparAbaixoDe('cidade');

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$cidadePlaceId'
        '&fields=geometry,address_components'
        '&key=$apiKey&language=pt_BR',
      );
      final resp = await http.get(url);
      final result = json.decode(resp.body)['result'];
      if (result == null) return;

      final loc = result['geometry']?['location'];
      if (loc != null) {
        cidadeLat = loc['lat'];
        cidadeLng = loc['lng'];
        debugPrint('🏙️ [CIDADE] Coords: $cidadeLat, $cidadeLng');
      }

      // Preenche estado automaticamente se vazio
      final comps = result['address_components'] as List? ?? [];
      for (var c in comps) {
        if ((c['types'] as List).contains('administrative_area_level_1') && _estadoCtrl.text.isEmpty) {
          setState(() => _estadoCtrl.text = c['long_name'] ?? '');
        }
      }
    } catch (e) { debugPrint('🏙️ [CIDADE] Erro detalhes: $e'); }
  }

  // ─────────────────────────────────────────────
  // BAIRRO
  // ─────────────────────────────────────────────

  Future<void> buscarBairros(String input) async {
    if (input.length < 2) { setState(() => sugestoesBairro = []); return; }
    if (cidadeLat == null || cidadeLng == null) {
      debugPrint('⚠️ [BAIRRO] Cidade não selecionada');
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&types=sublocality'
      '&location=$cidadeLat,$cidadeLng'
      '&radius=25000'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    debugPrint('🏘️ [BAIRRO] Buscando: "$input"');
    debugPrint('🏘️ [BAIRRO] URL: $url');

    try {
      final resp = await http.get(url);
      debugPrint('🏘️ [BAIRRO] HTTP ${resp.statusCode}');
      debugPrint('🏘️ [BAIRRO] Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final dados = json.decode(resp.body);
        debugPrint('🏘️ [BAIRRO] API status: ${dados['status']}');
        List predictions = dados['predictions'] ?? [];

        // Fallback: busca genérica na área da cidade
        if (predictions.isEmpty) {
          debugPrint('🏘️ [BAIRRO] Sem resultados, tentando fallback genérico...');
          final urlFb = Uri.parse(
            'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(input)}'
            '&location=$cidadeLat,$cidadeLng'
            '&radius=20000'
            '&key=$apiKey&language=pt_BR',
          );
          final respFb = await http.get(urlFb);
          debugPrint('🏘️ [BAIRRO] Fallback body: ${respFb.body}');
          predictions = json.decode(respFb.body)['predictions'] ?? [];
        }

        setState(() => sugestoesBairro = predictions);
        debugPrint('🏘️ [BAIRRO] ${predictions.length} resultado(s)');
      }
    } catch (e) { debugPrint('🏘️ [BAIRRO] Erro: $e'); }
  }

  Future<void> selecionarBairro(dynamic s) async {
    final nome = s['structured_formatting']?['main_text'] ?? s['description'];
    setState(() { _bairroCtrl.text = nome; sugestoesBairro = []; });
    _limparAbaixoDe('bairro');

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${s['place_id']}'
        '&fields=geometry'
        '&key=$apiKey&language=pt_BR',
      );
      final resp = await http.get(url);
      final loc = json.decode(resp.body)['result']?['geometry']?['location'];
      if (loc != null) {
        bairroLat = loc['lat'];
        bairroLng = loc['lng'];
        debugPrint('🏘️ [BAIRRO] Coords: $bairroLat, $bairroLng');
      }
    } catch (e) { debugPrint('🏘️ [BAIRRO] Erro detalhes: $e'); }
  }

  // ─────────────────────────────────────────────
  // RUA
  // ─────────────────────────────────────────────

  Future<void> buscarRuas(String input) async {
    if (input.length < 2) { setState(() => sugestoesRua = []); return; }

    final lat = bairroLat ?? cidadeLat;
    final lng = bairroLng ?? cidadeLng;

    if (lat == null || lng == null) {
      debugPrint('⚠️ [RUA] Cidade/bairro não selecionado');
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&types=address'
      '&location=$lat,$lng'
      '&radius=10000'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    debugPrint('🛣️ [RUA] Buscando: "$input"');
    debugPrint('🛣️ [RUA] URL: $url');

    try {
      final resp = await http.get(url);
      debugPrint('🛣️ [RUA] HTTP ${resp.statusCode}');
      debugPrint('🛣️ [RUA] Body: ${resp.body}');
      if (resp.statusCode == 200) {
        final dados = json.decode(resp.body);
        debugPrint('🛣️ [RUA] API status: ${dados['status']}');
        setState(() => sugestoesRua = dados['predictions'] ?? []);
      }
    } catch (e) { debugPrint('🛣️ [RUA] Erro: $e'); }
  }

  Future<void> selecionarRua(dynamic s) async {
    final nome = s['structured_formatting']?['main_text'] ?? s['description'];
    setState(() { _ruaCtrl.text = nome; sugestoesRua = []; });
    debugPrint('🛣️ [RUA] Selecionada: $nome');

    // Preenche bairro se estiver vazio
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${s['place_id']}'
        '&fields=address_components'
        '&key=$apiKey&language=pt_BR',
      );
      final resp = await http.get(url);
      final comps = json.decode(resp.body)['result']?['address_components'] as List? ?? [];
      for (var c in comps) {
        final types = c['types'] as List;
        if ((types.contains('sublocality') || types.contains('sublocality_level_1')) &&
            _bairroCtrl.text.isEmpty) {
          setState(() => _bairroCtrl.text = c['long_name'] ?? '');
        }
      }
    } catch (e) { debugPrint('🛣️ [RUA] Erro detalhes: $e'); }
  }

  // ─────────────────────────────────────────────
  // CONFIRMAR
  // ─────────────────────────────────────────────

  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(Address(
      pais:        _paisCtrl.text.trim().isEmpty ? 'Brasil' : _paisCtrl.text.trim(),
      estado:      _estadoCtrl.text.trim(),
      cidade:      _cidadeCtrl.text.trim(),
      bairro:      _bairroCtrl.text.trim(),
      rua:         _ruaCtrl.text.trim(),
      numero:      _numeroCtrl.text.trim(),
      complemento: _complementoCtrl.text.trim().isEmpty ? null : _complementoCtrl.text.trim(),
    ));
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool temPais   = paisIso != null;
    final bool temCidade = cidadeLat != null;

    return AlertDialog(
      title: const Text('Selecionar Endereço'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── PAÍS ──
                TextFormField(
                  controller: _paisCtrl,
                  decoration: _dec('País *', Icons.public),
                  onChanged: buscarPaises,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o país' : null,
                ),
                _buildSugestoes(sugestoesPais, selecionarPais),

                // ── ESTADO ──
                TextFormField(
                  controller: _estadoCtrl,
                  decoration: _dec('Estado *', Icons.map, enabled: temPais),
                  enabled: temPais,
                  onChanged: temPais ? buscarEstados : null,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o estado' : null,
                ),
                if (!temPais) _hint('Selecione um país primeiro'),
                _buildSugestoes(sugestoesEstado, selecionarEstado),

                // ── CIDADE ──
                TextFormField(
                  controller: _cidadeCtrl,
                  decoration: _dec('Cidade *', Icons.location_city, enabled: temPais),
                  enabled: temPais,
                  onChanged: temPais ? buscarCidades : null,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a cidade' : null,
                ),
                if (!temPais) _hint('Selecione um estado primeiro'),
                _buildSugestoes(sugestoesCidade, selecionarCidade),

                // ── BAIRRO ──
                TextFormField(
                  controller: _bairroCtrl,
                  decoration: _dec('Bairro *', Icons.holiday_village, enabled: temCidade),
                  enabled: temCidade,
                  onChanged: temCidade ? buscarBairros : null,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o bairro' : null,
                ),
                if (!temCidade) _hint('Selecione uma cidade primeiro'),
                _buildSugestoes(sugestoesBairro, selecionarBairro),

                // ── RUA ──
                TextFormField(
                  controller: _ruaCtrl,
                  decoration: _dec('Rua *', Icons.signpost, enabled: temCidade),
                  enabled: temCidade,
                  onChanged: temCidade ? buscarRuas : null,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a rua' : null,
                ),
                if (!temCidade) _hint('Selecione uma cidade primeiro'),
                _buildSugestoes(sugestoesRua, selecionarRua),

                const SizedBox(height: 4),

                // ── NÚMERO ──
                TextFormField(
                  controller: _numeroCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _dec('Número *', Icons.numbers),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o número' : null,
                ),
                const SizedBox(height: 12),

                // ── COMPLEMENTO ──
                TextFormField(
                  controller: _complementoCtrl,
                  decoration: _dec('Complemento (opcional)', Icons.add_location_alt),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: _confirmar,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

/// ==================== CREATE LEAD ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  final _responsavelCtrl = TextEditingController();
  final _telefoneCtrl    = TextEditingController();
  final _valorCtrl       = TextEditingController();
  final _obsCtrl         = TextEditingController();
  final _nome_localCtrl  = TextEditingController();

  String? _categoria;
  String? _statusLead;
  Address? _endereco;
  bool _saving = false;

  @override
  void dispose() {
    _responsavelCtrl.dispose();
    _telefoneCtrl.dispose();
    _valorCtrl.dispose();
    _obsCtrl.dispose();
    _nome_localCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirDialogEndereco() async {
    final selecionado = await showDialog<Address>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddressDialog(),
    );
    if (selecionado != null) setState(() => _endereco = selecionado);
  }

  String _formatarTelefone(String input) {
    final d = input.replaceAll(RegExp(r'\D'), '');
    if (d.length < 13) return input;
    return '+${d.substring(0, 2)}-${d.substring(2, 4)}-${d.substring(4)}';
  }

  Future<void> _salvar() async {
    if (_endereco == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecione um endereço antes de salvar.'),
        backgroundColor: kPrimary,
      ));
      return;
    }
    if (_statusLead == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecione um status do lead.'),
        backgroundColor: kPrimary,
      ));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final lead = Lead(
        nome_local:  _nome_localCtrl.text.trim(),
        responsavel: _responsavelCtrl.text.trim(),
        telefone:    _formatarTelefone(_telefoneCtrl.text),
        endereco:    _endereco!,
        status:      _statusLead!,
        categoria:   _categoria,
        observacao:  _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
        valor:       double.tryParse(_valorCtrl.text.replaceAll('.', '').replaceAll(',', '.')),
      );

      final resp = await http.post(
        Uri.parse('https://jornadabackend-hr3v.onrender.com/criar_lead'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(lead.toJson()),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lead salvo com sucesso!'),
          backgroundColor: kPrimary,
        ));
        Navigator.of(context).pop(true);
      } else {
        String msg = 'Erro ao salvar lead (${resp.statusCode})';
        try { msg = jsonDecode(resp.body)['mensagem'] ?? msg; } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    );
    final focusBorder = border.copyWith(
      borderSide: const BorderSide(color: kPrimary, width: 2),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Criar Lead'),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nome_localCtrl,
                  decoration: InputDecoration(labelText: 'Nome da Empresa *',
                      prefixIcon: const Icon(Icons.business, color: kPrimary),
                      enabledBorder: border, focusedBorder: focusBorder),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome da empresa' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _responsavelCtrl,
                  decoration: InputDecoration(labelText: 'Nome do Responsável *',
                      prefixIcon: const Icon(Icons.person, color: kPrimary),
                      enabledBorder: border, focusedBorder: focusBorder),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o responsável' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, TelefoneInputFormatter()],
                  decoration: InputDecoration(labelText: 'Telefone *', hintText: '+55 (43) 90000-0001',
                      prefixIcon: const Icon(Icons.phone, color: kPrimary),
                      enabledBorder: border, focusedBorder: focusBorder),
                  validator: (v) => (v == null || v.trim().length < 17) ? 'Informe um telefone válido' : null,
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: const Color(0xFFF7F7F7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.location_on, color: kPrimary),
                        const SizedBox(width: 8),
                        const Text('Endereço *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _abrirDialogEndereco,
                          icon: const Icon(Icons.edit_location_alt, color: kPrimary),
                          label: Text(_endereco == null ? 'Escolher' : 'Alterar',
                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(_endereco == null ? 'Nenhum endereço selecionado.' : _endereco!.resumo()),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Status do Lead *',
                      prefixIcon: const Icon(Icons.flag, color: kPrimary),
                      enabledBorder: border, focusedBorder: focusBorder),
                  items: const [
                    DropdownMenuItem(value: 'aberta',     child: Text('Aberta')),
                    DropdownMenuItem(value: 'conexao',    child: Text('Conexão')),
                    DropdownMenuItem(value: 'negociacao', child: Text('Negociação')),
                    DropdownMenuItem(value: 'fechada',    child: Text('Fechada')),
                  ],
                  value: _statusLead,
                  onChanged: (v) => setState(() => _statusLead = v),
                  validator: (v) => v == null ? 'Selecione um status' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), ValorInputFormatter()],
                  decoration: InputDecoration(labelText: 'Valor da Proposta',
                      prefixIcon: const Icon(Icons.attach_money, color: kPrimary),
                      enabledBorder: border, focusedBorder: focusBorder),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Categoria (opcional)',
                      prefixIcon: const Icon(Icons.category, color: kPrimary),
                      enabledBorder: border, focusedBorder: focusBorder),
                  items: const [
                    DropdownMenuItem(value: 'Imovel',      child: Text('Imóvel')),
                    DropdownMenuItem(value: 'Veículo',     child: Text('Veículo')),
                    DropdownMenuItem(value: 'Serviços',    child: Text('Serviços')),
                    DropdownMenuItem(value: 'Bens Móveis', child: Text('Bens Móveis')),
                  ],
                  value: _categoria,
                  onChanged: (v) => setState(() => _categoria = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _obsCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: 'Observação (opcional)',
                      prefixIcon: const Icon(Icons.notes, color: kPrimary),
                      alignLabelWithHint: true,
                      enabledBorder: border, focusedBorder: focusBorder),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvar', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============= FORMATADOR DE TELEFONE =============
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    String d = nv.text.replaceAll(RegExp(r'[^\d]'), '');
    if (d.isEmpty) return const TextEditingValue(text: '');
    if (d.length > 13) d = d.substring(0, 13);

    String f = '+';
    f += d.substring(0, min(2, d.length));
    if (d.length < 2) return _r(f);
    f += ' ';
    if (d.length >= 3) {
      f += '(' + d.substring(2, min(4, d.length));
    } else {
      return _r(f + '(' + d.substring(2) + ')');
    }
    if (d.length >= 4) f += ') '; else return _r(f);
    if (d.length > 4) {
      final n = d.substring(4);
      f += n.length <= 5 ? n : '${n.substring(0, 5)}-${n.substring(5)}';
    }
    return _r(f);
  }

  TextEditingValue _r(String t) =>
      TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
}

/// ============= FORMATADOR DE VALOR =============
class ValorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    String d = nv.text.replaceAll(RegExp(r'[^\d]'), '');
    if (d.isEmpty) d = '0';
    final t = NumberFormat('#,##0.00', 'pt_BR').format(double.parse(d) / 100.0);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}