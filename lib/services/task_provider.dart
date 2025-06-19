import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => [..._tasks];

  // Add a task
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  // Remove a task by ID
  void removeTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  // Update a task
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  // Reorder tasks in the list
  void reorderTasks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    notifyListeners();
  }

  // Full-text search (title, description, tags)
  List<Task> searchTasks(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return _tasks.where((task) {
      final inTitle = task.title.toLowerCase().contains(lowerKeyword);
      final inDescription = task.description.toLowerCase().contains(lowerKeyword);
      final inTags = task.tags?.any((tag) => tag.toLowerCase().contains(lowerKeyword)) ?? false;
      return inTitle || inDescription || inTags;
    }).toList();
  }

  // Filter tasks by date, priority, tags, and keyword
  List<Task> filterTasks({
    DateTime? date,
    String? priority,
    List<String>? tags,
    String? keyword,
  }) {
    return _tasks.where((task) {
      final matchesDate = date == null || 
        (task.dueDate.year == date.year &&
         task.dueDate.month == date.month &&
         task.dueDate.day == date.day);
      
      final matchesPriority = priority == null || task.priority == priority;

      final matchesTags = tags == null || tags.isEmpty || 
        (task.tags != null && tags.every((tag) => task.tags!.contains(tag)));

      final matchesKeyword = keyword == null || keyword.isEmpty || searchTasks(keyword).contains(task);

      return matchesDate && matchesPriority && matchesTags && matchesKeyword;
    }).toList();
  }

  // Logout and redirect to login screen
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
