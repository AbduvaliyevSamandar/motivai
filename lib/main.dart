import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/colors.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create:  (_) => TaskProvider(),
          update:  (_, auth, prev) {
            prev?.updateToken(auth.token);
            return prev ?? TaskProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create:  (_) => ChatProvider(),
          update:  (_, auth, prev) {
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
          home: auth.isLoading
              ? const SplashScreen()
              : auth.isLoggedIn
                  ? const MainShell()
                  : const LoginScreen(),
        ),
      ),
    );
  }
}
