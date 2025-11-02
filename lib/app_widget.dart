import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:teste/Login_page.dart';
import 'package:teste/app_controler.dart';
import 'package:teste/buscar_lead.dart';
import 'package:teste/criar_leads.dart';
import 'package:teste/gerenciar_pap.dart';
// ignore: undefined_hidden_name
import 'package:teste/home_page.dart' hide AppControler;
import 'package:teste/home_page_gestor.dart';
import 'package:teste/inicio.dart';
import 'package:teste/meus_leads.dart';

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
          initialRoute: '/login',
          routes: {
            '/gestor': (context) => HomePage_Gestor(),
            '/login': (context) => LoginPage(),
            '/pap': (context) => GerenciarPAP(),
            '/home': (context) => HomePage(),
            '/inicio': (context) => Inicio(),
            '/leads': (context) => CreateLead(),
            '/meus_leads': (context) => MeusLeads(),
            '/buscar_leads': (context) => BuscarLead(),
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