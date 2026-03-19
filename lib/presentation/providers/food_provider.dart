import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/gemini_service.dart';
import '../../domain/food_model.dart';

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

final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  return FoodNotifier();
});

class FoodNotifier extends StateNotifier<FoodState> {
  FoodNotifier() : super(FoodState());

  final _picker = ImagePicker();
  final _geminiService = GeminiService();
  final _supabase = Supabase.instance.client;

  // 1️⃣ Scan karne ka function
  Future<void> pickImageAndAnalyze(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      state = state.copyWith(
        selectedImage: imageFile,
        isLoading: true,
        errorMessage: '',
        foodModel: null,
      );

      final jsonResponse = await _geminiService.analyzeFoodImage(imageFile);
      String cleanedJson = jsonResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = jsonDecode(cleanedJson);

      final foodData = FoodModel(
        foodName: data['food_name'].toString(),
        calories: int.parse(data['calories'].toString()),
        protein: int.parse(data['protein'].toString()),
        carbs: int.parse(data['carbs'].toString()),
        fats: int.parse(data['fats'].toString()),
      );

      // 🚨 UPDATE: Yahan se Supabase Save wala code nikal diya gaya hai.
      // Ab data direct save nahi hoga, sirf screen par show hoga.
      state = state.copyWith(isLoading: false, foodModel: foodData);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Error: ${e.toString()}",
      );
    }
  }

  // 2️⃣ 🚀 NAYA FUNCTION: Manual Edit/Confirm ke liye (Bilkul sahi jagah par)
  Future<void> saveEditedFood(FoodModel editedFood) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User is not logged in!");

      await _supabase.from('food_scans').insert({
        'user_id': userId,
        'food_name': editedFood.foodName,
        'calories': editedFood.calories,
        'protein': editedFood.protein,
        'carbs': editedFood.carbs,
        'fats': editedFood.fats,
      });

      // ✅ Save hone ke baad State saaf kar dein taake nayi picture ke liye screen ready ho jaye
      state = state.copyWith(foodModel: null, selectedImage: null);

    } catch (e) {
      state = state.copyWith(errorMessage: "Save Error: ${e.toString()}");
    }
  }
}