import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/study_item_model.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../utils/deadline_status.dart';
import '../widgets/add_study_item_dialog.dart';

enum _TaskSort { byDeadline, byPriority }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FirestoreService _firestore = FirestoreService();
  final LocalStorageService _localStorage = LocalStorageService();
  String? _courseFilter;
  _TaskSort _sort = _TaskSort.byDeadline;

  Future<void> _deleteTask(String uid, String itemId) async {
    await _firestore.deleteStudyItem(uid: uid, itemId: itemId);
  }

  Future<void> _showDeleteAllTasksConfirmation(
    BuildContext context,
    String uid,
    List<StudyItemModel> allItems,
  ) async {
    if (allItems.isEmpty) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جميع المهام'),
        content: const Text(
          'هل أنت متأكد من حذف جميع المهام؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final item in allItems) {
                unawaited(_deleteTask(uid, item.id).catchError((_) {}));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTaskDialog(
    BuildContext context,
    String uid,
    StudyItemModel item,
  ) async {
    final formKey = GlobalKey<FormState>();
    final title = TextEditingController(text: item.title);
    final priority = TextEditingController(
      text: item.priority == 0 ? '' : item.priority.toString(),
    );
    var kind = item.kind;
    var hasDeadline = item.deadline != null;
    DateTime? deadline = item.deadline;

    Future<void> pickDate(StateSetter setLocalState) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: deadline ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 3),
      );
      if (picked == null) return;
      final tod = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(deadline ?? now),
      );
      setLocalState(() {
        deadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          tod?.hour ?? 23,
          tod?.minute ?? 59,
        );
      });
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('تعديل المهمة'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<StudyItemKind>(
                    value: kind,
                    decoration: const InputDecoration(labelText: 'النوع'),
                    items: StudyItemKind.values
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Text(k.labelAr),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setLocalState(() => kind = v ?? StudyItemKind.task),
                  ),
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'مطلوب' : null,
                  ),
                  TextFormField(
                    controller: priority,
                    decoration: const InputDecoration(labelText: 'الأولوية'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      if (int.tryParse(value) == null) return 'رقم صحيح';
                      return null;
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('له موعد نهائي'),
                    value: hasDeadline,
                    onChanged: (v) => setLocalState(() {
                      hasDeadline = v;
                      if (!v) deadline = null;
                    }),
                  ),
                  if (hasDeadline)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        deadline == null
                            ? 'لم يُحدد الموعد'
                            : '${deadline!.year}/${deadline!.month.toString().padLeft(2, '0')}/${deadline!.day.toString().padLeft(2, '0')} ${deadline!.hour.toString().padLeft(2, '0')}:${deadline!.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () => pickDate(setLocalState),
                        child: const Text('اختيار'),
                      ),
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
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                if (hasDeadline && deadline == null) return;
                if (ctx.mounted) Navigator.pop(ctx);
                unawaited(
                  _firestore
                      .updateStudyItem(
                        uid: uid,
                        itemId: item.id,
                        data: {
                          'title': title.text.trim(),
                          'kind': kind.firestoreValue,
                          'priority': int.tryParse(priority.text.trim()) ?? 0,
                          'deadline': hasDeadline && deadline != null
                              ? Timestamp.fromDate(deadline!)
                              : null,
                        },
                      )
                      .catchError((_) {}),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    priority.dispose();
  }

  Widget _header(
    BuildContext context, {
    required int total,
    required int done,
    required VoidCallback onDeleteAll,
  }) {
    final theme = Theme.of(context);
    final remaining = total - done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'المهام',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$done / $total',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (total > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDeleteAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                        SizedBox(width: 6),
                        Text(
                          'حذف الكل',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            total == 0 ? 'أضف واجب/مهمة/اختبار من زر +.' : 'متبقي: $remaining • مكتمل: $done',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  int _deadlineSortKey(StudyItemModel m) {
    final d = m.deadline;
    if (d == null) return 1 << 30;
    return d.millisecondsSinceEpoch;
  }

  List<StudyItemModel> _sorted(List<StudyItemModel> items) {
    final copy = List<StudyItemModel>.from(items);
    switch (_sort) {
      case _TaskSort.byDeadline:
        copy.sort((a, b) {
          final ac = a.isDone ? 1 : 0;
          final bc = b.isDone ? 1 : 0;
          if (ac != bc) return ac.compareTo(bc);
          return _deadlineSortKey(a).compareTo(_deadlineSortKey(b));
        });
      case _TaskSort.byPriority:
        copy.sort((a, b) {
          final ac = a.isDone ? 1 : 0;
          final bc = b.isDone ? 1 : 0;
          if (ac != bc) return ac.compareTo(bc);
          final p = b.priority.compareTo(a.priority);
          if (p != 0) return p;
          return _deadlineSortKey(a).compareTo(_deadlineSortKey(b));
        });
    }
    return copy;
  }

  Future<void> _openAdd(
    BuildContext context,
    String uid,
    List<CourseModel> courses,
    String? initialCourseId,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AddStudyItemDialog(
        uid: uid,
        courses: courses,
        initialCourseId: initialCourseId,
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
              if (itemSnap.hasError) {
                return Center(child: Text('فشل تحميل البيانات، تحقق من الاتصال وجرب مرة أخرى.'));
              }

              final raw = itemSnap.data?.docs ?? [];
              var items = raw
                  .map((d) => StudyItemModel.fromMap(d.data(), d.id))
                  .toList();

              if (_courseFilter != null) {
                items =
                    items.where((e) => e.courseId == _courseFilter).toList();
              }

              final allItems = raw
                  .map((d) => StudyItemModel.fromMap(d.data(), d.id))
                  .toList();
              final sorted = _sorted(items);
              final allTotal = allItems.length;
              final done = allItems.where((e) => e.isDone).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(
                    context,
                    total: allTotal,
                    done: done,
                    onDeleteAll: () => _showDeleteAllTasksConfirmation(
                      context,
                      user.uid,
                      allItems,
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('الكل'),
                          selected: _courseFilter == null,
                          onSelected: (_) =>
                              setState(() => _courseFilter = null),
                        ),
                        const SizedBox(width: 8),
                        ...courses.expand((c) => [
                              ChoiceChip(
                                label: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: _courseFilter == c.id,
                                onSelected: (_) =>
                                    setState(() => _courseFilter = c.id),
                              ),
                              const SizedBox(width: 8),
                            ]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<_TaskSort>(
                            segments: const [
                              ButtonSegment(
                                value: _TaskSort.byDeadline,
                                label: Text('الموعد'),
                                icon: Icon(Icons.event, size: 18),
                              ),
                              ButtonSegment(
                                value: _TaskSort.byPriority,
                                label: Text('الأولوية'),
                                icon: Icon(Icons.flag, size: 18),
                              ),
                            ],
                            selected: {_sort},
                            onSelectionChanged: (s) =>
                                setState(() => _sort = s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sorted.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد عناصر بعد.\nأضف واجبات أو مهام من زر +',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 104),
                            itemCount: sorted.length,
                            itemBuilder: (context, i) {
                              final m = sorted[i];
                              final st = DeadlineStatus.itemStatus(
                                isDone: m.isDone,
                                deadline: m.deadline,
                              );
                              final tint = DeadlineStatus.tintFor(st, theme);
                              final accent = DeadlineStatus.accentFor(
                                st,
                                theme.colorScheme,
                              );
                              final deadlineText = m.deadline == null
                                  ? 'بدون موعد'
                                  : '${m.deadline!.year}/${m.deadline!.month.toString().padLeft(2, '0')}/${m.deadline!.day.toString().padLeft(2, '0')}';

                              return Card(
                                color: tint,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: m.isDone,
                                        onChanged: (v) async {
                                          if (v == null) return;
                                          await _firestore.updateStudyItemDone(
                                            uid: user.uid,
                                            itemId: m.id,
                                            isDone: v,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    m.title,
                                                    style: theme.textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w800,
                                                      decoration: m.isDone
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(Icons.circle, color: accent, size: 12),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${m.kind.labelAr} • ${m.courseName}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _pill(
                                                  context,
                                                  Icons.event_outlined,
                                                  deadlineText,
                                                ),
                                                _pill(
                                                  context,
                                                  Icons.flag_outlined,
                                                  'أولوية ${m.priority}',
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  tooltip: 'تعديل',
                                                  onPressed: () =>
                                                      _showEditTaskDialog(
                                                    context,
                                                    user.uid,
                                                    m,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                                ),
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  tooltip: 'حذف',
                                                  onPressed: () =>
                                                      _deleteTask(user.uid, m.id),
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final courses = _localStorage.getCourses();
          if (!context.mounted) return;
          await _openAdd(context, user.uid, courses, _courseFilter);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String text) {
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
}
