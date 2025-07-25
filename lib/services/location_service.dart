import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_location.dart';
import 'package:uuid/uuid.dart';

class LocationService {
  static const String _userId =
      'user_001'; // In a real app, this would be dynamic
  StreamSubscription<Position>? _positionStream;
  final Uuid _uuid = const Uuid();

  Future<bool> requestLocationPermission() async {
    // Request location permission
    var status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> checkLocationService() async {
    // Check if location services are enabled
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<UserLocation?> getCurrentLocation() async {
    try {
      if (!await checkLocationService()) {
        print('Location services are disabled.');
        return null;
      }

      if (!await requestLocationPermission()) {
        print('Location permission denied');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return UserLocation(
        userId: _userId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  void startLocationTracking(Function(UserLocation) onLocationUpdate) async {
    if (!await checkLocationService() || !await requestLocationPermission()) {
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final userLocation = UserLocation(
              userId: _userId,
              latitude: position.latitude,
              longitude: position.longitude,
              timestamp: DateTime.now(),
            );
            onLocationUpdate(userLocation);
          },
        );
  }

  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  double calculateDistance(UserLocation location1, UserLocation location2) {
    return Geolocator.distanceBetween(
      location1.latitude,
      location1.longitude,
      location2.latitude,
      location2.longitude,
    );
  }

  List<UserLocation> filterNearbyUsers(
    List<UserLocation> allUsers,
    UserLocation currentUser,
    double maxDistanceInMeters,
  ) {
    return allUsers.where((user) {
      if (user.userId == currentUser.userId) return false;
      double distance = calculateDistance(currentUser, user);
      return distance <= maxDistanceInMeters;
    }).toList();
  }
}
