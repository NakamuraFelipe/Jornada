import 'package:flutter/material.dart';

class PerfilPage extends StatefulWidget {
  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 290,
                    decoration: BoxDecoration(color: Color(0xFFD32F2F)),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -40,
                          left: -40,
                          child: Opacity(
                            opacity: 0.18,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 50,
                          right: -20,
                          child: Opacity(
                            opacity: 0.15,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 30,
                          left: 40,
                          child: Opacity(
                            opacity: 0.12,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FOTO + NOME + BOTÃO DE CÂMERA
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 40,
                    bottom: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // FOTO COM ÍCONE
                        Stack(
                          children: [
                            // FOTO
                            CircleAvatar(
                              radius: 90,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: AssetImage(
                                'assets/images/foto_perfil_teste.png',
                              ),
                            ),

                            // BOTÃO DE CÂMERA
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

                        const SizedBox(height: 10),

                        // NOME
                        const Text(
                          "Xamuel Silva",
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
            ),

            // ---------------- INFO DO PERFIL ----------------
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Colors.grey[700]),
                      SizedBox(width: 15),
                      Text(
                        "Email:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Xamuel@gmail.com",
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 0.3, color: Colors.black26),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey[700]),
                      SizedBox(width: 15),
                      Text(
                        "Telefone:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "55(43) 9 9123-4567",
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 0.3, color: Colors.black26),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.badge, color: Colors.grey[700]),
                      SizedBox(width: 15),
                      Text(
                        "Cargo:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Gestor",
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 0.3, color: Colors.black26),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number, color: Colors.grey[700]),
                      SizedBox(width: 15),
                      Text(
                        "Matricula:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "125.659.874-0",
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 0.3, color: Colors.black26),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(
                        0xFFD32F2F,
                      ), // vermelho do seu tema
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      print('Botão clicado');
                    },
                    child: const Center(
                      child: Text(
                        'Trocar Telefone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 3,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(
                        0xFFD32F2F,
                      ), // vermelho do seu tema
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      print('Botão clicado');
                    },
                    child: const Center(
                      child: Text(
                        'Trocar Senha',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
