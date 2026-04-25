import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/lead_gestor.dart';
import 'models/usuario_consultor.dart';
import '../constants.dart';

const _kPrimary = Color(0xFFD32F2F);
const _kBase    = '$kBaseUrl';

class GerenciarLeadsPage extends StatefulWidget {
  const GerenciarLeadsPage({super.key});

  @override
  State<GerenciarLeadsPage> createState() => _GerenciarLeadsPageState();
}

class _GerenciarLeadsPageState extends State<GerenciarLeadsPage> {
  List<LeadGestor>        _leads       = [];
  List<LeadGestor>        _filtrados   = [];
  List<UsuarioConsultor>  _consultores = [];
  bool   _loading = true;
  String? _token;
  String  _busca  = '';
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
      final resp = await http.get(
        Uri.parse('$_kBase/gestor/leads'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _leads = (data['leads'] as List)
            .map((l) => LeadGestor.fromJson(l))
            .toList();
        _aplicarFiltro();
      } else {
        _showMsg('Erro ao carregar leads', erro: true);
      }
    } catch (e) {
      _showMsg('Erro de conexão: $e', erro: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _carregarConsultores() async {
    try {
      final resp = await http.get(
        Uri.parse('$_kBase/gestor/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _consultores = (data['usuarios'] as List)
              .map((u) => UsuarioConsultor.fromJson(u))
              .toList();
        });
      }
    } catch (_) {}
  }

  void _aplicarFiltro() {
    setState(() {
      _filtrados = _leads.where((l) {
        final matchBusca = _busca.isEmpty ||
            l.nomeLocal.toLowerCase().contains(_busca.toLowerCase()) ||
            l.nomeResponsavel.toLowerCase().contains(_busca.toLowerCase()) ||
            l.nomeConsultor.toLowerCase().contains(_busca.toLowerCase());
        final matchEstado = _filtroEstado == 'Todos' || l.estadoLeads == _filtroEstado;
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

  // ── Trocar consultor ──────────────────────────────────────────────────────
  void _abrirTrocarConsultor(LeadGestor lead) {
    if (_consultores.isEmpty) {
      _showMsg('Nenhum consultor disponível', erro: true);
      return;
    }

    UsuarioConsultor? selecionado = _consultores
        .where((c) => c.idUsuario == lead.idUsuario)
        .firstOrNull;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trocar Consultor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(lead.nomeLocal,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal)),
            ],
          ),
          content: DropdownButtonFormField<UsuarioConsultor>(
            value: selecionado,
            decoration: InputDecoration(
              labelText: 'Consultor',
              prefixIcon: const Icon(Icons.person, color: _kPrimary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _consultores.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c.nomeUsuario),
            )).toList(),
            onChanged: (v) => setDialog(() => selecionado = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selecionado == null ? null : () async {
                Navigator.pop(ctx);
                try {
                  final resp = await http.put(
                    Uri.parse('$_kBase/gestor/lead/${lead.idLeads}/trocar_consultor'),
                    headers: {
                      'Content-Type': 'application/json',
                      if (_token != null) 'Authorization': 'Bearer $_token',
                    },
                    body: jsonEncode({'id_usuario': selecionado!.idUsuario}),
                  );
                  if (resp.statusCode == 200) {
                    _showMsg('Consultor trocado com sucesso!');
                    _carregarLeads();
                  } else {
                    final data = jsonDecode(resp.body);
                    _showMsg(data['mensagem'] ?? 'Erro', erro: true);
                  }
                } catch (e) {
                  _showMsg('Erro de conexão: $e', erro: true);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cores/labels de estado ────────────────────────────────────────────────
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregarLeads),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de busca e filtro ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Busca
                TextField(
                  onChanged: (v) { _busca = v; _aplicarFiltro(); },
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
                // Filtro estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', 'aberta', 'conexao', 'negociacao', 'fechada']
                        .map((e) {
                      final sel = _filtroEstado == e;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_estadoLabel(e) == 'Aberta' && e == 'Todos'
                              ? 'Todos' : _estadoLabel(e)),
                          selected: sel,
                          onSelected: (_) { _filtroEstado = e; _aplicarFiltro(); },
                          selectedColor: _kPrimary.withOpacity(0.15),
                          checkmarkColor: _kPrimary,
                          labelStyle: TextStyle(
                            color: sel ? _kPrimary : Colors.grey.shade700,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
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
            child: Row(
              children: [
                Text('${_filtrados.length} lead${_filtrados.length != 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kPrimary))
                : _filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Nenhum lead encontrado',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarLeads,
                        color: _kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) => _buildCard(_filtrados[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(LeadGestor lead) {
    final estadoCor   = _estadoCor(lead.estadoLeads);
    final estadoLabel = _estadoLabel(lead.estadoLeads);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1: empresa + estado
            Row(
              children: [
                Expanded(
                  child: Text(lead.nomeLocal,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoCor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(estadoLabel,
                      style: TextStyle(
                          fontSize: 11, color: estadoCor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Responsável
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(lead.nomeResponsavel,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ]),
            const SizedBox(height: 4),

            // Linha consultor + valor
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(lead.nomeConsultor,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (lead.valorProposta != null)
                  Text(
                    'R\$ ${lead.valorProposta!.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green),
                  ),
              ],
            ),

            // Data + categoria
            if (lead.dataCriacao != null || lead.categoriaVenda != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (lead.dataCriacao != null) ...[
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(lead.dataCriacao!.substring(0, 10),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(width: 12),
                ],
                if (lead.categoriaVenda != null) ...[
                  Icon(Icons.category, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(lead.categoriaVenda!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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