import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      home: AuthTestPage(),
    );
  }
}

class AuthTestPage extends StatelessWidget {
  AuthTestPage({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Auth Test')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Create test user'),
          onPressed: () async {
            try {
              final result = await _auth.signUp(
                email: 'test${DateTime.now().millisecondsSinceEpoch}@test.com',
                password: 'password123',
              );

              debugPrint('User created: ${result.user?.uid}');
            } catch (e) {
              debugPrint('Auth error: $e');
            }
          },
        ),
      ),
    );
  }
}
