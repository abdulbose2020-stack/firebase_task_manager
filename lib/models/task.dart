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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          id == other.id &&
          title == other.title &&
          completed == other.completed &&
          priority == other.priority;

  @override
  int get hashCode => Object.hash(id, title, completed, priority);
}
