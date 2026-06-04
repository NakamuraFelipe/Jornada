import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dash_page.dart';
import 'dash_page_consultor.dart';

class DashboardWrapper extends StatefulWidget {
  const DashboardWrapper({super.key});

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  bool isLoading = true;
  Widget? dashboard;

  @override
  void initState() {
    super.initState();
    _verificarCargo();
  }

  Future<void> _verificarCargo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String cargo = 'consultor'; // padrão

    if (token != null && token.isNotEmpty) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          String payloadBase64 = parts[1];
          while (payloadBase64.length % 4 != 0) payloadBase64 += '=';
          payloadBase64 = payloadBase64.replaceAll('-', '+').replaceAll('_', '/');
          final bytes = base64.decode(payloadBase64);
          final payload = json.decode(utf8.decode(bytes));
          cargo = payload['cargo'] ?? 'consultor';
        }
      } catch (e) {
        print('Erro ao decodificar token: $e');
      }
    }

    setState(() {
      isLoading = false;
      if (cargo == 'gestor') {
        dashboard = DashPage();        // dashboard do gestor (original)
      } else {
        dashboard = DashPageConsultor(); // dashboard do consultor (simplificado)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return dashboard ?? DashPageConsultor();
  }
}