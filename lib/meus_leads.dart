import 'dart:ffi';

import 'package:flutter/material.dart';

const kPrimary = Color(0xFFD32F2F);

class MeusLeads extends StatefulWidget {
  const MeusLeads({super.key});

  @override
  State<MeusLeads> createState() => _MeusLeadsState();
}

class _MeusLeadsState extends State<MeusLeads> {
  final _buscaCtrl = TextEditingController();

  // ==== DADOS ESTÁTICOS (APENAS EXEMPLO) ====
  final List<_SampleLead> _itens = [
    _SampleLead(
      nomelead: 'Maria Silva',
      categoria: 'Varejo',
      endereco: _SampleAddress(
        pais: 'Brasil',
        estado: 'SP',
        cidade: 'São Paulo',
        rua: 'Av. Paulista',
        numero: '1000',
        complemento: 'Conj. 101',
      ),
      nomeconsultor: 'Lucas Ferreira',
      UltimaVisita: DateTime(2024, 3, 10),
      NomeResponsavel: 'Ana Souza',
      EstadoDoLead: 'Em negociação',
      dataCriacao: DateTime(2024, 1, 5),
      dataPrevisaoContato: DateTime(2024, 3, 15),
      ValorProposta: 15000.50,
      Observacoes: 'Cliente interessado em renovar contrato anual.',
    ),
    _SampleLead(
      nomelead: 'Comercial Almeida',
      categoria: 'Atacado',
      endereco: _SampleAddress(
        pais: 'Brasil',
        estado: 'MG',
        cidade: 'Belo Horizonte',
        rua: 'Rua da Bahia',
        numero: '230',
      ),
      nomeconsultor: 'Andre Henrique',
      UltimaVisita: DateTime(2024, 3, 12),
      NomeResponsavel: 'Rafael Lima',
      EstadoDoLead: 'Contato inicial',
      dataCriacao: DateTime(2024, 2, 20),
      dataPrevisaoContato: DateTime(2024, 3, 18),
      ValorProposta: 8000,
      Observacoes: 'Aguardando resposta sobre cotação enviada.',
    ),
    _SampleLead(
      nomelead: 'João Pereira',
      endereco: _SampleAddress(
        pais: 'Brasil',
        estado: 'RJ',
        cidade: 'Rio de Janeiro',
        rua: 'Rua das Laranjeiras',
        numero: '45',
      ),
      nomeconsultor: 'Mariana Costa',
      UltimaVisita: DateTime(2024, 3, 8),
      NomeResponsavel: 'Mariana Costa',
      EstadoDoLead: 'Fechado',
      dataCriacao: DateTime(2024, 1, 25),
      dataPrevisaoContato: null,
      ValorProposta: 20000,
      Observacoes: 'Lead finalizado com sucesso. Contrato assinado.',
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
    return lead.nomelead.toLowerCase().contains(q) ||
        lead.endereco.resumo().toLowerCase().contains(q) ||
        (lead.categoria ?? '').toLowerCase().contains(q) ||
        (lead.nomeconsultor ?? '').toLowerCase().contains(q);
  }

  void _mostrarDetalhes(_SampleLead lead) {
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
          minChildSize: 0.25,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MENSAGEM SUPERIOR
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

                    // CABEÇALHO PRINCIPAL
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.business, size: 28, color: kPrimary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead.nomelead,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (lead.categoria != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(lead.categoria!),
                                    backgroundColor: const Color(0xFFFFEBEE),
                                    labelStyle: const TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: const BorderSide(color: kPrimary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),

                    // SEÇÃO: INFORMAÇÕES GERAIS
                    const SizedBox(height: 10),
                    _sectionTitle("Informações Gerais"),

                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.location_on,
                      "Endereço",
                      lead.endereco.descricaoCompleta(),
                    ),

                    _infoRow(Icons.person, "Consultor", lead.nomeconsultor),
                    _infoRow(Icons.badge, "Responsável", lead.NomeResponsavel),
                    _infoRow(Icons.flag, "Estado do Lead", lead.EstadoDoLead),

                    if (lead.ValorProposta != null)
                      _infoRow(
                        Icons.attach_money,
                        "Proposta",
                        "R\$ ${lead.ValorProposta!.toStringAsFixed(2)}",
                      ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),

                    // SEÇÃO: DATAS
                    const SizedBox(height: 10),
                    _sectionTitle("Datas"),
                    const SizedBox(height: 6),

                    _infoRow(
                      Icons.calendar_today,
                      "Lead cadastrado em",
                      "${lead.dataCriacao.day}/${lead.dataCriacao.month}/${lead.dataCriacao.year}",
                    ),

                    if (lead.dataPrevisaoContato != null)
                      _infoRow(
                        Icons.schedule,
                        "Previsão de contato",
                        "${lead.dataPrevisaoContato!.day}/${lead.dataPrevisaoContato!.month}/${lead.dataPrevisaoContato!.year}",
                      ),

                    _infoRow(
                      Icons.update,
                      "Última visita",
                      "${lead.UltimaVisita.day}/${lead.UltimaVisita.month}/${lead.UltimaVisita.year}",
                    ),

                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),

                    // SEÇÃO: OBSERVAÇÕES
                    if (lead.Observacoes != null &&
                        lead.Observacoes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _sectionTitle("Observações"),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12, width: 0.5),
                        ),
                        child: Text(
                          lead.Observacoes!,
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    ],

                    const SizedBox(height: 25),

                    // BOTÕES
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.info),
                            label: const Text("Atualizar visita"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.info),
                            label: const Text("Atualizar lead"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Título de seção elegante
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: kPrimary,
      ),
    );
  }

  // 🔹 Linha de informação estilizada
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
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
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
          title: const Text('Meus Leads '),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
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
                                  lead.nomelead.isNotEmpty
                                      ? lead.nomelead.characters.first
                                            .toUpperCase()
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
                                      lead.nomelead,
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
                                  if ((lead.nomeconsultor ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            lead.nomeconsultor!,
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
                                  if (lead.UltimaVisita != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Última visita: ${lead.UltimaVisita!.day}/${lead.UltimaVisita!.month}/${lead.UltimaVisita!.year}',
                                          style: const TextStyle(
                                            color: Colors.black54,
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
  final String nomelead;
  final String nomeconsultor;
  final String? categoria;
  final _SampleAddress endereco;
  final DateTime dataCriacao;
  final DateTime? dataPrevisaoContato;
  final DateTime UltimaVisita;
  final String NomeResponsavel;
  final double? ValorProposta;
  final String? Observacoes;
  final String EstadoDoLead;

  _SampleLead({
    required this.nomelead,
    required this.nomeconsultor,
    required this.endereco,
    this.categoria,
    required this.UltimaVisita,
    required this.NomeResponsavel,
    this.ValorProposta,
    required this.dataCriacao,
    this.dataPrevisaoContato,
    this.Observacoes,
    required this.EstadoDoLead,
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
