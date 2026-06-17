import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

const _kPrimary = Color(0xFFD32F2F);

// ─────────────────────────────────────────────────────────────────────────────
// Modelos
// ─────────────────────────────────────────────────────────────────────────────

class VisitaModel {
  final int     idVisita;
  final int     idLeads;
  final int     idUsuario;
  final String? dataVisita;
  final String? proximaVisita;
  final String? observacao;
  final double  valorAcordado;
  final String? nomeUsuario;

  VisitaModel({
    required this.idVisita,
    required this.idLeads,
    required this.idUsuario,
    this.dataVisita,
    this.proximaVisita,
    this.observacao,
    required this.valorAcordado,
    this.nomeUsuario,
  });

  factory VisitaModel.fromJson(Map<String, dynamic> j) => VisitaModel(
    idVisita: int.tryParse('${j['id_visita']}') ?? 0,
    idLeads: int.tryParse('${j['id_lead']}') ?? 0,
    idUsuario: int.tryParse('${j['id_usuario']}') ?? 0,
    dataVisita:    j['data_visita']    as String?,
    proximaVisita: j['proxima_visita'] as String?,
    observacao:    j['observacao']     as String?,
    valorAcordado: (j['valor_acordado'] as num? ?? 0).toDouble(),
    nomeUsuario:   j['nome_usuario']   as String?,
  );

  String get dataFormatada    => _fmt(dataVisita);
  String get proximaFormatada => _fmt(proximaVisita);

