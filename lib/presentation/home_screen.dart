import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/food_provider.dart';
import 'providers/daily_goal_provider.dart';
import 'providers/weekly_analytics_provider.dart';
import 'providers/water_provider.dart';
import '../../domain/food_model.dart';
import 'history_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import '../utils/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Logout", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text("Are you sure you want to sign out?", style: GoogleFonts.poppins(color: AppColors.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: AppColors.textLight, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              ref.invalidate(foodProvider);
              ref.invalidate(dailyGoalProvider);
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Logout", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(foodProvider, (previous, next) {
      if (!next.isLoading && next.foodModel != null) {
        ref.invalidate(dailyGoalProvider);
        ref.invalidate(weeklyAnalyticsProvider);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });

    final foodState = ref.watch(foodProvider);
    final dailyCaloriesState = ref.watch(dailyGoalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            ref.invalidate(dailyGoalProvider);
          },
        ),
        title: Text('NutriLens', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: 0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 26),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
              ref.invalidate(weeklyAnalyticsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary, size: 26),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
              ref.invalidate(dailyGoalProvider);
              ref.invalidate(weeklyAnalyticsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            onPressed: _showLogoutDialog,
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
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGoalTracker(dailyCaloriesState),
                const SizedBox(height: 20),
                _buildWaterTracker(context, ref),
                const SizedBox(height: 24),
                _buildImagePreview(foodState.selectedImage),
                const SizedBox(height: 32),
                if (foodState.isLoading) _buildLoadingState()
                else if (foodState.errorMessage.isNotEmpty) _buildErrorState(foodState.errorMessage)
                else if (foodState.foodModel != null) _buildPremiumResultCard(context, ref, foodState.foodModel!),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildModernActionDock(ref),
    );
  }

  Widget _buildGoalTracker(AsyncValue<int> dailyCaloriesState) {
    return dailyCaloriesState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, stack) => const SizedBox.shrink(),
      data: (consumedCalories) {
        final user = Supabase.instance.client.auth.currentUser;
        final int dailyGoal = user?.userMetadata?['daily_goal'] ?? 2000;
        double progress = consumedCalories / dailyGoal;
        if (progress > 1.0) progress = 1.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              SizedBox(
                height: 75, width: 75,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                        value: progress, strokeWidth: 8,
                        backgroundColor: AppColors.textLight.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeCap: StrokeCap.round
                    ),
                    Center(child: Icon(progress >= 1.0 ? Icons.local_fire_department_rounded : Icons.restaurant_rounded, color: progress >= 1.0 ? Colors.orange : AppColors.primary, size: 28)),
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

  Widget _buildWaterTracker(BuildContext context, WidgetRef ref) {
    final waterState = ref.watch(waterProvider);
    final waterNotifier = ref.read(waterProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF8FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF90CDF4), width: 1.5),
        boxShadow: [BoxShadow(color: const Color(0xFF4299E1).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop_rounded, color: Color(0xFF3182CE), size: 24),
                  const SizedBox(width: 8),
                  Text("Water Tracker", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2B6CB0))),
                ],
              ),
              Text("${waterState.consumedGlasses} / ${waterState.dailyGoal}", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3182CE))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(waterState.dailyGoal, (index) {
              bool isFilled = index < waterState.consumedGlasses;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(isFilled ? Icons.local_drink_rounded : Icons.local_drink_outlined, color: isFilled ? const Color(0xFF3182CE) : const Color(0xFF90CDF4), size: 24),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () { HapticFeedback.lightImpact(); waterNotifier.removeGlass(); },
                icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE53E3E), size: 28),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  if (waterState.consumedGlasses < waterState.dailyGoal) {
                    waterNotifier.addGlass();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily Water Goal Completed! 💧🎉'), backgroundColor: Color(0xFF3182CE)));
                  }
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                label: Text("Drink", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182CE),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File? image) {
    return Container(
        height: 260,
        decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))]
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: image != null
                ? Image.file(image, fit: BoxFit.cover, width: double.infinity)
                : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), shape: BoxShape.circle), child: Icon(Icons.image_search_rounded, size: 40, color: AppColors.primary.withOpacity(0.6))),
                  const SizedBox(height: 16),
                  Text("Upload a food image", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w500))
                ]
            )
        )
    );
  }

  Widget _buildLoadingState() => Column(children: [const SizedBox(height: 30), const CircularProgressIndicator(color: AppColors.primary), const SizedBox(height: 20), Text("Analyzing...", style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600))]);

  Widget _buildErrorState(String error) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)), child: Text(error, style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w500)));

  Widget _buildPremiumResultCard(BuildContext context, WidgetRef ref, FoodModel food) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(food.foodName.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]), borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 4),
                Text("${food.calories}", style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                Text("Kcal", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
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
          const SizedBox(height: 24),

          // 🚀 NAYA: Clear, Edit aur Save Buttons ka Row
          Row(
            children: [
              // ❌ Clear Button
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(foodProvider); // Sab kuch reset kar dega
                  },
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 12),

              // ✏️ Edit Button
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => _showEditDialog(context, ref, food),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  child: const Icon(Icons.edit_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),

              // ✅ Save Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(foodProvider.notifier).saveEditedFood(food);
                    ref.invalidate(dailyGoalProvider);
                    ref.invalidate(foodProvider); // Save hone ke baad khud clear ho jayega
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Diary! ✅'), backgroundColor: AppColors.success));
                  },
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  label: Text("Save", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String title, String value, Color color, IconData icon) {
    return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)), Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600))])));
  }

  // 🚀 THEME MATCHING DOCK: Ab yeh app ke original colors (Primary/Secondary Gradient) use kar raha hai
  Widget _buildModernActionDock(WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      height: 65,
      decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary], // 🎨 Theme ke sath 100% Match
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10)
            )
          ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: InkWell(onTap: () { HapticFeedback.lightImpact(); ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.gallery); }, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_library_rounded, color: Colors.white, size: 22), SizedBox(height: 2), Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]))),
          Container(width: 1, height: 35, color: Colors.white.withOpacity(0.3)),
          Expanded(child: InkWell(onTap: () { HapticFeedback.lightImpact(); ref.read(foodProvider.notifier).pickImageAndAnalyze(ImageSource.camera); }, child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22), SizedBox(height: 2), Text("Camera", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]))),
        ],
      ),
    );
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
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Food Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(controller: caloriesController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Calories (Kcal)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: AppColors.textLight))),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final newCal = int.tryParse(caloriesController.text.trim()) ?? currentFood.calories;
                await ref.read(foodProvider.notifier).saveEditedFood(FoodModel(foodName: newName, calories: newCal, protein: currentFood.protein, carbs: currentFood.carbs, fats: currentFood.fats));
                ref.invalidate(dailyGoalProvider);
                if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated & Saved! ✨'), backgroundColor: AppColors.success)); }
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