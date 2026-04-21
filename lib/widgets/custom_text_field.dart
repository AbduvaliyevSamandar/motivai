import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../config/dimensions.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(D.radiusMd),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscureText,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        textInputAction: widget.textInputAction,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.txt,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: D.iconMd)
              : null,
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: D.sp16, vertical: 14),
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
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(D.radiusMd),
            borderSide: BorderSide(color: AppColors.danger),
          ),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.sub,
          ),
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.hint,
          ),
        ),
      ),
    );
  }
}
