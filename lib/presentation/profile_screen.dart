import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _goalController = TextEditingController();

  String _userName = "User";
  String _userEmail = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 📥 User ka data Supabase se nikalna
  void _loadUserData() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? "";
        // Metadata se naam aur goal nikalna (agar na ho toh default 2000)
        _userName = user.userMetadata?['full_name'] ?? "NutriLens User";
        _goalController.text = (user.userMetadata?['daily_goal'] ?? 2000).toString();
      });
    }
  }

  // 💾 Naya Goal Cloud par save karna
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final newGoal = int.tryParse(_goalController.text.trim()) ?? 2000;

      // Supabase ke metadata mein daily_goal update karna
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'daily_goal': newGoal},
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile Updated Successfully! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Save hone ke baad wapis Home par bhej do
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👤 Profile Avatar
            Center(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Center(
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 📝 Name & Email Display
            Text(_userName, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            Text(_userEmail, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight)),
            const SizedBox(height: 40),

            // 🎯 Goal Settings Card
            Text("Settings", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Daily Calorie Goal (Kcal)", style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.local_fire_department_rounded, color: Colors.orange),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 💾 Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text("Save Changes", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }
}