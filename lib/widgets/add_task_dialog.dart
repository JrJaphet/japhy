import 'package:flutter/material.dart';
import 'package:japhy_todo_app/models/task.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class AddTaskDialog extends StatefulWidget {
  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _controller = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _submit() {
    if (_controller.text.isEmpty) return;

    Provider.of<TaskProvider>(context, listen: false)
        .addTask(_controller.text as Task, _selectedDate);

    Navigator.of(context).pop(); // Close the dialog
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: 'Task Title'),
          ),
          SizedBox(height: 10),
          Text("Date: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
          TextButton.icon(
            icon: Icon(Icons.calendar_today),
            label: Text('Pick Date'),
            onPressed: _pickDate,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Add'),
          onPressed: _submit,
        ),
      ],
    );
  }
}
