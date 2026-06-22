import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/result_model.dart';

class ResultService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Result Sheets ─────────────────────────────────────

  Future<List<ResultSheetModel>> getResultSheetsByLecturer(String lecturerId) async {
    final data = await _client
        .from('result_sheets')
        .select('*, courses(*)')
        .eq('lecturer_id', lecturerId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ResultSheetModel.fromJson(e)).toList();
  }

  Future<List<ResultSheetModel>> getAllResultSheets() async {
    final data = await _client
        .from('result_sheets')
        .select('*, courses(*)')
        .order('updated_at', ascending: false);
    return (data as List).map((e) => ResultSheetModel.fromJson(e)).toList();
  }

  Future<ResultSheetModel> createOrGetResultSheet({
    required String courseId,
    required String sessionId,
    required String lecturerId,
  }) async {
    // Try to get existing
    final existing = await _client
        .from('result_sheets')
        .select('*, courses(*)')
        .eq('course_id', courseId)
        .eq('session_id', sessionId)
        .maybeSingle();
    if (existing != null) return ResultSheetModel.fromJson(existing);

    // Create new
    final data = await _client.from('result_sheets').insert({
      'course_id': courseId,
      'session_id': sessionId,
      'lecturer_id': lecturerId,
      'status': 'draft',
    }).select('*, courses(*)').single();
    return ResultSheetModel.fromJson(data);
  }

  Future<void> submitResultSheet(String sheetId) async {
    await _client.from('result_sheets').update({
      'status': 'submitted',
      'submitted_at': DateTime.now().toIso8601String(),
    }).eq('id', sheetId);
  }

  Future<void> approveResultSheet(String sheetId) async {
    await _client.from('result_sheets').update({
      'status': 'approved',
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', sheetId);
  }

  Future<void> rejectResultSheet(String sheetId, String reason) async {
    await _client.from('result_sheets').update({
      'status': 'rejected',
      'rejection_reason': reason,
    }).eq('id', sheetId);
  }

  Future<void> publishResultSheet(String sheetId) async {
    await _client.from('result_sheets').update({
      'status': 'published',
      'published_at': DateTime.now().toIso8601String(),
    }).eq('id', sheetId);
  }

  // ── Student Results ───────────────────────────────────

  Future<List<StudentResultModel>> getResultsBySheet(String sheetId) async {
    final data = await _client
        .from('student_results')
        .select('*, students(*, profiles(*)), courses(*)')
        .eq('result_sheet_id', sheetId)
        .order('created_at');
    return (data as List).map((e) => StudentResultModel.fromJson(e)).toList();
  }

  Future<List<StudentResultModel>> getStudentResults({
    required String studentId,
    String? sessionId,
  }) async {
    var query = _client
        .from('student_results')
        .select('*, courses(*)')
        .eq('student_id', studentId);
    if (sessionId != null) query = query.eq('session_id', sessionId);
    final data = await query.order('created_at');
    return (data as List).map((e) => StudentResultModel.fromJson(e)).toList();
  }

  Future<void> upsertScore({
    required String resultSheetId,
    required String studentId,
    required String courseId,
    required String sessionId,
    required double caScore,
    required double examScore,
  }) async {
    await _client.from('student_results').upsert({
      'result_sheet_id': resultSheetId,
      'student_id': studentId,
      'course_id': courseId,
      'session_id': sessionId,
      'ca_score': caScore,
      'exam_score': examScore,
    }, onConflict: 'result_sheet_id,student_id');
  }

  // ── GPA ───────────────────────────────────────────────

  Future<List<SemesterGpaModel>> getStudentGpa(String studentId) async {
    final data = await _client
        .from('semester_gpa')
        .select()
        .eq('student_id', studentId)
        .order('computed_at');
    return (data as List).map((e) => SemesterGpaModel.fromJson(e)).toList();
  }

  Future<void> computeAndSaveGpa({
    required String studentId,
    required String sessionId,
    required String semester,
    required List<StudentResultModel> results,
    required List<int> creditUnits,
  }) async {
    int totalCredits = 0;
    double totalQP = 0;
    for (int i = 0; i < results.length; i++) {
      totalCredits += creditUnits[i];
      totalQP += results[i].gradePoint * creditUnits[i];
    }
    final gpa = totalCredits > 0 ? totalQP / totalCredits : 0.0;
    await _client.from('semester_gpa').upsert({
      'student_id': studentId,
      'session_id': sessionId,
      'semester': semester,
      'total_credit_units': totalCredits,
      'total_quality_points': totalQP,
      'gpa': gpa,
      'computed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id,session_id,semester');
  }
}
