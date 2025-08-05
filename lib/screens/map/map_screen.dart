import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_styles.dart';
import '../../models/user_location.dart';
import '../../widgets/offline_map_widget.dart';
import '../../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final List<UserLocation> _userLocations = [];
  UserLocation? _currentUserLocation;
  bool _isLoading = true;
  bool _isLocationTracking = false;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationTracking();
    _checkOfflineStatus();
  }

  @override
  void dispose() {
    _locationService.stopLocationTracking();
    super.dispose();
  }

  void _checkOfflineStatus() {
    // Check if device is offline
    // For now, we'll assume offline mode based on GPS vs network availability
    setState(() {
      _isOfflineMode = true; // GPS works offline, maps may be cached
    });
  }

  Future<void> _getCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentUserLocation = location;
        // Add or update current user in the list
        _updateUserInList(location);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startLocationTracking() {
    _locationService.startLocationTracking((UserLocation newLocation) {
      setState(() {
        _currentUserLocation = newLocation;
        _updateUserInList(newLocation);
        _isLocationTracking = true;
      });
    });
  }

  void _updateUserInList(UserLocation newLocation) {
    // Remove old location for current user and add new one
    _userLocations.removeWhere((loc) => loc.userId == newLocation.userId);
    _userLocations.add(newLocation);
  }

  double _calculateDistance(UserLocation location) {
    if (_currentUserLocation == null) return 0;
    return _locationService.calculateDistance(_currentUserLocation!, location);
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

  void _showUserLocationDialog(UserLocation location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isCurrentUser = location.userId == _currentUserLocation?.userId;

        return AlertDialog(
          backgroundColor: AppStyles.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(
                isCurrentUser ? Icons.my_location : Icons.person_pin_circle,
                color: isCurrentUser ? AppStyles.primaryColor : AppStyles.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                isCurrentUser ? 'Your Location' : 'Traveler Location',
                style: AppStyles.headingSmall,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User ID: ${location.userId}',
                style: AppStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                style: AppStyles.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Last Update: ${_formatTimestamp(location.timestamp)}',
                style: AppStyles.bodySmall.copyWith(
                  color: AppStyles.textSecondary,
                ),
              ),
              if (_currentUserLocation != null && !isCurrentUser) ...[
                const SizedBox(height: 8),
                Text(
                  'Distance: ${_calculateDistance(location).toStringAsFixed(0)}m away',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppStyles.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.primaryColor,
              ),
              child: const Text('Close'),
            ),
            if (!isCurrentUser)
              TextButton(
                onPressed: () {
                  // TODO: Start navigation or connect to user
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppStyles.primaryColor,
                ),
                child: const Text('Connect'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Column(
        children: [
          // Modern app bar with gradient
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: AppStyles.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppStyles.glassDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: 16,
                    withBorder: false,
                  ),
                  child: const Icon(
                    Icons.map_rounded,
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
                        'Explore Map',
                        style: AppStyles.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUserLocation != null
                            ? (_isOfflineMode 
                                ? 'GPS tracking (Offline mode)'
                                : 'GPS tracking (Online mode)')
                            : 'Getting GPS location...',
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppStyles.glassDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: 16,
                      withBorder: false,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLocationTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                          color: Colors.white,
                          size: 20,
                        ),
                        if (_isLocationTracking) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isOfflineMode ? Colors.orange : Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Map container
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: AppStyles.modernCardDecoration(
                borderRadius: 32,
              ),
              clipBehavior: Clip.antiAlias,
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppStyles.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading map...',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppStyles.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : OfflineMapWidget(
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
          ),
        ],
      ),
      floatingActionButton: _currentUserLocation != null
          ? FloatingActionButton(
              onPressed: () {
                // Refresh current location
                _getCurrentLocation();
              },
              backgroundColor: AppStyles.primaryColor,
              child: const Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }
}
