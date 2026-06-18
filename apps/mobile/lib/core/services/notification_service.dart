import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_locator.dart';
import '../router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request permissions (especially for iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) debugPrint('User granted permission');
    } else {
      if (kDebugMode) debugPrint('User declined or has not accepted permission');
    }

    // 2. Initialize Local Notifications for Foreground display
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) debugPrint('Got a message whilst in the foreground!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // 4. Handle Background/Terminated state message click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) debugPrint('A new onMessageOpenedApp event was published!');
      _handleDeepLink(message.data['link']);
    });

    // 4b. Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleDeepLink(initialMessage.data['link']);
    }

    // 5. Listen to Auth State changes for token syncing
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        syncToken();
      }
    });
  }

  void _handleDeepLink(String? webLink) {
    if (webLink == null || webLink.isEmpty) return;

    if (kDebugMode) debugPrint('Handling Deep Link: $webLink');
    String flutterPath = '/';

    // Simplified Mapping logic
    if (webLink.contains('/patient/dashboard')) {
      flutterPath = '/patient_dashboard';
    } else if (webLink.contains('/doctor/dashboard')) {
      flutterPath = '/doctor_dashboard';
    } else if (webLink.contains('/patient/records') || webLink.contains('/records')) {
      flutterPath = '/vault';
    } else if (webLink.contains('/appointments')) {
      flutterPath = '/appointments';
    } else if (webLink.contains('/forum/post/')) {
      final postId = webLink.split('/').last;
      flutterPath = '/forum/post/$postId';
    } else if (webLink.contains('/forum')) {
      flutterPath = '/forum';
    } else if (webLink.contains('/messages')) {
      flutterPath = '/messages';
    }

    if (kDebugMode) debugPrint('Navigating to: $flutterPath');
    goRouter.push(flutterPath);
  }

  Future<void> syncToken() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? token = await _fcm.getToken();
      if (token == null) return;

      await supabase.from('profiles').update({
        'fcm_token': token,
      }).eq('id', user.id);
    } catch (e) {
      if (kDebugMode) debugPrint('Error syncing FCM token: $e');
    }
  }

  static Future<void> onBackgroundMessage(RemoteMessage message) async {
    // Ensure Firebase is initialized for background tasks if needed
    // await Firebase.initializeApp();
    if (kDebugMode) debugPrint("Handling a background message: ${message.messageId}");
  }
}
