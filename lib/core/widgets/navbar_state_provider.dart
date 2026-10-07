import 'package:flutter/material.dart';

class NavbarState extends ChangeNotifier {
  bool _expanded = true;
  bool get expanded => _expanded;

  void toggle() {
    _expanded = !_expanded;
    notifyListeners();
  }
}

/// Global singleton instance for navbar state
final navbarState = NavbarState();