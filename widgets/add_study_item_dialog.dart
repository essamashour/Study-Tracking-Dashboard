import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course_model.dart';
import '../models/study_item_model.dart';
import '../services/firestore_service.dart';

class AddStudyItemDialog extends StatefulWidget {
  final String uid;
  final List<CourseModel> courses;
  final String? initialCourseId;

  const AddStudyItemDialog({
    super.key,
    required this.uid,
    required this.courses,
    this.initialCourseId,
  });

  @override
  State<AddStudyItemDialog> createState() => _AddStudyItemDialogState();
}

class _AddStudyItemDialogState extends State<AddStudyItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _priority = TextEditingController(text: '0');
  final _firestore = FirestoreService();

  String? _courseId;
  StudyItemKind _kind = StudyItemKind.task;
  DateTime? _deadline;
  bool _hasDeadline = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.courses.isEmpty) return;
    final preferred = widget.initialCourseId;
    final exists = preferred != null &&
        widget.courses.any((course) => course.id == preferred);
    _courseId = exists ? preferred : widget.courses.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    _priority.dispose();
    super.dispose();
  }

  String _courseName() {
    final id = _courseId;
    if (id == null) return '';
    return widget.courses.firstWhere((c) => c.id == id, orElse: () => widget.courses.first).name;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? first,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) {
      final tod = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
      );
      if (tod != null && mounted) {
        setState(() {
          _deadline = DateTime(
            picked.year,
            picked.month,
            picked.day,
            tod.hour,
            tod.minute,
          );
        });
      } else if (mounted) {
        setState(() {
          _deadline = DateTime(picked.year, picked.month, picked.day, 23, 59);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (_courseId == null) return;
    if (_hasDeadline && _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر موعداً نهائياً أو عطّل الخيار')),
      );
      return;
    }

    setState(() => _saving = true);
    final item = StudyItemModel(
      id: '',
      courseId: _courseId!,
      courseName: _courseName(),
      kind: _kind,
      title: _title.text.trim(),
      deadline: _hasDeadline ? _deadline : null,
      isDone: false,
      priority: int.tryParse(_priority.text) ?? 0,
    );

    if (mounted) Navigator.pop(context);

    unawaited(
      _firestore
          .addStudyItem(uid: widget.uid, item: item)
          .timeout(const Duration(seconds: 12))
          .catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.courses.isEmpty) {
      return AlertDialog(
        title: const Text('إضافة عنصر'),
        content: const Text('أضف كورساً أولاً من تبويب الكورسات.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      );
    }

    final df = DateFormat('yyyy/MM/dd HH:mm');

    return AlertDialog(
      title: const Text('عنصر دراسي جديد'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _courseId,
                decoration: const InputDecoration(labelText: 'الكورس'),
                items: widget.courses
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _courseId = v),
                validator: (v) => v == null ? 'اختر كورساً' : null,
              ),
              DropdownButtonFormField<StudyItemKind>(
                value: _kind,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: StudyItemKind.values
                    .map(
                      (k) => DropdownMenuItem(
                        value: k,
                        child: Text(k.labelAr),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _kind = v ?? StudyItemKind.task),
              ),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'العنوان'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _priority,
                decoration: const InputDecoration(
                  labelText: 'الأولوية (للترتيب)',
                  hintText: 'رقم أكبر = أهم',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (int.tryParse(v ?? '') == null) return 'رقم صحيح';
                  return null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('له موعد نهائي'),
                value: _hasDeadline,
                onChanged: (v) => setState(() {
                  _hasDeadline = v;
                  if (!v) _deadline = null;
                }),
              ),
              if (_hasDeadline) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _deadline == null
                        ? 'لم يُحدد الموعد'
                        : df.format(_deadline!),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _pickDate,
                    child: const Text('اختيار'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
