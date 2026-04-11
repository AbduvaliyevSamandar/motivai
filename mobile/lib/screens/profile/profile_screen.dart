import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user?['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?['name'] ?? 'Foydalanuvchi',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              user?['email'] ?? '',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.getLevelColor(user?['level'] ?? 1)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${user?['level'] ?? 1}-daraja · ${user?['xp'] ?? 0} XP',
                style: TextStyle(
                  color: AppTheme.getLevelColor(user?['level'] ?? 1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Badges
            if ((user?['badges'] as List?)?.isNotEmpty == true) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: const Text('Badge\'lar',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (user?['badges'] as List).map((b) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(b['icon'] ?? '🏅',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(b['name'] ?? '',
                          style: const TextStyle(
                              color: AppTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Settings list
            _SettingsItem(
              icon: Icons.person_outline,
              title: 'Profilni tahrirlash',
              onTap: () => _editProfile(context, ref, user),
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Xabarnomalar',
              trailing: Switch(
                value: user?['notifications_push'] ?? true,
                onChanged: (v) {
                  ref.read(apiServiceProvider).updateProfile(
                      {'notifications_push': v});
                  ref.read(userProvider.notifier).refreshProfile();
                },
                activeColor: AppTheme.primary,
              ),
            ),
            _SettingsItem(
              icon: Icons.language,
              title: 'Til',
              subtitle: _langName(user?['language'] ?? 'uz'),
              onTap: () => _changeLang(context, ref),
            ),
            _SettingsItem(
              icon: Icons.info_outline,
              title: 'Ilova haqida',
              subtitle: 'MotivAI v1.0.0',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  String _langName(String lang) {
    switch (lang) {
      case 'uz': return "O'zbek";
      case 'ru': return 'Русский';
      case 'en': return 'English';
      default: return lang;
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Chiqish',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Hisobingizdan chiqishni tasdiqlaysizmi?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(userProvider.notifier).logout();
              context.go('/auth/login');
            },
            child: const Text('Chiqish',
                style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) {
    final nameCtrl = TextEditingController(text: user?['name']);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Profilni tahrirlash',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Ism'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(apiServiceProvider).updateProfile(
                      {'name': nameCtrl.text});
                  await ref.read(userProvider.notifier).refreshProfile();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeLang(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Tilni tanlang',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 8),
          ...['uz', 'ru', 'en'].map((lang) => ListTile(
            title: Text(_langName(lang),
                style: const TextStyle(color: AppTheme.textPrimary)),
            onTap: () async {
              await ref.read(apiServiceProvider).updateProfile({'language': lang});
              await ref.read(userProvider.notifier).refreshProfile();
              if (context.mounted) Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style:
                    const TextStyle(color: AppTheme.textSecondary, fontSize: 12))
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary)
                : null),
        onTap: onTap,
      ),
    );
  }
}
