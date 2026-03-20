import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import 'providers/daily_goal_provider.dart';

// 🚀 NAYA: Search query ko yaad rakhne ke liye ek chota sa provider
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// Asal provider jo sirf 1 dafa Supabase se data layega
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

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final searchQuery = ref.watch(searchQueryProvider); // 🚀 NAYA: Search word ko watch karein

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Diet History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          historyState.maybeWhen(
            data: (data) => data.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 28),
              onPressed: () => _showClearAllDialog(context, ref),
            )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(child: Text('Error: $error', style: GoogleFonts.poppins(color: AppColors.error))),
        data: (data) {

          // 🚀 JADOO 2: Local Filtering - Data base se aagaya, ab yahin filter karo!
          final filteredData = searchQuery.isEmpty
              ? data
              : data.where((item) => item['food_name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();

          return Column(
            children: [
              // 🔍 🚀 NAYA: Khoobsurat Search Bar (Error Fixed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: "Search your food (e.g. Samosa)",
                      hintStyle: GoogleFonts.poppins(color: AppColors.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textLight),
                        onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                      )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none, // 🚀 Border hata di taake shadow container ki dikhe
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
              ),

              // Agar Data khali hai (ya search result nahi mila)
              if (data.isEmpty || filteredData.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(searchQuery.isEmpty ? Icons.history_rounded : Icons.search_off_rounded, size: 80, color: AppColors.textLight.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        Text(
                            searchQuery.isEmpty ? "No food scanned yet!" : "No matches found for '$searchQuery'",
                            style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textLight)
                        ),
                      ],
                    ),
                  ),
                )
              else
              // Asal List View
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swipe_left_rounded, size: 16, color: AppColors.textLight),
                            const SizedBox(width: 8),
                            Text("Swipe left on any card to delete", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredData.length,
                          itemBuilder: (context, index) {
                            final item = filteredData[index];

                            return Dismissible(
                              key: Key(item['id'].toString()),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                final bool? confirm = await _showDeleteConfirmDialog(context);
                                if (confirm == true) {
                                  await _deleteSingleItem(context, ref, item['id'], item['food_name'].toString());
                                  return true;
                                }
                                return false;
                              },
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(20)),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
                              ),
                              child: _buildHistoryCard(item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // --- Neeche wale saare functions bilkul wese hi hain jaise aapne banaye thay ---

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text('Delete Item?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text('Are you sure you want to delete this food item?', style: GoogleFonts.poppins(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight, fontWeight: FontWeight.w600))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _deleteSingleItem(BuildContext context, WidgetRef ref, dynamic id, String foodName) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('food_scans').delete().eq('id', id);

      ref.invalidate(historyProvider);
      ref.invalidate(dailyGoalProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${foodName.toUpperCase()} deleted!'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        title: Text('Clear All History?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text('Are you sure you want to permanently delete all your scanned food history?', style: GoogleFonts.poppins(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textLight, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllHistory(context, ref);
            },
            child: Text('Delete All', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllHistory(BuildContext context, WidgetRef ref) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        await supabase.from('food_scans').delete().eq('user_id', userId);
        ref.invalidate(historyProvider);
        ref.invalidate(dailyGoalProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All history cleared!'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating));
        }
      }
    } catch (e) {
      debugPrint("Clear All Error: $e");
    }
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final DateTime date = DateTime.parse(item['created_at']);
    final String formattedDate = "${date.day}-${date.month}-${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [Text("${item['calories']}", style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), Text("Kcal", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['food_name'].toString().toUpperCase(), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textLight), const SizedBox(width: 4), Text(formattedDate, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight))]),
                  const SizedBox(height: 8),
                  Row(children: [_buildMiniMacro("P: ${item['protein']}g", Colors.blue), const SizedBox(width: 8), _buildMiniMacro("C: ${item['carbs']}g", Colors.green), const SizedBox(width: 8), _buildMiniMacro("F: ${item['fats']}g", Colors.orange)]),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}