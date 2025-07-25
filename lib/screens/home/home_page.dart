import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../journal/journal_page.dart';
import '../checklist/checklist_page.dart';
import '../guide/guide_page.dart';
import '../settings/settings_page.dart';
import '../trip/new_trip_page.dart';
import '../../widgets/offline_map_widget.dart';
import '../../models/user_location.dart';
import '../../models/trip_details.dart';
import '../../models/journal_entry.dart';
import '../../services/location_service.dart';
import '../../services/bluetooth_sync.dart';
import '../../services/map_tile_service.dart';
import '../../constants/app_styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<UserLocation> _userLocations = [];
  final LocationService _locationService = LocationService();
  final BluetoothSyncService _bluetoothService = BluetoothSyncService();
  UserLocation? _currentUserLocation;
  Timer? _bluetoothSyncTimer;

  @override
  void initState() {
    super.initState();
    // Start location tracking and Bluetooth sync
    _startLocationTracking();
    _startBluetoothSync();
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    _bluetoothSyncTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking() async {
    // Check permissions and start tracking
    final currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation != null) {
      setState(() {
        _currentUserLocation = currentLocation;
        _userLocations.add(currentLocation);
      });

      // Start continuous tracking
      _locationService.startLocationTracking((location) {
        setState(() {
          _currentUserLocation = location;

          // Update or add location in the list
          final existingIndex = _userLocations.indexWhere(
            (l) => l.userId == location.userId,
          );
          if (existingIndex != -1) {
            _userLocations[existingIndex] = location;
          } else {
            _userLocations.add(location);
          }
        });

        // Broadcast location via Bluetooth
        _bluetoothService.broadcastLocation(location);
      });
    }
  }

  void _startBluetoothSync() async {
    // Start periodic scanning for nearby users
    _bluetoothSyncTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final nearbyLocations = await _bluetoothService
            .scanForNearbyLocations();
        if (nearbyLocations.isNotEmpty && mounted) {
          setState(() {
            // Add nearby locations (avoid duplicates and merge recent data)
            for (var location in nearbyLocations) {
              final existingIndex = _userLocations.indexWhere(
                (l) => l.userId == location.userId,
              );
              if (existingIndex != -1) {
                // Update existing location if this one is more recent
                if (location.timestamp.isAfter(
                  _userLocations[existingIndex].timestamp,
                )) {
                  _userLocations[existingIndex] = location;
                }
              } else {
                _userLocations.add(location);
              }
            }
          });
        }
      } catch (e) {
        print('Bluetooth sync error: $e');
      }
    });
  }

  void _showUserLocationDialog(UserLocation location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isCurrentUser = location.userId == _currentUserLocation?.userId;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isCurrentUser ? Icons.my_location : Icons.person_pin_circle,
                color: isCurrentUser ? Colors.blue : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(isCurrentUser ? 'Your Location' : 'Traveler Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User ID: ${location.userId}'),
              const SizedBox(height: 8),
              Text('Latitude: ${location.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${location.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              Text('Last Update: ${_formatTimestamp(location.timestamp)}'),
              if (_currentUserLocation != null && !isCurrentUser) ...[
                const SizedBox(height: 8),
                Text(
                  'Distance: ${_calculateDistance(location).toStringAsFixed(0)}m away',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (!isCurrentUser)
              TextButton(
                onPressed: () {
                  // TODO: Start navigation or connect to user
                  Navigator.of(context).pop();
                },
                child: const Text('Connect'),
              ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  double _calculateDistance(UserLocation otherLocation) {
    if (_currentUserLocation == null) return 0;

    return _locationService.calculateDistance(
      _currentUserLocation!,
      otherLocation,
    );
  }

  static final List<Widget> _pages = <Widget>[
    const TripHomePage(),
    const JournalPage(),
    const ChecklistPage(),
    const GuidePage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0
          ? Column(
              children: [
                Expanded(flex: 1, child: _pages[_selectedIndex]),
                Expanded(
                  flex: 2,
                  child: OfflineMapWidget(
                    allUserLocations: _userLocations,
                    currentUserId: _currentUserLocation?.userId,
                    center: _currentUserLocation != null
                        ? LatLng(
                            _currentUserLocation!.latitude,
                            _currentUserLocation!.longitude,
                          )
                        : const LatLng(22.1953, 92.2184), // Default: Bandarban
                    onUserMarkerTap: (location) {
                      _showUserLocationDialog(location);
                    },
                  ),
                ),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Checklist',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Guide'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class TripHomePage extends StatefulWidget {
  const TripHomePage({super.key});

  @override
  State<TripHomePage> createState() => _TripHomePageState();
}

class _TripHomePageState extends State<TripHomePage> {
  final MapTileService _mapTileService = MapTileService();
  List<TripDetails> _recentTrips = [];
  List<JournalEntry> _recentJournals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentData();
  }

  Future<void> _loadRecentData() async {
    try {
      // Check if Hive is initialized (for tests)
      if (!Hive.isBoxOpen('trips')) {
        // Skip loading data in test environment
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load recent trips and journals from Hive
      final tripBox = await Hive.openBox<TripDetails>('trips');
      final journalBox = await Hive.openBox<JournalEntry>('journal_entries');

      // Add sample data if boxes are empty (for demonstration)
      if (tripBox.isEmpty) {
        await _createSampleTrips(tripBox);
      }
      if (journalBox.isEmpty) {
        await _createSampleJournals(journalBox);
      }

      setState(() {
        _recentTrips = tripBox.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _recentJournals = journalBox.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleTrips(Box<TripDetails> tripBox) async {
    final sampleTrips = [
      TripDetails(
        id: '1',
        destinationName: 'Bandarban',
        description: 'Hill tracts with beautiful mountains and waterfalls',
        region: 'Chittagong Hill Tracts',
        latitude: 22.1953,
        longitude: 92.2184,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        attractions: ['Nilgiri Hills', 'Golden Temple', 'Boga Lake'],
        status: 'active',
        hasOfflineMaps: true,
        journalEntriesCount: 3,
      ),
      TripDetails(
        id: '2',
        destinationName: 'Cox\'s Bazar',
        description: 'World\'s longest natural sandy beach',
        region: 'Chittagong',
        latitude: 21.4272,
        longitude: 92.0058,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        startDate: DateTime.now().subtract(const Duration(days: 12)),
        endDate: DateTime.now().subtract(const Duration(days: 8)),
        attractions: ['Cox\'s Bazar Beach', 'Himchari', 'Inani Beach'],
        status: 'completed',
        hasOfflineMaps: true,
        journalEntriesCount: 5,
      ),
    ];

    for (final trip in sampleTrips) {
      await tripBox.add(trip);
    }
  }

  Future<void> _createSampleJournals(Box<JournalEntry> journalBox) async {
    final sampleJournals = [
      JournalEntry(
        id: '1',
        tripId: '1',
        title: 'Amazing sunrise at Nilgiri Hills',
        content:
            'Woke up early to catch the breathtaking sunrise from Nilgiri Hills. The view was absolutely incredible with clouds below us and the sun painting the sky in golden hues.',
        photoPaths: [],
        mood: '😍',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        latitude: 22.1953,
        longitude: 92.2184,
      ),
      JournalEntry(
        id: '2',
        tripId: '1',
        title: 'Golden Temple visit',
        content:
            'Visited the beautiful Golden Temple today. The architecture and peaceful atmosphere were truly mesmerizing. Met some lovely local people who shared stories about the temple\'s history.',
        photoPaths: [],
        mood: '🙏',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        latitude: 22.1953,
        longitude: 92.2184,
      ),
      JournalEntry(
        id: '3',
        tripId: '2',
        title: 'Beach sunset in Cox\'s Bazar',
        content:
            'The most beautiful sunset I\'ve ever seen! Walked along the endless beach and watched the sun dip into the Bay of Bengal. Perfect end to an amazing trip.',
        photoPaths: [],
        mood: '🌅',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        latitude: 21.4272,
        longitude: 92.0058,
      ),
    ];

    for (final journal in sampleJournals) {
      await journalBox.add(journal);
    }
  }

  Future<void> _startNewTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTripPage()),
    );

    if (result != null && result is TripDestination) {
      // Create new trip from selected destination
      final newTrip = TripDetails(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        destinationName: result.name,
        description: result.description,
        region: result.region,
        latitude: result.coordinates.latitude,
        longitude: result.coordinates.longitude,
        createdAt: DateTime.now(),
        attractions: result.attractions,
        hasOfflineMaps: true, // Maps were downloaded in NewTripPage
      );

      // Save to Hive
      final tripBox = await Hive.openBox<TripDetails>('trips');
      await tripBox.add(newTrip);

      // Refresh the list
      _loadRecentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New trip to ${result.name} created!'),
            backgroundColor: AppStyles.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TripMate'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: _startNewTrip,
            tooltip: 'Start New Trip',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecentData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),

                    // Start new trip button
                    _buildNewTripButton(),
                    const SizedBox(height: 24),

                    // Recent trips section
                    _buildRecentTripsSection(),
                    const SizedBox(height: 24),

                    // Recent journals section
                    _buildRecentJournalsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppStyles.primaryColor,
            AppStyles.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppStyles.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.luggage, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Welcome to TripMate!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your smart offline travel companion',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('${_recentTrips.length}', 'Trips', Icons.map),
              const SizedBox(width: 12),
              _buildStatCard(
                '${_recentJournals.length}',
                'Memories',
                Icons.auto_stories,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTripButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startNewTrip,
        icon: const Icon(Icons.add_location_alt, size: 24),
        label: const Text(
          'Start New Trip',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.cardRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Trips', style: AppStyles.headingMedium),
            if (_recentTrips.isNotEmpty)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all trips page
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _recentTrips.isEmpty
            ? _buildEmptyState(
                'No trips yet',
                'Start your first adventure!',
                Icons.explore,
              )
            : SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentTrips.take(5).length,
                  itemBuilder: (context, index) {
                    final trip = _recentTrips[index];
                    return _buildTripCard(trip);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildRecentJournalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Memories', style: AppStyles.headingMedium),
            if (_recentJournals.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to journal page
                  Navigator.of(context).pushNamed('/journal');
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _recentJournals.isEmpty
            ? _buildEmptyState(
                'No memories yet',
                'Start documenting your adventures',
                Icons.auto_stories,
              )
            : Column(
                children: _recentJournals
                    .take(3)
                    .map((journal) => _buildJournalCard(journal))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildTripCard(TripDetails trip) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: AppStyles.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppStyles.cardRadius),
                  topRight: Radius.circular(AppStyles.cardRadius),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 32,
                      color: AppStyles.primaryColor,
                    ),
                    Text(
                      trip.region,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppStyles.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destinationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.statusDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: trip.isCompleted
                            ? AppStyles.successColor
                            : AppStyles.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(trip.durationText, style: AppStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalCard(JournalEntry journal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppStyles.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.auto_stories,
            color: AppStyles.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          journal.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          journal.content,
          style: AppStyles.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatRelativeTime(journal.timestamp),
          style: AppStyles.bodySmall,
        ),
        onTap: () {
          // TODO: Navigate to journal detail
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
