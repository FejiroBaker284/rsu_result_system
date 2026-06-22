import 'package:equatable/equatable.dart';
import 'course_model.dart';
import 'student_model.dart';

enum ResultStatus { draft, submitted, approved, rejected, published }

class ResultSheetModel extends Equatable {
  final String id;
  final String courseId;
  final String sessionId;
  final String lecturerId;
  final ResultStatus status;
  final String? rejectionReason;
  final CourseModel? course;

  const ResultSheetModel({
    required this.id,
    required this.courseId,
    required this.sessionId,
    required this.lecturerId,
    required this.status,
    this.rejectionReason,
    this.course,
  });

  factory ResultSheetModel.fromJson(Map<String, dynamic> json) {
    return ResultSheetModel(
      id: json['id'],
      courseId: json['course_id'],
      sessionId: json['session_id'],
      lecturerId: json['lecturer_id'],
      status: ResultStatus.values.firstWhere((e) => e.name == json['status']),
      rejectionReason: json['rejection_reason'],
      course: json['courses'] != null ? CourseModel.fromJson(json['courses']) : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case ResultStatus.draft: return 'Draft';
      case ResultStatus.submitted: return 'Submitted';
      case ResultStatus.approved: return 'Approved';
      case ResultStatus.rejected: return 'Rejected';
      case ResultStatus.published: return 'Published';
    }
  }

  @override
  List<Object?> get props => [id, courseId, sessionId, status];
}

class StudentResultModel extends Equatable {
  final String id;
  final String resultSheetId;
  final String studentId;
  final String courseId;
  final String sessionId;
  final double caScore;
  final double examScore;
  final double totalScore;
  final String grade;
  final double gradePoint;
  final StudentModel? student;
  final CourseModel? course;

  const StudentResultModel({
    required this.id,
    required this.resultSheetId,
    required this.studentId,
    required this.courseId,
    required this.sessionId,
    required this.caScore,
    required this.examScore,
    required this.totalScore,
    required this.grade,
    required this.gradePoint,
    this.student,
    this.course,
  });

  factory StudentResultModel.fromJson(Map<String, dynamic> json) {
    return StudentResultModel(
      id: json['id'],
      resultSheetId: json['result_sheet_id'],
      studentId: json['student_id'],
      courseId: json['course_id'],
      sessionId: json['session_id'],
      caScore: (json['ca_score'] as num).toDouble(),
      examScore: (json['exam_score'] as num).toDouble(),
      totalScore: (json['total_score'] as num).toDouble(),
      grade: json['grade'],
      gradePoint: (json['grade_point'] as num).toDouble(),
      student: json['students'] != null ? StudentModel.fromJson(json['students']) : null,
      course: json['courses'] != null ? CourseModel.fromJson(json['courses']) : null,
    );
  }

  @override
  List<Object?> get props => [id, studentId, courseId, totalScore];
}

class SemesterGpaModel extends Equatable {
  final String id;
  final String studentId;
  final String sessionId;
  final String semester;
  final int totalCreditUnits;
  final double totalQualityPoints;
  final double gpa;

  const SemesterGpaModel({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.semester,
    required this.totalCreditUnits,
    required this.totalQualityPoints,
    required this.gpa,
  });

  factory SemesterGpaModel.fromJson(Map<String, dynamic> json) {
    return SemesterGpaModel(
      id: json['id'],
      studentId: json['student_id'],
      sessionId: json['session_id'],
      semester: json['semester'],
      totalCreditUnits: json['total_credit_units'],
      totalQualityPoints: (json['total_quality_points'] as num).toDouble(),
      gpa: (json['gpa'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, studentId, sessionId, semester, gpa];
}
