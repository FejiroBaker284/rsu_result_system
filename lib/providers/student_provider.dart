import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/student_service.dart';
import '../models/student_model.dart';
import 'auth_provider.dart';

final studentServiceProvider = Provider<StudentService>((ref) => StudentService());

final allStudentsProvider = FutureProvider<List<StudentModel>>((ref) async {
  return ref.watch(studentServiceProvider).getAllStudents();
});

final studentsByLevelProvider =
    FutureProvider.family<List<StudentModel>, int>((ref, level) async {
  return ref.watch(studentServiceProvider).getStudentsByLevel(level);
});

final currentStudentProvider = FutureProvider<StudentModel?>((ref) async {
  final profile = ref.watch(authNotifierProvider).value;
  if (profile == null) return null;
  return ref.watch(studentServiceProvider).getStudentByProfileId(profile.id);
});
