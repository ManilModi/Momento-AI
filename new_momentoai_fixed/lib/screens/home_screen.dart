import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
        } else if (role == 'Client') {
          return ClientHome(profilePic: profilePic);
        } else if (role == 'Admin') {
          return AdminHome(profilePic: profilePic);
        } else {
          return const Scaffold(
            body: Center(child: Text("Role not found")),
          );
        }
      },
    );
  }
}

// ================= Photographer Home =================
class PhotographerHome extends StatelessWidget {
  final String? businessId;
  final String? profilePic;

  const PhotographerHome({super.key, this.businessId, this.profilePic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photographer Dashboard"),
        backgroundColor: Colors.indigo,
      ),
      drawer: _buildDrawer(context, profilePic),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(context, "Add Event", Icons.event, Colors.indigo.shade400),
            _buildCard(context, "All Events", Icons.event_note, Colors.indigo.shade600),
            _buildCard(context, "Event Gallery", Icons.photo_library, Colors.indigo.shade700),
            if (businessId != null)
              _buildCard(context, "Business ID: $businessId", Icons.business, Colors.indigo.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: color.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Client Home =================
class ClientHome extends StatelessWidget {
  final String? profilePic;

  const ClientHome({super.key, this.profilePic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Dashboard"),
        backgroundColor: Colors.green,
      ),
      drawer: _buildDrawer(context, profilePic),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(context, "View Events", Icons.event_available, Colors.green.shade400),
          _buildTile(context, "Book Photographer", Icons.book_online, Colors.green.shade600),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}

// ================= Admin Home =================
class AdminHome extends StatelessWidget {
  final String? profilePic;

  const AdminHome({super.key, this.profilePic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.red,
      ),
      drawer: _buildDrawer(context, profilePic),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTile(context, "Manage Users", Icons.manage_accounts, Colors.red.shade400),
          _buildTile(context, "View Reports", Icons.report, Colors.red.shade600),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}

// ================= Drawer =================
Widget _buildDrawer(BuildContext context, String? profilePic) {
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
          decoration: BoxDecoration(
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
