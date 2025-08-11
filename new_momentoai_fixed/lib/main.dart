import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Correct if using FlutterFire CLI

import 'screens/login_screen.dart'; // Correct path to your LoginScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // From FlutterFire CLI
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momento AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
