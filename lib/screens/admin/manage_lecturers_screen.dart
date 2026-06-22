import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/student_service.dart';
import '../../widgets/common_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lecturer_model.dart';

final allLecturersProvider = FutureProvider<List<LecturerModel>>((ref) async {
  final data = await Supabase.instance.client
      .from('lecturers')
      .select('*, profiles(*)')
      .order('created_at', ascending: false);
  return (data as List).map((e) => LecturerModel.fromJson(e)).toList();
});

class ManageLecturersScreen extends ConsumerStatefulWidget {
  const ManageLecturersScreen({super.key});

  @override
  ConsumerState<ManageLecturersScreen> createState() => _ManageLecturersScreenState();
}

class _ManageLecturersScreenState extends ConsumerState<ManageLecturersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final lecturersAsync = ref.watch(allLecturersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Lecturers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => context.push('/admin/lecturers/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by name or staff ID...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: lecturersAsync.when(
              data: (lecturers) {
                final filtered = lecturers.where((l) {
                  if (_search.isEmpty) return true;
                  return (l.profile?.fullName.toLowerCase().contains(_search) ?? false) ||
                      l.staffId.toLowerCase().contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.person_outline,
                    title: 'No Lecturers Found',
                    subtitle: 'Add a lecturer to get started.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final l = filtered[i];
                    final name = l.profile?.fullName ?? 'Unknown';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.info.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: AppColors.info,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(l.staffId,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        trailing: l.designation != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(l.designation!,
                                    style: const TextStyle(
                                        color: AppColors.info,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingOverlay(message: 'Loading lecturers...'),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
