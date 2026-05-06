import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/study_item_model.dart';
import 'firestore_service.dart';
import 'sync_service.dart';

class LocalStorageService {
  LocalStorageService._internal() {
    _initBoxes();
  }

  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  static const String _coursesBoxKey = 'courses';
  static const String _studyItemsBoxKey = 'study_items';
  static const String _userSettingsBoxKey = 'user_settings';
  static const String _lastUserIdKey = 'last_user_id';

  Box<CourseModel>? _coursesBox;
  Box<StudyItemModel>? _studyItemsBox;
  Box<dynamic>? _userSettingsBox;

  Future<void> _initBoxes() async {
    try {
      _coursesBox = Hive.box<CourseModel>(_coursesBoxKey);
      _studyItemsBox = Hive.box<StudyItemModel>(_studyItemsBoxKey);
      _userSettingsBox = Hive.box<dynamic>(_userSettingsBoxKey);
    } catch (_) {}
  }

  Stream<List<CourseModel>> getCoursesStream() async* {
    final box = _coursesBox;
    if (box == null) {
      yield [];
      return;
    }
    // Hive watch() does not emit until a change — emit current snapshot first.
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }

  List<CourseModel> getCourses() {
    if (_coursesBox == null) return [];
    return _coursesBox!.values.toList();
  }

  Future<void> addCourse(CourseModel course) async {
    if (_coursesBox == null) return;
    await _coursesBox!.add(course);
  }

  Future<void> upsertCourseById(CourseModel course) async {
    if (_coursesBox == null) return;
    dynamic matchedKey;
    for (final key in _coursesBox!.keys) {
      final value = _coursesBox!.get(key);
      if (value != null && value.id == course.id) {
        matchedKey = key;
        break;
      }
    }
    if (matchedKey != null) {
      await _coursesBox!.put(matchedKey, course);
    } else {
      await _coursesBox!.add(course);
    }
  }

  Future<void> deleteCourseById(String courseId) async {
    if (_coursesBox == null) return;
    dynamic matchedKey;
    for (final key in _coursesBox!.keys) {
      final value = _coursesBox!.get(key);
      if (value != null && value.id == courseId) {
        matchedKey = key;
        break;
      }
    }
    if (matchedKey != null) {
      await _coursesBox!.delete(matchedKey);
    }
  }

  Stream<List<StudyItemModel>> getStudyItemsStream() async* {
    final box = _studyItemsBox;
    if (box == null) {
      yield [];
      return;
    }
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }

  List<StudyItemModel> getStudyItems() {
    if (_studyItemsBox == null) return [];
    return _studyItemsBox!.values.toList();
  }

  Future<void> addStudyItem(StudyItemModel item) async {
    if (_studyItemsBox == null) return;
    await _studyItemsBox!.add(item);
  }

  Future<void> clearStudyData() async {
    if (_coursesBox != null) await _coursesBox!.clear();
    if (_studyItemsBox != null) await _studyItemsBox!.clear();
  }

  Future<void> prepareForUser(String? userId) async {
    if (_userSettingsBox == null) return;
    final previousUserId = _userSettingsBox!.get(_lastUserIdKey) as String?;

    if (userId == null) {
      await clearStudyData();
      await _userSettingsBox!.delete(_lastUserIdKey);
      return;
    }

    if (previousUserId != null && previousUserId != userId) {
      await clearStudyData();
    }

    await _userSettingsBox!.put(_lastUserIdKey, userId);
  }

  Future<void> syncFromFirestore(FirestoreService firestore) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await SyncService(firestore, this).syncFirestoreToLocal(uid);
  }

  Future<void> close() async {
    if (_coursesBox != null) await _coursesBox!.close();
    if (_studyItemsBox != null) await _studyItemsBox!.close();
    if (_userSettingsBox != null) await _userSettingsBox!.close();
  }
}
