import 'package:flutter/material.dart';

class AppControler extends ChangeNotifier {
  static AppControler instance = AppControler();

  bool isDarkTheme = false;
  changeTheme() {
    isDarkTheme = !isDarkTheme;
    notifyListeners();
  }
}
