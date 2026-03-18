import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🚀 1. Riverpod Provider: Supabase se data mangwane ke liye
final historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  // Database se data fetch karein aur naya data sab se upar dikhayein (ascending: false)
  final response = await supabase
      .from('food_scans')
      .select()
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

// 🎨 2. The UI Screen
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider ko watch karein
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'My Diet History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E2C),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
      ),
      body: historyState.when(
        // ⏳ Jab data load ho raha ho
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),

        // ❌ Jab koi error aaye
        error: (error, stack) => Center(
          child: Text(
            'Error loading history: $error',
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),

        // ✅ Jab data aagaya ho
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "No food scanned yet!",
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          // 📜 Data ko List mein show karein
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

  // 🌟 Premium Card Design for each History Item
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    // Date ko clean format mein laane ke liye
    final DateTime date = DateTime.parse(item['created_at']);
    final String formattedDate = "${date.day}-${date.month}-${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mini Macros
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

  // Chote Macros (Protein, Carbs, Fats) ke tags
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