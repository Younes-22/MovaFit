class Reward {
  final String id;
  final String name;
  final int coinCost;
  final int minLevelRequired; // 1 for basic items
  final bool isUserDefined;   // True = "Netflix", False = "App Avatar"

  Reward({
    required this.id,
    required this.name,
    required this.coinCost,
    this.minLevelRequired = 1,
    this.isUserDefined = true,
  });
}