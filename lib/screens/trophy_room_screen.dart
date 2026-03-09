import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class TrophyRoomScreen extends StatelessWidget {
  const TrophyRoomScreen({super.key});

  // Helper method to get the color based on badge rarity
  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.blueGrey;
      case BadgeRarity.rare:
        return Colors.blueAccent;
      case BadgeRarity.legendary:
        return Colors.amber;
    }
  }

  // Helper method to show badge details in a popup
  void _showBadgeDetails(BuildContext context, BadgeModel badge, bool isUnlocked) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Icon(
                isUnlocked ? badge.icon : Icons.lock,
                size: 60,
                color: isUnlocked ? _getRarityColor(badge.rarity) : Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                isUnlocked ? badge.name : 'Locked Badge',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            badge.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trophy Room', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel>(
        stream: FirestoreService().getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Unable to load badges."));
          }

          final user = snapshot.data!;
          final earnedBadgeIds = user.earnedBadges;

          return Column(
            children: [
              // Header Summary
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(
                      '${earnedBadgeIds.length} / ${BadgeModel.allBadges.length}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const Text('Badges Unlocked', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              // The Badge Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 badges per row
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.8, // Make the cards slightly taller than they are wide
                  ),
                  itemCount: BadgeModel.allBadges.length,
                  itemBuilder: (context, index) {
                    final badge = BadgeModel.allBadges[index];
                    final isUnlocked = earnedBadgeIds.contains(badge.id);

                    return GestureDetector(
                      onTap: () => _showBadgeDetails(context, badge, isUnlocked),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked 
                              ? _getRarityColor(badge.rarity).withOpacity(0.1) 
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isUnlocked 
                                ? _getRarityColor(badge.rarity).withOpacity(0.5) 
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUnlocked ? badge.icon : Icons.lock,
                              size: 40,
                              color: isUnlocked 
                                  ? _getRarityColor(badge.rarity) 
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                isUnlocked ? badge.name : '???',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked 
                                      ? Theme.of(context).textTheme.bodyLarge?.color 
                                      : Colors.grey.shade500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}