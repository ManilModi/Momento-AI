import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Photographer';
  bool _isLoading = false;

  final List<String> roles = [
    'Photographer',
    'Client',
    'Admin',
  ];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // ----------------------
  // Shared user document creation
  // ----------------------
  Future<void> _createUserDocIfNeeded(User user, String role) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      String? businessId;
      if (role == 'Photographer') {
        businessId = const Uuid().v4();
      }

      await docRef.set({
        'email': user.email,
        'role': role,
        if (businessId != null) 'business_id': businessId,
      });
    }
  }

  // ----------------------
  // Email & password login
  // ----------------------
  Future<void> _signInWithEmail() async {
    try {
      setState(() => _isLoading = true);

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;
      await _createUserDocIfNeeded(user, _selectedRole);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged in as $_selectedRole")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ----------------------
  // Google login
  // ----------------------
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Check existing role in Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      String role;
      if (doc.exists) {
        role = doc['role'];
      } else {
        role = _selectedRole;
        await _createUserDocIfNeeded(user, role);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signed in with Google as $role")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In failed")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: roles
                  .map((role) =>
                  DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value!),
              decoration: const InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _signInWithEmail,
              child: const Text("Login with Email"),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const SizedBox.shrink()
                : OutlinedButton.icon(
              onPressed: _signInWithGoogle,
              icon: const Icon(Icons.login),
              label: const Text("Login with Google"),
            ),
          ],
        ),
      ),
    );
  }
}
