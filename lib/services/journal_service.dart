import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/journal_entry.dart';

class JournalService {
  static const String _boxName = 'journal_entries';
  Box<JournalEntry>? _box;

  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<JournalEntry>(_boxName);
    } catch (e) {
      print('Error opening journal box: $e');
    }
  }

  // Get all journal entries for a specific trip
  List<JournalEntry> getEntriesForTrip(String tripId) {
    if (_box == null) return [];
    
    return _box!.values
        .where((entry) => entry.tripId == tripId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get all journal entries across all trips
  List<JournalEntry> getAllEntries() {
    if (_box == null) return [];
    
    return _box!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get recent entries (last 30 days)
  List<JournalEntry> getRecentEntries({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return getAllEntries()
        .where((entry) => entry.timestamp.isAfter(cutoffDate))
        .toList();
  }

  // Add a new journal entry
  Future<void> addEntry(JournalEntry entry) async {
    if (_box == null) await initialize();
    await _box?.add(entry);
  }

  // Update an existing entry
  Future<void> updateEntry(JournalEntry entry) async {
    await entry.save();
  }

  // Delete an entry
  Future<void> deleteEntry(JournalEntry entry) async {
    await entry.delete();
  }

  // Get entries by mood
  List<JournalEntry> getEntriesByMood(String mood) {
    return getAllEntries()
        .where((entry) => entry.mood == mood)
        .toList();
  }

  // Get entries by location (within radius)
  List<JournalEntry> getEntriesNearLocation(
    double latitude, 
    double longitude, 
    {double radiusKm = 5.0}
  ) {
    return getAllEntries()
        .where((entry) {
          if (entry.latitude == null || entry.longitude == null) return false;
          
          final distance = Geolocator.distanceBetween(
            latitude, longitude,
            entry.latitude!, entry.longitude!,
          ) / 1000; // Convert to km
          
          return distance <= radiusKm;
        })
        .toList();
  }

  // Get statistics for a trip
  Map<String, dynamic> getTripJournalStats(String tripId) {
    final entries = getEntriesForTrip(tripId);
    
    if (entries.isEmpty) {
      return {
        'totalEntries': 0,
        'totalPhotos': 0,
        'moodDistribution': <String, int>{},
        'averageEntriesPerDay': 0.0,
        'firstEntry': null,
        'lastEntry': null,
      };
    }
    
    final moodCount = <String, int>{};
    int totalPhotos = 0;
    
    for (final entry in entries) {
      moodCount[entry.mood] = (moodCount[entry.mood] ?? 0) + 1;
      totalPhotos += entry.photoPaths.length;
    }
    
    final firstEntry = entries.last;
    final lastEntry = entries.first;
    final daysDiff = lastEntry.timestamp.difference(firstEntry.timestamp).inDays + 1;
    
    return {
      'totalEntries': entries.length,
      'totalPhotos': totalPhotos,
      'moodDistribution': moodCount,
      'averageEntriesPerDay': entries.length / daysDiff,
      'firstEntry': firstEntry,
      'lastEntry': lastEntry,
    };
  }

  // Search entries by text content
  List<JournalEntry> searchEntries(String query) {
    if (query.isEmpty) return getAllEntries();
    
    final lowercaseQuery = query.toLowerCase();
    
    return getAllEntries()
        .where((entry) =>
            entry.title.toLowerCase().contains(lowercaseQuery) ||
            entry.content.toLowerCase().contains(lowercaseQuery) ||
            (entry.locationName?.toLowerCase().contains(lowercaseQuery) ?? false))
        .toList();
  }

  // Get entries for a specific date range
  List<JournalEntry> getEntriesInDateRange(DateTime start, DateTime end) {
    return getAllEntries()
        .where((entry) =>
            entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList();
  }

  // Export journal entries as text
  String exportJournalAsText(String tripId, String tripName) {
    final entries = getEntriesForTrip(tripId);
    final stats = getTripJournalStats(tripId);
    
    final buffer = StringBuffer();
    buffer.writeln('$tripName - Travel Journal');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('Total Entries: ${stats['totalEntries']}');
    buffer.writeln('Total Photos: ${stats['totalPhotos']}');
    buffer.writeln('');
    
    for (final entry in entries.reversed) { // Chronological order for export
      buffer.writeln('=' * 50);
      buffer.writeln(entry.title);
      buffer.writeln('Date: ${_formatDateTime(entry.timestamp)}');
      buffer.writeln('Mood: ${entry.mood}');
      if (entry.locationName != null) {
        buffer.writeln('Location: ${entry.locationName}');
      }
      if (entry.weather != null) {
        buffer.writeln('Weather: ${entry.weather}');
      }
      buffer.writeln('');
      buffer.writeln(entry.content);
      if (entry.photoPaths.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Photos: ${entry.photoPaths.length} attached');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  // Get mood distribution for visualization
  Map<String, int> getMoodDistribution({String? tripId}) {
    final entries = tripId != null ? getEntriesForTrip(tripId) : getAllEntries();
    final moodCount = <String, int>{};
    
    for (final entry in entries) {
      moodCount[entry.mood] = (moodCount[entry.mood] ?? 0) + 1;
    }
    
    return moodCount;
  }

  // Create a sample journal entry for new trips
  Future<void> createWelcomeEntry(String tripId, String tripName) async {
    final entry = JournalEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_welcome',
      tripId: tripId,
      title: 'Welcome to $tripName!',
      content: 'This is the beginning of your travel journal for $tripName. '
               'Document your experiences, memories, and adventures here. '
               'Add photos, record your mood, and capture the essence of your journey!',
      mood: '🎉',
      timestamp: DateTime.now(),
    );
    
    await addEntry(entry);
  }

  // Get current location for journal entries
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Clear all entries for a trip
  Future<void> clearTripJournal(String tripId) async {
    final entries = getEntriesForTrip(tripId);
    for (final entry in entries) {
      await entry.delete();
    }
  }
}
