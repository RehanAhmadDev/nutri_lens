import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final weeklyAnalyticsProvider = FutureProvider.autoDispose<Map<String, double>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return {};

  // 📅 Aaj se 7 din pehle ki date nikalna
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  final response = await supabase
      .from('food_scans')
      .select('calories, created_at')
      .eq('user_id', userId)
      .gte('created_at', weekAgo.toIso8601String());

  // 📊 Data ko Days ke hisaab se group karna (Mon, Tue, etc.)
  Map<String, double> dailyTotals = {};

  for (var item in response) {
    DateTime date = DateTime.parse(item['created_at']);
    String dayName = _getDayName(date.weekday);
    dailyTotals[dayName] = (dailyTotals[dayName] ?? 0) + (item['calories'] as num).toDouble();
  }

  return dailyTotals;
});

String _getDayName(int day) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[day - 1];
}