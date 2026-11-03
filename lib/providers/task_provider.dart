import 'package:flutter/foundation.dart';

class TaskProvider extends ChangeNotifier {
  int taskCount = 0;

  String _selectedFilter = 'All';

  String get selectedFilter => _selectedFilter;

  void incrementTaskCount() {
    taskCount++;
    notifyListeners();
  }

  void changeFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
}