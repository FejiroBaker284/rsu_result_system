import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/student_model.dart';

class StudentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<StudentModel>> getAllStudents() async {
    final data = await _client
        .from('students')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => StudentModel.fromJson(e)).toList();
  }

  Future<List<StudentModel>> getStudentsByLevel(int level) async {
    final data = await _client
        .from('students')
        .select('*, profiles(*)')
        .eq('level', level)
        .order('matric_number');
    return (data as List).map((e) => StudentModel.fromJson(e)).toList();
  }

  Future<StudentModel?> getStudentByProfileId(String profileId) async {
    final data = await _client
        .from('students')
        .select('*, profiles(*)')
        .eq('profile_id', profileId)
        .maybeSingle();
    if (data == null) return null;
    return StudentModel.fromJson(data);
  }

  Future<StudentModel> createStudent({
    required String profileId,
    required String matricNumber,
    required int level,
    required String entrySessionId,
  }) async {
    final data = await _client.from('students').insert({
      'profile_id': profileId,
      'matric_number': matricNumber,
      'level': level,
      'entry_session_id': entrySessionId,
    }).select('*, profiles(*)').single();
    return StudentModel.fromJson(data);
  }

  Future<void> updateStudentLevel(String studentId, int newLevel) async {
    await _client
        .from('students')
        .update({'level': newLevel})
        .eq('id', studentId);
  }

  Future<void> deleteStudent(String studentId) async {
    await _client.from('students').delete().eq('id', studentId);
  }
}
