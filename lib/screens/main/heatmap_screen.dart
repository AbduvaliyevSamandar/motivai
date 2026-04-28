import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/colors.dart';
import '../../services/journey_storage.dart';
import '../../widgets/nebula/nebula.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  List<List<int>> _grid = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await JourneyStorage.heatmap();
    if (!mounted) return;
    setState(() {
      _grid = g;
      _loading = false;
    });
  }

  int get _max {
    var m = 1;
    for (final row in _grid) {
      for (final v in row) {
        if (v > m) m = v;
      }
    }
    return m;
  }

  /// Best hour of day — average across weekdays
  ({int hour, double avg}) _bestHour() {
    if (_grid.isEmpty) return (hour: 0, avg: 0);
    int bestH = 0;
    double bestAvg = 0;
    for (var h = 0; h < 24; h++) {
      var sum = 0;
      for (var d = 0; d < 7; d++) {
        sum += _grid[d][h];
      }
      final avg = sum / 7;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestH = h;
      }
    }
    return (hour: bestH, avg: bestAvg);
  }

  ({int day, int count}) _bestDay() {
    if (_grid.isEmpty) return (day: 0, count: 0);
    int bestD = 0;
    int bestC = 0;
    for (var d = 0; d < 7; d++) {
      final sum = _grid[d].fold<int>(0, (a, b) => a + b);
      if (sum > bestC) {
        bestC = sum;
        bestD = d;
      }
    }
    return (day: bestD, count: bestC);
  }

  static const _dayNames = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: AppColors.titleGradient,
          ).createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text('Mahsuldorlik',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              )),
        ),
      ),
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 22),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _insightRow(),
                        const SizedBox(height: 20),
                        _heatmapCard(),
                        const SizedBox(height: 20),
                        _legend(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _insightRow() {
    final bestH = _bestHour();
    final bestD = _bestDay();
    final hourLabel = '${bestH.hour.toString().padLeft(2, '0')}:00';
    final dayLabel = _dayNames[bestD.day];
    return Row(
      children: [
        Expanded(
          child: _insightCard(
            icon: LucideIcons.clock,
            color: AppColors.primary,
            label: 'Eng faol soat',
            value: bestH.avg == 0 ? '—' : hourLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _insightCard(
            icon: LucideIcons.calendar,
            color: AppColors.success,
            label: 'Eng mahsuldor kun',
            value: bestD.count == 0 ? '—' : dayLabel,
          ),
        ),
      ],
    );
  }

  Widget _insightCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.sub, fontSize: 10)),
          Text(value,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _heatmapCard() {
    final max = _max;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.grid,
                  color: AppColors.pink, size: 18),
              const SizedBox(width: 6),
              Text('Soat × kun',
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              Text('Oxirgi 8 hafta',
                  style: GoogleFonts.poppins(
                      color: AppColors.sub, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                // Hour labels (0, 3, 6, 9, 12, 15, 18, 21)
                Row(
                  children: [
                    const SizedBox(width: 28),
                    for (var h = 0; h < 24; h++)
                      Container(
                        width: 12,
                        alignment: Alignment.center,
                        child: h % 3 == 0
                            ? Text(
                                h.toString(),
                                style: GoogleFonts.poppins(
                                  color: AppColors.sub,
                                  fontSize: 8,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                for (var d = 0; d < 7; d++) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          _dayNames[d],
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      for (var h = 0; h < 24; h++) _cell(_grid[d][h], max),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(int value, int max) {
    final intensity = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final c = intensity == 0
        ? AppColors.border.withOpacity(0.5)
        : AppColors.primary.withOpacity(0.15 + intensity * 0.75);
    return Container(
      width: 10,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _legend() {
    return Row(
      children: [
        Text('Kam',
            style: GoogleFonts.poppins(
                color: AppColors.sub, fontSize: 11)),
        const SizedBox(width: 8),
        for (final op in [0.15, 0.35, 0.55, 0.75, 0.95])
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(op),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 8),
        Text('Ko\'p',
            style: GoogleFonts.poppins(
                color: AppColors.sub, fontSize: 11)),
      ],
    );
  }
}
