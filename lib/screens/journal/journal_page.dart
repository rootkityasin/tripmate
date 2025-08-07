import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/journal_entry.dart';
import '../../services/journal_service.dart';
import 'new_journal_entry_page.dart';

class JournalPage extends StatefulWidget {
  final String? tripId;
  final String tripName;
  final bool showAllEntries;

  const JournalPage({
    super.key,
    this.tripId,
    required this.tripName,
    this.showAllEntries = false,
  });

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final JournalService _journalService = JournalService();
  final TextEditingController _searchController = TextEditingController();
  List<JournalEntry> _entries = [];
  List<JournalEntry> _filteredEntries = [];
  bool _isLoading = true;
  String _selectedMoodFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    await _journalService.initialize();
    setState(() {
      if (widget.showAllEntries) {
        _entries = _journalService.getAllEntries();
      } else if (widget.tripId != null) {
        _entries = _journalService.getEntriesForTrip(widget.tripId!);
      } else {
        _entries = [];
      }
      _filteredEntries = _entries;
      _isLoading = false;
    });
  }

  void _filterEntries() {
    setState(() {
      _filteredEntries = _entries.where((entry) {
        final matchesSearch =
            _searchController.text.isEmpty ||
            entry.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            entry.content.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            (entry.locationName?.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ??
                false);

        final matchesMood =
            _selectedMoodFilter == 'all' || entry.mood == _selectedMoodFilter;

        return matchesSearch && matchesMood;
      }).toList();
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

  Future<void> _editEntry(JournalEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewJournalEntryPage()),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${entry.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _journalService.deleteEntry(entry);
      _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry deleted'),
            backgroundColor: Color(0xFF2C2C2E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // Apple Journal Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.tripName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.tripId != null)
                    IconButton(
                      onPressed: _addNewEntry,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                  IconButton(
                    onPressed: () => _showMoreOptions(),
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            if (_entries.isNotEmpty) _buildAppleSearchBar(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : _filteredEntries.isEmpty
                  ? _buildAppleEmptyState()
                  : _buildAppleJournalList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppleSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white.withOpacity(0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search entries...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (_) => _filterEntries(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _filterEntries();
              },
              child: Icon(
                Icons.clear,
                color: Colors.white.withOpacity(0.6),
                size: 20,
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.3),
                  Colors.purple.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 60,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.tripId != null ? 'No entries yet' : 'No entries found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.tripId != null
                ? 'Start documenting your\ntravel experiences'
                : 'Try adjusting your search',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 17,
              height: 1.4,
            ),
          ),
          if (widget.tripId != null) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _addNewEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Add First Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppleJournalList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = _filteredEntries[index];
        return _buildAppleEntryCard(entry);
      },
    );
  }

  Widget _buildAppleEntryCard(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editEntry(entry),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date and mood
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatAppleDate(entry.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        if (entry.mood.isNotEmpty)
                          Text(
                            entry.mood,
                            style: const TextStyle(fontSize: 20),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showEntryOptions(entry),
                          child: Icon(
                            Icons.more_horiz,
                            color: Colors.white.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                      ],
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

                // Location and photos info
                if (entry.locationName != null ||
                    entry.photoPaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (entry.locationName != null) ...[
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.locationName!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        if (entry.photoPaths.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.photo,
                            size: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.photoPaths.length}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ] else if (entry.photoPaths.isNotEmpty) ...[
                        Icon(
                          Icons.photo,
                          size: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entry.photoPaths.length} photo${entry.photoPaths.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAppleDate(DateTime date) {
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.analytics_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Statistics',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showStats();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined, color: Colors.white),
              title: const Text(
                'Export Journal',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportJournal();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEntryOptions(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: const Text(
                'Edit Entry',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _editEntry(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Entry',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteEntry(entry);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _exportJournal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: Color(0xFF2C2C2E),
      ),
    );
  }

  void _showStats() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Statistics view coming soon!'),
        backgroundColor: Color(0xFF2C2C2E),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Add/Edit Journal Entry Page
class AddEditJournalEntryPage extends StatefulWidget {
  final String tripId;
  final String tripName;
  final JournalEntry? entry;

  const AddEditJournalEntryPage({
    super.key,
    required this.tripId,
    required this.tripName,
    this.entry,
  });

  @override
  State<AddEditJournalEntryPage> createState() =>
      _AddEditJournalEntryPageState();
}

class _AddEditJournalEntryPageState extends State<AddEditJournalEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _weatherController = TextEditingController();
  final JournalService _journalService = JournalService();

  String _selectedMood = '😊';
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  final List<String> _moodOptions = [
    '😊',
    '😍',
    '🤔',
    '😎',
    '🥰',
    '😅',
    '🙂',
    '😌',
    '😴',
    '🤩',
    '😂',
    '🥳',
    '😇',
    '🤗',
    '🥺',
    '😋',
    '🤤',
    '🤪',
    '😜',
    '🙃',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _populateFields();
    }
    _journalService.initialize();
  }

  void _populateFields() {
    final entry = widget.entry!;
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _locationController.text = entry.locationName ?? '';
    _weatherController.text = entry.weather ?? '';
    _selectedMood = entry.mood;
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      setState(() {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: const Color(0xFF2C2C2E),
          ),
        );
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in title and content'),
          backgroundColor: Color(0xFF2C2C2E),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final photoPaths = _selectedImages.map((file) => file.path).toList();

      if (widget.entry != null) {
        // Update existing entry
        final entry = widget.entry!;
        entry.title = _titleController.text;
        entry.content = _contentController.text;
        entry.mood = _selectedMood;
        entry.locationName = _locationController.text.isEmpty
            ? null
            : _locationController.text;
        entry.weather = _weatherController.text.isEmpty
            ? null
            : _weatherController.text;
        entry.photoPaths = photoPaths;

        await _journalService.updateEntry(entry);
      } else {
        // Create new entry
        final location = await _journalService.getCurrentLocation();

        final entry = JournalEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tripId: widget.tripId,
          title: _titleController.text,
          content: _contentController.text,
          mood: _selectedMood,
          timestamp: DateTime.now(),
          photoPaths: photoPaths,
          locationName: _locationController.text.isEmpty
              ? null
              : _locationController.text,
          weather: _weatherController.text.isEmpty
              ? null
              : _weatherController.text,
          latitude: location?['latitude'],
          longitude: location?['longitude'],
        );

        await _journalService.addEntry(entry);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: const Color(0xFF2C2C2E),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // Apple-style header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.orange, fontSize: 17),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.entry != null ? 'Edit Entry' : 'New Entry',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _saveEntry,
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: _isLoading
                            ? Colors.orange.withOpacity(0.5)
                            : Colors.orange,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _titleController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Entry title...',
                                hintStyle: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Content field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _contentController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'What happened today?',
                                hintStyle: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              maxLines: 8,
                              minLines: 8,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mood selection
                          const Text(
                            'How are you feeling?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _moodOptions.map((mood) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMood = mood;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _selectedMood == mood
                                          ? Colors.orange.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: _selectedMood == mood
                                          ? Border.all(
                                              color: Colors.orange,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      mood,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Location field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _locationController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Add location',
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Weather field
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wb_sunny,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _weatherController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Add weather',
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Photos section
                          Row(
                            children: [
                              const Text(
                                'Photos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Add Photos',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            image: DecorationImage(
                                              image: FileImage(
                                                _selectedImages[index],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
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
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _weatherController.dispose();
    super.dispose();
  }
}
