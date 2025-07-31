import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/trip_details.dart';
import '../../constants/app_styles.dart';
import 'checklist_page.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<TripDetails> _userTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final tripBox = await Hive.openBox<TripDetails>('trip_details');
      setState(() {
        _userTrips = tripBox.values.toList()
          ..sort(
            (a, b) => (b.startDate ?? DateTime.now()).compareTo(
              a.startDate ?? DateTime.now(),
            ),
          );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading trips: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Checklists'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userTrips.isEmpty
          ? _buildEmptyState()
          : _buildTripsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rtl, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No trips found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create a trip first to start building your checklist',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to trip creation
              Navigator.of(context).pushNamed('/new-trip');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userTrips.length,
      itemBuilder: (context, index) {
        final trip = _userTrips[index];
        return _buildTripCard(trip);
      },
    );
  }

  Widget _buildTripCard(TripDetails trip) {
    final DateTime startDate = trip.startDate ?? DateTime.now();
    final DateTime endDate =
        trip.endDate ?? DateTime.now().add(const Duration(days: 1));

    final bool isUpcoming = startDate.isAfter(DateTime.now());
    final bool isCurrent =
        DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChecklistPage(
                tripId: trip.id,
                tripName: trip.destinationName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.destinationName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(isUpcoming, isCurrent),
                ],
              ),
              const SizedBox(height: 12),
              _buildChecklistPreview(trip.id),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to view checklist',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isUpcoming, bool isCurrent) {
    String label;
    Color color;

    if (isCurrent) {
      label = 'Ongoing';
      color = Colors.green;
    } else if (isUpcoming) {
      label = 'Upcoming';
      color = Colors.blue;
    } else {
      label = 'Completed';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildChecklistPreview(String tripId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getChecklistStats(tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 20);
        }

        final stats = snapshot.data!;
        final progress = stats['percentage'] / 100.0;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Checklist Progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${stats['completed']}/${stats['total']} items',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : AppStyles.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${stats['percentage']}% complete',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getChecklistStats(String tripId) async {
    try {
      final checklistBox = await Hive.openBox('checklist_items');
      final items = checklistBox.values
          .where((item) => item.tripId == tripId)
          .toList();

      final completed = items.where((item) => item.isCompleted).length;
      final total = items.length;

      return {
        'completed': completed,
        'total': total,
        'percentage': total > 0 ? (completed / total * 100).round() : 0,
      };
    } catch (e) {
      return {'completed': 0, 'total': 0, 'percentage': 0};
    }
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
