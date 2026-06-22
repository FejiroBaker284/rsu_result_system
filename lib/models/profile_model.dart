import 'package:equatable/equatable.dart';

enum UserRole { admin, lecturer, student }

class ProfileModel extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role.name,
    'phone': phone,
  };

  @override
  List<Object?> get props => [id, fullName, email, role, phone];
}
