import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vanta_app/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/auth_gate.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vanta',
      theme: ThemeData.dark(), // langsung kasih aura elite 😄
      //home: const AuthGate(), // 🔥 INI KUNCINYA
home: AuthWrapper()
    );
  }
}
