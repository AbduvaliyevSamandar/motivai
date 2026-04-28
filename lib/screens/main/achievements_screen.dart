import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../config/colors.dart';
import '../../services/achievements.dart';
import '../../widgets/nebula/nebula.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<(AchievementDef, bool)> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await AchievementService.listWithStatus();
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _items.where((e) => e.$2).length;
    final total = _items.length;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 22),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.chevronLeft,
                            color: AppColors.txt, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: AppColors.titleGradient,
                        ).createShader(b),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'Yutuqlar',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: AppColors.gradCosmic),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$unlockedCount / $total',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              16, 8, 16, 40),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final (a, unlocked) = _items[i];
                            return _AchCard(def: a, unlocked: unlocked);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchCard extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;
  const _AchCard({required this.def, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final accent = def.rarityColor;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showDialog(
          context: context,
          builder: (_) => _AchDialog(def: def, unlocked: unlocked),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(colors: [
                  accent.withOpacity(0.25),
                  accent.withOpacity(0.08),
                ])
              : null,
          color: unlocked ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? accent.withOpacity(0.5)
                : AppColors.border,
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1.0 : 0.3,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unlocked
                      ? RadialGradient(colors: [
                          accent.withOpacity(0.45),
                          accent.withOpacity(0.1),
                        ])
                      : null,
                  color: unlocked ? null : AppColors.bg,
                ),
                child: Center(
                  child: Text(
                    unlocked ? def.emoji : '\u{1F512}',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              def.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: unlocked ? AppColors.txt : AppColors.sub,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withOpacity(unlocked ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                def.rarity.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: unlocked ? accent : AppColors.sub,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchDialog extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;
  const _AchDialog({required this.def, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final accent = def.rarityColor;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.card,
            Color.lerp(AppColors.card, accent, 0.08)!,
          ]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: unlocked ? 1.0 : 0.3,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accent.withOpacity(0.55),
                    accent.withOpacity(0.1),
                  ]),
                ),
                child: Center(
                  child: Text(
                    unlocked ? def.emoji : '\u{1F512}',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              def.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              def.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    def.rarity.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.star_1,
                          color: AppColors.accent, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '+${def.bonusXP}',
                        style: GoogleFonts.poppins(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            NebulaButton(
              label: unlocked ? 'Ajoyib!' : 'Qulflangan',
              icon: unlocked
                  ? LucideIcons.check
                  : LucideIcons.lock,
              disabled: !unlocked,
              gradient: unlocked
                  ? AppColors.gradSuccess
                  : AppColors.gradCosmic,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
