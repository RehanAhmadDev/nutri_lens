import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart'; // 🎨 NAYA: AppColors import kiya hai

// 🚀 1. Riverpod Provider
final historyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  final response = await supabase
      .from('food_scans')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

// 🎨 2. The UI Screen
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background, // 🎨 Updated
      appBar: AppBar(
        title: Text(
          'My Diet History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark, // 🎨 Updated
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark), // 🎨 Updated
      ),
      body: historyState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary), // 🎨 Updated
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading history: $error',
            style: GoogleFonts.poppins(color: AppColors.error), // 🎨 Updated
          ),
        ),
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: AppColors.textLight.withOpacity(0.4)), // 🎨 Updated
                  const SizedBox(height: 16),
                  Text(
                    "No food scanned yet!",
                    style: GoogleFonts.poppins(fontSize: 18, color: AppColors.textLight), // 🎨 Updated
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildHistoryCard(item);
            },
          );
        },
      ),
    );
  }

  // 🌟 Premium Card Design
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final DateTime date = DateTime.parse(item['created_at']);
    final String formattedDate = "${date.day}-${date.month}-${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardColor, // 🎨 Updated
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Side: Calories Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary], // 🎨 Updated
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "${item['calories']}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Kcal",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Side: Food Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['food_name'].toString().toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark, // 🎨 Updated
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textLight), // 🎨 Updated
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textLight, // 🎨 Updated
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mini Macros (Colors untouched for semantics)
                  Row(
                    children: [
                      _buildMiniMacro("P: ${item['protein']}g", Colors.blue),
                      const SizedBox(width: 8),
                      _buildMiniMacro("C: ${item['carbs']}g", Colors.green),
                      const SizedBox(width: 8),
                      _buildMiniMacro("F: ${item['fats']}g", Colors.orange),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMacro(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}