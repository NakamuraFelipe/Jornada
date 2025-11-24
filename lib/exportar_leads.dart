import 'package:flutter/material.dart';

const kPrimary = Color(0xFFD32F2F);

class ExportarLeads extends StatefulWidget {
  const ExportarLeads({super.key});

  @override
  State<ExportarLeads> createState() => _ExportarLeadsState();
}

class _ExportarLeadsState extends State<ExportarLeads> {
  final _buscaCtrl = TextEditingController();
  final List<_SampleLead> _itens = [
    _SampleLead(nomelead: 'Maria Silva', nomeconsultor: 'Lucas Ferreira'),
    _SampleLead(nomelead: 'Comercial Almeida', nomeconsultor: 'Andre Henrique'),
    _SampleLead(nomelead: 'João Pereira', nomeconsultor: 'Mariana Costa'),
  ];

  final Set<_SampleLead> _selecionados = {};

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  bool _match(_SampleLead lead, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();
    return lead.nomelead.toLowerCase().contains(q) ||
        lead.nomeconsultor.toLowerCase().contains(q);
  }

  void _exportarSelecionados() {
    if (_selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum lead selecionado.'),
          backgroundColor: kPrimary,
        ),
      );
      return;
    }

    // Converter em JSON simples
    final List<Map<String, String>> jsonList = _selecionados
        .map(
          (lead) => {
            'nomelead': lead.nomelead,
            'nomeconsultor': lead.nomeconsultor,
          },
        )
        .toList();

    print('JSON exportado: $jsonList');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leads exportados no console.'),
        backgroundColor: kPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itensFiltrados = _itens
        .where((l) => _match(l, _buscaCtrl.text))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Leads'),
        foregroundColor: Colors.white,

        backgroundColor: kPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Busca
            TextField(
              controller: _buscaCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Buscar',
                hintText: 'Nome ou consultor...',
                prefixIcon: const Icon(Icons.search, color: kPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Lista
            Expanded(
              child: itensFiltrados.isEmpty
                  ? const Center(child: Text('Nenhum lead encontrado.'))
                  : ListView.separated(
                      itemCount: itensFiltrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final lead = itensFiltrados[index];
                        final selecionado = _selecionados.contains(lead);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            value: selecionado,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selecionados.add(lead);
                                } else {
                                  _selecionados.remove(lead);
                                }
                              });
                            },
                            title: Text(lead.nomelead),
                            subtitle: Text('Consultor: ${lead.nomeconsultor}'),
                          ),
                        );
                      },
                    ),
            ),
            // Botão de exportar
            ElevatedButton.icon(
              onPressed: _exportarSelecionados,
              icon: const Icon(Icons.download),
              label: const Text('Exportar selecionados'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleLead {
  final String nomelead;
  final String nomeconsultor;

  _SampleLead({required this.nomelead, required this.nomeconsultor});

  // Para Set e CheckboxListTile funcionar corretamente
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SampleLead &&
          runtimeType == other.runtimeType &&
          nomelead == other.nomelead &&
          nomeconsultor == other.nomeconsultor;

  @override
  int get hashCode => nomelead.hashCode ^ nomeconsultor.hashCode;
}
