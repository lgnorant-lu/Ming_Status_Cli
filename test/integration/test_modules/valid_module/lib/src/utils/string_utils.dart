/// Utility functions for string manipulation.
///
/// This library provides common string operations
/// with proper null safety and validation.
class StringUtils {
  /// Private constructor to prevent instantiation.
  const StringUtils._();

  /// Checks if a string is null or empty.
  ///
  /// Returns true if the string is null, empty, or contains only whitespace.
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Capitalizes the first letter of a string.
  ///
  /// Returns the string with the first letter capitalized.
  /// Returns empty string if input is null or empty.
  static String capitalize(String? value) {
    if (isNullOrEmpty(value)) return '';

    final trimmed = value!.trim();
    if (trimmed.isEmpty) return '';

    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  /// Converts a string to camelCase.
  ///
  /// Splits the string by spaces, underscores, and hyphens,
  /// then capitalizes each word except the first.
  static String toCamelCase(String? value) {
    if (isNullOrEmpty(value)) return '';

    final words = value!
        .trim()
        .split(RegExp(r'[\s_-]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    final result = StringBuffer(words.first.toLowerCase());
    for (var i = 1; i < words.length; i++) {
      result.write(capitalize(words[i]));
    }

    return result.toString();
  }

  /// Converts a string to snake_case.
  ///
  /// Replaces spaces and hyphens with underscores,
  /// and converts to lowercase.
  static String toSnakeCase(String? value) {
    if (isNullOrEmpty(value)) return '';

    return value!.trim().replaceAll(RegExp(r'[\s-]+'), '_').toLowerCase();
  }

  /// Truncates a string to a maximum length.
  ///
  /// Adds ellipsis (...) if the string is longer than maxLength.
  static String truncate(String? value, int maxLength,
      {String suffix = '...',}) {
    if (isNullOrEmpty(value)) return '';
    if (maxLength <= 0) return '';

    final trimmed = value!.trim();
    if (trimmed.length <= maxLength) return trimmed;

    return '${trimmed.substring(0, maxLength - suffix.length)}$suffix';
  }
}
