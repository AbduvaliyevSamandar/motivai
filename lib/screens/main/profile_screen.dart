import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/theme.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? _localAvatar;
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadAvatar();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final auth = context.read<AuthProvider>();
    final path = await auth.getLocalAvatar();
    if (mounted && path != null) {
      setState(() => _localAvatar = path);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (img != null && mounted) {
        final auth = context.read<AuthProvider>();
        await auth.updateAvatar(img.path);
        setState(() => _localAvatar = img.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.get('done')),
              backgroundColor: C.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Rasm yuklanmasa xato ko'rsatmaslik - shunchaki ignore qilamiz
      debugPrint('Image picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: C.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient Header ──
          SliverToBoxAdapter(
            child: _buildHeader(auth, mq),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                const SizedBox(height: 24),

                // Stats Grid
                _buildStatsGrid(auth),
                const SizedBox(height: 28),

                // Settings section
                _buildSectionHeader(S.get('settings')),
                const SizedBox(height: 12),

                // Theme toggle
                _buildSettingTile(
                  icon: theme.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: theme.isDark
                      ? S.get('dark_mode')
                      : S.get('light_mode'),
                  trailing: Switch.adaptive(
                    value: theme.isDark,
                    activeColor: C.primary,
                    activeTrackColor: C.primary.withValues(alpha: 0.3),
                    onChanged: (_) => theme.toggle(),
                  ),
                ),

                // Change password
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: S.get('change_pass'),
                  onTap: _showChangePassword,
                ),

                // Language
                _buildSettingTile(
                  icon: Icons.translate_rounded,
                  title: S.get('language'),
                  subtitle: _langName(S.lang),
                  onTap: _showLanguageDialog,
                ),

                // Notifications
                _buildSettingTile(
                  icon: Icons.notifications_outlined,
                  title: S.get('notifications'),
                  subtitle: S.get('coming_soon'),
                  onTap: () {},
                ),

                const SizedBox(height: 28),

                // Account section
                _buildSectionHeader(S.get('account')),
                const SizedBox(height: 12),

                // Clear cache
                _buildSettingTile(
                  icon: Icons.cleaning_services_outlined,
                  title: S.get('clear_cache'),
                  onTap: () => _clearCache(auth),
                ),

                // Logout
                _buildSettingTile(
                  icon: Icons.logout_rounded,
                  title: S.get('logout'),
                  color: C.error,
                  onTap: () => _confirmLogout(auth),
                ),

                const SizedBox(height: 32),
                Text(
                  'MotivAI v2.1.0',
                  style: TextStyle(
                    color: C.sub.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header with gradient ──────────────────────────────
  Widget _buildHeader(AuthProvider auth, MediaQueryData mq) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            C.primary.withValues(alpha: 0.25),
            C.primary.withValues(alpha: 0.08),
            C.bg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(children: [
            const SizedBox(height: 8),

            // Avatar
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  // Outer glow
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, child) => Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: C.primary.withValues(
                                alpha: 0.2 + 0.2 * _shimmer.value),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                    child: _buildAvatar(auth),
                  ),

                  // Camera icon overlay
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: C.gradPrimary),
                        shape: BoxShape.circle,
                        border: Border.all(color: C.bg, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: C.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              auth.name,
              style: TextStyle(
                color: C.txt,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            // Email
            Text(
              auth.email,
              style: TextStyle(
                color: C.sub,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 14),

            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: C.gradPrimary),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: C.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(auth.levelEmoji,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${S.get('level')} ${auth.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    '${auth.points} XP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Avatar widget ─────────────────────────────────────
  Widget _buildAvatar(AuthProvider auth) {
    final hasLocal = _localAvatar != null && _localAvatar!.isNotEmpty;
    final hasNetwork = auth.avatarUrl != null && auth.avatarUrl!.startsWith('http');

    Widget avatarImage;
    if (hasLocal) {
      if (!kIsWeb) {
        // Telefon: File dan yuklash
        final file = File(_localAvatar!);
        if (file.existsSync()) {
          avatarImage = ClipOval(
            child: Image.file(
              file,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialLetter(auth),
            ),
          );
        } else {
          avatarImage = _initialLetter(auth);
        }
      } else {
        // Web: network URL
        avatarImage = ClipOval(
          child: Image.network(
            _localAvatar!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialLetter(auth),
          ),
        );
      }
    } else if (hasNetwork) {
      avatarImage = ClipOval(
        child: Image.network(
          auth.avatarUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialLetter(auth),
        ),
      );
    } else {
      avatarImage = _initialLetter(auth);
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (hasLocal || hasNetwork) ? null : const LinearGradient(colors: C.gradPrimary),
        border: Border.all(
          color: C.primary.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
      child: avatarImage,
    );
  }

  Widget _initialLetter(AuthProvider auth) {
    final letter =
        auth.name.isNotEmpty ? auth.name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Stats Grid ────────────────────────────────────────
  Widget _buildStatsGrid(AuthProvider auth) {
    final stats = [
      _StatData(Icons.star_rounded, C.gradGold, '${auth.points}', 'XP'),
      _StatData(
          Icons.local_fire_department_rounded,
          C.gradAccent,
          '${auth.streak}',
          S.get('streak')),
      _StatData(Icons.check_circle_rounded, C.gradGreen,
          '${auth.totalTasks}', S.get('tasks_label')),
      _StatData(Icons.emoji_events_rounded, C.gradPrimary,
          '${auth.achiev.length}', S.get('achievements')),
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.border),
                  ),
                  child: Column(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: s.gradColors),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.value,
                      style: TextStyle(
                        color: C.txt,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: C.sub,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
              ))
          .toList(),
    );
  }

  // ── Section header ────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: C.sub,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Setting tile ──────────────────────────────────────
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (color ?? C.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color ?? C.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color ?? C.txt,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: C.sub, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: C.sub.withValues(alpha: 0.5), size: 22),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Change password bottom sheet ──────────────────────
  void _showChangePassword() {
    final current = TextEditingController();
    final newPass = TextEditingController();
    final confirm = TextEditingController();
    bool obs1 = true, obs2 = true, obs3 = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: C.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: C.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.get('change_pass'),
              style: TextStyle(
                color: C.txt,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _passField(current, S.get('current_pass'), obs1,
                () => setS(() => obs1 = !obs1)),
            const SizedBox(height: 14),
            _passField(newPass, S.get('new_pass'), obs2,
                () => setS(() => obs2 = !obs2)),
            const SizedBox(height: 14),
            _passField(confirm, S.get('confirm_pass'), obs3,
                () => setS(() => obs3 = !obs3)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: C.gradPrimary),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: C.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (newPass.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.get('min_6')),
                          backgroundColor: C.error,
                        ),
                      );
                      return;
                    }
                    if (newPass.text != confirm.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.get('pass_mismatch')),
                          backgroundColor: C.error,
                        ),
                      );
                      return;
                    }
                    final auth = context.read<AuthProvider>();
                    final ok = await auth.changePassword(
                      current.text,
                      newPass.text,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? S.get('pass_changed')
                            : auth.error ?? S.get('error')),
                        backgroundColor: ok ? C.success : C.error,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    S.get('save'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: C.txt),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline_rounded, color: C.sub),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: C.sub,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  // ── Language dialog ───────────────────────────────────
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          S.get('select_lang'),
          style: TextStyle(color: C.txt, fontWeight: FontWeight.bold),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _langTile("O'zbek", 'uz', '🇺🇿'),
          const SizedBox(height: 6),
          _langTile('Русский', 'ru', '🇷🇺'),
          const SizedBox(height: 6),
          _langTile('English', 'en', '🇬🇧'),
        ]),
      ),
    );
  }

  Widget _langTile(String name, String code, String flag) {
    final isActive = S.lang == code;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.read<ThemeProvider>().setLang(code);
          if (mounted) {
            Navigator.pop(context);
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? C.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? C.primary : C.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: C.txt,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle_rounded, color: C.primary, size: 22),
          ]),
        ),
      ),
    );
  }

  String _langName(String code) {
    return const {
          'uz': "O'zbek",
          'ru': 'Русский',
          'en': 'English',
        }[code] ??
        code;
  }

  // ── Clear cache ───────────────────────────────────────
  void _clearCache(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(S.get('clear_cache'),
            style: TextStyle(color: C.txt, fontWeight: FontWeight.bold)),
        content: Text(
          S.get('clear_cache'),
          style: TextStyle(color: C.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'), style: TextStyle(color: C.sub)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.get('done')),
                  backgroundColor: C.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.warning,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(S.get('clear_cache')),
          ),
        ],
      ),
    );
  }

  // ── Logout confirmation ───────────────────────────────
  void _confirmLogout(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(S.get('logout'),
            style: TextStyle(color: C.txt, fontWeight: FontWeight.bold)),
        content: Text(
          S.get('logout_confirm'),
          style: TextStyle(color: C.sub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'), style: TextStyle(color: C.sub)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.error,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(S.get('logout')),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final List<Color> gradColors;
  final String value;
  final String label;
  const _StatData(this.icon, this.gradColors, this.value, this.label);
}
