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

  // Search for tasks containing a keyword in title or description
  List<Task> searchTasks(String keyword) {
  return _tasks.where((task) =>
    task.title.toLowerCase().contains(keyword.toLowerCase())
  ).toList();
}

  // Logout and redirect to login screen
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
