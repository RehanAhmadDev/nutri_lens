import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/splash_screen.dart';
import 'utils/api_constants.dart';
import 'utils/app_colors.dart';
// 🚀 NAYA IMPORT: Theme Provider
import 'presentation/providers/theme_provider.dart';

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

// 🚀 NAYA: StatelessWidget ko ConsumerWidget banaya taake theme sun sake
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎨 JADOO YAHAN HAI: Pori app ab themeProvider ko watch karegi.
    // Jaise hi theme change hogi, yeh app ko naye colors ke sath foran refresh kar dega.
    ref.watch(themeProvider);

    return MaterialApp(
      title: 'NutriLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 🎨 Ab yeh AppColors.primary bilkul dynamic hai!
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      // 🚀 App khulte hi ab sab se pehle SplashScreen aayegi
      home: const SplashScreen(),
    );
  }
}