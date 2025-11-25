import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// sua cor padrão
const kPrimary = Color(0xFFD32F2F);

class CreateUser extends StatefulWidget {
  const CreateUser({super.key});

  @override
  State<CreateUser> createState() => _CreateUserState();
}

class _CreateUserState extends State<CreateUser> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  String cargoSelecionado = 'consultor';
  String? fotoBase64;

  File? fotoSelecionada;

  
  /// Escolher foto (MANEIRA ORIGINAL — mantida exatamente como estava)
  Future<void> _escolherFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        fotoSelecionada = File(image.path);
        fotoBase64 = base64Encode(bytes);
      });
    }
  }
  

  Future<void> _salvarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri.parse("http://192.168.0.5:5000/cadastrar_usuario");

      SharedPreferences prefs = await SharedPreferences.getInstance();
    int? idGestor = prefs.getInt("id_usuario");

    if (idGestor == null) {
      _erro("Erro: usuário logado não encontrado.");
      return;
    }

    final body = jsonEncode({
      "nome_usuario": nomeController.text.trim(),
      "cargo": cargoSelecionado,
      "email": emailController.text.trim(),
      "telefone": telefoneController.text.trim(),
      "senha": senhaController.text.trim(),
      "foto": fotoBase64,
      "id_gestor": idGestor,
    });

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Usuário criado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } else {
        _erro(data["mensagem"]);
      }
    } else {
      _erro("Erro ao salvar usuário");
    }
  }

  void _erro(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // Bordas padrão
  OutlineInputBorder getInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.black),
    );
  }

  OutlineInputBorder getFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Criar Usuário"),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16),
          ),

          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// FOTO DO USUÁRIO
                GestureDetector(
                  onTap: _escolherFoto,   // ← mantido como estava
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage: fotoSelecionada != null
                        ? FileImage(fotoSelecionada!)
                        : null,
                    child: fotoSelecionada == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 36,
                            color: kPrimary,
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                _buildInput(
                  controller: nomeController,
                  label: "Nome completo *",
                  icon: Icons.person,
                  validator: (v) =>
                      v!.isEmpty ? "Informe o nome do usuário" : null,
                ),

                const SizedBox(height: 16),

                /// CARGO
                DropdownButtonFormField<String>(
                  value: cargoSelecionado,
                  decoration: InputDecoration(
                    labelText: "Cargo *",
                    prefixIcon: const Icon(Icons.badge, color: kPrimary),
                    enabledBorder: getInputBorder(),
                    focusedBorder: getFocusedBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "gestor", child: Text("Gestor")),
                    DropdownMenuItem(
                      value: "consultor",
                      child: Text("Consultor"),
                    ),
                    DropdownMenuItem(
                      value: "gestor",
                      child: Text("Gestor"),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => cargoSelecionado = val!);
                  },
                ),

                const SizedBox(height: 16),

                _buildInput(
                  controller: emailController,
                  label: "Email *",
                  icon: Icons.email,
                  validator: (v) => v!.isEmpty ? "Informe o email" : null,
                ),

                const SizedBox(height: 16),

                _buildInput(
                  controller: telefoneController,
                  label: "Telefone *",
                  icon: Icons.phone,
                  validator: (v) => v!.isEmpty ? "Informe o telefone" : null,
                ),

                const SizedBox(height: 16),

                _buildInput(
                  controller: senhaController,
                  label: "Senha *",
                  icon: Icons.lock,
                  obscure: true,
                  validator: (v) => v!.length < 4
                      ? "A senha deve ter pelo menos 4 dígitos"
                      : null,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _salvarUsuario,
                    child: const Text(
                      "Criar Usuário",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimary),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: getInputBorder(),
        focusedBorder: getFocusedBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
