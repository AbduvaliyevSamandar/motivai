import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';

/// Six independent slot-style OTP input. Calls [onChanged] with the
/// concatenated string and [onComplete] when all 6 digits are filled.
class OtpCodeField extends StatefulWidget {
  final void Function(String value)? onChanged;
  final void Function(String value)? onComplete;
  final bool autofocus;
  final int length;
  const OtpCodeField({
    super.key,
    this.onChanged,
    this.onComplete,
    this.autofocus = true,
    this.length = 6,
  });

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focuses;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _focuses = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focuses) f.dispose();
    super.dispose();
  }

  String get _value =>
      _controllers.map((c) => c.text).join().replaceAll(RegExp(r'\D'), '');

  void _onSlotChanged(int idx, String v) {
    if (v.length > 1) {
      // Likely paste — distribute the digits.
      final digits = v.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text =
            i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, widget.length - 1);
      _focuses[next].requestFocus();
    } else {
      if (v.isNotEmpty && idx < widget.length - 1) {
        _focuses[idx + 1].requestFocus();
      }
    }
    final value = _value;
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      FocusScope.of(context).unfocus();
      widget.onComplete?.call(value);
    }
  }

  KeyEventResult _onKey(int idx, KeyEvent ev) {
    if (ev is KeyDownEvent &&
        ev.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[idx].text.isEmpty &&
        idx > 0) {
      _controllers[idx - 1].clear();
      _focuses[idx - 1].requestFocus();
      widget.onChanged?.call(_value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        return SizedBox(
          width: 44,
          height: 56,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (ev) => _onKey(i, ev),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focuses[i],
              autofocus: widget.autofocus && i == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.6),
                ),
              ),
              onChanged: (v) => _onSlotChanged(i, v),
            ),
          ),
        );
      }),
    );
  }
}
