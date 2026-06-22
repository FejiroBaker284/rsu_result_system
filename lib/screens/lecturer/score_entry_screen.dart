import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/result_service.dart';
import '../../models/result_model.dart';
import '../../models/student_model.dart';
import '../../providers/result_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common_widgets.dart';

class ScoreEntryScreen extends ConsumerStatefulWidget {
  final String sheetId;
  const ScoreEntryScreen({super.key, required this.sheetId});

  @override
  ConsumerState<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends ConsumerState<ScoreEntryScreen> {
  final Map<String, TextEditingController> _caControllers = {};
  final Map<String, TextEditingController> _examControllers = {};
  bool _isSaving = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (var c in _caControllers.values) c.dispose();
    for (var c in _examControllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _getCaCtrl(String studentId, double initial) {
    return _caControllers.putIfAbsent(
        studentId, () => TextEditingController(text: initial > 0 ? '$initial' : ''));
  }

  TextEditingController _getExamCtrl(String studentId, double initial) {
    return _examControllers.putIfAbsent(
        studentId, () => TextEditingController(text: initial > 0 ? '$initial' : ''));
  }

  Future<void> _saveScores(
      ResultSheetModel sheet, List<StudentResultModel> results, List<StudentModel> students) async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(resultServiceProvider);
      for (final student in students) {
        final caCtrl = _caControllers[student.id];
        final examCtrl = _examControllers[student.id];
        if (caCtrl == null && examCtrl == null) continue;
        final ca = double.tryParse(caCtrl?.text ?? '0') ?? 0;
        final exam = double.tryParse(examCtrl?.text ?? '0') ?? 0;
        await service.upsertScore(
          resultSheetId: sheet.id,
          studentId: student.id,
          courseId: sheet.courseId,
          sessionId: sheet.sessionId,
          caScore: ca.clamp(0, 30),
          examScore: exam.clamp(0, 70),
        );
      }
      ref.invalidate(sheetResultsProvider(widget.sheetId));
      if (mounted) AppSnackbar.show(context, 'Scores saved!');
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Error saving: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitSheet(ResultSheetModel sheet) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Submit for Approval',
      message: 'Once submitted, scores cannot be edited until reviewed by the HOD. Continue?',
      confirmLabel: 'Submit',
    );
    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(resultServiceProvider).submitResultSheet(sheet.id);
      ref.invalidate(sheetResultsProvider(widget.sheetId));
      if (mounted) AppSnackbar.show(context, 'Result submitted for approval!');
    } catch (e) {
      if (mounted) AppSnackbar.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetsAsync = ref.watch(allResultSheetsProvider);

    return sheetsAsync.when(
      data: (sheets) {
        final sheet = sheets.firstWhere(
          (s) => s.id == widget.sheetId,
          orElse: () => throw Exception('Sheet not found'),
        );
        final resultsAsync = ref.watch(sheetResultsProvider(widget.sheetId));
        final studentsAsync = ref.watch(
            studentsByLevelProvider(sheet.course?.level ?? 100));

        final isEditable = sheet.status == ResultStatus.draft ||
            sheet.status == ResultStatus.rejected;

        return Scaffold(
          appBar: AppBar(
            title: Text(sheet.course?.courseCode ?? 'Score Entry'),
            actions: [
              if (isEditable)
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => studentsAsync.whenData((students) =>
                          resultsAsync.whenData((results) =>
                              _saveScores(sheet, results, students))),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          body: Column(
            children: [
              // Course info header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sheet.course?.courseTitle ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const Gap(4),
                              Text(
                                '${sheet.course?.level}L | ${sheet.course?.semesterLabel} | ${sheet.course?.creditUnits} Units',
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge.fromStatus(sheet.status.name),
                      ],
                    ),
                    if (!isEditable) ...[
                      const Gap(10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline, size: 16, color: AppColors.warning),
                            Gap(8),
                            Text('Result is locked — not editable',
                                style: TextStyle(
                                    color: AppColors.warning, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Score table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.surfaceVariant,
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                    Expanded(flex: 2, child: Text('CA /30', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Exam /70', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                    Expanded(flex: 1, child: Text('Grade', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                  ],
                ),
              ),

              // Student list
              Expanded(
                child: studentsAsync.when(
                  data: (students) => resultsAsync.when(
                    data: (results) {
                      if (students.isEmpty) {
                        return const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No Students',
                          subtitle: 'No students found for this level.',
                        );
                      }
                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (_, i) {
                          final student = students[i];
                          final existing = results.where(
                              (r) => r.studentId == student.id).firstOrNull;
                          final caCtrl = _getCaCtrl(student.id, existing?.caScore ?? 0);
                          final examCtrl = _getExamCtrl(student.id, existing?.examScore ?? 0);

                          return _ScoreRow(
                            student: student,
                            caCtrl: caCtrl,
                            examCtrl: examCtrl,
                            existingResult: existing,
                            isEditable: isEditable,
                          );
                        },
                      );
                    },
                    loading: () => const LoadingOverlay(message: 'Loading scores...'),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  loading: () => const LoadingOverlay(message: 'Loading students...'),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),

              // Submit button
              if (isEditable)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : () => _submitSheet(sheet),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_outlined),
                    label: const Text('Submit for Approval'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: LoadingOverlay()),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _ScoreRow extends StatefulWidget {
  final StudentModel student;
  final TextEditingController caCtrl;
  final TextEditingController examCtrl;
  final StudentResultModel? existingResult;
  final bool isEditable;

  const _ScoreRow({
    required this.student,
    required this.caCtrl,
    required this.examCtrl,
    required this.existingResult,
    required this.isEditable,
  });

  @override
  State<_ScoreRow> createState() => _ScoreRowState();
}

class _ScoreRowState extends State<_ScoreRow> {
  String _currentGrade = '-';

  @override
  void initState() {
    super.initState();
    _updateGrade();
    widget.caCtrl.addListener(_updateGrade);
    widget.examCtrl.addListener(_updateGrade);
  }

  void _updateGrade() {
    final ca = double.tryParse(widget.caCtrl.text) ?? 0;
    final exam = double.tryParse(widget.examCtrl.text) ?? 0;
    final total = ca + exam;
    String grade;
    if (total >= 70) grade = 'A';
    else if (total >= 60) grade = 'B';
    else if (total >= 50) grade = 'C';
    else if (total >= 45) grade = 'D';
    else if (total >= 40) grade = 'E';
    else grade = total > 0 ? 'F' : '-';
    if (mounted) setState(() => _currentGrade = grade);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student.profile?.fullName ?? 'Unknown';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                Text(widget.student.matricNumber,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                controller: widget.caCtrl,
                enabled: widget.isEditable,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  fillColor: widget.isEditable
                      ? AppColors.surfaceVariant
                      : Colors.grey.shade100,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextFormField(
                controller: widget.examCtrl,
                enabled: widget.isEditable,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '0',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  fillColor: widget.isEditable
                      ? AppColors.surfaceVariant
                      : Colors.grey.shade100,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _currentGrade == '-'
                  ? const Text('-',
                      style: TextStyle(color: AppColors.textHint))
                  : GradeBadge(grade: _currentGrade),
            ),
          ),
        ],
      ),
    );
  }
}
