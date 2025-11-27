import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './models/usuario_logado.dart';

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  UsuarioLogado? usuario;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        debugPrint("Nenhum token encontrado.");
        setState(() => loading = false);
        return;
      }

      // 1️⃣ Buscar dados do usuário
      final response = await http.get(
        Uri.parse('http://192.168.25.76:5000/usuario_logado'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['status'] == 'ok') {
          usuario = UsuarioLogado.fromJson(body['usuario']);
          await _buscarFoto(usuario!.idUsuario);
        }
      } else {
        debugPrint("Erro: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // 2️⃣ Buscar foto
  Future<void> _buscarFoto(int idUser) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.25.76:5000/usuario/$idUser/foto'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          usuario!.foto = data['foto'];
        }
      }
    } catch (e) {
      debugPrint("Erro ao carregar foto: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Perfil"),
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Perfil"),
          backgroundColor: Color(0xFFD32F2F),
        ),
        body: Center(child: Text("Erro ao carregar usuário.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // FOTO + NOME
  // ---------------------------------------------------------------
  Widget _buildHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(color: Color(0xFFD32F2F)),
          ),

          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 90,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: usuario!.foto != null
                          ? MemoryImage(base64Decode(usuario!.foto!))
                          : AssetImage('assets/images/foto_perfil_teste.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          print("Botão da câmera pressionado");
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                Text(
                  usuario!.nomeUsuario,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // INFORMAÇÕES DO USUÁRIO
  // ---------------------------------------------------------------
  Widget _buildInfo() {
    return Column(
      children: [
        _infoItem(Icons.email, "Email", usuario?.email ?? "—"),
        _divider(),
        _infoItem(Icons.phone, "Telefone", usuario?.telefone ?? "—"),
        _divider(),
        _infoItem(Icons.badge, "Cargo", usuario?.cargo ?? "—"),
        _divider(),
        _infoItem(Icons.confirmation_number, "Matrícula", usuario?.matricula ?? "—"),
        _divider(),
        _buttons(),
      ],
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          SizedBox(width: 15),
          Text(
            "$label:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 18, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, thickness: 0.3, color: Colors.black26);
  }

  Widget _buttons() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              print('Trocar Telefone');
            },
            child: const Center(
              child: Text(
                'Trocar Telefone',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              print('Trocar Senha');
            },
            child: const Center(
              child: Text(
                'Trocar Senha',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
