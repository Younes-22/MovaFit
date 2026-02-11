import 'package:cloud_firestore/cloud_firestore.dart';

class Reward {
  final String id;
  final String title;
  final int cost;
  final int requiredLevel; 
  final bool isPreset; // true = Permanent Unlock (Avatar), false = Consumable (Custom)

  Reward({
    required this.id,
    required this.title,
    required this.cost,
    this.requiredLevel = 0,
    this.isPreset = false,
  });

  // --- Static List of App Rewards ---
  static List<Reward> get presetRewards => [
    // NEW: Test Avatar for Level 1
    Reward(id: 'avatar_novice', title: 'Green Novice Avatar', cost: 50, requiredLevel: 1, isPreset: true),
    
    Reward(id: 'theme_dark', title: 'Dark Mode', cost: 0, requiredLevel: 1, isPreset: true),
    Reward(id: 'avatar_blue', title: 'Blue Warrior Avatar', cost: 100, requiredLevel: 2, isPreset: true),
    Reward(id: 'avatar_gold', title: 'Gold Champion Avatar', cost: 500, requiredLevel: 5, isPreset: true),
    Reward(id: 'theme_neon', title: 'Neon Theme', cost: 1000, requiredLevel: 10, isPreset: true),
  ];

  // --- Firestore Serialization (For Custom Rewards) ---
  factory Reward.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reward(
      id: doc.id,
      title: data['title'] ?? 'Unknown Reward',
      cost: data['cost'] ?? 0,
      requiredLevel: 0, 
      isPreset: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'cost': cost,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}