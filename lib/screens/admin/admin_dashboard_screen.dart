import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/result_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../models/result_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).value;
    final studentsAsync = ref.watch(allStudentsProvider);
    final resultsAsync = ref.watch(allResultSheetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        name: profile?.fullName ?? '',
        role: 'Admin',
        email: profile?.email ?? '',
        items: [
          DrawerItem(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            isActive: true,
            onTap: () => Navigator.pop(context),
          ),
          DrawerItem(
            label: 'Manage Students',
            icon: Icons.people_outline,
            onTap: () { Navigator.pop(context); context.push('/admin/students'); },
          ),
          DrawerItem(
            label: 'Manage Lecturers',
            icon: Icons.person_outline,
            onTap: () { Navigator.pop(context); context.push('/admin/lecturers'); },
          ),
          DrawerItem(
            label: 'Manage Courses',
            icon: Icons.book_outlined,
            onTap: () { Navigator.pop(context); context.push('/admin/courses'); },
          ),
          DrawerItem(
            label: 'Result Approval',
            icon: Icons.fact_check_outlined,
            onTap: () { Navigator.pop(context); context.push('/admin/results'); },
          ),
          DrawerItem(
            label: 'Notifications',
            icon: Icons.notifications_outlined,
            onTap: () { Navigator.pop(context); context.push('/admin/notifications'); },
          ),
        ],
        onSignOut: () async {
          await ref.read(authNotifierProvider.notifier).signOut();
        },
      ),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Good ${_greeting()}, ${profile?.fullName.split(' ').first ?? 'Admin'}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const Gap(4),
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
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

                // Stats Grid
                studentsAsync.when(
                  data: (students) => resultsAsync.when(
                    data: (sheets) {
                      final pending = sheets
                          .where((s) => s.status == ResultStatus.submitted)
                          .length;
                      final published = sheets
                          .where((s) => s.status == ResultStatus.published)
                          .length;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          StatCard(
                            label: 'Total Students',
                            value: '${students.length}',
                            icon: Icons.people_outline,
                            color: AppColors.primary,
                            onTap: () => context.push('/admin/students'),
                          ),
                          StatCard(
                            label: 'Pending Approval',
                            value: '$pending',
                            icon: Icons.pending_actions_outlined,
                            color: AppColors.warning,
                            onTap: () => context.push('/admin/results'),
                          ),
                          StatCard(
                            label: 'Published Results',
                            value: '$published',
                            icon: Icons.check_circle_outline,
                            color: AppColors.success,
                            onTap: () => context.push('/admin/results'),
                          ),
                          StatCard(
                            label: 'Total Sheets',
                            value: '${sheets.length}',
                            icon: Icons.description_outlined,
                            color: AppColors.info,
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms);
                    },
                    loading: () => const LoadingOverlay(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  loading: () => const LoadingOverlay(),
                  error: (e, _) => Text('Error: $e'),
                ),

                const Gap(28),

                // Quick Actions
                const SectionHeader(title: 'Quick Actions'),
                const Gap(12),
                _QuickActionsGrid(context: context),

                const Gap(28),

                // Pending Results
                SectionHeader(
                  title: 'Pending Approvals',
                  actionLabel: 'View All',
                  onAction: () => context.push('/admin/results'),
                ),
                const Gap(12),
                resultsAsync.when(
                  data: (sheets) {
                    final pending = sheets
                        .where((s) => s.status == ResultStatus.submitted)
                        .take(5)
                        .toList();
                    if (pending.isEmpty) {
                      return const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'All Caught Up!',
                        subtitle: 'No results pending approval.',
                      );
                    }
                    return Column(
                      children: pending
                          .map((sheet) => _PendingResultTile(
                                sheet: sheet,
                                onTap: () =>
                                    context.push('/admin/results/${sheet.id}'),
                              ))
                          .toList(),
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
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final BuildContext context;
  const _QuickActionsGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.person_add_outlined, 'Add Student', AppColors.primary,
          () => context.push('/admin/students/add')),
      (Icons.group_add_outlined, 'Add Lecturer', AppColors.info,
          () => context.push('/admin/lecturers/add')),
      (Icons.add_box_outlined, 'Add Course', AppColors.success,
          () => context.push('/admin/courses')),
      (Icons.fact_check_outlined, 'Review Results', AppColors.warning,
          () => context.push('/admin/results')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions
          .map((a) => GestureDetector(
                onTap: a.$4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: a.$3.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: a.$3.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(a.$1, color: a.$3, size: 20),
                      const Gap(8),
                      Expanded(
                        child: Text(a.$2,
                            style: TextStyle(
                                color: a.$3,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _PendingResultTile extends StatelessWidget {
  final sheet;
  final VoidCallback onTap;

  const _PendingResultTile({required this.sheet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.pending_actions_outlined,
              color: AppColors.warning, size: 22),
        ),
        title: Text(
          sheet.course?.courseCode ?? 'Unknown Course',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          sheet.course?.courseTitle ?? '',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge.fromStatus(sheet.status.name),
            const Gap(8),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
