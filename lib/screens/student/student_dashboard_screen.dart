import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/result_provider.dart';
import '../../widgets/common_widgets.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).value;
    final studentAsync = ref.watch(currentStudentProvider);

    return studentAsync.when(
      data: (student) {
        if (student == null) {
          return const Scaffold(
            body: Center(child: Text('Student record not found.')),
          );
        }

        final gpaAsync = ref.watch(studentGpaProvider(student.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: AppDrawer(
            name: profile?.fullName ?? '',
            role: 'Student',
            email: profile?.email ?? '',
            items: [
              DrawerItem(
                label: 'Dashboard',
                icon: Icons.dashboard_outlined,
                isActive: true,
                onTap: () => Navigator.pop(context),
              ),
              DrawerItem(
                label: 'My Results',
                icon: Icons.assignment_outlined,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/student/results');
                },
              ),
              DrawerItem(
                label: 'Transcript',
                icon: Icons.description_outlined,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/student/transcript');
                },
              ),
              DrawerItem(
                label: 'Notifications',
                icon: Icons.notifications_outlined,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/student/notifications');
                },
              ),
            ],
            onSignOut: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.accent,
                              child: Text(
                                (profile?.fullName.isNotEmpty == true)
                                    ? profile!.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const Gap(14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?.fullName ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const Gap(2),
                                  Text(
                                    student.matricNumber,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            _InfoChip(label: '${student.level} Level'),
                            const Gap(8),
                            _InfoChip(label: AppConstants.department),
                            const Gap(8),
                            _InfoChip(label: student.standingLabel),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // CGPA Card
                    gpaAsync.when(
                      data: (gpaList) {
                        double cgpa = 0;
                        if (gpaList.isNotEmpty) {
                          double totalQP = gpaList.fold(0.0, (s, g) => s + g.totalQualityPoints);
                          int totalUnits = gpaList.fold(0, (s, g) => s + g.totalCreditUnits);
                          cgpa = totalUnits > 0 ? totalQP / totalUnits : 0;
                        }
                        final standing = AppConstants.getAcademicStanding(cgpa);
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cumulative GPA',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 12)),
                                    const Gap(4),
                                    Text(
                                      cgpa.toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    Text(standing,
                                        style: const TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text('${gpaList.length}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800)),
                                  const Text('Semesters',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms);
                      },
                      loading: () => Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const LoadingOverlay(),
                      ),
                      error: (e, _) => const SizedBox(),
                    ),

                    const Gap(24),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.assignment_outlined,
                            label: 'View Results',
                            color: AppColors.primary,
                            onTap: () => context.push('/student/results'),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.description_outlined,
                            label: 'Transcript',
                            color: AppColors.success,
                            onTap: () => context.push('/student/transcript'),
                          ),
                        ),
                      ],
                    ),

                    const Gap(24),

                    // GPA Per Semester
                    const SectionHeader(title: 'GPA Per Semester'),
                    const Gap(12),
                    gpaAsync.when(
                      data: (gpaList) {
                        if (gpaList.isEmpty) {
                          return const EmptyState(
                            icon: Icons.bar_chart_outlined,
                            title: 'No Results Yet',
                            subtitle: 'Your GPA will appear here once results are published.',
                          );
                        }
                        return Column(
                          children: gpaList.map((g) => _GpaTile(gpa: g)).toList(),
                        );
                      },
                      loading: () => const LoadingOverlay(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const Gap(20),
                  ]),
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

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const Gap(8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _GpaTile extends StatelessWidget {
  final gpa;
  const _GpaTile({required this.gpa});

  @override
  Widget build(BuildContext context) {
    final semLabel = gpa.semester == 'first' ? 'First Semester' : 'Second Semester';
    final gpaValue = (gpa.gpa as num).toDouble();
    final color = gpaValue >= 3.5
        ? AppColors.success
        : gpaValue >= 2.5
            ? AppColors.primary
            : gpaValue >= 1.5
                ? AppColors.warning
                : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  gpaValue.toStringAsFixed(1),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(semLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const Gap(2),
                  Text('${gpa.totalCreditUnits} units · ${gpa.totalQualityPoints.toStringAsFixed(1)} quality points',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
