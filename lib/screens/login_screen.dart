import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await AuthService().signInWithGoogle();
              },
              child: const Text("Login with Google"),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
