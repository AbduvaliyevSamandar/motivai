// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_theme.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Center(
                          child: Text('🎯', style: TextStyle(fontSize: 38)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('MotivAI', style: AppTheme.heading1),
                      const SizedBox(height: 4),
                      const Text(
                        'Hisobingizga kiring',
                        style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Error
                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(auth.error!,
                              style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                // Email
                const Text('Email', style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary,
                )),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'email@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email kiriting';
                    if (!v.contains('@')) return "To'g'ri email kiriting";
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                const Text('Parol', style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary,
                )),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Parol kiriting';
                    if (v.length < 6) return "Parol kamida 6 ta belgi bo'lishi kerak";
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2,
                            ),
                          )
                        : const Text('Kirish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 24),

                // Register link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: "Hisob yo'qmi? ",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Ro'yxatdan o'tish",
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
