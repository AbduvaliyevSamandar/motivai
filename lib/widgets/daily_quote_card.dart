import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/colors.dart';
import '../services/daily_quotes.dart';
import 'nebula/nebula.dart';

/// Swipeable daily quote card. Starts on today's quote.
class DailyQuoteCard extends StatefulWidget {
  const DailyQuoteCard({super.key});

  @override
  State<DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends State<DailyQuoteCard> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Start at today's quote. Find its index by searching.
    final todayText = DailyQuotes.today().text;
    for (var i = 0; i < DailyQuotes.total; i++) {
      if (DailyQuotes.byIndex(i).text == todayText) {
        _index = i;
        break;
      }
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    setState(() => _index = DailyQuotes.next(_index));
  }

  void _prev() {
    HapticFeedback.selectionClick();
    setState(() => _index = DailyQuotes.prev(_index));
  }

  @override
  Widget build(BuildContext context) {
    final q = DailyQuotes.byIndex(_index);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200) {
          _next();
        } else if (v > 200) {
          _prev();
        }
      },
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        glowColors: [AppColors.primary, AppColors.pink],
        glowIntensity: 0.15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: AppColors.gradCosmic),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.quote,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  'KUN IQTIBOSI',
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    key: ValueKey(_index),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _navBtn(LucideIcons.chevronLeft, _prev),
                      const SizedBox(width: 4),
                      _navBtn(LucideIcons.chevronRight, _next),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(_index),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u201C${q.text}\u201D',
                    style: GoogleFonts.poppins(
                      color: AppColors.txt,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 1.5,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        q.author,
                        style: GoogleFonts.poppins(
                          color: AppColors.sub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.sub, size: 16),
        ),
      ),
    );
  }
}
