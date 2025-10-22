import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste/app_widget.dart';

main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(appWidget(title: 'Teste'));
}
