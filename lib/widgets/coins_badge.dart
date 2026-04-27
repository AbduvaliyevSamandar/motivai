import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/colors.dart';
import '../services/coins_storage.dart';

class CoinsBadge extends StatefulWidget {
  final VoidCallback? onTap;
  const CoinsBadge({super.key, this.onTap});

  @override
  State<CoinsBadge> createState() => _CoinsBadgeState();
}

class _CoinsBadgeState extends State<CoinsBadge> {
  int _coins = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await CoinsStorage.balance();
    if (mounted) setState(() => _coins = b);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.accent.withOpacity(0.25),
            AppColors.accent.withOpacity(0.1),
          ]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1FA99}', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$_coins',
              style: GoogleFonts.poppins(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
