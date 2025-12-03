// ===============================================================
//   MEUS LEADS  -  FRONT + BACK INTEGRADO
//   Usa o layout completo do seu primeiro exemplo
//   e consome a API real com token + GET /meus_leads
// ===============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './models/usuario_logado.dart';

const kPrimary = Color(0xFFD32F2F);

class BuscarLead extends StatefulWidget {
  const BuscarLead({super.key});

  @override
  State<BuscarLead> createState() => _MeusLeadsState();
}

class _MeusLeadsState extends State<BuscarLead> {
  String? _token;
  bool _carregandoToken = true;

  final TextEditingController _buscaCtrl = TextEditingController();
  final FocusNode _buscaFocus = FocusNode();

  List<MeusLeadsModel> _leads = [];
  bool _carregando = false;
  bool _primeiraVez = true;

  Timer? _debounce;
  static const String baseUrl = "http://192.168.0.3:5000";

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
      _token = usuario.token;
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

  // ---------------- BUSCA ----------------
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (value.trim().isNotEmpty) _buscarLeadsInternal(value.trim());
    });
  }

  Future<void> _buscarLeads(String termo) async {
    setState(() => _primeiraVez = false);
    _onSearchChanged(termo);
  }

  Future<void> _buscarLeadsInternal(String termo) async {
    if (_token == null || termo.isEmpty) {
      setState(() => _leads = []);
      return;
    }

    setState(() => _carregando = true);

    try {
      final url = Uri.parse(
        "$baseUrl/all_leads?query=${Uri.encodeQueryComponent(termo)}",
      );

      final resp = await http.get(
        url,
        headers: {"Authorization": "Bearer $_token"},
      );

      print("========== RESPOSTA API ==========");
      print("URL: $url");
      print("STATUS: ${resp.statusCode}");
      print("BODY: ${resp.body}");
      print("===================================");

      if (resp.statusCode == 200) {
        final parsed = jsonDecode(resp.body);
        if (parsed is List) {
          setState(() {
            _leads = parsed
                .map<MeusLeadsModel>(
                  (e) => MeusLeadsModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
          });
        }
      } else {
        setState(() => _leads = []);
      }
    } catch (e) {
      setState(() => _leads = []);
    } finally {
      setState(() => _carregando = false);
    }
  }

  // ---------------- MODAL DETALHES ----------------
  void _mostrarDetalhes(MeusLeadsModel lead) {
    final e = lead.endereco;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          maxChildSize: 0.95,
          minChildSize: 0.25,
          expand: false,
          builder: (_, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Arraste para cima para mais detalhes",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Icon(Icons.business, size: 28, color: kPrimary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lead.nomeLocalOrDash,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),

                    _sectionTitle("Informações Gerais"),
                    const SizedBox(height: 10),

                    _infoRow(
                      Icons.location_on,
                      "Endereço",
                      "${e.ruaOrDash}, ${e.numeroOrDash}${e.complementoOrEmpty}\n${e.cidadeOrDash}/${e.estadoOrDash} - ${e.paisOrDash}",
                    ),

                    _infoRow(
                      Icons.person,
                      "Consultor",
                      lead.nomeConsultorOrDash,
                    ),

                    _infoRow(
                      Icons.badge,
                      "Responsável",
                      lead.nomeResponsavelOrDash,
                    ),

                    _infoRow(
                      Icons.flag,
                      "Estado do Lead",
                      lead.estadoLeadOrDash,
                    ),

                    if (lead.valorProposta != null)
                      _infoRow(
                        Icons.attach_money,
                        "Proposta",
                        "R\$ ${lead.valorProposta!.toStringAsFixed(2)}",
                      ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),

                    _sectionTitle("Datas"),
                    const SizedBox(height: 10),

                    _infoRow(
                      Icons.calendar_today,
                      "Criado em",
                      lead.dataCriacaoFormatted,
                    ),

                    if (lead.previsaoContato != null)
                      _infoRow(
                        Icons.schedule,
                        "Previsão de contato",
                        lead.previsaoContato ?? "-",
                      ),

                    _infoRow(
                      Icons.update,
                      "Última visita",
                      lead.ultimaVisitaFormatted,
                    ),

                    if (lead.observacoes != null &&
                        lead.observacoes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionTitle("Observações"),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          lead.observacoes!,
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------ COMPONENTES DE UI ------------
  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      color: kPrimary,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  //                       BUILD
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    if (_carregandoToken) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _buscaCtrl,
                focusNode: _buscaFocus,
                onChanged: _buscarLeads,
                decoration: InputDecoration(
                  labelText: "Buscar",
                  hintText: "Nome, categoria, estado, rua...",
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
                    ? _telaInicial()
                    : _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _leads.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum lead encontrado",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : _listaLeads(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telaInicial() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search, size: 64, color: Colors.black26),
          SizedBox(height: 10),
          Text(
            "Digite algo para buscar seus leads",
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _listaLeads() {
    return ListView.separated(
      itemCount: _leads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final l = _leads[i];
        final e = l.endereco;
        final letra = l.nomeLocalOrDash.characters.first.toUpperCase();

        return Card(
          elevation: 0,
          color: const Color(0xFFF7F7F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFEBEE),
              child: Text(
                letra,
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              l.nomeLocalOrDash,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${e.ruaOrDash}, ${e.numeroOrDash} - ${e.cidadeOrDash}/${e.estadoOrDash}",
              style: const TextStyle(color: Colors.black87),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

// ===============================================================
//                        MODELS
// ===============================================================

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

  factory MeusLeadsModel.fromJson(Map<String, dynamic> j) {
    return MeusLeadsModel(
      idLead: _toInt(j["id_lead"]),
      nomeLocal: j["nome_local"]?.toString(),
      categoriaVenda: j["categoria_venda"]?.toString(),
      estadoLead: j["estado_leads"]?.toString(),
      idLocalizacao: _toInt(j["id_localizacao"]),
      endereco: Endereco.fromJson(j),
      nomeConsultor: j["nome_consultor"]?.toString(),
      nomeResponsavel: j["nome_responsavel"]?.toString(),
      ultimaVisita: j["ultima_visita"]?.toString(),
      previsaoContato: j["previsao_contato"]?.toString(),
      dataCriacao: j["data_criacao"]?.toString(),
      valorProposta: j["valor_proposta"] == null
          ? null
          : double.tryParse(j["valor_proposta"].toString()),
      observacoes: j["observacoes"]?.toString(),
    );
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? "");
  }

  String get nomeLocalOrDash =>
      (nomeLocal?.trim().isEmpty ?? true) ? "-" : nomeLocal!;

  String get nomeConsultorOrDash =>
      (nomeConsultor?.trim().isEmpty ?? true) ? "-" : nomeConsultor!;

  String get nomeResponsavelOrDash =>
      (nomeResponsavel?.trim().isEmpty ?? true) ? "-" : nomeResponsavel!;

  String get estadoLeadOrDash =>
      (estadoLead?.trim().isEmpty ?? true) ? "-" : estadoLead!;

  String get dataCriacaoFormatted => _format(dataCriacao);

  String get ultimaVisitaFormatted => _format(ultimaVisita);

  static String _format(String? iso) {
    if (iso == null) return "-";
    try {
      final dt = DateTime.parse(iso);
      return "${dt.day.toString().padLeft(2, "0")}/${dt.month.toString().padLeft(2, "0")}/${dt.year}";
    } catch (_) {
      return iso;
    }
  }
}

class Endereco {
  final String? rua, numero, complemento, cidade, estado, pais;

  Endereco({
    this.rua,
    this.numero,
    this.complemento,
    this.cidade,
    this.estado,
    this.pais,
  });

  factory Endereco.fromJson(Map<String, dynamic> j) {
    return Endereco(
      rua: j["nome_rua"]?.toString(),
      numero: j["numero"]?.toString(),
      complemento: j["complemento"]?.toString(),
      cidade: j["nome_cidade"]?.toString(),
      estado: j["uf"]?.toString(),
      pais: "-",
    );
  }

  String get ruaOrDash => _val(rua);
  String get numeroOrDash => _val(numero);
  String get cidadeOrDash => _val(cidade);
  String get estadoOrDash => _val(estado);
  String get paisOrDash => _val(pais);

  String get complementoOrEmpty =>
      (complemento?.trim().isEmpty ?? true) ? "" : " - $complemento";

  String _val(String? v) => (v?.trim().isEmpty ?? true) ? "-" : v!;
}
