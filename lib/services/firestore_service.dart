import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/reward_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get the current User ID safely
  String? get _uid => _auth.currentUser?.uid;

  // ===========================================================================
  // USER PROFILE METHODS
  // ===========================================================================

  Future<void> createUserProfile(User user, String username) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    
    if (!snapshot.exists) {
      await docRef.set({
        'email': user.email,
        'username': username,
        'currentLevel': 1,
        'currentXP': 0,
        'currentCoins': 0,
        'unlockedRewardIds': [], 
        'selectedAvatarId': 'default', 
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveDate': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<UserModel> getUserStream() {
    if (_uid == null) return const Stream.empty();
    return _db.collection('users').doc(_uid).snapshots()
        .map((doc) => UserModel.fromSnapshot(doc));
  }

  Future<void> equipAvatar(String avatarId) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'selectedAvatarId': avatarId,
    });
  }

  // ===========================================================================
  // TASK METHODS
  // ===========================================================================

  Stream<List<Task>> getTasksForDay(DateTime date) {
    if (_uid == null) return const Stream.empty();

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromSnapshot(doc)).toList());
  }

  Future<void> addTask({
    required String title,
    required String category,
    required TaskDifficulty difficulty,
    required TaskPriority priority,
    required DateTime date,
  }) async {
    if (_uid == null) return;
    
    final cleanDate = DateTime(date.year, date.month, date.day);

    final newTask = Task(
      id: '', 
      title: title,
      category: category,
      difficulty: difficulty,
      priority: priority,
      scheduledDate: cleanDate,
    );

    await _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .add(newTask.toMap());
  }

  Future<bool> toggleTaskCompletion(Task task, bool newStatus) async {
    if (_uid == null) return false;

    final userRef = _db.collection('users').doc(_uid);
    final taskRef = userRef.collection('tasks').doc(task.id);

    return await _db.runTransaction<bool>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final taskSnapshot = await transaction.get(taskRef);

      if (!userSnapshot.exists || !taskSnapshot.exists) {
        throw Exception("Data missing");
      }

      final user = UserModel.fromSnapshot(userSnapshot);
      
      int xpDelta = task.xpReward;
      int coinDelta = task.coinReward;

      if (!newStatus) {
        xpDelta = -xpDelta;
        coinDelta = -coinDelta;
      }

      int newXP = user.currentXP + xpDelta;
      int newCoins = user.currentCoins + coinDelta;
      int newLevel = user.currentLevel;

      int xpRequired = newLevel * 500;
      if (newXP >= xpRequired) {
        newLevel++;
        newXP -= xpRequired;
      } else if (newXP < 0 && newLevel > 1) {
        newLevel--;
        newXP += (newLevel * 500);
      }
      
      bool didLevelUp = newLevel > user.currentLevel;

      transaction.update(taskRef, {'isCompleted': newStatus});
      transaction.update(userRef, {
        'currentXP': newXP,
        'currentCoins': newCoins,
        'currentLevel': newLevel,
      });

      return didLevelUp;
    });
  }

  // ===========================================================================
  // SHOP & REWARD METHODS
  // ===========================================================================

  Stream<List<Reward>> getCustomRewards() {
    if (_uid == null) return const Stream.empty();
    
    return _db
        .collection('users')
        .doc(_uid)
        .collection('custom_rewards')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Reward.fromSnapshot(doc)).toList());
  }

  Future<void> addCustomReward(String title, int cost) async {
    if (_uid == null) return;
    
    await _db
        .collection('users')
        .doc(_uid)
        .collection('custom_rewards')
        .add({
          'title': title,
          'cost': cost,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteCustomReward(String rewardId) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('custom_rewards')
        .doc(rewardId)
        .delete();
  }

  Future<String?> purchaseReward(Reward reward) async {
    if (_uid == null) return "User not logged in";

    final userRef = _db.collection('users').doc(_uid);

    try {
      await _db.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw Exception("User not found");

        final user = UserModel.fromSnapshot(userSnapshot);

        if (user.currentCoins < reward.cost) {
          throw Exception("Not enough coins!");
        }

        if (reward.isPreset && user.currentLevel < reward.requiredLevel) {
          throw Exception("Level too low to unlock this!");
        }

        if (reward.isPreset && user.unlockedRewardIds.contains(reward.id)) {
          throw Exception("You already own this item!");
        }

        int newCoins = user.currentCoins - reward.cost;
        
        List<String> newUnlockedIds = List.from(user.unlockedRewardIds);
        if (reward.isPreset) {
          newUnlockedIds.add(reward.id);
        }

        transaction.update(userRef, {
          'currentCoins': newCoins,
          'unlockedRewardIds': newUnlockedIds,
        });
      });
      return null; 
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  // ===========================================================================
  // DAILY ROLLOVER LOGIC
  // ===========================================================================

  Future<String?> checkDailyRollover() async {
    if (_uid == null) return null;

    final userRef = _db.collection('users').doc(_uid);
    final userSnapshot = await userRef.get();
    
    if (!userSnapshot.exists) return null;
    
    final user = UserModel.fromSnapshot(userSnapshot);
    final now = DateTime.now();
    
    final lastActive = (userSnapshot.data() as Map<String, dynamic>)['lastActiveDate'] != null 
        ? (userSnapshot.data() as Map<String, dynamic>)['lastActiveDate'].toDate() 
        : now;

    final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    final currentDay = DateTime(now.year, now.month, now.day);

    if (currentDay.isBefore(lastActiveDay) || currentDay.isAtSameMomentAs(lastActiveDay)) {
      return null;
    }

    final endOfLastActiveDay = DateTime(lastActiveDay.year, lastActiveDay.month, lastActiveDay.day, 23, 59, 59);

    final tasksSnapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(lastActiveDay))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfLastActiveDay))
        .where('isCompleted', isEqualTo: false) 
        .get();

    int totalPenalty = 0;
    int missedCount = 0;

    for (var doc in tasksSnapshot.docs) {
      final task = Task.fromSnapshot(doc);
      
      int penalty = 0;
      switch (task.priority) {
        case TaskPriority.low: penalty = 5; break;
        case TaskPriority.normal: penalty = 15; break;
        case TaskPriority.high: penalty = 30; break;
      }
      totalPenalty += penalty;
      missedCount++;
    }

    await userRef.update({
      'lastActiveDate': FieldValue.serverTimestamp(),
      'currentCoins': (user.currentCoins - totalPenalty).clamp(0, 999999), 
    });

    if (missedCount > 0) {
      return "While you were away, you missed $missedCount tasks and lost $totalPenalty coins.";
    } else {
      return "Welcome back! You had a perfect streak last time.";
    }
  }

  // ===========================================================================
  // DEBUG / SETTINGS METHODS
  // ===========================================================================
  
  // Resets the user's progress for testing/demo purposes
  Future<void> resetAccount() async {
    if (_uid == null) return;
    
    await _db.collection('users').doc(_uid).update({
      'currentLevel': 1,
      'currentXP': 0,
      'currentCoins': 0,
      'unlockedRewardIds': [],
      'selectedAvatarId': 'default',
      // Note: We are NOT deleting tasks here, just resetting stats.
    });
  }
}