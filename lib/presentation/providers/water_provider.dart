import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterState {
  final int consumedGlasses;
  final int dailyGoal;
  final Map<String, int> waterHistory; // 🚀 NAYA: Pichle tamaam dino ka record

  WaterState({
    this.consumedGlasses = 0,
    this.dailyGoal = 8,
    this.waterHistory = const {},
  });

  WaterState copyWith({
    int? consumedGlasses,
    int? dailyGoal,
    Map<String, int>? waterHistory
  }) {
    return WaterState(
      consumedGlasses: consumedGlasses ?? this.consumedGlasses,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      waterHistory: waterHistory ?? this.waterHistory,
    );
  }
}

final waterProvider = StateNotifierProvider<WaterNotifier, WaterState>((ref) {
  return WaterNotifier();
});

class WaterNotifier extends StateNotifier<WaterState> {
  WaterNotifier() : super(WaterState()) {
    _loadWaterData(); // App khulte hi history load karo
  }

  // Aaj ki date nikalne ka shortcut (Format: yyyy-mm-dd)
  String get _today => DateTime.now().toString().split(' ')[0];

  // 1️⃣ Phone ki memory se poori HISTORY load karna
  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();

    // Memory se purana JSON data nikalo, agar nahi hai toh khali '{}' de do
    final historyString = prefs.getString('water_history') ?? '{}';
    final Map<String, dynamic> decodedMap = jsonDecode(historyString);

    // Dynamic map ko proper Map<String, int> mein badlo
    final Map<String, int> history = decodedMap.map((key, value) => MapEntry(key, value as int));

    // Aaj ke din ka paani check karo (agar aaj kuch nahi piya toh 0)
    final todayGlasses = history[_today] ?? 0;

    // State ko update karo
    state = state.copyWith(consumedGlasses: todayGlasses, waterHistory: history);
  }

  // 2️⃣ History ko update karna aur Memory mein Save karna
  Future<void> _saveWaterData(int glasses) async {
    final prefs = await SharedPreferences.getInstance();

    // Purani history ki ek copy banao
    final Map<String, int> newHistory = Map.from(state.waterHistory);

    // Aaj ki date mein naye glasses update karo
    newHistory[_today] = glasses;

    // JSON format mein memory mein lock (save) kar do
    await prefs.setString('water_history', jsonEncode(newHistory));

    // Screen (UI) ko update karne ke liye state change karo
    state = state.copyWith(consumedGlasses: glasses, waterHistory: newHistory);
  }

  // 💧 Glass add karna
  void addGlass() {
    if (state.consumedGlasses < state.dailyGoal) {
      _saveWaterData(state.consumedGlasses + 1);
    }
  }

  // ❌ Glass remove karna
  void removeGlass() {
    if (state.consumedGlasses > 0) {
      _saveWaterData(state.consumedGlasses - 1);
    }
  }

  // 🔄 Manual reset
  void resetWater() {
    _saveWaterData(0);
  }
}