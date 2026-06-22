import 'package:equatable/equatable.dart';
import 'profile_model.dart';

class LecturerModel extends Equatable {
  final String id;
  final String profileId;
  final String staffId;
  final String? designation;
  final ProfileModel? profile;

  const LecturerModel({
    required this.id,
    required this.profileId,
    required this.staffId,
    this.designation,
    this.profile,
  });

  factory LecturerModel.fromJson(Map<String, dynamic> json) {
    return LecturerModel(
      id: json['id'],
      profileId: json['profile_id'],
      staffId: json['staff_id'],
      designation: json['designation'],
      profile: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'])
          : null,
    );
  }

  @override
  List<Object?> get props => [id, staffId];
}
