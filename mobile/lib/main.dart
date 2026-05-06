import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'data/services/simple_auth_service.dart';
import 'presentation/screens/auth/email_login_screen.dart';
import 'presentation/screens/dashboard_screen_new.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait-only for crisp mobile rendering
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Immersive status bar — let UI bleed under it beautifully
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    const ProviderScope(
      child: GeoDishaMobileApp(),
    ),
  );
}

class GeoDishaMobileApp extends ConsumerWidget {
  const GeoDishaMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = SimpleAuthService();
    // ScreenUtil baseline: design at 390×844 (iPhone 14 logical pixels)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) => MaterialApp(
        title: 'GeoDisha Political Intelligence Platform',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: child,
      ),
      child: FutureBuilder<bool>(
        future: authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) return const DashboardScreen();
          return const EmailLoginScreen();
        },
      ),
    );
  }
}
