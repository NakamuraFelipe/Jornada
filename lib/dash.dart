import 'package:flutter/material.dart';

class DashPage extends StatefulWidget {
  @override
  _DashPageState createState() => _DashPageState();
}

class _DashPageState extends State<DashPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Lead'),
        backgroundColor: Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: Center(child: Text('Página de Dash')),
    );
  }
}
