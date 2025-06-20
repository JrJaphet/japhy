import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];
  final _tasksCollection = FirebaseFirestore.instance.collection('tasks');

  List<Task> get tasks => [..._tasks];

  // Fetch tasks from Firestore on app startup
  Future<void> fetchTasksFromFirestore() async {
    final snapshot = await _tasksCollection.get();
    _tasks.clear();
    _tasks.addAll(snapshot.docs.map((doc) => Task.fromMap(doc.data())));
    notifyListeners();
  }

  // Add a task locally and in Firestore
  Future<void> addTask(Task task) async {
    _tasks.add(task);
    notifyListeners();
    await _tasksCollection.doc(task.id).set(task.toMap());
  }

  // Remove a task locally and in Firestore
  Future<void> removeTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
    await _tasksCollection.doc(id).delete();
  }

  // Update a task locally and in Firestore
  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
      await _tasksCollection.doc(updatedTask.id).update(updatedTask.toMap());
    }
  }

  // Complete a task: update due date if recurring, delete if not
  Future<void> completeTask(Task task) async {
    if (task.isRecurring) {
      DateTime newDueDate;

      switch (task.recurrenceRule) {
        case 'daily':
          newDueDate = task.dueDate.add(Duration(days: task.recurrenceInterval));
          break;
        case 'weekly':
          newDueDate = task.dueDate.add(Duration(days: 7 * task.recurrenceInterval));
          break;
        case 'monthly':
          newDueDate = DateTime(
            task.dueDate.year,
            task.dueDate.month + task.recurrenceInterval,
            task.dueDate.day,
          );
          break;
        default:
          newDueDate = task.dueDate;
      }

      final updatedTask = task.copyWith(dueDate: newDueDate);
      await updateTask(updatedTask);
    } else {
      await removeTask(task.id);
    }
  }

  // Reorder tasks in the list locally
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

  // Logout user and redirect to login screen
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
