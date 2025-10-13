import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:teste/app_controler.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(height: 10, color: Color(0xFFFF0000)),
          Container(
            width: double.infinity,
            padding: EdgeInsetsDirectional.only(
              top: 25,
              start: 15,
              end: 15,
              bottom: 10,
            ),
            color: Color(0xFFFF0000),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Foto + texto ao lado
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage(
                        'assets/images/foto_perfil_teste.png',
                      ),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: Offset(0, -15),
                          child: Text(
                            'Conta : Consultor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, -7),
                          child: Text(
                            'Olá, Xamuel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Logo à direita
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [Image.asset('assets/images/logo.png', height: 50)],
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          // Conteúdo central (botões)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Container(
                  width: 350,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF0000).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 15,
                        child: Text(
                          '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 15,
                        child: Text(
                          'Bem vindo ao APP Ademicon.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 35,
                        left: 15,
                        child: Text(
                          'Você tem 5 notificações de seus LEADS',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 70,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 16,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 5,
                          ),
                          child: Text('notificações'),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(padding: EdgeInsets.only(top: 20)),
                // Linha 1: Buscar Leads e Criar Leads
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          padding: EdgeInsets.symmetric(
                            vertical: 25,
                          ), // aumento da altura
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Buscar Leads',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          padding: EdgeInsets.symmetric(
                            vertical: 25,
                          ), // aumento da altura
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Criar Leads',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Linha 2: Meus Leads
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 5,
                    padding: EdgeInsets.symmetric(vertical: 25), // maior altura
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Text('Meus Leads', style: TextStyle(fontSize: 18)),
                  ),
                ),
                SizedBox(height: 20),
                // Linha 3: Leads Salvos
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 5,
                    padding: EdgeInsets.symmetric(vertical: 25), // maior altura
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Center(
                    child: Text('Leads Salvos', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
          Spacer(), // empurra o rodapé para baixo
          // Rodapé fixo
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 4),
            color: Color(0xFFFF0000),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(15),
                  backgroundColor: Colors.white,
                  elevation: 5,
                ),
                child: Icon(Icons.home, color: Colors.black, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
