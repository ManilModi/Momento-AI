import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photographer_home.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong. Please try again.")),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("User data not found")),
          );
        }

        final userData = snapshot.data!;
        final role = userData['role'] ?? '';
        final businessId = userData['business_id'] ?? '';
        final profilePic = FirebaseAuth.instance.currentUser?.photoURL ?? '';
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        if (role.toLowerCase() == 'photographer') {
          return PhotographerHome(
            businessId: businessId,
            profilePic: profilePic,
          );
        } else {
          return const Scaffold(
            body: Center(child: Text("Unauthorized or role not found")),
          );
        }
      },
    );
  }
}
