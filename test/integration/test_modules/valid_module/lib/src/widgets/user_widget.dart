import 'package:flutter/material.dart';

import '../models/user.dart';

/// Widget for displaying user information.
/// 
/// This widget shows user details in a card format
/// with proper Material Design styling.
class UserWidget extends StatelessWidget {
  /// Creates a new UserWidget.
  const UserWidget({
    required this.user,
    this.onTap,
    super.key,
  });

  /// User to display.
  final User user;

  /// Callback when the widget is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? Colors.green : Colors.grey,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Text(
              user.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: user.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: user.isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.red),
        onTap: onTap,
      ),
    );
  }
}
