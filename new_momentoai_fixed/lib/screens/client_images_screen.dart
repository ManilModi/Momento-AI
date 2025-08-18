import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ClientImagesScreen extends StatefulWidget {
  const ClientImagesScreen({super.key});

  @override
  State<ClientImagesScreen> createState() => _ClientImagesScreenState();
}

class _ClientImagesScreenState extends State<ClientImagesScreen> {
  int _selectedTab = 0; // 0 = Add Event, 1 = All Events

  final _businessIdController = TextEditingController();
  final _eventIdController = TextEditingController();

  // Local storage for added events
  List<Map<String, dynamic>> events = [];

  void _addEvent() {
    final businessId = _businessIdController.text.trim();
    final eventId = _eventIdController.text.trim();

    if (businessId.isEmpty || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both Business ID and Event ID")),
      );
      return;
    }

    setState(() {
      events.add({
        "business_id": businessId,
        "event_id": eventId,
        "images": [], // images will be uploaded later
      });

      _businessIdController.clear();
      _eventIdController.clear();
      _selectedTab = 1; // switch to All Events
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event added successfully!")),
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 0),
            child: Card(
              color: _selectedTab == 0 ? Colors.blue : Colors.grey[200],
              elevation: _selectedTab == 0 ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    "Add Event",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 0 ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = 1),
            child: Card(
              color: _selectedTab == 1 ? Colors.blue : Colors.grey[200],
              elevation: _selectedTab == 1 ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    "All Events",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 1 ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
    if (events.isEmpty) {
      return const Center(child: Text("No events added yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              "Event: ${event["event_id"]}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Business: ${event["business_id"]}"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to an "Upload Images" page for this event
            },
          ),
        );
      },
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
              child: _selectedTab == 0 ? _buildAddEvent() : _buildAllEvents(),
            ),
          ),
        ],
      ),
    );
  }
}
