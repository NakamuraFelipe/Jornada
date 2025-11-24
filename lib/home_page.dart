// ignore_for_file: unused_import
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ==================== MODELS ====================
class Address {
  final String? cep;
  final String pais;
  final String estado;
  final String cidade;
  final String bairro;
  final String rua;
  final String numero;
  final String? complemento;

  Address({
    this.cep,
    required this.pais,
    required this.estado,
    required this.cidade,
    required this.bairro,
    required this.rua,
    required this.numero,
    this.complemento,
  });

  Map<String, dynamic> toJson() => {
    'cep': cep,
    'pais': pais,
    'estado': estado,
    'cidade': cidade,
    'bairro': bairro,
    'rua': rua,
    'numero': numero,
    'complemento': complemento,
  };

  String resumo() {
    return '${rua}, $numero${complemento != null ? ' - $complemento' : ''}, $bairro, $cidade - $estado, $pais${cep != null ? ', CEP: $cep' : ''}';
  }
}

class Lead {
  final String nome_local;
  final String responsavel;
  final String telefone;
  final Address endereco;
  final String status;
  final String? categoria;
  final String? observacao;
  final double? valor;

  Lead({
    required this.nome_local,
    required this.responsavel,
    required this.telefone,
    required this.endereco,
    required this.status,
    this.categoria,
    this.observacao,
    this.valor,
  });

  Map<String, dynamic> toJson() => {
    'nome_local': nome_local,
    'nome_responsavel': responsavel,
    'telefone': telefone,
    'endereco': endereco.toJson(),
    'estado_leads': status,
    'categoria_venda': categoria,
    'observacao': observacao,
    'valor_proposta': valor,
  };
}

/// ==================== CONSTANTES ====================
const kPrimary = Color(0xFFD32F2F);

/// ==================== ADDRESS DIALOG ====================
class AddressDialog extends StatefulWidget {
  const AddressDialog({super.key});

  @override
  State<AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final String apiKey = 'AIzaSyCWaK80DL4E84s-qMKXl1tM-7o7BSMc-DY';
  List<dynamic> sugestoesCidades = [];
  List<dynamic> sugestoesRuas = [];
  Map<String, String?>? _detalhes;
  String? cidadePlaceId;
  double? cidadeLat;
  double? cidadeLng;
  final _cepCtrl = TextEditingController();
  final _paisCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();

  @override
  void dispose() {
    _cepCtrl.dispose();
    _paisCtrl.dispose();
    _estadoCtrl.dispose();
    _cidadeCtrl.dispose();
    _bairroCtrl.dispose();
    _ruaCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final address = Address(
      cep: _cepCtrl.text.trim().isEmpty ? null : _cepCtrl.text.trim(),
      pais: _paisCtrl.text.trim(),
      estado: _estadoCtrl.text.trim(),
      cidade: _cidadeCtrl.text.trim(),
      bairro: _bairroCtrl.text.trim(),
      rua: _ruaCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      complemento: _complementoCtrl.text.trim().isEmpty
          ? null
          : _complementoCtrl.text.trim(),
    );

    Navigator.of(context).pop(address);
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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

  Future<void> buscarCidades(String input) async {
    if (input.isEmpty) {
      setState(() => sugestoesCidades = []);
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&types=(cities)'
      '&components=country:br'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final dados = json.decode(response.body);
      setState(() {
        sugestoesCidades = dados['predictions'];
      });
    }
  }

  Future<void> buscarDetalhesCidade(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) return;

    final dados = json.decode(resp.body)['result'];

    final location = dados['geometry']['location'];
    cidadeLat = location['lat'];
    cidadeLng = location['lng'];

    // componentes do endereço
    final comps = dados['address_components'];

    String pais = '';
    String estado = '';
    String cidade = '';

    for (var c in comps) {
      List types = c['types'];

      if (types.contains('country')) {
        pais = c['long_name'];
      }
      if (types.contains('administrative_area_level_1')) {
        estado = c['long_name'];
      }
      if (types.contains('locality')) {
        cidade = c['long_name'];
      }
    }

    // preenche os campos automaticamente
    setState(() {
      _paisCtrl.text = pais;
      _estadoCtrl.text = estado;
      _cidadeCtrl.text = cidade;
    });
  }

  Future<void> buscarRuas(String input) async {
    if (input.isEmpty || cidadeLat == null || cidadeLng == null) {
      setState(() => sugestoesRuas = []);
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&types=address'
      '&location=$cidadeLat,$cidadeLng'
      '&radius=30000'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final dados = json.decode(resp.body);

      setState(() {
        sugestoesRuas = dados['predictions'];
      });
    }
  }

  Future<void> buscarDetalhesRua(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$apiKey'
      '&language=pt_BR',
    );

