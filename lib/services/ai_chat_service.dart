import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';
import '../models/nutrition_model.dart';

class AIChatService {
  // This looks for the key passed during the 'flutter run' command
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final GenerativeModel _model;

  AIChatService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash', 
          apiKey: _apiKey,
        );

  Future<String> getMealSuggestion({
    required UserModel user,
    required NutritionDay todayNutrition,
    required String userQuery,
  }) async {
    // Safety check if the key is missing
    if (_apiKey.isEmpty) {
      return "Error: API Key is missing. Did you set up the environment variable?";
    }

    final remainingCals = user.calorieGoal - todayNutrition.calories;
    final diet = user.dietaryRestrictions.join(', ');

    // --- UPDATED SYSTEM PROMPT TO INCLUDE USERNAME ---
    final systemPrompt = """
    You are a professional nutritionist for the app 'MotivaFit'. 
    CONTEXT:
    - User Name: ${user.username}
    - User Fitness Goal: ${user.fitnessGoal}
    - Dietary Restrictions: ${diet.isEmpty ? 'None' : diet}
    - Remaining Daily Calories: $remainingCals
    
    STRICT GUIDELINES:
    1. If user is 'Halal', do not suggest pork or alcohol.
    2. Avoid all listed allergies: $diet.
    3. Keep suggestions within $remainingCals calories.
    4. Be concise and professional.
    5. Address the user by their name (${user.username}) occasionally to make the conversation friendly and personalized.
    """;

    try {
      final content = [Content.text("$systemPrompt\n\nUser: $userQuery")];
      final response = await _model.generateContent(content);
      return response.text ?? "I'm sorry, I couldn't generate a suggestion.";
    } catch (e) {
      return "DEBUG ERROR: ${e.toString()}";
    }
  }
}