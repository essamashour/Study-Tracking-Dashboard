import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/study_item_model.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';

class SyncService {
  final FirestoreService _firestore;
  final LocalStorageService _local;

  SyncService(this._firestore, this._local);

  Future<void> syncAll(String uid) async {
    await _syncFirestoreToLocal(uid);
    await _syncLocalToFirestore(uid);
  }

  Future<void> syncFirestoreToLocal(String uid) async {
    await _syncFirestoreToLocal(uid);
  }

  Future<void> syncLocalToFirestore(String uid) async {
    await _syncLocalToFirestore(uid);
  }

  Future<void> _syncFirestoreToLocal(String uid) async {
    final courseSnap = await _firestore.getUserCourses(uid).first;
    final courses = courseSnap.docs
        .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
        .toList();
    await _local.clearStudyData();
    for (final course in courses) {
      await _local.addCourse(course);
    }

    final itemSnap = await _firestore.getStudyItems(uid).first;
    final items = itemSnap.docs
        .map((doc) => StudyItemModel.fromMap(doc.data(), doc.id))
        .toList();
    for (final item in items) {
      await _local.addStudyItem(item);
    }
  }

  Future<void> _syncLocalToFirestore(String uid) async {
    final localCourses = _local.getCourses();
    for (final course in localCourses) {
      final data = course.toMap();
      await _firestore.coursesCol.doc(course.id).set(data, SetOptions(merge: true));
    }

    final localItems = _local.getStudyItems();
    for (final item in localItems) {
      await _firestore.itemsCol.doc(item.id).set(item.toFirestoreCreate(), SetOptions(merge: true));
    }
  }
}
