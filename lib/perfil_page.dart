import 'package:flutter/material.dart';

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: Container(
          margin: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black38, width: 0.3),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(width: double.infinity, height: 120),

                  Positioned(
                    left: 20,
                    top: 20,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: AssetImage(
                            'assets/images/foto_perfil_teste.png',
                          ),
                        ),

                        const SizedBox(width: 15),

                        // NOME
                        const Text(
                          "Xamuel Silva",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                child: const Text(
                  "Email: xamuel.silva@example.com",
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ),
              Container(
                padding: EdgeInsets.all(15),
                child: const Text(
                  "Cargo: Gestor",
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
