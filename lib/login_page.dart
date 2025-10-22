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
  bool passwordText = true;

  Widget _body() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(padding: EdgeInsets.only(top: 80)),
          Center(child: Image.asset('assets/images/logo3.png', width: 160)),

          Padding(padding: EdgeInsets.only(top: 65)),
          //Center(child: Image.asset('assets/images/logo2.png')),
          Text(
            "LOGIN",
            style: TextStyle(
              fontSize: 55,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD32F2F),
              letterSpacing: 2,
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 40)),
          SizedBox(
            width: 300,

            child: TextField(
              onChanged: (text) {
                email = text;
              },
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
                prefixIcon: const Icon(Icons.email, color: Color(0xFFD32F2F)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Color(0xFFD32F2F)),
                ),

                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 40)),
          SizedBox(
            width: 300,
            child: TextField(
              obscureText: passwordText,
              onChanged: (text) {
                password = text;
              },
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
                prefixIcon: const Icon(Icons.lock, color: Color(0xFFD32F2F)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Color(0xFFD32F2F)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      passwordText = !passwordText;
                    });
                  },
                ),

                labelText: 'Password',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 40)),
          ElevatedButton(
            onPressed: () {
              if (email == 'xamuel@gmail.com' && password == '1234') {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
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
          margin: EdgeInsets.only(top: 230),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Color(0xFFD32F2F),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(children: [background3(context), _body()]),
          ),
        ),
      ),
    );
  }
}
