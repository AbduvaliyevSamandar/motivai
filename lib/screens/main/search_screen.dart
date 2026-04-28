import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../providers/task_provider.dart';
import '../../services/habit_storage.dart';
import '../../services/flashcards_storage.dart';
import '../../models/models.dart';
import '../../widgets/nebula/nebula.dart';
import '../widgets/task_detail_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  List<Habit> _habits = [];
  List<Flashcard> _cards = [];
  List<FlashDeck> _decks = [];

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadExtra() async {
    final h = await HabitStorage.load();
    final c = await FlashcardsStorage.loadCards();
    final d = await FlashcardsStorage.loadDecks();
    if (mounted) setState(() {
      _habits = h;
      _cards = c;
      _decks = d;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final q = _query.toLowerCase().trim();

    final matchedTasks = q.isEmpty
        ? <Task>[]
        : tasks.all
            .where((t) =>
                t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q))
            .toList();
    final matchedHabits = q.isEmpty
        ? <Habit>[]
        : _habits
            .where((h) => h.title.toLowerCase().contains(q))
            .toList();
    final matchedDecks = q.isEmpty
        ? <FlashDeck>[]
        : _decks.where((d) => d.name.toLowerCase().contains(q)).toList();
    final matchedCards = q.isEmpty
        ? <Flashcard>[]
        : _cards
            .where((c) =>
                c.front.toLowerCase().contains(q) ||
                c.back.toLowerCase().contains(q))
            .toList();

    final total = matchedTasks.length +
        matchedHabits.length +
        matchedDecks.length +
        matchedCards.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
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
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _ctrl,
                            autofocus: true,
                            onChanged: (v) => setState(() => _query = v),
                            style: GoogleFonts.poppins(
                              color: AppColors.txt,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Qidirish...',
                              hintStyle: GoogleFonts.poppins(
                                color: AppColors.hint,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(LucideIcons.search,
                                  color: AppColors.sub, size: 20),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              suffixIcon: q.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear_rounded,
                                          color: AppColors.sub, size: 18),
                                      onPressed: () {
                                        _ctrl.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (q.isNotEmpty && total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          '$total ta natija',
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                      ],
                    ),
                  ),
                Expanded(
                  child: q.isEmpty
                      ? _emptyQuery()
                      : total == 0
                          ? _noResults()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 80),
                              children: [
                                if (matchedTasks.isNotEmpty)
                                  _section('Vazifalar',
                                      matchedTasks.length),
                                ...matchedTasks.map((t) => _TaskHit(
                                      task: t,
                                      onTap: () =>
                                          showTaskDetail(context, t),
                                    )),
                                if (matchedHabits.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _section('Odatlar',
                                      matchedHabits.length),
                                ],
                                ...matchedHabits.map(
                                    (h) => _SimpleHit(
                                          title: h.title,
                                          subtitle:
                                              '${h.currentStreak()} kun streak',
                                          emoji: h.emoji,
                                        )),
                                if (matchedDecks.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _section('Flashcards',
                                      matchedDecks.length),
                                ],
                                ...matchedDecks.map(
                                    (d) => _SimpleHit(
                                          title: d.name,
                                          subtitle: 'Flashcard deck',
                                          emoji: d.emoji,
                                        )),
                                if (matchedCards.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _section('Kartalar',
                                      matchedCards.length),
                                ],
                                ...matchedCards.map(
                                    (c) => _SimpleHit(
                                          title: c.front,
                                          subtitle: c.back,
                                          emoji: '\u{1F4C7}',
                                        )),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _emptyQuery() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.secondary.withOpacity(0.1),
                ]),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('\u{1F50D}', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nimani qidiryapsiz?',
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vazifa, odat yoki flashcard nomini yozing',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F614}', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            'Hech narsa topilmadi',
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskHit extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const _TaskHit({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: task.color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: task.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(task.emoji,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.poppins(
                          color: AppColors.txt,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description,
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (task.isCompleted)
                  Icon(LucideIcons.checkCircle2,
                      color: AppColors.success, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleHit extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  const _SimpleHit({
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: AppColors.txt,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: AppColors.sub,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
