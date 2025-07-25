import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'trip_details.g.dart';

@HiveType(typeId: 4)
class TripDetails extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String destinationName;

  @HiveField(2)
  String description;

  @HiveField(3)
  String region;

  @HiveField(4)
  double latitude;

  @HiveField(5)
  double longitude;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? startDate;

  @HiveField(8)
  DateTime? endDate;

  @HiveField(9)
  List<String> attractions;

  @HiveField(10)
  String status; // 'planned', 'active', 'completed'

  @HiveField(11)
  String? coverImage;

  @HiveField(12)
  int journalEntriesCount;

  @HiveField(13)
  bool hasOfflineMaps;

  TripDetails({
    required this.id,
    required this.destinationName,
    required this.description,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.startDate,
    this.endDate,
    required this.attractions,
    this.status = 'planned',
    this.coverImage,
    this.journalEntriesCount = 0,
    this.hasOfflineMaps = false,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  String get statusDisplay {
    switch (status) {
      case 'planned':
        return 'Planning';
      case 'active':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  String get durationText {
    if (startDate == null || endDate == null) {
      return 'Date TBD';
    }

    final duration = endDate!.difference(startDate!).inDays;
    if (duration == 0) {
      return 'Day trip';
    } else if (duration == 1) {
      return '2 days';
    } else {
      return '${duration + 1} days';
    }
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isPlanned => status == 'planned';
}
