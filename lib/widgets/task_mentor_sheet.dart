import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../config/colors.dart';
import '../models/models.dart';
import '../services/task_mentor.dart';
import 'nebula/nebula.dart';

/// Bottom sheet showing a step-by-step AI mentor plan for a specific task.
class TaskMentorSheet extends StatelessWidget {
  final Task task;
  const TaskMentorSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskMentorSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = TaskMentor.plan(
      title: task.title,
      description: task.description,
      category: task.category,
      durationMin: task.durationMinutes == 0 ? 30 : task.durationMinutes,
    );
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorder, width: 1.5),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: AppColors.gradCosmic),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.brifecase_tick,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                            colors: AppColors.titleGradient,
                          ).createShader(b),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'AI mentor',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        Text(
                          plan.title,
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  // TLDR card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.primary.withOpacity(0.22),
                        AppColors.secondary.withOpacity(0.1),
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              AppColors.primary.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Text('\u{1F4A1}',
                            style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            plan.tldr,
                            style: GoogleFonts.poppins(
                              color: AppColors.txt,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(LucideIcons.timer,
                          color: AppColors.accent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${plan.totalMinutes} daqiqa • ${plan.steps.length} qadam',
                        style: GoogleFonts.poppins(
                          color: AppColors.sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < plan.steps.length; i++)
                    _step(i + 1, plan.steps[i]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              AppColors.accent.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Text('\u{1F31F}',
                            style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            plan.closing,
                            style: GoogleFonts.poppins(
                              color: AppColors.txt,
                              fontSize: 12,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  NebulaButton(
                    label: 'Yaxshi, boshlayman',
                    icon: Iconsax.send_2,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int index, MentorStep s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: AppColors.gradCosmic),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.title,
                        style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${s.minutes}m',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.tip,
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 11,
                    height: 1.5,
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
