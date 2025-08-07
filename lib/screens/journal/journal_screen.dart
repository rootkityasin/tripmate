import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/journal_service.dart';
import '../../models/journal_entry.dart';
import 'new_journal_entry_page.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final JournalService _journalService = JournalService();
  List<JournalEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    await _journalService.initialize();
    final entries = _journalService.getAllEntries();
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  Future<void> _addNewEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewJournalEntryPage()),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Journal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 100,
                    ), // Add padding for FAB
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          )
                        : _entries.isEmpty
                        ? _buildAppleEmptyState()
                        : _buildJournalList(),
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button positioned above nav bar
          Positioned(
            bottom: 100, // Position above the navigation bar
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _addNewEntry,
                  icon: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppleEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Butterfly icon like in Apple Journal
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.8),
                  const Color(0xFF4ECDC4).withOpacity(0.8),
                  const Color(0xFF45B7D1).withOpacity(0.8),
                  const Color(0xFFF9CA24).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          const Text(
            'Start Journaling',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            'Create your personal journal.\nTap the plus button to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 17,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to entry details - for now just show the entry creation page
                _addNewEntry();
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and mood
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(entry.timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (entry.mood.isNotEmpty)
                          Text(
                            entry.mood,
                            style: const TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Content preview
                    Text(
                      entry.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),

                    // Photo Grid
                    if (entry.photoPaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPhotoGrid(entry.photoPaths),
                    ],

                    // Location indicator
                    if (entry.locationName != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              entry.locationName!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference} days ago';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildPhotoGrid(List<String> photoPaths) {
    if (photoPaths.isEmpty) return const SizedBox.shrink();

    final remainingCount = photoPaths.length > 2 ? photoPaths.length - 2 : 0;

    return Container(
      height: 200,
      child: Row(
        children: [
          // Left half - Main photo (takes up 50% width)
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _showPhotoViewer(photoPaths, 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF3C3C3E),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photoPaths.isNotEmpty
                      ? (photoPaths[0].startsWith('http')
                            ? Image.network(
                                photoPaths[0],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: const Color(0xFF3C3C3E),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 32,
                                      ),
                                    ),
                              )
                            : Image.file(
                                File(photoPaths[0]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: const Color(0xFF3C3C3E),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 32,
                                      ),
                                    ),
                              ))
                      : Container(
                          color: const Color(0xFF3C3C3E),
                          child: Icon(
                            Icons.image,
                            color: Colors.white.withOpacity(0.5),
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Right half - 2x2 grid (takes up 50% width)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Top row
                Expanded(
                  child: Row(
                    children: [
                      // Top left - Steps walked
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(
                              0xFF8B5A3C,
                            ), // Walking icon brown color
                          ),
                          child: Center(
                            child: Icon(
                              Icons.directions_walk,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Top right - Second photo or additional count
                      Expanded(
                        child: GestureDetector(
                          onTap: photoPaths.length > 1
                              ? () => _showPhotoViewer(photoPaths, 1)
                              : null,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF3C3C3E),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: photoPaths.length > 1
                                  ? (photoPaths[1].startsWith('http')
                                        ? Image.network(
                                            photoPaths[1],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: const Color(
                                                        0xFF3C3C3E,
                                                      ),
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                        size: 16,
                                                      ),
                                                    ),
                                          )
                                        : Image.file(
                                            File(photoPaths[1]),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: const Color(
                                                        0xFF3C3C3E,
                                                      ),
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                        size: 16,
                                                      ),
                                                    ),
                                          ))
                                  : Container(
                                      color: const Color(0xFF3C3C3E),
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Bottom row
                Expanded(
                  child: Row(
                    children: [
                      // Bottom left - Map view
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFF34C759), // Map green color
                          ),
                          child: Center(
                            child: Icon(
                              Icons.map,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bottom right - Additional photos count
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: remainingCount > 0
                                ? const Color(0xFF48484A).withOpacity(0.8)
                                : const Color(0xFF3C3C3E),
                          ),
                          child: remainingCount > 0
                              ? Center(
                                  child: Text(
                                    '+$remainingCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    '0:43', // Video duration placeholder
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoViewer(List<String> photoPaths, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${initialIndex + 1} of ${photoPaths.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photoPaths.length,
            itemBuilder: (context, index) {
              final photoPath = photoPaths[index];
              return Center(
                child: InteractiveViewer(
                  child: photoPath.startsWith('http')
                      ? Image.network(
                          photoPath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                        )
                      : Image.file(
                          File(photoPath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
