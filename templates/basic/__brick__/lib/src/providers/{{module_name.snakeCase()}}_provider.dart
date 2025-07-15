import 'package:flutter/foundation.dart';

/// {{module_name}} Provider
/// 
/// State management provider for {{module_name}}
/// {{description}}
/// 
/// Created by {{author}} on {{generated_date}}
class {{module_name.pascalCase()}}Provider extends ChangeNotifier {
  int _counter = 0;
  bool _isLoading = false;

  /// Current counter value
  int get counter => _counter;

  /// Whether the provider is currently loading
  bool get isLoading => _isLoading;

  /// Increment the counter
  void increment() {
    _counter++;
    notifyListeners();
  }

  /// Decrement the counter
  void decrement() {
    if (_counter > 0) {
      _counter--;
      notifyListeners();
    }
  }

  /// Reset the counter to zero
  void reset() {
    _counter = 0;
    notifyListeners();
  }

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Simulate async operation
  Future<void> performAsyncOperation() async {
    setLoading(true);
    try {
      // Simulate network call or heavy computation
      await Future<void>.delayed(const Duration(seconds: 2));
      increment();
    } finally {
      setLoading(false);
    }
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }
} 