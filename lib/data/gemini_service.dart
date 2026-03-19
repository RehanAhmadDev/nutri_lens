import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/api_constants.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // 🚀 Aap ka apna latest model!
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

      // 🧠 NAYA SMART PROMPT (Quantity aur Total Calories ke liye)
      final prompt = TextPart('''
        Aap ek expert AI nutritionist hain. Is tasveer ko dekhein aur is mein mojood khane ko pehchanein.

        ⚠️ ZAROORI HIDAYAT (QUANTITY KE LIYE):
        1. Agar tasveer mein ek hi cheez ke multiple items hain (maslan 5 samosay, 3 apple), toh 'food_name' ke andar quantity aur 1 piece ki calories zaroor likhein. 
           Example: "Samosa (x5 pieces - 200 Kcal each)"
        2. Agar single item hai toh sirf naam likhein. Example: "Apple"
        3. Niche di gayi 'calories', 'protein', 'carbs', aur 'fats' ki values mein tasveer mein mojood TAMAM items ka GRAND TOTAL jama kar ke (integer mein) likhein.

        Mujhe sirf aur sirf ek JSON object format mein jawab dein, koi izafi text, markdown ya backticks (```) na likhein.
        JSON format exact yeh hona chahiye:
        {
          "food_name": "Khane ka naam (Quantity ke sath agar 1 se zyada hain)",
          "calories": Total estimated calories sab ka mila kar (integer),
          "protein": Total Protein in grams (integer),
          "carbs": Total Carbohydrates in grams (integer),
          "fats": Total Fats in grams (integer)
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