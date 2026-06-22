import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lecturer_model.dart';
import '../../models/result_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/result_provider.dart';
import '../../widgets/common_widgets.dart';

final currentLecturerProvider = FutureProvider<LecturerModel?>((ref) async {
  final profile = ref.watch(authNotifierProvider).value;
  if (profile == null) return null;
  final data = await Supabase.instance.client
      .from('lecturers')
      .select('*, profiles(*)')
      .eq('profile_id', profile.id)
      .maybeSingle();
  if (data == null) return null;
  return LecturerModel.fromJson(data);
});

class LecturerDashboardScreen extends ConsumerWidget {
  const LecturerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).value;
    final lecturerAsync = ref.watch(currentLecturerProvider);

    return lecturerAsync.when(
      data: (lecturer) {
        if (lecturer == null) {
          return const Scaffold(
            body: Center(child: Text('Lecturer profile not found.')),
          );
        }

        final sheetsAsync = ref.watch(lecturerResultSheetsProvider(lecturer.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: AppDrawer(
            name: profile?.fullName ?? '',
            role: 'Lecturer',
            email: profile?.email ?? '',
            items: [
              DrawerItem(
                label: 'Dashboard',
                icon: Icons.dashboard_outlined,
                isActive: true,
                onTap: () => Navigator.pop(context),
              ),
              DrawerItem(
                label: 'Notifications',
                icon: Icons.notifications_outlined,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/lecturer/notifications');
                },
              ),
            ],
            onSignOut: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
          body: CustomScrollView(
            slivers: [
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
                          'Welcome, ${profile?.fullName.split(' ').first ?? ''}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const Gap(4),
                        Text(
                          lecturer.designation ?? 'Lecturer',
                          style: const TextStyle(
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
                    // Stats
                    sheetsAsync.when(
                      data: (sheets) {
                        final draft = sheets.where((s) => s.status == ResultStatus.draft).length;
                        final submitted = sheets.where((s) => s.status == ResultStatus.submitted).length;
                        final published = sheets.where((s) => s.status == ResultStatus.published).length;
                        return Row(
                          children: [
                            Expanded(child: StatCard(
                              label: 'Draft', value: '$draft',
                              icon: Icons.edit_outlined, color: AppColors.textSecondary,
                            )),
                            const Gap(12),
                            Expanded(child: StatCard(
                              label: 'Submitted', value: '$submitted',
                              icon: Icons.send_outlined, color: AppColors.info,
                            )),
                            const Gap(12),
                            Expanded(child: StatCard(
                              label: 'Published', value: '$published',
                              icon: Icons.check_circle_outline, color: AppColors.success,
                            )),
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 80, child: LoadingOverlay()),
                      error: (e, _) => const SizedBox(),
                    ),
                    const Gap(28),

                    const SectionHeader(title: 'My Assigned Courses'),
                    const Gap(12),

                    sheetsAsync.when(
                      data: (sheets) {
                        if (sheets.isEmpty) {
                          return const EmptyState(
                            icon: Icons.book_outlined,
                            title: 'No Courses Assigned',
                            subtitle: 'Contact the admin to get courses assigned.',
                          );
                        }
                        return Column(
                          children: sheets
                              .map((sheet) => _CourseSheetTile(
                                    sheet: sheet,
                                    onTap: () => context.push('/lecturer/scores/${sheet.id}'),
                                  ))
                              .toList(),
                        );
                      },
                      loading: () => const LoadingOverlay(message: 'Loading courses...'),
                      error: (e, _) => Text('Error: $e'),
                    ),
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

class _CourseSheetTile extends StatelessWidget {
  final ResultSheetModel sheet;
  final VoidCallback onTap;

  const _CourseSheetTile({required this.sheet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRejected = sheet.status == ResultStatus.rejected;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 22),
        ),
        title: Text(
          sheet.course?.courseCode ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(2),
            Text(sheet.course?.courseTitle ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            if (isRejected) ...[
              const Gap(4),
              const Text('⚠ Rejected — tap to review and resubmit',
                  style: TextStyle(fontSize: 11, color: AppColors.error)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge.fromStatus(sheet.status.name),
            const Gap(6),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
        onTap: sheet.status == ResultStatus.published ? null : onTap,
      ),
    );
  }
}
