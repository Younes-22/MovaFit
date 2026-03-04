import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart'; // <--- Import this
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

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
    // Wrap MaterialApp with ValueListenableBuilder
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Motivafit',
          debugShowCheckedModeBanner: false,
          
          // --- THEME CONFIGURATION ---
          themeMode: currentMode,
          
          // Light Theme (Material 3)
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, 
              brightness: Brightness.light
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[50],
          ),
          
          // Dark Theme (Material 3)
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, 
              brightness: Brightness.dark
            ),
            useMaterial3: true,
            // Dark mode specific tweaks if needed
          ),

          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}