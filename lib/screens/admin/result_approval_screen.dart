import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../models/result_model.dart';
import '../../providers/result_provider.dart';
import '../../core/services/result_service.dart';
import '../../widgets/common_widgets.dart';

class ResultApprovalScreen extends ConsumerStatefulWidget {
  final String? sheetId;
  const ResultApprovalScreen({super.key, this.sheetId});

  @override
  ConsumerState<ResultApprovalScreen> createState() => _ResultApprovalScreenState();
}

class _ResultApprovalScreenState extends ConsumerState<ResultApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _statuses = ['submitted', 'approved', 'rejected', 'published'];
  final _statusLabels = ['Pending', 'Approved', 'Rejected', 'Published'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetsAsync = ref.watch(allResultSheetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Approval'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.accent,
          tabs: _statusLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: sheetsAsync.when(
        data: (sheets) => TabBarView(
          controller: _tabController,
          children: _statuses.map((status) {
            final filtered =
                sheets.where((s) => s.status.name == status).toList();
            if (filtered.isEmpty) {
              return EmptyState(
                icon: _statusIcon(status),
                title: 'No ${_statusLabels[_statuses.indexOf(status)]} Results',
                subtitle: 'Nothing to show here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _SheetCard(
                sheet: filtered[i],
                onAction: () {
                  ref.invalidate(allResultSheetsProvider);
                },
              ),
            );
          }).toList(),
        ),
        loading: () => const LoadingOverlay(message: 'Loading result sheets...'),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'submitted': return Icons.pending_actions_outlined;
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.publish_outlined;
    }
  }
}

class _SheetCard extends ConsumerWidget {
  final ResultSheetModel sheet;
  final VoidCallback onAction;

  const _SheetCard({required this.sheet, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultService = ref.read(resultServiceProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
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
                        sheet.course?.courseCode ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary),
                      ),
                      const Gap(2),
                      Text(
                        sheet.course?.courseTitle ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                StatusBadge.fromStatus(sheet.status.name),
              ],
            ),

            if (sheet.status == ResultStatus.rejected &&
                sheet.rejectionReason != null) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.error, size: 16),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'Reason: ${sheet.rejectionReason}',
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (sheet.status == ResultStatus.submitted) ...[
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _reject(context, ref, resultService),
                      icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                      label: const Text('Reject',
                          style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await resultService.approveResultSheet(sheet.id);
                        onAction();
                        if (context.mounted) {
                          AppSnackbar.show(context, 'Result approved!');
                        }
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 42),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (sheet.status == ResultStatus.approved) ...[
              const Gap(16),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showConfirmDialog(
                    context,
                    title: 'Publish Result',
                    message:
                        'Students will be able to see this result. Continue?',
                    confirmLabel: 'Publish',
                  );
                  if (confirm == true) {
                    await resultService.publishResultSheet(sheet.id);
                    onAction();
                    if (context.mounted) {
                      AppSnackbar.show(context, 'Result published!');
                    }
                  }
                },
                icon: const Icon(Icons.publish, size: 16),
                label: const Text('Publish to Students'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 42),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, ResultService service) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const Gap(12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonCtrl.text.isNotEmpty) {
      await service.rejectResultSheet(sheet.id, reasonCtrl.text.trim());
      onAction();
      if (context.mounted) {
        AppSnackbar.show(context, 'Result rejected.', isError: true);
      }
    }
  }
}
