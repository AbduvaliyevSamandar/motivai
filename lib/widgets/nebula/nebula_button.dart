import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';

/// Primary call-to-action button. Solid brand color, tiny shadow,
/// 12dp radius, simple scale on press. Same API as before.
class NebulaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool disabled;
  final List<Color>? gradient; // back-compat — uses first color only
  final double height;
  final bool expand;
  final bool glow; // back-compat — ignored

  const NebulaButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.disabled = false,
    this.gradient,
    this.height = 52,
    this.expand = true,
    this.glow = true,
  });

  @override
  State<NebulaButton> createState() => _NebulaButtonState();
}

class _NebulaButtonState extends State<NebulaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _disabled => widget.disabled || widget.loading;

  @override
  Widget build(BuildContext context) {
    // Use the first color of the supplied gradient (if any) so callers
    // that still pass [gradient] keep their accent.
    final base = (widget.gradient != null && widget.gradient!.isNotEmpty)
        ? widget.gradient!.first
        : AppColors.primary;

    Widget body = Container(
      height: widget.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _disabled
            ? base.withOpacity(0.3)
            : base,
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );

    body = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _disabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap?.call();
              },
        onTapDown: _disabled ? null : (_) => _ctrl.forward(),
        onTapUp: _disabled ? null : (_) => _ctrl.reverse(),
        onTapCancel: _ctrl.reverse,
        splashColor: Colors.white.withOpacity(0.08),
        highlightColor: Colors.white.withOpacity(0.05),
        child: body,
      ),
    );

    body = ScaleTransition(scale: _scale, child: body);
    return widget.expand ? SizedBox(width: double.infinity, child: body) : body;
  }
}
