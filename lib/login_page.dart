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
          Padding(padding: EdgeInsets.only(top: 70)),
          Center(child: Image.asset('assets/images/logo.png')),
          Padding(padding: EdgeInsets.only(top: 10)),
          Center(child: Image.asset('assets/images/logo2.png')),

          Padding(padding: EdgeInsets.only(top: 40)),
          SizedBox(
            width: 320,
            child: TextField(
              style: TextStyle(fontSize: 20, color: Colors.white),
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
                labelStyle: TextStyle(color: Colors.white, fontSize: 20),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 40)),
          SizedBox(
            width: 320,
            child: TextField(
              style: TextStyle(fontSize: 20, color: Colors.white),
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

                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white, fontSize: 20),
                border: OutlineInputBorder(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [background(), _body()]),
    );
  }
}
