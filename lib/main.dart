import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkeutgong_mobile/core/api/api_client.dart';
import 'package:kkeutgong_mobile/core/auth/token_store.dart';
import 'package:kkeutgong_mobile/core/notifications/notification_service.dart';
import 'package:kkeutgong_mobile/core/routes/app_routes.dart';
import 'package:kkeutgong_mobile/core/version/version_gate.dart';
import 'package:kkeutgong_mobile/presentation/views/system/force_update_page.dart';
import 'package:kkeutgong_mobile/presentation/views/system/maintenance_page.dart';
import 'package:kkeutgong_mobile/shared/styles/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/.env');

  // Kakao SDK init
  final kakaoKey = dotenv.maybeGet('KAKAO_NATIVE_APP_KEY') ?? '';
  if (kakaoKey.isNotEmpty && kakaoKey != 'your_kakao_native_app_key_here') {
    KakaoSdk.init(nativeAppKey: kakaoKey);
  }

  // Notification service init
  await NotificationService().init();

  // Sentry
  final sentryDsn = dotenv.maybeGet('SENTRY_DSN') ?? '';
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => runApp(const MainApp()),
    );
  } else {
    runApp(const MainApp());
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  _BootState _bootState = _BootState.loading;
  String? _initialRoute;
  ThemeMode _themeMode = ThemeMode.system;
  VoidCallback? _onRetry;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _bootState = _BootState.loading);

    // 1. Load saved theme preference
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'system';
    _themeMode = saved == 'light'
        ? ThemeMode.light
        : saved == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;

    // 2. Health / force-update gate
    final gate = await VersionGate().check();
    if (gate.status == AppStatus.forceUpdate) {
      setState(() => _bootState = _BootState.forceUpdate);
      return;
    }
    if (gate.status == AppStatus.maintenance) {
      setState(() {
        _bootState = _BootState.maintenance;
        _onRetry = _boot;
      });
      return;
    }

    // 3. Check stored tokens
    final tokenStore = TokenStore();
    final access = await tokenStore.accessToken;
    if (access == null) {
      setState(() {
        _bootState = _BootState.ready;
        _initialRoute = AppRoutes.welcome;
      });
      return;
    }

    // 4. Validate token by calling /users/me
    try {
      await ApiClient().get('/users/me');
      final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
      setState(() {
        _bootState = _BootState.ready;
        _initialRoute = hasOnboarded ? AppRoutes.main : AppRoutes.onboarding;
      });
    } catch (_) {
      // Token invalid even after refresh attempt handled inside ApiClient.
      setState(() {
        _bootState = _BootState.ready;
        _initialRoute = AppRoutes.welcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootState == _BootState.loading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Container(color: Colors.white),
        theme: initThemeData(brightness: Brightness.light),
        darkTheme: initThemeData(brightness: Brightness.dark),
        themeMode: _themeMode,
      );
    }

    if (_bootState == _BootState.forceUpdate) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const ForceUpdatePage(),
        theme: initThemeData(brightness: Brightness.light),
        darkTheme: initThemeData(brightness: Brightness.dark),
        themeMode: _themeMode,
      );
    }

    if (_bootState == _BootState.maintenance) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MaintenancePage(onRetry: _onRetry ?? _boot),
        theme: initThemeData(brightness: Brightness.light),
        darkTheme: initThemeData(brightness: Brightness.dark),
        themeMode: _themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko'), Locale('en')],
      );
    }

    return GetMaterialApp(
      getPages: AppRoutes.routes,
      initialRoute: _initialRoute ?? AppRoutes.welcome,
      debugShowCheckedModeBanner: false,
      theme: initThemeData(brightness: Brightness.light),
      darkTheme: initThemeData(brightness: Brightness.dark),
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
    );
  }
}

enum _BootState { loading, forceUpdate, maintenance, ready }
