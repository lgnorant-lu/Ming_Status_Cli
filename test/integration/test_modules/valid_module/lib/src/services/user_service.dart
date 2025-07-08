import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user.dart';

/// Service for managing user operations.
///
/// This service provides methods for CRUD operations
/// on user data with proper error handling.
class UserService {
  /// Creates a new UserService instance.
  const UserService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Base URL for the API.
  final String baseUrl;

  /// Request timeout duration.
  final Duration timeout;

  /// Fetches a user by ID.
  ///
  /// Returns the user if found, null otherwise.
  /// Throws [UserServiceException] on error.
  Future<User?> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw UserServiceException(
          'Failed to fetch user: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw UserServiceException('Network error: $e');
    }
  }

  /// Creates a new user.
  ///
  /// Returns the created user with assigned ID.
  /// Throws [UserServiceException] on error.
  Future<User> createUser(User user) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(user.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(json);
      } else {
        throw UserServiceException(
          'Failed to create user: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw UserServiceException('Network error: $e');
    }
  }
}

/// Exception thrown by UserService operations.
class UserServiceException implements Exception {
  /// Creates a new UserServiceException.
  const UserServiceException(this.message);

  /// Error message.
  final String message;

  @override
  String toString() => 'UserServiceException: $message';
}
