import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Account?'),
        content: const Text(
          'This will reset your Level, XP, Coins, and Inventory to zero. '
          'Your Tasks will remain, but stats will be wiped. '
          'This is intended for testing/demos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirestoreService().resetAccount();
              if (ctx.mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(ctx); // Go back to Home
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account Reset Successful')),
                );
              }
            },
            child: const Text('RESET EVERYTHING'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // --- Section: Account ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context); // Close settings
              AuthService().signOut();
            },
          ),
          
          const Divider(),

          // --- Section: Debug Zone ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Debug Zone (For Demo)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset User Stats'),
            subtitle: const Text('Set Level 1, 0 XP, 0 Coins'),
            onTap: () => _showResetConfirmation(context),
          ),

          const Divider(),

          // --- Section: App Info ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Motivafit'),
            subtitle: Text('Final Year Project v1.0'),
          ),
        ],
      ),
    );
  }
}