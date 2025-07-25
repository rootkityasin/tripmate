import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/user_location.dart'; // Adjust path if needed

class OfflineMapWidget extends StatelessWidget {
  final List<UserLocation> allUserLocations;
  final LatLng center;

  const OfflineMapWidget({
    super.key,
    required this.allUserLocations,
    this.center = const LatLng(22.1953, 92.2184), // Default: Bandarban
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: center,
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tripmate.app',
          tileProvider: const NetworkTileProvider(), // Optional: You can later replace with cached provider
        ),
        MarkerLayer(
          markers: allUserLocations.map(
            (loc) => Marker(
              point: LatLng(loc.latitude, loc.longitude),
              width: 40,
              height: 40,
              builder: (ctx) => const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 30,
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }
}
