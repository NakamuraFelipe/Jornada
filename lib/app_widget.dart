import 'package:flutter/material.dart';
import 'package:teste/Login_page.dart';
import 'package:teste/app_controler.dart';
import 'package:teste/home_page.dart';

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
          initialRoute: '/',
          routes: {
            '/': (context) => LoginPage(),
            '/home': (context) => HomePage(),
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