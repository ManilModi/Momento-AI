import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessIdController = TextEditingController(); // New field
  String _selectedRole = "client"; // default role

  final List<String> _roles = ["photographer", "client", "admin"];

  Future<void> _signUp() async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save role, businessId, and email in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'business_id': _businessIdController.text.trim().isNotEmpty
            ? _businessIdController.text.trim()
            : "", // fallback if empty
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign up successful")),
      );

      // Navigate to Login page
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
              DropdownButtonFormField(
                value: _selectedRole,
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: const InputDecoration(labelText: "Select Role"),
              ),

              // Business ID field (needed for photographers)
              if (_selectedRole == "photographer") ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _businessIdController,
                  decoration: const InputDecoration(
                    labelText: "Business ID",
                  ),
                ),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signUp,
                child: const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
