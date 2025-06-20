import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/task_provider.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(bool isDark) onThemeChanged;
  final ThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _searchQuery = '';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.currentThemeMode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks.where((task) {
      final matchesDate = _selectedDay == null || isSameDay(task.dueDate, _selectedDay!);
      final matchesQuery = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDate && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Japhy To-Do"),
        actions: [
          Row(
            children: [
              const Icon(Icons.light_mode),
              Switch(
                value: _isDarkMode,
                onChanged: (val) {
                  setState(() {
                    _isDarkMode = val;
                  });
                  widget.onThemeChanged(val);
                },
              ),
              const Icon(Icons.dark_mode),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => taskProvider.logout(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Dismissible(
                  key: Key(task.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    taskProvider.removeTask(task.id);
                    NotificationService.cancelNotification(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task deleted")),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(task.dueDate.toLocal().toString()),
                    onTap: () async {
                      final updatedTask = await Navigator.push<Task?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddTaskScreen(existingTask: task),
                        ),
                      );
                      if (updatedTask != null) {
                        taskProvider.updateTask(updatedTask);
                        NotificationService.cancelNotification(task.id);
                        NotificationService.scheduleTaskReminder(updatedTask);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push<Task?>(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          if (newTask != null) {
            taskProvider.addTask(newTask);
            NotificationService.scheduleTaskReminder(newTask);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
