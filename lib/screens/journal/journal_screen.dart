import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/trip_details.dart';
import '../../constants/app_styles.dart';
import 'journal_page.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
  List<TripDetails> _userTrips = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    try {
      final tripBox = await Hive.openBox<TripDetails>('trip_details');
      setState(() {
        _userTrips = tripBox.values.toList()
          ..sort((a, b) => (b.startDate ?? DateTime.now())
              .compareTo(a.startDate ?? DateTime.now()));
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
        title: const Text(
          'Travel Journals',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppStyles.primaryColor, AppStyles.accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16),
          tabs: const [
            Tab(
              icon: Icon(Icons.folder_outlined, size: 24),
              text: 'My Trips',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.timeline_outlined, size: 24),
              text: 'All Entries',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primaryColor),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading journals...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTripsTab(),
                _buildAllEntriesTab(),
              ],
            ),
    );
  }

  Widget _buildTripsTab() {
    if (_userTrips.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _userTrips.length,
        itemBuilder: (context, index) {
          final trip = _userTrips[index];
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 100)),
            curve: Curves.easeOutBack,
            child: _buildTripCard(trip),
          );
        },
      ),
    );
  }

  Widget _buildAllEntriesTab() {
    return JournalPage(
      showAllEntries: true,
      tripId: null,
      tripName: 'All Journals',
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 64,
                  color: AppStyles.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No trips found',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first trip to start journaling\nyour travel experiences and memories',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Material(
                elevation: 8,
                shadowColor: AppStyles.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppStyles.primaryColor, AppStyles.accentColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/new-trip');
                    },
                    icon: const Icon(Icons.add_rounded, size: 24),
                    label: const Text(
                      'Create New Trip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(TripDetails trip) {
    final DateTime startDate = trip.startDate ?? DateTime.now();
    final DateTime endDate = trip.endDate ?? DateTime.now().add(const Duration(days: 1));
    
    final bool isUpcoming = startDate.isAfter(DateTime.now());
    final bool isCurrent = DateTime.now().isAfter(startDate) && 
                          DateTime.now().isBefore(endDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => JournalPage(
                    tripId: trip.id,
                    tripName: trip.destinationName,
                    showAllEntries: false,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Modern trip image with hero animation
                      Hero(
                        tag: 'trip_${trip.id}',
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [AppStyles.primaryColor, AppStyles.accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.place_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.destinationName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              trip.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(isUpcoming, isCurrent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: _buildJournalPreview(trip.id),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to view journal entries',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppStyles.primaryColor,
                        ),
                      ),
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

  Widget _buildStatusChip(bool isUpcoming, bool isCurrent) {
    String label;
    Color color;
    IconData icon;

    if (isCurrent) {
      label = 'Ongoing';
      color = Colors.green;
      icon = Icons.play_circle_outline;
    } else if (isUpcoming) {
      label = 'Upcoming';
      color = Colors.blue;
      icon = Icons.schedule_outlined;
    } else {
      label = 'Completed';
      color = Colors.grey;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalPreview(String tripId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getJournalStats(tripId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.book_outlined, '- entries', isLoading: true),
                _buildStatItem(Icons.photo_outlined, '- photos', isLoading: true),
                _buildStatItem(null, 'Recent: -', isLoading: true),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(Icons.book_outlined, '${stats['entries']} entries'),
            Container(
              width: 1,
              height: 30,
              color: Colors.grey[300],
            ),
            _buildStatItem(Icons.photo_outlined, '${stats['photos']} photos'),
            if (stats['lastMood'] != null) ...[
              Container(
                width: 1,
                height: 30,
                color: Colors.grey[300],
              ),
              _buildStatItem(null, '${stats['lastMood']}', isEmoji: true),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatItem(IconData? icon, String text, {bool isLoading = false, bool isEmoji = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEmoji) ...[
            Text(
              text,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'Recent mood',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            if (icon != null) ...[
              isLoading 
                ? Container(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                  )
                : Icon(icon, size: 20, color: AppStyles.primaryColor),
              const SizedBox(height: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isLoading ? Colors.grey[400] : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getJournalStats(String tripId) async {
    try {
      final journalBox = await Hive.openBox('journal_entries');
      final entries = journalBox.values
          .where((entry) => entry.tripId == tripId)
          .toList();
      
      int totalPhotos = 0;
      String? lastMood;
      
      if (entries.isNotEmpty) {
        // Sort by timestamp to get the most recent
        entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        lastMood = entries.first.mood;
        
        for (final entry in entries) {
          totalPhotos += (entry.photoPaths as List<String>? ?? []).length;
        }
      }
      
      return {
        'entries': entries.length,
        'photos': totalPhotos,
        'lastMood': lastMood,
      };
    } catch (e) {
      return {'entries': 0, 'photos': 0, 'lastMood': null};
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}