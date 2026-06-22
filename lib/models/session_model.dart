import 'package:equatable/equatable.dart';

class SessionModel extends Equatable {
  final String id;
  final String sessionName;
  final bool isCurrent;

  const SessionModel({
    required this.id,
    required this.sessionName,
    required this.isCurrent,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'],
      sessionName: json['session_name'],
      isCurrent: json['is_current'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, sessionName];
}
