import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/result_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common_widgets.dart';

class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Results')),
      body: studentAsync.when(
        data: (student) {
          if (student == null) {
            return const Center(child: Text('Student record not found.'));
          }
          final resultsAsync = ref.watch(studentResultsProvider(student.id));
          return resultsAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No Results Available',
                  subtitle: 'Your results will appear here once published by the department.',
                );
              }

              // Group by session
              final grouped = <String, List<dynamic>>{};
              for (final r in results) {
                grouped.putIfAbsent(r.sessionId, () => []).add(r);
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: grouped.entries.map((entry) {
                  final sessionResults = entry.value;
                  double totalQP = 0;
                  int totalUnits = 0;
                  for (final r in sessionResults) {
                    final units = r.course?.creditUnits ?? 0;
                    totalQP += r.gradePoint * units;
                    totalUnits += units as int;
                  }
                  final gpa = totalUnits > 0 ? totalQP / totalUnits : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session header
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                            const Gap(8),
                            const Text('Session', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const Spacer(),
                            Text('GPA: ${gpa.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                      const Gap(8),

                      // Results table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text('Course', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                            Expanded(flex: 1, child: Text('CA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('Exam', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center)),
                            Expanded(flex: 1, child: Text('Grade', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      const Gap(4),

                      ...sessionResults.map((r) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.course?.courseCode ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                  Text(r.course?.courseTitle ?? '',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Expanded(flex: 1, child: Text('${r.caScore.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                            Expanded(flex: 1, child: Text('${r.examScore.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                            Expanded(flex: 1, child: Text('${r.totalScore.toInt()}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                            Expanded(
                              flex: 1,
                              child: Center(child: GradeBadge(grade: r.grade)),
                            ),
                          ],
                        ),
                      )),
                      const Gap(20),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingOverlay(message: 'Loading results...'),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
