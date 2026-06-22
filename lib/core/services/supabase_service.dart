import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ─────────────────────────────────────────
  // PROFILES
  // ─────────────────────────────────────────

  static Future<UserProfile?> getProfile(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return res != null ? UserProfile.fromJson(res) : null;
  }

  static Future<UserProfile> getMyProfile() async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();
    return UserProfile.fromJson(res);
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', currentUser!.id);
  }

  // ─────────────────────────────────────────
  // STUDENTS
  // ─────────────────────────────────────────

  static Future<Student?> getMyStudentRecord() async {
    final res = await _client
        .from('students')
        .select('*, profiles(*)')
        .eq('profile_id', currentUser!.id)
        .maybeSingle();
    return res != null ? Student.fromJson(res) : null;
  }

  static Future<List<Student>> getAllStudents() async {
    final res = await _client
        .from('students')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return (res as List).map((e) => Student.fromJson(e)).toList();
  }

  static Future<List<Student>> getStudentsByLevel(int level) async {
    final res = await _client
        .from('students')
        .select('*, profiles(*)')
        .eq('level', level)
        .order('matric_number');
    return (res as List).map((e) => Student.fromJson(e)).toList();
  }

  static Future<Student> createStudent({
    required String fullName,
    required String email,
    required String matricNumber,
    required int level,
    required String password,
    required String sessionId,
  }) async {
    // Create auth user
    final authRes = await _client.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        userMetadata: {'full_name': fullName, 'role': 'student'},
        emailConfirm: true,
      ),
    );

    final userId = authRes.user!.id;

    // Create student record
    final res = await _client.from('students').insert({
      'profile_id': userId,
      'matric_number': matricNumber,
      'level': level,
      'entry_session_id': sessionId,
    }).select('*, profiles(*)').single();

    return Student.fromJson(res);
  }

  static Future<void> updateStudentLevel(String studentId, int level) async {
    await _client.from('students').update({'level': level}).eq('id', studentId);
  }

  static Future<void> updateStudentStanding(String studentId, String standing) async {
    await _client.from('students').update({'standing': standing}).eq('id', studentId);
  }

  // ─────────────────────────────────────────
  // LECTURERS
  // ─────────────────────────────────────────

  static Future<Lecturer?> getMyLecturerRecord() async {
    final res = await _client
        .from('lecturers')
        .select('*, profiles(*)')
        .eq('profile_id', currentUser!.id)
        .maybeSingle();
    return res != null ? Lecturer.fromJson(res) : null;
  }

  static Future<List<Lecturer>> getAllLecturers() async {
    final res = await _client
        .from('lecturers')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return (res as List).map((e) => Lecturer.fromJson(e)).toList();
  }

  static Future<Lecturer> createLecturer({
    required String fullName,
    required String email,
    required String staffId,
    required String password,
    String? specialization,
  }) async {
    final authRes = await _client.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        userMetadata: {'full_name': fullName, 'role': 'lecturer'},
        emailConfirm: true,
      ),
    );

    final userId = authRes.user!.id;

    final res = await _client.from('lecturers').insert({
      'profile_id': userId,
      'staff_id': staffId,
      'specialization': specialization,
    }).select('*, profiles(*)').single();

    return Lecturer.fromJson(res);
  }

  // ─────────────────────────────────────────
  // COURSES
  // ─────────────────────────────────────────

  static Future<List<Course>> getAllCourses() async {
    final res = await _client.from('courses').select().order('level').order('course_code');
    return (res as List).map((e) => Course.fromJson(e)).toList();
  }

  static Future<List<Course>> getCoursesByLevel(int level, String semester) async {
    final res = await _client
        .from('courses')
        .select()
        .eq('level', level)
        .eq('semester', semester)
        .eq('is_active', true)
        .order('course_code');
    return (res as List).map((e) => Course.fromJson(e)).toList();
  }

  static Future<Course> createCourse(Map<String, dynamic> data) async {
    final res = await _client.from('courses').insert(data).select().single();
    return Course.fromJson(res);
  }

  static Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    await _client.from('courses').update(data).eq('id', courseId);
  }

  // ─────────────────────────────────────────
  // COURSE ASSIGNMENTS
  // ─────────────────────────────────────────

  static Future<List<CourseAssignment>> getLecturerCourses(String lecturerId) async {
    final res = await _client
        .from('course_assignments')
        .select('*, courses(*), lecturers(*, profiles(*))')
        .eq('lecturer_id', lecturerId);
    return (res as List).map((e) => CourseAssignment.fromJson(e)).toList();
  }

  static Future<void> assignCourseToLecturer({
    required String courseId,
    required String lecturerId,
    required String sessionId,
    required String semester,
  }) async {
    await _client.from('course_assignments').upsert({
      'course_id': courseId,
      'lecturer_id': lecturerId,
      'session_id': sessionId,
      'semester': semester,
    });
  }

  // ─────────────────────────────────────────
  // RESULTS
  // ─────────────────────────────────────────

  static Future<List<Result>> getStudentResults(String studentId) async {
    final res = await _client
        .from('results')
        .select('*, courses(*)')
        .eq('student_id', studentId)
        .eq('status', 'published')
        .order('session_id')
        .order('semester');
    return (res as List).map((e) => Result.fromJson(e)).toList();
  }

  static Future<List<Result>> getLecturerResults(String lecturerId) async {
    final res = await _client
        .from('results')
        .select('*, courses(*), students(*, profiles(*))')
        .eq('submitted_by', lecturerId)
        .order('created_at', ascending: false);
    return (res as List).map((e) => Result.fromJson(e)).toList();
  }

  static Future<List<Result>> getAllResultsForAdmin({String? status}) async {
    var query = _client
        .from('results')
        .select('*, courses(*), students(*, profiles(*))');
    if (status != null) {
      query = query.eq('status', status);
    }
    final res = await query.order('created_at', ascending: false);
    return (res as List).map((e) => Result.fromJson(e)).toList();
  }

  static Future<List<Result>> getCourseResults({
    required String courseId,
    required String sessionId,
    required String semester,
  }) async {
    final res = await _client
        .from('results')
        .select('*, courses(*), students(*, profiles(*))')
        .eq('course_id', courseId)
        .eq('session_id', sessionId)
        .eq('semester', semester);
    return (res as List).map((e) => Result.fromJson(e)).toList();
  }

  static Future<void> upsertResult({
    required String studentId,
    required String courseId,
    required String sessionId,
    required String semester,
    required double caScore,
    required double examScore,
    required String lecturerId,
  }) async {
    await _client.from('results').upsert({
      'student_id': studentId,
      'course_id': courseId,
      'session_id': sessionId,
      'semester': semester,
      'ca_score': caScore,
      'exam_score': examScore,
      'submitted_by': lecturerId,
      'status': 'draft',
    }, onConflict: 'student_id,course_id,session_id,semester');
  }

  static Future<void> submitResults(List<String> resultIds, String lecturerId) async {
    await _client.from('results').update({
      'status': 'submitted',
      'submitted_by': lecturerId,
      'submitted_at': DateTime.now().toIso8601String(),
    }).inFilter('id', resultIds);
  }

  static Future<void> approveResults(List<String> resultIds) async {
    await _client.from('results').update({
      'status': 'approved',
      'approved_by': currentUser!.id,
      'approved_at': DateTime.now().toIso8601String(),
    }).inFilter('id', resultIds);
  }

  static Future<void> rejectResults(List<String> resultIds, String reason) async {
    await _client.from('results').update({
      'status': 'rejected',
      'rejection_reason': reason,
    }).inFilter('id', resultIds);
  }

  static Future<void> publishResults(List<String> resultIds) async {
    await _client.from('results').update({
      'status': 'published',
      'published_at': DateTime.now().toIso8601String(),
    }).inFilter('id', resultIds);
  }

  // ─────────────────────────────────────────
  // ACADEMIC SESSIONS
  // ─────────────────────────────────────────

  static Future<List<AcademicSession>> getAllSessions() async {
    final res = await _client.from('academic_sessions').select().order('start_year', ascending: false);
    return (res as List).map((e) => AcademicSession.fromJson(e)).toList();
  }

  static Future<AcademicSession?> getCurrentSession() async {
    final res = await _client
        .from('academic_sessions')
        .select()
        .eq('is_current', true)
        .maybeSingle();
    return res != null ? AcademicSession.fromJson(res) : null;
  }

  static Future<void> createSession(String name, int startYear, int endYear) async {
    // Set all others to not current
    await _client.from('academic_sessions').update({'is_current': false});
    await _client.from('academic_sessions').insert({
      'session_name': name,
      'start_year': startYear,
      'end_year': endYear,
      'is_current': true,
    });
  }

  // ─────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────

  static Future<List<AppNotification>> getMyNotifications() async {
    final res = await _client
        .from('notifications')
        .select()
        .eq('recipient_id', currentUser!.id)
        .order('created_at', ascending: false)
        .limit(20);
    return (res as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  static Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
  }) async {
    await _client.from('notifications').insert({
      'recipient_id': recipientId,
      'title': title,
      'message': message,
    });
  }

  // ─────────────────────────────────────────
  // DASHBOARD STATS (Admin)
  // ─────────────────────────────────────────

  static Future<Map<String, int>> getAdminStats() async {
    final students = await _client
        .from('students')
        .select()
        .count(CountOption.exact);
    final lecturers = await _client
        .from('lecturers')
        .select()
        .count(CountOption.exact);
    final courses = await _client
        .from('courses')
        .select()
        .count(CountOption.exact);
    final pendingResults = await _client
        .from('results')
        .select()
        .eq('status', 'submitted')
        .count(CountOption.exact);

    return {
      'students': students.count,
      'lecturers': lecturers.count,
      'courses': courses.count,
      'pending_results': pendingResults.count,
    };
  }
}