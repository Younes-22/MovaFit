import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodItem {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    // Open Food Facts varies a lot, so we need safe parsing
    final nutriments = json['nutriments'] ?? {};
    
    return FoodItem(
      name: json['product_name'] ?? 'Unknown Food',
      // API returns kJ or kcal, usually we want kcal
      calories: (nutriments['energy-kcal_100g'] ?? 0).toInt(),
      protein: (nutriments['proteins_100g'] ?? 0).toInt(),
      carbs: (nutriments['carbohydrates_100g'] ?? 0).toInt(),
      fat: (nutriments['fat_100g'] ?? 0).toInt(),
    );
  }
}

class FoodService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';

  // 1. Search by Name
  Future<List<FoodItem>> searchFood(String query) async {
    final url = Uri.parse('$_baseUrl/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1');
    
    try {
      final response = await http.get(url, headers: {'User-Agent': 'Motivafit - Student Project'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List?;
        
        if (products == null) return [];

        return products.map((p) => FoodItem.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      print("Error searching food: $e");
      return [];
    }
  }

  // 2. Search by Barcode
  Future<FoodItem?> getFoodByBarcode(String barcode) async {
    final url = Uri.parse('$_baseUrl/api/v0/product/$barcode.json');

    try {
      final response = await http.get(url, headers: {'User-Agent': 'Motivafit - Student Project'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return FoodItem.fromJson(data['product']);
        }
      }
      return null;
    } catch (e) {
      print("Error scanning barcode: $e");
      return null;
    }
  }
}