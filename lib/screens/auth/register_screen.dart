import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _State();
}

class _State extends State<RegisterScreen> {
  final _form     = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _pass     = TextEditingController();
  bool  _obscure  = true;
  String _diff    = 'medium';
  final List<String> _selected = [];

  static const _subjects = [
    'Matematika','Fizika','Dasturlash','Ingliz tili',
    'Tarix','Kimyo','Biologiya','Iqtisodiyot',
  ];
  static const _diffs = [
    ('easy','Oson','🟢'),('medium',"O'rta",'🟡'),
    ('hard','Qiyin','🟠'),('expert','Expert','🔴'),
  ];

  @override void dispose() {
    for (final c in [_name,_username,_email,_pass]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email:    _email.text.trim(),
      password: _pass.text,
      subjects: _selected,
      difficulty: _diff,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Ro\'yxatdan o\'tish xato'),
        backgroundColor: C.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text("Ro'yxatdan o'tish",
            style: TextStyle(color: C.txt, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: C.txt),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yangi hisob yaratish',
                    style: TextStyle(color: C.txt, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Ma\'lumotlaringizni to\'ldiring',
                    style: TextStyle(color: C.sub, fontSize: 14)),
                const SizedBox(height: 28),

                _field(_name, "To'liq ism", Icons.person_outline,
                    validator: (v) => v!.length < 2 ? 'Kamida 2 belgi' : null),
                const SizedBox(height: 14),
                _field(_username, 'Username', Icons.alternate_email,
                    validator: (v) => v!.length < 3 ? 'Kamida 3 belgi' : null),
                const SizedBox(height: 14),
                _field(_email, 'Email', Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    validator: (v) => !v!.contains('@') ? "To'g'ri email" : null),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass,
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
                  validator: (v) => v!.length < 6 ? 'Kamida 6 belgi' : null,
                ),
                const SizedBox(height: 24),

                // Qiyinchilik darajasi
                const Text('Afzal qiyinchilik darajasi',
                    style: TextStyle(color: C.txt, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: _diffs.map((d) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _diff = d.$1),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _diff == d.$1 ? C.primary : C.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _diff == d.$1 ? C.primary : C.border),
                        ),
                        child: Column(children: [
                          Text(d.$3, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(d.$2,
                              style: TextStyle(
                                  color: _diff == d.$1 ? Colors.white : C.sub,
                                  fontSize: 11)),
                        ]),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),

                // Fanlar
                const Text("Qiziqish yo'nalishlari",
                    style: TextStyle(color: C.txt, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _subjects.map((s) {
                    final sel = _selected.contains(s);
                    return GestureDetector(
                      onTap: () => setState(() =>
                          sel ? _selected.remove(s) : _selected.add(s)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? C.primary : C.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? C.primary : C.border),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                color: sel ? Colors.white : C.sub,
                                fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) => auth.isLoading
                      ? const Center(child: CircularProgressIndicator(color: C.primary))
                      : _GradBtn(label: "Ro'yxatdan o'tish", onTap: _register),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: C.txt),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: C.sub),
      ),
      validator: validator,
    );
  }
}

class _GradBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _GradBtn({required this.label, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: C.gradPrimary),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: C.primary.withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Center(child: Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
    ),
  );
}
