import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedLang = 'uz';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(userProvider.notifier).register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
      _selectedLang,
    );
    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/auth/login'),
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Ro\'yxatdan o\'tish',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MotivAI ga xush kelibsiz! 🎯',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Ismingiz',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 2) return 'Ismingizni kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || !v.contains('@')) return 'To\'g\'ri email kiriting';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Parol',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Kamida 6 ta belgi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Language selector
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLang,
                      dropdownColor: AppTheme.surface,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                      items: const [
                        DropdownMenuItem(value: 'uz', child: Text("🇺🇿  O'zbek")),
                        DropdownMenuItem(value: 'ru', child: Text('🇷🇺  Русский')),
                        DropdownMenuItem(value: 'en', child: Text('🇬🇧  English')),
                      ],
                      onChanged: (v) => setState(() => _selectedLang = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 24),

                // Register button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Ro\'yxatdan o\'tish',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hisobingiz bormi? ',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    GestureDetector(
                      onTap: () => context.go('/auth/login'),
                      child: const Text('Kirish',
                          style: TextStyle(
                              color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
