import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'event_images_screen.dart';

class ClientImagesScreen extends StatefulWidget {
  const ClientImagesScreen({super.key});

  @override
  State<ClientImagesScreen> createState() => _ClientImagesScreenState();
}

class _ClientImagesScreenState extends State<ClientImagesScreen> {
  int _selectedTab = 0; // 0 = Add Event, 1 = All Events, 2 = Prompt Search

  final _businessIdController = TextEditingController();
  final _eventIdController = TextEditingController();
  final _promptController = TextEditingController();

  final User? currentUser = FirebaseAuth.instance.currentUser;

  List<String> _searchResults = [];
  bool _isSearching = false;

  Future<void> _addEvent() async {
    final businessId = _businessIdController.text.trim();
    final eventId = _eventIdController.text.trim();

    if (businessId.isEmpty || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both Business ID and Event ID")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("added_events").add({
        "business_id": businessId,
        "event_id": eventId,
        "uid": currentUser?.uid ?? "",
        "createdAt": FieldValue.serverTimestamp(),
        "createdAtLocal": DateTime.now().millisecondsSinceEpoch,
      });

      _businessIdController.clear();
      _eventIdController.clear();

      setState(() {
        _selectedTab = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event added successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add event: $e")),
      );
    }
  }

  Future<void> _searchByPrompt() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      // 1. Fetch event_ids accessible to this client
      final snapshot = await FirebaseFirestore.instance
          .collection("added_events")
          .where("uid", isEqualTo: currentUser?.uid ?? "")
          .get();

      final eventIds = snapshot.docs
          .map((doc) => doc["event_id"] as String)
          .toList();

      if (eventIds.isEmpty) {
        throw Exception("No accessible events found.");
      }

      // 2. Build query string
      final eventIdsParam = eventIds.join(",");
      final url =
          "https://momento-ai-1-42230574747.asia-south1.run.app/search?prompt=$query&top_k=10&event_ids=$eventIdsParam";

      // 3. Call backend
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = List<Map<String, dynamic>>.from(data["results"]);
        setState(() {
          _searchResults = results.map((e) => e["url"] as String).toList();
          _isSearching = false;
        });
      } else {
        throw Exception("Failed to search: ${response.body}");
      }
    } catch (e) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  Widget _buildTabSelector() {
    return Row(
      children: [
        _tabButton("Add Event", 0),
        const SizedBox(width: 8),
        _tabButton("All Events", 1),
        const SizedBox(width: 8),
        _tabButton("Prompt Search", 2),
      ],
    );
  }

  Widget _tabButton(String text, int tabIndex) {
    final isSelected = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Card(
          color: isSelected ? Colors.blue : Colors.grey[200],
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddEvent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _businessIdController,
          decoration: const InputDecoration(
            labelText: "Business ID",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _eventIdController,
          decoration: const InputDecoration(
            labelText: "Event ID",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: _addEvent,
          child: const Text("Add Event"),
        ),
      ],
    );
  }

  Widget _buildAllEvents() {
    if (currentUser == null) {
      return const Center(child: Text("Not logged in"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("added_events")
          .where("uid", isEqualTo: currentUser!.uid)
          .orderBy("createdAtLocal", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No events added yet"));
        }

        final events = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final data = events[index].data() as Map<String, dynamic>;
            final eventId = data["event_id"] ?? "Unknown";
            final businessId = data["business_id"] ?? "Unknown";

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(
                  "Event: $eventId",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Business: $businessId"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventImagesScreen(
                        businessId: businessId,
                        eventId: eventId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPromptSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: "Enter prompt",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchByPrompt,
                child: const Text("Search"),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? const Center(child: Text("No results yet"))
              : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final url = _searchResults[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImage(url: url),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url, fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Dashboard"),
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildTabSelector(),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedTab == 0
                  ? _buildAddEvent()
                  : _selectedTab == 1
                  ? _buildAllEvents()
                  : _buildPromptSearch(),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String url;
  const FullScreenImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}
