import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form     = GlobalKey<FormState>();
  final _name     = TextEditingController();
  final _username = TextEditingController();
  final _email    = TextEditingController();
  final _pass     = TextEditingController();
  bool  _obscure  = true;
  String _diff    = 'medium';
  final _selected = <String>[];

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
        backgroundColor: AppColors.danger,
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

              // -- Full name --
              _buildField(
                controller: _name,
                label: S.get('full_name'),
                icon: Icons.person_outline_rounded,
                validator: (v) => v!.length < 2 ? S.get('min_6') : null,
              ),
              const SizedBox(height: D.sp16),

              // -- Username --
              _buildField(
                controller: _username,
                label: S.get('username'),
                icon: Icons.alternate_email_rounded,
                validator: (v) => v!.length < 3 ? S.get('min_6') : null,
              ),
              const SizedBox(height: D.sp16),

              // -- Email --
              _buildField(
                controller: _email,
                label: S.get('email'),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    !v!.contains('@') ? S.get('valid_email') : null,
              ),
              const SizedBox(height: D.sp16),

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
                    color: AppColors.sub,
                    size: D.iconMd,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => v!.length < 6 ? S.get('min_6') : null,
              ),

              const SizedBox(height: D.sp32),

              // -- Difficulty section --
              _buildSectionTitle(S.get('priority')),
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
                        onTap: () => setState(() => _diff = d.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isActive
                                ? d.$3.withValues(alpha: 0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(D.radiusMd),
                            border: Border.all(
                              color: isActive ? d.$3 : AppColors.border,
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: d.$3.withValues(alpha: 0.2),
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
                                      color: d.$3.withValues(alpha: 0.4),
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

              // -- Subjects / interests --
              _buildSectionTitle(S.get('category')),
              const SizedBox(height: D.sp12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  _subjects.length,
                  (i) {
                    final s = _subjects[i];
                    final sel = _selected.contains(s);
                    return GestureDetector(
                      onTap: () => setState(
                        () => sel ? _selected.remove(s) : _selected.add(s),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: sel
                              ? const LinearGradient(
                                  colors: AppColors.gradPrimary,
                                )
                              : null,
                          color: sel ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(D.radiusXl),
                          border: sel
                              ? null
                              : Border.all(color: AppColors.border),
                          boxShadow: sel
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _subjectIcons[i],
                              size: D.iconSm,
                              color: sel ? Colors.white : AppColors.sub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s,
                              style: GoogleFonts.poppins(
                                color: sel ? Colors.white : AppColors.txt,
                                fontSize: 13,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400,
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
                builder: (_, auth, __) => GestureDetector(
                  onTap: auth.isLoading ? null : _register,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: auth.isLoading
                            ? [
                                AppColors.primary.withValues(alpha: 0.5),
                                AppColors.secondary.withValues(alpha: 0.5),
                              ]
                            : AppColors.gradPrimary,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(D.radiusMd),
                      boxShadow: auth.isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Center(
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              S.get('register'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: D.sp24),

              // -- Login link --
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
        borderRadius: BorderRadius.circular(D.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.poppins(
          color: AppColors.txt,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(icon, size: D.iconMd),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: D.sp20,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(D.radiusMd),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(D.radiusMd),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(D.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(D.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.danger,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(D.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.danger,
              width: 2,
            ),
          ),
          labelStyle: GoogleFonts.poppins(
            color: AppColors.sub,
            fontSize: 14,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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
