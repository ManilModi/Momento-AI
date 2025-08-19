import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Screen with two tabs
class SearchScreen extends StatefulWidget {
  final String businessId;
  final String eventId;

  const SearchScreen({
    super.key,
    required this.businessId,
    required this.eventId,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Images"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "By Image"),
            Tab(text: "By Prompt"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ImageSearchTab(
            businessId: widget.businessId,
            eventId: widget.eventId,
          ),
          PromptSearchTab(),
        ],
      ),
    );
  }
}

/// 🔹 Tab 1 - Search by Image
class ImageSearchTab extends StatefulWidget {
  final String businessId;
  final String eventId;

  const ImageSearchTab({
    super.key,
    required this.businessId,
    required this.eventId,
  });

  @override
  State<ImageSearchTab> createState() => _ImageSearchTabState();
}

class _ImageSearchTabState extends State<ImageSearchTab> {
  bool isLoading = false;
  String? queryImage;
  List<String> matchedImages = [];

  Future<void> _pickAndSearchImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => isLoading = true);

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://10.0.2.2:8000/find-face"),
      )
        ..fields['business_id'] = widget.businessId
        ..fields['event_id'] = widget.eventId
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        setState(() {
          queryImage = data["uploaded_image_url"];
          matchedImages = List<String>.from(data["matched_images"] ?? []);
        });
      } else {
        debugPrint("Error: ${response.statusCode} $body");
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageGallery(
          images: matchedImages,
          initialIndex: matchedImages.indexOf(imageUrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text("Pick Image & Search"),
          onPressed: _pickAndSearchImage,
        ),
        if (isLoading) const LinearProgressIndicator(),
        if (queryImage != null)
          Column(
            children: [
              const SizedBox(height: 8),
              const Text("Query Image:"),
              Image.network(queryImage!, height: 150),
              const Divider(),
            ],
          ),
        Expanded(
          child: matchedImages.isEmpty
              ? const Center(child: Text("No matches yet"))
              : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: matchedImages.length,
            itemBuilder: (context, index) {
              final url = matchedImages[index];
              return GestureDetector(
                onTap: () => _openFullScreen(url),
                child: Image.network(url, fit: BoxFit.cover),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 🔹 Tab 2 - Search by Prompt
class PromptSearchTab extends StatefulWidget {
  const PromptSearchTab({super.key});

  @override
  State<PromptSearchTab> createState() => _PromptSearchTabState();
}

class _PromptSearchTabState extends State<PromptSearchTab> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  List<Map<String, dynamic>> results = [];

  Future<void> _search() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final url =
      Uri.parse("http://10.0.2.2:8000/search?prompt=$prompt&top_k=10");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          results = List<Map<String, dynamic>>.from(data["results"]);
        });
      } else {
        debugPrint("Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _openFullScreen(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageGallery(
          images: results.map((r) => r["url"] as String).toList(),
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration:
                  const InputDecoration(labelText: "Enter search prompt"),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ],
          ),
        ),
        if (isLoading) const LinearProgressIndicator(),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text("No results yet"))
              : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final res = results[index];
              return GestureDetector(
                onTap: () => _openFullScreen(index),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(res["url"], fit: BoxFit.cover),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(2),
                        child: Text(
                          res["score"].toStringAsFixed(2),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 🔹 Fullscreen gallery with swipe
class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (_, index) => InteractiveViewer(
          child: Image.network(widget.images[index]),
        ),
      ),
    );
  }
}
