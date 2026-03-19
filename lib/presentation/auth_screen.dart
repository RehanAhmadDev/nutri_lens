import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController(); // 🚀 NAYA: Name Field
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  final _supabase = Supabase.instance.client;

  // 🚀 Core Authentication Function
  Future<void> _authenticate() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validations
    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      _showError("Please fill all the required fields!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Log In
        await _supabase.auth.signInWithPassword(email: email, password: password);
      } else {
        // Sign Up (Name bhi database mein save ho jayega)
        await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name}, // 🚀 Metadata mein naam save karein
        );
      }

      // Successful hone par Home Screen par le jayen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Something went wrong. Try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🌟 Premium Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.center_focus_strong_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // 📝 Dynamic Headers
              Text(
                _isLogin ? 'Welcome Back!' : 'Join NutriLens',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E2C)),
              ),
              Text(
                _isLogin ? 'Log in to track your daily nutrition.' : 'Create an account to start your fitness journey.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),

              // 🎛️ Form Container (Card Look)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    // 👤 Name Field (Sirf Signup mein dikhega)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _isLogin ? 0 : 70, // Smooth transition
                      child: SingleChildScrollView(
                        child: _isLogin ? const SizedBox.shrink() : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_rounded,
                          ),
                        ),
                      ),
                    ),

                    // ✉️ Email Field
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                      isEmail: true,
                    ),
                    const SizedBox(height: 16),

                    // 🔒 Password Field
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 🚀 Premium Gradient Action Button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                    _isLogin ? 'Log In' : 'Create Account',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🔄 Dynamic Toggle Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account? " : "Already have an account? ",
                    style: GoogleFonts.poppins(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLogin = !_isLogin;
                      // Clear fields when switching
                      _nameController.clear();
                      _passwordController.clear();
                    }),
                    child: Text(
                      _isLogin ? "Sign Up" : "Log In",
                      style: GoogleFonts.poppins(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 📝 Custom Text Field Builder (Light grey background, sleek design)
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 22),
        filled: true,
        fillColor: const Color(0xFFF4F6F9), // Light grayish-blue for input background
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}