import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/gemini_service.dart';
import '../../domain/food_model.dart';

// State Class: To manage the UI state (Loading, Error, Data, Image)
class FoodState {
  final File? selectedImage;
  final bool isLoading;
  final String errorMessage;
  final FoodModel? foodModel;

  FoodState({
    this.selectedImage,
    this.isLoading = false,
    this.errorMessage = '',
    this.foodModel,
  });

  FoodState copyWith({
    File? selectedImage,
    bool? isLoading,
    String? errorMessage,
    FoodModel? foodModel,
  }) {
    return FoodState(
      selectedImage: selectedImage ?? this.selectedImage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      foodModel: foodModel ?? this.foodModel,
    );
  }
}

// Provider initialization
final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  return FoodNotifier();
});

// Notifier Class: Contains the core logic
class FoodNotifier extends StateNotifier<FoodState> {
  FoodNotifier() : super(FoodState());

  final _picker = ImagePicker();
  final _geminiService = GeminiService();

  // Initialize Supabase Client
  final _supabase = Supabase.instance.client;

  Future<void> pickImageAndAnalyze(ImageSource source) async {
    try {
      // 1. Pick Image from Camera or Gallery
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      // 2. Set UI to Loading State
      state = state.copyWith(
        selectedImage: imageFile,
        isLoading: true,
        errorMessage: '',
        foodModel: null, // Clear previous results
      );

      // 3. Send image to Gemini API
      final jsonResponse = await _geminiService.analyzeFoodImage(imageFile);

      // 4. Clean the JSON string (in case Gemini adds markdown like ```json ... ```)
      String cleanedJson = jsonResponse.replaceAll('```json', '').replaceAll('```', '').trim();

      // 5. Parse JSON into FoodModel
      final Map<String, dynamic> data = jsonDecode(cleanedJson);
      final foodData = FoodModel(
        foodName: data['food_name'].toString(),
        calories: int.parse(data['calories'].toString()),
        protein: int.parse(data['protein'].toString()),
        carbs: int.parse(data['carbs'].toString()),
        fats: int.parse(data['fats'].toString()),
      );

      // 6. 🚀 SAVE TO SUPABASE DATABASE 🚀
      await _supabase.from('food_scans').insert({
        'food_name': foodData.foodName,
        'calories': foodData.calories,
        'protein': foodData.protein,
        'carbs': foodData.carbs,
        'fats': foodData.fats,
      });

      print("✅ SUCCESS: Data saved to Supabase securely!");

      // 7. Update UI with the final result
      state = state.copyWith(
        isLoading: false,
        foodModel: foodData,
      );

    } catch (e) {
      // Handle any errors gracefully
      print("❌ ERROR: ${e.toString()}");
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Something went wrong. Please try again with a clear picture.",
      );
    }
  }
}