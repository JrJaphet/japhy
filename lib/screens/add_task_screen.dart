import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? existingTask;

  const AddTaskScreen({super.key, this.existingTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  bool _isRecurring = false;
  String _recurrenceRule = 'daily';
  int _recurrenceInterval = 1;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingTask?.description ?? '');
    _selectedDate = widget.existingTask?.dueDate ?? DateTime.now();

    final existingDueDate = widget.existingTask?.dueDate;
    _selectedTime = existingDueDate != null
        ? TimeOfDay(hour: existingDueDate.hour, minute: existingDueDate.minute)
        : TimeOfDay.now();

    if (widget.existingTask != null) {
      _isRecurring = widget.existingTask!.isRecurring;
      _recurrenceRule = widget.existingTask!.recurrenceRule.isNotEmpty
          ? widget.existingTask!.recurrenceRule
          : 'daily';
      _recurrenceInterval = widget.existingTask!.recurrenceInterval;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newTask = Task(
        id: widget.existingTask?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        dueDate: combinedDateTime,
        description: _descriptionController.text.trim(),
        isRecurring: _isRecurring,
        recurrenceRule: _isRecurring ? _recurrenceRule : '',
        recurrenceInterval: _isRecurring ? _recurrenceInterval : 1,
        priority: widget.existingTask?.priority ?? 'Medium',
        tags: widget.existingTask?.tags,
      );

      // 🔔 Schedule notifications
      await NotificationService.scheduleTaskReminder(newTask);
      if (_isRecurring) {
        await NotificationService.scheduleRecurringReminder(newTask);
      }

      Navigator.of(context).pop(newTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Due Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() => _selectedDate = pickedDate);
                  }
                },
              ),
              ListTile(
                title: Text('Due Time: ${_selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (pickedTime != null) {
                    setState(() => _selectedTime = pickedTime);
                  }
                },
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('Recurring Task'),
                value: _isRecurring,
                onChanged: (val) {
                  setState(() {
                    _isRecurring = val ?? false;
                  });
                },
              ),
              if (_isRecurring) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Recurrence'),
                  value: _recurrenceRule,
                  items: ['daily', 'weekly', 'monthly']
                      .map((rule) => DropdownMenuItem(
                            value: rule,
                            child: Text(rule[0].toUpperCase() + rule.substring(1)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _recurrenceRule = val!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _recurrenceInterval.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Interval',
                    helperText: 'Every n days/weeks/months',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter interval';
                    }
                    final intVal = int.tryParse(value);
                    if (intVal == null || intVal <= 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    final intVal = int.tryParse(val);
                    if (intVal != null && intVal > 0) {
                      _recurrenceInterval = intVal;
                    }
                  },
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Update Task' : 'Add Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
