import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/colors.dart';
import 'nebula/nebula.dart';
import 'otp_code_field.dart';

/// Bottom sheet that asks the user to enter the 6-digit code we just sent.
/// Returns the entered code (string) on success, null on cancel.
///
/// If the user wants a new code, they cancel and re-trigger the signup
/// form — keeps this sheet single-purpose with no timer.
Future<String?> showOtpSheet(
  BuildContext context, {
  required String email,
  Future<bool> Function()? onResend,
  String title = 'Tasdiq kodini kiriting',
  String purpose = 'register',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OtpSheet(email: email, title: title),
  );
}

class _OtpSheet extends StatefulWidget {
  final String email;
  final String title;
  const _OtpSheet({required this.email, required this.title});

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  String _code = '';

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
                style: GoogleFonts.poppins(
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
              icon: LucideIcons.check,
              disabled: _code.length != 6,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, _code);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Kod kelmasa, oynani yopib qaytadan boshlang',
              style: GoogleFonts.poppins(
                  color: AppColors.sub.withOpacity(0.7), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
