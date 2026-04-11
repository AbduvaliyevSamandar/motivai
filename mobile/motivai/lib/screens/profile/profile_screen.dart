// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plan_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final plans = context.watch<PlanProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox();

    final levelName = user.level < AppConstants.levelNames.length
        ? AppConstants.levelNames[user.level]
        : 'Champion';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Chiqish'),
                  content: const Text('Hisobdan chiqmoqchimisiz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Bekor qilish'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Chiqish',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await auth.logout();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  Text(user.email,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _profileStat('${user.level}', 'Daraja'),
                      _divider(),
                      _profileStat('${user.xp}', 'XP'),
                      _divider(),
                      _profileStat('${user.streak}🔥', 'Streak'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(levelName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(
              children: [
                _statCard('✅', '${user.totalTasksCompleted}', 'Bajarilgan'),
                const SizedBox(width: 12),
                _statCard('⏱️', '${user.totalStudyMinutes}', 'Daqiqa'),
                const SizedBox(width: 12),
                _statCard('🤖', '${user.aiMessagesCount}', 'AI Xabar'),
              ],
            ),
            const SizedBox(height: 24),

            // Badges
            if (user.badges.isNotEmpty) ...[
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('🏅 Badgelar (${user.badges.length})',
                      style: AppTheme.heading3)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: user.badges.map((badge) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(badge.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(badge.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Settings section
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  _settingTile(
                    Icons.person_outline,
                    "Ma'lumotlarimni tahrirlash",
                    onTap: () => _showEditProfile(context, auth),
                  ),
                  _settingDivider(),
                  _settingTile(
                    Icons.notifications_outlined,
                    "Bildirishnomalar",
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppTheme.primary,
                    ),
                  ),
                  _settingDivider(),
                  _settingTile(
                    Icons.language_outlined,
                    "Til: ${user.language == 'uz' ? "O'zbek" : user.language == 'ru' ? 'Русский' : 'English'}",
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App info
            const Text('MotivAI v1.0.0',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const Text('AI yordamida muvaffaqiyat sari',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _profileStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 30, width: 1, color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _statCard(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.primary)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(IconData icon, String title,
      {VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _settingDivider() {
    return const Divider(height: 1, color: AppTheme.divider, indent: 56);
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.user?.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Profilni tahrirlash", style: AppTheme.heading3),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Ismingiz'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await auth.updateProfile({'name': nameCtrl.text.trim()});
                  Navigator.pop(ctx);
                },
                child: const Text("Saqlash"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
