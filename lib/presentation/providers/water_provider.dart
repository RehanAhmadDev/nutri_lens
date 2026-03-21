import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterState {
  final int consumedGlasses;
  final int dailyGoal; // 🚀 Ab yeh Profile se update hoga
  final Map<String, int> waterHistory;

  WaterState({
    this.consumedGlasses = 0,
    this.dailyGoal = 8, // Default 8 hai
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
    _loadWaterData(); // App khulte hi history aur goal load karo
  }

  String get _today => DateTime.now().toString().split(' ')[0];

  // 1️⃣ Phone ki memory se HISTORY aur GOAL load karna
  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();

    // Custom Goal load karo (agar kisi ne profile mein set kiya tha), warna 8
    final savedGoal = prefs.getInt('water_goal') ?? 8;

    final historyString = prefs.getString('water_history') ?? '{}';
    final Map<String, dynamic> decodedMap = jsonDecode(historyString);
    final Map<String, int> history = decodedMap.map((key, value) => MapEntry(key, value as int));

    final todayGlasses = history[_today] ?? 0;

    // 🚀 State update karo (Consumed glasses, History, aur Naya Goal)
    state = state.copyWith(
      consumedGlasses: todayGlasses,
      waterHistory: history,
      dailyGoal: savedGoal,
    );
  }

  // 2️⃣ History ko update karna
  Future<void> _saveWaterData(int glasses) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> newHistory = Map.from(state.waterHistory);
    newHistory[_today] = glasses;
    await prefs.setString('water_history', jsonEncode(newHistory));

    state = state.copyWith(consumedGlasses: glasses, waterHistory: newHistory);
  }

  // ⚙️ 🚀 NAYA: Profile screen se jab naya goal set ho, toh usay update aur save karo
  Future<void> updateDailyGoal(int newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal', newGoal); // Phone mein hamesha ke liye save

    // Foran UI ko update karo
    state = state.copyWith(dailyGoal: newGoal);
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