class FoodModel {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  FoodModel({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  // 🔄 AI ke diye gaye JSON (Map) ko Dart Object mein badalne ke liye
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      foodName: json['food_name'] ?? 'Unknown Food',
      // Agar AI string mein number de de, toh usay int mein parse karna
      calories: (json['calories'] is int) ? json['calories'] : int.tryParse(json['calories'].toString()) ?? 0,
      protein: (json['protein'] is int) ? json['protein'] : int.tryParse(json['protein'].toString()) ?? 0,
      carbs: (json['carbs'] is int) ? json['carbs'] : int.tryParse(json['carbs'].toString()) ?? 0,
      fats: (json['fats'] is int) ? json['fats'] : int.tryParse(json['fats'].toString()) ?? 0,
    );
  }

  // 💾 Aage chal kar Supabase (Database) mein save karne ke liye
  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}