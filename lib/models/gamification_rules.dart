enum TaskDifficulty { easy, medium, hard }
enum TaskPriority { low, normal, high }
enum TaskCategory { workout, nutrition, wellness, custom }

class GameRules {
  // --- XP Rewards (Fixed by Difficulty) ---
  static const Map<TaskDifficulty, int> xpRewards = {
    TaskDifficulty.easy: 25,
    TaskDifficulty.medium: 50,
    TaskDifficulty.hard: 80,
  };

  // --- Coin Base Rewards (Fixed by Difficulty) ---
  static const Map<TaskDifficulty, int> coinBaseRewards = {
    TaskDifficulty.easy: 10,
    TaskDifficulty.medium: 25,
    TaskDifficulty.hard: 40,
  };

  // --- Priority Multipliers for Coins ---
  static const Map<TaskPriority, double> coinMultipliers = {
    TaskPriority.low: 0.8,
    TaskPriority.normal: 1.0,
    TaskPriority.high: 1.3,
  };

  // --- Missed Task Penalties (Coins) ---
  static const Map<TaskPriority, int> missedTaskPenalties = {
    TaskPriority.low: 5,
    TaskPriority.normal: 15,
    TaskPriority.high: 30,
  };

  // --- Safeguard Thresholds ---
  static const int minLevelForHardTasks = 3; // Hard tasks locked until Lvl 3
  static const int maxHighPriorityTasksPerDay = 2; // Prevent burnout
}