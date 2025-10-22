import 'package:flutter/material.dart';

const kPrimary = Color(0xFFD32F2F);

class CreateLead extends StatefulWidget {
  const CreateLead({super.key});

  @override
  State<CreateLead> createState() => _CreateLeadState();
}

class _CreateLeadState extends State<CreateLead> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomeCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  String? _categoria; // opcional
  Address? _endereco; // obrigatório

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirDialogEndereco() async {
    final selecionado = await showDialog<Address>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddressDialog(),
    );
    if (selecionado != null) {
      setState(() => _endereco = selecionado);
    }
  }

  void _salvar() {
    final isValid = _formKey.currentState?.validate() ?? false;

    // Validar endereço (obrigatório)
    if (_endereco == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um endereço antes de salvar.'),
          backgroundColor: kPrimary,
        ),
      );
      return;
    }

    if (isValid) {
      final lead = Lead(
        nome: _nomeCtrl.text.trim(),
        endereco: _endereco!,
        categoria: _categoria,
        observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      );

      // Aqui você pode enviar o lead para sua API/serviço, persistir local, etc.
      // Exemplo: printar no console
      // ignore: avoid_print
      print(lead);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lead salvo com sucesso!'),
          backgroundColor: kPrimary,
        ),
      );

      Navigator.of(
        context,
      ).pop(lead); // retorna o lead para a página anterior (opcional)
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
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
                // Nome do lead (obrigatório)
                TextFormField(
                  controller: _nomeCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nome do lead *',
                    prefixIcon: const Icon(Icons.person, color: kPrimary),
                    enabledBorder: themeInputBorder,
                    focusedBorder: themeInputBorder.copyWith(
                      borderSide: const BorderSide(color: kPrimary, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o nome do lead';
                    }
                    if (v.trim().length < 2) {
                      return 'Nome muito curto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Endereço (obrigatório via dialog)
                Card(
                  elevation: 0,
                  color: const Color(0xFFF7F7F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: kPrimary),
                            const SizedBox(width: 8),
                            const Text(
                              'Endereço *',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _abrirDialogEndereco,
                              icon: const Icon(
                                Icons.edit_location_alt,
                                color: kPrimary,
                              ),
                              label: Text(
                                _endereco == null
                                    ? 'Escolher endereço'
                                    : 'Alterar',
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_endereco == null)
                          const Text(
                            'Nenhum endereço selecionado.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Text(
                            _endereco!.resumo(),
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Categoria de venda (opcional)
                DropdownButtonFormField<String>(
                  value: _categoria,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Categoria de venda (opcional)',
                    prefixIcon: const Icon(Icons.category, color: kPrimary),
                    enabledBorder: themeInputBorder,
                    focusedBorder: themeInputBorder.copyWith(
                      borderSide: const BorderSide(color: kPrimary, width: 2),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Varejo', child: Text('Varejo')),
                    DropdownMenuItem(value: 'Atacado', child: Text('Atacado')),
                    DropdownMenuItem(
                      value: 'Serviços',
                      child: Text('Serviços'),
                    ),
                    DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                  ],
                  onChanged: (val) => setState(() => _categoria = val),
                ),
                const SizedBox(height: 16),

                // Observação (opcional)
                TextFormField(
                  controller: _obsCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Observação (opcional)',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.notes, color: kPrimary),
                    enabledBorder: themeInputBorder,
                    focusedBorder: themeInputBorder.copyWith(
                      borderSide: const BorderSide(color: kPrimary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Ações
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar lead'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: kPrimary),
                        label: const Text(
                          'Cancelar',
                          style: TextStyle(color: kPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======= MODELOS =======

class Lead {
  final String nome;
  final Address endereco;
  final String? categoria;
  final String? observacao;

  Lead({
    required this.nome,
    required this.endereco,
    this.categoria,
    this.observacao,
  });

  @override
  String toString() {
    return 'Lead(nome: $nome, endereco: ${endereco.resumo()}, categoria: $categoria, observacao: $observacao)';
  }
}

class Address {
  final String pais;
  final String estado;
  final String cidade;
  final String rua;
  final String numero;
  final String? complemento;

  Address({
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
}

// ======= DIALOG DE ENDEREÇO =======

class AddressDialog extends StatefulWidget {
  const AddressDialog({super.key});

  @override
  State<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  final _formKey = GlobalKey<FormState>();

  final _paisCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();

  @override
  void dispose() {
    _paisCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final address = Address(
      pais: _paisCtrl.text.trim(),
      estado: _estadoCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      rua: _ruaCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      complemento: _complementoCtrl.text.trim().isEmpty
          ? null
          : _complementoCtrl.text.trim(),
    );

    Navigator.of(context).pop(address);
  }

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Endereço'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // País
              TextFormField(
                controller: _paisCtrl,
                decoration: _dec('País *', Icons.public),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o país' : null,
              ),
              const SizedBox(height: 12),

              // Estado
              TextFormField(
                controller: _estadoCtrl,
                decoration: _dec('Estado *', Icons.flag),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o estado' : null,
              ),
              const SizedBox(height: 12),

              // Cidade
              TextFormField(
                controller: _cidadeCtrl,
                decoration: _dec('Cidade *', Icons.location_city),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a cidade' : null,
              ),
              const SizedBox(height: 12),

              // Rua
              TextFormField(
                controller: _ruaCtrl,
                decoration: _dec('Rua *', Icons.map),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a rua' : null,
              ),
              const SizedBox(height: 12),

              // Número
              TextFormField(
                controller: _numeroCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('Número *', Icons.numbers),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o número' : null,
              ),
              const SizedBox(height: 12),

              // Complemento (opcional)
              TextFormField(
                controller: _complementoCtrl,
                decoration: _dec(
                  'Complemento (opcional)',
                  Icons.add_location_alt,
                ),
              ),
            ],
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
