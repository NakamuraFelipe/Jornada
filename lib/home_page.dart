import 'package:flutter/material.dart';
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
      drawer: Drawer(
        child: ListTile(
          leading: Icon(Icons.home),
          title: Text('inicio'),
          subtitle: Text('tela de inicio'),
          onTap: () {
            print('home');
          },
        ),
      ),
      appBar: AppBar(title: Text('Home Page'), actions: [CustomSwitcher()]),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Contador: $counter'),
            CustomSwitcher(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 50, height: 50, color: Colors.black),
                Container(width: 50, height: 50, color: Colors.black),
                Container(width: 50, height: 50, color: Colors.black),
              ],
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          setState(() {
            counter++;
          });
        },
      ),
    );
  }
}

class CustomSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: AppControler.instance.isDarkTheme,
      onChanged: (value) {
        AppControler.instance.changeTheme();
      },
    );
  }
}
