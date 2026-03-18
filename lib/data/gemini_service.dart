import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/api_constants.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // 🚀 Yahan hum ne aap ka naya model laga diya hai jo browser mein show hua!
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  Future<String> analyzeFoodImage(File imageFile) async {
    try {
      print("🚀 STEP 1: Tasveer read ho rahi hai...");
      final imageBytes = await imageFile.readAsBytes();
      print("✅ STEP 2: Tasveer bytes convert ho gayin.");

      final imageParts = [
        DataPart('image/jpeg', imageBytes),
      ];

      final prompt = TextPart('''
        Aap ek expert nutritionist hain. Is tasveer ko dekhein aur is mein mojood khane ko pehchanein.
        Mujhe sirf aur sirf ek JSON object format mein jawab dein, koi izafi text na likhein.
        JSON format yeh hona chahiye:
        {
          "food_name": "Khane ka naam",
          "calories": Total estimated calories (integer),
          "protein": Protein in grams (integer),
          "carbs": Carbohydrates in grams (integer),
          "fats": Fats in grams (integer)
        }
      ''');

      print("⏳ STEP 3: AI ko data bheja ja raha hai (gemini-2.5-flash)...");
      final response = await _model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);

      print("🎉 STEP 4: AI ka jawab aa gaya!");
      if (response.text != null) {
        print("🤖 AI Ka Jawab: ${response.text}");
        return response.text!;
      } else {
        throw Exception("AI ne koi jawab nahi diya.");
      }
    } catch (e) {
      print("❌❌❌ ASLI ERROR: ❌❌❌");
      print(e.toString());
      throw Exception("Masla: $e");
    }
  }
}