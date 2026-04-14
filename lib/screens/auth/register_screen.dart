import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _S();
}

class _S extends State<RegisterScreen> {
  final _form     = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _pass     = TextEditingController();
  bool  _obscure  = true;
  String _diff    = 'medium';
  final  _selected = <String>[];

  static const _subjects = ['Matematika','Fizika',
    'Dasturlash','Ingliz tili','Tarix','Kimyo',
    'Biologiya','Iqtisodiyot'];

  static const _diffs = [
    ('easy','Oson','🟢'),
    ('medium',"O'rta",'🟡'),
    ('hard','Qiyin','🟠'),
    ('expert','Expert','🔴'),
  ];

  @override
  void dispose() {
    for (final c in [_name,_username,_email,_pass]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      fullName:   _name.text.trim(),
      username:   _username.text.trim(),
      email:      _email.text.trim(),
      password:   _pass.text,
      subjects:   _selected,
      difficulty: _diff,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Xato yuz berdi'),
        backgroundColor: C.error));
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
          onPressed: () => Navigator.pop(context)),
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
                    style: TextStyle(color: C.txt,
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("Ma'lumotlaringizni to'ldiring",
                    style: TextStyle(color: C.sub, fontSize: 14)),
                const SizedBox(height: 28),

                _field(_name, "To'liq ism", Icons.person_outline,
                    v: (v) => v!.length < 2 ? 'Kamida 2 belgi' : null),
                const SizedBox(height: 14),
                _field(_username, 'Username', Icons.alternate_email,
                    v: (v) => v!.length < 3 ? 'Kamida 3 belgi' : null),
                const SizedBox(height: 14),
                _field(_email, 'Email', Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    v: (v) => !v!.contains('@') ? "To'g'ri email" : null),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass,
                  obscureText: _obscure,
                  style: const TextStyle(color: C.txt),
                  decoration: InputDecoration(
                    labelText: 'Parol',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure))),
                  validator: (v) =>
                      v!.length < 6 ? 'Kamida 6 belgi' : null),
                const SizedBox(height: 24),

                const Text('Qiyinchilik darajasi',
                    style: TextStyle(color: C.txt, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(children: _diffs.map((d) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _diff = d.$1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _diff == d.$1 ? C.primary : C.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _diff == d.$1 ? C.primary : C.border)),
                      child: Column(children: [
                        Text(d.$3, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(d.$2, style: TextStyle(
                            color: _diff == d.$1 ? Colors.white : C.sub,
                            fontSize: 11)),
                      ]),
                    ),
                  ),
                )).toList()),
                const SizedBox(height: 24),

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
                              color: sel ? C.primary : C.border)),
                        child: Text(s, style: TextStyle(
                            color: sel ? Colors.white : C.sub,
                            fontSize: 13))));
                  }).toList()),
                const SizedBox(height: 32),

                Consumer<AuthProvider>(
                  builder: (_, auth, __) => auth.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: C.primary))
                      : GestureDetector(
                          onTap: _register,
                          child: Container(
                            width: double.infinity, height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: C.gradPrimary),
                              borderRadius: BorderRadius.circular(12)),
                            child: const Center(
                              child: Text("Ro'yxatdan o'tish",
                                  style: TextStyle(color: Colors.white,
                                      fontSize: 16, fontWeight: FontWeight.w600)))))),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type, String? Function(String?)? v}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: C.txt),
      decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon)),
      validator: v);
  }
}
