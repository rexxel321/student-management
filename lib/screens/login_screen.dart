import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
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
            // Judul dengan Gradasi Text (Logic sederhana)
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)],
              ).createShader(bounds),
              child: const Text(
                "Welcome Admin",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Manage your school efficiently.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              controller: _emailController,
              hint: "Email",
              icon: Icons.email,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passController,
              hint: "Password",
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 30),

            NeonButton(text: "Sign In", onPressed: login),
          ],
        ),
      ),
    );
  }
}
