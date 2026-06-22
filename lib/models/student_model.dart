import 'package:equatable/equatable.dart';
import 'profile_model.dart';

enum AcademicStanding { goodStanding, probation, withdrawn }

class StudentModel extends Equatable {
  final String id;
  final String profileId;
  final String matricNumber;
  final int level;
  final AcademicStanding academicStanding;
  final ProfileModel? profile;

  const StudentModel({
    required this.id,
    required this.profileId,
    required this.matricNumber,
    required this.level,
    required this.academicStanding,
    this.profile,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      profileId: json['profile_id'],
      matricNumber: json['matric_number'],
      level: json['level'],
      academicStanding: AcademicStanding.values.firstWhere(
        (e) => e.name == _toCamel(json['academic_standing'] ?? 'good_standing'),
        orElse: () => AcademicStanding.goodStanding,
      ),
      profile: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'])
          : null,
    );
  }

  static String _toCamel(String snake) {
    final parts = snake.split('_');
    return parts[0] + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  String get standingLabel {
    switch (academicStanding) {
      case AcademicStanding.goodStanding: return 'Good Standing';
      case AcademicStanding.probation: return 'Probation';
      case AcademicStanding.withdrawn: return 'Withdrawn';
    }
  }

  @override
  List<Object?> get props => [id, matricNumber, level];
}
