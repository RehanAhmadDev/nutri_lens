import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterState {
  final int consumedGlasses;
  final int dailyGoal;

  WaterState({
    this.consumedGlasses = 0,
    this.dailyGoal = 8,
  });

  WaterState copyWith({int? consumedGlasses, int? dailyGoal}) {
    return WaterState(
      consumedGlasses: consumedGlasses ?? this.consumedGlasses,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier();
});

class WaterNotifier extends StateNotifier<WaterState> {
  WaterNotifier() : super(WaterState()) {
    _loadWaterData(); // 🚀 App khulte hi memory se data load karega
  }

  // 1️⃣ Phone ki memory se aaj ka paani check karna
  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('water_date') ?? '';
    final today = DateTime.now().toString().split(' ')[0]; // Format: yyyy-mm-dd

    if (savedDate == today) {
      // Agar aaj ka hi din hai, toh purane glasses wapis screen par le aao
      final glasses = prefs.getInt('water_glasses') ?? 0;
      state = state.copyWith(consumedGlasses: glasses);
    } else {
      // Naya din shuru ho gaya hai, memory mein 0 save kar do
      _saveWaterData(0, today);
    }
  }

  // 2️⃣ Memory mein data save karna
  Future<void> _saveWaterData(int glasses, String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_glasses', glasses);
    await prefs.setString('water_date', date);
  }

  // 💧 Glass add karna aur memory mein save karna
  void addGlass() {
    if (state.consumedGlasses < state.dailyGoal) {
      final newValue = state.consumedGlasses + 1;
      state = state.copyWith(consumedGlasses: newValue);
      _saveWaterData(newValue, DateTime.now().toString().split(' ')[0]);
    }
  }

  // ❌ Glass remove karna aur memory mein save karna
  void removeGlass() {
    if (state.consumedGlasses > 0) {
      final newValue = state.consumedGlasses - 1;
      state = state.copyWith(consumedGlasses: newValue);
      _saveWaterData(newValue, DateTime.now().toString().split(' ')[0]);
    }
  }

  // 🔄 Manual reset (agar kabhi zarurat pare)
  void resetWater() {
    state = state.copyWith(consumedGlasses: 0);
    _saveWaterData(0, DateTime.now().toString().split(' ')[0]);
  }
}