import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/study_item_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../utils/deadline_status.dart';

DeadlineUiStatus _courseStatus(List<StudyItemModel> items) {
  if (items.isEmpty) return DeadlineUiStatus.noDeadline;
  if (items.every((e) => e.isDone)) return DeadlineUiStatus.allDone;
  final open = items.where((e) => !e.isDone).toList();
  final anyUrgent = open.any((e) {
    final s = DeadlineStatus.itemStatus(isDone: false, deadline: e.deadline);
    return s == DeadlineUiStatus.overdueOrUrgent;
  });
  if (anyUrgent) return DeadlineUiStatus.overdueOrUrgent;
  return DeadlineUiStatus.inProgress;
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final FirestoreService _firestore = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService();

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Text(
        'التقدم',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final theme = Theme.of(context);

    return Scaffold(
      body: StreamBuilder<List<CourseModel>>(
        stream: _localStorage.getCoursesStream(),
        builder: (context, courseSnap) {
          final courses = courseSnap.data ?? _localStorage.getCourses();

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore.getStudyItems(user.uid),
            builder: (context, itemSnap) {
              if (itemSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (itemSnap.hasError) {
                return Center(
                  child: Text(
                    'فشل تحميل البيانات، تحقق من الاتصال وجرب مرة أخرى.',
                  ),
                );
              }

              final items = (itemSnap.data?.docs ?? [])
                  .map((d) => StudyItemModel.fromMap(d.data(), d.id))
                  .toList();

              final byCourse = <String, List<StudyItemModel>>{};
              for (final c in courses) {
                byCourse[c.id] = [];
              }
              for (final it in items) {
                byCourse.putIfAbsent(it.courseId, () => []).add(it);
              }

              var totalItems = 0;
              var totalDone = 0;
              for (final it in items) {
                totalItems++;
                if (it.isDone) totalDone++;
              }
              final globalPct =
                  totalItems == 0 ? 0.0 : (totalDone / totalItems) * 100;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  _header(context),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          title: 'إجمالي العناصر',
                          value: '$totalItems',
                          icon: Icons.list_alt_rounded,
                        ),
                      ),
                      Expanded(
                        child: _statCard(
                          context,
                          title: 'مكتمل',
                          value: '$totalDone',
                          icon: Icons.verified_rounded,
                        ),
                      ),
                    ],
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'النسبة العامة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 12,
                              value: totalItems == 0 ? 0 : globalPct / 100,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              color: globalPct >= 99.9
                                  ? Colors.green.shade600
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${globalPct.toStringAsFixed(0)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تقدم كل كورس',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (courses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('لا توجد كورسات بعد')),
                    )
                  else
                    ...courses.map((c) {
                      final list = byCourse[c.id] ?? [];
                      final done = list.where((e) => e.isDone).length;
                      final total = list.length;
                      final pct = total == 0 ? 0.0 : (done / total) * 100;
                      final st = _courseStatus(list);
                      final accent =
                          DeadlineStatus.accentFor(st, theme.colorScheme);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  Icon(Icons.circle, color: accent, size: 14),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('مكتمل: $done / $total'),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 12,
                                  value: total == 0 ? 0 : pct / 100,
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${pct.toStringAsFixed(0)}%'),
                              if (total == 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'لا عناصر بعد — أضف من تبويب المهام',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
