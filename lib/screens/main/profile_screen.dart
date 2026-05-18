import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../config/colors.dart';
import '../../config/strings.dart';
import '../../config/theme_presets.dart';
import '../../services/smart_reminder.dart';
import '../../services/sound_pack.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../services/export_service.dart';
import '../../widgets/nebula/nebula.dart';
import 'achievements_screen.dart';
import 'habits_screen.dart';
import 'wrapped_screen.dart';
import 'flashcards_screen.dart';
import 'journey_screen.dart';
import 'friends_screen.dart';
import 'smart_plan_screen.dart';
import 'friend_challenges_screen.dart';
import 'rituals_screen.dart';
import 'heatmap_screen.dart';
import '../../services/haptic_service.dart';

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
              content: Text(S.get('done'), style: TextStyle()),
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

    final nextTarget = (auth.level + 1) * 100;
    final ratio = nextTarget > 0 ? (auth.points % 100) / 100 : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      children: [
                        XPRing(
                          progress: ratio.clamp(0.0, 1.0),
                          size: 140,
                          strokeWidth: 8,
                          gradientColors: [AppColors.primary],
                          center: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                _buildAvatar(auth),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.bg,
                                          width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.5),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      LucideIcons.camera,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                            auth.name.isEmpty ? 'User' : auth.name,
                            style: TextStyle(
                              color: AppColors.txt,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          auth.email,
                          style: TextStyle(
                            color: AppColors.sub,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  AppColors.primary.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(auth.levelEmoji,
                                  style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(
                                '${S.get('level')} ${auth.level}',
                                style: TextStyle(
                                  color: AppColors.txt,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                  '${auth.points} XP',
                                  style: TextStyle(
                                    color: AppColors.txt,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      BentoCard(
                        icon: HugeIcons.strokeRoundedStar,
                        value: '${auth.points}',
                        label: 'XP',
                        gradient: AppColors.gradGold,
                        accent: AppColors.accent,
                      ),
                      BentoCard(
                        icon: HugeIcons.strokeRoundedFire,
                        value: '${auth.streak}',
                        label: S.get('streak'),
                        gradient: AppColors.gradFire,
                        accent: AppColors.accent,
                      ),
                      BentoCard(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        value: '${auth.totalTasks}',
                        label: S.get('tasks_label'),
                        gradient: AppColors.gradSuccess,
                        accent: AppColors.success,
                      ),
                      BentoCard(
                        icon: HugeIcons.strokeRoundedChampion,
                        value: '${auth.achiev.length}',
                        label: S.get('achievements'),
                        gradient: AppColors.gradCosmic,
                        accent: AppColors.primary,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AchievementsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _section(S.get('settings')),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _tile(
                      icon: theme.isDark
                          ? LucideIcons.moon
                          : LucideIcons.sun,
                      iconColor: AppColors.sub,
                      title: theme.auto
                          ? S.tr('Avto rejim', 'Авто режим', 'Auto mode')
                          : (theme.isDark
                              ? S.get('dark_mode')
                              : S.get('light_mode')),
                      subtitle: theme.auto
                          ? S.get('auto_theme_sub')
                          : null,
                      trailing: Switch.adaptive(
                        value: theme.isDark,
                        activeColor: AppColors.primary,
                        onChanged: theme.auto
                            ? null
                            : (_) {
                                HapticFeedback.selectionClick();
                                theme.toggle();
                              },
                      ),
                    ),
                    _tile(
                      icon: Iconsax.brush_1_copy,
                      iconColor: AppColors.info,
                      emoji: '🌗',
                      title: S.get('auto_theme'),
                      subtitle:
                          S.get('auto_dark_light'),
                      trailing: Switch.adaptive(
                        value: theme.auto,
                        activeColor: AppColors.primary,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          theme.setAuto(v);
                        },
                      ),
                    ),
                    _tile(
                      icon: LucideIcons.palette,
                      iconColor: AppColors.pink,
                      emoji: '🎨',
                      title: S.get('theme_color'),
                      subtitle:
                          '${ThemePresets.current.emoji}  ${ThemePresets.current.name}',
                      onTap: _showThemePicker,
                    ),
                    _tile(
                      icon: Iconsax.lock_1_copy,
                      iconColor: AppColors.success,
                      emoji: '🔒',
                      title: S.get('change_pass'),
                      onTap: _showChangePassword,
                    ),
                    _tile(
                      icon: Iconsax.card_copy,
                      iconColor: AppColors.info,
                      emoji: '📇',
                      title: S.get('flashcards'),
                      subtitle: S.get('flashcards'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FlashcardsScreen(),
                          ),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.activity_copy,
                      iconColor: AppColors.success,
                      emoji: '🌱',
                      title: S.get('habits'),
                      subtitle: S.get('goal_streak'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HabitsScreen(),
                          ),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.magicpen_copy,
                      iconColor: AppColors.pink,
                      emoji: '📊',
                      title: S.get('wrapped'),
                      subtitle: S.get('wrapped'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const WrappedScreen(),
                            transitionsBuilder: (_, a, __, c) =>
                                FadeTransition(opacity: a, child: c),
                          ),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.magicpen_copy,
                      iconColor: AppColors.primary,
                      emoji: '🧠',
                      title: S.get('smart_plan'),
                      subtitle: S.get('split_to_blocks'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SmartPlanScreen()),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.tree_copy,
                      iconColor: AppColors.success,
                      emoji: '🌳',
                      title: S.get('journey'),
                      subtitle: S.get('tree_30_grow'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const JourneyScreen()),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.grid_8_copy,
                      iconColor: AppColors.info,
                      emoji: '📈',
                      title: S.get('heatmap'),
                      subtitle: S.get('heatmap_sub'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HeatmapScreen()),
                        );
                      },
                    ),
                    _tile(
                      icon: LucideIcons.flower2,
                      iconColor: AppColors.accent,
                      emoji: '🌅',
                      title: S.get('rituals'),
                      subtitle: S.get('ritual_repeat_help'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RitualsScreen()),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.profile_2user_copy,
                      iconColor: AppColors.sub,
                      emoji: '👥',
                      title: S.get('friends_title'),
                      subtitle: S.get('friends_sub'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FriendsScreen()),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.cup_copy,
                      iconColor: AppColors.accent,
                      emoji: '🏆',
                      title: S.get('challenges'),
                      subtitle: S.get('challenge_friend_7day'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const FriendChallengesScreen()),
                        );
                      },
                    ),
                    _tile(
                      icon: Iconsax.translate_copy,
                      iconColor: AppColors.secondary,
                      emoji: '🌍',
                      title: S.get('language'),
                      subtitle: _langName(S.lang),
                      onTap: _showLanguageDialog,
                    ),
                    Consumer<NotificationProvider>(
                      builder: (_, np, __) => Column(children: [
                        _tile(
                          icon: Iconsax.notification_1_copy,
                          iconColor: AppColors.accent,
                          emoji: '🔔',
                          title: S.get('notifications'),
                          subtitle: np.enabled
                              ? '${np.defaultReminderMinutes} ${S.get("min_before_remind")}'
                              : S.get('reminder_off'),
                          trailing: Switch.adaptive(
                            value: np.enabled,
                            activeColor: AppColors.primary,
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              np.setEnabled(v);
                            },
                          ),
                          onTap: np.enabled ? _showReminderPicker : null,
                        ),
                        if (np.enabled)
                          _SmartReminderTile(buildTile: _tile),
                        if (np.enabled)
                          _tile(
                            icon: Iconsax.notification_1_copy,
                            iconColor: AppColors.success,
                            emoji: '🧪',
                            title: S.get('test_notif'),
                            subtitle: S.get('test_notif_sub'),
                            onTap: _testNotification,
                          ),
                        if (np.enabled)
                          _tile(
                            icon: Iconsax.music_circle_copy,
                            iconColor: AppColors.pink,
                            emoji: '🎵',
                            title: S.get('sound_pack'),
                            subtitle:
                                '${SoundPackStore.info(SoundPackStore.current).emoji}  ${SoundPackStore.info(SoundPackStore.current).name}',
                            onTap: _showSoundPackPicker,
                          ),
                      ]),
                    ),
                    _tile(
                      icon: Iconsax.mobile_copy,
                      iconColor: AppColors.secondary,
                      emoji: '📳',
                      title: S.get('haptics'),
                      subtitle:
                          '${Haptics.info(Haptics.level).emoji}  ${Haptics.info(Haptics.level).name}',
                      onTap: _showHapticPicker,
                    )
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _section(S.get('account')),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _tile(
                      icon: Iconsax.import_1_copy,
                      iconColor: AppColors.sub,
                      title: S.get('export_data_btn'),
                      subtitle: S.get('export_data_sub'),
                      onTap: _exportData,
                    ),
                    _tile(
                      icon: Iconsax.send_1_copy,
                      iconColor: AppColors.pink,
                      emoji: '📨',
                      title: S.get('share_template'),
                      subtitle: S.get('send_friend_json'),
                      onTap: _shareTemplate,
                    ),
                    _tile(
                      icon: Iconsax.export_1_copy,
                      iconColor: AppColors.success,
                      emoji: '📥',
                      title: S.get('import_template'),
                      subtitle: S.get('json_paste_help'),
                      onTap: _importTemplate,
                    ),
                    _tile(
                      icon: Iconsax.magicpen_copy,
                      iconColor: AppColors.accent,
                      title: S.get('clear_cache'),
                      onTap: () => _clearCache(auth),
                    ),
                    _tile(
                      icon: Iconsax.logout_1,
                      iconColor: AppColors.danger,
                      title: S.get('logout'),
                      color: AppColors.danger,
                      onTap: () => _confirmLogout(auth),
                    ),
                    _tile(
                      icon: Iconsax.trash,
                      iconColor: AppColors.danger,
                      title: S.get('delete_account_btn'),
                      subtitle: S.get('with_all_data'),
                      color: AppColors.danger,
                      onTap: () => _confirmDeleteAccount(auth),
                    ),
                    const SizedBox(height: 24),
                    _section(S.get('about_app')),
                    const SizedBox(height: 12),
                    _tile(
                      icon: Iconsax.info_circle,
                      iconColor: AppColors.info,
                      emoji: 'ℹ️',
                      title: S.get('about_motivai'),
                      onTap: _showAbout,
                    ),
                    _tile(
                      icon: Iconsax.message_question,
                      iconColor: AppColors.secondary,
                      emoji: '❓',
                      title: S.get('help'),
                      subtitle: S.get('guide_help_full'),
                      onTap: _showHelp,
                    ),
                    _tile(
                      icon: Iconsax.security_safe,
                      iconColor: AppColors.success,
                      emoji: '🛡️',
                      title: S.get('privacy_policy'),
                      onTap: () => _openUrl(
                          'https://abduvaliyevsamandar.github.io/motivai/privacy.html'),
                    ),
                    _tile(
                      icon: Iconsax.document_text,
                      iconColor: AppColors.info,
                      emoji: '📜',
                      title: S.get('terms_of_service'),
                      onTap: () => _openUrl(
                          'https://abduvaliyevsamandar.github.io/motivai/terms.html'),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Iconsax.flash,
                                color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            S.get('version_label'),
                            style: TextStyle(
                              color: AppColors.txt,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            S.get('ground_motto'),
                            style: TextStyle(
                              color: AppColors.sub,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: img,
    );
  }

  Widget _initialLetter(AuthProvider auth) {
    final letter =
        auth.name.isNotEmpty ? auth.name[0].toUpperCase() : 'U';
    return Center(
      child: Text(
          letter,
          style: TextStyle(
            color: AppColors.txt,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
    );
  }

  Widget _section(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppColors.sub,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
    // When an emoji is given the chip renders it as the picture-like
    // glyph (modern OS emoji = full-color illustration). Falls back to
    // the IconData if emoji is null.
    String? emoji,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              // Picture-like chip: 3-stop gradient + inner top gloss + outer
              // colored shadow gives the chip real depth. With an emoji we
              // soften the chip so the emoji's own colors shine through;
              // with an icon we keep the bold tint and put the icon on top
              // in white. Either way the chip reads as a 3D button.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, 0.5, 1],
                    colors: emoji != null
                        ? [
                            Color.alphaBlend(
                              Colors.white.withOpacity(0.55),
                              iconColor,
                            ),
                            Color.alphaBlend(
                              Colors.white.withOpacity(0.30),
                              iconColor,
                            ),
                            Color.alphaBlend(
                              Colors.white.withOpacity(0.10),
                              iconColor,
                            ),
                          ]
                        : [
                            Color.alphaBlend(
                              Colors.white.withOpacity(0.32),
                              iconColor,
                            ),
                            iconColor,
                            Color.alphaBlend(
                              Colors.black.withOpacity(0.28),
                              iconColor,
                            ),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                    ),
                    Center(
                      child: emoji != null
                          ? Text(emoji, style: const TextStyle(fontSize: 24))
                          : Icon(icon, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color ?? AppColors.txt,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                            color: AppColors.sub, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(LucideIcons.chevronRight,
                    color: AppColors.sub.withOpacity(0.4), size: 18),
            ]),
          ),
        ),
      ),
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
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.5),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.get('change_pass'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 24),
            GlassTextField(
              controller: current,
              label: S.get('current_pass'),
              prefixIcon: LucideIcons.lock,
              obscureText: obs1,
              suffixIcon: IconButton(
                icon: Icon(
                  obs1
                      ? LucideIcons.eyeOff
                      : LucideIcons.eye,
                  color: AppColors.sub,
                ),
                onPressed: () => setS(() => obs1 = !obs1),
              ),
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: newPass,
              label: S.get('new_pass'),
              prefixIcon: LucideIcons.lock,
              obscureText: obs2,
              suffixIcon: IconButton(
                icon: Icon(
                  obs2
                      ? LucideIcons.eyeOff
                      : LucideIcons.eye,
                  color: AppColors.sub,
                ),
                onPressed: () => setS(() => obs2 = !obs2),
              ),
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: confirm,
              label: S.get('confirm_pass'),
              prefixIcon: LucideIcons.lock,
              obscureText: obs3,
              suffixIcon: IconButton(
                icon: Icon(
                  obs3
                      ? LucideIcons.eyeOff
                      : LucideIcons.eye,
                  color: AppColors.sub,
                ),
                onPressed: () => setS(() => obs3 = !obs3),
              ),
            ),
            const SizedBox(height: 24),
            NebulaButton(
              label: S.get('save'),
              icon: LucideIcons.check,
              onTap: () async {
                if (newPass.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.get('min_6'),
                          style: TextStyle()),
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
                          style: TextStyle()),
                      backgroundColor: AppColors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final auth = context.read<AuthProvider>();
                final ok = await auth.changePassword(
                    current.text, newPass.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? S.get('pass_changed')
                          : auth.error ?? S.get('error'),
                      style: TextStyle(),
                    ),
                    backgroundColor:
                        ok ? AppColors.success : AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  void _showThemePicker() {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              top:
                  BorderSide(color: AppColors.glassBorder, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                  S.get('color_theme_title'),
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                S.get('color_theme_pick'),
                style: TextStyle(
                  color: AppColors.sub,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: ThemePresets.all.map((p) {
                  final active = p.id == ThemePresets.current.id;
                  return GestureDetector(
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await theme.setPreset(p.id);
                      if (ctx.mounted) setS(() {});
                      if (mounted) setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: p.primary.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? p.primary
                              : AppColors.border,
                          width: active ? 2 : 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.emoji,
                                  style: const TextStyle(fontSize: 24)),
                              if (active)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: p.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  color: AppColors.txt,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _swatch(p.primary),
                                  const SizedBox(width: 4),
                                  _swatch(p.secondary),
                                  const SizedBox(width: 4),
                                  _swatch(p.accent),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swatch(Color c) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
    );
  }

  void _showHapticPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                S.get('haptic_title'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(S.get('tap_test_now'),
                  style: TextStyle(
                      color: AppColors.sub, fontSize: 11)),
              const SizedBox(height: 20),
              ...HapticLevel.values.map((l) {
                final info = Haptics.info(l);
                final active = Haptics.level == l;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await Haptics.set(l);
                        Haptics.medium();
                        if (ctx.mounted) setS(() {});
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary.withOpacity(0.22) : AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(info.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(info.name,
                                      style: TextStyle(
                                        color: AppColors.txt,
                                        fontSize: 13,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      )),
                                  Text(info.desc,
                                      style: TextStyle(
                                        color: AppColors.sub,
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                            ),
                            if (active)
                              Icon(LucideIcons.checkCircle2,
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSoundPackPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                  S.get('sound_pack_title'),
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                S.get('notif_style_pick'),
                style: TextStyle(
                  color: AppColors.sub,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 20),
              ...SoundPack.values.map((s) {
                final info = SoundPackStore.info(s);
                final active = SoundPackStore.current == s;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await SoundPackStore.set(s);
                        if (ctx.mounted) setS(() {});
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary.withOpacity(0.22) : AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(info.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.name,
                                    style: TextStyle(
                                      color: AppColors.txt,
                                      fontSize: 13,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    info.desc,
                                    style: TextStyle(
                                      color: AppColors.sub,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (active)
                              Icon(LucideIcons.checkCircle2,
                                  color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
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
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          S.get('select_lang'),
          style: TextStyle(
              color: AppColors.txt,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3),
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
        borderRadius: BorderRadius.circular(12),
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.18) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 15,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              Icon(LucideIcons.checkCircle2,
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
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(S.get('clear_cache'),
            style: TextStyle(
                color: AppColors.txt, fontWeight: FontWeight.w700)),
        content: Text(
          S.get('clear_cache'),
          style: TextStyle(color: AppColors.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'),
                style: TextStyle(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(S.get('done'), style: TextStyle()),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF0F1028),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(S.get('clear_cache'),
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareTemplate() async {
    HapticFeedback.lightImpact();
    final bytes = await ExportService.shareTemplate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        S.tr('Template nusxa olindi ($bytes bayt). Endi do\'stingizga yuboring.', 'Шаблон скопирован ($bytes байт). Теперь отправьте другу.', 'Template copied ($bytes bytes). Now send to a friend.'),
        style: TextStyle(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _importTemplate() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              top:
                  BorderSide(color: AppColors.glassBorder, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                  S.get('import_temp'),
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                S.get('json_paste_friend'),
                style: TextStyle(
                    color: AppColors.sub, fontSize: 11),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                minLines: 5,
                maxLines: 10,
                style: TextStyle(
                    color: AppColors.txt, fontSize: 11),
                decoration: InputDecoration(
                  hintText: S.get('json_sample'),
                  hintStyle: TextStyle(
                      color: AppColors.hint, fontSize: 11),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final clip = await Clipboard.getData(
                            Clipboard.kTextPlain);
                        if (clip?.text != null) {
                          ctrl.text = clip!.text!;
                        }
                      },
                      icon: Icon(LucideIcons.clipboardPaste,
                          color: AppColors.sub, size: 18),
                      label: Text('Clipboard',
                          style: TextStyle(
                              color: AppColors.sub)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              NebulaButton(
                label: S.get('import_btn'),
                icon: Iconsax.export_1_copy,
                onTap: () async {
                  final raw = ctrl.text.trim();
                  if (raw.isEmpty) return;
                  final r = await ExportService.importTemplateJson(raw);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor:
                        r.ok ? AppColors.success : AppColors.danger,
                    content: Text(
                      r.ok
                          ? 'Qo\'shildi: ${r.habits} odat, ${r.decks} kolod, ${r.cards} karta'
                          : (r.error ?? 'Xatolik'),
                      style: TextStyle(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    HapticFeedback.lightImpact();
    final bytes = await ExportService.exportToClipboard();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(LucideIcons.checkCircle2,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.tr('Nusxa olindi ($bytes bayt)', 'Скопировано ($bytes байт)', 'Copied ($bytes bytes)'),
              style: TextStyle(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _testNotification() async {
    HapticFeedback.lightImpact();
    final np = context.read<NotificationProvider>();
    // Schedule one 5s into the future
    final when = DateTime.now().add(const Duration(seconds: 5));
    await NotificationService.instance.scheduleAt(
      id: 99999,
      title: S.get('notif_test'),
      body: S.tr('Bu sinov bildirishnomasi — hammasi ishlayapti!', 'Это тестовое уведомление — всё работает!', 'This is a test notification — everything works!'),
      at: when,
    );
    // Also add to in-app feed
    np.addAchievement(
        S.tr('Test bildirishnoma', 'Тестовое уведомление', 'Test notification'), S.get('min_arrives'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(LucideIcons.checkCircle2,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            S.get('test_notif_when'),
            style: TextStyle(),
          ),
        ],
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Iconsax.flash,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                  'MotivAI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.txt,
                    letterSpacing: -0.5,
                  ),
                ),
              Text(
                'v2.2.0',
                style: TextStyle(
                  color: AppColors.sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                S.get('app_about_full'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _aboutRow('\u{1F527}', 'Flutter + FastAPI + MongoDB'),
              const SizedBox(height: 8),
              _aboutRow('\u{1F3A8}', 'Nebula Premium design'),
              const SizedBox(height: 8),
              _aboutRow('\u{1F680}', 'Open source, Uzbekistan'),
              const SizedBox(height: 20),
              NebulaButton(
                label: S.tr('Yopish', 'Закрыть', 'Close'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutRow(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.sub,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(url);
    // Don't gate on canLaunchUrl — on Android 11+ it returns false unless
    // the queries entry is registered, even though the URL is valid.
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!launched) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        content: Text(S.get('could_not_open'),
            style: TextStyle()),
      ));
    }
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
                S.get('guide'),
                style: TextStyle(
                  color: AppColors.txt,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            const SizedBox(height: 20),
            _helpItem(LucideIcons.plus, S.get('add_task'),
                S.tr("'+' tugmasi orqali nom, vaqt, eslatma bilan qo'shing", "Через кнопку '+' добавьте имя, время, напоминание", "Via '+' add name, time and reminder")),
            _helpItem(LucideIcons.checkCircle2, S.tr('Bajarish', 'Выполнить', 'Complete'),
                S.tr("Davra tugmasini bosing yoki o'ngga swipe qiling", "Нажмите кружок или свайп вправо", "Tap the circle or swipe right")),
            _helpItem(LucideIcons.moveLeft, S.get('remove_btn'),
                S.tr("Chapga swipe qiling yoki 3-nuqta menyu", "Свайп влево или меню из 3 точек", "Swipe left or use the 3-dot menu")),
            _helpItem(LucideIcons.pointer, S.tr('Tafsilot', 'Подробнее', 'Details'),
                S.tr("Vazifani bosing — tafsilot oynasi ochiladi", "Нажмите задачу — откроется детальное окно", "Tap a task — details open")),
            _helpItem(Iconsax.magicpen, S.get('chat'),
                S.tr("AI'dan tavsiya so'rang — tanlab ro'yxatga qo'shing", "Спросите у AI — выберите и добавьте в список", "Ask AI — pick and add to your list")),
            _helpItem(LucideIcons.bell, S.tr('Bildirishnoma', 'Уведомление', 'Notification'),
                S.tr("Vazifaga vaqt qo'ying — oldindan eslatadi", "Поставьте время задаче — напомнит заранее", "Set a time on the task — get reminded ahead")),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.txt,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.sub,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.danger.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle,
                color: AppColors.danger, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.get('delete_account_btn'),
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          S.get('delete_account_warn') +
              S.tr('tangalar, do\'stlar va chat tarix butunlay o\'chiriladi.', 'монеты, друзья и история чата будут удалены безвозвратно.', 'coins, friends and chat history will be permanently deleted.'),
          style: TextStyle(
            color: AppColors.sub,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.get('cancel'),
                style: TextStyle(color: AppColors.sub)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              final ok = await auth.deleteAccount();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor:
                      ok ? AppColors.success : AppColors.danger,
                  content: Text(
                    ok
                        ? S.tr('Akkaunt o\'chirildi', 'Аккаунт удалён', 'Account deleted')
                        : '${S.get('error')}: ${auth.error ?? S.get('retry')}',
                    style: TextStyle(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              S.get('delete'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
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
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(S.get('logout'),
            style: TextStyle(
                color: AppColors.txt, fontWeight: FontWeight.w700)),
        content: Text(
          S.get('logout_confirm'),
          style: TextStyle(color: AppColors.sub, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.get('cancel'),
                style: TextStyle(color: AppColors.sub)),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(S.get('logout'), style: TextStyle()),
          ),
        ],
      ),
    );
  }

  void _showReminderPicker() {
    final np = context.read<NotificationProvider>();
    final options = [5, 15, 30, 60, 120];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(10)),
          border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.5)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              S.get('notif_when'),
              style: TextStyle(
                color: AppColors.txt,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              S.get('notif_remind_min_before'),
              style: TextStyle(
                color: AppColors.sub,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ...options.map((m) {
              final label =
                  m < 60 ? '$m ${S.get('unit_minute')}' : '${m ~/ 60} ${S.get('unit_hour')}';
              final active = np.defaultReminderMinutes == m;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      np.setDefaultReminderMinutes(m);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary.withOpacity(0.2) : AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.border,
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.bell,
                            color: active
                                ? AppColors.primary
                                : AppColors.sub,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: AppColors.txt,
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (active)
                            Icon(LucideIcons.checkCircle2,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Reactive tile that reads SmartReminder state on each build and shows
/// the chosen hour. Tapping opens a picker with auto + 7..22 options.
class _SmartReminderTile extends StatefulWidget {
  final Widget Function({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
    String? emoji,
  }) buildTile;
  const _SmartReminderTile({required this.buildTile});
  @override
  State<_SmartReminderTile> createState() => _SmartReminderTileState();
}

class _SmartReminderTileState extends State<_SmartReminderTile> {
  bool _enabled = true;
  int? _override;
  int _bestHour = 9;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final en = await SmartReminder.isEnabled();
    final ov = await SmartReminder.hourOverride();
    final bh = await SmartReminder.bestHour();
    if (mounted) {
      setState(() {
        _enabled = en;
        _override = ov;
        _bestHour = bh;
      });
    }
  }

  Future<void> _showPicker() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.get('smart_reminder_pick_hour'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.txt,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(LucideIcons.sparkles,
                  color: AppColors.primary),
              title: Text(S.get('smart_reminder_auto'),
                  style: TextStyle(color: AppColors.txt)),
              trailing: _override == null
                  ? Icon(LucideIcons.check, color: AppColors.success)
                  : null,
              onTap: () => Navigator.pop(ctx, -1),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 280,
              child: ListView(
                children: [
                  for (int h = 7; h <= 22; h++)
                    ListTile(
                      title: Text('${h.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                              color: AppColors.txt,
                              fontWeight: FontWeight.w600)),
                      trailing: _override == h
                          ? Icon(LucideIcons.check,
                              color: AppColors.success)
                          : null,
                      onTap: () => Navigator.pop(ctx, h),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await SmartReminder.setHourOverride(picked == -1 ? null : picked);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hourText = _override?.toString().padLeft(2, '0') ??
        _bestHour.toString().padLeft(2, '0');
    return widget.buildTile(
      icon: Iconsax.flash_1_copy,
      iconColor: AppColors.accent,
      emoji: '⏰',
      title: S.get('smart_reminder'),
      subtitle: _enabled
          ? S.get('smart_reminder_sub_on').replaceAll('{h}', hourText)
          : S.get('smart_reminder_sub_off'),
      trailing: Switch.adaptive(
        value: _enabled,
        activeColor: AppColors.primary,
        onChanged: (v) async {
          HapticFeedback.selectionClick();
          await SmartReminder.setEnabled(v);
          _refresh();
        },
      ),
      onTap: _enabled ? _showPicker : null,
    );
  }
}
