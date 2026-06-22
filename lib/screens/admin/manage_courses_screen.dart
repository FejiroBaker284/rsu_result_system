import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/course_model.dart';
import '../../widgets/common_widgets.dart';

final allCoursesProvider = FutureProvider<List<CourseModel>>((ref) async {
  final data = await Supabase.instance.client
      .from('courses')
      .select()
      .order('level')
      .order('semester')
      .order('course_code');
  return (data as List).map((e) => CourseModel.fromJson(e)).toList();
});

class ManageCoursesScreen extends ConsumerStatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  ConsumerState<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends ConsumerState<ManageCoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _levels = [100, 200, 300, 400, 500];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: _levels.map((l) => Tab(text: '${l}L')).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCourseDialog(context),
          ),
        ],
      ),
      body: coursesAsync.when(
        data: (courses) => TabBarView(
          controller: _tabController,
          children: _levels.map((level) {
            final levelCourses =
                courses.where((c) => c.level == level).toList();
            if (levelCourses.isEmpty) {
              return const EmptyState(
                icon: Icons.book_outlined,
                title: 'No Courses',
                subtitle: 'No courses set up for this level.',
              );
            }

            final firstSem = levelCourses
                .where((c) => c.semester == SemesterType.first)
                .toList();
            final secondSem = levelCourses
                .where((c) => c.semester == SemesterType.second)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (firstSem.isNotEmpty) ...[
                  _semesterHeader('First Semester'),
                  ...firstSem.map((c) => _CourseTile(course: c)),
                  const Gap(16),
                ],
                if (secondSem.isNotEmpty) ...[
                  _semesterHeader('Second Semester'),
                  ...secondSem.map((c) => _CourseTile(course: c)),
                ],
              ],
            );
          }).toList(),
        ),
        loading: () => const LoadingOverlay(message: 'Loading courses...'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _semesterHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(8),
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    int units = 3;
    int level = 100;
    SemesterType semester = SemesterType.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Course Code'),
                ),
                const Gap(12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Course Title'),
                ),
                const Gap(12),
                DropdownButtonFormField<int>(
                  value: level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: [100, 200, 300, 400, 500]
                      .map((l) => DropdownMenuItem(value: l, child: Text('$l Level')))
                      .toList(),
                  onChanged: (v) => setS(() => level = v!),
                ),
                const Gap(12),
                DropdownButtonFormField<SemesterType>(
                  value: semester,
                  decoration: const InputDecoration(labelText: 'Semester'),
                  items: [
                    const DropdownMenuItem(
                        value: SemesterType.first, child: Text('First Semester')),
                    const DropdownMenuItem(
                        value: SemesterType.second, child: Text('Second Semester')),
                  ],
                  onChanged: (v) => setS(() => semester = v!),
                ),
                const Gap(12),
                DropdownButtonFormField<int>(
                  value: units,
                  decoration: const InputDecoration(labelText: 'Credit Units'),
                  items: [1, 2, 3, 4, 5, 6]
                      .map((u) => DropdownMenuItem(value: u, child: Text('$u Units')))
                      .toList(),
                  onChanged: (v) => setS(() => units = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty || titleCtrl.text.isEmpty) return;
                try {
                  await Supabase.instance.client.from('courses').insert({
                    'course_code': codeCtrl.text.trim(),
                    'course_title': titleCtrl.text.trim(),
                    'credit_units': units,
                    'level': level,
                    'semester': semester.name,
                  });
                  if (context.mounted) {
                    ref.invalidate(allCoursesProvider);
                    Navigator.pop(ctx);
                    AppSnackbar.show(context, 'Course added!');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackbar.show(context, 'Error: $e', isError: true);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final CourseModel course;
  const _CourseTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${course.creditUnits}U',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12),
          ),
        ),
        title: Text(course.courseCode,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text(course.courseTitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: course.isActive
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            course.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
                color: course.isActive ? AppColors.success : AppColors.error,
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
