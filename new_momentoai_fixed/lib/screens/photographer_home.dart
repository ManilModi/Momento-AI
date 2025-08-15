import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'photographer_events_screen.dart';
import '../drawer_widget.dart';
import 'addEvent_screen.dart';

class PhotographerHome extends StatelessWidget {
  final String businessId;
  final String? profilePic;

  const PhotographerHome({super.key, required this.businessId, this.profilePic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photographer Dashboard"),
        backgroundColor: Colors.indigo,
      ),
      drawer: buildDrawer(context, profilePic),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCard(
              context,
              "Add Event",
              Icons.add_box,
              Colors.indigo.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEventScreen()),
                );
              },
            ),
            _buildCard(
              context,
              "All Events",
              Icons.event_note,
              Colors.indigo.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PhotographerEventsScreen(businessId: businessId)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      shadowColor: color.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap ?? () {},
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
