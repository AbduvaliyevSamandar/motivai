// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../constants/app_theme.dart';
import '../home/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _language = 'uz';
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      language: _language,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Ro'yxatdan o'tish"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    child: Text(auth.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),

                _buildField('Ismingiz', _nameCtrl, 'Ali Valiyev',
                  icon: Icons.person_outline,
                  validator: (v) => v!.length < 2 ? "Ism kamida 2 ta belgi" : null,
                ),
                const SizedBox(height: 16),
                _buildField('Email', _emailCtrl, 'email@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => !v!.contains('@') ? "To'g'ri email" : null,
                ),
                const SizedBox(height: 16),
                _buildField('Parol', _passCtrl, '••••••••',
                  icon: Icons.lock_outline,
                  obscure: _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) => v!.length < 6 ? "Kamida 6 ta belgi" : null,
                ),
                const SizedBox(height: 20),

                // Language selection
                const Text('Til', style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14,
                )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final lang in [
                      {'key': 'uz', 'label': "O'zbek 🇺🇿"},
                      {'key': 'ru', 'label': 'Русский 🇷🇺'},
                      {'key': 'en', 'label': 'English 🇺🇸'},
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _language = lang['key']!),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _language == lang['key']
                                  ? AppTheme.primary
                                  : AppTheme.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _language == lang['key']
                                    ? AppTheme.primary
                                    : AppTheme.divider,
                              ),
                            ),
                            child: Text(
                              lang['label']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _language == lang['key']
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text("Ro'yxatdan o'tish",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Ro'yxatdan o'tish orqali siz MotivAI shartlari va maxfiylik siyosatini qabul qilasiz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    IconData? icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: suffixIcon,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return '$label kiriting';
            return validator?.call(v);
          },
        ),
      ],
    );
  }
}
