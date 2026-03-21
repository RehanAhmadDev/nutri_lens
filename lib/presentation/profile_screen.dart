import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_colors.dart';
import 'providers/water_provider.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _goalController = TextEditingController();
  final _waterGoalController = TextEditingController();

  String _userName = "User";
  String _userEmail = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 📥 User ka data Supabase se load karna
  void _loadUserData() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? "";
        _userName = user.userMetadata?['full_name'] ?? "NutriLens User";
        _goalController.text = (user.userMetadata?['daily_goal'] ?? 2000).toString();
        _waterGoalController.text = (user.userMetadata?['water_goal'] ?? 8).toString();
      });
    }
  }

  // 💾 Goals save karne ka function
  Future<void> _saveProfile() async {
    HapticFeedback.mediumImpact(); // 🚀 Professional Haptic Feedback
    setState(() => _isLoading = true);

    try {
      final newCalGoal = int.tryParse(_goalController.text.trim()) ?? 2000;
      final newWaterGoal = int.tryParse(_waterGoalController.text.trim()) ?? 8;

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'daily_goal': newCalGoal,
            'water_goal': newWaterGoal,
          },
        ),
      );

      // Water Provider ko foran update karna
      ref.read(waterProvider.notifier).updateDailyGoal(newWaterGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully! ✨'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
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

  // 🛡️ Logout Dialog Function
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Logout",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text("Are you sure you want to sign out of NutriLens?",
            style: GoogleFonts.poppins(color: AppColors.textLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: GoogleFonts.poppins(color: AppColors.textLight, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _supabase.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text("Logout",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👤 Header Section
            Column(
              children: [
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_userName,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text(_userEmail,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight)),
              ],
            ),
            const SizedBox(height: 40),

            Text("Personal Goals",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),

            // 🎯 Settings Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                children: [
                  _buildGoalField(
                    controller: _goalController,
                    label: "Daily Calorie Goal",
                    unit: "Kcal",
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                    fillColor: AppColors.background,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),
                  _buildGoalField(
                    controller: _waterGoalController,
                    label: "Daily Water Goal",
                    unit: "Glasses",
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF3182CE),
                    fillColor: const Color(0xFFEBF8FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 💾 Save Changes Button
            SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Save Changes",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 24),

            // ❌ Logout Button
            TextButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              label: Text("Logout Account",
                  style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // 🏗️ Goal Field Builder
  Widget _buildGoalField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor, size: 22),
            suffixText: unit,
            suffixStyle: GoogleFonts.poppins(color: AppColors.textLight, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: iconColor.withOpacity(0.5), width: 1.5)
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    _waterGoalController.dispose();
    super.dispose();
  }
}