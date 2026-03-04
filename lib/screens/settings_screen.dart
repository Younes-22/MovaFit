import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../services/pdf_service.dart'; // <--- NEW IMPORT

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state to track the switch value visual
  bool _isDark = ThemeService().isDarkMode;
  final PdfService _pdfService = PdfService(); // <--- Instantiate PDF Service

  // --- ACTIONS ---

  void _handleLogout() {
    AuthService().signOut();
    // Pop until we are back at the login screen (handled by AuthWrapper usually)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleExportReport() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF Report... please wait.')),
    );

    try {
      await _pdfService.generateAndDownloadReport();
      // No need for success snackbar here as the "Share" sheet will open
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

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

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // --- Section: Appearance ---
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: _isDark,
            onChanged: (val) {
              setState(() {
                _isDark = val;
              });
              ThemeService().toggleTheme(val);
            },
          ),

          const Divider(),

          // --- Section: Data & Reports (NEW) ---
          _buildSectionHeader('Data & Reports'),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export Weekly Report'),
            subtitle: const Text('Download PDF summary'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _handleExportReport,
          ),

          const Divider(),

          // --- Section: Debug Zone ---
          _buildSectionHeader('Debug Zone (For Demo)'),
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.orange),
            title: const Text('Reset User Stats'),
            subtitle: const Text('Set Level 1, 0 XP, 0 Coins'),
            onTap: () => _showResetConfirmation(context),
          ),

          const Divider(),

          // --- Section: Account ---
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: _handleLogout,
          ),
          
          const Divider(),

          // --- Section: App Info ---
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Motivafit'),
            subtitle: Text('Final Year Project v1.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}