import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  String? _localAvatar;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
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
      HapticFeedback.lightImpact();
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(auth)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: D.sp16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: D.sp20),
                  _buildStatsGrid(auth),
                  const SizedBox(height: D.sp24),
                  _SectionHeader(title: S.get('settings')),
                  const SizedBox(height: D.sp12),
                  _SettingTile(
                    icon: theme.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    iconColor: AppColors.primary,
                    title: theme.isDark
                        ? S.get('dark_mode')
                        : S.get('light_mode'),
                    trailing: Switch.adaptive(
                      value: theme.isDark,
                      activeColor: AppColors.primary,
                      activeTrackColor:
                          AppColors.primary.withOpacity(0.3),
                      onChanged: (_) {
                        HapticFeedback.selectionClick();
                        theme.toggle();
                      },
                    ),
                  ),
                  _SettingTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.info,
                    title: S.get('change_pass'),
                    onTap: _showChangePassword,
                  ),
                  _SettingTile(
                    icon: Icons.translate_rounded,
                    iconColor: AppColors.secondary,
                    title: S.get('language'),
                    subtitle: _langName(S.lang),
                    onTap: _showLanguageDialog,
                  ),
                  _SettingTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.accent,
                    title: S.get('notifications'),
                    subtitle: S.get('coming_soon'),
                    onTap: () {},
                  ),
                  const SizedBox(height: D.sp24),
                  _SectionHeader(title: S.get('account')),
                  const SizedBox(height: D.sp12),
                  _SettingTile(
                    icon: Icons.cleaning_services_outlined,
                    iconColor: AppColors.accent,
                    title: S.get('clear_cache'),
                    onTap: () => _clearCache(auth),
                  ),
                  _SettingTile(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.danger,
                    title: S.get('logout'),
                    color: AppColors.danger,
                    onTap: () => _confirmLogout(auth),
                  ),
                  const SizedBox(height: D.sp32),
                  Text(
                    'MotivAI v2.1.0',
                    style: GoogleFonts.poppins(
                      color: AppColors.sub.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    // XP progress toward next level — estimate using level cap
    final nextTarget = (auth.level + 1) * 100;
    final ratio = nextTarget > 0
        ? (auth.points % 100) / 100
        : 0.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(D.sp20, D.sp16, D.sp20, D.sp32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircularPercentIndicator(
                          radius: 58,
                          lineWidth: 5,
                          percent: ratio.clamp(0.0, 1.0),
                          backgroundColor:
                              Colors.white.withOpacity(0.2),
                          progressColor: Colors.white,
                          circularStrokeCap: CircularStrokeCap.round,
                          center: _buildAvatar(auth),
                          animation: true,
                          animationDuration: 900,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
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
                  Text(
                    auth.name.isEmpty ? 'User' : auth.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.email,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: D.sp12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: D.sp16, vertical: D.sp8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(D.sp24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35)),
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: D.sp8),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          '${auth.points} XP',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AuthProvider auth) {
    final hasLocal = _localAvatar != null && _localAvatar!.isNotEmpty;
    final hasNetwork =
        auth.avatarUrl != null && auth.avatarUrl!.startsWith('http');

    Widget img;
    if (hasLocal && !kIsWeb) {
      final file = File(_localAvatar!);
      if (file.existsSync()) {
        img = ClipOval(
          child: Image.file(
            file,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialLetter(auth),
          ),
        );
      } else {
        img = _initialLetter(auth);
      }
    } else if (hasLocal && kIsWeb) {
      img = ClipOval(
        child: Image.network(
          _localAvatar!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialLetter(auth),
        ),
      );
    } else if (hasNetwork) {
      img = ClipOval(
        child: Image.network(
          auth.avatarUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialLetter(auth),
        ),
      );
    } else {
      img = _initialLetter(auth);
    }

    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.secondary.withOpacity(0.2),
              ],
            ),
          ),
          child: img,
        ),
      ),
    );
  }

  Widget _initialLetter(AuthProvider auth) {
    final letter =
        auth.name.isNotEmpty ? auth.name[0].toUpperCase() : 'U';
    return Center(
      child: ShaderMask(
        shaderCallback: (r) =>
            const LinearGradient(colors: AppColors.gradPrimary)
                .createShader(r),
        blendMode: BlendMode.srcIn,
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AuthProvider auth) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: D.sp12,
      crossAxisSpacing: D.sp12,
      childAspectRatio: 1.55,
      children: [
        StatCard(
          icon: Icons.star_rounded,
          value: '${auth.points}',
          label: 'XP',
          gradient: AppColors.gradGold,
        ),
        StatCard(
          icon: Icons.local_fire_department_rounded,
          value: '${auth.streak}',
          label: S.get('streak'),
          gradient: AppColors.gradAccent,
        ),
        StatCard(
          icon: Icons.check_circle_rounded,
          value: '${auth.totalTasks}',
          label: S.get('tasks_label'),
          gradient: AppColors.gradSuccess,
        ),
        StatCard(
          icon: Icons.emoji_events_rounded,
          value: '${auth.achiev.length}',
          label: S.get('achievements'),
          gradient: AppColors.gradPrimary,
        ),
      ],
    );
  }

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
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: D.sp24),
            CustomTextField(
              controller: current,
              label: S.get('current_pass'),
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obs1,
              suffixIcon: IconButton(
                icon: Icon(
                  obs1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.sub,
                ),
                onPressed: () => setS(() => obs1 = !obs1),
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: newPass,
              label: S.get('new_pass'),
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obs2,
              suffixIcon: IconButton(
                icon: Icon(
                  obs2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.sub,
                ),
                onPressed: () => setS(() => obs2 = !obs2),
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: confirm,
              label: S.get('confirm_pass'),
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obs3,
              suffixIcon: IconButton(
                icon: Icon(
                  obs3
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.sub,
                ),
                onPressed: () => setS(() => obs3 = !obs3),
              ),
            ),
            const SizedBox(height: D.sp24),
            GradientButton(
              label: S.get('save'),
              icon: Icons.check_rounded,
              onTap: () async {
                if (newPass.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.get('min_6'),
                          style: GoogleFonts.poppins()),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
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
                      behavior: SnackBarBehavior.floating,
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
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: D.sp12),
          ]),
        ),
      ),
    );
  }

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
              color: AppColors.txt, fontWeight: FontWeight.w700),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _langTile("O'zbek", 'uz', '\u{1F1FA}\u{1F1FF}'),
          const SizedBox(height: 6),
          _langTile('Русский', 'ru', '\u{1F1F7}\u{1F1FA}'),
          const SizedBox(height: 6),
          _langTile('English', 'en', '\u{1F1EC}\u{1F1E7}'),
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
          HapticFeedback.selectionClick();
          await context.read<ThemeProvider>().setLang(code);
          if (mounted) {
            Navigator.pop(context);
            setState(() {});
          }
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: D.sp16, vertical: 14),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.secondary.withOpacity(0.06),
                  ])
                : null,
            color: isActive ? null : Colors.transparent,
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
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              const Icon(Icons.check_circle_rounded,
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
                color: AppColors.txt, fontWeight: FontWeight.w700)),
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
                  behavior: SnackBarBehavior.floating,
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
                color: AppColors.txt, fontWeight: FontWeight.w700)),
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
            child: Text(S.get('logout'), style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradPrimary,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: D.sp8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: D.sp16, vertical: 14),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: D.iconMd),
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
                        subtitle!,
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
                    color: AppColors.sub.withOpacity(0.5), size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}
