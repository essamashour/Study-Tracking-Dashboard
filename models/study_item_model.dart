import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'study_item_model.g.dart';

enum StudyItemKind {
  assignment,
  task,
  quiz,
  project,
  examMidterm,
  examFinal;

  String get firestoreValue => name;

  String get labelAr => switch (this) {
        StudyItemKind.assignment => 'واجب',
        StudyItemKind.task => 'مهمة',
        StudyItemKind.quiz => 'كويز',
        StudyItemKind.project => 'مشروع',
        StudyItemKind.examMidterm => 'امتحان نصفي',
        StudyItemKind.examFinal => 'نهائي',
      };

  static StudyItemKind fromFirestore(Object? v) {
    final s = v?.toString();
    switch (s) {
      case 'assignment':
        return StudyItemKind.assignment;
      case 'quiz':
        return StudyItemKind.quiz;
      case 'project':
        return StudyItemKind.project;
      case 'examMidterm':
        return StudyItemKind.examMidterm;
      case 'examFinal':
        return StudyItemKind.examFinal;
      case 'task':
      default:
        return StudyItemKind.task;
    }
  }
}

@HiveType(typeId: 1)
class StudyItemModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String courseId;
  @HiveField(2)
  final String courseName;
  @HiveField(3)
  final StudyItemKind kind;
  @HiveField(4)
  final String title;
  @HiveField(5)
  final DateTime? deadline;
  @HiveField(6)
  final bool isDone;
  @HiveField(7)
  final int priority;

  StudyItemModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.kind,
    required this.title,
    this.deadline,
    required this.isDone,
    required this.priority,
  });

  static DateTime? _parseDeadline(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory StudyItemModel.fromMap(Map<String, dynamic> map, String id) {
    return StudyItemModel(
      id: id,
      courseId: map['courseId'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      kind: StudyItemKind.fromFirestore(map['kind']),
      title: map['title'] as String? ?? '',
      deadline: _parseDeadline(map['deadline']),
      isDone: map['isDone'] as bool? ?? false,
      priority: (map['priority'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'kind': kind.firestoreValue,
      'title': title,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
      'isDone': isDone,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
