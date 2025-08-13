import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show basename;


class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _eventIdController = TextEditingController();
  final _eventNameController = TextEditingController();
  bool _isLoading = false;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _createEvent() async {
    if (_eventIdController.text.isEmpty || _eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both Event ID and Name")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = _auth.currentUser!.uid;

      // Fetch business_id
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final businessId = userDoc.data()?['business_id'] ?? '';

      await _firestore.collection('events').doc(_eventIdController.text).set({
        'event_id': _eventIdController.text,
        'event_name': _eventNameController.text,
        'photographer_id': uid,
        'business_id': businessId,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully!")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventGalleryScreen(
            eventId: _eventIdController.text,
            businessId: businessId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating event: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(label == "Event ID" ? Icons.tag : Icons.event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Event"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField("Event ID", _eventIdController),
            const SizedBox(height: 16),
            _buildTextField("Event Name", _eventNameController),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createEvent,
                icon: const Icon(Icons.add_box),
                label: const Text("Create Event"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventGalleryScreen extends StatefulWidget {
  final String eventId;
  final String businessId;
  const EventGalleryScreen({super.key, required this.eventId, required this.businessId});

  @override
  State<EventGalleryScreen> createState() => _EventGalleryScreenState();
}

class _EventGalleryScreenState extends State<EventGalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select images first")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      for (var image in _selectedImages) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.0.2.2:8000/vectorize')
        );

        request.fields['event_id'] = widget.eventId;
        request.fields['business_id'] = widget.businessId;
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            filename: basename(image.path),
          ),
        );

        var response = await request.send();

        if (response.statusCode != 200) {
          throw Exception("Failed to upload ${image.name}");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All images uploaded successfully!")),
      );
      setState(() => _selectedImages.clear());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildImageGrid() {
    return _selectedImages.isEmpty
        ? const Center(child: Text("No images selected"))
        : GridView.builder(
      itemCount: _selectedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, index) {
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(_selectedImages[index].path),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Gallery"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(child: _buildImageGrid()),
            const SizedBox(height: 16),
            _isUploading
                ? const CircularProgressIndicator()
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Select Images"),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadImages,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Upload Images"),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
