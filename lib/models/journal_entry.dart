import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 1)
class JournalEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  List<String> photoPaths;

  @HiveField(5)
  String mood; // emoji string

  @HiveField(6)
  DateTime timestamp;

  @HiveField(7)
  double? latitude;

  @HiveField(8)
  double? longitude;

  @HiveField(9)
  String? locationName;

  @HiveField(10)
  String? weather;

  JournalEntry({
    required this.id,
    required this.tripId,
    required this.title,
    required this.content,
    this.photoPaths = const [],
    this.mood = '😊',
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.locationName,
    this.weather,
  });
}
