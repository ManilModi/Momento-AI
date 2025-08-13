import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';

class EventGalleryScreen extends StatefulWidget {
  final String eventId;
  const EventGalleryScreen({super.key, required this.eventId});

  @override
  State<EventGalleryScreen> createState() => _EventGalleryScreenState();
}

class _EventGalleryScreenState extends State<EventGalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUploadedImages();
  }

  // Fetch images already uploaded for this event
  Future<void> _fetchUploadedImages() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/event/${widget.eventId}/images'), // Replace with your GET endpoint
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _uploadedImageUrls = data.map((e) => e['url'] as String).toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch images");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching images: $e")));
    }
  }

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
          Uri.parse('http://10.0.2.2:8000/vectorize'), // Your upload endpoint
        );

        request.fields['event_id'] = widget.eventId;
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
      _selectedImages.clear();
      _fetchUploadedImages(); // Refresh the gallery after upload
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Gallery"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: GridView.builder(
                itemCount: _uploadedImageUrls.length + _selectedImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, index) {
                  if (index < _uploadedImageUrls.length) {
                    return Image.network(
                      _uploadedImageUrls[index],
                      fit: BoxFit.cover,
                    );
                  } else {
                    final localIndex = index - _uploadedImageUrls.length;
                    return Image.file(
                      File(_selectedImages[localIndex].path),
                      fit: BoxFit.cover,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            _isUploading
                ? const CircularProgressIndicator()
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImages,
                  child: const Text("Select Images"),
                ),
                ElevatedButton(
                  onPressed: _uploadImages,
                  child: const Text("Upload Images"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
