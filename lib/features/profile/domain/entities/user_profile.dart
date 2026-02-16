import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final bool isDarkMode; // persisted in Firestore

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.isDarkMode = false,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    bool? isDarkMode,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  // To/From Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isDarkMode': isDarkMode,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isDarkMode: map['isDarkMode'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, email, name, createdAt, isDarkMode];
}
