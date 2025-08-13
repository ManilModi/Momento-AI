class PhotographerHome extends StatelessWidget {
  const PhotographerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Photographer Dashboard")),
      body: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        padding: const EdgeInsets.all(16),
        children: [
          _buildActionCard(
            icon: Icons.add_box,
            title: "Add Event",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEventScreen()),
              );
            },
          ),
          _buildActionCard(
            icon: Icons.event,
            title: "All Events",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventListScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
