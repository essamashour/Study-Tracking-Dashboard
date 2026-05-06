import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _coursesCol(String uid) =>
      _db.collection('users').doc(uid).collection('courses');

  CollectionReference<Map<String, dynamic>> _itemsCol(String uid) =>
      _db.collection('users').doc(uid).collection('studyItems');

  CollectionReference<Map<String, dynamic>> get coursesCol => _coursesCol(FirebaseAuth.instance.currentUser!.uid);

  CollectionReference<Map<String, dynamic>> get itemsCol => _itemsCol(FirebaseAuth.instance.currentUser!.uid);

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserCourses(String uid) {
    return _coursesCol(uid).orderBy('name').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudyItems(String uid) {
    return _itemsCol(uid).snapshots();
  }

  Future<void> addCourse({
    required String uid,
    required String name,
    required int lectures,
    required int labs,
    required int sections,
    Map<String, dynamic>? schedule,
  }) async {
    await _coursesCol(uid).add({
      'name': name,
      'lectures': lectures,
      'labs': labs,
      'sections': sections,
      if (schedule != null && schedule.isNotEmpty) 'schedule': schedule,
    });
  }

  Future<void> addStudyItem({
    required String uid,
    required StudyItemModel item,
  }) async {
    await _itemsCol(uid).add(item.toFirestoreCreate());
  }

  Future<void> updateStudyItemDone({
    required String uid,
    required String itemId,
    required bool isDone,
  }) async {
    await _itemsCol(uid).doc(itemId).update({'isDone': isDone});
  }

  Future<void> updateStudyItemPriority({
    required String uid,
    required String itemId,
    required int priority,
  }) async {
    await _itemsCol(uid).doc(itemId).update({'priority': priority});
  }

  Future<void> updateStudyItem({
    required String uid,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    await _itemsCol(uid).doc(itemId).update(data);
  }

  Future<void> deleteStudyItem({
    required String uid,
    required String itemId,
  }) async {
    await _itemsCol(uid).doc(itemId).delete();
  }

  Future<void> deleteCourse({
    required String uid,
    required String courseId,
  }) async {
    await _coursesCol(uid).doc(courseId).delete();
  }

  Future<void> updateCourse({
    required String uid,
    required String courseId,
    required Map<String, dynamic> courseData,
  }) async {
    await _coursesCol(uid).doc(courseId).update(courseData);
  }
}
