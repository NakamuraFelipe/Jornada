import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/lead_gestor.dart';
import 'models/usuario_consultor.dart';
import '../constants.dart';

const _kPrimary = Color(0xFFD32F2F);

class GerenciarLeadsPage extends StatefulWidget {
  const GerenciarLeadsPage({super.key});

  @override
  State<GerenciarLeadsPage> createState() => _GerenciarLeadsPageState();
}

class _GerenciarLeadsPageState extends State<GerenciarLeadsPage> {
  List<LeadGestor>       _leads       = [];
  List<LeadGestor>       _filtrados   = [];
  List<UsuarioConsultor> _consultores = [];
  bool    _loading      = true;
  String? _token;
  String  _busca        = '';
  String  _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await Future.wait([_carregarLeads(), _carregarConsultores()]);
  }

  Future<void> _carregarLeads() async {
  setState(() => _loading = true);

  try {
    debugPrint('URL FINAL: ${'$kBaseUrl/gestor/lead'}');
    final resp = await http.get(
      Uri.parse('$kBaseUrl/gestor/lead'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );

    debugPrint('[GerenciarLead] GET /gestor/lead → ${resp.statusCode}');
    debugPrint('[GerenciarLead] Body: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);

      final lista = data['leads'] as List? ?? [];

      setState(() {
        _leads = lista
            .map((l) => LeadGestor.fromJson(l as Map<String, dynamic>))
            .toList();
      });

      _aplicarFiltro();
    } else {
      _showMsg(
        'Erro ${resp.statusCode} ao carregar leads',
        erro: true,
      );
    }
  } catch (e) {
    debugPrint('[GerenciarLead] Erro: $e');

    _showMsg(
      'Erro de conexão',
      erro: true,
    );
  } finally {
    setState(() => _loading = false);
  }
}

  Future<void> _carregarConsultores() async {
    try {
      final resp = await http.get(
        Uri.parse('$kBaseUrl/gestor/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
      debugPrint('[GerenciarLead] GET /gestor/usuarios → ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final lista = data['usuarios'] as List? ?? [];
        setState(() {
          _consultores = lista
              .map((u) => UsuarioConsultor.fromJson(u as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('[GerenciarLead] Erro consultores: $e');
    }
  }

  void _aplicarFiltro() {
    setState(() {
      _filtrados = _leads.where((l) {
        final q = _busca.toLowerCase();
        final matchBusca = q.isEmpty ||
            l.nomeLocal.toLowerCase().contains(q) ||
            l.nomeResponsavel.toLowerCase().contains(q) ||
            l.nomeConsultor.toLowerCase().contains(q);
        final matchEstado =
            _filtroEstado == 'Todos' || l.estadoLead == _filtroEstado;
        return matchBusca && matchEstado;
      }).toList();
    });
  }

  void _showMsg(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? Colors.red : Colors.green,
    ));
  }

  void _abrirTrocarConsultor(LeadGestor lead) {
    if (_consultores.isEmpty) {
      _showMsg('Nenhum consultor disponível. Recarregue a página.', erro: true);
      return;
    }

    UsuarioConsultor? selecionado;
    try {
      selecionado =
          _consultores.firstWhere((c) => c.idUsuario == lead.idUsuario);
    } catch (_) {
      selecionado = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Trocar Consultor',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                lead.nomeLocal,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          content: DropdownButtonFormField<UsuarioConsultor>(
            value: selecionado,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Selecione o consultor',
              prefixIcon: const Icon(Icons.person, color: _kPrimary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary, width: 2),
              ),
            ),
            items: _consultores
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.nomeUsuario,
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setDialog(() => selecionado = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selecionado == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _trocarConsultor(lead, selecionado!);
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _trocarConsultor(
      LeadGestor lead, UsuarioConsultor novoConsultor) async {
    try {
      final resp = await http.put(
        Uri.parse('$kBaseUrl/gestor/lead/${lead.idLead}/trocar_consultor'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'id_usuario': novoConsultor.idUsuario}),
      );

      debugPrint('[GerenciarLeads] PUT trocar_consultor → ${resp.statusCode}');

      if (resp.statusCode == 200) {
        _showMsg(
            'Lead "${lead.nomeLocal}" transferido para ${novoConsultor.nomeUsuario}!');
        await _carregarLeads();
      } else {
        final data = jsonDecode(resp.body);
        _showMsg(data['mensagem'] ?? 'Erro ao trocar consultor', erro: true);
      }
    } catch (e) {
      _showMsg('Erro de conexão: $e', erro: true);
    }
  }

  Color _estadoCor(String estado) {
    switch (estado) {
      case 'fechada':    return Colors.green;
      case 'negociacao': return Colors.blue;
      case 'conexao':    return Colors.orange;
      default:           return Colors.grey;
    }
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'fechada':    return 'Fechada';
      case 'negociacao': return 'Negociação';
      case 'conexao':    return 'Conexão';
      default:           return 'Aberta';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Gerenciar Leads',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Future.wait([_carregarLeads(), _carregarConsultores()]);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Busca + filtro ───────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    _busca = v;
                    _aplicarFiltro();
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por empresa, responsável ou consultor...',
                    prefixIcon: const Icon(Icons.search, color: _kPrimary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', 'aberta', 'conexao', 'negociacao', 'fechada']
                        .map((e) {
                      final sel = _filtroEstado == e;
                      final label = e == 'Todos' ? 'Todos' : _estadoLabel(e);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(label),
                          selected: sel,
                          onSelected: (_) {
                            setState(() => _filtroEstado = e);
                            _aplicarFiltro();
                          },
                          selectedColor: _kPrimary.withOpacity(0.15),
                          checkmarkColor: _kPrimary,
                          labelStyle: TextStyle(
                            color: sel ? _kPrimary : Colors.grey.shade700,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Contador ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Text(
                '${_filtrados.length} lead${_filtrados.length != 1 ? 's' : ''}',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              if (_consultores.isNotEmpty) ...[
                const Spacer(),
                Text(
                  '${_consultores.length} consultor${_consultores.length != 1 ? 'es' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ]),
          ),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : _filtrados.isEmpty
                    ? _buildVazio()
                    : RefreshIndicator(
                        onRefresh: _carregarLeads,
                        color: _kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) => _buildCard(_filtrados[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _leads.isEmpty
                ? 'Nenhum lead encontrado para seus consultores'
                : 'Nenhum lead corresponde ao filtro',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _carregarLeads,
            icon: const Icon(Icons.refresh, color: _kPrimary),
            label: const Text('Recarregar',
                style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(LeadGestor lead) {
    final cor   = _estadoCor(lead.estadoLead);
    final label = _estadoLabel(lead.estadoLead);

    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Empresa + estado
            Row(children: [
              Expanded(
                child: Text(lead.nomeLocal,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),

            // Responsável
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(lead.nomeResponsavel,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            const SizedBox(height: 4),

            // Consultor + valor acordado
            Row(children: [
              Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lead.nomeConsultor.isNotEmpty
                      ? lead.nomeConsultor
                      : 'Sem consultor',
                  style: TextStyle(
                      fontSize: 13,
                      color: lead.nomeConsultor.isNotEmpty
                          ? Colors.grey.shade700
                          : Colors.red.shade300,
                      fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // ✅ valorAcordado (da tabela VISITA)
              if (lead.valorAcordado != null && lead.valorAcordado! > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'R\$ ${lead.valorAcordado!.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green),
                ),
              ],
            ]),

            // Data + categoria
            if (lead.dataCriacao != null || lead.categoriaVenda != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (lead.dataCriacao != null) ...[
                  Icon(Icons.calendar_today,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    lead.dataCriacao!.length >= 10
                        ? lead.dataCriacao!.substring(0, 10)
                        : lead.dataCriacao!,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 12),
                ],
                if (lead.categoriaVenda != null) ...[
                  Icon(Icons.category, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(lead.categoriaVenda!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ]),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Botão trocar consultor
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirTrocarConsultor(lead),
                icon: const Icon(Icons.swap_horiz, size: 16, color: _kPrimary),
                label: const Text('Trocar Consultor',
                    style: TextStyle(fontSize: 13, color: _kPrimary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}