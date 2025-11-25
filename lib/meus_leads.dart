import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './models/usuario_logado.dart';

const kPrimary = Color(0xFFD32F2F);

class MeusLeads extends StatefulWidget {
  const MeusLeads({super.key});

  @override
  State<MeusLeads> createState() => _MeusLeadsState();
}

class _MeusLeadsState extends State<MeusLeads> {
  String? _token; // Token do usuário
  bool _carregandoToken = true;

  final TextEditingController _buscaCtrl = TextEditingController();
  final FocusNode _buscaFocus = FocusNode();

  List<MeusLeadsModel> _leads = [];
  bool _carregando = false;
  bool _primeiraVez = true;

  Timer? _debounce;
  static const String baseUrl = "http://192.168.0.22:5000";

  @override
  void initState() {
    super.initState();
    _carregarToken();

    _buscaFocus.addListener(() {
      if (_buscaFocus.hasFocus) setState(() => _primeiraVez = false);
    });
  }

  Future<void> _carregarToken() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString('usuario_logado');
    if (usuarioJson != null) {
      final usuario = UsuarioLogado.fromJson(jsonDecode(usuarioJson));
      _token = usuario.token; // Aqui pega o token do usuário logado
      print("Token carregado: $_token");
    } else {
      print("Nenhum usuário logado encontrado.");
    }
    setState(() => _carregandoToken = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaCtrl.dispose();
    _buscaFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim().isNotEmpty) _buscarLeadsInternal(value.trim());
    });
  }

  Future<void> _buscarLeads(String termo) async {
    setState(() => _primeiraVez = false);
    _onSearchChanged(termo);
  }

  Future<void> _buscarLeadsInternal(String termo) async {
    if (_token == null || termo.isEmpty) {
      setState(() {
        _leads = [];
        _carregando = false;
      });
      return;
    }

    setState(() => _carregando = true);

    try {
      final url = Uri.parse("$baseUrl/meus_leads?query=${Uri.encodeQueryComponent(termo)}");
      print("GET $url");

      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $_token"},
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final parsed = jsonDecode(resp.body);
        if (parsed is List) {
          setState(() {
            _leads = parsed
                .map<MeusLeadsModel>((e) =>
                    MeusLeadsModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          });
        } else {
          setState(() => _leads = []);
        }
      } else {
        debugPrint("Status ${resp.statusCode} - ${resp.body}");
        setState(() => _leads = []);
      }
    } catch (e, st) {
      debugPrint("Erro: $e\n$st");
      setState(() => _leads = []);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarDetalhes(MeusLeadsModel lead) {
    // Mantém o mesmo código do seu modal
  }

  Widget _sectionTitle(String text) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kPrimary));

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: kPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, height: 1.3),
                  children: [
                    TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_carregandoToken) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meus Leads'),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _buscaCtrl,
                focusNode: _buscaFocus,
                textInputAction: TextInputAction.search,
                onChanged: _buscarLeads,
                onSubmitted: _buscarLeadsInternal,
                onTap: () => setState(() => _primeiraVez = false),
                decoration: InputDecoration(
                  labelText: 'Buscar',
                  hintText: 'Nome, categoria, estado ou rua...',
                  prefixIcon: const Icon(Icons.search, color: kPrimary),
                  enabledBorder: themeInputBorder,
                  focusedBorder: themeInputBorder.copyWith(
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _primeiraVez
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.search, size: 64, color: Colors.black26),
                            SizedBox(height: 8),
                            Text("Digite para buscar seus leads", style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      )
                    : _carregando
                        ? const Center(child: CircularProgressIndicator())
                        : _leads.isEmpty
                            ? const Center(child: Text("Nenhum lead encontrado.", style: TextStyle(color: Colors.black54)))
                            : ListView.separated(
                                itemCount: _leads.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final lead = _leads[index];
                                  final e = lead.endereco;
                                  final avatarLetter = lead.nomeLocalOrDash.characters.first.toUpperCase();

                                  return Card(
                                    elevation: 0,
                                    color: const Color(0xFFF7F7F7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                                    ),
                                    child: ListTile(
                                      onTap: () => _mostrarDetalhes(lead),
                                      leading: CircleAvatar(
                                        backgroundColor: const Color(0xFFFFEBEE),
                                        child: Text(avatarLetter,
                                            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(lead.nomeLocalOrDash, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text("${e.ruaOrDash}, ${e.numeroOrDash} - ${e.cidadeOrDash}/${e.estadoOrDash}",
                                          style: const TextStyle(color: Colors.black87)),
                                      trailing: const Icon(Icons.chevron_right),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------------
/// MODELS
/// ------------------------------------------------------------------

class MeusLeadsModel {
  final int? idLead;
  final String? nomeLocal;
  final String? categoriaVenda;
  final String? estadoLead;
  final int? idLocalizacao;
  final Endereco endereco;
  final String? nomeConsultor;
  final String? nomeResponsavel;
  final String? ultimaVisita;
  final String? previsaoContato;
  final String? dataCriacao;
  final double? valorProposta;
  final String? observacoes;

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

  factory MeusLeadsModel.fromJson(Map<String, dynamic> json) {
    final endereco = Endereco.fromJson(Map<String, dynamic>.from(json['endereco'] ?? {}));
    final valor = json['valor_proposta'] != null ? double.tryParse(json['valor_proposta'].toString()) : null;

    return MeusLeadsModel(
      idLead: json['id_lead'] is int ? json['id_lead'] : int.tryParse(json['id_lead']?.toString() ?? ""),
      nomeLocal: json['nome_local']?.toString(),
      categoriaVenda: json['categoria_venda']?.toString(),
      estadoLead: json['estado_leads']?.toString() ?? json['estado_lead']?.toString(),
      idLocalizacao: json['id_localizacao'] is int ? json['id_localizacao'] : int.tryParse(json['id_localizacao']?.toString() ?? ""),
      endereco: endereco,
      nomeConsultor: json['nome_consultor']?.toString(),
      nomeResponsavel: json['nome_responsavel']?.toString(),
      ultimaVisita: json['ultima_visita']?.toString(),
      previsaoContato: json['previsao_contato']?.toString(),
      dataCriacao: json['data_criacao']?.toString(),
      valorProposta: valor,
      observacoes: json['observacoes']?.toString(),
    );
  }

  String get nomeLocalOrDash => (nomeLocal?.trim().isEmpty ?? true) ? "-" : nomeLocal!;
  String get nomeConsultorOrDash => (nomeConsultor?.trim().isEmpty ?? true) ? "-" : nomeConsultor!;
  String get nomeResponsavelOrDash => (nomeResponsavel?.trim().isEmpty ?? true) ? "-" : nomeResponsavel!;
  String get estadoLeadOrDash => (estadoLead?.trim().isEmpty ?? true) ? "-" : estadoLead!;
  String get dataCriacaoFormatted => _formatDateSafe(dataCriacao);
  String get ultimaVisitaFormatted => _formatDateSafe(ultimaVisita);

  static String _formatDateSafe(String? iso) {
    if (iso == null) return "-";
    try {
      final dt = DateTime.parse(iso);
      return "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}";
    } catch (_) {
      return iso;
    }
  }
}

class Endereco {
  final String? rua, numero, complemento, cidade, estado, pais;

  Endereco({this.rua, this.numero, this.complemento, this.cidade, this.estado, this.pais});

  factory Endereco.fromJson(Map<String, dynamic> json) => Endereco(
        rua: json['rua']?.toString(),
        numero: json['numero']?.toString(),
        complemento: json['complemento']?.toString(),
        cidade: json['cidade']?.toString(),
        estado: json['estado']?.toString(),
        pais: json['pais']?.toString(),
      );

  String get ruaOrDash => (rua?.trim().isEmpty ?? true) ? "-" : rua!;
  String get numeroOrDash => (numero?.trim().isEmpty ?? true) ? "-" : numero!;
  String get cidadeOrDash => (cidade?.trim().isEmpty ?? true) ? "-" : cidade!;
  String get estadoOrDash => (estado?.trim().isEmpty ?? true) ? "-" : estado!;
  String get paisOrDash => (pais?.trim().isEmpty ?? true) ? "-" : pais!;
  String get complementoOrEmpty => (complemento?.trim().isEmpty ?? true) ? "" : " - $complemento";
}
