import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MotivafitApp());
}

class MotivafitApp extends StatelessWidget {
  const MotivafitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motivafit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
