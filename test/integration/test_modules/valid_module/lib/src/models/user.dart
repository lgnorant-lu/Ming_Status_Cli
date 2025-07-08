import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// User data model with proper documentation.
///
/// This class represents a user in the system with
/// basic information and JSON serialization support.
@JsonSerializable()
class User {
  /// Creates a new User instance.
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isActive = true,
  });

  /// Creates a User from JSON data.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// User unique identifier.
  final String id;

  /// User display name.
  final String name;

  /// User email address.
  final String email;

  /// Whether the user is currently active.
  final bool isActive;

  /// Converts User to JSON data.
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(id, name, email, isActive);
}
