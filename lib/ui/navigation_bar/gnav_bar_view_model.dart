// lib/ui/navigation_bar/gnav_bar_view_model.dart

import 'package:flutter/material.dart';

class GnavBarViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }
}
