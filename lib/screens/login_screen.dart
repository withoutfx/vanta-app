import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final user = await AuthService().signInWithGoogle();

            if (user != null) {
              print("LOGIN SUCCESS");
            } else {
              print("LOGIN FAILED");
            }
          },
          child: const Text("Login with Google"),
        ),
      ),
    );
  }
}
