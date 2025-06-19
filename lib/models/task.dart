class Task {
  final String id;
  final String title;
  final DateTime dueDate;
  final String priority;
  final List<String>? tags;
  final String description;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.priority = 'Medium',
    this.tags,
    this.description = '',
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    String? priority,
    List<String>? tags,
    String? description,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      description: description ?? this.description,
    );
  }

  // Also update fromMap and toMap accordingly for persistence
}
