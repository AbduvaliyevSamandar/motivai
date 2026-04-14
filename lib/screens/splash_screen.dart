// ═══════════════════════════════════════════════════════
//  lib/screens/splash_screen.dart
// ═══════════════════════════════════════════════════════
// SAVE AS: lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: C.gradPrimary,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: C.primary.withOpacity(0.4),
                  blurRadius: 24, spreadRadius: 2)],
              ),
              child: const Center(
                  child: Text('🚀',
                      style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 20),
            const Text('MotivAI',
                style: TextStyle(
                    color: C.txt, fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text('Yuklanmoqda...',
                style: TextStyle(color: C.sub, fontSize: 14)),
            const SizedBox(height: 40),
            SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                color: C.primary.withOpacity(0.8),
                strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
