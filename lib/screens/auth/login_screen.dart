import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/google_auth.dart';
import '../../widgets/nebula/nebula.dart';
import '../../widgets/otp_sheet.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _obscure = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text.trim(), _pass.text);
    if (!ok && mounted) {
      _errorToast(auth.error ?? S.get('error'));
    }
  }

  void _errorToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: GoogleFonts.poppins()),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 24),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slideUp,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: D.sp24),
                  child: Form(
                    key: _form,
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Small glass logo mark
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: D.sp24),

                        ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                            colors: AppColors.titleGradient,
                          ).createShader(b),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'Xush kelibsiz',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          S.get('motto'),
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

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

                        const SizedBox(height: D.sp16),

                        GlassTextField(
                          controller: _pass,
                          label: S.get('password'),
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.sub,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return S.get('min_6');
                            }
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _forgotPassword,
                            child: Text(
                              S.get('forgot_pass'),
                              style: GoogleFonts.poppins(
                                color: AppColors.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: D.sp16),

                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => NebulaButton(
                            label: S.get('login'),
                            icon: Icons.arrow_forward_rounded,
                            loading: auth.isLoading,
                            onTap: _login,
                          ),
                        ),

                        const SizedBox(height: D.sp24),

                        _divider(),

                        const SizedBox(height: D.sp16),

                        if (GoogleAuth.available)
                          _socialBtn(
                            label: S.get('login_google'),
                            iconBg: const Color(0xFF4285F4),
                            iconChild: Text(
                              'G',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onTap: _googleSignIn,
                          ),

                        const SizedBox(height: D.sp32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              S.get('no_account'),
                              style: GoogleFonts.poppins(
                                color: AppColors.sub,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      const RegisterScreen(),
                                  transitionsBuilder:
                                      (_, a, __, child) => FadeTransition(
                                    opacity: a,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.08),
                                        end: Offset.zero,
                                      ).animate(a),
                                      child: child,
                                    ),
                                  ),
                                  transitionDuration:
                                      const Duration(milliseconds: 400),
                                ),
                              ),
                              child: ShaderMask(
                                shaderCallback: (b) =>
                                    LinearGradient(
                                        colors: AppColors.gradCosmic)
                                        .createShader(b),
                                blendMode: BlendMode.srcIn,
                                child: Text(
                                  S.get('register'),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: D.sp32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.border],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            S.get('or'),
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.border, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialBtn({
    required String label,
    required Widget iconChild,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconBg.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(child: iconChild),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final emailCtrl =
        TextEditingController(text: _email.text.trim());
    final email = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AuthSheet(
        icon: Icons.lock_reset_rounded,
        accent: AppColors.primary,
        title: S.get('reset_pass'),
        subtitle: S.get('enter_email'),
        child: GlassTextField(
          controller: emailCtrl,
          label: S.get('email'),
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        actionLabel: 'Kod yuborish',
        onAction: () {
          if (emailCtrl.text.trim().isEmpty) {
            Navigator.pop(ctx);
            return;
          }
          Navigator.pop(ctx, emailCtrl.text.trim());
        },
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;

    final auth = context.read<AuthProvider>();
    final sent = await auth.sendOtp(email, purpose: 'reset');
    if (!sent || !mounted) {
      _showSnack(auth.error ?? 'Kod yuborilmadi', isError: true);
      return;
    }
    final code = await showOtpSheet(
      context,
      email: email,
      onResend: () => auth.sendOtp(email, purpose: 'reset'),
      title: 'Parolni tiklash',
      purpose: 'reset',
    );
    if (code == null || code.length != 6 || !mounted) return;

    // Ask for new password
    final newPassCtrl = TextEditingController();
    final newPass = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AuthSheet(
        icon: Icons.password_rounded,
        accent: AppColors.success,
        title: 'Yangi parol',
        subtitle: 'Kamida 6 belgi',
        child: GlassTextField(
          controller: newPassCtrl,
          label: 'Yangi parol',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        actionLabel: 'Saqlash',
        onAction: () {
          if (newPassCtrl.text.length < 6) return;
          Navigator.pop(ctx, newPassCtrl.text);
        },
      ),
    );
    if (newPass == null || newPass.isEmpty || !mounted) return;

    final ok = await auth.resetPassword(
      email: email,
      code: code,
      newPassword: newPass,
    );
    if (!mounted) return;
    if (ok) {
      _showSnack('Parol yangilandi! Endi kiring.', isError: false);
    } else {
      _showSnack(auth.error ?? 'Xatolik', isError: true);
    }
  }

  Future<void> _googleSignIn() async {
    HapticFeedback.lightImpact();
    final auth = context.read<AuthProvider>();
    final idToken = await GoogleAuth.signIn();
    if (idToken == null) return;
    final ok = await auth.loginWithGoogleIdToken(idToken);
    if (!ok && mounted) {
      _showSnack(auth.error ?? 'Google kirish xatosi', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
    ));
  }

}

class _AuthSheet extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Widget child;
  final String actionLabel;
  final VoidCallback onAction;

  const _AuthSheet({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.25),
                  accent.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(icon, color: accent, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.txt,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 24),
          NebulaButton(
            label: actionLabel,
            onTap: onAction,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
