import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import 'nebula/nebula.dart';
import 'otp_code_field.dart';

/// Bottom sheet that asks the user to enter the 6-digit code we just sent.
/// Returns the entered code (string) on success, null on cancel.
Future<String?> showOtpSheet(
  BuildContext context, {
  required String email,
  required Future<bool> Function() onResend,
  String title = 'Tasdiq kodini kiriting',
  String purpose = 'register',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OtpSheet(
      email: email,
      onResend: onResend,
      title: title,
      purpose: purpose,
    ),
  );
}

class _OtpSheet extends StatefulWidget {
  final String email;
  final Future<bool> Function() onResend;
  final String title;
  final String purpose;
  const _OtpSheet({
    required this.email,
    required this.onResend,
    required this.title,
    required this.purpose,
  });

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  String _code = '';
  int _cooldown = 30;
  Timer? _timer;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    HapticFeedback.lightImpact();
    setState(() => _resending = true);
    final ok = await widget.onResend();
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: ok ? AppColors.success : AppColors.danger,
      behavior: SnackBarBehavior.floating,
      content: Text(
        ok ? 'Yangi kod yuborildi' : 'Yuborib bo\'lmadi',
        style: GoogleFonts.poppins(),
      ),
    ));
    if (ok) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: AppColors.titleGradient,
              ).createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                widget.title,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.email} ga 6 xonali kod yuborildi',
              style: GoogleFonts.poppins(
                  color: AppColors.sub, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            OtpCodeField(
              autofocus: true,
              onChanged: (v) => setState(() => _code = v),
              onComplete: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 20),
            NebulaButton(
              label: 'Tasdiqlash',
              icon: Icons.check_rounded,
              disabled: _code.length != 6,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, _code);
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed:
                  (_cooldown == 0 && !_resending) ? _resend : null,
              child: Text(
                _resending
                    ? 'Yuborilmoqda...'
                    : _cooldown == 0
                        ? 'Kodni qayta yuborish'
                        : 'Qayta yuborish ($_cooldown s)',
                style: GoogleFonts.poppins(
                  color: _cooldown == 0
                      ? AppColors.primary
                      : AppColors.sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
