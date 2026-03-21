import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/food_provider.dart';
import 'providers/daily_goal_provider.dart';
import 'providers/weekly_analytics_provider.dart';
import 'providers/water_provider.dart'; // 💧 NAYA: Water Provider import kiya
import '../../domain/food_model.dart';
import 'history_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import '../utils/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(foodProvider, (previous, next) {
      if (!next.isLoading && next.foodModel != null) {
        ref.invalidate(dailyGoalProvider);
        ref.invalidate(weeklyAnalyticsProvider);
      }
    });

    final foodState = ref.watch(foodProvider);
    final dailyCaloriesState = ref.watch(dailyGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 28),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            ref.invalidate(dailyGoalProvider);
          },
        ),
        title: Text('NutriLens', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
              );
              ref.invalidate(weeklyAnalyticsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary, size: 28),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
              ref.invalidate(dailyGoalProvider);
              ref.invalidate(weeklyAnalyticsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
            onPressed: () async {
              ref.invalidate(foodProvider);
              ref.invalidate(dailyGoalProvider);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyGoalProvider);
          ref.invalidate(weeklyAnalyticsProvider);
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGoalTracker(dailyCaloriesState),
                const SizedBox(height: 20), // Thoda gap diya
                _buildWaterTracker(context, ref), // 💧 NAYA: Water Tracker Yahan Add Kiya
                const SizedBox(height: 32),
                _buildImagePreview(foodState.selectedImage),
                const SizedBox(height: 32),
                if (foodState.isLoading) _buildLoadingState()
                else if (foodState.errorMessage.isNotEmpty) _buildErrorState(foodState.errorMessage)
                else if (foodState.foodModel != null) _buildPremiumResultCard(context, ref, foodState.foodModel!),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildModernActionDock(ref),
    );
  }

  // 💧 🚀 NAYA FUNCTION: Water Tracker ka Khubsurat UI
  Widget _buildWaterTracker(BuildContext context, WidgetRef ref) {
    final waterState = ref.watch(waterProvider);
    final waterNotifier = ref.read(waterProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FF), // Halka Neela (Light Blue) background
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF90CDF4), width: 1.5), // Neeli border
        boxShadow: [BoxShadow(color: const Color(0xFF4299E1).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop_rounded, color: Color(0xFF3182CE), size: 28),
                  const SizedBox(width: 8),
                  Text("Water Tracker", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2B6CB0))),
                ],
              ),
              Text(
                "${waterState.consumedGlasses} / ${waterState.dailyGoal} Glasses",
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF3182CE)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Glasses Row (Icons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(waterState.dailyGoal, (index) {
              bool isFilled = index < waterState.consumedGlasses;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    isFilled ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                    color: isFilled ? const Color(0xFF3182CE) : const Color(0xFF90CDF4),
                    size: 26,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => waterNotifier.removeGlass(),
                icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE53E3E), size: 30),
                tooltip: "Remove Glass",
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (waterState.consumedGlasses < waterState.dailyGoal) {
                    waterNotifier.addGlass();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily Water Goal Completed! 💧🎉'), backgroundColor: Color(0xFF3182CE)));
                  }
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text("Drink Water", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182CE),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTracker(AsyncValue<int> dailyCaloriesState) {
    final user = Supabase.instance.client.auth.currentUser;
    final int dailyGoal = user?.userMetadata?['daily_goal'] ?? 2000;

    return dailyCaloriesState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stack) => const SizedBox.shrink(),
      data: (consumedCalories) {
        double progress = consumedCalories / dailyGoal;
        if (progress > 1.0) progress = 1.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: AppColors.textLight.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeCap: StrokeCap.round
                    ),
                    Center(child: Icon(progress >= 1.0 ? Icons.local_fire_department_rounded : Icons.restaurant_rounded, color: progress >= 1.0 ? Colors.orange : AppColors.primary, size: 30)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Daily Goal", style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text("$consumedCalories / $dailyGoal", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text("Kcal consumed today", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePreview(File? image) {
    return Container(height: 300, decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8))]), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: image != null ? Image.file(image, fit: BoxFit.cover, width: double.infinity) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFF0F4FF), shape: BoxShape.circle), child: const Icon(Icons.image_search_rounded, size: 50, color: Color(0xFF6B7280))), const SizedBox(height: 20), Text("Upload a food image to analyze", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 15, fontWeight: FontWeight.w500))])));
  }

  Widget _buildLoadingState() {
    return Column(children: [const SizedBox(height: 30), const CircularProgressIndicator(color: AppColors.primary), const SizedBox(height: 20), Text("Analyzing nutritional values...", style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16))]);
  }

  Widget _buildErrorState(String error) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFCA5A5))), child: Row(children: [const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32), const SizedBox(width: 16), Expanded(child: Text(error, style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w500)))]));
  }

  Widget _buildPremiumResultCard(BuildContext context, WidgetRef ref, FoodModel food) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(food.foodName.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: 1.0)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text("${food.calories}", style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
              Text("Total Calories (Kcal)", style: GoogleFonts.poppins(fontSize: 15, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
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
        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () => _showEditDialog(context, ref, food),
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                label: Text("Edit", style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(foodProvider.notifier).saveEditedFood(food);
                  ref.invalidate(dailyGoalProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Diary! ✅'), backgroundColor: AppColors.success));
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text("Save to Diary", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 5,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard(String title, String value, Color color, IconData icon) {
    return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 6), padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8), decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]), child: Column(children: [Icon(icon, color: color, size: 30), const SizedBox(height: 12), Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)), const SizedBox(height: 2), Text(title, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w500))])));
  }

  Widget _buildModernActionDock(WidgetRef ref) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 40), height: 70, decoration: BoxDecoration(color: AppColors.textDark, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: AppColors.textDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Expanded(child: InkWell(onTap: () => ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.gallery), borderRadius: const BorderRadius.horizontal(left: Radius.circular(35)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_library_rounded, color: Colors.white, size: 24), SizedBox(height: 4), Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]))), Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)), Expanded(child: InkWell(onTap: () => ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.camera), borderRadius: const BorderRadius.horizontal(right: Radius.circular(35)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24), SizedBox(height: 4), Text("Camera", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))])))]));
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, FoodModel currentFood) {
    final nameController = TextEditingController(text: currentFood.foodName);
    final caloriesController = TextEditingController(text: currentFood.calories.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Edit Details", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Food Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Calories (Kcal)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newCal = int.tryParse(caloriesController.text.trim()) ?? currentFood.calories;

                final updatedFood = FoodModel(
                  foodName: newName,
                  calories: newCal,
                  protein: currentFood.protein,
                  carbs: currentFood.carbs,
                  fats: currentFood.fats,
                );

                await ref.read(foodProvider.notifier).saveEditedFood(updatedFood);
                ref.invalidate(dailyGoalProvider);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated & Saved! ✨'), backgroundColor: AppColors.success));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text("Save", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}