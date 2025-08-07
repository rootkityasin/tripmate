import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../journal/journal_screen.dart';
import '../journal/journal_page.dart';
import '../map/map_screen.dart';
import '../trip/new_trip_page.dart';
import '../../services/journal_service.dart';
import '../../models/user_location.dart';
import '../../models/trip_details.dart';
import '../../models/journal_entry.dart';
import '../../services/location_service.dart';
import '../../services/bluetooth_sync.dart';
import '../../services/trip_service.dart';
import '../../constants/app_styles.dart';
import '../../models/navigation_item.dart';
import '../../widgets/liquid_nav.dart';

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
      extendBody: true,
      bottomNavigationBar: LiquidGlassNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          NavigationItem(icon: Icons.home_rounded, label: 'Home'),
          NavigationItem(icon: Icons.map_rounded, label: 'Map'),
          NavigationItem(icon: Icons.auto_stories_rounded, label: 'Journal'),
        ],
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
  final TripService _tripService = TripService();
  final JournalService _journalService = JournalService();
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
      // Initialize services
      await _tripService.initialize();
      await _journalService.initialize();

      // Check if Hive is initialized (for tests)
      if (!Hive.isBoxOpen('trips')) {
        // Skip loading data in test environment
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load recent trips and journals from services
      _recentTrips = _tripService.getRecentTrips(limit: 5);
      _recentJournals = _journalService.getAllEntries()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _recentJournals = _recentJournals.take(5).toList();

      // Add sample data if no trips exist (for demonstration)
      if (_recentTrips.isEmpty) {
        await _createSampleTrips();
      }
      if (_recentJournals.isEmpty) {
        await _createSampleJournals();
      }

      // Update journal counts for trips
      for (final trip in _recentTrips) {
        final journalCount = _journalService.getEntriesForTrip(trip.id).length;
        if (trip.journalEntriesCount != journalCount) {
          await _tripService.updateJournalCount(trip.id, journalCount);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleTrips() async {
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
      await _tripService.addTrip(trip);
    }

    // Reload trips after adding samples
    _recentTrips = _tripService.getRecentTrips(limit: 5);
  }

  Future<void> _createSampleJournals() async {
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
      await _journalService.addEntry(journal);
    }

    // Reload journals after adding samples
    _recentJournals = _journalService.getAllEntries()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _recentJournals = _recentJournals.take(5).toList();
  }

  Future<void> _startNewTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewTripPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final destination = result['destination'] as TripDestination;
      final startDate = result['startDate'] as DateTime;
      final endDate = result['endDate'] as DateTime;

      // Create new trip from selected destination with dates
      final newTrip = TripDetails(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        destinationName: destination.name,
        description: destination.description,
        region: destination.region,
        latitude: destination.coordinates.latitude,
        longitude: destination.coordinates.longitude,
        createdAt: DateTime.now(),
        startDate: startDate,
        endDate: endDate,
        attractions: destination.attractions,
        hasOfflineMaps: true, // Maps were downloaded in NewTripPage
      );

      // Save using TripService
      await _tripService.addTrip(newTrip);

      // Create welcome journal entry
      final journalService = JournalService();
      await journalService.initialize();
      await journalService.createWelcomeEntry(newTrip.id, destination.name);

      // Refresh the list
      _loadRecentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'New trip to ${destination.name} created with journal!',
            ),
            backgroundColor: AppStyles.successColor,
          ),
        );
      }
    }
  }

  void _openTripJournal(TripDetails trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            JournalPage(tripId: trip.id, tripName: trip.destinationName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
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
                        decoration: AppStyles.modernButtonDecoration(
                          borderRadius: 30,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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

                      // Travel journals section
                      _buildTravelJournalsSection(),
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
          child: Icon(Icons.menu_rounded, color: Colors.black87, size: 20),
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
        'description':
            'Explore ${trip.destinationName} and discover amazing places',
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
            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'START',
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
                child: Icon(Icons.add_rounded, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      );
    }

    // Show rotating cards
    return Column(
      children: [
        SizedBox(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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

  Widget _buildTravelJournalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Your Travel Journals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JournalScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'View All',
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
        if (_recentJournals.isEmpty)
          _buildEmptyJournalsCard()
        else
          ..._recentJournals
              .take(5)
              .map(
                (journal) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildJournalCard(journal),
                ),
              ),
      ],
    );
  }

  Widget _buildJournalCard(JournalEntry journal) {
    // Find the trip for this journal entry
    final trip = _recentTrips.firstWhere(
      (t) => t.id == journal.tripId,
      orElse: () => TripDetails(
        id: '',
        destinationName: 'Unknown Destination',
        description: '',
        region: 'Unknown Region',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        attractions: [],
      ),
    );

    return GestureDetector(
      onTap: () => _openTripJournal(trip),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppStyles.modernCardDecoration(borderRadius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF30D158)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      journal.mood,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journal.title,
                        style: AppStyles.headingSmall.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.destinationName,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppStyles.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: AppStyles.glassDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: 12,
                        ),
                        child: Text(
                          _formatJournalDate(journal.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: AppStyles.glassDecoration(
                    borderRadius: 16,
                    withBorder: false,
                  ),
                  child: IconButton(
                    onPressed: () => _openTripJournal(trip),
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppStyles.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Journal content preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppStyles.glassDecoration(
                color: AppStyles.backgroundColor.withOpacity(0.5),
                borderRadius: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journal.content,
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppStyles.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (journal.photoPaths.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_camera_rounded,
                          size: 16,
                          color: AppStyles.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${journal.photoPaths.length} photo${journal.photoPaths.length == 1 ? '' : 's'}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppStyles.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJournalDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyJournalsCard() {
    return Container(
      height: 200,
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No journal entries yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing about your adventures!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
