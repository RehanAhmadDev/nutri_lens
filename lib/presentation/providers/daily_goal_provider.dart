import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🚀 NAYA: Aaj ki calories calculate karne wala jadoo!
final dailyGoalProvider = FutureProvider.autoDispose<int>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  // Agar user nahi hai toh 0 bhej do
  if (userId == null) return 0;

  // 🕒 Aaj ke din ki shuruwat ka time nikalein (Midnight 12:00 AM)
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

  // 🗄️ Database se sirf "Aaj" ka data fetch karein
  final response = await supabase
      .from('food_scans')
      .select('calories')
      .eq('user_id', userId)
      .gte('created_at', startOfDay); // gte = Greater Than or Equal (Yani aaj ke din shuru hone ke baad ka data)

  // ➕ Saari calories ko aapas mein jama (sum) karein
  int totalCaloriesToday = 0;
  for (var item in response) {
    totalCaloriesToday += (item['calories'] as num).toInt();
  }

  return totalCaloriesToday; // Total sum wapis bhej dein
});