import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // No navigation needed; AuthWrapper in main.dart handles it automatically
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
            ),
            TextButton(
              child: const Text('Create Account'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAccountScreen())),
            )
          ],
        ),
      ),
    );
  }
}