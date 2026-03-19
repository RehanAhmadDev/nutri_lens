import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/splash_screen.dart'; // 🚀 NAYA IMPORT
import 'utils/api_constants.dart';
import 'utils/app_colors.dart'; // 🎨 Color File

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  runApp(
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
        // 🎨 Poori app ka default color humari primary color se set ho raha hai
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      // 🚀 App khulte hi ab sab se pehle SplashScreen aayegi
      home: const SplashScreen(),
    );
  }
}