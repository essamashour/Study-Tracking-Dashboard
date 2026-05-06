import 'package:hive/hive.dart';

part 'course_model.g.dart';

@HiveType(typeId: 0)
class CourseModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int lectures;
  @HiveField(3)
  final int labs;
  @HiveField(4)
  final int sections;
  @HiveField(5)
  final Map<String, dynamic>? schedule;

  CourseModel({
    required this.id,
    required this.name,
    required this.lectures,
    required this.labs,
    required this.sections,
    this.schedule,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) {
    final sched = map['schedule'];
    return CourseModel(
      id: id,
      name: map['name'] ?? '',
      lectures: (map['lectures'] as num?)?.toInt() ?? 0,
      labs: (map['labs'] as num?)?.toInt() ?? 0,
      sections: (map['sections'] as num?)?.toInt() ?? 0,
      schedule: sched is Map ? Map<String, dynamic>.from(sched as Map) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lectures': lectures,
      'labs': labs,
      'sections': sections,
      if (schedule != null && schedule!.isNotEmpty) 'schedule': schedule,
    };
  }

  String? scheduleLine(String key) {
    final s = schedule?[key];
    if (s == null) return null;
    final t = s.toString().trim();
    return t.isEmpty ? null : t;
  }
}
