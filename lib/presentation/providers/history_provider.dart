import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryState {
  final bool isLoading;
  final List<Map<String, dynamic>> scans;
  final String searchQuery;

  HistoryState({
    this.isLoading = true,
    this.scans = const [],
    this.searchQuery = '',
  });

  HistoryState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? scans,
    String? searchQuery,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      scans: scans ?? this.scans,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(HistoryState()) {
    loadHistory();
  }

  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allScans = []; // Asal data yahan mehfooz rahega

  // 1. Database se data lana
  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await _supabase
          .from('food_scans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _allScans = List<Map<String, dynamic>>.from(response);
      _applySearch(state.searchQuery);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print("Error loading history: $e");
    }
  }

  // 2. 🚀 Search filter apply karna
  void search(String query) {
    _applySearch(query);
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      state = state.copyWith(isLoading: false, scans: _allScans, searchQuery: query);
    } else {
      final filteredList = _allScans.where((scan) {
        final foodName = scan['food_name'].toString().toLowerCase();
        return foodName.contains(query.toLowerCase());
      }).toList();

      state = state.copyWith(isLoading: false, scans: filteredList, searchQuery: query);
    }
  }

  // 3. Item Delete karna
  Future<void> deleteScan(int id) async {
    try {
      await _supabase.from('food_scans').delete().eq('id', id);
      _allScans.removeWhere((element) => element['id'] == id);
      _applySearch(state.searchQuery); // Delete ke baad UI update karo
    } catch (e) {
      print("Error deleting: $e");
    }
  }
}