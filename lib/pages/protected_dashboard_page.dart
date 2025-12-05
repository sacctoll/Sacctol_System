import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class ProtectedDashboardPage extends StatelessWidget {
  const ProtectedDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => _showPasswordDialog(context));
    return const Scaffold();
  }

  void _showPasswordDialog(BuildContext context) async {
    final TextEditingController passwordController = TextEditingController();
    const correctPassword = 'admin123';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('Dashboard Access'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter password to access the business dashboard',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.password),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  final entered = passwordController.text;
                  Navigator.of(context).pop(entered == correctPassword);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Enter'),
              onPressed: () {
                final entered = passwordController.text;
                Navigator.of(context).pop(entered == correctPassword);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
