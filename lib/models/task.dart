class Task {
  final String id;
  final String title;
  final DateTime dueDate;
  final String priority;
  final List<String>? tags;
  final String description;

  // Recurring task fields
  final bool isRecurring;
  final String recurrenceRule; // 'daily', 'weekly', 'monthly', or ''
  final int recurrenceInterval; // e.g., every 1 day/week/month

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.priority = 'Medium',
    this.tags,
    this.description = '',
    this.isRecurring = false,
    this.recurrenceRule = '',
    this.recurrenceInterval = 1,
  });

  // Create a copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    DateTime? dueDate,
    String? priority,
    List<String>? tags,
    String? description,
    bool? isRecurring,
    String? recurrenceRule,
    int? recurrenceInterval,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
    );
  }

  // Convert Firestore map to Task instance
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      priority: map['priority'] as String? ?? 'Medium',
      tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
      description: map['description'] as String? ?? '',
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrenceRule: map['recurrenceRule'] as String? ?? '',
      recurrenceInterval: map['recurrenceInterval'] as int? ?? 1,
    );
  }

  get date => null;

  // Convert Task instance to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'tags': tags,
      'description': description,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'recurrenceInterval': recurrenceInterval,
    };
  }
}
