import 'package:hive_flutter/hive_flutter.dart';
import '../models/checklist_item.dart';

class ChecklistService {
  static const String _boxName = 'checklist_items';
  Box<ChecklistItem>? _box;

  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<ChecklistItem>(_boxName);
    } catch (e) {
      print('Error opening checklist box: $e');
    }
  }

  // Get all checklist items for a specific trip
  List<ChecklistItem> getItemsForTrip(String tripId) {
    if (_box == null) return [];

    return _box!.values.where((item) => item.tripId == tripId).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.priority.compareTo(a.priority);
      });
  }

  // Get items by category for a trip
  List<ChecklistItem> getItemsByCategoryForTrip(
    String tripId,
    String category,
  ) {
    if (_box == null) return [];

    return _box!.values
        .where(
          (item) =>
              item.tripId == tripId &&
              item.category == category.toLowerCase().replaceAll(' ', '_'),
        )
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  // Add a new checklist item
  Future<void> addItem(ChecklistItem item) async {
    if (_box == null) await initialize();
    await _box?.add(item);
  }

  // Update an existing item
  Future<void> updateItem(ChecklistItem item) async {
    await item.save();
  }

  // Delete an item
  Future<void> deleteItem(ChecklistItem item) async {
    await item.delete();
  }

  // Toggle item completion status
  Future<void> toggleItemCompletion(ChecklistItem item) async {
    item.isCompleted = !item.isCompleted;
    item.completedAt = item.isCompleted ? DateTime.now() : null;
    await item.save();
  }

  // Get completion statistics for a trip
  Map<String, dynamic> getTripStats(String tripId) {
    final items = getItemsForTrip(tripId);
    final completed = items.where((item) => item.isCompleted).length;
    final total = items.length;

    return {
      'completed': completed,
      'total': total,
      'percentage': total > 0 ? (completed / total * 100).round() : 0,
      'remaining': total - completed,
    };
  }

  // Get items by priority
  List<ChecklistItem> getHighPriorityItems(String tripId) {
    return getItemsForTrip(
      tripId,
    ).where((item) => item.priority >= 4 && !item.isCompleted).toList();
  }

  // Create default checklist items for Bangladesh trip
  Future<void> createDefaultBangladeshChecklist(String tripId) async {
    final templates = [
      // Essential Documents
      {
        'title': 'Passport/National ID',
        'category': 'essential_items',
        'priority': 5,
        'description': 'Valid identification document',
      },
      {
        'title': 'Travel Insurance',
        'category': 'essential_items',
        'priority': 4,
        'description': 'Medical and travel coverage',
      },
      {
        'title': 'Hotel Bookings',
        'category': 'essential_items',
        'priority': 4,
        'description': 'Accommodation confirmations',
      },
      {
        'title': 'Emergency Contacts',
        'category': 'essential_items',
        'priority': 5,
        'description': 'Important phone numbers',
      },

      // Personal Items
      {
        'title': 'Mosquito Repellent',
        'category': 'clothing_&_personal',
        'priority': 5,
        'description': 'Essential for tropical climate',
      },
      {
        'title': 'Light Cotton Clothing',
        'category': 'clothing_&_personal',
        'priority': 4,
        'description': 'For humid weather',
      },
      {
        'title': 'Comfortable Walking Shoes',
        'category': 'clothing_&_personal',
        'priority': 4,
        'description': 'For exploring',
      },
      {
        'title': 'Umbrella/Raincoat',
        'category': 'clothing_&_personal',
        'priority': 3,
        'description': 'For monsoon protection',
      },
      {
        'title': 'Sunscreen & Sunglasses',
        'category': 'clothing_&_personal',
        'priority': 3,
        'description': 'UV protection',
      },
      {
        'title': 'Personal Medications',
        'category': 'clothing_&_personal',
        'priority': 5,
        'description': 'Prescription drugs and first aid',
      },

      // Electronics
      {
        'title': 'Phone Charger',
        'category': 'electronics_&_gadgets',
        'priority': 4,
        'description': 'Don\'t forget the cable!',
      },
      {
        'title': 'Power Bank',
        'category': 'electronics_&_gadgets',
        'priority': 4,
        'description': 'For charging on the go',
      },
      {
        'title': 'Universal Power Adapter',
        'category': 'electronics_&_gadgets',
        'priority': 3,
        'description': 'Type C/G plugs used in Bangladesh',
      },
      {
        'title': 'Camera',
        'category': 'electronics_&_gadgets',
        'priority': 3,
        'description': 'Capture beautiful memories',
      },

      // Bangladesh Specific
      {
        'title': 'Bangladesh Taka (Cash)',
        'category': 'essential_items',
        'priority': 5,
        'description': 'Local currency for transactions',
      },
      {
        'title': 'Local SIM Card Info',
        'category': 'electronics_&_gadgets',
        'priority': 3,
        'description': 'GP, Robi, or Banglalink',
      },
      {
        'title': 'Bengali Phrasebook/App',
        'category': 'electronics_&_gadgets',
        'priority': 2,
        'description': 'Basic communication help',
      },
    ];

    for (int i = 0; i < templates.length; i++) {
      final template = templates[i];
      final item = ChecklistItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        tripId: tripId,
        title: template['title'] as String,
        description: template['description'] as String,
        category: template['category'] as String,
        priority: template['priority'] as int,
        createdAt: DateTime.now(),
      );
      await addItem(item);
    }
  }

  // Create minimal checklist for any destination
  Future<void> createBasicChecklist(String tripId) async {
    final basicItems = [
      {
        'title': 'Travel Documents',
        'category': 'essential_items',
        'priority': 5,
        'description': 'ID, tickets, bookings',
      },
      {
        'title': 'Money & Cards',
        'category': 'essential_items',
        'priority': 5,
        'description': 'Cash and payment methods',
      },
      {
        'title': 'Phone & Charger',
        'category': 'electronics_&_gadgets',
        'priority': 4,
        'description': 'Stay connected',
      },
      {
        'title': 'Medications',
        'category': 'clothing_&_personal',
        'priority': 4,
        'description': 'Personal health items',
      },
      {
        'title': 'Comfortable Clothes',
        'category': 'clothing_&_personal',
        'priority': 3,
        'description': 'Weather-appropriate',
      },
      {
        'title': 'Camera/Phone',
        'category': 'electronics_&_gadgets',
        'priority': 3,
        'description': 'Capture memories',
      },
    ];

    for (int i = 0; i < basicItems.length; i++) {
      final template = basicItems[i];
      final item = ChecklistItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_basic_$i',
        tripId: tripId,
        title: template['title'] as String,
        description: template['description'] as String,
        category: template['category'] as String,
        priority: template['priority'] as int,
        createdAt: DateTime.now(),
      );
      await addItem(item);
    }
  }

  // Clear all items for a trip
  Future<void> clearTripChecklist(String tripId) async {
    final items = getItemsForTrip(tripId);
    for (final item in items) {
      await item.delete();
    }
  }

  // Export checklist as text (for sharing)
  String exportChecklistAsText(String tripId, String tripName) {
    final items = getItemsForTrip(tripId);
    final stats = getTripStats(tripId);

    final buffer = StringBuffer();
    buffer.writeln('$tripName - Travel Checklist');
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln(
      'Progress: ${stats['completed']}/${stats['total']} (${stats['percentage']}%)',
    );
    buffer.writeln('');

    final categories = <String, List<ChecklistItem>>{};
    for (final item in items) {
      final category = item.category
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
      categories.putIfAbsent(category, () => []).add(item);
    }

    categories.forEach((category, categoryItems) {
      buffer.writeln('## $category');
      for (final item in categoryItems) {
        final status = item.isCompleted ? '✅' : '⬜';
        buffer.writeln(
          '$status ${item.title}${item.description.isNotEmpty ? ' - ${item.description}' : ''}',
        );
      }
      buffer.writeln('');
    });

    return buffer.toString();
  }
}
