import 'package:flutter/material.dart';
import 'package:teste/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = '';
  String password = '';

  Widget _body() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(padding: EdgeInsets.only(top: 50)),
          Center(child: Image.asset('assets/images/logo3.png', width: 200)),

          Padding(padding: EdgeInsets.only(top: 50)),
          //Center(child: Image.asset('assets/images/logo2.png')),
          Text(
            "LOGIN",
            style: TextStyle(
              fontSize: 60,
              color: Colors.black87,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 60)),
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (text) {
                email = text;
              },
              style: TextStyle(
                fontSize: 20,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 15,
                ),
                prefixIcon: const Icon(Icons.email),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.black12, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),

                labelText: 'Email',
                labelStyle: TextStyle(fontSize: 20),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 40)),
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (text) {
                password = text;
              },
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 15,
                ),
                prefixIcon: const Icon(Icons.password),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.black12, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),

                labelText: 'Password',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontSize: 20),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 60)),
          ElevatedButton(
            onPressed: () {
              if (email == 'xamuel@gmail.com' && password == '1234') {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Login'),
          ),
          Padding(padding: EdgeInsets.only(top: 40)),
          Text("Esqueceu sua senha?"),
        ],
      ),
    );
  }

  Widget background() {
    return Container(
      height: 1000,
      width: 500,
      decoration: BoxDecoration(
        color: Color(0xFF7A1315),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(500)),
        //image: DecorationImage(
        //image: AssetImage('assets/images/retangulo.png'),
        //fit: BoxFit.cover,
        //),
      ),
    );
  }

  Widget background2() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Image.asset('assets/images/retangulo.png', fit: BoxFit.cover),
    );
  }

  Widget background3(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          margin: EdgeInsets.only(top: 210),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF0000),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              background3(context), // seu fundo
              _body(), // seu conteúdo
            ],
          ),
        ),
      ),
    );
  }
}
