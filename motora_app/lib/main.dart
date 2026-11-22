import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MotoraApp());
}

class MotoraApp extends StatelessWidget {
  const MotoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motora',
      debugShowCheckedModeBanner: false,
      theme: motoraTheme,
      home: const HomeScreen(),
    );
  }
}
