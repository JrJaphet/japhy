import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];

  final _tasksCollection = FirebaseFirestore.instance.collection('tasks');

  List<Task> get tasks => [..._tasks];

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

  // Optional: Sync from Firestore on app startup
  Future<void> fetchTasksFromFirestore() async {
    final snapshot = await _tasksCollection.get();
    _tasks.clear();
    _tasks.addAll(snapshot.docs.map((doc) => Task.fromMap(doc.data())));
    notifyListeners();
  }

  // Search tasks by title
  List<Task> searchTasks(String keyword) {
    return _tasks.where((task) =>
      task.title.toLowerCase().contains(keyword.toLowerCase())
    ).toList();
  }

  // Log out user
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