    final resp = await http.get(url);
    if (resp.statusCode != 200) return;

    final dados = json.decode(resp.body)['result'];
    final comps = dados['address_components'];

    String bairro = '';
    String rua = '';

    for (var c in comps) {
      List types = c['types'];

      if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        bairro = c['long_name'];
      }
      if (types.contains('route')) {
        rua = c['long_name'];
      }
    }

    setState(() {
      _bairroCtrl.text = bairro;
      _ruaCtrl.text = rua;
    });
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
              TextFormField(
                controller: _cidadeCtrl,
                decoration: _dec('Cidade *', Icons.location_city),
                onChanged: buscarCidades,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a cidade' : null,
              ),

              // lista de sugestões de cidades
              if (sugestoesCidades.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    itemCount: sugestoesCidades.length,
                    itemBuilder: (context, index) {
                      final s = sugestoesCidades[index];

                      return ListTile(
                        title: Text(s['description']),
                        onTap: () {
                          setState(() {
                            _cidadeCtrl.text = s['description'];
                            cidadePlaceId = s['place_id'];
                            sugestoesCidades = [];
                          });

                          buscarDetalhesCidade(cidadePlaceId!);
                        },
                      );
                    },
                  ),
                ),
              SizedBox(height: 16),
              TextFormField(
                controller: _ruaCtrl,
                decoration: _dec('Rua *', Icons.map),
                onChanged: buscarRuas,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a rua' : null,
              ),

              // lista de sugestões de ruas
              if (sugestoesRuas.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    itemCount: sugestoesRuas.length,
                    itemBuilder: (context, index) {
                      final s = sugestoesRuas[index];

                      return ListTile(
                        title: Text(s['description']),
                        onTap: () {
                          setState(() {
                            _ruaCtrl.text = s['description'];
                            sugestoesRuas = [];
                          });

                          buscarDetalhesRua(s['place_id']);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroCtrl,
                keyboardType: TextInputType.number,
                decoration: _dec('Número *', Icons.numbers),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o número' : null,
              ),
              const SizedBox(height: 12),
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

/// ==================== CREATE LEAD ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  final String apiKey = 'AIzaSyCWaK80DL4E84s-qMKXl1tM-7o7BSMc-DY';
  List<dynamic> sugestoesCidades = [];
  List<dynamic> sugestoesRuas = [];
  Map<String, String?>? _detalhes;
  String? cidadePlaceId;
  double? cidadeLat;
  double? cidadeLng;

  final _responsavelCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _nome_localCtrl = TextEditingController();

  String? _categoria;
  String? _statusLead;
  Address? _endereco;

  bool _saving = false;
  final _formatter = NumberFormat("#,##0.00", "pt_BR");

  @override
  void dispose() {
    _responsavelCtrl.dispose();
    _telefoneCtrl.dispose();
    _valorCtrl.dispose();
    _obsCtrl.dispose();
    _nome_localCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirDialogEndereco() async {
    final selecionado = await showDialog<Address>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AddressDialog(),
    );
    if (selecionado != null) setState(() => _endereco = selecionado);
  }

  String _formatarTelefoneParaBanco(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13) return input;
    final ddi = digits.substring(0, 2);
    final ddd = digits.substring(2, 4);
    final numero = digits.substring(4);
    return '+$ddi-$ddd-$numero';
  }

  Future<void> _salvar() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (_endereco == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um endereço antes de salvar.'),
          backgroundColor: kPrimary,
        ),
      );
      return;
    }

    if (_statusLead == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um status do lead.'),
          backgroundColor: kPrimary,
        ),
      );
      return;
    }

    if (!isValid) return;
    setState(() => _saving = true);

    final valorParsed = double.tryParse(
      _valorCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
    );
    final telefoneFormatado = _formatarTelefoneParaBanco(_telefoneCtrl.text);

    final lead = Lead(
      nome_local: _nome_localCtrl.text.trim(),
      responsavel: _responsavelCtrl.text.trim(),
      telefone: telefoneFormatado,
      endereco: _endereco!,
      status: _statusLead!,
      categoria: _categoria,
      observacao: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      valor: valorParsed,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final uri = Uri.parse('http://192.168.0.5:5000/criar_lead');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(lead.toJson()),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead salvo com sucesso!'),
            backgroundColor: kPrimary,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        String msg = 'Erro ao salvar lead (${resp.statusCode})';
        try {
          final data = jsonDecode(resp.body);
          if (data['mensagem'] != null) msg = data['mensagem'];
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
    } finally {
      setState(() => _saving = false);
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
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Nome da Empresa
                    TextFormField(
                      controller: _nome_localCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome da Empresa *',
                        prefixIcon: const Icon(Icons.business, color: kPrimary),
                        enabledBorder: themeInputBorder,
                        focusedBorder: themeInputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: kPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome da empresa'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    /// Responsável
                    TextFormField(
                      controller: _responsavelCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome do Responsável *',
                        prefixIcon: const Icon(Icons.person, color: kPrimary),
                        enabledBorder: themeInputBorder,
                        focusedBorder: themeInputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: kPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o responsável'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    /// Telefone
                    TextFormField(
                      controller: _telefoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TelefoneInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Telefone *',
                        hintText: '+55 (43) 90000-0001',
                        prefixIcon: const Icon(Icons.phone, color: kPrimary),
                        enabledBorder: themeInputBorder,
                        focusedBorder: themeInputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: kPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().length < 17)
                          ? 'Informe um telefone válido'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    /// Endereço
                    Card(
                      elevation: 0,
                      color: const Color(0xFFF7F7F7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
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
                                    _endereco == null ? 'Escolher' : 'Alterar',
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _endereco == null
                                  ? 'Nenhum endereço selecionado.'
                                  : _endereco!.resumo(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Status do Lead
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Status do Lead *',
                        prefixIcon: const Icon(Icons.flag, color: kPrimary),
                        enabledBorder: themeInputBorder,
                        focusedBorder: themeInputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: kPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'aberta',
                          child: Text('Aberta'),
                        ),
                        DropdownMenuItem(
                          value: 'conexao',
                          child: Text('Conexão'),
                        ),
                        DropdownMenuItem(
                          value: 'negociacao',
                          child: Text('Negociação'),
                        ),
                        DropdownMenuItem(
                          value: 'fechada',
                          child: Text('Fechada'),
                        ),
                      ],
                      value: _statusLead,
                      onChanged: (v) => setState(() => _statusLead = v),
                      validator: (v) =>
                          v == null ? 'Selecione um status' : null,
                    ),
                    const SizedBox(height: 16),

                    /// Valor
                    TextFormField(
                      controller: _valorCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ValorInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Valor da Proposta',
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: kPrimary,
                        ),
                        enabledBorder: themeInputBorder,
                        focusedBorder: themeInputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: kPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Categoria
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Categoria (opcional)',
                        prefixIcon: const Icon(Icons.category, color: kPrimary),
                        enabledBorder: themeInputBorder,
                        focusedBorder: themeInputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: kPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Imovel',
                          child: Text('Imóvel'),
                        ),
                        DropdownMenuItem(
                          value: 'Veículo',
                          child: Text('Veículo'),
                        ),
                        DropdownMenuItem(
                          value: 'Serviços',
                          child: Text('Serviços'),
                        ),
                        DropdownMenuItem(
                          value: 'Bens Móveis',
                          child: Text('Bens Móveis'),
                        ),
                      ],
                      value: _categoria,
                      onChanged: (v) => setState(() => _categoria = v),
                    ),
                    const SizedBox(height: 16),

                    /// Observação
                    TextFormField(
                      controller: _obsCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Observação (opcional)',
                        prefixIcon: const Icon(Icons.notes, color: kPrimary),
                        alignLabelWithHint: true,
                        enabledBorder: themeInputBorder,
                        focusedBorder: themeInputBorder.copyWith(
                          borderSide: const BorderSide(
                            color: kPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _saving ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Salvar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============= FORMATADOR DE TELEFONE =============
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove tudo que não for número
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Limitar: DDI(2) + DDD(2) + Número(9) = 13 dígitos
    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }

    String formatted = '+';

    // DDI (2 dígitos)
    if (digits.length >= 1) {
      formatted += digits.substring(0, min(2, digits.length));
    }

    if (digits.length >= 2) {
      formatted += ' ';
    } else {
      return _ret(formatted);
    }

    // DDD (2 dígitos)
    if (digits.length >= 3) {
      formatted += '(' + digits.substring(2, min(4, digits.length));
    } else {
      formatted += '(' + digits.substring(2);
      return _ret(formatted + ')');
    }

    if (digits.length >= 4) {
      formatted += ') ';
    } else {
      return _ret(formatted);
    }

    // Número
    if (digits.length > 4) {
      String numero = digits.substring(4);
      if (numero.length <= 5) {
        formatted += numero;
      } else {
        formatted += numero.substring(0, 5) + '-' + numero.substring(5);
      }
    }

    return _ret(formatted);
  }

  TextEditingValue _ret(String text) {
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// ============= FORMATADOR DE VALOR =============
class ValorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) digits = '0';

    double value = double.parse(digits) / 100.0;
    final formatter = NumberFormat("#,##0.00", "pt_BR");
    String newText = formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
