import 'package:flutter/foundation.dart';

/// Service to track whether the user action menu is open globally.
/// This allows pages to intercept the back button and close the menu first.
class UserMenuState extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void setOpen(bool value) {
    if (_isOpen != value) {
      _isOpen = value;
      notifyListeners();
    }
  }

  void open() => setOpen(true);
  void close() => setOpen(false);
  void toggle() => setOpen(!_isOpen);
}
