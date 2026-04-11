import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _currentPage = 0;

  final List<_OnboardPage> _pages = [
    _OnboardPage(
      emoji: '🤖',
      title: 'AI bilan Suhbat',
      subtitle: 'Claude AI bilan muloqot qilib, o\'zingizga mos shaxsiy motivatsiya rejasini tuzing',
      gradient: [const Color(0xFF6C63FF), const Color(0xFF3F3D56)],
    ),
    _OnboardPage(
      emoji: '🎯',
      title: 'Shaxsiy Rejalar',
      subtitle: 'Maqsadlaringizga mos kunlik, haftalik va oylik rejalar tuzib, ketma-ket bajarib boring',
      gradient: [const Color(0xFF00D4AA), const Color(0xFF006B55)],
    ),
    _OnboardPage(
      emoji: '🏆',
      title: 'Global Raqobat',
      subtitle: 'Dunyo talabalar bilan raqobatlashing, XP to\'plang va o\'z darajangizni oshiring',
      gradient: [const Color(0xFFFF6B6B), const Color(0xFF9B2335)],
    ),
    _OnboardPage(
      emoji: '🔥',
      title: 'Streak Saqlang',
      subtitle: 'Har kuni bir vazifa bajaring, streak saqlang va maxsus badge\'lar qozonib boring',
      gradient: [const Color(0xFFFFD700), const Color(0xFF856000)],
    ),
  ];

  void _next() async {
    if (_currentPage < _pages.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      await StorageService.setOnboardingDone();
      if (mounted) context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardPageWidget(page: _pages[i]),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _ctrl.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Orqaga'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Boshlash 🚀'
                                : 'Keyingisi',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _OnboardPageWidget extends StatelessWidget {
  final _OnboardPage page;

  const _OnboardPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: page.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(page.emoji, style: const TextStyle(fontSize: 96)),
              const SizedBox(height: 32),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
