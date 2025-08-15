import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photographer_home.dart'; // Separate photographer home screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data(); // contains role and business_id
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!;
        final role = userData['role'];
        final businessId = userData['business_id'];
        final profilePic = FirebaseAuth.instance.currentUser?.photoURL;

        if (role == 'Photographer') {
          return PhotographerHome(businessId: businessId, profilePic: profilePic);
        } else {
          return const Scaffold(
            body: Center(child: Text("Unauthorized or role not found")),
          );
        }
      },
    );
  }
}
