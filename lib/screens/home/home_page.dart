import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../journal/journal_screen.dart';
import '../map/map_screen.dart';
import '../trip/new_trip_page.dart';
import '../../services/checklist_service.dart';
import '../../services/journal_service.dart';
import '../../models/user_location.dart';
import '../../models/trip_details.dart';
import '../../models/journal_entry.dart';
import '../../services/location_service.dart';
import '../../services/bluetooth_sync.dart';
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
  UserLocation? _currentUserLocation; // Keep for location tracking and sync
  Timer? _bluetoothSyncTimer;

  @override
  void initState() {
    super.initState();
    // Start location tracking and Bluetooth sync
    _startLocationTracking();
    _startBluetoothSync();
  }

  // Getter to satisfy compilation requirement - location is tracked for other features
  bool get hasCurrentLocation => _currentUserLocation != null;

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

  static final List<Widget> _pages = <Widget>[
    const TripHomePage(),
    const MapScreen(),
    const JournalScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: AppStyles.modernCardDecoration(
          borderRadius: 0,
          backgroundColor: AppStyles.surfaceColor,
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_rounded),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_stories_rounded),
                  label: 'Journal',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: AppStyles.primaryColor,
              unselectedItemColor: AppStyles.textSecondary,
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppStyles.primaryColor,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: AppStyles.textSecondary,
              ),
              onTap: _onItemTapped,
            ),
          ),
        ),
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
  List<TripDetails> _recentTrips = [];
  List<JournalEntry> _recentJournals = [];
  bool _isLoading = true;
  int _currentCardIndex = 0;

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

      // Create default checklist for the trip
      final checklistService = ChecklistService();
      await checklistService.initialize();

      // Create Bangladesh-specific checklist if destination is in Bangladesh
      if (result.region.contains('Bangladesh') ||
          [
            'Bandarban',
            'Cox\'s Bazar',
            'Rangamati',
            'Sylhet',
            'Sundarbans',
            'Paharpur',
            'Dhaka',
            'Chittagong',
          ].contains(result.name)) {
        await checklistService.createDefaultBangladeshChecklist(newTrip.id);
      } else {
        await checklistService.createBasicChecklist(newTrip.id);
      }

      // Create welcome journal entry
      final journalService = JournalService();
      await journalService.initialize();
      await journalService.createWelcomeEntry(newTrip.id, result.name);

      // Refresh the list
      _loadRecentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New trip to ${result.name} created with checklist and journal!'),
            backgroundColor: AppStyles.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
      ),
      child: SafeArea(
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
                        'Loading your trips...',
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppStyles.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadRecentData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with greeting and profile
                      _buildHeaderSection(),
                      const SizedBox(height: 24),

                      // Discover your next trip section
                      _buildDiscoverSection(),
                      const SizedBox(height: 24),

                      // Recent trips promotional cards (rotating)
                      _buildRecentTripsPromotionalCards(),
                      const SizedBox(height: 24),

                      // Recent trips section
                      _buildRecentTripsSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.menu_rounded,
            color: Colors.black87,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Alexius',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7DD3FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '2 active',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: Colors.black87,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover your next trip\nand destination',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTripsPromotionalCards() {
    // Combine trips and journals for the rotating cards
    final allItems = <Map<String, dynamic>>[];
    
    // Add recent trips
    for (final trip in _recentTrips.take(3)) {
      allItems.add({
        'type': 'trip',
        'data': trip,
        'title': trip.destinationName,
        'subtitle': trip.region,
        'description': 'Explore ${trip.destinationName} and discover amazing places',
        'color': const Color(0xFF007AFF),
      });
    }
    
    // Add recent journals
    for (final journal in _recentJournals.take(3)) {
      allItems.add({
        'type': 'journal',
        'data': journal,
        'title': journal.title,
        'subtitle': 'Journal Entry',
        'description': journal.content.length > 50 
            ? '${journal.content.substring(0, 50)}...' 
            : journal.content,
        'color': const Color(0xFF34C759),
      });
    }
    
    if (allItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFFF8E53),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'START YOUR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FIRST',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Adventure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _startNewTrip,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show rotating cards
    return Column(
      children: [
        Container(
          height: 160,
          child: PageView.builder(
            itemCount: allItems.length,
            onPageChanged: (index) {
              setState(() {
                _currentCardIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = allItems[index];
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      item['color'] as Color,
                      (item['color'] as Color).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (item['color'] as Color).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['type'] == 'trip' ? 'RECENT TRIP' : 'JOURNAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (item['type'] == 'journal')
                          Text(
                            (item['data'] as JournalEntry).mood,
                            style: const TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        item['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (allItems.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              allItems.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentCardIndex == index 
                      ? const Color(0xFF007AFF) 
                      : Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Recent Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _startNewTrip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Add New',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentTrips.isEmpty)
          _buildEmptyTripsCard()
        else
          ..._recentTrips.map((trip) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildTripCard(trip),
          )),
      ],
    );
  }

  Widget _buildTripCard(TripDetails trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppStyles.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.destinationName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.region,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.statusDisplay,
                      style: TextStyle(
                        fontSize: 11,
                        color: trip.isCompleted ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTripsCard() {
    return Container(
      height: 300, // Fixed height to take up more space
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
        children: [
          Icon(
            Icons.luggage_rounded,
            size: 64, // Larger icon
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No trips yet',
            style: TextStyle(
              fontSize: 18, // Larger font
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start planning your first adventure!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _startNewTrip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Larger button
              decoration: BoxDecoration(
                gradient: AppStyles.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Plan First Trip',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
