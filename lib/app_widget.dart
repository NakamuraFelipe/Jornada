import 'package:flutter/material.dart';
import 'package:teste/autocomplete.dart';
import 'package:teste/dash_page.dart';

// ignore: unused_import
import 'package:teste/login_page.dart';
import 'package:teste/app_controler.dart';
import 'package:teste/buscar_lead.dart';
import 'package:teste/criar_leads.dart';
import 'package:teste/gerenciar_pap.dart';
// ignore: undefined_hidden_name
import 'package:teste/home_page.dart' hide AppControler;
import 'package:teste/home_page_gestor.dart';
import 'package:teste/inicio.dart';
// ignore: unused_import
import 'package:teste/main.dart';
import 'package:teste/meus_leads.dart';
import 'package:teste/perfil_page.dart';
import 'package:teste/usuarios_supervisionados.dart';

class appWidget extends StatelessWidget {
  final String title;

  const appWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppControler.instance,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.red,
            primaryColor: Colors.red,
            appBarTheme: AppBarTheme(backgroundColor: Colors.red),
            brightness: AppControler.instance.isDarkTheme
                ? Brightness.dark
                : Brightness.light,
          ),
          home: UsuariosSupervisionados(),
          routes: {
            '/gestor': (context) => HomePage_Gestor(),
            '/login': (context) => LoginPage(),
            '/pap': (context) => GerenciarPAP(),
            '/home': (context) => HomePage(),
            '/inicio': (context) => Inicio(),
            '/leads': (context) => CreateLead(),
            '/meus_leads': (context) => MeusLeads(),
            '/buscar_leads': (context) => BuscarLead(),
            '/home_screen': (context) => HomeScreen(),
            '/perfil': (context) => PerfilPage(),
            '/dash': (context) => DashPage(),
          },
        );
      },
    );
  }
}

//MaterialApp(
  //    theme: ThemeData(
    //    primarySwatch: Colors.red,
      //  primaryColor: Colors.red,
        //appBarTheme: AppBarTheme(backgroundColor: Colors.red),
        //brightness: Brightness.light,
      //),
      //home: HomePage(),
    //);