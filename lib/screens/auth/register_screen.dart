import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/nebula/nebula.dart';

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
  double _strength = 0;
  String _strengthLabel = '';
  Color _strengthColor = AppColors.border;

  static const _subjects = [
    ('Matematika', Icons.calculate_rounded),
    ('Fizika', Icons.science_rounded),
    ('Dasturlash', Icons.code_rounded),
    ('Ingliz tili', Icons.translate_rounded),
    ('Tarix', Icons.history_edu_rounded),
    ('Kimyo', Icons.biotech_rounded),
    ('Biologiya', Icons.eco_rounded),
    ('Iqtisodiyot', Icons.trending_up_rounded),
  ];

  static const _diffs = [
    ('easy', 'easy', Color(0xFF34D399)),
    ('medium', 'medium', Color(0xFFFCD34D)),
    ('hard', 'hard', Color(0xFFF87171)),
    ('expert', 'expert', Color(0xFFA855F7)),
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
      label = "O'rtacha";
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(auth.error ?? S.get('error'),
                    style: GoogleFonts.poppins())),
          ]),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 20),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(8, 8, D.sp16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.txt,
                            size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: AppColors.titleGradient,
                        ).createShader(b),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          S.get('register'),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: D.sp24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          GlassTextField(
                            controller: _name,
                            label: S.get('full_name'),
                            prefixIcon:
                                Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null ||
                                    v.trim().length < 2)
                                ? S.get('min_6')
                                : null,
                          ),
                          const SizedBox(height: D.sp12),
                          GlassTextField(
                            controller: _username,
                            label: S.get('username'),
                            prefixIcon: Icons.alternate_email_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null ||
                                    v.trim().length < 3)
                                ? S.get('min_6')
                                : null,
                          ),
                          const SizedBox(height: D.sp12),
                          GlassTextField(
                            controller: _email,
                            label: S.get('email'),
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return S.get('enter_email');
                              }
                              final re = RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!re.hasMatch(v)) {
                                return S.get('valid_email');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: D.sp12),
                          GlassTextField(
                            controller: _pass,
                            label: S.get('password'),
                            prefixIcon:
                                Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onChanged: _onPasswordChange,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.sub,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6)
                                    ? S.get('min_6')
                                    : null,
                          ),
                          if (_pass.text.isNotEmpty) ...[
                            const SizedBox(height: D.sp12),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 300),
                                      height: 5,
                                      child:
                                          LinearProgressIndicator(
                                        value: _strength,
                                        backgroundColor: AppColors
                                            .border
                                            .withOpacity(0.3),
                                        valueColor:
                                            AlwaysStoppedAnimation<
                                                    Color>(
                                                _strengthColor),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _strengthLabel,
                                  style: GoogleFonts.poppins(
                                    color: _strengthColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: D.sp32),
                          _sectionTitle(S.get('priority')),
                          const SizedBox(height: 12),
                          Row(
                            children: _diffs.map((d) {
                              final isActive = _diff == d.$1;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right:
                                          d.$1 != 'expert' ? 8 : 0),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback
                                          .selectionClick();
                                      setState(
                                          () => _diff = d.$1);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 220),
                                      padding: const EdgeInsets
                                          .symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isActive
                                            ? LinearGradient(
                                                colors: [
                                                  d.$3.withOpacity(
                                                      0.25),
                                                  d.$3.withOpacity(
                                                      0.08),
                                                ],
                                              )
                                            : null,
                                        color: isActive
                                            ? null
                                            : AppColors.card
                                                .withOpacity(0.5),
                                        borderRadius:
                                            BorderRadius.circular(
                                                14),
                                        border: Border.all(
                                          color: isActive
                                              ? d.$3
                                              : AppColors.border,
                                          width:
                                              isActive ? 1.5 : 1,
                                        ),
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: d.$3
                                                      .withOpacity(
                                                          0.3),
                                                  blurRadius: 14,
                                                  offset:
                                                      const Offset(
                                                          0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration:
                                                BoxDecoration(
                                              color: d.$3,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: d.$3
                                                      .withOpacity(
                                                          0.6),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            S.get(d.$2),
                                            style: GoogleFonts
                                                .poppins(
                                              color: isActive
                                                  ? d.$3
                                                  : AppColors.sub,
                                              fontSize: 11,
                                              fontWeight: isActive
                                                  ? FontWeight
                                                      .w700
                                                  : FontWeight
                                                      .w500,
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
                          _sectionTitle(S.get('category')),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _subjects.map((s) {
                              final sel =
                                  _selected.contains(s.$1);
                              return NebulaChip(
                                label: s.$1,
                                icon: s.$2,
                                selected: sel,
                                onTap: () => setState(() => sel
                                    ? _selected.remove(s.$1)
                                    : _selected.add(s.$1)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 36),
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) =>
                                NebulaButton(
                              label: S.get('register'),
                              icon: Icons
                                  .check_circle_outline_rounded,
                              loading: auth.isLoading,
                              onTap: _register,
                            ),
                          ),
                          const SizedBox(height: D.sp24),
                          Center(
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  S.get('has_account'),
                                  style: GoogleFonts.poppins(
                                    color: AppColors.sub,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pop(context),
                                  child: ShaderMask(
                                    shaderCallback: (b) =>
                                        const LinearGradient(
                                            colors: AppColors
                                                .gradCosmic)
                                            .createShader(b),
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      S.get('login'),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.gradCosmic,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.txt,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
