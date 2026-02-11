import 'gamification_rules.dart';

class Task {
  final String id;
  final String title;
  final TaskCategory category;
  final TaskDifficulty difficulty;
  final TaskPriority priority;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.priority,
    this.isCompleted = false,
  });

  // Helper to visualize the potential reward before completion
  int get potentialXP => GameRules.xpRewards[difficulty]!;
  
  int get potentialCoins {
    int base = GameRules.coinBaseRewards[difficulty]!;
    double multiplier = GameRules.coinMultipliers[priority]!;
    return (base * multiplier).round();
  }
}