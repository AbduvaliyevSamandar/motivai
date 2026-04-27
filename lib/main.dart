import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'services/sound_pack.dart';
import 'services/action_queue.dart';
import 'services/home_widget_service.dart';
import 'services/haptic_service.dart';
import 'services/rituals_storage.dart';
import 'services/user_goal.dart';
import 'services/legacy_wipe.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await LegacyWipe.run();
  await SoundPackStore.load();
  await Haptics.load();
  await UserGoal.load();
  await HomeWidgetService.init();
  await NotificationService.instance.init();
  // Re-schedule any saved rituals after notification plugin is ready.
  unawaited(RitualsStorage.rescheduleAll());
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _needOnboarding = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final need = await OnboardingScreen.shouldShow();
    if (mounted) setState(() {
      _needOnboarding = need;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider<ActionQueue>.value(value: ActionQueue.instance),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, prev) {
            prev?.updateToken(auth.token);
            return prev ?? TaskProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, prev) {
            prev?.updateToken(auth.token);
            return prev ?? ChatProvider();
          },
        ),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (_, theme, auth, __) => MaterialApp(
          title: 'MotivAI',
          debugShowCheckedModeBanner: false,
          theme: theme.theme,
          home: !_checked
              ? const SplashScreen()
              : _needOnboarding
                  ? OnboardingScreen(
                      onFinish: () =>
                          setState(() => _needOnboarding = false),
                    )
                  : auth.isLoading
                      ? const SplashScreen()
                      : auth.isLoggedIn
                          ? const MainShell()
                          : const LoginScreen(),
        ),
      ),
    );
  }
}
