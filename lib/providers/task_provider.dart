import 'package:flutter/foundation.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => [..._tasks];

  void addTask(String title, DateTime date) {
    final task = Task(id: DateTime.now().toString(), title: title, date: date);
    _tasks.add(task);
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
  }

  List<Task> searchTasks(String query) {
    return _tasks.where((task) => task.title.toLowerCase().contains(query.toLowerCase())).toList();
  }

  List<Task> tasksForDate(DateTime date) {
    return _tasks.where((task) =>
      task.date.year == date.year &&
      task.date.month == date.month &&
      task.date.day == date.day
    ).toList();
  }
}
