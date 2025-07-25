import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/user_location.dart';
import '../services/map_tile_service.dart' as service;

class OfflineMapWidget extends StatefulWidget {
  final List<UserLocation> allUserLocations;
  final LatLng center;
  final String? currentUserId;
  final Function(UserLocation)? onUserMarkerTap;

  const OfflineMapWidget({
    super.key,
    required this.allUserLocations,
    this.center = const LatLng(22.1953, 92.2184), // Default: Bandarban
    this.currentUserId,
    this.onUserMarkerTap,
  });

  @override
  State<OfflineMapWidget> createState() => _OfflineMapWidgetState();
}

class _OfflineMapWidgetState extends State<OfflineMapWidget> {
  service.MapTileService? _tileService;
  final MapController _mapController = MapController();
  bool _isOfflineMode = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTileService();
  }

  Future<void> _initializeTileService() async {
    if (_isInitialized) return;

    try {
      _tileService = service.MapTileService();
      await _tileService!.initialize();
      final status = await _tileService!.getCacheStatus();
      setState(() {
        _isOfflineMode = status['tileCount'] > 0;
        _isInitialized = true;
      });
      print(
        'OfflineMapWidget: Tile service initialized, offline mode: $_isOfflineMode',
      );
    } catch (e) {
      print('OfflineMapWidget: Failed to initialize tile service: $e');
      setState(() {
        _isOfflineMode = false;
        _isInitialized = true;
      });
    }
  }

  // Create different colored markers for different users
  Widget _buildUserMarker(UserLocation location, bool isCurrentUser) {
    final color = isCurrentUser ? Colors.blue : Colors.red;
    final icon = isCurrentUser ? Icons.my_location : Icons.person_pin_circle;

    return GestureDetector(
      onTap: () => widget.onUserMarkerTap?.call(location),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  // Create cluster marker for nearby users
  Widget _buildClusterMarker(List<UserLocation> clusteredUsers) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: Text(
          '${clusteredUsers.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Group nearby users into clusters
  List<MapCluster> _createClusters() {
    const double clusterDistance = 50.0; // meters
    List<MapCluster> clusters = [];
    List<UserLocation> processed = [];

    for (final location in widget.allUserLocations) {
      if (processed.contains(location)) continue;

      List<UserLocation> nearbyUsers = [location];
      processed.add(location);

      // Find nearby users
      for (final other in widget.allUserLocations) {
        if (processed.contains(other)) continue;

        final distance = const Distance().as(
          LengthUnit.Meter,
          LatLng(location.latitude, location.longitude),
          LatLng(other.latitude, other.longitude),
        );

        if (distance <= clusterDistance) {
          nearbyUsers.add(other);
          processed.add(other);
        }
      }

      clusters.add(
        MapCluster(
          position: LatLng(location.latitude, location.longitude),
          users: nearbyUsers,
        ),
      );
    }

    return clusters;
  }

  @override
  Widget build(BuildContext context) {
    final clusters = _createClusters();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: 13.0,
            minZoom: 8.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              // Handle map tap
              print('Map tapped at: ${point.latitude}, ${point.longitude}');
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tripmate.app',
              tileProvider: (_isOfflineMode && _tileService != null)
                  ? _tileService!.getCachedTileProvider()
                  : NetworkTileProvider(),
            ),
            MarkerLayer(
              markers: clusters.map((cluster) {
                final isCurrentUser = cluster.users.any(
                  (u) => u.userId == widget.currentUserId,
                );

                if (cluster.users.length == 1) {
                  // Single user marker
                  return Marker(
                    point: cluster.position,
                    width: 40,
                    height: 40,
                    child: _buildUserMarker(cluster.users.first, isCurrentUser),
                  );
                } else {
                  // Cluster marker
                  return Marker(
                    point: cluster.position,
                    width: 50,
                    height: 50,
                    child: _buildClusterMarker(cluster.users),
                  );
                }
              }).toList(),
            ),
            // Add circle layer to show accuracy/range
            CircleLayer(
              circles: widget.allUserLocations
                  .where((loc) => loc.userId == widget.currentUserId)
                  .map(
                    (loc) => CircleMarker(
                      point: LatLng(loc.latitude, loc.longitude),
                      radius: 100, // 100 meter radius
                      color: Colors.blue.withOpacity(0.1),
                      borderColor: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 2,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        // Offline mode indicator
        if (_isOfflineMode)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_bolt, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        // User count indicator
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${widget.allUserLocations.length} travelers nearby',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        // Map controls
        Positioned(
          right: 10,
          bottom: 80,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: "zoom_in",
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "zoom_out",
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: "my_location",
                onPressed: () {
                  final myLocation = widget.allUserLocations
                      .where((loc) => loc.userId == widget.currentUserId)
                      .firstOrNull;
                  if (myLocation != null) {
                    _mapController.move(
                      LatLng(myLocation.latitude, myLocation.longitude),
                      15.0,
                    );
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper class for clustering
class MapCluster {
  final LatLng position;
  final List<UserLocation> users;

  MapCluster({required this.position, required this.users});
}
