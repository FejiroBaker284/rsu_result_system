import 'package:equatable/equatable.dart';

enum SemesterType { first, second }

class CourseModel extends Equatable {
  final String id;
  final String courseCode;
  final String courseTitle;
  final int creditUnits;
  final int level;
  final SemesterType semester;
  final bool isActive;

  const CourseModel({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.level,
    required this.semester,
    this.isActive = true,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'],
      courseCode: json['course_code'],
      courseTitle: json['course_title'],
      creditUnits: json['credit_units'],
      level: json['level'],
      semester: SemesterType.values.firstWhere((e) => e.name == json['semester']),
      isActive: json['is_active'] ?? true,
    );
  }

  String get semesterLabel => semester == SemesterType.first ? 'First Semester' : 'Second Semester';

  @override
  List<Object?> get props => [id, courseCode];
}
