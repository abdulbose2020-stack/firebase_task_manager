import 'package:flutter/foundation.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  bool _isAddingTask = false;
  bool get isAddingTask => _isAddingTask;

  bool _isUpdatingTask = false;
  bool get isUpdatingTask => _isUpdatingTask;

  bool _isDeletingTask = false;
  bool get isDeletingTask => _isDeletingTask;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void changeFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<bool> addTask(
    String title, {
    required int priority,
  }) async {
    if (_isAddingTask) return false;

    _isAddingTask = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.addTask(title, priority: priority);
      return true;
    } catch (e) {
      _errorMessage = 'Could not add task. Please try again.';
      return false;
    } finally {
      _isAddingTask = false;
      notifyListeners();
    }
  }

  Future<bool> updateTask(
    String id, {
    String? title,
    bool? completed,
    int? priority,
  }) async {
    if (_isUpdatingTask) return false;

    _isUpdatingTask = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.updateTask(
        id,
        title: title,
        completed: completed,
        priority: priority,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Could not update task. Please try again.';
      return false;
    } finally {
      _isUpdatingTask = false;
      notifyListeners();
    }
  }

  Future<bool> toggleTask(String id, bool completed) {
    return updateTask(id, completed: completed);
  }

  Future<bool> deleteTask(String id) async {
    if (_isDeletingTask) return false;

    _isDeletingTask = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.deleteTask(id);
      return true;
    } catch (e) {
      _errorMessage = 'Could not delete task. Please try again.';
      return false;
    } finally {
      _isDeletingTask = false;
      notifyListeners();
    }
  }
}
