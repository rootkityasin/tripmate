import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/checklist_item.dart';
import '../../constants/app_styles.dart';

class ChecklistPage extends StatefulWidget {
  final String tripId;
  final String tripName;

  const ChecklistPage({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Box<ChecklistItem> _checklistBox;
  bool _isLoading = true;

  // Predefined checklist templates
  final Map<String, List<Map<String, dynamic>>> _templates = {
    'Essential Items': [
      {
        'title': 'Passport/ID',
        'priority': 5,
        'description': 'Valid travel documents',
      },
      {
        'title': 'Flight/Bus Tickets',
        'priority': 5,
        'description': 'Booking confirmations',
      },
      {
        'title': 'Hotel Reservations',
        'priority': 4,
        'description': 'Accommodation bookings',
      },
      {
        'title': 'Travel Insurance',
        'priority': 4,
        'description': 'Valid insurance policy',
      },
      {
        'title': 'Emergency Contacts',
        'priority': 5,
        'description': 'Important phone numbers',
      },
      {
        'title': 'Cash & Cards',
        'priority': 5,
        'description': 'Local currency and cards',
      },
    ],
    'Clothing & Personal': [
      {
        'title': 'Comfortable Walking Shoes',
        'priority': 4,
        'description': 'For long walks',
      },
      {
        'title': 'Weather-appropriate Clothes',
        'priority': 4,
        'description': 'Check destination weather',
      },
      {
        'title': 'Toiletries',
        'priority': 3,
        'description': 'Toothbrush, shampoo, etc.',
      },
      {
        'title': 'Medications',
        'priority': 5,
        'description': 'Prescription & first aid',
      },
      {
        'title': 'Sunscreen & Sunglasses',
        'priority': 3,
        'description': 'UV protection',
      },
      {
        'title': 'Phone Charger',
        'priority': 4,
        'description': 'Don\'t forget the cable!',
      },
    ],
    'Electronics & Gadgets': [
      {
        'title': 'Power Bank',
        'priority': 4,
        'description': 'For charging on the go',
      },
      {'title': 'Camera', 'priority': 3, 'description': 'Capture memories'},
      {
        'title': 'Universal Adapter',
        'priority': 3,
        'description': 'For different outlets',
      },
      {
        'title': 'Headphones',
        'priority': 2,
        'description': 'For entertainment',
      },
      {
        'title': 'Flashlight',
        'priority': 2,
        'description': 'Emergency lighting',
      },
    ],
    'Bangladesh Specific': [
      {
        'title': 'Mosquito Repellent',
        'priority': 4,
        'description': 'Essential for tropical climate',
      },
      {
        'title': 'Light Cotton Clothes',
        'priority': 4,
        'description': 'For humid weather',
      },
      {
        'title': 'Umbrella/Raincoat',
        'priority': 3,
        'description': 'For monsoon season',
      },
      {
        'title': 'Local SIM Card Info',
        'priority': 3,
        'description': 'GP, Robi, Banglalink options',
      },
      {
        'title': 'Bengali Phrasebook',
        'priority': 2,
        'description': 'Basic communication',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      _checklistBox = await Hive.openBox<ChecklistItem>('checklist_items');
      _loadDefaultItems();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing checklist: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadDefaultItems() {
    final existingItems = _checklistBox.values
        .where((item) => item.tripId == widget.tripId)
        .toList();

    // Only add templates if no items exist for this trip
    if (existingItems.isEmpty) {
      _templates.forEach((category, items) {
        for (final template in items) {
          final item = ChecklistItem(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                items.indexOf(template).toString(),
            tripId: widget.tripId,
            title: template['title'],
            description: template['description'] ?? '',
            category: category.toLowerCase().replaceAll(' ', '_'),
            priority: template['priority'] ?? 3,
            createdAt: DateTime.now(),
          );
          _checklistBox.add(item);
        }
      });
    }
  }

  List<ChecklistItem> _getItemsByCategory(String category) {
    return _checklistBox.values
        .where(
          (item) =>
              item.tripId == widget.tripId &&
              item.category == category.toLowerCase().replaceAll(' ', '_'),
        )
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  List<ChecklistItem> _getAllItems() {
    return _checklistBox.values
        .where((item) => item.tripId == widget.tripId)
        .toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.priority.compareTo(a.priority);
      });
  }

  void _toggleItem(ChecklistItem item) {
    setState(() {
      item.isCompleted = !item.isCompleted;
      item.completedAt = item.isCompleted ? DateTime.now() : null;
      item.save();
    });
  }

  void _deleteItem(ChecklistItem item) {
    setState(() {
      item.delete();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Note: In a real app, you'd need to implement undo functionality
          },
        ),
      ),
    );
  }

  void _addCustomItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        tripId: widget.tripId,
        onAdd: (item) {
          setState(() {
            _checklistBox.add(item);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.tripName} Checklist'),
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allItems = _getAllItems();
    final completedCount = allItems.where((item) => item.isCompleted).length;
    final totalCount = allItems.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tripName} Checklist'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addCustomItem),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Items'),
            Tab(text: 'Essential'),
            Tab(text: 'Personal'),
            Tab(text: 'Electronics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppStyles.primaryColor, AppStyles.accentColor],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount of $totalCount completed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsList(_getAllItems()),
                _buildItemsList(_getItemsByCategory('Essential Items')),
                _buildItemsList(_getItemsByCategory('Clothing & Personal')),
                _buildItemsList(_getItemsByCategory('Electronics & Gadgets')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<ChecklistItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No items in this category',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildChecklistItem(item);
      },
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => _toggleItem(item),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: item.description.isNotEmpty
            ? Text(
                item.description,
                style: TextStyle(
                  color: item.isCompleted ? Colors.grey : Colors.grey[600],
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(item.priority),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'P${item.priority}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteItem(item),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 1:
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _AddItemDialog extends StatefulWidget {
  final String tripId;
  final Function(ChecklistItem) onAdd;

  const _AddItemDialog({required this.tripId, required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _priority = 3;
  final String _category = 'personal';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Checklist Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Item Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Priority: '),
              DropdownButton<int>(
                value: _priority,
                items: [1, 2, 3, 4, 5].map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text('$priority'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              final item = ChecklistItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                tripId: widget.tripId,
                title: _titleController.text,
                description: _descriptionController.text,
                category: _category,
                priority: _priority,
                createdAt: DateTime.now(),
              );
              widget.onAdd(item);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
