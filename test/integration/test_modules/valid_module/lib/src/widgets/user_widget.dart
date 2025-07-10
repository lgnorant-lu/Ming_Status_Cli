import '../models/user.dart';

/// Widget for displaying user information.
///
/// This widget shows user details in a simple format.
class UserWidget {
  /// Creates a new UserWidget.
  const UserWidget({
    required this.user,
    this.onTap,
  });

  /// User to display.
  final User user;

  /// Callback when the widget is tapped.
  final void Function()? onTap;

  /// Build method that returns a string representation.
  String build() {
    return 'User: ${user.name} (${user.email}) - ${user.isActive ? 'Active' : 'Inactive'}';
  }
}
