import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSubscription;

  int _streamGeneration = 0;
  bool _disposed = false;

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  final List<Task> _firstPageTasks = [];
  final List<Task> _additionalTasks = [];

  List<Task> get tasks {
    final uniqueTasks = <String, Task>{};

    for (final task in [..._firstPageTasks, ..._additionalTasks]) {
      uniqueTasks[task.id] = task;
    }

    return uniqueTasks.values.toList();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMoreTasks = true;
  bool get hasMoreTasks => _hasMoreTasks;

  bool _hasStreamError = false;
  bool get hasStreamError => _hasStreamError;

  bool _isAddingTask = false;
  bool get isAddingTask => _isAddingTask;

  bool _isUpdatingTask = false;
  bool get isUpdatingTask => _isUpdatingTask;

  bool _isDeletingTask = false;
  bool get isDeletingTask => _isDeletingTask;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  bool? get _completedFilter {
    switch (_selectedFilter) {
      case 'Pending':
        return false;
      case 'Completed':
        return true;
      default:
        return null;
    }
  }

  TaskProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChange,
      onError: (Object error) {
        _hasStreamError = true;
        _errorMessage = 'Authentication error. Please try again.';
        _isLoading = false;
        _notify();
      },
    );
  }

  void _handleAuthChange(User? user) {
    if (_disposed) return;

    if (user == null) {
      _cancelTasksSubscription();
      _firstPageTasks.clear();
      _additionalTasks.clear();
      _lastDocument = null;
      _hasMoreTasks = false;
      _isLoading = false;
      _hasStreamError = false;
      _errorMessage = null;
      _notify();
      return;
    }

    _startTasksStream();
  }

  void _cancelTasksSubscription() {
    _streamGeneration++;
    final subscription = _tasksSubscription;
    _tasksSubscription = null;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }
  }

  void _startTasksStream() {
    if (_disposed || FirebaseAuth.instance.currentUser == null) return;

    _cancelTasksSubscription();
    final generation = _streamGeneration;

    _firstPageTasks.clear();
    _additionalTasks.clear();
    _lastDocument = null;
    _hasMoreTasks = true;
    _isLoading = true;
    _isLoadingMore = false;
    _hasStreamError = false;
    _errorMessage = null;
    _notify();

    _tasksSubscription = _taskService
        .watchFirstTaskPage(completed: _completedFilter)
        .listen(
          (snapshot) {
            if (_disposed || generation != _streamGeneration) return;

            _firstPageTasks
              ..clear()
              ..addAll(
                snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)),
              );

            if (_additionalTasks.isEmpty) {
              _lastDocument = snapshot.docs.isEmpty ? null : snapshot.docs.last;

              _hasMoreTasks = snapshot.docs.length == 10;
            }
            _isLoading = false;
            _hasStreamError = false;
            _errorMessage = null;
            _notify();
          },
          onError: (Object error) {
            if (_disposed || generation != _streamGeneration) return;

            _isLoading = false;
            _hasStreamError = true;
            _errorMessage = 'Something went wrong loading tasks.';
            _notify();
          },
        );
  }

  void changeFilter(String filter) {
    if (_selectedFilter == filter) return;

    _selectedFilter = filter;
    _startTasksStream();
  }

  void retryTasksStream() {
    _startTasksStream();
  }

  Future<void> loadMoreTasks() async {
    if (_isLoadingMore ||
        !_hasMoreTasks ||
        _lastDocument == null ||
        FirebaseAuth.instance.currentUser == null) {
      return;
    }

    _isLoadingMore = true;
    _notify();

    try {
      final snapshot = await _taskService.getNextTaskPage(
        _lastDocument!,
        completed: _completedFilter,
      );

      if (_disposed) return;

      final existingIds = tasks.map((task) => task.id).toSet();

      for (final doc in snapshot.docs) {
        if (existingIds.add(doc.id)) {
          _additionalTasks.add(Task.fromMap(doc.data(), doc.id));
        }
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMoreTasks = snapshot.docs.length == 10;
      _errorMessage = null;
    } catch (e) {
      if (_disposed) return;
      _errorMessage = 'Could not load more tasks. Please try again.';
    } finally {
      if (!_disposed) {
        _isLoadingMore = false;
        _notify();
      }
    }
  }

  Future<bool> addTask(String title, {required int priority}) async {
    if (_isAddingTask) return false;

    _isAddingTask = true;
    _errorMessage = null;
    _notify();

    try {
      await _taskService.addTask(title, priority: priority);
      return true;
    } catch (e) {
      _errorMessage = 'Could not add task. Please try again.';
      return false;
    } finally {
      _isAddingTask = false;
      _notify();
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
    _notify();

    try {
      await _taskService.updateTask(
        id,
        title: title,
        completed: completed,
        priority: priority,
      );

      final index = tasks.indexWhere((task) => task.id == id);

      if (index != -1) {
        final currentTask = tasks[index];

        final updatedTask = Task(
          id: currentTask.id,
          title: title ?? currentTask.title,
          completed: completed ?? currentTask.completed,
          priority: priority ?? currentTask.priority,
        );

        _replaceTask(updatedTask);

        if (_completedFilter != null &&
            completed != null &&
            completed != _completedFilter) {
          _removeTask(id);
        }
      }

      return true;
    } catch (e) {
      _errorMessage = 'Could not update task. Please try again.';
      return false;
    } finally {
      _isUpdatingTask = false;
      _notify();
    }
  }

  Future<bool> toggleTask(String id, bool completed) {
    return updateTask(id, completed: completed);
  }

  Future<bool> deleteTask(String id) async {
    if (_isDeletingTask) return false;

    _isDeletingTask = true;
    _errorMessage = null;
    _notify();

    try {
      await _taskService.deleteTask(id);
      _removeTask(id);
      return true;
    } catch (e) {
      _errorMessage = 'Could not delete task. Please try again.';
      return false;
    } finally {
      _isDeletingTask = false;
      _notify();
    }
  }

  void _replaceTask(Task updatedTask) {
    for (var i = 0; i < _firstPageTasks.length; i++) {
      if (_firstPageTasks[i].id == updatedTask.id) {
        _firstPageTasks[i] = updatedTask;
        return;
      }
    }

    for (var i = 0; i < _additionalTasks.length; i++) {
      if (_additionalTasks[i].id == updatedTask.id) {
        _additionalTasks[i] = updatedTask;
        return;
      }
    }
  }

  void _removeTask(String id) {
    _firstPageTasks.removeWhere((task) => task.id == id);
    _additionalTasks.removeWhere((task) => task.id == id);
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTasksSubscription();

    final authSubscription = _authSubscription;
    _authSubscription = null;

    if (authSubscription != null) {
      unawaited(authSubscription.cancel());
    }

    super.dispose();
  }
}
