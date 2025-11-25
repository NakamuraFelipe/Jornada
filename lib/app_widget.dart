import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teste/autocomplete.dart';
import 'package:teste/dash_page.dart';
import 'package:teste/login_page.dart';
import 'package:teste/app_controler.dart';
import 'package:teste/buscar_lead.dart';
import 'package:teste/criar_leads.dart';
import 'package:teste/cadastrar_usuario.dart';
import 'package:teste/gerenciar_pap.dart';
import 'package:teste/home_page.dart' hide AppControler;
import 'package:teste/home_page_gestor.dart';
import 'package:teste/inicio.dart';
import 'package:teste/main.dart';
import 'package:teste/meus_leads.dart';
import 'package:teste/perfil_page.dart';
import 'package:teste/usuarios_supervisionados.dart';
import './models/usuario_logado.dart';

class AppWidget extends StatefulWidget {
  final String title;

  const AppWidget({super.key, required this.title});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString('usuario_logado');

    if (usuarioJson != null) {
      final usuario = UsuarioLogado.fromJson(jsonDecode(usuarioJson));
      print("Usuário logado encontrado com token: ${usuario.token}");
    } else {
      print("Nenhum usuário logado encontrado.");
    }

    setState(() {
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AnimatedBuilder(
      animation: AppControler.instance,
      builder: (context, child) {
        return MaterialApp(
          title: widget.title,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.red,
            primaryColor: Colors.red,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.red),
            brightness: AppControler.instance.isDarkTheme
                ? Brightness.dark
                : Brightness.light,
          ),
          home: LoginPage(),
          routes: {
            '/meus_leads': (context) => const MeusLeads(),
            '/gestor': (context) => HomePage_Gestor(),
            '/novo_usuario': (context) => CreateUser(),
            '/home_gestor': (context) => const HomeScreenGestor(),
            '/login': (context) => LoginPage(),
            '/pap': (context) => GerenciarPAP(),
            '/home': (context) => HomePage(),
            '/inicio': (context) => Inicio(),
            '/leads': (context) => CreateLead(),
            '/buscar_leads': (context) => BuscarLead(),
            '/home_screen': (context) => const HomeScreen(),
            '/perfil': (context) => PerfilPage(),
            '/dash': (context) => DashPage(),
            '/usuarios_supervisionados': (context) => UsuariosSupervisionados(),
          },
        );
      },
    );
  }
}
