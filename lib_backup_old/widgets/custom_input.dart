import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onPasswordToggle;
  final TextInputType inputType;
  final int maxLines;

  const CustomInput({
    Key? key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isDark = false,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onPasswordToggle,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword && !widget.isPasswordVisible,
        keyboardType: widget.inputType,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        style: TextStyle(
          color: widget.isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: widget.isDark ? Colors.white38 : Colors.black38,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused
                ? Colors.white
                : (widget.isDark ? Colors.white60 : Colors.black54),
          ),
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: widget.onPasswordToggle,
                  child: Icon(
                    widget.isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: _isFocused
                        ? Colors.white
                        : (widget.isDark ? Colors.white60 : Colors.black54),
                  ),
                )
              : null,
          filled: true,
          fillColor: widget.isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isDark ? Colors.white12 : Colors.grey[200]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.isDark ? Colors.white : Colors.blue,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
