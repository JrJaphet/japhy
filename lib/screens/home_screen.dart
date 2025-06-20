import 'dart:async';

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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.currentThemeMode == ThemeMode.dark;

    Future.microtask(() {
      Provider.of<TaskProvider>(context, listen: false).fetchTasksFromFirestore();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks.where((task) {
      final matchesDate = _selectedDay == null || isSameDay(task.dueDate, _selectedDay!);
      final query = _searchQuery.toLowerCase();

      final matchesQuery = task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          (task.tags != null && task.tags!.any((tag) => tag.toLowerCase().contains(query)));

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
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Japhy big background text:
          Center(
            child: Text(
              'Japhy',
              style: TextStyle(
                fontSize: 120,
                fontWeight: FontWeight.bold,
                color: Colors.blue.withOpacity(0.1),
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.15),
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
            ),
          ),

          // Your actual content on top:
          Column(
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
                      onDismissed: (_) async {
                        await taskProvider.completeTask(task);
                        NotificationService.cancelNotification(task.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Task completed")),
                        );
                      },
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: task.isRecurring
                            ? const Icon(Icons.loop, color: Colors.blue)
                            : const Icon(Icons.radio_button_unchecked),
                        title: Text(task.title),
                        subtitle: Text(
                          "${task.dueDate.toLocal()}${task.isRecurring ? ' • ${task.recurrenceRule}' : ''}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
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
                      ),
                    );
                  },
                ),
              ),
            ],
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
