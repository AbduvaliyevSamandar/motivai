import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CompletionDialog extends StatefulWidget {
  final Map<String, dynamic> result;
  final String taskTitle;
  const CompletionDialog(
      {super.key,
      required this.result,
      required this.taskTitle});

  @override
  State<CompletionDialog> createState() =>
      _CompletionDialogState();
}

class _CompletionDialogState extends State<CompletionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(
            parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(
        parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r         = widget.result;
    final pts       = r['points_earned']    ?? 0;
    final streak    = r['current_streak']   ?? 0;
    final levelUp   = r['level_up'] == true;
    final newLevel  = r['new_level'];
    final newAchiev = (r['new_achievements'] as List?) ?? [];

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: C.primary.withOpacity(0.4),
                  width: 1.5),
              boxShadow: [BoxShadow(
                  color: C.primary.withOpacity(0.2),
                  blurRadius: 30)],
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Icon
              Text(levelUp ? '🚀' : '✅',
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),

              // Title
              if (levelUp) ...[
                ShaderMask(
                  shaderCallback: (r) =>
                      const LinearGradient(
                              colors: C.gradGold)
                          .createShader(r),
                  child: Text(
                    'DARAJA OSHDI! $newLevel-DARAJA',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ] else
                const Text('Bajarildi! 💪',
                    style: TextStyle(
                        color: C.txt,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),

              const SizedBox(height: 6),
              Text(widget.taskTitle,
                  style: const TextStyle(
                      color: C.sub, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),

              // Stats
              Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                _S('⭐', '+$pts', 'Ball'),
                _S('🔥', '$streak', 'Streak'),
                if (newLevel != null)
                  _S('🎯', '$newLevel', 'Daraja'),
              ]),

              // New achievements
              if (newAchiev.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.gold.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            C.gold.withOpacity(0.3))),
                  child: Column(children: [
                    const Text('🏆 Yangi yutuq!',
                        style: TextStyle(
                            color: C.gold,
                            fontWeight:
                                FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...newAchiev.map((a) => Text(
                          '${a['emoji'] ?? '🎖'} '
                          '${a['name'] ?? ''}',
                          style: const TextStyle(
                              color: C.txt,
                              fontSize: 13),
                        )),
                  ]),
                ),
              ],

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: C.gradPrimary),
                    borderRadius:
                        BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('Davom etish',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _S extends StatelessWidget {
  final String e, v, l;
  const _S(this.e, this.v, this.l);
  @override
  Widget build(BuildContext context) =>
      Column(children: [
        Text(e, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(v,
            style: const TextStyle(
                color: C.txt,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(l,
            style: const TextStyle(
                color: C.sub, fontSize: 11)),
      ]);
}
