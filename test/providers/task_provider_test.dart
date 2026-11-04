
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_task_manager/models/task.dart';
import 'package:firebase_task_manager/providers/task_provider.dart';
import 'package:firebase_task_manager/repositories/task_repository.dart';

class FakeTaskRepository implements TaskRepository {
  List<Task> storedTasks = [
    const Task(
      id: '1',
      title: 'Learn Flutter',
      completed: false,
      priority: 3,
    ),
    const Task(
      id: '2',
      title: 'Practice Firebase',
      completed: true,
      priority: 2,
    ),
  ];

  String? lastAddedTitle;
  int? lastAddedPriority;
  String? lastDeletedId;
  bool? lastCompletedFilter;

  bool shouldFail = false;

  @override
  Stream<TaskPage> watchFirstTaskPage({bool? completed}) {
    lastCompletedFilter = completed;

    return Stream.value(
      TaskPage(
        tasks: storedTasks,
        cursor: null,
        hasMore: false,
      ),
    );
  }

  @override
  Future<TaskPage> getFirstTaskPage({bool? completed}) async {
    lastCompletedFilter = completed;

    return TaskPage(
      tasks: storedTasks,
      cursor: null,
      hasMore: false,
    );
  }

  @override
  Future<TaskPage> getNextTaskPage(
    TaskPageCursor cursor, {
    bool? completed,
  }) async {
    return TaskPage(
      tasks: [],
      cursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> addTask(
    String title, {
    required int priority,
  }) async {
    if (shouldFail) throw Exception('Add failed');

    lastAddedTitle = title;
    lastAddedPriority = priority;
  }

  @override
  Future<void> updateTask(
    String id, {
    String? title,
    bool? completed,
    int? priority,
  }) async {
    if (shouldFail) throw Exception('Update failed');
  }

  @override
  Future<void> deleteTask(String id) async {
    if (shouldFail) throw Exception('Delete failed');

    lastDeletedId = id;
  }
}

void main() {
  late FakeTaskRepository repository;
  late TaskProvider provider;

  Future<void> waitForTasks() async {
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    repository = FakeTaskRepository();

    provider = TaskProvider(
  taskRepository: repository,
      authenticationChanges: Stream<bool>.value(true),
      isAuthenticated: () => true,
    );
  });

  tearDown(() {
    provider.dispose();
  });

  test('loads tasks successfully', () async {
    await waitForTasks();

    expect(provider.tasks.length, 2);
    expect(provider.tasks.first.title, 'Learn Flutter');
    expect(provider.isLoading, false);
    expect(provider.hasStreamError, false);
  });

  test('gets a task by its ID', () async {
    await waitForTasks();

    final task = provider.getTaskById('1');

    expect(task, isNotNull);
    expect(task!.title, 'Learn Flutter');
  });

  test('adds a task successfully', () async {
    final result = await provider.addTask(
      'Build an app',
      priority: 3,
    );

    expect(result, true);
    expect(repository.lastAddedTitle, 'Build an app');
    expect(repository.lastAddedPriority, 3);
    expect(provider.isAddingTask, false);
  });

  test('updates a task successfully', () async {
    await waitForTasks();

    final result = await provider.updateTask(
      '1',
      title: 'Master Flutter',
      priority: 2,
    );

    expect(result, true);
    expect(provider.getTaskById('1')!.title, 'Master Flutter');
    expect(provider.getTaskById('1')!.priority, 2);
  });

  test('toggles a task successfully', () async {
    await waitForTasks();

    final result = await provider.toggleTask('1', true);

    expect(result, true);
    expect(provider.getTaskById('1')!.completed, true);
  });

  test('deletes a task successfully', () async {
    await waitForTasks();

    final result = await provider.deleteTask('1');

    expect(result, true);
    expect(provider.getTaskById('1'), isNull);
    expect(repository.lastDeletedId, '1');
  });

  test('changes the task filter', () async {
    await waitForTasks();

    provider.changeFilter('Pending');

    await waitForTasks();

    expect(provider.selectedFilter, 'Pending');
    expect(repository.lastCompletedFilter, false);
  });

  test('handles add task errors', () async {
    repository.shouldFail = true;

    final result = await provider.addTask(
      'Failed task',
      priority: 1,
    );

    expect(result, false);
    expect(provider.errorMessage, 'Could not add task. Please try again.');
    expect(provider.isAddingTask, false);
  });
}
