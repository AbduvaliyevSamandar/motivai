import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/google_auth.dart';
import '../../widgets/nebula/nebula.dart';
import '../../widgets/otp_sheet.dart';
import '../../widgets/google_logo.dart';

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
  String? _formError;

  static const _subjects = [
    ('Matematika', LucideIcons.calculator),
    ('Fizika', LucideIcons.flaskConical),
    ('Dasturlash', LucideIcons.code2),
    ('Ingliz tili', LucideIcons.languages),
    ('Tarix', LucideIcons.scroll),
    ('Kimyo', LucideIcons.flaskConical),
    ('Biologiya', LucideIcons.leaf),
    ('Iqtisodiyot', LucideIcons.trendingUp),
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
    setState(() => _formError = null);
    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();

    // Step 1: send OTP to email
    final sent = await auth.sendOtp(email);
    if (!sent) {
      _showError(auth.error);
      return;
    }
    if (!mounted) return;

    // Step 2: collect code via bottom sheet
    final code = await showOtpSheet(
      context,
      email: email,
      title: 'Tasdiq kodi',
    );
    if (code == null || code.length != 6 || !mounted) return;

    // Step 3: complete registration with code
    final ok = await auth.registerWithOtp(
      name: _name.text.trim(),
      email: email,
      password: _pass.text,
      code: code,
    );
    if (!mounted) return;
    if (ok) {
      // We're authenticated — close the register screen so the App's
      // Consumer<AuthProvider> can swap the home to MainShell.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showError(auth.error);
    }
  }

  void _showError(String? raw) {
    if (!mounted) return;
    setState(() => _formError = _humanize(raw));
  }

  String _humanize(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Xato yuz berdi. Qayta urinib ko\'ring.';
    }
    var msg = raw;
    if (msg.startsWith('Exception:')) msg = msg.substring(10).trim();
    if (msg.contains('Tarmoq xatosi')) {
      return 'Internet aloqasini tekshiring va qayta urinib ko\'ring';
    }
    if (msg.contains('Email already registered')) {
      return 'Bu email allaqachon ro\'yxatdan o\'tgan';
    }
    if (msg.contains('Invalid or expired code')) {
      return 'Kod noto\'g\'ri yoki muddati o\'tgan. Yangi kod oling.';
    }
    if (msg.contains('Vaqtinchalik') || msg.contains('fake email')) {
      return 'Bu email vaqtinchalik/soxta. Real email kiriting.';
    }
    if (msg.contains('Too many requests')) {
      return 'Juda ko\'p urinish — biroz kuting va qayta urining';
    }
    return msg;
  }

  Future<void> _googleSignIn() async {
    HapticFeedback.lightImpact();
    setState(() => _formError = null);
    final auth = context.read<AuthProvider>();
    final idToken = await GoogleAuth.signIn();
    if (idToken == null) return;
    final ok = await auth.loginWithGoogleIdToken(idToken);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showError(auth.error);
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
                            LucideIcons.chevronLeft,
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
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
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
                                LucideIcons.user,
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
                            prefixIcon: LucideIcons.mail,
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
                                LucideIcons.lock,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onChanged: _onPasswordChange,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
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
                                        BorderRadius.circular(8),
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
                                    fontSize: 11,
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
                                            BorderRadius.circular(12),
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
              maxLines: 1, overflow: TextOverflow.ellipsis,
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
                          const SizedBox(height: 24),
                          if (_formError != null) ...[
                            _RegErrorBanner(message: _formError!),
                            const SizedBox(height: 12),
                          ],
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
                          if (GoogleAuth.available) ...[
                            const SizedBox(height: 14),
                            const _OrDivider(),
                            const SizedBox(height: 14),
                            _GoogleButton(onTap: _googleSignIn),
                          ],
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
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pop(context),
                                  child: ShaderMask(
                                    shaderCallback: (b) =>
                                        LinearGradient(
                                            colors: AppColors
                                                .gradCosmic)
                                            .createShader(b),
                                    blendMode: BlendMode.srcIn,
                                    child: Text(
                                      S.get('login'),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
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
            gradient: LinearGradient(
              colors: AppColors.gradCosmic,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
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
          style: GoogleFonts.poppins(
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'yoki',
            style: GoogleFonts.poppins(
                color: AppColors.sub, fontSize: 11),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogo(size: 20),
                const SizedBox(width: 12),
                Text(
                  'Google bilan kirish',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1F2937),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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


class _RegErrorBanner extends StatelessWidget {
  final String message;
  const _RegErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertCircle,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
