import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/pdf_service.dart';
import '../../providers/student_provider.dart';
import '../../providers/result_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class TranscriptScreen extends ConsumerWidget {
  const TranscriptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).value;
    final studentAsync = ref.watch(currentStudentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Transcript'),
        actions: [
          studentAsync.when(
            data: (student) => student != null
                ? IconButton(
                    icon: const Icon(Icons.download_outlined),
                    onPressed: () {
                      if (kIsWeb) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'PDF download is not supported on web. Please use the mobile app.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        _downloadPdf(context, ref, student, profile);
                      }
                    },
                    tooltip: 'Download PDF',
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: studentAsync.when(
        data: (student) {
          if (student == null) return const Center(child: Text('Student not found.'));
          final resultsAsync = ref.watch(studentResultsProvider(student.id));
          final gpaAsync = ref.watch(studentGpaProvider(student.id));

          return resultsAsync.when(
            data: (results) => gpaAsync.when(
              data: (gpaList) {
                double totalQP =
                    gpaList.fold(0.0, (s, g) => s + g.totalQualityPoints);
                int totalUnits =
                    gpaList.fold(0, (s, g) => s + g.totalCreditUnits);
                double cgpa = totalUnits > 0 ? totalQP / totalUnits : 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.school_outlined,
                                    color: AppColors.accent, size: 28),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(AppConstants.university,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14)),
                                      const Text(
                                          'Department of Computer Engineering',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Gap(16),
                            const Divider(color: Colors.white24),
                            const Gap(12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Student Name',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10)),
                                      Text(profile?.fullName ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Matric Number',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10)),
                                      Text(student.matricNumber,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Gap(12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Current Level',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10)),
                                      Text('${student.level} Level',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('CGPA',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10)),
                                      Row(
                                        children: [
                                          Text(cgpa.toStringAsFixed(2),
                                              style: const TextStyle(
                                                  color: AppColors.accent,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 20)),
                                          const Gap(6),
                                          Text(
                                              AppConstants.getAcademicStanding(
                                                  cgpa),
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Gap(20),

                      // Results
                      if (results.isEmpty)
                        const EmptyState(
                          icon: Icons.description_outlined,
                          title: 'No Results',
                          subtitle: 'No published results found.',
                        )
                      else ...[
                        const Text('Academic Record',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const Gap(12),
                        ...results.map((r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(r.course?.courseCode ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13)),
                                          const Gap(2),
                                          Text(r.course?.courseTitle ?? '',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors
                                                      .textSecondary)),
                                          const Gap(2),
                                          Text(
                                              '${r.course?.creditUnits ?? 0} Units | CA: ${r.caScore.toInt()} | Exam: ${r.examScore.toInt()} | Total: ${r.totalScore.toInt()}',
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textHint)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        GradeBadge(grade: r.grade),
                                        const Gap(4),
                                        Text(
                                            '${r.gradePoint.toStringAsFixed(1)} GP',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const LoadingOverlay(),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
            loading: () =>
                const LoadingOverlay(message: 'Loading transcript...'),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const LoadingOverlay(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _downloadPdf(
      BuildContext context, WidgetRef ref, student, profile) async {
    final results =
        await ref.read(studentResultsProvider(student.id).future);
    final gpaList =
        await ref.read(studentGpaProvider(student.id).future);

    double totalQP =
        gpaList.fold(0.0, (s, g) => s + g.totalQualityPoints);
    int totalUnits = gpaList.fold(0, (s, g) => s + g.totalCreditUnits);
    double cgpa = totalUnits > 0 ? totalQP / totalUnits : 0;

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context ctx) => [
        pw.Header(
          level: 0,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(AppConstants.university,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Department of ${AppConstants.department}',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text('ACADEMIC TRANSCRIPT',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
            ],
          ),
        ),
        pw.Row(children: [
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Text('Name: ${profile?.fullName ?? ''}'),
                pw.Text('Matric No: ${student.matricNumber}'),
              ])),
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Text('Level: ${student.level}'),
                pw.Text(
                    'CGPA: ${cgpa.toStringAsFixed(2)} (${AppConstants.getAcademicStanding(cgpa)})'),
              ])),
        ]),
        pw.SizedBox(height: 16),
        pw.TableHelper.fromTextArray(
          headers: [
            'Course Code',
            'Course Title',
            'Units',
            'CA',
            'Exam',
            'Total',
            'Grade',
            'GP'
          ],
          data: results
              .map((r) => [
                    r.course?.courseCode ?? '',
                    r.course?.courseTitle ?? '',
                    '${r.course?.creditUnits ?? 0}',
                    '${r.caScore.toInt()}',
                    '${r.examScore.toInt()}',
                    '${r.totalScore.toInt()}',
                    r.grade,
                    r.gradePoint.toStringAsFixed(1),
                  ])
              .toList(),
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          border: pw.TableBorder.all(width: 0.5),
          cellPadding: const pw.EdgeInsets.all(4),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
            'Generated: ${DateTime.now().toString().split('.')[0]}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey)),
      ],
    ));

    await printTranscript(pdf);
  }
}