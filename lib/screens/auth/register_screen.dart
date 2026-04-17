import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _form     = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _pass     = TextEditingController();
  bool  _obscure  = true;
  String _diff    = 'medium';
  final _selected = <String>[];

  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;

  static const _subjects = [
    'Matematika',
    'Fizika',
    'Dasturlash',
    'Ingliz tili',
    'Tarix',
    'Kimyo',
    'Biologiya',
    'Iqtisodiyot',
  ];

  static const _subjectIcons = [
    Icons.calculate_rounded,
    Icons.science_rounded,
    Icons.code_rounded,
    Icons.translate_rounded,
    Icons.history_edu_rounded,
    Icons.biotech_rounded,
    Icons.eco_rounded,
    Icons.trending_up_rounded,
  ];

  static const _diffs = [
    ('easy', 'easy', Color(0xFF43E97B)),
    ('medium', 'medium', Color(0xFFFFD700)),
    ('hard', 'hard', Color(0xFFFF6584)),
    ('expert', 'expert', Color(0xFFEF5350)),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [_name, _username, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _pass.text,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? S.get('error')),
        backgroundColor: C.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slideUp,
            child: Column(
              children: [
                // -- Custom app bar --
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _BackButton(
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          S.get('register'),
                          style: TextStyle(
                            color: C.txt,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // -- Body --
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // -- Header decoration --
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  C.primary.withValues(alpha: 0.08),
                                  C.primary.withValues(alpha: 0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: C.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: C.gradPrimary,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        S.get('register'),
                                        style: TextStyle(
                                          color: C.txt,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        S.get('motto'),
                                        style: TextStyle(
                                          color: C.sub,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // -- Full name --
                          _buildField(
                            controller: _name,
                            label: S.get('full_name'),
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                v!.length < 2 ? S.get('min_6') : null,
                          ),
                          const SizedBox(height: 16),

                          // -- Username --
                          _buildField(
                            controller: _username,
                            label: S.get('username'),
                            icon: Icons.alternate_email_rounded,
                            validator: (v) =>
                                v!.length < 3 ? S.get('min_6') : null,
                          ),
                          const SizedBox(height: 16),

                          // -- Email --
                          _buildField(
                            controller: _email,
                            label: S.get('email'),
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                !v!.contains('@') ? S.get('valid_email') : null,
                          ),
                          const SizedBox(height: 16),

                          // -- Password --
                          _buildField(
                            controller: _pass,
                            label: S.get('password'),
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: C.sub,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                v!.length < 6 ? S.get('min_6') : null,
                          ),

                          const SizedBox(height: 32),

                          // -- Difficulty section --
                          _SectionTitle(title: S.get('priority')),
                          const SizedBox(height: 12),
                          Row(
                            children: _diffs.map((d) {
                              final isActive = _diff == d.$1;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: d.$1 != 'expert' ? 8 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _diff = d.$1),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? d.$3.withValues(alpha: 0.15)
                                            : C.surface,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isActive
                                              ? d.$3
                                              : C.border,
                                          width: isActive ? 2 : 1,
                                        ),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: d.$3.withValues(
                                                      alpha: 0.2),
                                                  blurRadius: 12,
                                                  offset:
                                                      const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: d.$3,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: d.$3.withValues(
                                                      alpha: 0.4),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            S.get(d.$2),
                                            style: TextStyle(
                                              color: isActive
                                                  ? d.$3
                                                  : C.sub,
                                              fontSize: 11,
                                              fontWeight: isActive
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 32),

                          // -- Subjects / interests --
                          _SectionTitle(title: S.get('category')),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              _subjects.length,
                              (i) {
                                final s = _subjects[i];
                                final sel = _selected.contains(s);
                                return GestureDetector(
                                  onTap: () => setState(() => sel
                                      ? _selected.remove(s)
                                      : _selected.add(s)),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: sel
                                          ? const LinearGradient(
                                              colors: C.gradPrimary,
                                            )
                                          : null,
                                      color: sel ? null : C.surface,
                                      borderRadius:
                                          BorderRadius.circular(24),
                                      border: sel
                                          ? null
                                          : Border.all(color: C.border),
                                      boxShadow: sel
                                          ? [
                                              BoxShadow(
                                                color: C.primary.withValues(
                                                    alpha: 0.3),
                                                blurRadius: 10,
                                                offset:
                                                    const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _subjectIcons[i],
                                          size: 16,
                                          color: sel
                                              ? Colors.white
                                              : C.sub,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          s,
                                          style: TextStyle(
                                            color: sel
                                                ? Colors.white
                                                : C.txt,
                                            fontSize: 13,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 40),

                          // -- Register button --
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) => auth.isLoading
                                ? Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          C.primary.withValues(alpha: 0.5),
                                          C.primaryLight
                                              .withValues(alpha: 0.5),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),
                                  )
                                : _GradientRegisterButton(
                                    label: S.get('register'),
                                    onTap: _register,
                                  ),
                          ),

                          const SizedBox(height: 24),

                          // -- Login link --
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  S.get('has_account'),
                                  style: TextStyle(
                                    color: C.sub,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    S.get('login'),
                                    style: const TextStyle(
                                      color: C.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: C.primary.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: TextStyle(color: C.txt, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: C.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: C.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: C.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: C.error, width: 2),
          ),
          labelStyle: TextStyle(color: C.sub, fontSize: 14),
        ),
        validator: validator,
      ),
    );
  }
}

// ── Section title ──
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: C.gradPrimary,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: C.txt,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Back button ──
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: C.txt,
          size: 18,
        ),
      ),
    );
  }
}

// ── Gradient register button ──
class _GradientRegisterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientRegisterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: C.gradPrimary,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: C.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
