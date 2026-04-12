import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../models/models.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override State<AchievementsScreen> createState() => _State();
}

class _State extends State<AchievementsScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_loaded) { _loaded = true; await context.read<TaskProvider>().loadAchievements(); }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    final all   = tasks.achievements;
    final done  = all.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Row(children: [
          const Text('🏆 Yutuqlar',
              style: TextStyle(color: C.txt, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: C.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$done/${all.length}',
                style: const TextStyle(
                    color: C.primary, fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        backgroundColor: C.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: C.sub),
            onPressed: () => tasks.loadAchievements(),
          ),
        ],
      ),
      body: tasks.isLoading
          ? const Center(child: CircularProgressIndicator(color: C.primary))
          : all.isEmpty
              ? const _Empty()
              : Column(children: [
                  _ProgressBanner(done: done, total: all.length),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: all.length,
                      itemBuilder: (_, i) => _AchievCard(a: all[i]),
                    ),
                  ),
                ]),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  final int done, total;
  const _ProgressBanner({required this.done, required this.total});
  @override Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [C.gold.withOpacity(0.1), C.primary.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.gold.withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$done ta yutuq qo\'lga kiritildi',
              style: const TextStyle(color: C.txt, fontWeight: FontWeight.w600)),
          Text('${(pct * 100).toInt()}%',
              style: const TextStyle(color: C.gold, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: C.border,
            valueColor: const AlwaysStoppedAnimation(C.gold),
            minHeight: 8,
          ),
        ),
      ]),
    );
  }
}

class _AchievCard extends StatelessWidget {
  final Achievement a;
  const _AchievCard({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: a.isUnlocked ? C.card : C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.isUnlocked ? a.rarityColor.withOpacity(0.5) : C.border,
          width: a.isUnlocked ? 1.5 : 1,
        ),
        boxShadow: a.isUnlocked
            ? [BoxShadow(
                color: a.rarityColor.withOpacity(0.15),
                blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      child: Stack(children: [
        // Locked overlay
        if (!a.isUnlocked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: C.bg.withOpacity(0.4),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              Text(
                a.isUnlocked ? a.emoji : '🔒',
                style: TextStyle(
                    fontSize: a.isUnlocked ? 36 : 28),
              ),
              const SizedBox(height: 8),

              // Rarity badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: a.rarityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(a.rarityLabel,
                    style: TextStyle(
                        color: a.rarityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),

              // Name
              Text(a.name,
                  style: TextStyle(
                      color: a.isUnlocked ? C.txt : C.sub,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),

              // Description
              Text(a.description,
                  style: const TextStyle(color: C.sub, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),

              // Bonus points
              if (a.isUnlocked)
                Text('+${a.bonusPoints} ball',
                    style: const TextStyle(
                        color: C.gold, fontSize: 11,
                        fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override Widget build(BuildContext context) {
    return const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🏆', style: TextStyle(fontSize: 64)),
        SizedBox(height: 16),
        Text('Yutuqlar hali mavjud emas',
            style: TextStyle(color: C.sub, fontSize: 16)),
        SizedBox(height: 8),
        Text('Vazifalar bajaring va yutuqlar oling!',
            style: TextStyle(color: C.primary, fontSize: 13)),
      ],
    ));
  }
}
