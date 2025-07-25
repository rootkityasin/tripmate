import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import '../models/user_location.dart';

class BluetoothSyncService {
  static const String serviceUuid = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUuid =
      "87654321-4321-4321-4321-cba987654321";

  Future<void> broadcastLocation(UserLocation location) async {
    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isAvailable == false) {
        print("Bluetooth not available");
        return;
      }

      // Serialize location data
      String payload = jsonEncode({
        'id': location.userId,
        'lat': location.latitude,
        'lon': location.longitude,
        'time': location.timestamp.toIso8601String(),
      });

      // Start advertising (simplified implementation)
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 1));
      await FlutterBluePlus.stopScan();

      print("Broadcasting location: $payload");
      // In a real implementation, you would set up GATT server and advertise

      // TODO: Implement actual BLE advertising with GATT services
    } catch (e) {
      print("Error broadcasting location: $e");
    }
  }

  Future<List<UserLocation>> scanForNearbyLocations() async {
    List<UserLocation> nearbyLocations = [];

    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isAvailable == false) {
        print("Bluetooth not available");
        return nearbyLocations;
      }

      // Start scanning for devices
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Check if device advertises our service
          if (result.advertisementData.serviceUuids.contains(serviceUuid)) {
            // TODO: Parse location data from advertisement
            print("Found nearby device: ${result.device.name}");
          }
        }
      });

      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("Error scanning for locations: $e");
    }

    return nearbyLocations;
  }

  Future<void> connectAndSync(BluetoothDevice device) async {
    try {
      // Connect to device
      await device.connect();

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString() == characteristicUuid) {
              // Read location data
              List<int> value = await characteristic.read();
              String jsonString = String.fromCharCodes(value);

              // Parse and store location data
              Map<String, dynamic> locationData = jsonDecode(jsonString);
              UserLocation receivedLocation = UserLocation(
                userId: locationData['id'],
                latitude: locationData['lat'],
                longitude: locationData['lon'],
                timestamp: DateTime.parse(locationData['time']),
              );

              print("Received location: ${receivedLocation.userId}");
              // TODO: Store in local database
            }
          }
        }
      }

      await device.disconnect();
    } catch (e) {
      print("Error connecting and syncing: $e");
    }
  }
}
