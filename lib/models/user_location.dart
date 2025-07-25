import 'package:hive/hive.dart';

part 'user_location.g.dart';

@HiveType(typeId: 3)
class UserLocation extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  @HiveField(3)
  DateTime timestamp;

  UserLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
