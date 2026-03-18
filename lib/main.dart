import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🚀 Supabase Import
import 'presentation/home_screen.dart';
import 'utils/api_constants.dart'; // 🚀 Keys Import

void main() async {
  // 1. Flutter engine ko ready karna zaroori hai async setup ke liye
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 🚀 App start hone se pehle Supabase ko connect karna
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  runApp(
    // ProviderScope ke baghair Riverpod nahi chalta
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // Aap ka selected theme
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}