import 'package:hive/hive.dart';

part 'checklist_item.g.dart';

@HiveType(typeId: 2)
class ChecklistItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String tripId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  String category; // personal, group, suggested

  @HiveField(6)
  String? assignedTo; // for group checklists

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  int priority; // 1-5, 5 being highest

  ChecklistItem({
    required this.id,
    required this.tripId,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.category = 'personal',
    this.assignedTo,
    required this.createdAt,
    this.completedAt,
    this.priority = 3,
  });
}
