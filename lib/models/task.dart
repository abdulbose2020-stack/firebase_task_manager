class Task {
  final String id;
  final String title;
  final bool completed;
  final int priority;

  const Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.priority,
  });

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      title: map['title'] as String? ?? 'Untitled Task',
      completed: map['completed'] as bool? ?? false,
      priority: map['priority'] as int? ?? 1,
    );
  }
}