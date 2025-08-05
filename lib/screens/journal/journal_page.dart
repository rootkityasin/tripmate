import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/journal_entry.dart';
import '../../services/journal_service.dart';
import '../../constants/app_styles.dart';

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

  final List<String> _moodOptions = [
    '😊', '😍', '🤔', '😎', '🥰', '😅', '🙂', '😌', '😴', '🤩',
    '😂', '🥳', '😇', '🤗', '🥺', '😋', '🤤', '🤪', '😜', '🙃'
  ];

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
        final matchesSearch = _searchController.text.isEmpty ||
            entry.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            entry.content.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (entry.locationName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);

        final matchesMood = _selectedMoodFilter == 'all' || entry.mood == _selectedMoodFilter;

        return matchesSearch && matchesMood;
      }).toList();
    });
  }

  Future<void> _addNewEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJournalEntryPage(
          tripId: widget.tripId ?? '',
          tripName: widget.tripName,
        ),
      ),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  Future<void> _editEntry(JournalEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditJournalEntryPage(
          tripId: widget.tripId ?? entry.tripId,
          tripName: widget.tripName,
          entry: entry,
        ),
      ),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
          const SnackBar(content: Text('Journal entry deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '${widget.tripName} Journal',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppStyles.primaryGradient,
          ),
        ),
        actions: [
          if (widget.tripId != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: AppStyles.glassDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: 15,
                withBorder: false,
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, size: 22),
                onPressed: _addNewEntry,
                tooltip: 'Add new entry',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: AppStyles.glassDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: 15,
              withBorder: false,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, size: 22),
              onSelected: (value) {
                if (value == 'export') {
                  _exportJournal();
                } else if (value == 'stats') {
                  _showStats();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'stats',
                  child: Container(
                    decoration: AppStyles.glassDecoration(
                      borderRadius: 12,
                      withBorder: false,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: const Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.black87, size: 20),
                        SizedBox(width: 12),
                        Text('Statistics', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Container(
                    decoration: AppStyles.glassDecoration(
                      borderRadius: 12,
                      withBorder: false,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: const Row(
                      children: [
                        Icon(Icons.download_for_offline_outlined, color: Colors.black87, size: 20),
                        SizedBox(width: 12),
                        Text('Export Journal', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppStyles.backgroundColor,
              AppStyles.surfaceColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: AppStyles.glassDecoration(borderRadius: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: AppStyles.modernButtonDecoration(borderRadius: 30),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading journal entries...',
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppStyles.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: Column(
                  children: [
                    _buildSearchAndFilter(),
                    Expanded(child: _buildEntriesList()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Glass search bar
          Container(
            decoration: AppStyles.glassDecoration(borderRadius: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your memories...',
                hintStyle: TextStyle(
                  color: AppStyles.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.24,
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: AppStyles.primaryColor,
                    size: 22,
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: AppStyles.glassDecoration(
                          borderRadius: 16,
                          withBorder: false,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppStyles.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterEntries();
                          },
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              ),
              style: AppStyles.bodyLarge,
              onChanged: (_) => _filterEntries(),
            ),
          ),
          const SizedBox(height: 16),
          // Glass mood filter chips
          SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildMoodFilterChip('all', 'All Moods', isFirst: true),
                const SizedBox(width: 12),
                ..._moodOptions.map((mood) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildMoodFilterChip(mood, mood),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodFilterChip(String mood, String label, {bool isFirst = false}) {
    final isSelected = _selectedMoodFilter == mood;
    return Container(
      decoration: AppStyles.glassDecoration(
        color: isSelected 
            ? AppStyles.primaryColor.withOpacity(0.2)
            : AppStyles.glassBackground,
        borderRadius: 18,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedMoodFilter = isSelected ? 'all' : mood;
              _filterEntries();
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected && mood != 'all')
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: mood == 'all' ? 15 : 18,
                    color: isSelected ? AppStyles.primaryColor : AppStyles.textSecondary,
                    letterSpacing: -0.24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (_filteredEntries.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = _filteredEntries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        decoration: AppStyles.glassDecoration(borderRadius: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: AppStyles.modernButtonDecoration(borderRadius: 50),
              child: Icon(
                widget.tripId != null ? Icons.book_rounded : Icons.search_off_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.tripId != null ? 'No journal entries yet' : 'No entries found',
              style: AppStyles.headingMedium.copyWith(
                color: AppStyles.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.tripId != null 
                  ? 'Start documenting your travel experiences and create lasting memories'
                  : 'Try adjusting your search terms or mood filters',
              style: AppStyles.bodyLarge.copyWith(
                color: AppStyles.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.tripId != null) ...[
              const SizedBox(height: 32),
              Container(
                decoration: AppStyles.modernButtonDecoration(borderRadius: 18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addNewEntry,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add First Entry',
                            style: AppStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: AppStyles.modernCardDecoration(borderRadius: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _editEntry(entry),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Mood container with glass effect
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AppStyles.glassDecoration(
                          color: AppStyles.primaryColor.withOpacity(0.1),
                          borderRadius: 16,
                        ),
                        child: Text(
                          entry.mood,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: AppStyles.headingSmall.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: AppStyles.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDateTime(entry.timestamp),
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppStyles.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: AppStyles.glassDecoration(
                          borderRadius: 16,
                          withBorder: false,
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: AppStyles.textSecondary,
                            size: 22,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editEntry(entry);
                            } else if (value == 'delete') {
                              _deleteEntry(entry);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Container(
                                decoration: AppStyles.glassDecoration(
                                  borderRadius: 12,
                                  withBorder: false,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit_note_rounded, color: Colors.black87, size: 20),
                                    SizedBox(width: 12),
                                    Text('Edit', style: TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Container(
                                decoration: AppStyles.glassDecoration(
                                  borderRadius: 12,
                                  withBorder: false,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Content with glass background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppStyles.glassDecoration(
                      color: AppStyles.backgroundColor.withOpacity(0.3),
                      borderRadius: 16,
                    ),
                    child: Text(
                      entry.content,
                      style: AppStyles.bodyLarge.copyWith(
                        height: 1.6,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tags row with glass chips
                  Row(
                    children: [
                      if (entry.locationName != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: AppStyles.glassDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: 20,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_rounded, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 6),
                              Text(
                                entry.locationName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.08,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (entry.photoPaths.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: AppStyles.glassDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: 20,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera_rounded, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 6),
                              Text(
                                '${entry.photoPaths.length} photo${entry.photoPaths.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.08,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _exportJournal() {
    // TODO: Implement journal export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
  }

  void _showStats() {
    // TODO: Implement statistics view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Statistics view coming soon!')),
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
  State<AddEditJournalEntryPage> createState() => _AddEditJournalEntryPageState();
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
    '😊', '😍', '🤔', '😎', '🥰', '😅', '🙂', '😌', '😴', '🤩',
    '😂', '🥳', '😇', '🤗', '🥺', '😋', '🤤', '🤪', '😜', '🙃'
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
    
    // TODO: Load existing images from paths
    // _selectedImages = entry.photoPaths.map((path) => File(path)).toList();
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
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and content')),
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
        entry.locationName = _locationController.text.isEmpty ? null : _locationController.text;
        entry.weather = _weatherController.text.isEmpty ? null : _weatherController.text;
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
          locationName: _locationController.text.isEmpty ? null : _locationController.text,
          weather: _weatherController.text.isEmpty ? null : _weatherController.text,
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
          SnackBar(content: Text('Error saving entry: $e')),
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
      backgroundColor: AppStyles.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.entry != null ? 'Edit Entry' : 'New Entry',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppStyles.primaryGradient,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: AppStyles.modernButtonDecoration(borderRadius: 18),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _saveEntry,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: _isLoading ? Colors.white60 : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Save',
                        style: TextStyle(
                          color: _isLoading ? Colors.white60 : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppStyles.backgroundColor,
              AppStyles.surfaceColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: AppStyles.glassDecoration(borderRadius: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: AppStyles.modernButtonDecoration(borderRadius: 30),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Saving your memories...',
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppStyles.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field with glass design
                      Container(
                        decoration: AppStyles.modernCardDecoration(borderRadius: 20),
                        child: TextField(
                          controller: _titleController,
                          style: AppStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Entry Title',
                            labelStyle: AppStyles.bodyMedium,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Content field with glass design
                      Container(
                        decoration: AppStyles.modernCardDecoration(borderRadius: 20),
                        child: TextField(
                          controller: _contentController,
                          style: AppStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Your thoughts and experiences...',
                            labelStyle: AppStyles.bodyMedium,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(20),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 8,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Mood selection with glass design
                      Text(
                        'How are you feeling?',
                        style: AppStyles.headingSmall,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppStyles.modernCardDecoration(borderRadius: 20),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _moodOptions.map((mood) {
                            return Container(
                              decoration: AppStyles.glassDecoration(
                                color: _selectedMood == mood
                                    ? AppStyles.primaryColor.withOpacity(0.2)
                                    : AppStyles.glassBackground,
                                borderRadius: 16,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedMood = mood;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      mood,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Location field with glass design
                      Container(
                        decoration: AppStyles.modernCardDecoration(borderRadius: 20),
                        child: TextField(
                          controller: _locationController,
                          style: AppStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Location (optional)',
                            labelStyle: AppStyles.bodyMedium,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(20),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: AppStyles.glassDecoration(
                                borderRadius: 12,
                                withBorder: false,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Weather field with glass design
                      Container(
                        decoration: AppStyles.modernCardDecoration(borderRadius: 20),
                        child: TextField(
                          controller: _weatherController,
                          style: AppStyles.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Weather (optional)',
                            labelStyle: AppStyles.bodyMedium,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(20),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: AppStyles.glassDecoration(
                                borderRadius: 12,
                                withBorder: false,
                              ),
                              child: Icon(
                                Icons.wb_sunny_rounded,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Photos section with glass design
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppStyles.modernCardDecoration(borderRadius: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Photos',
                                  style: AppStyles.headingSmall,
                                ),
                                const Spacer(),
                                Container(
                                  decoration: AppStyles.modernButtonDecoration(borderRadius: 16),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _pickImages,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.add_photo_alternate_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Add Photos',
                                              style: AppStyles.bodyMedium.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                              borderRadius: BorderRadius.circular(16),
                                              image: DecorationImage(
                                                image: FileImage(_selectedImages[index]),
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
                                                  Icons.close_rounded,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), // Extra space at bottom
                    ],
                  ),
                ),
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
