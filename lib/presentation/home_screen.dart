import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🚀 NAYA: Supabase import for logout
import 'providers/food_provider.dart';
import '../../domain/food_model.dart';
import 'history_screen.dart';
import 'auth_screen.dart'; // 🚀 NAYA: AuthScreen import for navigation after logout

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodState = ref.watch(foodProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'NutriLens',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E2C),
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // 📜 History Button
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF4F46E5), size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),

          // 🚪 🚀 Sign Out Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
            onPressed: () async {
              // 🚀 JADOO: Logout hone par Riverpod ki memory (Home screen ka data) clear kar do
              ref.invalidate(foodProvider);

              // 1. Supabase se user ko sign out karein
              await Supabase.instance.client.auth.signOut();

              // 2. Wapis Auth Screen par bhejein aur purani sari screens khatam kar dein
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false, // Yeh pichli history clear kar dega taake user back daba kar wapis na aa sake
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(foodState.selectedImage),
              const SizedBox(height: 32),

              if (foodState.isLoading)
                _buildLoadingState()
              else if (foodState.errorMessage.isNotEmpty)
                _buildErrorState(foodState.errorMessage)
              else if (foodState.foodModel != null)
                  _buildPremiumResultCard(foodState.foodModel!),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildModernActionDock(ref),
    );
  }

  // --- Niche ka sara code waisa hi hai jaisa pehle tha ---

  Widget _buildImagePreview(File? image) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: image != null
            ? Image.file(image, fit: BoxFit.cover, width: double.infinity)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.image_search_rounded, size: 50, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            Text(
              "Upload a food image to analyze",
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const CircularProgressIndicator(color: Color(0xFF4F46E5)),
        const SizedBox(height: 20),
        Text(
          "Analyzing nutritional values...",
          style: GoogleFonts.poppins(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(color: const Color(0xFFB91C1C), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumResultCard(FoodModel food) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          food.foodName.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                "${food.calories}",
                style: GoogleFonts.poppins(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                "Total Calories (Kcal)",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMacroCard("Protein", "${food.protein}g", const Color(0xFF3B82F6), Icons.fitness_center_rounded),
            _buildMacroCard("Carbs", "${food.carbs}g", const Color(0xFF10B981), Icons.grass_rounded),
            _buildMacroCard("Fats", "${food.fats}g", const Color(0xFFF59E0B), Icons.water_drop_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionDock(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1E2C).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.gallery),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(35)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                  SizedBox(height: 4),
                  Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: InkWell(
              onTap: () => ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.camera),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(35)),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24),
                  SizedBox(height: 4),
                  Text("Camera", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}