import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/student_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common_widgets.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key});

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _selectedLevel = 100;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _matricCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Create auth user
      final authService = ref.read(authServiceProvider);
      final response = await authService.createUser(
        email: _emailCtrl.text.trim(),
        password: 'RSU@${_matricCtrl.text.trim()}', // default password
        fullName: _nameCtrl.text.trim(),
        role: 'student',
      );

      if (response.user == null) throw Exception('Failed to create user');

      // 2. Get current session ID
      final supabase = ref.read(authServiceProvider);
      // 3. Create student record
      final studentService = ref.read(studentServiceProvider);
      await studentService.createStudent(
        profileId: response.user!.id,
        matricNumber: _matricCtrl.text.trim(),
        level: _selectedLevel,
        entrySessionId: '', // Will be set from current session
      );

      if (mounted) {
        ref.invalidate(allStudentsProvider);
        AppSnackbar.show(context, 'Student added successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, 'Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'Default password: RSU@<matric_number>. Student should change on first login.',
                        style: TextStyle(
                            color: AppColors.info, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              _buildLabel('Full Name'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. John Doe',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const Gap(16),

              _buildLabel('Matric Number'),
              TextFormField(
                controller: _matricCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. RSU/2021/CE/001',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const Gap(16),

              _buildLabel('Email Address'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'student@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const Gap(16),

              _buildLabel('Phone Number (Optional)'),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '08012345678',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const Gap(16),

              _buildLabel('Level'),
              DropdownButtonFormField<int>(
                value: _selectedLevel,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: [100, 200, 300, 400, 500]
                    .map((l) => DropdownMenuItem(
                          value: l,
                          child: Text('$l Level'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedLevel = v!),
              ),
              const Gap(32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Add Student'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary)),
    );
  }
}
