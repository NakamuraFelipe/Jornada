import 'package:flutter/material.dart';
import 'dart:convert';
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
    final url = Uri.parse("http://192.168.0.5:5000/login");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          //cria o objeto usuario
          final usuarioJson = data['usuario'];
          // salva token no storage
          final token = data['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('id_usuario', usuarioJson['id_usuario']);
          await prefs.setString('token', token);

          // insere token no JSON
          usuarioJson['token'] = token;

          return UsuarioLogado.fromJson(usuarioJson);
        }
      }

      print('Erro no login: ${response.body}');
      return null;
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
                  print("cargo: ${usuario.cargo}");

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
