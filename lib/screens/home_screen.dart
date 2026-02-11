import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
// import '../services/auth_service.dart'; // No longer needed directly here
import '../widgets/progress_card.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart'; // <--- Import Settings

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _updatingTaskIds = {}; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDailyCheck();
    });
  }

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

  void _navigateToAddTask(BuildContext context, {String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskScreen(initialCategory: category),
      ),
    );
  }

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
                  // ACTIONS ROW
                  Row(
                    children: [
                      // SHOP BUTTON
                      IconButton(
                        tooltip: "Item Shop",
                        icon: const Icon(Icons.store, color: Colors.deepPurple, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShopScreen()),
                          );
                        },
                      ),
                      // SETTINGS BUTTON (Replaced Logout)
                      IconButton(
                        tooltip: "Settings",
                        icon: const Icon(Icons.settings, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // --- Progress Card (Stream) ---
              StreamBuilder<UserModel>(
                stream: firestore.getUserStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Error loading stats: ${snapshot.error}',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 180, 
                      child: Center(child: CircularProgressIndicator())
                    );
                  }

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
                  _buildActionButton(context, Icons.directions_run, 'Log Workout', Colors.orange, 'Workout'),
                  _buildActionButton(context, Icons.restaurant, 'Log Meal', Colors.green, 'Nutrition'),
                  _buildActionButton(context, Icons.local_drink, 'Log Water', Colors.blue, 'Nutrition'),
                  _buildActionButton(context, Icons.add, 'Custom', Colors.purple, 'Custom'),
                ],
              ),

              const SizedBox(height: 32),

              // --- Today's Tasks List (Stream) ---
              Text("Today's Tasks", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              StreamBuilder<List<Task>>(
                stream: firestore.getTasksForDay(DateTime.now()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Text('Error loading tasks: ${snapshot.error}');
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
                        "No tasks yet. Use the buttons above to add one!",
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

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, String category) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _navigateToAddTask(context, category: category),
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