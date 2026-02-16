import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name; // For Firebase Auth user, name might be null initially

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
  });

  @override
  List<Object?> get props => [id, email, name];
}
