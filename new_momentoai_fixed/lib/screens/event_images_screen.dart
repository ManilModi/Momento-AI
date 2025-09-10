import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EventImagesScreen extends StatefulWidget {
  final String businessId;
  final String eventId;

  const EventImagesScreen({
    super.key,
    required this.businessId,
    required this.eventId,
  });

  @override
  State<EventImagesScreen> createState() => _EventImagesScreenState();
}

class _EventImagesScreenState extends State<EventImagesScreen> {
  List<String> eventImages = [];
  List<String> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  int _selectedTab = 0; // 0 = All, 1 = Prompt Search, 2 = Face Search
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEventImages();
  }

  Future<void> _fetchEventImages() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://momento-ai-1-42230574747.asia-south1.run.app/event-images?business_id=${widget.businessId}&event_id=${widget.eventId}",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          eventImages = List<String>.from(data["images"]);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load images: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Prompt search (uses /search)
  Future<void> _searchByPrompt() async {
    final query = _promptController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    try {
      final url =
          "https://momento-ai-1-42230574747.asia-south1.run.app/search?prompt=$query&top_k=10&event_ids=${widget.eventId}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults =
              List<Map<String, dynamic>>.from(data["results"]).map((e) => e["url"] as String).toList();
          isSearching = false;
        });
      } else {
        throw Exception("Failed to search: ${response.body}");
      }
    } catch (e) {
      setState(() => isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// Face search (uses /find-face)
  /// Face search (uses /find-face)
  Future<void> _searchByFace() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://momento-ai-1-42230574747.asia-south1.run.app/find-face"),
      );
      request.fields["business_id"] = widget.businessId;
      request.fields["event_id"] = widget.eventId;
      request.files.add(await http.MultipartFile.fromPath("file", picked.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);

        setState(() {
          // Correctly pick "image_url" instead of "url"
          searchResults = List<Map<String, dynamic>>.from(data["matched_images"])
              .map((e) => e["image_url"] as String)
              .toList();
          isSearching = false;
        });
      } else {
        throw Exception("Failed to search: $body");
      }
    } catch (e) {
      setState(() => isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  void _openFullScreen(int initialIndex, List<String> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenGallery(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildAllImages() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (eventImages.isEmpty) {
      return const Center(child: Text("No images found for this event"));
    }
    return _buildGrid(eventImages);
  }

  Widget _buildPromptSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
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
          child: isSearching
              ? const Center(child: CircularProgressIndicator())
              : searchResults.isEmpty
              ? const Center(child: Text("No results yet"))
              : _buildGrid(searchResults),
        ),
      ],
    );
  }

  Widget _buildFaceSearch() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _searchByFace,
            icon: const Icon(Icons.face_retouching_natural),
            label: const Text("Pick Face Image to Search"),
          ),
        ),
        Expanded(
          child: isSearching
              ? const Center(child: CircularProgressIndicator())
              : searchResults.isEmpty
              ? const Center(child: Text("No results yet"))
              : _buildGrid(searchResults),
        ),
      ],
    );
  }

  Widget _buildGrid(List<String> images) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imgUrl = images[index];
        return GestureDetector(
          onTap: () => _openFullScreen(index, images),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imgUrl, fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: [
        _tabButton("All Images", 0),
        const SizedBox(width: 8),
        _tabButton("Prompt Search", 1),
        const SizedBox(width: 8),
        _tabButton("Face Search", 2),
      ],
    );
  }

  Widget _tabButton(String text, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Card(
          color: isSelected ? Colors.blue : Colors.grey[200],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Event: ${widget.eventId}"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildTabSelector(),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedTab == 0
                  ? _buildAllImages()
                  : _selectedTab == 1
                  ? _buildPromptSearch()
                  : _buildFaceSearch(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full screen gallery with swipe + zoom support
class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("${_currentIndex + 1} / ${widget.images.length}"),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(widget.images[i]),
            ),
          );
        },
      ),
    );
  }
}
