import 'package:flutter/material.dart';
import 'saved_carts_page.dart'; // Your real page

class ProtectedSavedCartsPage extends StatelessWidget {
  const ProtectedSavedCartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => _showPasswordDialog(context));
    return const Scaffold(); // Empty while waiting for password
  }

  void _showPasswordDialog(BuildContext context) async {
  final TextEditingController _passwordController = TextEditingController();
  final correctPassword = 'admin123'; // Change as needed

  final formKey = GlobalKey<FormState>();

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return AlertDialog(
        title: const Text('Enter Password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onFieldSubmitted: (_) {
              final entered = _passwordController.text;
              Navigator.of(context).pop(entered == correctPassword);
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text('Enter'),
            onPressed: () {
              final entered = _passwordController.text;
              Navigator.of(context).pop(entered == correctPassword);
            },
          ),
        ],
      );
    },
  );

  if (result == true) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SavedCartsPage()),
    );
  } else {
    Navigator.of(context).pop(); // Exit page if password failed
  }
}

}
