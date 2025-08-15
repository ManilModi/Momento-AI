import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Widget buildDrawer(BuildContext context, String? profilePic) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        UserAccountsDrawerHeader(
          accountName: const Text(""),
          accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ""),
          currentAccountPicture: CircleAvatar(
            backgroundImage: profilePic != null
                ? NetworkImage(profilePic)
                : const AssetImage("assets/default_avatar.png") as ImageProvider,
          ),
          decoration: const BoxDecoration(
            color: Colors.blueGrey,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text("Help & Support"),
          onTap: () {
            Navigator.pushNamed(context, '/help');
          },
        ),
        ListTile(
          leading: const Icon(Icons.contact_mail),
          title: const Text("Contact Us"),
          onTap: () {
            Navigator.pushNamed(context, '/contact');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text("Logout"),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            GoogleSignIn().signOut();
            Navigator.of(context).pushReplacementNamed('/');
          },
        ),
      ],
    ),
  );
}
