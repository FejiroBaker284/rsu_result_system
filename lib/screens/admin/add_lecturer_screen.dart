import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import 'manage_lecturers_screen.dart';

class AddLecturerScreen extends ConsumerStatefulWidget {
  const AddLecturerScreen({super.key});

  @override
  ConsumerState<AddLecturerScreen> createState() => _AddLecturerScreenState();
}

class _AddLecturerScreenState extends ConsumerState<AddLecturerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _staffIdCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.createUser(
        email: _emailCtrl.text.trim(),
        password: 'RSU@Lecturer${_staffIdCtrl.text.trim()}',
        fullName: _nameCtrl.text.trim(),
        role: 'lecturer',
      );

      if (response.user == null) throw Exception('Failed to create user');

      await Supabase.instance.client.from('lecturers').insert({
        'profile_id': response.user!.id,
        'staff_id': _staffIdCtrl.text.trim(),
        'designation': _designationCtrl.text.trim().isEmpty
            ? null
            : _designationCtrl.text.trim(),
      });

      if (mounted) {
        ref.invalidate(allLecturersProvider);
        AppSnackbar.show(context, 'Lecturer added successfully!');
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
      appBar: AppBar(title: const Text('Add Lecturer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Full Name'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Dr. Amara Okafor',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              _label('Staff ID'),
              TextFormField(
                controller: _staffIdCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. RSU/STAFF/0045',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              _label('Email Address'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'lecturer@rsu.edu.ng',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const Gap(16),
              _label('Designation (Optional)'),
              TextFormField(
                controller: _designationCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Senior Lecturer',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const Gap(32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Add Lecturer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary)),
      );
}
