import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_widgets.dart';
import '../home/home_screen.dart';
import 'register_screen.dart'; // Pastikan ini di-import!

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  Future<void> login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      // Login sukses otomatis ditangani oleh stream di main.dart,
      // tapi kita bisa paksa navigasi biar aman:
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        // Tampilkan pesan error yang lebih ramah
        String message = "Login failed. Check your email/password.";
        if (e.toString().contains('invalid-credential')) {
          message = "Email tidak ditemukan atau password salah.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)],
              ).createShader(bounds),
              child: const Text(
                "Welcome Admin",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Manage your school efficiently.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),

            // Input Form
            CustomTextField(
                controller: _emailController, hint: "Email", icon: Icons.email),
            const SizedBox(height: 16),
            CustomTextField(
                controller: _passController,
                hint: "Password",
                icon: Icons.lock,
                isPassword: true),
            const SizedBox(height: 30),

            // Tombol Login
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD946EF)))
                : NeonButton(text: "Sign In", onPressed: login),

            const SizedBox(height: 24),

            // --- TOMBOL PINDAH KE REGISTER (INI YANG KURANG TADI) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ",
                    style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () {
                    // Pindah ke halaman Register
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                        color: Color(0xFFD946EF), fontWeight: FontWeight.bold),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
