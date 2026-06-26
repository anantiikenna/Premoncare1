import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_locator.dart';
import '../features/auth/admin_login_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/password_reset_success_screen.dart';
import '../features/auth/otp_verification_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/account_conversion_screen.dart';
import '../features/auth/permission_screen.dart';
import '../features/patient/patient_main_layout.dart';
import '../features/patient/doctor_details_screen.dart';
import '../features/patient/select_duration_screen.dart';
import '../features/patient/confirm_booking_screen.dart';
import '../features/patient/booking_confirmed_screen.dart';
import '../features/patient/upload_receipt_screen.dart';
import '../features/patient/consultation_summary_screen.dart';
import '../features/patient/doctor_search_screen.dart';
import '../features/patient/payment_failed_screen.dart';
import '../features/patient/booking_failed_screen.dart';
import '../features/patient/credits_screen.dart';
import '../features/verification/widgets/upload_failed_screen.dart';
import '../shared/widgets/no_internet_screen.dart';
import '../features/appointments/emergency_failed_screen.dart';
import '../features/patient/emergency_waiting_screen.dart';
import '../features/doctor/doctor_emergency_request_screen.dart';
import '../features/auth/session_expired_screen.dart';
import '../features/messaging/chat_list_screen.dart';
import '../features/messaging/chat_detail_screen.dart';
import '../features/records/medical_vault_screen.dart';
import '../features/records/doctor_shared_records_screen.dart';
import '../features/forum/forum_list_screen.dart';
import '../features/forum/forum_provider.dart';
import '../features/forum/post_detail_screen.dart';
import '../features/forum/create_post_screen.dart';
import '../features/forum/my_activity_screen.dart';
import '../features/forum/ask_doctor_screen.dart';
import '../features/forum/saved_followed_screen.dart';
import '../features/appointments/appointments_screen.dart';
import '../features/appointments/appointment_detail_screen.dart';
import '../features/appointments/consultation_screen.dart';
import '../features/verification/verify_practitioner_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/doctor/doctor_appointments_screen.dart';
import '../features/doctor/doctor_main_layout.dart';
import '../features/doctor/patient_details_layout.dart';
import '../features/doctor/earnings_analytics_screen.dart';
import '../features/doctor/subscription_management_screen.dart';
import '../features/doctor/schedule_management_screen.dart';
import '../features/doctor/doctor_payments_screen.dart';
import '../shared/widgets/document_viewer.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/doctor_verification_panel.dart';
import '../features/admin/financial_moderation_screen.dart';
import '../features/admin/p2p_monitoring_panel.dart';
import '../features/admin/dispute_resolution_screen.dart';
import '../features/admin/notification_control_panel.dart';
import '../features/admin/subscription_plan_control.dart';
import '../features/admin/doctor_subscription_management.dart';
import '../features/admin/user_management_panel.dart';
import '../features/admin/admin_audit_timeline_screen.dart';
import '../features/admin/admin_reports_screen.dart';
import '../features/admin/forum_moderation_panel.dart';
import '../features/admin/admin_emergency_queue_screen.dart';
import '../features/settings/settings_privacy_screen.dart';
import '../features/settings/personal_info_screen.dart';
import '../features/settings/appearance_settings_screen.dart';
import '../features/settings/login_security_screen.dart';
import '../features/settings/notification_preferences_screen.dart';
import '../features/settings/language_region_screen.dart';
import '../features/settings/biometric_privacy_screen.dart';
import '../features/settings/medical_record_permissions_screen.dart';
import '../features/settings/device_sessions_screen.dart';
import '../features/settings/download_data_screen.dart';
import '../features/settings/accessibility_settings_screen.dart';
import '../features/settings/health_preferences_screen.dart';
import '../features/settings/help_support_screen.dart';
import '../features/settings/terms_of_service_screen.dart';
import '../features/settings/privacy_policy_screen.dart';
import '../features/settings/about_screen.dart';
import 'flavor_config.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

