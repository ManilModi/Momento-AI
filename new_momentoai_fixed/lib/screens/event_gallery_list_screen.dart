import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html'; // Avoid File issues on web
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class EventGalleryScreen extends StatefulWidget {
  final String businessId;
  final String eventId;

  const EventGalleryScreen({
    super.key,
    required this.businessId,
    required this.eventId,
  });

  @override
  State<EventGalleryScreen> createState() => _EventGalleryScreenState();
}

class _EventGalleryScreenState extends State<EventGalleryScreen> {
  List<String> imageUrls = [];
  List<PlatformFile> selectedImages = [];
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        "http://10.0.2.2:8000/event-images?business_id=${widget.businessId}&event_id=${widget.eventId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          imageUrls = List<String>.from(data['images'] ?? []);
        });
      } else {
        debugPrint("Failed to load images: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching images: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result != null) {
        setState(() => selectedImages = result.files);
      }
    } else {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          selectedImages = images
              .map((xfile) => PlatformFile(
            name: xfile.name,
            path: xfile.path,
            size: File(xfile.path!).lengthSync(),
          ))
              .toList();
        });
      }
    }
  }

  Future<void> _uploadImages() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select images first")),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      for (var img in selectedImages) {
        final request = http.MultipartRequest(
          "POST",
          Uri.parse("http://10.0.2.2:8000/vectorize"),
        )
          ..fields['business_id'] = widget.businessId
          ..fields['event_id'] = widget.eventId;

        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            img.bytes!,
            filename: img.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            img.path!,
          ));
        }

        final response = await request.send();
        if (response.statusCode != 200) {
          debugPrint("Upload failed for ${img.name} (${response.statusCode})");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Images uploaded successfully")),
      );
      setState(() => selectedImages.clear());
      await _fetchImages();
    } catch (e) {
      debugPrint("Error uploading images: $e");
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Gallery")),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : imageUrls.isEmpty
                ? const Center(child: Text("No images yet"))
                : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
                  ),
                );
              },
            ),
          ),

          if (selectedImages.isNotEmpty) ...[
            const Divider(),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final img = selectedImages[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.memory(
                      img.bytes!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                        : Image.file(
                      File(img.path!),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],

          const Divider(),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text("Pick Images"),
                  onPressed: _pickImages,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: isUploading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.cloud_upload),
                  label: const Text("Upload"),
                  onPressed: isUploading ? null : _uploadImages,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
