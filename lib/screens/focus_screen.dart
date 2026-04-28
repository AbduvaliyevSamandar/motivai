import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/colors.dart';
import '../services/pomodoro.dart';
import '../services/ambient_sounds.dart';
import '../services/journey_storage.dart';
import '../widgets/nebula/nebula.dart';

/// Opens a full-screen Pomodoro session. Returns minutes focused when closed.
Future<int?> startPomodoro(
  BuildContext context, {
  required String taskId,
  required String taskTitle,
}) {
  return Navigator.of(context).push<int?>(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) =>
          FocusScreen(taskId: taskId, taskTitle: taskTitle),
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(a),
          child: c,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

class FocusScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  const FocusScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late final PomodoroSession _session;
  AmbientSound _ambient = AmbientSounds.none;

  @override
  void initState() {
    super.initState();
    _session = PomodoroSession(
      taskId: widget.taskId,
      taskTitle: widget.taskTitle,
    );
    _session.addListener(_tick);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _loadAmbient();
  }

  Future<void> _loadAmbient() async {
    final s = await AmbientSounds.selected();
    if (mounted) setState(() => _ambient = s);
  }

  Future<void> _pickAmbient() async {
    HapticFeedback.selectionClick();
    final chosen = await showModalBottomSheet<AmbientSound>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Fon ovozi',
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tez orada chalinadi (infratuzilma tayyor)',
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AmbientSounds.all.map((s) {
                final sel = s.id == _ambient.id;
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: sel
                          ? LinearGradient(colors: [
                              s.color.withOpacity(0.3),
                              s.color.withOpacity(0.15),
                            ])
                          : null,
                      color: sel ? null : AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? s.color.withOpacity(0.6)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          s.name,
                          style: GoogleFonts.poppins(
                            color: sel ? s.color : AppColors.txt,
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      await AmbientSounds.select(chosen.id);
      if (mounted) setState(() => _ambient = chosen);
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_tick);
    _session.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _exit() {
    HapticFeedback.mediumImpact();
    final minutes = _session.stop();
    if (minutes > 0) {
      JourneyStorage.recordFocusMinutes(minutes);
    }
    Navigator.of(context).pop<int?>(minutes);
  }

  Future<void> _confirmExit() async {
    if (_session.totalFocusedMinutes == 0) {
      _exit();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Sessiyani to\'xtatilsinmi?',
          style: GoogleFonts.poppins(
            color: AppColors.txt,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          '${_session.totalFocusedMinutes} daqiqa fokuslangansiz. '
          'Bu vaqt saqlanadi.',
          style: GoogleFonts.poppins(color: AppColors.sub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Davom etish',
                style: GoogleFonts.poppins(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text("To'xtatish", style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok == true) _exit();
  }

  @override
  Widget build(BuildContext context) {
    final isFocus = _session.isFocus;
    final gradient = isFocus
        ? AppColors.gradCosmic
        : _session.phase == PomodoroPhase.longBreak
            ? AppColors.gradSuccess
            : AppColors.gradCyan;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF08091A),
        body: Stack(
          children: [
            const AuroraBackground(subtle: true),
            const ParticleField(count: 24),
            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Material(
                          color: AppColors.card.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _confirmExit,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.border),
                              ),
                              child: const Icon(LucideIcons.x,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Material(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _pickAmbient,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_ambient.emoji,
                                      style: const TextStyle(
                                          fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _ambient.name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white
                                          .withOpacity(0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PhaseBadge(
                          label: _session.phaseLabel,
                          cycle: _session.cycle,
                          gradient: gradient,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Task title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.taskTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Big ring with countdown
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: XPRing(
                      progress: _session.progress,
                      size: 280,
                      strokeWidth: 14,
                      gradientColors: gradient,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTime(_session.remaining),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -3,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isFocus ? 'FOKUS' : 'DAM OLISH',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatPill(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Tsikl',
                        value: '${_session.cycle}',
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        icon: LucideIcons.timer,
                        label: 'Fokus',
                        value: '${_session.totalFocusedMinutes} min',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ControlBtn(
                            icon: LucideIcons.skipForward,
                            label: "O'tkazib yuborish",
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _session.skip();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: NebulaButton(
                            label: _session.isPaused
                                ? 'Davom etish'
                                : 'Pauza',
                            icon: _session.isPaused
                                ? LucideIcons.play
                                : LucideIcons.pause,
                            gradient: gradient,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              _session.togglePause();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PhaseBadge extends StatelessWidget {
  final String label;
  final int cycle;
  final List<Color> gradient;
  const _PhaseBadge({
    required this.label,
    required this.cycle,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.5),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.timer, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label \u2022 #$cycle',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
