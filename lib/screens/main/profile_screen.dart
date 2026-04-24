import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/colors.dart';
import '../../config/dimensions.dart';
import '../../config/strings.dart';
import '../../config/theme_presets.dart';
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

    final nextTarget = (auth.level + 1) * 100;
    final ratio = nextTarget > 0 ? (auth.points % 100) / 100 : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const AuroraBackground(subtle: true),
          const ParticleField(count: 22),
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
                          gradientColors: AppColors.gradCosmic,
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
                                      gradient: LinearGradient(
                                          colors: AppColors.gradCosmic),
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
                                      Icons.camera_alt_rounded,
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
                        ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                            colors: AppColors.titleGradient,
                          ).createShader(b),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            auth.name.isEmpty ? 'User' : auth.name,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.email,
                          style: GoogleFonts.poppins(
                            color: AppColors.sub,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.primary.withOpacity(0.25),
                              AppColors.secondary.withOpacity(0.15),
                            ]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  AppColors.primary.withOpacity(0.4),
                            ),
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
                                  color: AppColors.txt,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
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
                              ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                        colors: AppColors.gradGold)
                                    .createShader(b),
                                blendMode: BlendMode.srcIn,
                                child: Text(
                                  '${auth.points} XP',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                    childAspectRatio: 1.55,
                    children: [
                      BentoCard(
                        icon: Icons.star_rounded,
                        value: '${auth.points}',
                        label: 'XP',
                        gradient: AppColors.gradGold,
                        accent: AppColors.accent,
                      ),
                      BentoCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '${auth.streak}',
                        label: S.get('streak'),
                        gradient: AppColors.gradFire,
                        accent: AppColors.accent,
                      ),
                      BentoCard(
                        icon: Icons.check_circle_rounded,
                        value: '${auth.totalTasks}',
                        label: S.get('tasks_label'),
                        gradient: AppColors.gradSuccess,
                        accent: AppColors.success,
                      ),
                      BentoCard(
                        icon: Icons.emoji_events_rounded,
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
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      iconColor: AppColors.primary,
                      title: theme.auto
                          ? 'Avto rejim'
                          : (theme.isDark
                              ? S.get('dark_mode')
                              : S.get('light_mode')),
                      subtitle: theme.auto
                          ? 'Soatga qarab avtomatik'
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
                      icon: Icons.brightness_auto_rounded,
                      iconColor: AppColors.info,
                      title: 'Avto tema',
                      subtitle:
                          'Kechqurun dark, kunduzi light — avtomatik',
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
                      icon: Icons.palette_rounded,
                      iconColor: AppColors.pink,
                      title: 'Rang mavzusi',
                      subtitle:
                          '${ThemePresets.current.emoji}  ${ThemePresets.current.name}',
                      onTap: _showThemePicker,
                    ),
                    _tile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.info,
                      title: S.get('change_pass'),
                      onTap: _showChangePassword,
                    ),
                    _tile(
                      icon: Icons.credit_card_rounded,
                      iconColor: AppColors.info,
                      title: 'Flashcards',
                      subtitle: 'Spaced repetition bilan yodlash',
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
                      icon: Icons.eco_rounded,
                      iconColor: AppColors.success,
                      title: 'Kundalik odatlar',
                      subtitle: 'Streak orqali o\'z-o\'zingizni rivojlantiring',
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
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColors.pink,
                      title: 'Haftalik xulosa',
                      subtitle: 'Bu haftangiz natijalari',
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
                      icon: Icons.park_rounded,
                      iconColor: AppColors.success,
                      title: 'Sayohat',
                      subtitle: '30 kunlik daraxt o\'sishi',
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
                      icon: Icons.grid_view_rounded,
                      iconColor: AppColors.info,
                      title: 'Mahsuldorlik xaritasi',
                      subtitle: 'Qaysi soatda eng faol ekanligi',
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
                      icon: Icons.self_improvement_rounded,
                      iconColor: AppColors.accent,
                      title: 'Rituallar',
                      subtitle: 'Takroriy mashg\'ulotlar uchun eslatma',
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
                      icon: Icons.group_rounded,
                      iconColor: AppColors.pink,
                      title: 'Do\'stlar',
                      subtitle: 'Taklif kodi bilan guruhlash',
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
                      icon: Icons.emoji_events_rounded,
                      iconColor: AppColors.accent,
                      title: 'Chellenjlar',
                      subtitle: 'Do\'st bilan 7 kunlik turnir',
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
                      icon: Icons.translate_rounded,
                      iconColor: AppColors.secondary,
                      title: S.get('language'),
                      subtitle: _langName(S.lang),
                      onTap: _showLanguageDialog,
                    ),
                    Consumer<NotificationProvider>(
                      builder: (_, np, __) => Column(children: [
                        _tile(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.accent,
                          title: S.get('notifications'),
                          subtitle: np.enabled
                              ? '${np.defaultReminderMinutes} min oldin eslatma'
                              : "O'chirilgan",
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
                          _tile(
                            icon: Icons.notifications_active_rounded,
                            iconColor: AppColors.success,
                            title: 'Bildirishnomani sinash',
                            subtitle: '5 soniyadan keyin test keladi',
                            onTap: _testNotification,
                          ),
                        if (np.enabled)
                          _tile(
                            icon: Icons.music_note_rounded,
                            iconColor: AppColors.pink,
                            title: 'Tovush pachkasi',
                            subtitle:
                                '${SoundPackStore.info(SoundPackStore.current).emoji}  ${SoundPackStore.info(SoundPackStore.current).name}',
                            onTap: _showSoundPackPicker,
                          ),
                      ]),
                    ),
                    _tile(
                      icon: Icons.vibration_rounded,
                      iconColor: AppColors.secondary,
                      title: 'Titrash kuchi',
                      subtitle:
                          '${Haptics.info(Haptics.level).emoji}  ${Haptics.info(Haptics.level).name}',
                      onTap: _showHapticPicker,
                    ),
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
                      icon: Icons.download_rounded,
                      iconColor: AppColors.info,
                      title: 'Ma\'lumotlarni eksport',
                      subtitle: 'Vazifalar, odatlar, kartalar — JSON',
                      onTap: _exportData,
                    ),
                    _tile(
                      icon: Icons.share_rounded,
                      iconColor: AppColors.pink,
                      title: 'Template ulashish',
                      subtitle: 'Odatlar + kartalar — do\'stga yuboring',
                      onTap: _shareTemplate,
                    ),
                    _tile(
                      icon: Icons.file_upload_rounded,
                      iconColor: AppColors.success,
                      title: 'Template import',
                      subtitle: 'JSON yopishtiring — odat/kartalarga qo\'shiladi',
                      onTap: _importTemplate,
                    ),
                    _tile(
                      icon: Icons.cleaning_services_outlined,
                      iconColor: AppColors.accent,
                      title: S.get('clear_cache'),
                      onTap: () => _clearCache(auth),
                    ),
                    _tile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.danger,
                      title: S.get('logout'),
                      color: AppColors.danger,
                      onTap: () => _confirmLogout(auth),
                    ),
                    const SizedBox(height: 24),
                    _section('Ilova haqida'),
                    const SizedBox(height: 12),
                    _tile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.info,
                      title: 'MotivAI haqida',
                      onTap: _showAbout,
                    ),
                    _tile(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.secondary,
                      title: 'Yordam',
                      subtitle: 'Qo\'llanma va savollar',
                      onTap: _showHelp,
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
                              gradient: LinearGradient(colors: [
                                AppColors.primary.withOpacity(0.22),
                                AppColors.secondary.withOpacity(0.15),
                              ]),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.bolt_rounded,
                                color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'MotivAI v2.2.0',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.txt,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'Maqsadga — har kuni bir qadam',
                            style: GoogleFonts.poppins(
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
      child: ShaderMask(
        shaderCallback: (r) =>
            LinearGradient(colors: AppColors.gradCosmic)
                .createShader(r),
        blendMode: BlendMode.srcIn,
        child: Text(
          letter,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w700,
          ),
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
            gradient: LinearGradient(
              colors: AppColors.gradCosmic,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    iconColor.withOpacity(0.22),
                    iconColor.withOpacity(0.08),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
                trailing
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.sub.withOpacity(0.5), size: 22),
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
                const BorderRadius.vertical(top: Radius.circular(28)),
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
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.get('change_pass'),
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.txt,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 24),
            GlassTextField(
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
            const SizedBox(height: 12),
            GlassTextField(
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
            const SizedBox(height: 12),
            GlassTextField(
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
            const SizedBox(height: 24),
            NebulaButton(
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
                    current.text, newPass.text);
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
                const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: AppColors.titleGradient,
                ).createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Rang mavzusi',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ilovaning rang palitrasini tanlang',
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 12,
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
                        gradient: LinearGradient(
                          colors: [
                            p.primary.withOpacity(0.25),
                            p.secondary.withOpacity(0.18),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: active
                              ? p.primary
                              : AppColors.border,
                          width: active ? 2 : 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: p.primary.withOpacity(0.35),
                                  blurRadius: 16,
                                  spreadRadius: 1,
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
                                  style: const TextStyle(fontSize: 22)),
                              if (active)
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: p.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
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
                                style: GoogleFonts.spaceGrotesk(
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
                const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Titrash kuchi',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.txt,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text('Tanlang va darhol sinab ko\'ring',
                  style: GoogleFonts.poppins(
                      color: AppColors.sub, fontSize: 12)),
              const SizedBox(height: 20),
              ...HapticLevel.values.map((l) {
                final info = Haptics.info(l);
                final active = Haptics.level == l;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
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
                          gradient: active
                              ? LinearGradient(colors: [
                                  AppColors.primary.withOpacity(0.22),
                                  AppColors.secondary.withOpacity(0.1),
                                ])
                              : null,
                          color: active ? null : AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
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
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(info.name,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: AppColors.txt,
                                        fontSize: 14,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      )),
                                  Text(info.desc,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.sub,
                                        fontSize: 11,
                                      )),
                                ],
                              ),
                            ),
                            if (active)
                              Icon(Icons.check_circle_rounded,
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
                const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: AppColors.titleGradient,
                ).createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Tovush pachkasi',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bildirishnoma uslubini tanlang',
                style: GoogleFonts.poppins(
                  color: AppColors.sub,
                  fontSize: 12,
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
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
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
                          gradient: active
                              ? LinearGradient(colors: [
                                  AppColors.primary.withOpacity(0.22),
                                  AppColors.secondary.withOpacity(0.1),
                                ])
                              : null,
                          color: active ? null : AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
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
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.txt,
                                      fontSize: 14,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    info.desc,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.sub,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (active)
                              Icon(Icons.check_circle_rounded,
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
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(
          S.get('select_lang'),
          style: GoogleFonts.spaceGrotesk(
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
        borderRadius: BorderRadius.circular(14),
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
            gradient: isActive
                ? LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.18),
                    AppColors.secondary.withOpacity(0.08),
                  ])
                : null,
            borderRadius: BorderRadius.circular(14),
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

  void _clearCache(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(S.get('clear_cache'),
            style: GoogleFonts.spaceGrotesk(
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
              foregroundColor: const Color(0xFF0F1028),
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(S.get('clear_cache'),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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
        'Template nusxa olindi ($bytes bayt). Endi do\'stingizga yuboring.',
        style: GoogleFonts.poppins(),
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
                const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: AppColors.titleGradient,
                ).createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Template import',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Do\'stingizdan olgan JSON ni yopishtiring',
                style: GoogleFonts.poppins(
                    color: AppColors.sub, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                minLines: 5,
                maxLines: 10,
                style: GoogleFonts.poppins(
                    color: AppColors.txt, fontSize: 12),
                decoration: InputDecoration(
                  hintText: '{"app":"MotivAI", ...}',
                  hintStyle: GoogleFonts.poppins(
                      color: AppColors.hint, fontSize: 12),
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
                      icon: Icon(Icons.paste_rounded,
                          color: AppColors.sub, size: 18),
                      label: Text('Clipboard',
                          style: GoogleFonts.poppins(
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
                label: 'Import qilish',
                icon: Icons.file_upload_rounded,
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
                      style: GoogleFonts.poppins(),
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
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nusxa olindi ($bytes bayt)',
              style: GoogleFonts.poppins(),
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
      title: 'MotivAI test',
      body: 'Bu sinov bildirishnomasi — hammasi ishlayapti! \u{1F389}',
      at: when,
    );
    // Also add to in-app feed
    np.addAchievement(
        'Test bildirishnoma', '5 soniyadan keyin yetib keladi');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '5 soniyadan keyin keladi \u{1F514}',
            style: GoogleFonts.poppins(),
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
            gradient: LinearGradient(colors: [
              AppColors.card,
              Color.lerp(AppColors.card, AppColors.primary, 0.08)!,
            ]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 30,
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
                  gradient: LinearGradient(
                      colors: AppColors.gradCosmic),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: AppColors.titleGradient,
                ).createShader(b),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'MotivAI',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                'v2.2.0',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI orqali talabalarga motivatsiya beruvchi ilova',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.txt,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _aboutRow('\u{1F527}', 'Flutter + FastAPI + MongoDB'),
              const SizedBox(height: 8),
              _aboutRow('\u{1F3A8}', 'Nebula Premium design'),
              const SizedBox(height: 8),
              _aboutRow('\u{1F680}', 'Open source, \u{1F1FA}\u{1F1FF} Uzbekistan'),
              const SizedBox(height: 20),
              NebulaButton(
                label: 'Yopish',
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
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: AppColors.sub,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
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
              const BorderRadius.vertical(top: Radius.circular(28)),
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
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (b) => LinearGradient(
                colors: AppColors.titleGradient,
              ).createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                "Qo'llanma",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _helpItem(Icons.add_rounded, 'Vazifa qo\'shish',
                "'+' tugmasi orqali nom, vaqt, eslatma bilan qo'shing"),
            _helpItem(Icons.check_circle_rounded, 'Bajarish',
                "Davra tugmasini bosing yoki o'ngga swipe qiling"),
            _helpItem(Icons.swipe_left_rounded, 'O\'chirish',
                "Chapga swipe qiling yoki 3-nuqta menyu"),
            _helpItem(Icons.touch_app_rounded, 'Tafsilot',
                "Vazifani bosing — tafsilot oynasi ochiladi"),
            _helpItem(Icons.auto_awesome_rounded, 'AI Chat',
                "AI'dan tavsiya so'rang — tanlab ro'yxatga qo'shing"),
            _helpItem(Icons.notifications_active_rounded, 'Bildirishnoma',
                "Vazifaga vaqt qo'ying — oldindan eslatadi"),
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
              gradient: LinearGradient(colors: [
                AppColors.primary.withOpacity(0.22),
                AppColors.secondary.withOpacity(0.12),
              ]),
              borderRadius: BorderRadius.circular(11),
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
                  style: GoogleFonts.poppins(
                    color: AppColors.txt,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    color: AppColors.sub,
                    fontSize: 12,
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

  void _confirmLogout(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text(S.get('logout'),
            style: GoogleFonts.spaceGrotesk(
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
              const BorderRadius.vertical(top: Radius.circular(28)),
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
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Eslatma vaqti',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.txt,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vazifadan qancha vaqt oldin eslatish',
              style: GoogleFonts.poppins(
                color: AppColors.sub,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ...options.map((m) {
              final label =
                  m < 60 ? '$m daqiqa' : '${m ~/ 60} soat';
              final active = np.defaultReminderMinutes == m;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      np.setDefaultReminderMinutes(m);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: active
                            ? LinearGradient(colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.secondary.withOpacity(0.1),
                              ])
                            : null,
                        color: active ? null : AppColors.bg,
                        borderRadius: BorderRadius.circular(14),
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
                            Icons.notifications_active_rounded,
                            color: active
                                ? AppColors.primary
                                : AppColors.sub,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: GoogleFonts.poppins(
                                color: AppColors.txt,
                                fontSize: 14,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (active)
                            Icon(Icons.check_circle_rounded,
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
