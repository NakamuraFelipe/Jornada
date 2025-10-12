import 'package:flutter/material.dart';
// ignore: unused_import
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
          Padding(padding: EdgeInsets.only(top: 70)),
          Center(child: Image.asset('assets/images/logo3.png', width: 200)),

          Padding(padding: EdgeInsets.only(top: 70)),
          //Center(child: Image.asset('assets/images/logo2.png')),
          Text(
            "LOGIN",
            style: TextStyle(
              fontSize: 60,
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 50)),
          SizedBox(
            width: 320,
            child: TextField(
              style: TextStyle(
                fontSize: 20,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white, width: 2),
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
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    width: 2,
                  ),
                ),

                labelText: 'Password',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontSize: 20),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 40)),
          ElevatedButton(onPressed: () {}, child: Text('Entrar')),
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

  Widget background3() {
    return Padding(
      padding: EdgeInsets.only(top: 240),
      child: Container(
        height: 600,
        width: 800,
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFF0000),
      resizeToAvoidBottomInset: false,
      body: Stack(children: [background3(), _body()]),
    );
  }
}
