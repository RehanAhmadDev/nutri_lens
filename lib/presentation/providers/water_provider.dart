import 'package:flutter_riverpod/flutter_riverpod.dart';

class WaterState {
  final int consumedGlasses;
  final int dailyGoal; // Default 8 glasses (taqreeban 2 Liters)

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
  WaterNotifier() : super(WaterState());

  // Pani ka glass add karna 💧
  void addGlass() {
    if (state.consumedGlasses < state.dailyGoal) {
      state = state.copyWith(consumedGlasses: state.consumedGlasses + 1);
    }
  }

  // Galti se add ho jaye toh remove karna ❌
  void removeGlass() {
    if (state.consumedGlasses > 0) {
      state = state.copyWith(consumedGlasses: state.consumedGlasses - 1);
    }
  }

  // Naye din ke liye reset karna 🔄
  void resetWater() {
    state = state.copyWith(consumedGlasses: 0);
  }
}