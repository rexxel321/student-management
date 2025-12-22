import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_widgets.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> register() async {
    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Passwords do not match!"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );
      // Jika sukses, langsung masuk ke Home
      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)],
                ).createShader(bounds),
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              const Text("Register as Admin to manage school.",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              CustomTextField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _passController,
                  hint: "Password",
                  icon: Icons.lock,
                  isPassword: true),
              const SizedBox(height: 16),
              CustomTextField(
                  controller: _confirmPassController,
                  hint: "Confirm Password",
                  icon: Icons.lock,
                  isPassword: true),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFD946EF)))
                  : NeonButton(text: "Sign Up", onPressed: register),
            ],
          ),
        ),
      ),
    );
  }
}
