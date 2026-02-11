import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final int currentLevel;
  final int currentXP;
  final int currentCoins;
  final List<String> unlockedRewardIds;
  final String selectedAvatarId; // <--- NEW FIELD

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.currentLevel = 1,
    this.currentXP = 0,
    this.currentCoins = 0,
    this.unlockedRewardIds = const [],
    this.selectedAvatarId = 'default', // Default avatar
  });

  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? 'User',
      currentLevel: data['currentLevel'] ?? 1,
      currentXP: data['currentXP'] ?? 0,
      currentCoins: data['currentCoins'] ?? 0,
      unlockedRewardIds: List<String>.from(data['unlockedRewardIds'] ?? []),
      selectedAvatarId: data['selectedAvatarId'] ?? 'default',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'currentLevel': currentLevel,
      'currentXP': currentXP,
      'currentCoins': currentCoins,
      'unlockedRewardIds': unlockedRewardIds,
      'selectedAvatarId': selectedAvatarId,
      'lastActiveDate': FieldValue.serverTimestamp(),
    };
  }
}