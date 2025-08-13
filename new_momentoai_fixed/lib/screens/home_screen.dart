import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Momento AI"),
        backgroundColor: Colors.indigo,
        actions: [
          CircleAvatar(
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : const AssetImage('assets/avatar_placeholder.png')
            as ImageProvider,
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _buildBody(context, user),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : const AssetImage('assets/avatar_placeholder.png')
              as ImageProvider,
            ),
            decoration: const BoxDecoration(color: Colors.indigo),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, User? user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildActionCard(
            context,
            icon: Icons.photo_library,
            title: "View My Photos",
            onTap: () {},
          ),
          _buildActionCard(
            context,
            icon: Icons.search,
            title: "Search by Face",
            onTap: () {},
          ),
          _buildActionCard(
            context,
            icon: Icons.image_search,
            title: "Search by Object",
            onTap: () {},
          ),
          _buildActionCard(
            context,
            icon: Icons.event,
            title: "My Events",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.indigo),
            const SizedBox(height: 10),
            Text(
              title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
