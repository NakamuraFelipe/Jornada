import 'package:flutter/material.dart';

const kPrimary = Color(0xFFD32F2F);

class BuscarLead extends StatefulWidget {
  const BuscarLead({super.key});

  @override
  State<BuscarLead> createState() => _BuscarLeadState();
}

class _BuscarLeadState extends State<BuscarLead> {
  final _buscaCtrl = TextEditingController();

  // ==== DADOS ESTÁTICOS (APENAS EXEMPLO) ====
  final List<_SampleLead> _itens = [
    _SampleLead(
      nome: 'Maria Silva',
      categoria: 'Varejo',
      endereco: _SampleAddress(
        pais: 'Brasil',
        estado: 'SP',
        cidade: 'São Paulo',
        rua: 'Av. Paulista',
        numero: '1000',
        complemento: 'Conj. 101',
      ),
      observacao: 'Cliente interessada em prazo estendido.',
    ),
    _SampleLead(
      nome: 'Comercial Almeida',
      categoria: 'Atacado',
      endereco: _SampleAddress(
        pais: 'Brasil',
        estado: 'MG',
        cidade: 'Belo Horizonte',
        rua: 'Rua da Bahia',
        numero: '230',
      ),
    ),
    _SampleLead(
      nome: 'João Pereira',
      endereco: _SampleAddress(
        pais: 'Brasil',
        estado: 'RJ',
        cidade: 'Rio de Janeiro',
        rua: 'Rua das Laranjeiras',
        numero: '45',
      ),
      observacao: 'Prefere contato por WhatsApp de manhã.',
    ),
  ];
  // ===========================================

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  bool _match(_SampleLead lead, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();
    return lead.nome.toLowerCase().contains(q) ||
        lead.endereco.resumo().toLowerCase().contains(q) ||
        (lead.categoria ?? '').toLowerCase().contains(q) ||
        (lead.observacao ?? '').toLowerCase().contains(q);
  }

  void _mostrarDetalhes(_SampleLead lead) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: kPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lead.nome,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (lead.categoria != null)
                  Chip(
                    label: Text(lead.categoria!),
                    backgroundColor: const Color(0xFFFFEBEE),
                    labelStyle: const TextStyle(color: kPrimary),
                    side: const BorderSide(color: kPrimary),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.location_on, color: kPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lead.endereco.descricaoCompleta(),
                    style: const TextStyle(height: 1.3),
                  ),
                ),
              ],
            ),
            if ((lead.observacao ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lead.observacao!,
                      style: const TextStyle(height: 1.3),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    );

    final itensFiltrados = _itens
        .where((l) => _match(l, _buscaCtrl.text))
        .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Buscar Leads '),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar lead'),
          onPressed: () {},
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
                  hintText: 'Nome, endereço, categoria...',
                  prefixIcon: const Icon(Icons.search, color: kPrimary),
                  enabledBorder: themeInputBorder,
                  focusedBorder: themeInputBorder.copyWith(
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Lista
              Expanded(
                child: itensFiltrados.isEmpty
                    ? _EmptyState(
                        onCreate: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exemplo: nenhum cadastro real.'),
                              backgroundColor: kPrimary,
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        itemCount: itensFiltrados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final lead = itensFiltrados[index];
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
                                child: Text(
                                  lead.nome.isNotEmpty
                                      ? lead.nome.characters.first.toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: kPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lead.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (lead.categoria != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Chip(
                                        label: Text(lead.categoria!),
                                        backgroundColor: const Color(
                                          0xFFFFEBEE,
                                        ),
                                        labelStyle: const TextStyle(
                                          color: kPrimary,
                                        ),
                                        side: const BorderSide(color: kPrimary),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    lead.endereco.resumo(),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if ((lead.observacao ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.notes,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            lead.observacao!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
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

class _SampleLead {
  final String nome;
  final String? categoria;
  final _SampleAddress endereco;
  final String? observacao;

  _SampleLead({
    required this.nome,
    required this.endereco,
    this.categoria,
    this.observacao,
  });
}

class _SampleAddress {
  final String pais;
  final String estado;
  final String cidade;
  final String rua;
  final String numero;
  final String? complemento;

  _SampleAddress({
    required this.pais,
    required this.estado,
    required this.cidade,
    required this.rua,
    required this.numero,
    this.complemento,
  });

  String resumo() {
    final comp = (complemento == null || complemento!.trim().isEmpty)
        ? ''
        : ' - ${complemento!.trim()}';
    return '$rua, $numero$comp - $cidade/$estado - $pais';
  }

  String descricaoCompleta() {
    final comp = (complemento == null || complemento!.trim().isEmpty)
        ? ''
        : ' - ${complemento!.trim()}';
    return '$rua, $numero$comp\n$cidade/$estado - $pais';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 72, color: Colors.black26),
            const SizedBox(height: 12),
            const Text(
              'Sem leads no momento (exemplo).',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esse exemplo não salva dados. Use o botão abaixo apenas para demonstração.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
