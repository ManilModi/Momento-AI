import 'package:flutter/material.dart';
import '../drawer_widget.dart';
import 'client_images_screen.dart';
import 'client_search_screen.dart';

class ClientHome extends StatelessWidget {
  final String businessId;
  final String eventId;
  final String? profilePic;

  const ClientHome({
    super.key,
    required this.businessId,
    required this.eventId,
    this.profilePic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Dashboard"),
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
              "My Event Images",
              Icons.photo_album,
              Colors.indigo.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientImagesScreen(
                      businessId: businessId,
                      eventId: eventId,
                    ),
                  ),
                );
              },
            ),
            _buildCard(
              context,
              "Search Images",
              Icons.search,
              Colors.indigo.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientSearchScreen(
                      businessId: businessId,
                      eventId: eventId,
                    ),
                  ),
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
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