  static String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) { return iso; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tela principal
// ─────────────────────────────────────────────────────────────────────────────

class VisitasPage extends StatefulWidget {
  final int    idLead;
  final String nomeLocal;
  final int?   idLocalizacao;

  const VisitasPage({
    super.key,
    required this.idLead,
    required this.nomeLocal,
    this.idLocalizacao,
  });

  @override
  State<VisitasPage> createState() => _VisitasPageState();
}

class _VisitasPageState extends State<VisitasPage> {
  List<VisitaModel> _visitas   = [];
  bool   _loading = true;
  String? _token;
  int?   _idUsuario;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    // decodifica payload do JWT para pegar id_usuario
    if (_token != null) {
      try {
        final parts   = _token!.split('.');
        final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        _idUsuario = payload['id_usuario'] as int?;
      } catch (_) {}
    }
    await _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(
        Uri.parse('$kBaseUrl/lead/${widget.idLead}/visitas'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _visitas = (data['visitas'] as List)
              .map((v) => VisitaModel.fromJson(v as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      _msg('Erro ao carregar visitas: $e', erro: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _msg(String t, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t),
      backgroundColor: erro ? Colors.red : Colors.green,
    ));
  }

  // ── Nova / Editar visita ──────────────────────────────────────────────────
  void _abrirFormVisita([VisitaModel? existente]) {
    final dataCtrl    = TextEditingController(text: existente?.dataVisita    ?? '');
    final proximaCtrl = TextEditingController(text: existente?.proximaVisita ?? '');
    final obsCtrl     = TextEditingController(text: existente?.observacao    ?? '');
    final valorCtrl   = TextEditingController(
        text: existente != null && existente.valorAcordado > 0
            ? existente.valorAcordado.toStringAsFixed(2)
            : '');

    DateTime? dataVisita    = existente?.dataVisita    != null ? DateTime.tryParse(existente!.dataVisita!)    : null;
    DateTime? proximaVisita = existente?.proximaVisita != null ? DateTime.tryParse(existente!.proximaVisita!) : null;
    bool salvando = false;

    Future<void> pickDate(BuildContext ctx, bool isData) async {
      final inicial = isData ? dataVisita : proximaVisita;
      final picked  = await showDatePicker(
        context: ctx,
        initialDate: inicial ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
        builder: (c, w) => Theme(
          data: ThemeData(colorScheme: const ColorScheme.light(primary: _kPrimary)),
          child: w!,
        ),
      );
      if (picked == null) return;
      final time = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(inicial ?? DateTime.now()),
      );
      final dt = time == null
          ? picked
          : DateTime(picked.year, picked.month, picked.day,
                     time.hour, time.minute);
      if (isData) {
        dataVisita = dt;
        dataCtrl.text = dt.toIso8601String();
      } else {
        proximaVisita = dt;
        proximaCtrl.text = dt.toIso8601String();
      }
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final focusBorder = border.copyWith(
        borderSide: const BorderSide(color: _kPrimary, width: 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(existente == null ? 'Nova Visita' : 'Editar Visita',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Data da visita
                GestureDetector(
                  onTap: () => pickDate(ctx, true).then((_) => setSheet(() {})),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: TextEditingController(
                        text: dataVisita != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(dataVisita!)
                            : ''),
                      decoration: InputDecoration(
                        labelText: 'Data da visita *',
                        prefixIcon: const Icon(Icons.calendar_today, color: _kPrimary),
                        enabledBorder: border, focusedBorder: focusBorder,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Próxima visita
                GestureDetector(
                  onTap: () => pickDate(ctx, false).then((_) => setSheet(() {})),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: TextEditingController(
                        text: proximaVisita != null
                            ? DateFormat('dd/MM/yyyy HH:mm').format(proximaVisita!)
                            : ''),
                      decoration: InputDecoration(
                        labelText: 'Próxima visita',
                        prefixIcon: const Icon(Icons.event, color: _kPrimary),
                        enabledBorder: border, focusedBorder: focusBorder,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Valor acordado
                TextFormField(
                  controller: valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor acordado (R\$)',
                    prefixIcon: const Icon(Icons.attach_money, color: _kPrimary),
                    enabledBorder: border, focusedBorder: focusBorder,
                  ),
                ),
                const SizedBox(height: 14),

                // Observação
                TextFormField(
                  controller: obsCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Observação',
                    prefixIcon: const Icon(Icons.notes, color: _kPrimary),
                    alignLabelWithHint: true,
                    enabledBorder: border, focusedBorder: focusBorder,
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: salvando ? null : () async {
                    if (dataVisita == null) {
                      _msg('Informe a data da visita', erro: true);
                      return;
                    }
                    setSheet(() => salvando = true);
                    final body = jsonEncode({
                      'data_visita':    dataVisita!.toIso8601String(),
                      'proxima_visita': proximaVisita?.toIso8601String(),
                      'observacao':     obsCtrl.text.trim(),
                      'valor_acordado': double.tryParse(
                          valorCtrl.text.replaceAll(',', '.')) ?? 0.0,
                    });

                    try {
                      http.Response resp;
                      if (existente == null) {
                        resp = await http.post(
                          Uri.parse('$kBaseUrl/lead/${widget.idLead}/visita'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $_token',
                          },
                          body: body,
                        );
                      } else {
                        resp = await http.put(
                          Uri.parse('$kBaseUrl/visita/${existente.idVisita}'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $_token',
                          },
                          body: body,
                        );
                      }
                      Navigator.pop(ctx);
                      if (resp.statusCode == 200 || resp.statusCode == 201) {
                        _msg(existente == null
                            ? 'Visita registrada!' : 'Visita atualizada!');
                        _carregar();
                      } else {
                        final d = jsonDecode(resp.body);
                        _msg(d['mensagem'] ?? 'Erro', erro: true);
                      }
                    } catch (e) {
                      _msg('Erro de conexão: $e', erro: true);
                    } finally {
                      setSheet(() => salvando = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: salvando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(existente == null ? 'Registrar Visita' : 'Salvar',
                          style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Confirmar venda ───────────────────────────────────────────────────────
  void _confirmarVenda() {
    if (widget.idLocalizacao == null) {
      _msg('Lead sem localização cadastrada', erro: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Venda',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Deseja confirmar a venda de "${widget.nomeLocal}"?\n\n'
            'O lead será marcado como FECHADO.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final resp = await http.post(
                  Uri.parse('$kBaseUrl/lead/${widget.idLead}/confirmar_venda'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $_token',
                  },
                  body: jsonEncode(
                      {'id_localizacao': widget.idLocalizacao}),
                );
                if (resp.statusCode == 201) {
                  _msg('🎉 Venda confirmada com sucesso!');
                  _carregar();
                } else {
                  final d = jsonDecode(resp.body);
                  _msg(d['mensagem'] ?? 'Erro', erro: true);
                }
              } catch (e) {
                _msg('Erro de conexão: $e', erro: true);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Confirmar Venda'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Visitas',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            Text(widget.nomeLocal,
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botão confirmar venda
          TextButton.icon(
            onPressed: _confirmarVenda,
            icon: const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18),
            label: const Text('Venda',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : _visitas.isEmpty
              ? _buildVazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _visitas.length,
                    itemBuilder: (_, i) => _buildCard(_visitas[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormVisita(),
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nova Visita'),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Nenhuma visita registrada',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _abrirFormVisita(),
            icon: const Icon(Icons.add),
            label: const Text('Registrar primeira visita'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(VisitaModel v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today,
                    color: _kPrimary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.dataFormatada,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    if (v.nomeUsuario != null)
                      Text(v.nomeUsuario!,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              if (v.valorAcordado > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'R\$ ${v.valorAcordado.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
            ]),

            if (v.observacao != null && v.observacao!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(v.observacao!,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            ],

            if (v.proximaVisita != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.event_available,
                    size: 14, color: Colors.orange.shade600),
                const SizedBox(width: 6),
                Text('Próxima visita: ${v.proximaFormatada}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500)),
              ]),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Botão editar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirFormVisita(v),
                icon: const Icon(Icons.edit_outlined,
                    size: 15, color: _kPrimary),
                label: const Text('Editar visita',
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