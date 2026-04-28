import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lucide_icons/lucide_icons.dart';
import '../config/colors.dart';

/// Circular mic button — tap to start, tap again to stop.
/// Streams partial recognition into the given controller.
class VoiceInputButton extends StatefulWidget {
  final TextEditingController controller;
  final String locale;
  final bool append;
  const VoiceInputButton({
    super.key,
    required this.controller,
    this.locale = 'uz_UZ',
    this.append = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  double _level = 0;
  String _base = '';
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) return; // speech not reliable on web
    try {
      final ok = await _speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'notListening' || s == 'done') {
            setState(() => _listening = false);
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _listening = false);
        },
      );
      if (mounted) setState(() => _available = ok);
    } catch (_) {
      // ignore — button will show unavailable state
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_available) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ovozli kirish mavjud emas',
            style: GoogleFonts.poppins()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_listening) {
      HapticFeedback.mediumImpact();
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    HapticFeedback.selectionClick();
    _base = widget.append ? widget.controller.text : '';
    setState(() => _listening = true);
    try {
      await _speech.listen(
        localeId: widget.locale,
        onResult: (r) {
          if (!mounted) return;
          final text = r.recognizedWords;
          final joined = _base.isEmpty ? text : '$_base $text';
          widget.controller.text = joined;
          widget.controller.selection = TextSelection.collapsed(
              offset: widget.controller.text.length);
        },
        onSoundLevelChange: (l) {
          if (!mounted) return;
          setState(() => _level = l);
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      );
    } catch (_) {
      setState(() => _listening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: _listening
                ? LinearGradient(colors: [
                    AppColors.danger,
                    AppColors.pink,
                  ])
                : LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.35),
                    AppColors.secondary.withOpacity(0.2),
                  ]),
            shape: BoxShape.circle,
            border: Border.all(
              color: _listening
                  ? AppColors.danger
                  : AppColors.primary.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: _listening
                ? [
                    BoxShadow(
                      color: AppColors.danger.withOpacity(0.4 +
                          (_level.clamp(0, 10) / 20)),
                      blurRadius: 14 + _level.clamp(0, 10),
                      spreadRadius: 1.5,
                    )
                  ]
                : null,
          ),
          child: Icon(
            _listening ? LucideIcons.square : LucideIcons.mic,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
