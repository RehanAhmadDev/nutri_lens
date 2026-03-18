import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/gemini_service.dart';
import '../../domain/food_model.dart';

// 1. State Class: Yeh batayegi ke screen par loading ghumani hai, error dikhana hai, ya data.
class FoodState {
  final bool isLoading;
  final FoodModel? foodModel;
  final File? selectedImage;
  final String errorMessage;

  FoodState({
    this.isLoading = false,
    this.foodModel,
    this.selectedImage,
    this.errorMessage = '',
  });

  FoodState copyWith({
    bool? isLoading,
    FoodModel? foodModel,
    File? selectedImage,
    String? errorMessage,
  }) {
    return FoodState(
      isLoading: isLoading ?? this.isLoading,
      foodModel: foodModel ?? this.foodModel,
      selectedImage: selectedImage ?? this.selectedImage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// 2. Notifier Class: Asli logic yahan chalega
class FoodNotifier extends StateNotifier<FoodState> {
  FoodNotifier() : super(FoodState());

  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();

  // 📸 Tasveer lene aur AI ko bhejne ka function
  Future<void> pickImageAndAnalyze(ImageSource source) async {
    try {
      // Pehle tasveer select karwai
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return; // Agar user ne cancel kar diya

      final File imageFile = File(pickedFile.path);

      // UI ko bataya ke Loading shuru kar do aur purana data clear kar do
      state = state.copyWith(isLoading: true, selectedImage: imageFile, errorMessage: '', foodModel: null);

      // AI ko tasveer bheji
      final String aiResponse = await _geminiService.analyzeFoodImage(imageFile);

      // 🧹 Gemini aksar jawab ke shuru mein ```json aur aakhir mein ``` laga deta hai.
      // Isay saaf karna zaroori hai taake app crash na ho.
      String cleanedJson = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();

      // JSON text ko Dart ke Map mein badla
      final Map<String, dynamic> jsonData = jsonDecode(cleanedJson);

      // Map ko apne FoodModel mein badla
      final FoodModel food = FoodModel.fromJson(jsonData);

      // UI ko bataya ke Loading khatam aur naya data aa gaya hai
      state = state.copyWith(isLoading: false, foodModel: food);

    } catch (e) {
      // Agar koi error aaya toh UI ko error message bhej diya
      state = state.copyWith(isLoading: false, errorMessage: e.toString().replaceAll("Exception: ", ""));
    }
  }
}

// 3. Provider: Jise hum apni UI screens mein use karenge
final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  return FoodNotifier();
});