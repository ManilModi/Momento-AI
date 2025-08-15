import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UploadEventImagesScreen extends StatefulWidget {
  final String businessId;

  const UploadEventImagesScreen({super.key, required this.businessId});

  @override
  State<UploadEventImagesScreen> createState() => _UploadEventImagesScreenState();
}

class _UploadEventImagesScreenState extends State<UploadEventImagesScreen> {
  String? selectedEventId;
  List<Map<String, dynamic>> events = [];
  List<XFile> selectedImages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final url = Uri.parse(
        "http://10.0.2.2:8000/events?business_id=${widget.businessId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          events = data.map((e) => e as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception("Failed to load events");
      }
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        selectedImages = images;
      });
    }
  }

  Future<void> _uploadImages() async {
    if (selectedEventId == null || selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select event & images first")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://10.0.2.2:8000/upload-event-images"),
      );

      request.fields['business_id'] = widget.businessId;
      request.fields['event_id'] = selectedEventId!;

      for (var img in selectedImages) {
        request.files.add(await http.MultipartFile.fromPath('images', img.path));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Images uploaded successfully")),
        );
        setState(() {
          selectedImages.clear();
          selectedEventId = null;
        });
      } else {
        throw Exception("Failed to upload images");
      }
    } catch (e) {
      print("Error uploading images: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Event Images")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedEventId,
              decoration: const InputDecoration(labelText: "Select Event"),
              items: events
                  .map((e) => DropdownMenuItem<String>(
                value: e['event_id'].toString(),
                child: Text(e['title'] ?? "Untitled Event"),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedEventId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text("Pick Images"),
              onPressed: _pickImages,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: selectedImages.isEmpty
                  ? const Center(child: Text("No images selected"))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: selectedImages.length,
                itemBuilder: (context, index) {
                  return Image.file(File(selectedImages[index].path), fit: BoxFit.cover);
                },
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadImages,
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
