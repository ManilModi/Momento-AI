import 'package:flutter/material.dart';
import 'add_event_screen.dart'; // <-- Import your AddEventScreen file

class PhotographerHome extends StatelessWidget {
  final String? businessId;

  const PhotographerHome({super.key, this.businessId});

  Widget _buildActionCard(BuildContext context, IconData icon, String title, VoidCallback onTap) {
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
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photographer Dashboard"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Assuming FirebaseAuth sign out
              // await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
              context,
              Icons.add_box,
              "Add Event",
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEventScreen()),
                );
              },
            ),
            _buildActionCard(context, Icons.event_note, "All Events", () {}),
            _buildActionCard(context, Icons.photo_library, "Event Gallery", () {}),
            if (businessId != null)
              _buildActionCard(context, Icons.business, "Business ID: $businessId", () {}),
          ],
        ),
      ),
    );
  }
}
