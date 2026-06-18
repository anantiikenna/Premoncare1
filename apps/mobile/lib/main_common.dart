import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase_locator.dart';
import 'core/router.dart';
import 'core/flavor_config.dart';
import 'core/app_colors.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';

Future<void> mainCommon() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment secrets
  await dotenv.load(fileName: ".env");
  
  // Initialize Firebase (using files in android/app and ios/Runner)
  try {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('Skipping Firebase initialization on Web/Desktop to prevent crash. Run via Android/iOS or use flutterfire configure.');
    } else {
      await Firebase.initializeApp();
      
      // Initialize Notification Service
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(NotificationService.onBackgroundMessage);
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Supabase
  await initSupabase();
  
  runApp(
    const ProviderScope(
      child: PremonCareApp(),
    ),
  );
}

class PremonCareApp extends StatelessWidget {
  const PremonCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    
    return MaterialApp.router(
      title: config.appTitle,
      theme: ThemeData(
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
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
