class UserProgress {
  final int currentLevel;
  final int currentXP;
  final int currentCoins;
  
  // For the progress bar: How much XP needed for next level?
  // Logic: Level 1 requires 500 XP, Level 2 requires 1000 XP, etc.
  int get xpToNextLevel => currentLevel * 500; 

  UserProgress({
    this.currentLevel = 1,
    this.currentXP = 0,
    this.currentCoins = 0,
  });

  // Create a copyWith for immutable state updates
  UserProgress copyWith({
    int? currentLevel,
    int? currentXP,
    int? currentCoins,
  }) {
    return UserProgress(
      currentLevel: currentLevel ?? this.currentLevel,
      currentXP: currentXP ?? this.currentXP,
      currentCoins: currentCoins ?? this.currentCoins,
    );
  }
}