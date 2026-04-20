import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_chip.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  String _diff = 'medium';
  final _selected = <String>[];
  double _strength = 0.0;
  String _strengthLabel = '';
  Color _strengthColor = AppColors.border;

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
    ('hard', 'hard', Color(0xFFFF8C00)),
    ('expert', 'expert', Color(0xFFEF5350)),
  ];

  @override
  void dispose() {
    for (final c in [_name, _username, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onPasswordChange(String v) {
    double s = 0;
    if (v.length >= 6) s += 0.25;
    if (v.length >= 10) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(v)) s += 0.15;
    if (RegExp(r'[0-9]').hasMatch(v)) s += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(v)) s += 0.15;
    s = s.clamp(0.0, 1.0);

    String label;
    Color color;
    if (s < 0.3) {
      label = 'Zaif';
      color = AppColors.danger;
    } else if (s < 0.6) {
      label = 'O\'rtacha';
      color = AppColors.accent;
    } else if (s < 0.85) {
      label = 'Yaxshi';
      color = AppColors.info;
    } else {
      label = 'Kuchli';
      color = AppColors.success;
    }
    setState(() {
      _strength = s;
      _strengthLabel = label;
      _strengthColor = color;
    });
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      fullName: _name.text.trim(),
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _pass.text,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: D.sp8),
            Expanded(child: Text(auth.error ?? S.get('error'))),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radiusMd),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.txt,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          S.get('register'),
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: D.sp24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: D.sp8),

              CustomTextField(
                controller: _name,
                label: S.get('full_name'),
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? S.get('min_6') : null,
              ),
              const SizedBox(height: D.sp16),

              CustomTextField(
                controller: _username,
                label: S.get('username'),
                prefixIcon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? S.get('min_6') : null,
              ),
              const SizedBox(height: D.sp16),

              CustomTextField(
                controller: _email,
                label: S.get('email'),
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || !v.contains('@'))
                    ? S.get('valid_email')
                    : null,
              ),
              const SizedBox(height: D.sp16),

              CustomTextField(
                controller: _pass,
                label: S.get('password'),
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onChanged: _onPasswordChange,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.sub,
                    size: D.iconMd,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? S.get('min_6') : null,
              ),

              if (_pass.text.isNotEmpty) ...[
                const SizedBox(height: D.sp12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _strength,
                          minHeight: 5,
                          backgroundColor: AppColors.border.withOpacity(0.4),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_strengthColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: D.sp12),
                    Text(
                      _strengthLabel,
                      style: GoogleFonts.poppins(
                        color: _strengthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: D.sp32),

              _SectionTitle(title: S.get('priority')),
              const SizedBox(height: D.sp12),
              Row(
                children: _diffs.map((d) {
                  final isActive = _diff == d.$1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: d.$1 != 'expert' ? D.sp8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _diff = d.$1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isActive
                                ? d.$3.withOpacity(0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(D.radiusMd),
                            border: Border.all(
                              color: isActive ? d.$3 : AppColors.border,
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: d.$3.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
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
                                      color: d.$3.withOpacity(0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                S.get(d.$2),
                                style: GoogleFonts.poppins(
                                  color: isActive ? d.$3 : AppColors.sub,
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

              const SizedBox(height: D.sp32),

              _SectionTitle(title: S.get('category')),
              const SizedBox(height: D.sp12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_subjects.length, (i) {
                  final s = _subjects[i];
                  final sel = _selected.contains(s);
                  return CustomChip(
                    label: s,
                    icon: _subjectIcons[i],
                    selected: sel,
                    onTap: () => setState(
                      () => sel ? _selected.remove(s) : _selected.add(s),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              Consumer<AuthProvider>(
                builder: (_, auth, __) => GradientButton(
                  label: S.get('register'),
                  onTap: _register,
                  loading: auth.isLoading,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),

              const SizedBox(height: D.sp24),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.get('has_account'),
                      style: GoogleFonts.poppins(
                        color: AppColors.sub,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: D.sp4),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        S.get('login'),
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: D.sp32),
            ],
          ),
        ),
      ),
    );
  }
}

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
              colors: AppColors.gradPrimary,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
