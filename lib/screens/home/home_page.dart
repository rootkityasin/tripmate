import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../journal/journal_page.dart';
import '../checklist/checklist_page.dart';
import '../guide/guide_page.dart';
import '../settings/settings_page.dart';
import '../../widgets/offline_map_widget.dart';
import '../../models/user_location.dart';
import '../../services/location_service.dart';
import '../../services/bluetooth_sync.dart';
import '../../services/map_tile_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<UserLocation> _userLocations = [];
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
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _downloadOfflineMaps() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      await _mapTileService.downloadBandarbanTiles(
        onProgress: (current, total) {
          setState(() {
            _downloadProgress = current / total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bandarban maps downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TripMate'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadOfflineMaps,
            tooltip: 'Download Offline Maps',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create trip page
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.luggage, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Welcome to TripMate!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your smart offline travel companion',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (_isDownloading) ...[
              const Text(
                'Downloading offline maps...',
                style: TextStyle(fontSize: 16, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(_downloadProgress * 100).toStringAsFixed(1)}% complete',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.map, size: 48, color: Colors.deepPurple),
                    const SizedBox(height: 12),
                    const Text(
                      'Live Location Sharing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share your location with nearby travelers via Bluetooth. Perfect for group trips and exploring together!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // The parent widget already handles location tracking
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location sharing is active!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_location),
                      label: const Text('Location Sharing Active'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Live map with nearby travelers below',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
