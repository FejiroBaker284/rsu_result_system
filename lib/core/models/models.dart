// ============================================================
// ALL DATA MODELS
// ============================================================

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'admin' | 'lecturer' | 'student'
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    fullName: json['full_name'],
    email: json['email'],
    role: json['role'],
    phone: json['phone'],
    avatarUrl: json['avatar_url'],
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'role': role,
    'phone': phone,
    'avatar_url': avatarUrl,
    'is_active': isActive,
  };
}

// ─────────────────────────────────────────

class Student {
  final String id;
  final String profileId;
  final String matricNumber;
  final int level;
  final String? entrySessionId;
  final String standing;
  final UserProfile? profile;

  Student({
    required this.id,
    required this.profileId,
    required this.matricNumber,
    required this.level,
    this.entrySessionId,
    required this.standing,
    this.profile,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'],
    profileId: json['profile_id'],
    matricNumber: json['matric_number'],
    level: json['level'],
    entrySessionId: json['entry_session_id'],
    standing: json['standing'] ?? 'good_standing',
    profile: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
  );

  String get fullName => profile?.fullName ?? 'Unknown';
  String get email => profile?.email ?? '';
}

// ─────────────────────────────────────────

class Lecturer {
  final String id;
  final String profileId;
  final String staffId;
  final String? specialization;
  final UserProfile? profile;

  Lecturer({
    required this.id,
    required this.profileId,
    required this.staffId,
    this.specialization,
    this.profile,
  });

  factory Lecturer.fromJson(Map<String, dynamic> json) => Lecturer(
    id: json['id'],
    profileId: json['profile_id'],
    staffId: json['staff_id'],
    specialization: json['specialization'],
    profile: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
  );

  String get fullName => profile?.fullName ?? 'Unknown';
  String get email => profile?.email ?? '';
}

// ─────────────────────────────────────────

class Course {
  final String id;
  final String courseCode;
  final String courseTitle;
  final int creditUnits;
  final int level;
  final String semester;
  final bool isActive;

  Course({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.level,
    required this.semester,
    required this.isActive,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'],
    courseCode: json['course_code'],
    courseTitle: json['course_title'],
    creditUnits: json['credit_units'],
    level: json['level'],
    semester: json['semester'],
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'course_code': courseCode,
    'course_title': courseTitle,
    'credit_units': creditUnits,
    'level': level,
    'semester': semester,
    'is_active': isActive,
  };
}

// ─────────────────────────────────────────

class AcademicSession {
  final String id;
  final String sessionName;
  final int startYear;
  final int endYear;
  final bool isCurrent;

  AcademicSession({
    required this.id,
    required this.sessionName,
    required this.startYear,
    required this.endYear,
    required this.isCurrent,
  });

  factory AcademicSession.fromJson(Map<String, dynamic> json) => AcademicSession(
    id: json['id'],
    sessionName: json['session_name'],
    startYear: json['start_year'],
    endYear: json['end_year'],
    isCurrent: json['is_current'] ?? false,
  );
}

// ─────────────────────────────────────────

class Result {
  final String id;
  final String studentId;
  final String courseId;
  final String sessionId;
  final String semester;
  final double? caScore;
  final double? examScore;
  final double? totalScore;
  final String? grade;
  final double? gradePoint;
  final String status;
  final String? rejectionReason;
  final String? submittedBy;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? publishedAt;

  // Joined data
  final Course? course;
  final Student? student;

  Result({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.sessionId,
    required this.semester,
    this.caScore,
    this.examScore,
    this.totalScore,
    this.grade,
    this.gradePoint,
    required this.status,
    this.rejectionReason,
    this.submittedBy,
    this.submittedAt,
    this.approvedAt,
    this.publishedAt,
    this.course,
    this.student,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json['id'],
    studentId: json['student_id'],
    courseId: json['course_id'],
    sessionId: json['session_id'],
    semester: json['semester'],
    caScore: json['ca_score'] != null ? (json['ca_score'] as num).toDouble() : null,
    examScore: json['exam_score'] != null ? (json['exam_score'] as num).toDouble() : null,
    totalScore: json['total_score'] != null ? (json['total_score'] as num).toDouble() : null,
    grade: json['grade'],
    gradePoint: json['grade_point'] != null ? (json['grade_point'] as num).toDouble() : null,
    status: json['status'] ?? 'draft',
    rejectionReason: json['rejection_reason'],
    submittedBy: json['submitted_by'],
    submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
    approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
    publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
    course: json['courses'] != null ? Course.fromJson(json['courses']) : null,
    student: json['students'] != null ? Student.fromJson(json['students']) : null,
  );
}

// ─────────────────────────────────────────

class SemesterResult {
  final String sessionName;
  final String semester;
  final List<Result> results;
  final double gpa;
  final int totalUnits;
  final int totalPoints;

  SemesterResult({
    required this.sessionName,
    required this.semester,
    required this.results,
    required this.gpa,
    required this.totalUnits,
    required this.totalPoints,
  });
}

// ─────────────────────────────────────────

class AppNotification {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'],
    recipientId: json['recipient_id'],
    title: json['title'],
    message: json['message'],
    isRead: json['is_read'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
  );
}

// ─────────────────────────────────────────

class CourseAssignment {
  final String id;
  final String courseId;
  final String lecturerId;
  final String sessionId;
  final String semester;
  final Course? course;
  final Lecturer? lecturer;

  CourseAssignment({
    required this.id,
    required this.courseId,
    required this.lecturerId,
    required this.sessionId,
    required this.semester,
    this.course,
    this.lecturer,
  });

  factory CourseAssignment.fromJson(Map<String, dynamic> json) => CourseAssignment(
    id: json['id'],
    courseId: json['course_id'],
    lecturerId: json['lecturer_id'],
    sessionId: json['session_id'],
    semester: json['semester'],
    course: json['courses'] != null ? Course.fromJson(json['courses']) : null,
    lecturer: json['lecturers'] != null ? Lecturer.fromJson(json['lecturers']) : null,
  );
}
