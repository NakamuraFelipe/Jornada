import 'package:flutter/material.dart';

const kPrimary = Color(0xFFD32F2F);

class UsuariosSupervisionados extends StatefulWidget {
  const UsuariosSupervisionados({super.key});

  @override
  State<UsuariosSupervisionados> createState() => _UsuariosSupervisionadosState();
}

class _UsuariosSupervisionadosState extends State<UsuariosSupervisionados> {
  final _buscaCtrl = TextEditingController();

  // ==== DADOS DE EXEMPLO ====
  final List<_SampleUsuarioSupervisionado> _itens = [
    _SampleUsuarioSupervisionado(
      nome: 'Maria Silva',
      email: 'maria@email.com',
      totalLeads: 4,
    ),
    _SampleUsuarioSupervisionado(
      nome: 'Luiz Almeida',
      email: 'almeida@email.com',
      telefone: '+55(43)99482-5469',
      totalLeads: 12,
    ),
    _SampleUsuarioSupervisionado(
      nome: 'João Pereira',
      telefone: '+55(43)99482-5469',
      totalLeads: 0,
    ),
  ];
  // ==========================

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  // FILTRO DE BUSCA
  bool _match(_SampleUsuarioSupervisionado u, String query) {
    if (query.trim().isEmpty) return true;

    final q = query.toLowerCase().trim();

    return u.nome.toLowerCase().contains(q) ||
        (u.email ?? '').toLowerCase().contains(q) ||
        (u.telefone ?? '').toLowerCase().contains(q);
  }

  // MOSTRAR DETALHES
  void _mostrarDetalhes(_SampleUsuarioSupervisionado u) {
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
                    u.nome,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // CHIP COM TOTAL DE LEADS
                Chip(
                  label: Text("${u.totalLeads} leads"),
                  backgroundColor: const Color(0xFFFFEBEE),
                  labelStyle: const TextStyle(color: kPrimary),
                  side: const BorderSide(color: kPrimary),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if ((u.email ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.email, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(u.email!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if ((u.telefone ?? '').isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(u.telefone!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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

    final itensFiltrados = _itens.where((u) => _match(u, _buscaCtrl.text)).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Usuários supervisionados"),
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),

        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Cadastrar usuário"),
          onPressed: () {},
        ),

        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _buscaCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Buscar',
                  hintText: 'Nome, email ou telefone...',
                  prefixIcon: const Icon(Icons.search, color: kPrimary),
                  enabledBorder: themeInputBorder,
                  focusedBorder: themeInputBorder.copyWith(
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: itensFiltrados.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: itensFiltrados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final u = itensFiltrados[index];

                          return Card(
                            elevation: 0,
                            color: const Color(0xFFF7F7F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            child: ListTile(
                              onTap: () => _mostrarDetalhes(u),

                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFFEBEE),
                                child: Text(
                                  u.nome.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: kPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              title: Text(
                                u.nome,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((u.email ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(u.email!, style: const TextStyle(color: Colors.black87)),
                                  ],
                                  if ((u.telefone ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(u.telefone!, style: const TextStyle(color: Colors.black54)),
                                  ],
                                ],
                              ),

                              trailing: Chip(
                                label: Text("${u.totalLeads}"),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0,),
                                backgroundColor: const Color(0xFFFFEBEE),
                                labelStyle: const TextStyle(color: kPrimary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                side: const BorderSide(color: kPrimary),
                              ),
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

// ============================
// CLASSE DO USUÁRIO EXEMPLO
// ============================
class _SampleUsuarioSupervisionado {
  final String nome;
  final String? foto;
  final String? telefone;
  final String? email;

  // Quantos leads esse usuário tem
  final int totalLeads;

  _SampleUsuarioSupervisionado({
    required this.nome,
    this.foto,
    this.telefone,
    this.email,
    this.totalLeads = 0,
  });
}

// ============================
// ESTADO QUANDO A LISTA ESTÁ VAZIA
// ============================
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 72, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Nenhum usuário encontrado.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
