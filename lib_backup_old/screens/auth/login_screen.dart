import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _form     = GlobalKey<FormState>();
  bool  _obscure  = true;
  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override void dispose() { _anim.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text.trim(), _password.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Kirish xato'),
        backgroundColor: C.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
    // Muvaffaqiyatli bo'lsa → main.dart Consumer avtomatik yo'naltiradi
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: C.gradPrimary,
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: C.primary.withOpacity(0.4),
                          blurRadius: 30, spreadRadius: 2)],
                    ),
                    child: const Center(child: Text('🚀', style: TextStyle(fontSize: 42))),
                  ),
                  const SizedBox(height: 20),
                  const Text('MotivAI',
                      style: TextStyle(color: C.txt, fontSize: 30,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('O\'quv motivatsiyangizni oshiring',
                      style: TextStyle(color: C.sub, fontSize: 14)),
                  const SizedBox(height: 48),

                  // Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: C.txt),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined, color: C.sub),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email kiriting';
                      if (!v.contains('@')) return 'To\'g\'ri email kiriting';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: C.txt),
                    decoration: InputDecoration(
                      labelText: 'Parol',
                      prefixIcon: const Icon(Icons.lock_outlined, color: C.sub),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: C.sub),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) return 'Kamida 6 belgi';
                      return null;
                    },
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 32),

                  // Login button
                  Consumer<AuthProvider>(
                    builder: (_, auth, __) => auth.isLoading
                        ? const CircularProgressIndicator(color: C.primary)
                        : _GradBtn(
                            label: 'Kirish',
                            onTap: _login,
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Hisobingiz yo'qmi? ",
                          style: TextStyle(color: C.sub, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text("Ro'yxatdan o'ting",
                            style: TextStyle(color: C.primary, fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Demo credentials
                  _DemoCard(onTap: () {
                    _email.text    = 'student@motivate.ai';
                    _password.text = 'student123456';
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: C.gradPrimary),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: C.primary.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w600))),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DemoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('🧑‍💻', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Demo hisob',
                      style: TextStyle(color: C.txt, fontWeight: FontWeight.w600)),
                  Text('student@motivate.ai | student123456',
                      style: TextStyle(color: C.sub, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: C.sub, size: 14),
          ],
        ),
      ),
    );
  }
}
