import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

Future<void> broadcastLocation(UserLocation location) async {
  // serialize & advertise over BLE (Bluetooth Low Energy)
  String payload = jsonEncode({
    'id': location.userId,
    'lat': location.latitude,
    'lon': location.longitude,
    'time': location.timestamp.toIso8601String()
  });

  // Advertise this string as Bluetooth packet (mock)
  // Advanced: You can use Bluetooth GATT services to make this more robust
}
