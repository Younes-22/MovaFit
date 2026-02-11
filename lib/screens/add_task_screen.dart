import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';

class AddTaskScreen extends StatefulWidget {
  final String? initialCategory;

  const AddTaskScreen({super.key, this.initialCategory});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  TaskDifficulty _difficulty = TaskDifficulty.easy;
  TaskPriority _priority = TaskPriority.normal;
  String _category = 'Workout'; // Default
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
    }
  }

  void _submit() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirestoreService().addTask(
        title: _titleController.text,
        category: _category,
        difficulty: _difficulty,
        priority: _priority,
        date: DateTime.now(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: ['Workout', 'Nutrition', 'Wellness', 'Custom']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskDifficulty>(
                    value: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                    items: TaskDifficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                    items: TaskPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Task'),
              ),
            )
          ],
        ),
      ),
    );
  }
}