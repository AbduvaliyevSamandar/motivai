import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
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
              content: Text(S.get('done'), style: GoogleFonts.poppins()),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // -- Gradient Header --
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 260,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(auth, mq),
            ),
          ),

          // -- Content --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: D.sp20),
              child: Column(children: [
                const SizedBox(height: D.sp24),

                // Stats Grid
                _buildStatsGrid(auth),
                const SizedBox(height: 28),

                // Settings section
                _buildSectionHeader(S.get('settings')),
                const SizedBox(height: D.sp12),

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
                    activeColor: AppColors.primary,
                    activeTrackColor:
                        AppColors.primary.withValues(alpha: 0.3),
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
                const SizedBox(height: D.sp12),

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
                  color: AppColors.danger,
                  onTap: () => _confirmLogout(auth),
                ),

                const SizedBox(height: D.sp32),
                Text(
                  'MotivAI v2.1.0',
                  style: GoogleFonts.poppins(
                    color: AppColors.sub.withValues(alpha: 0.5),
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

  // -- Header with gradient ----------------------------------
  Widget _buildHeader(AuthProvider auth, MediaQueryData mq) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.bg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(D.sp20, D.sp16, D.sp20, D.sp24),
          child: Column(children: [
            const SizedBox(height: D.sp8),

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
                            color: AppColors.primary.withValues(
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
                        gradient: const LinearGradient(
                            colors: AppColors.gradPrimary),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.3),
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

            const SizedBox(height: D.sp16),

            // Name
            Text(
              auth.name,
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: D.sp4),

            // Email
            Text(
              auth.email,
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 14),

            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: D.sp16, vertical: D.sp8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.gradPrimary),
                borderRadius: BorderRadius.circular(D.sp24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
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
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: D.sp8),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    '${auth.points} XP',
                    style: GoogleFonts.poppins(
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

  // -- Avatar widget -----------------------------------------
  Widget _buildAvatar(AuthProvider auth) {
    final hasLocal = _localAvatar != null && _localAvatar!.isNotEmpty;
    final hasNetwork =
        auth.avatarUrl != null && auth.avatarUrl!.startsWith('http');

    Widget avatarImage;
    if (hasLocal) {
      if (!kIsWeb) {
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
        gradient: (hasLocal || hasNetwork)
            ? null
            : const LinearGradient(colors: AppColors.gradPrimary),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
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
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // -- Stats Grid --------------------------------------------
  Widget _buildStatsGrid(AuthProvider auth) {
    final stats = [
      _StatData(Icons.star_rounded, AppColors.gradGold, '${auth.points}', 'XP'),
      _StatData(Icons.local_fire_department_rounded, AppColors.gradAccent,
          '${auth.streak}', S.get('streak')),
      _StatData(Icons.check_circle_rounded, AppColors.gradSuccess,
          '${auth.totalTasks}', S.get('tasks_label')),
      _StatData(Icons.emoji_events_rounded, AppColors.gradPrimary,
          '${auth.achiev.length}', S.get('achievements')),
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: D.sp4),
                  padding: const EdgeInsets.symmetric(vertical: D.sp16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(D.radiusLg),
                    border: Border.all(color: AppColors.border),
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
                      style: GoogleFonts.poppins(
                        color: AppColors.txt,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.label,
                      style: GoogleFonts.poppins(
                        color: AppColors.sub,
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

  // -- Section header ----------------------------------------
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          color: AppColors.sub,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // -- Setting tile ------------------------------------------
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: D.sp8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: D.sp16, vertical: 14),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: color ?? AppColors.primary, size: D.iconMd),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: color ?? AppColors.txt,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                            color: AppColors.sub, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.sub.withValues(alpha: 0.5),
                    size: 22),
            ]),
          ),
        ),
      ),
    );
  }

  // -- Change password bottom sheet --------------------------
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
            color: AppColors.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(D.sp24)),
          ),
          padding: EdgeInsets.only(
            left: D.sp24,
            right: D.sp24,
            top: D.sp16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + D.sp24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: D.sp24),
            Text(
              S.get('change_pass'),
              style: GoogleFonts.poppins(
                color: AppColors.txt,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: D.sp24),
            _passField(current, S.get('current_pass'), obs1,
                () => setS(() => obs1 = !obs1)),
            const SizedBox(height: 14),
            _passField(newPass, S.get('new_pass'), obs2,
                () => setS(() => obs2 = !obs2)),
            const SizedBox(height: 14),
            _passField(confirm, S.get('confirm_pass'), obs3,
                () => setS(() => obs3 = !obs3)),
            const SizedBox(height: D.sp24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.gradPrimary),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary.withValues(alpha: 0.3),
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
                          content: Text(S.get('min_6'),
                              style: GoogleFonts.poppins()),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                    if (newPass.text != confirm.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.get('pass_mismatch'),
                              style: GoogleFonts.poppins()),
                          backgroundColor: AppColors.danger,
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
                        content: Text(
                          ok
                              ? S.get('pass_changed')
                              : auth.error ?? S.get('error'),
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.danger,
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
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: D.sp12),
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
      style: GoogleFonts.poppins(color: AppColors.txt),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(Icons.lock_outline_rounded, color: AppColors.sub),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.sub,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  // -- Language dialog ---------------------------------------
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radiusXl),
        ),
        title: Text(
          S.get('select_lang'),
          style: GoogleFonts.poppins(
              color: AppColors.txt, fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(D.radiusMd),
        onTap: () async {
          await context.read<ThemeProvider>().setLang(code);
          if (mounted) {
            Navigator.pop(context);
            setState(() {});
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: D.sp16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(D.radiusMd),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 15,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
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

  // -- Clear cache -------------------------------------------
  void _clearCache(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radiusXl),
        ),
        title: Text(S.get('clear_cache'),
            style: GoogleFonts.poppins(
                color: AppColors.txt, fontWeight: FontWeight.bold)),
        content: Text(
          S.get('clear_cache'),
          style: GoogleFonts.poppins(color: AppColors.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'),
                style: GoogleFonts.poppins(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(S.get('done'), style: GoogleFonts.poppins()),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(S.get('clear_cache'),
                style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // -- Logout confirmation -----------------------------------
  void _confirmLogout(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(D.radiusXl),
        ),
        title: Text(S.get('logout'),
            style: GoogleFonts.poppins(
                color: AppColors.txt, fontWeight: FontWeight.bold)),
        content: Text(
          S.get('logout_confirm'),
          style: GoogleFonts.poppins(color: AppColors.sub, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'),
                style: GoogleFonts.poppins(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child:
                Text(S.get('logout'), style: GoogleFonts.poppins()),
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
