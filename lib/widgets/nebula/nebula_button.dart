import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/colors.dart';

/// Nebula premium button — gradient + outer glow + inner highlight + scale
class NebulaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final bool disabled;
  final List<Color>? gradient;
  final double height;
  final bool expand;
  final bool glow;

  const NebulaButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
    this.disabled = false,
    this.gradient,
    this.height = 56,
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
      duration: const Duration(milliseconds: 140),
    );
    _scale =
        Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _disabled => widget.disabled || widget.loading;

  @override
  Widget build(BuildContext context) {
    final grad = widget.gradient ?? AppColors.gradCosmic;

    Widget body = Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: grad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(widget.height / 2),
        boxShadow: _disabled || !widget.glow
            ? null
            : [
                BoxShadow(
                  color: grad.first.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: grad.last.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Inner highlight (top gloss)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: Container(
              height: widget.height / 2.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(widget.height / 2)),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _disabled
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onTap?.call();
                    },
              onTapDown: _disabled ? null : (_) => _ctrl.forward(),
              onTapUp: _disabled ? null : (_) => _ctrl.reverse(),
              onTapCancel: _ctrl.reverse,
              borderRadius: BorderRadius.circular(widget.height / 2),
              splashColor: Colors.white.withOpacity(0.15),
              highlightColor: Colors.white.withOpacity(0.08),
              child: Container(
                alignment: Alignment.center,
                height: widget.height,
                child: widget.loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    body = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _disabled ? 0.55 : 1.0,
      child: ScaleTransition(scale: _scale, child: body),
    );

    return widget.expand ? SizedBox(width: double.infinity, child: body) : body;
  }
}
