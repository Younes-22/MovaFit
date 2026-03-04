import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // Calendar Package
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/progress_card.dart';
import '../widgets/task_tile.dart';
import '../widgets/quote_widget.dart'; // Motivational Quote
import '../widgets/completion_chart.dart'; // <--- NEW IMPORT
import 'add_task_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';
import 'nutrition_screen.dart'; 
import 'workout_screen.dart';   

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Keep track of which tasks are currently loading to prevent double-clicks
  final Set<String> _updatingTaskIds = {}; 
  
  // --- CALENDAR STATE ---
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week; // Default to week view

  @override
  void initState() {
    super.initState();
    // Run the rollover check after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDailyCheck();
    });
  }

  // --- DAILY ROLLOVER CHECK ---
  void _runDailyCheck() async {
    final firestore = FirestoreService();
    final summary = await firestore.checkDailyRollover();

    if (summary != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daily Summary'),
          content: Text(summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // --- LEVEL UP DIALOG ---
  void _showLevelUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
        title: const Text('🎉 LEVEL UP! 🎉', textAlign: TextAlign.center),
        content: const Text(
          'Congratulations! You have reached the next level. Keep up the great work!',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('AWESOME!'),
          ),
        ],
      ),
    );
  }

  String get _formattedDate {
    final now = DateTime.now();
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Generic Task Navigation
  void _navigateToAddTask(BuildContext context, {String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the currently selected day to the Add Task screen
        builder: (_) => AddTaskScreen(
          initialCategory: category,
          initialDate: _selectedDay, 
        ),
      ),
    );
  }

  // Safe Toggle Method to handle Firestore transactions
  Future<void> _handleTaskToggle(Task task, bool newValue, FirestoreService firestore) async {
    setState(() {
      _updatingTaskIds.add(task.id);
    });

    try {
      bool didLevelUp = await firestore.toggleTaskCompletion(task, newValue);

      if (didLevelUp && mounted) {
        _showLevelUpDialog();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingTaskIds.remove(task.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back,',
                        style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                      ),
                      Text(
                        _formattedDate,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: "Item Shop",
                        icon: const Icon(Icons.store, color: Colors.deepPurple, size: 28),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                      ),
                      IconButton(
                        tooltip: "Settings",
                        icon: const Icon(Icons.settings, size: 28),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // --- MOTIVATIONAL QUOTE WIDGET ---
              const QuoteWidget(), 

              const SizedBox(height: 24),

              // --- Progress Card ---
              StreamBuilder<UserModel>(
                stream: firestore.getUserStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const SizedBox.shrink(); 
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final user = snapshot.data!;
                  double progress = user.currentXP / 500.0;
                  
                  return ProgressCard(
                    level: user.currentLevel,
                    currentXP: user.currentXP,
                    currentCoins: user.currentCoins,
                    progress: progress,
                    selectedAvatarId: user.selectedAvatarId, 
                  );
                },
              ),

              const SizedBox(height: 32),

              // --- Quick Actions Grid ---
              Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  // 1. Log Workout (Opens WorkoutScreen)
                  _buildActionButton(
                    context, 
                    Icons.directions_run, 
                    'Log Workout', 
                    Colors.orange, 
                    'Workout',
                    onPressedOverride: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const WorkoutScreen())
                      );
                    },
                  ),
                  
                  // 2. Nutrition Tracker (Opens NutritionScreen)
                  _buildActionButton(
                    context, 
                    Icons.restaurant, 
                    'Log Meal', 
                    Colors.green, 
                    'Nutrition',
                    onPressedOverride: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const NutritionScreen())
                      );
                    },
                  ),
                  
                  // 3. Generic Water (Still a generic task for now)
                  _buildActionButton(context, Icons.local_drink, 'Log Water', Colors.blue, 'Nutrition'),
                  
                  // 4. Custom Task
                  _buildActionButton(context, Icons.add, 'Custom', Colors.purple, 'Custom'),
                ],
              ),

              const SizedBox(height: 32),

              // --- CALENDAR WIDGET ---
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const SizedBox(height: 24), // Spacing

              // --- NEW: COMPLETION CHART ---
              const CompletionChart(),

              const SizedBox(height: 16),

              // --- Tasks List (Filtered by Calendar Selection) ---
              StreamBuilder<List<Task>>(
                stream: firestore.getTasksForDay(_selectedDay), 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final tasks = snapshot.data ?? [];

                  if (tasks.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "No tasks for this day.\nTap '+' to add one!",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskTile(
                        task: task,
                        isUpdating: _updatingTaskIds.contains(task.id), 
                        onChanged: (val) {
                          if (val != null) {
                            _handleTaskToggle(task, val, firestore);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Updated Button Builder with optional Override
  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, String category, {VoidCallback? onPressedOverride}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        // Use the override if provided, otherwise default to Task Creator
        onTap: onPressedOverride ?? () => _navigateToAddTask(context, category: category),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}