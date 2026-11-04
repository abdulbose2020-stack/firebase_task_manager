import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskPageCursor {
  final QueryDocumentSnapshot<Map<String, dynamic>> _document;

  TaskPageCursor._(this._document);
}

class TaskPage {
  final List<Task> tasks;
  final TaskPageCursor? cursor;
  final bool hasMore;

  const TaskPage({
    required this.tasks,
    required this.cursor,
    required this.hasMore,
  });
}

class TaskRepository {
  final TaskService _taskService;

  TaskRepository({required this._taskService});
  TaskPage _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return TaskPage(
      tasks: snapshot.docs
          .map((doc) => Task.fromMap(doc.data(), doc.id))
          .toList(),
      cursor: snapshot.docs.isEmpty
          ? null
          : TaskPageCursor._(snapshot.docs.last),
      hasMore: snapshot.docs.length == 10,
    );
  }

  Stream<TaskPage> watchFirstTaskPage({bool? completed}) {
    return _taskService
        .watchFirstTaskPage(completed: completed)
        .map(_mapSnapshot);
  }

  Future<TaskPage> getFirstTaskPage({bool? completed}) async {
    final snapshot = await _taskService.getFirstTaskPage(
      completed: completed,
    );

    return _mapSnapshot(snapshot);
  }

  Future<TaskPage> getNextTaskPage(
    TaskPageCursor cursor, {
    bool? completed,
  }) async {
    final snapshot = await _taskService.getNextTaskPage(
      cursor._document,
      completed: completed,
    );

    return _mapSnapshot(snapshot);
  }

  Future<void> addTask(
    String title, {
    required int priority,
  }) {
    return _taskService.addTask(title, priority: priority);
  }

  Future<void> updateTask(
    String id, {
    String? title,
    bool? completed,
    int? priority,
  }) {
    return _taskService.updateTask(
      id,
      title: title,
      completed: completed,
      priority: priority,
    );
  }

  Future<void> deleteTask(String id) {
    return _taskService.deleteTask(id);
  }
}