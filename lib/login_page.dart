import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './models/usuario_logado.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';
  bool passwordText = true;
  bool loading = false;

  // Função de login
  Future<UsuarioLogado?> loginUser(String email, String password) async {
    final url = Uri.parse("http://192.168.0.3:5000/login");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'ok') {
        final token = data['token'];

        // Cria objeto UsuarioLogado incluindo token
        final usuarioJson = data['usuario'];
        usuarioJson['token'] = token;
        final usuario = UsuarioLogado.fromJson(usuarioJson);

        // Salva token e usuário no SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // 🔥 CORREÇÃO PRINCIPAL — SALVAR TOKEN
        await prefs.setString('token', token);

        // Salva o objeto do usuário
        await prefs.setString('usuario_logado', jsonEncode(usuario.toJson()));

        print("TOKEN SALVO: $token");

        return usuario;
      } else {
        print('Erro no login: ${data['mensagem']}');
        return null;
      }
    } catch (e) {
      print('Erro de conexão: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFD32F2F),
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Positioned(
                  top: 50,
                  left: 30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  right: 30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 200,
                  left: 150,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 230),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                ),

                _body(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Center(child: Image.asset('assets/images/logo3.png', width: 160)),
          const SizedBox(height: 65),
          const Padding(
            padding: EdgeInsets.only(left: 30),
            child: Text(
              "LOGIN",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F),
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _emailField(),
          const SizedBox(height: 20),
          _passwordField(),
          const SizedBox(height: 40),
          _loginButton(),
        ],
      ),
    );
  }

  Widget _emailField() {
    return Center(
      child: SizedBox(
        width: 300,
        child: TextField(
          onChanged: (text) => email = text.trim(),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email, color: Color(0xFFD32F2F)),
            labelText: 'Email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Center(
      child: SizedBox(
        width: 300,
        child: TextField(
          obscureText: passwordText,
          onChanged: (text) => password = text,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Color(0xFFD32F2F)),
            labelText: 'Senha',
            suffixIcon: IconButton(
              icon: Icon(
                passwordText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => passwordText = !passwordText),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return Center(
      child: ElevatedButton(
        onPressed: loading
            ? null
            : () async {
                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha email e senha')),
                  );
                  return;
                }

                setState(() => loading = true);
                final usuario = await loginUser(email, password);
                setState(() => loading = false);

                if (usuario != null) {
                  if (usuario.cargo.toLowerCase() == "gestor") {
                    Navigator.pushReplacementNamed(
                      context,
                      '/home_gestor',
                      arguments: usuario,
                    );
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      '/home_screen',
                      arguments: usuario,
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email ou senha incorretos')),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
