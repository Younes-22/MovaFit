import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';

class CompletionChart extends StatelessWidget {
  const CompletionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    // Calculate the last 7 days dynamically
    final now = DateTime.now();
    final weekDays = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Task Consistency (Last 7 Days)",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: weekDays.map((date) {
                  return Expanded(
                    child: StreamBuilder<List<Task>>(
                      stream: firestore.getTasksForDay(date),
                      builder: (context, snapshot) {
                        // Default to 0 if loading or no data
                        if (!snapshot.hasData) {
                          return _buildBar(context, 0, date);
                        }

                        final tasks = snapshot.data!;
                        if (tasks.isEmpty) {
                          // No tasks assigned = 0% completed effectively
                          return _buildBar(context, 0, date);
                        }

                        final completed = tasks.where((t) => t.isCompleted).length;
                        final percentage = completed / tasks.length;

                        return _buildBar(context, percentage, date);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context, double percentage, DateTime date) {
    final isToday = date.day == DateTime.now().day && 
                    date.month == DateTime.now().month;
    
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background track
              Container(
                width: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Foreground progress
              FractionallySizedBox(
                heightFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  width: 12,
                  decoration: BoxDecoration(
                    color: isToday ? Colors.orange : Colors.deepPurple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat.E().format(date)[0], // M, T, W...
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }
}