final goRouter = GoRouter(
  initialLocation: FlavorConfig.instance.initialRoute,
  observers: [PosthogObserver()],
  redirect: (context, state) async {
    final session = supabase.auth.currentSession;
    final loggedIn = session != null;
    final isLoggingIn = state.matchedLocation == '/login';
    final isRegistering = state.matchedLocation == '/register';
    final isOnboarding = state.matchedLocation == '/onboarding';
    final isSplash = state.matchedLocation == '/';
    final isPublicAuthRoute = {
      '/login',
      '/register',
      '/forgot-password',
      '/reset-password',
      '/password-reset-success',
      '/otp-verification',
      '/session-expired',
    }.contains(state.matchedLocation);
    final extra = state.extra;
    final isEmergencyAccess =
        state.uri.queryParameters['emergency'] == 'true' ||
        (extra is Map<String, dynamic> && extra['isEmergency'] == true);

    final isAdminLogin = state.matchedLocation == '/admin-login';

    if (FlavorConfig.isAdmin) {
      if (!loggedIn) {
        return isAdminLogin ? null : '/admin-login';
      }

      final role = await getUserRole();
      if (role != 'admin') {
        await supabase.auth.signOut();
        return '/admin-login';
      }

      if (isAdminLogin || isLoggingIn || isSplash) return '/admin-dashboard';
      return null;
    }

    if (!loggedIn) {
      if (isSplash || isOnboarding || isPublicAuthRoute) return null;

      final allowsGuestEmergency =
          isEmergencyAccess &&
          {
            '/doctor-search',
            '/doctor-details',
            '/select-duration',
            '/confirm-booking',
            '/booking-confirmed',
          }.contains(state.matchedLocation);
      if (allowsGuestEmergency) return null;

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      if (!hasSeenOnboarding) {
        return isSplash ? null : '/onboarding';
      }
      return (isLoggingIn || isSplash || isRegistering) ? null : '/login';
    }

    final role = await getUserRole();

    if (role == 'admin') {
      await supabase.auth.signOut();
      return '/login';
    }

    if (isLoggingIn || isOnboarding || isRegistering || isSplash) {
      return role == 'doctor' ? '/doctor_dashboard' : '/patient_dashboard';
    }

    final location = state.matchedLocation;

    if (location == '/doctor_dashboard' && role == 'patient') {
      return '/patient_dashboard';
    }

    if (location == '/doctor/earnings') {
      final profileData = await supabase
          .from('profiles')
          .select('verification_status')
          .eq('id', session.user.id)
          .maybeSingle();
      final status = profileData?['verification_status'] as String?;
      if (status != 'approved') {
        return '/doctor_dashboard';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/password-reset-success',
      builder: (context, state) => const PasswordResetSuccessScreen(),
    ),
    GoRoute(
      path: '/patient_dashboard',
      builder: (context, state) => const PatientMainLayout(),
    ),
    GoRoute(
      path: '/doctor-details',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return DoctorDetailsScreen(
          doctorId: extras['id'] as String? ?? '',
          doctorName: extras['name'] as String? ?? 'Doctor',
          specialty: extras['specialty'] as String? ?? '',
          isEmergency: extras['isEmergency'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/select-duration',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return SelectDurationScreen(
          doctorId: extras['doctorId'] as String? ?? '',
          doctorName: extras['doctorName'] as String? ?? 'Doctor',
          hourlyRate: (extras['hourlyRate'] as num?)?.toDouble() ?? 5000.0,
          isEmergency: extras['isEmergency'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/confirm-booking',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return ConfirmBookingScreen(
          doctorId: extras['doctorId'] as String? ?? '',
          doctorName: extras['doctorName'] as String? ?? 'Doctor',
          durationMinutes: extras['durationMinutes'] as int? ?? 30,
          totalAmount: (extras['totalAmount'] as num?)?.toDouble() ?? 0.0,
          isEmergency: extras['isEmergency'] as bool? ?? false,
        );
      },
    ),
    GoRoute(
      path: '/booking-confirmed',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return BookingConfirmedScreen(
          consultationFee: (extras['consultationFee'] as num?)?.toDouble(),
          doctorName: extras['doctorName'] as String?,
          doctorId: extras['doctorId'] as String?,
          durationMinutes: extras['durationMinutes'] as int?,
          appointmentId: extras['appointmentId'] as String?,
          appointmentDate: extras['appointmentDate'] as String?,
          consultationType: extras['consultationType'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/emergency-waiting',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return EmergencyWaitingScreen(
          appointmentId: extras['appointmentId'] as String? ?? '',
          doctorId: extras['doctorId'] as String? ?? '',
          doctorName: extras['doctorName'] as String? ?? 'Doctor',
          totalAmount: (extras['totalAmount'] as num?)?.toDouble() ?? 0.0,
          durationMinutes: extras['durationMinutes'] as int? ?? 15,
        );
      },
    ),
    GoRoute(
      path: '/doctor_dashboard',
      builder: (context, state) => const DoctorMainLayout(),
    ),
    GoRoute(
      path: '/doctor-emergency-request',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return DoctorEmergencyRequestScreen(
          appointmentId: extras['appointmentId'] as String? ?? '',
          patientId: extras['patientId'] as String? ?? '',
          patientName: extras['patientName'] as String? ?? 'Patient',
          durationMinutes: extras['durationMinutes'] as int? ?? 15,
          totalAmount: (extras['totalAmount'] as num?)?.toDouble() ?? 0.0,
        );
      },
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: '/chat/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? '';
        return ChatDetailScreen(partnerId: userId);
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        final partnerId = extras['doctorId'] as String? ?? '';
        return ChatDetailScreen(partnerId: partnerId);
      },
    ),
    GoRoute(
      path: '/vault',
      builder: (context, state) => const MedicalVaultScreen(),
    ),
    GoRoute(
      path: '/doctor/shared_records',
      builder: (context, state) => const DoctorSharedRecordsScreen(),
    ),
    GoRoute(
      path: '/forum',
      builder: (context, state) => const ForumListScreen(),
    ),
    GoRoute(
      path: '/forum/post/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId'] ?? '';
        final post = state.extra as ForumPost?;
        return PostDetailScreen(postId: postId, post: post);
      },
    ),
    GoRoute(
      path: '/forum/create',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/forum/my-activity',
      builder: (context, state) => const MyActivityScreen(),
    ),
    GoRoute(
      path: '/forum/ask-doctor',
      builder: (context, state) => const AskDoctorScreen(),
    ),
    GoRoute(
      path: '/forum/saved',
      builder: (context, state) => const SavedFollowedScreen(),
    ),
    GoRoute(
      path: '/appointments',
      builder: (context, state) {
        return FutureBuilder<String>(
          future: getUserRole(),
          builder: (context, snapshot) {
            if (snapshot.data == 'doctor') {
              return const DoctorAppointmentsScreen();
            }
            return const AppointmentsScreen();
          },
        );
      },
    ),
    GoRoute(
      path: '/appointments/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AppointmentDetailScreen(appointmentId: id);
      },
    ),
    GoRoute(
      path: '/settings-privacy',
      builder: (context, state) => const SettingsPrivacyCenterScreen(),
    ),
    GoRoute(
      path: '/personal-info',
      builder: (context, state) => const PersonalInfoScreen(),
    ),
    GoRoute(
      path: '/appearance',
      builder: (context, state) => const AppearanceSettingsScreen(),
    ),
    GoRoute(
      path: '/login-security',
      builder: (context, state) => const LoginSecurityScreen(),
    ),
    GoRoute(
      path: '/notification-preferences',
      builder: (context, state) => const NotificationPreferencesScreen(),
    ),
    GoRoute(
      path: '/language-region',
      builder: (context, state) => const LanguageRegionScreen(),
    ),
    GoRoute(
      path: '/biometric-privacy',
      builder: (context, state) => const BiometricPrivacyScreen(),
    ),
    GoRoute(
      path: '/medical-record-permissions',
      builder: (context, state) => const MedicalRecordPermissionsScreen(),
    ),
    GoRoute(
      path: '/device-sessions',
      builder: (context, state) => const DeviceSessionsScreen(),
    ),
    GoRoute(
      path: '/download-data',
      builder: (context, state) => const DownloadDataScreen(),
    ),
    GoRoute(
      path: '/accessibility',
      builder: (context, state) => const AccessibilitySettingsScreen(),
    ),
    GoRoute(
      path: '/health-preferences',
      builder: (context, state) => const HealthPreferencesScreen(),
    ),
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/terms-of-service',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(
      path: '/admin/audit-timeline',
      builder: (context, state) => const AdminAuditTimelineScreen(),
    ),
    GoRoute(
      path: '/admin/forum-moderation',
      builder: (context, state) => const ForumModerationPanel(),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/consultation/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final extras = state.extra as Map<String, dynamic>?;
        return ConsultationScreen(
          appointmentId: id,
          doctorName: extras?['doctorName'] as String?,
          specialty: extras?['specialty'] as String?,
          durationMinutes: extras?['durationMinutes'] as int?,
        );
      },
    ),
    GoRoute(
      path: '/verify-practitioner',
      builder: (context, state) => const VerifyPractitionerScreen(),
    ),
    GoRoute(
      path: '/document-viewer',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return DocumentViewer(
          bucket: extras['bucket'] as String? ?? '',
          path: extras['path'] as String? ?? '',
          title: extras['title'] as String? ?? '',
          url: extras['url'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/upload-receipt',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return UploadReceiptScreen(
          doctorId: extras['doctorId'] as String?,
          amount: (extras['amount'] as num?)?.toDouble(),
          appointmentId: extras['appointmentId'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/consultation-summary/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ConsultationSummaryScreen(appointmentId: id);
      },
    ),
    GoRoute(
      path: '/doctor-search',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return DoctorSearchScreen(isBuyingTime: extras['isBuyingTime'] as bool? ?? false);
      },
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        return OTPVerificationScreen(
          email: extras?['email'] ?? '',
          isEmergency: extras?['isEmergency'] ?? false,
          isSignup: extras?['isSignup'] ?? false,
        );
      },
    ),
    GoRoute(
      path: '/account-conversion',
      builder: (context, state) => const AccountConversionScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionScreen(),
    ),
    GoRoute(
      path: '/no_internet',
      builder: (context, state) => const NoInternetScreen(),
    ),
    GoRoute(
      path: '/emergency-failed',
      builder: (context, state) => const EmergencyFailedScreen(),
    ),
    GoRoute(
      path: '/session-expired',
      builder: (context, state) => const SessionExpiredScreen(),
    ),
    GoRoute(
      path: '/payment-failed',
      builder: (context, state) => const PaymentFailedScreen(),
    ),
    GoRoute(
      path: '/booking-failed',
      builder: (context, state) => const BookingFailedScreen(),
    ),
    GoRoute(
      path: '/upload-failed',
      builder: (context, state) => const UploadFailedScreen(),
    ),
    GoRoute(
      path: '/doctor/earnings',
      builder: (context, state) => const EarningsAnalyticsScreen(),
    ),
    GoRoute(
      path: '/doctor/payments',
      builder: (context, state) => const DoctorPaymentsScreen(),
    ),
    GoRoute(
      path: '/doctor/subscription',
      builder: (context, state) => const SubscriptionManagementScreen(),
    ),
    GoRoute(
      path: '/doctor/schedule',
      builder: (context, state) => const ScheduleManagementScreen(),
    ),
    GoRoute(
      path: '/doctor/patient/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return PatientDetailsLayout(patientId: id);
      },
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/admin/doctor-verification',
      builder: (context, state) => const DoctorVerificationPanel(),
    ),
    GoRoute(
      path: '/admin/financial',
      builder: (context, state) => const FinancialModerationScreen(),
    ),
    GoRoute(
      path: '/admin/p2p-monitoring',
      builder: (context, state) => const P2PMonitoringPanel(),
    ),
    GoRoute(
      path: '/admin/disputes',
      builder: (context, state) => const DisputeResolutionScreen(),
    ),
    GoRoute(
      path: '/admin/subscription-control',
      builder: (context, state) => const SubscriptionPlanControl(),
    ),
    GoRoute(
      path: '/admin/doctor-subscriptions',
      builder: (context, state) => const DoctorSubscriptionManagement(),
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const NotificationControlPanel(),
    ),
    GoRoute(
      path: '/admin/emergency-queue',
      builder: (context, state) => const AdminEmergencyQueueScreen(),
    ),
    GoRoute(
      path: '/admin/user-management',
      builder: (context, state) => const UserManagementPanel(),
    ),
    GoRoute(
      path: '/credits',
      builder: (context, state) => const CreditsScreen(),
    ),
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
  ],
);
