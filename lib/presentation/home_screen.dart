import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/food_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⬅️ Provider se data sun-na
    final foodState = ref.watch(foodProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Modern light background
      appBar: AppBar(
        title: Text('NutriLens', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📸 Image Preview Section
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: foodState.selectedImage != null
                      ? Image.file(foodState.selectedImage!, fit: BoxFit.cover)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fastfood_outlined, size: 80, color: Colors.black26),
                      const SizedBox(height: 10),
                      Text("Khane ki tasveer yahan aayegi", style: GoogleFonts.poppins(color: Colors.black38)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ⚙️ Loading, Error, ya Data dikhane ka logic
              if (foodState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (foodState.errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(15)),
                  child: Text(foodState.errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                )
              else if (foodState.foodModel != null)
                  _buildNutritionCard(foodState.foodModel!), // Niche banaya gaya function
            ],
          ),
        ),
      ),

      // 🖲️ Camera aur Gallery ke Buttons
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            heroTag: 'gallery',
            onPressed: () => ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text("Gallery"),
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
          ),
          const SizedBox(width: 20),
          FloatingActionButton.extended(
            heroTag: 'camera',
            onPressed: () => ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text("Camera"),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // 📊 Khubsurat Data Card
  Widget _buildNutritionCard(foodModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Text(foodModel.foodName.toUpperCase(), style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nutritionItem("Calories", "${foodModel.calories} kcal", Colors.orange),
              _nutritionItem("Protein", "${foodModel.protein} g", Colors.redAccent),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nutritionItem("Carbs", "${foodModel.carbs} g", Colors.blue),
              _nutritionItem("Fats", "${foodModel.fats} g", Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutritionItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
      ],
    );
  }
}