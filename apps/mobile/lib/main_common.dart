import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/supabase_locator.dart';
import 'core/router.dart';
import 'core/flavor_config.dart';
import 'core/app_colors.dart';
import 'core/theme_provider.dart';
import 'core/providers/accessibility_provider.dart';
import 'l10n/app_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/inactivity_detector.dart';
import 'core/widgets/biometric_gate.dart';

final accessibilityProvider = ChangeNotifierProvider<AccessibilityProvider>((ref) {
  final provider = AccessibilityProvider();
  provider.load();
  return provider;
});

const _languageToLocale = <String, Locale>{
  'English': Locale('en'),
  'French': Locale('fr'),
  'Yoruba': Locale('yo'),
  'Igbo': Locale('ig'),
  'Hausa': Locale('ha'),
  'Swahili': Locale('sw'),
};

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('locale_language');
    if (lang != null && _languageToLocale.containsKey(lang)) {
      state = _languageToLocale[lang];
    }
  }

  void setLanguage(String language) {
    final locale = _languageToLocale[language];
    if (locale != null) state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

Future<void> mainCommon() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Pre-load theme BEFORE first frame to prevent light→dark flash
  final persistedTheme = await loadPersistedTheme();

  try {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      if (!kDebugMode) debugPrint('Skipping Firebase initialization on Web/Desktop.');
    } else {
      await Firebase.initializeApp();
      final notificationService = NotificationService();
      await notificationService.initialize();
      FirebaseMessaging.onBackgroundMessage(NotificationService.onBackgroundMessage);
    }
  } catch (e) {
    if (!kDebugMode) debugPrint('Firebase initialization error: $e');
  }

  await initSupabase();

  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(persistedTheme),
      ],
      child: const BiometricGate(
        child: PremonCareApp(),
      ),
    ),
  );
}

class PremonCareApp extends ConsumerWidget {
  const PremonCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = FlavorConfig.instance;
    final themeMode = ref.watch(themeModeProvider);
    final accessibility = ref.watch(accessibilityProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: config.appTitle,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('yo'),
        Locale('ig'),
        Locale('ha'),
        Locale('sw'),
      ],
      builder: (context, child) {
        return InactivityDetector(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(accessibility.textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Color(0xFFF1F5F9),
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
    );
  }
}
