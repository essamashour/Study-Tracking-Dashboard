import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../widgets/add_course_dialog.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final FirestoreService _firestore = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService();
  late final SyncService _syncService;
  Stream<List<CourseModel>> _coursesStream = Stream.value(<CourseModel>[]);
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncService = SyncService(_firestore, _localStorage);
    _coursesStream = _localStorage.getCoursesStream();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_syncInBackground());
    });
  }

  Future<void> _syncInBackground() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (mounted) setState(() => _syncing = true);
    try {
      await _syncService.syncAll(user.uid).timeout(const Duration(seconds: 10));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _scheduleSubtitle(CourseModel c) {
    final lec = c.scheduleLine('lecture');
    final sec = c.scheduleLine('section');
    final lab = c.scheduleLine('lab');
    final parts = <String>[];
    if (lec != null) parts.add('محاضرة: $lec');
    if (sec != null) parts.add('تمارين: $sec');
    if (lab != null) parts.add('معمل: $lab');
    if (parts.isEmpty) return '';
    return parts.join(' • ');
  }

  Widget _header(BuildContext context, {required int count}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الكورسات',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 0
                      ? 'أضف أول كورس لتبدأ.'
                      : 'إجمالي الكورسات: $count',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showClearAllConfirmation(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'حذف الكل',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد كورسات بعد',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'اضغط على زر + لإضافة كورس جديد مع عدد المحاضرات والجدول.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جميع البيانات'),
        content: const Text(
            'هل أنت متأكد من حذف جميع الكورسات والبدء من جديد؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = FirebaseAuth.instance.currentUser!;
              await _syncService.syncAll(user.uid);
              await _localStorage.clearStudyData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCourseDialog(
    BuildContext context,
    CourseModel course,
    User user,
  ) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: course.name);
    final lectures = TextEditingController(
      text: course.lectures == 0 ? '' : course.lectures.toString(),
    );
    final labs = TextEditingController(
      text: course.labs == 0 ? '' : course.labs.toString(),
    );
    final sections = TextEditingController(
      text: course.sections == 0 ? '' : course.sections.toString(),
    );
    final lectureTime =
        TextEditingController(text: course.scheduleLine('lecture') ?? '');
    final sectionTime =
        TextEditingController(text: course.scheduleLine('section') ?? '');
    final labTime = TextEditingController(text: course.scheduleLine('lab') ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الكورس'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم الكورس'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: lectures,
                  decoration: const InputDecoration(labelText: 'عدد المحاضرات'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    final n = int.tryParse(value);
                    if (n == null || n < 0) return 'رقم صحيح ≥ 0';
                    return null;
                  },
                ),
                TextFormField(
                  controller: labs,
                  decoration: const InputDecoration(labelText: 'عدد المعامل'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    final n = int.tryParse(value);
                    if (n == null || n < 0) return 'رقم صحيح ≥ 0';
                    return null;
                  },
                ),
                TextFormField(
                  controller: sections,
                  decoration: const InputDecoration(labelText: 'عدد التمارين'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    final n = int.tryParse(value);
                    if (n == null || n < 0) return 'رقم صحيح ≥ 0';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'الجدول (اختياري)',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                TextFormField(
                  controller: lectureTime,
                  decoration: const InputDecoration(labelText: 'وقت المحاضرة'),
                ),
                TextFormField(
                  controller: sectionTime,
                  decoration: const InputDecoration(labelText: 'وقت التمارين'),
                ),
                TextFormField(
                  controller: labTime,
                  decoration: const InputDecoration(labelText: 'وقت المعمل'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final schedule = <String, dynamic>{
                if (lectureTime.text.trim().isNotEmpty)
                  'lecture': lectureTime.text.trim(),
                if (sectionTime.text.trim().isNotEmpty)
                  'section': sectionTime.text.trim(),
                if (labTime.text.trim().isNotEmpty) 'lab': labTime.text.trim(),
              };
              final updated = CourseModel(
                id: course.id,
                name: name.text.trim(),
                lectures: int.tryParse(lectures.text.trim()) ?? 0,
                labs: int.tryParse(labs.text.trim()) ?? 0,
                sections: int.tryParse(sections.text.trim()) ?? 0,
                schedule: schedule.isEmpty ? null : schedule,
              );

              if (ctx.mounted) Navigator.pop(ctx);

              await _localStorage.upsertCourseById(updated);
              unawaited(
                _firestore
                    .updateCourse(
                      uid: user.uid,
                      courseId: updated.id,
                      courseData: updated.toMap(),
                    )
                    .catchError((_) {}),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    name.dispose();
    lectures.dispose();
    labs.dispose();
    sections.dispose();
    lectureTime.dispose();
    sectionTime.dispose();
    labTime.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    final scaffold = Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_syncing)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: _coursesStream,
              builder: (context, snapshot) {
                final courses =
                    snapshot.data ?? _localStorage.getCourses();
                if (snapshot.hasError && courses.isEmpty) {
                  return Center(
                    child: Text('فشل تحميل البيانات: ${snapshot.error}'),
                  );
                }
                return _buildCourseList(context, courses, user);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AddCourseDialog(
              onAdd: (name, lectures, labs, sections, schedule) async {
                final course = CourseModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  lectures: lectures,
                  labs: labs,
                  sections: sections,
                  schedule: schedule,
                );
                await _localStorage.addCourse(course);
                unawaited(
                  _firestore
                      .updateCourse(
                        uid: user.uid,
                        courseId: course.id,
                        courseData: course.toMap(),
                      )
                      .catchError((_) {}),
                );
                try {
                  await _syncService
                      .syncLocalToFirestore(user.uid)
                      .timeout(const Duration(seconds: 12));
                } catch (_) {}
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await _syncService.syncAll(user.uid);
      },
      child: scaffold,
    );
  }

  Widget _buildCourseList(BuildContext context, List<CourseModel> courses, User user) {
    final count = courses.length;

    if (count == 0) {
      return Column(
        children: [
          _header(context, count: 0),
          const SizedBox(height: 6),
          Expanded(child: _emptyState(context)),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 104),
      itemCount: count + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _header(context, count: count);
        }
        final course = courses[i - 1];
        final sched = _scheduleSubtitle(course);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.book_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statPill(context, Icons.school_outlined,
                                  'محاضرات ${course.lectures}'),
                              _statPill(
                                  context, Icons.science_outlined, 'معامل ${course.labs}'),
                              _statPill(context, Icons.groups_outlined,
                                  'تمارين ${course.sections}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditCourseDialog(context, course, user),
                      tooltip: 'تعديل الكورس',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _localStorage.deleteCourseById(course.id);
                        unawaited(
                          _firestore
                              .deleteCourse(
                                uid: user.uid,
                                courseId: course.id,
                              )
                              .catchError((_) {}),
                        );
                      },
                      tooltip: 'حذف الكورس',
                    ),
                  ],
                ),
                if (sched.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sched,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
