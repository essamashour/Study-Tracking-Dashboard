import 'dart:async';

import 'package:flutter/material.dart';

class AddCourseDialog extends StatefulWidget {
  final Future<void> Function(
    String name,
    int lectures,
    int labs,
    int sections,
    Map<String, dynamic>? schedule,
  ) onAdd;

  const AddCourseDialog({super.key, required this.onAdd});

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lectures = TextEditingController();
  final _labs = TextEditingController();
  final _sections = TextEditingController();
  final _lectureTime = TextEditingController();
  final _sectionTime = TextEditingController();
  final _labTime = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _lectures.dispose();
    _labs.dispose();
    _sections.dispose();
    _lectureTime.dispose();
    _sectionTime.dispose();
    _labTime.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _schedule() {
    final lec = _lectureTime.text.trim();
    final sec = _sectionTime.text.trim();
    final lab = _labTime.text.trim();
    if (lec.isEmpty && sec.isEmpty && lab.isEmpty) return null;
    return {
      if (lec.isNotEmpty) 'lecture': lec,
      if (sec.isNotEmpty) 'section': sec,
      if (lab.isNotEmpty) 'lab': lab,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final lectures = int.tryParse(_lectures.text) ?? 0;
    final labs = int.tryParse(_labs.text) ?? 0;
    final sections = int.tryParse(_sections.text) ?? 0;
    final saveFuture = widget.onAdd(
        _name.text.trim(),
        lectures,
        labs,
        sections,
        _schedule(),
      );

    if (mounted) Navigator.pop(context);

    unawaited(
      saveFuture.timeout(const Duration(seconds: 12)).catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة كورس جديد'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم الكورس'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _lectures,
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
                controller: _labs,
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
                controller: _sections,
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
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextFormField(
                controller: _lectureTime,
                decoration: const InputDecoration(
                  labelText: 'وقت المحاضرة',
                  hintText: 'مثال: الأحد 10 ص',
                ),
              ),
              TextFormField(
                controller: _sectionTime,
                decoration: const InputDecoration(
                  labelText: 'وقت التمارين',
                  hintText: 'مثال: الثلاثاء 2 م',
                ),
              ),
              TextFormField(
                controller: _labTime,
                decoration: const InputDecoration(
                  labelText: 'وقت المعمل',
                  hintText: 'مثال: الخميس 12 م',
                ),
              ),
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
              : const Text('إضافة'),
        ),
      ],
    );
  }
}
