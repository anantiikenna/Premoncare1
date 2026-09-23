import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('sw'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Premon Care'**
  String get appTitle;

  /// No description provided for @secureHealthcareSimplified.
  ///
  /// In en, this message translates to:
  /// **'Secure healthcare, simplified'**
  String get secureHealthcareSimplified;

  /// No description provided for @emergencyAccess.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY ACCESS'**
  String get emergencyAccess;

  /// No description provided for @needUrgentCareSkipLogin.
  ///
  /// In en, this message translates to:
  /// **'Need urgent care? Skip login.'**
  String get needUrgentCareSkipLogin;

  /// No description provided for @secureClinicalEcosystem.
  ///
  /// In en, this message translates to:
  /// **'SECURE CLINICAL ECOSYSTEM'**
  String get secureClinicalEcosystem;

  /// No description provided for @clinicalEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Clinical Email Address'**
  String get clinicalEmailAddress;

  /// No description provided for @otpLoginDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a seven digit one-time code to your email to log you in securely.'**
  String get otpLoginDescription;

  /// No description provided for @sendOtpCode.
  ///
  /// In en, this message translates to:
  /// **'SEND OTP CODE'**
  String get sendOtpCode;

  /// No description provided for @secureSocialSync.
  ///
  /// In en, this message translates to:
  /// **'SECURE SOCIAL SYNC'**
  String get secureSocialSync;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'GOOGLE'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'APPLE'**
  String get apple;

  /// No description provided for @googleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In will be available in the next update. Use email sign-in to continue.'**
  String get googleSignInUnavailable;

  /// No description provided for @appleSignInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In will be available in the next update. Use email sign-in to continue.'**
  String get appleSignInUnavailable;

  /// No description provided for @noClinicalAccount.
  ///
  /// In en, this message translates to:
  /// **'NO CLINICAL ACCOUNT? '**
  String get noClinicalAccount;

  /// No description provided for @createAccess.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCESS'**
  String get createAccess;

  /// No description provided for @hipaaCompliantAesEncrypted.
  ///
  /// In en, this message translates to:
  /// **'HIPAA COMPLIANT & AES-256 ENCRYPTED'**
  String get hipaaCompliantAesEncrypted;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmail;

  /// No description provided for @noAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Please sign up first.'**
  String get noAccountFound;

  /// No description provided for @tooManyFailedAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later.'**
  String get tooManyFailedAttempts;

  /// No description provided for @otpSendFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not send the verification code. Please try again.'**
  String get otpSendFailed;

  /// No description provided for @clinicalIdentity.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL IDENTITY'**
  String get clinicalIdentity;

  /// No description provided for @yourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Your Identity'**
  String get yourIdentity;

  /// No description provided for @joinEcosystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Join the Premoncare ecosystem and access\nworld-class clinical specialists.'**
  String get joinEcosystemDescription;

  /// No description provided for @fullLegalName.
  ///
  /// In en, this message translates to:
  /// **'Full Legal Name'**
  String get fullLegalName;

  /// No description provided for @phoneNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (optional)'**
  String get phoneNumberOptional;

  /// No description provided for @verificationCodeInfo.
  ///
  /// In en, this message translates to:
  /// **'We will send a seven digit verification code to your email. No password required.'**
  String get verificationCodeInfo;

  /// No description provided for @legalFramework.
  ///
  /// In en, this message translates to:
  /// **'LEGAL FRAMEWORK'**
  String get legalFramework;

  /// No description provided for @ourTerms.
  ///
  /// In en, this message translates to:
  /// **'Our Terms'**
  String get ourTerms;

  /// No description provided for @reviewTermsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review our clinical commitments and data\nsecurity protocols before proceeding.'**
  String get reviewTermsDescription;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Terms & Clinical Quality'**
  String get termsTitle;

  /// No description provided for @termsDescription.
  ///
  /// In en, this message translates to:
  /// **'By using Premoncare, you agree to supply correct clinical histories and behave respectfully during telehealth appointments.'**
  String get termsDescription;

  /// No description provided for @hipaaTitle.
  ///
  /// In en, this message translates to:
  /// **'2. HIPAA Data Privacy'**
  String get hipaaTitle;

  /// No description provided for @hipaaDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clinical records are AES-256 encrypted. We strictly follow HIPAA rules and never share medical data without explicit consent.'**
  String get hipaaDescription;

  /// No description provided for @ndaTitle.
  ///
  /// In en, this message translates to:
  /// **'3. Reciprocal NDA Agreement'**
  String get ndaTitle;

  /// No description provided for @ndaDescription.
  ///
  /// In en, this message translates to:
  /// **'To safeguard diagnostic confidentiality, you enter into a binding reciprocal NDA. You agree not to record, screenshot, or distribute consultations or messages.'**
  String get ndaDescription;

  /// No description provided for @termsAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'I acknowledge the Terms & Conditions, HIPAA Privacy Policy, and Non-Disclosure Agreement (NDA)'**
  String get termsAcknowledgment;

  /// No description provided for @verifyAndFinalize.
  ///
  /// In en, this message translates to:
  /// **'VERIFY & FINALIZE'**
  String get verifyAndFinalize;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email address and we\'ll send you a link to reset your password.'**
  String get forgotPasswordDescription;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterYourEmail;

  /// No description provided for @yourSecurityImportant.
  ///
  /// In en, this message translates to:
  /// **'Your security is important to us'**
  String get yourSecurityImportant;

  /// No description provided for @secureResetLinkDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a secure password reset link to your email address.'**
  String get secureResetLinkDescription;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @resetWithPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Reset with Phone Number'**
  String get resetWithPhoneNumber;

  /// No description provided for @phoneResetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number reset will be available in a future update. Use email reset for now.'**
  String get phoneResetUnavailable;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @informationSecureEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Your information is secure and encrypted'**
  String get informationSecureEncrypted;

  /// No description provided for @emergencyCare.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY CARE'**
  String get emergencyCare;

  /// No description provided for @fiveXPriorityAccess.
  ///
  /// In en, this message translates to:
  /// **'5x Priority Access'**
  String get fiveXPriorityAccess;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @createNewPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new password to secure your account.'**
  String get createNewPasswordDescription;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @oneUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get oneUppercaseLetter;

  /// No description provided for @oneNumber.
  ///
  /// In en, this message translates to:
  /// **'One number'**
  String get oneNumber;

  /// No description provided for @oneSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'One special character'**
  String get oneSpecialCharacter;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordRequirementsNotMet.
  ///
  /// In en, this message translates to:
  /// **'Please meet all password requirements before continuing.'**
  String get passwordRequirementsNotMet;

  /// No description provided for @resetting.
  ///
  /// In en, this message translates to:
  /// **'Resetting...'**
  String get resetting;

  /// No description provided for @makePasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Make sure your password is strong'**
  String get makePasswordStrong;

  /// No description provided for @strongPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'A strong password keeps your account safe and protects your personal data.'**
  String get strongPasswordDescription;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password Reset!'**
  String get passwordResetSuccess;

  /// No description provided for @passwordResetDescription.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully\nreset. You can now sign in with your\nnew password.'**
  String get passwordResetDescription;

  /// No description provided for @accountSecure.
  ///
  /// In en, this message translates to:
  /// **'Your account is secure'**
  String get accountSecure;

  /// No description provided for @confirmationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a confirmation email to your inbox.'**
  String get confirmationEmailSent;

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to Sign In'**
  String get goToSignIn;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @didntReceiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email?'**
  String get didntReceiveEmail;

  /// No description provided for @checkSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder or resend the email.'**
  String get checkSpamFolder;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @resetEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Reset email resent'**
  String get resetEmailResent;

  /// No description provided for @resetLinkSentCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your email inbox.'**
  String get resetLinkSentCheckInbox;

  /// No description provided for @couldNotSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'We could not send the reset link. Please try again.'**
  String get couldNotSendResetLink;

  /// No description provided for @identityVerification.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY VERIFICATION'**
  String get identityVerification;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @enter7DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 7-digit code sent to'**
  String get enter7DigitCode;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get edit;

  /// No description provided for @securityProtocol.
  ///
  /// In en, this message translates to:
  /// **'SECURITY PROTOCOL: Do not disclose this clinical access code to any third party.'**
  String get securityProtocol;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'VERIFYING...'**
  String get verifying;

  /// No description provided for @authorizeAndContinue.
  ///
  /// In en, this message translates to:
  /// **'AUTHORIZE & CONTINUE'**
  String get authorizeAndContinue;

  /// No description provided for @encryptedClinicalAuth.
  ///
  /// In en, this message translates to:
  /// **'256-BIT ENCRYPTED CLINICAL AUTHENTICATION'**
  String get encryptedClinicalAuth;

  /// No description provided for @expiresIn.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES IN'**
  String get expiresIn;

  /// No description provided for @missingTheDispatch.
  ///
  /// In en, this message translates to:
  /// **'MISSING THE DISPATCH?'**
  String get missingTheDispatch;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'RESEND CODE'**
  String get resendCode;

  /// No description provided for @newVerificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new verification code has been sent'**
  String get newVerificationCodeSent;

  /// No description provided for @resendFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not resend the code. Please wait a moment and try again.'**
  String get resendFailed;

  /// No description provided for @priorityCare.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY CARE'**
  String get priorityCare;

  /// No description provided for @pleaseEnter7DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 7-digit code'**
  String get pleaseEnter7DigitCode;

  /// No description provided for @tooManyAttemptsLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Account temporarily locked.'**
  String get tooManyAttemptsLocked;

  /// No description provided for @tooManyFailedAttemptsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Try again in {minutes} minutes.'**
  String tooManyFailedAttemptsTryAgain(Object minutes);

  /// No description provided for @thatCodeCouldNotBeVerified.
  ///
  /// In en, this message translates to:
  /// **'That code could not be verified.'**
  String get thatCodeCouldNotBeVerified;

  /// No description provided for @attemptsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} attempt(s) remaining'**
  String attemptsRemaining(Object count);

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get anErrorOccurred;

  /// No description provided for @adminCannotAccessPatientApp.
  ///
  /// In en, this message translates to:
  /// **'Admin accounts cannot access the patient/doctor app. Please use the Admin app.'**
  String get adminCannotAccessPatientApp;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpired;

  /// No description provided for @sessionExpiredDescription.
  ///
  /// In en, this message translates to:
  /// **'For your security, please sign in again\nto continue.'**
  String get sessionExpiredDescription;

  /// No description provided for @sessionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Your session has timed out'**
  String get sessionTimedOut;

  /// No description provided for @sessionTimeoutDescription.
  ///
  /// In en, this message translates to:
  /// **'For your safety, we automatically log you out after a period of inactivity.'**
  String get sessionTimeoutDescription;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign In Again'**
  String get signInAgain;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelp;

  /// No description provided for @supportTeam247.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here for you 24/7.'**
  String get supportTeam247;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @dataSafeWithUs.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe with us'**
  String get dataSafeWithUs;

  /// No description provided for @industryStandardSecurity.
  ///
  /// In en, this message translates to:
  /// **'We use industry-standard security to protect your information.'**
  String get industryStandardSecurity;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @permissionsDescription.
  ///
  /// In en, this message translates to:
  /// **'We need a couple of\npermissions to make your\nexperience seamless'**
  String get permissionsDescription;

  /// No description provided for @permissionsExplanation.
  ///
  /// In en, this message translates to:
  /// **'These permissions help us provide secure video\nconsultations and keep you updated on important\ninformation.'**
  String get permissionsExplanation;

  /// No description provided for @allowCamera.
  ///
  /// In en, this message translates to:
  /// **'Allow camera for consultations'**
  String get allowCamera;

  /// No description provided for @allowCameraDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your camera to connect face-to-face with doctors during video consultations for a better experience.'**
  String get allowCameraDescription;

  /// No description provided for @videoPrivateEncrypted.
  ///
  /// In en, this message translates to:
  /// **'Your video is private and encrypted end-to-end.'**
  String get videoPrivateEncrypted;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications for updates'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get timely updates about appointments, reminders, test results, prescriptions and important alerts.'**
  String get enableNotificationsDescription;

  /// No description provided for @changeSettingsLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings.'**
  String get changeSettingsLater;

  /// No description provided for @enableAllAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Enable All & Continue'**
  String get enableAllAndContinue;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @privacyMatters.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get privacyMatters;

  /// No description provided for @privacyMattersDescription.
  ///
  /// In en, this message translates to:
  /// **'We only use permissions to improve your healthcare experience.'**
  String get privacyMattersDescription;

  /// No description provided for @premonAdmin.
  ///
  /// In en, this message translates to:
  /// **'Premon Admin'**
  String get premonAdmin;

  /// No description provided for @administrativeAccessPortal.
  ///
  /// In en, this message translates to:
  /// **'Administrative Access Portal'**
  String get administrativeAccessPortal;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Admin Email'**
  String get adminEmail;

  /// No description provided for @adminOtpDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a seven digit verification code to your email.'**
  String get adminOtpDescription;

  /// No description provided for @sendAdminCode.
  ///
  /// In en, this message translates to:
  /// **'Send Admin Code'**
  String get sendAdminCode;

  /// No description provided for @securedAdministrativeSession.
  ///
  /// In en, this message translates to:
  /// **'SECURED ADMINISTRATIVE SESSION'**
  String get securedAdministrativeSession;

  /// No description provided for @pleaseEnterAdminEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your admin email address.'**
  String get pleaseEnterAdminEmail;

  /// No description provided for @noAdminAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Please contact the platform administrator.'**
  String get noAdminAccountFound;

  /// No description provided for @adminAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. This account does not have admin privileges.'**
  String get adminAccessDenied;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome ðŸ‘‹'**
  String get welcome;

  /// No description provided for @searchSpecialistsClinic.
  ///
  /// In en, this message translates to:
  /// **'Search specialists, clinic...'**
  String get searchSpecialistsClinic;

  /// No description provided for @consultationCredits.
  ///
  /// In en, this message translates to:
  /// **'CONSULTATION CREDITS'**
  String get consultationCredits;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @addCredit.
  ///
  /// In en, this message translates to:
  /// **'Add Credit'**
  String get addCredit;

  /// No description provided for @topSpecialists.
  ///
  /// In en, this message translates to:
  /// **'TOP SPECIALISTS'**
  String get topSpecialists;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @specialists.
  ///
  /// In en, this message translates to:
  /// **'Specialists'**
  String get specialists;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @medicalVault.
  ///
  /// In en, this message translates to:
  /// **'Medical Vault'**
  String get medicalVault;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @p2pTopUp.
  ///
  /// In en, this message translates to:
  /// **'P2P Top-up'**
  String get p2pTopUp;

  /// No description provided for @noSpecialistsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No specialists available at the moment.'**
  String get noSpecialistsAvailable;

  /// No description provided for @searchDoctors.
  ///
  /// In en, this message translates to:
  /// **'Search Doctors'**
  String get searchDoctors;

  /// No description provided for @searchDoctorsSpecialties.
  ///
  /// In en, this message translates to:
  /// **'Search doctors, specialties...'**
  String get searchDoctorsSpecialties;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @emergencyOnly.
  ///
  /// In en, this message translates to:
  /// **'Emergency Only'**
  String get emergencyOnly;

  /// No description provided for @showEmergencyReady.
  ///
  /// In en, this message translates to:
  /// **'Show only emergency-ready doctors'**
  String get showEmergencyReady;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @needImmediateCare.
  ///
  /// In en, this message translates to:
  /// **'Need immediate care? Find emergency doctors'**
  String get needImmediateCare;

  /// No description provided for @showingEmergencyDoctors.
  ///
  /// In en, this message translates to:
  /// **'Showing emergency-ready doctors nearby'**
  String get showingEmergencyDoctors;

  /// No description provided for @topRatedDoctors.
  ///
  /// In en, this message translates to:
  /// **'Top Rated Doctors'**
  String get topRatedDoctors;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'found'**
  String get found;

  /// No description provided for @noDoctorsAvailableEmergency.
  ///
  /// In en, this message translates to:
  /// **'No emergency doctors available right now'**
  String get noDoctorsAvailableEmergency;

  /// No description provided for @viewAllDoctors.
  ///
  /// In en, this message translates to:
  /// **'View All Doctors'**
  String get viewAllDoctors;

  /// No description provided for @emergencyDoctors.
  ///
  /// In en, this message translates to:
  /// **'Emergency Doctors'**
  String get emergencyDoctors;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get noDoctorsFound;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingSearch;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @buyCredit.
  ///
  /// In en, this message translates to:
  /// **'Buy Credit'**
  String get buyCredit;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @allDoctorsVerified.
  ///
  /// In en, this message translates to:
  /// **'All doctors are verified professionals'**
  String get allDoctorsVerified;

  /// No description provided for @verifyLicensesDescription.
  ///
  /// In en, this message translates to:
  /// **'We verify licenses, qualifications and experience to ensure you receive safe and quality care.'**
  String get verifyLicensesDescription;

  /// No description provided for @doctorPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Public Profile'**
  String get doctorPublicProfile;

  /// No description provided for @verifiedHealthcareProfessional.
  ///
  /// In en, this message translates to:
  /// **'Verified Healthcare Professional'**
  String get verifiedHealthcareProfessional;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// No description provided for @profileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied to clipboard'**
  String get profileLinkCopied;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// No description provided for @aboutDoctor.
  ///
  /// In en, this message translates to:
  /// **'About {doctorName}'**
  String aboutDoctor(Object doctorName);

  /// No description provided for @specializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get specializations;

  /// No description provided for @patientRating.
  ///
  /// In en, this message translates to:
  /// **'Patient Rating'**
  String get patientRating;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @verifiedTrusted.
  ///
  /// In en, this message translates to:
  /// **'Verified & Trusted'**
  String get verifiedTrusted;

  /// No description provided for @doctorLicenseVerified.
  ///
  /// In en, this message translates to:
  /// **'This doctor\'s license and qualifications have been verified by Premon Care.'**
  String get doctorLicenseVerified;

  /// No description provided for @videoConsultation.
  ///
  /// In en, this message translates to:
  /// **'Video Consultation'**
  String get videoConsultation;

  /// No description provided for @chatSupport.
  ///
  /// In en, this message translates to:
  /// **'Chat Support'**
  String get chatSupport;

  /// No description provided for @availableStatus.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableStatus;

  /// No description provided for @unavailableStatus.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailableStatus;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get responseTime;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @clinicalBooking.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL BOOKING'**
  String get clinicalBooking;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @specialistReview.
  ///
  /// In en, this message translates to:
  /// **'SPECIALIST REVIEW'**
  String get specialistReview;

  /// No description provided for @sessionDuration.
  ///
  /// In en, this message translates to:
  /// **'SESSION DURATION'**
  String get sessionDuration;

  /// No description provided for @pricingArchitecture.
  ///
  /// In en, this message translates to:
  /// **'PRICING ARCHITECTURE'**
  String get pricingArchitecture;

  /// No description provided for @proceedToConfirmation.
  ///
  /// In en, this message translates to:
  /// **'PROCEED TO CONFIRMATION'**
  String get proceedToConfirmation;

  /// No description provided for @priorityDispatch.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY DISPATCH'**
  String get priorityDispatch;

  /// No description provided for @emergencyAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Access'**
  String get emergencyAccessTitle;

  /// No description provided for @authorizeEmergencyCare.
  ///
  /// In en, this message translates to:
  /// **'AUTHORIZE EMERGENCY CARE'**
  String get authorizeEmergencyCare;

  /// No description provided for @clinicalBaseRate.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL BASE RATE'**
  String get clinicalBaseRate;

  /// No description provided for @sessionDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'SESSION DURATION'**
  String get sessionDurationLabel;

  /// No description provided for @emergencyPremium.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY PREMIUM'**
  String get emergencyPremium;

  /// No description provided for @fiveXRateApplied.
  ///
  /// In en, this message translates to:
  /// **'5X RATE APPLIED'**
  String get fiveXRateApplied;

  /// No description provided for @totalEstimate.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ESTIMATE'**
  String get totalEstimate;

  /// No description provided for @priorityAccess.
  ///
  /// In en, this message translates to:
  /// **'PRIORITY ACCESS'**
  String get priorityAccess;

  /// No description provided for @appointmentDetails.
  ///
  /// In en, this message translates to:
  /// **'APPOINTMENT DETAILS'**
  String get appointmentDetails;

  /// No description provided for @timeBalanceAvailability.
  ///
  /// In en, this message translates to:
  /// **'TIME BALANCE & AVAILABILITY'**
  String get timeBalanceAvailability;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT SUMMARY'**
  String get paymentSummary;

  /// No description provided for @consultationFee.
  ///
  /// In en, this message translates to:
  /// **'Consultation Fee'**
  String get consultationFee;

  /// No description provided for @platformService.
  ///
  /// In en, this message translates to:
  /// **'Platform Service'**
  String get platformService;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get totalPayable;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @purchaseTime.
  ///
  /// In en, this message translates to:
  /// **'Purchase Time'**
  String get purchaseTime;

  /// No description provided for @currentTimeBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Time Balance'**
  String get currentTimeBalance;

  /// No description provided for @afterBooking.
  ///
  /// In en, this message translates to:
  /// **'After Booking'**
  String get afterBooking;

  /// No description provided for @enoughBalance.
  ///
  /// In en, this message translates to:
  /// **'Enough balance'**
  String get enoughBalance;

  /// No description provided for @insufficient.
  ///
  /// In en, this message translates to:
  /// **'Insufficient'**
  String get insufficient;

  /// No description provided for @checkingBalance.
  ///
  /// In en, this message translates to:
  /// **'Checking balance...'**
  String get checkingBalance;

  /// No description provided for @emergencyModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Emergency mode triggers instant notification to the specialist for immediate clinical attention.'**
  String get emergencyModeDescription;

  /// No description provided for @endToEndEncrypted.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted booking & clinical records'**
  String get endToEndEncrypted;

  /// No description provided for @finalReview.
  ///
  /// In en, this message translates to:
  /// **'Final Review'**
  String get finalReview;

  /// No description provided for @emergencyReview.
  ///
  /// In en, this message translates to:
  /// **'Emergency Review'**
  String get emergencyReview;

  /// No description provided for @sessionMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min session'**
  String sessionMinutes(Object minutes);

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get verified;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @consultationType.
  ///
  /// In en, this message translates to:
  /// **'Consultation Type'**
  String get consultationType;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// No description provided for @inClinicVisit.
  ///
  /// In en, this message translates to:
  /// **'In-Clinic Visit'**
  String get inClinicVisit;

  /// No description provided for @emergencyBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Emergency Consult\nConfirmed'**
  String get emergencyBookingConfirmed;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking\nConfirmed!'**
  String get bookingConfirmed;

  /// No description provided for @emergencyConsultScheduled.
  ///
  /// In en, this message translates to:
  /// **'Your priority medical session is scheduled for immediate connection. Complete payment to start.'**
  String get emergencyConsultScheduled;

  /// No description provided for @bookingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been successfully scheduled and verified.'**
  String get bookingScheduled;

  /// No description provided for @specialist.
  ///
  /// In en, this message translates to:
  /// **'Specialist'**
  String get specialist;

  /// No description provided for @connectingAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Connecting automatically...'**
  String get connectingAutomatically;

  /// No description provided for @emergencySessionPayNow.
  ///
  /// In en, this message translates to:
  /// **'Emergency session â€” pay now to connect'**
  String get emergencySessionPayNow;

  /// No description provided for @p2pPaymentInstructions.
  ///
  /// In en, this message translates to:
  /// **'P2P Payment Instructions'**
  String get p2pPaymentInstructions;

  /// No description provided for @payEmergencyFeeBelow.
  ///
  /// In en, this message translates to:
  /// **'Pay the emergency fee below to start your consultation immediately:'**
  String get payEmergencyFeeBelow;

  /// No description provided for @contactDoctorPayment.
  ///
  /// In en, this message translates to:
  /// **'Contact doctor for payment details'**
  String get contactDoctorPayment;

  /// No description provided for @doctorAlertedAfterPayment.
  ///
  /// In en, this message translates to:
  /// **'Once paid, the doctor will be alerted for immediate session startup.'**
  String get doctorAlertedAfterPayment;

  /// No description provided for @needAssistance.
  ///
  /// In en, this message translates to:
  /// **'Need assistance?'**
  String get needAssistance;

  /// No description provided for @careTeamAvailable247.
  ///
  /// In en, this message translates to:
  /// **'Our care team is available 24/7'**
  String get careTeamAvailable247;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @createPermanentAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Permanent Account'**
  String get createPermanentAccount;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Continue'**
  String get signInToContinue;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @downloadDigitalReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Digital Receipt'**
  String get downloadDigitalReceipt;

  /// No description provided for @receiptCopiedClipboard.
  ///
  /// In en, this message translates to:
  /// **'Receipt copied to clipboard'**
  String get receiptCopiedClipboard;

  /// No description provided for @sessionFinalized.
  ///
  /// In en, this message translates to:
  /// **'SESSION FINALIZED'**
  String get sessionFinalized;

  /// No description provided for @summaryReport.
  ///
  /// In en, this message translates to:
  /// **'Summary Report'**
  String get summaryReport;

  /// No description provided for @consultingSpecialist.
  ///
  /// In en, this message translates to:
  /// **'CONSULTING SPECIALIST'**
  String get consultingSpecialist;

  /// No description provided for @clinicalPrescription.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL PRESCRIPTION'**
  String get clinicalPrescription;

  /// No description provided for @noPrescriptionsIssued.
  ///
  /// In en, this message translates to:
  /// **'No prescriptions issued for this session.'**
  String get noPrescriptionsIssued;

  /// No description provided for @unableToLoadPrescriptions.
  ///
  /// In en, this message translates to:
  /// **'Unable to load prescriptions.'**
  String get unableToLoadPrescriptions;

  /// No description provided for @doctorsObservations.
  ///
  /// In en, this message translates to:
  /// **'DOCTOR\'S OBSERVATIONS'**
  String get doctorsObservations;

  /// No description provided for @noObservationsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No observations recorded for this session.'**
  String get noObservationsRecorded;

  /// No description provided for @unableToLoadObservations.
  ///
  /// In en, this message translates to:
  /// **'Unable to load observations.'**
  String get unableToLoadObservations;

  /// No description provided for @experienceRating.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE RATING'**
  String get experienceRating;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get sessionComplete;

  /// No description provided for @sessionCompleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Your clinical encounter has been verified and securely archived.'**
  String get sessionCompleteDescription;

  /// No description provided for @nextEvaluation.
  ///
  /// In en, this message translates to:
  /// **'NEXT EVALUATION'**
  String get nextEvaluation;

  /// No description provided for @nextEvaluationDescription.
  ///
  /// In en, this message translates to:
  /// **'Scheduled in 7 days to monitor clinical trajectory.'**
  String get nextEvaluationDescription;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get schedule;

  /// No description provided for @pdfReport.
  ///
  /// In en, this message translates to:
  /// **'PDF REPORT'**
  String get pdfReport;

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'SHARE LINK'**
  String get shareLink;

  /// No description provided for @dismissReport.
  ///
  /// In en, this message translates to:
  /// **'DISMISS REPORT'**
  String get dismissReport;

  /// No description provided for @followUpDays.
  ///
  /// In en, this message translates to:
  /// **'Follow-up in {count} days'**
  String followUpDays(Object count);

  /// No description provided for @generalMedicalPhysician.
  ///
  /// In en, this message translates to:
  /// **'General Medical Physician'**
  String get generalMedicalPhysician;

  /// No description provided for @connectingYou.
  ///
  /// In en, this message translates to:
  /// **'Connecting You...'**
  String get connectingYou;

  /// No description provided for @doctorAccepted.
  ///
  /// In en, this message translates to:
  /// **'Doctor Accepted!'**
  String get doctorAccepted;

  /// No description provided for @doctorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Doctor Unavailable'**
  String get doctorUnavailable;

  /// No description provided for @requestExpired.
  ///
  /// In en, this message translates to:
  /// **'Request Expired'**
  String get requestExpired;

  /// No description provided for @sendingEmergencyRequest.
  ///
  /// In en, this message translates to:
  /// **'Sending your emergency request to {doctorName}...'**
  String sendingEmergencyRequest(Object doctorName);

  /// No description provided for @doctorReadyConsultation.
  ///
  /// In en, this message translates to:
  /// **'{doctorName} is ready for your consultation.'**
  String doctorReadyConsultation(Object doctorName);

  /// No description provided for @doctorUnavailableDescription.
  ///
  /// In en, this message translates to:
  /// **'The doctor is currently unavailable. Let us find you another specialist.'**
  String get doctorUnavailableDescription;

  /// No description provided for @requestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. We\'ll find you another available doctor.'**
  String get requestTimedOut;

  /// No description provided for @waitingForDoctor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for doctor response'**
  String get waitingForDoctor;

  /// No description provided for @urgentNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'The doctor will receive an urgent notification. You\'ll be connected immediately once they accept.'**
  String get urgentNotificationDescription;

  /// No description provided for @doctorUnableToTakeCase.
  ///
  /// In en, this message translates to:
  /// **'{doctorName} is unable to take your case right now.'**
  String doctorUnableToTakeCase(Object doctorName);

  /// No description provided for @noResponseReceived.
  ///
  /// In en, this message translates to:
  /// **'No response received within the time limit.'**
  String get noResponseReceived;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @findAnotherDoctor.
  ///
  /// In en, this message translates to:
  /// **'Find Another Doctor'**
  String get findAnotherDoctor;

  /// No description provided for @emergencyConsultation.
  ///
  /// In en, this message translates to:
  /// **'Emergency Consultation'**
  String get emergencyConsultation;

  /// No description provided for @uploadPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Receipt'**
  String get uploadPaymentReceipt;

  /// No description provided for @uploadReceiptDescription.
  ///
  /// In en, this message translates to:
  /// **'Upload your payment proof for verification'**
  String get uploadReceiptDescription;

  /// No description provided for @uploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt'**
  String get uploadReceipt;

  /// No description provided for @jpgPngPdf.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF (Max 5MB)'**
  String get jpgPngPdf;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @yourDataSecure.
  ///
  /// In en, this message translates to:
  /// **'Your data is secure and encrypted'**
  String get yourDataSecure;

  /// No description provided for @payingTo.
  ///
  /// In en, this message translates to:
  /// **'Paying To'**
  String get payingTo;

  /// No description provided for @selectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Select a doctor'**
  String get selectDoctor;

  /// No description provided for @loadingDoctors.
  ///
  /// In en, this message translates to:
  /// **'Loading doctors...'**
  String get loadingDoctors;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid (â‚¦)'**
  String get amountPaid;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @p2pTransfer.
  ///
  /// In en, this message translates to:
  /// **'P2P Transfer'**
  String get p2pTransfer;

  /// No description provided for @transactionReferenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Transaction Reference (Optional)'**
  String get transactionReferenceOptional;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @submitForVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get submitForVerification;

  /// No description provided for @receiptSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Receipt submitted for verification'**
  String get receiptSubmitted;

  /// No description provided for @tipsFasterVerification.
  ///
  /// In en, this message translates to:
  /// **'Tips for faster verification'**
  String get tipsFasterVerification;

  /// No description provided for @amountVisibleTip.
  ///
  /// In en, this message translates to:
  /// **'â€¢ Make sure the amount is clearly visible'**
  String get amountVisibleTip;

  /// No description provided for @clearImageTip.
  ///
  /// In en, this message translates to:
  /// **'â€¢ Use a clear, well-lit image of the receipt'**
  String get clearImageTip;

  /// No description provided for @pleaseSelectReceipt.
  ///
  /// In en, this message translates to:
  /// **'Please select a receipt image first'**
  String get pleaseSelectReceipt;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter the amount paid'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseSelectDoctor.
  ///
  /// In en, this message translates to:
  /// **'Please select the doctor you are paying'**
  String get pleaseSelectDoctor;

  /// No description provided for @fileSizeUnder5MB.
  ///
  /// In en, this message translates to:
  /// **'File size must be under 5MB'**
  String get fileSizeUnder5MB;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @changeFile.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get changeFile;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking Failed'**
  String get bookingFailed;

  /// No description provided for @bookingFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm your booking'**
  String get bookingFailedDescription;

  /// No description provided for @slotUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This time slot is no longer available or has just been\nbooked by someone else.\nPlease choose another time.'**
  String get slotUnavailable;

  /// No description provided for @bookingDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetailsLabel;

  /// No description provided for @chooseAnotherTime.
  ///
  /// In en, this message translates to:
  /// **'Choose Another Time'**
  String get chooseAnotherTime;

  /// No description provided for @viewOtherDoctors.
  ///
  /// In en, this message translates to:
  /// **'View Other Doctors'**
  String get viewOtherDoctors;

  /// No description provided for @needHelpFindingSlot.
  ///
  /// In en, this message translates to:
  /// **'Need help finding a slot?'**
  String get needHelpFindingSlot;

  /// No description provided for @supportTeamHelp.
  ///
  /// In en, this message translates to:
  /// **'Our support team can help you find the next available slot.'**
  String get supportTeamHelp;

  /// No description provided for @contactSupportForAssistance.
  ///
  /// In en, this message translates to:
  /// **'Contact support@premoncare.com for assistance'**
  String get contactSupportForAssistance;

  /// No description provided for @backToHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHomeLabel;

  /// No description provided for @whatWouldYouLikeToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatWouldYouLikeToDo;

  /// No description provided for @slotNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Slot not available'**
  String get slotNotAvailable;

  /// No description provided for @slotNotAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'This time slot is no longer available. Please select a different time or date.'**
  String get slotNotAvailableDescription;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @paymentFailedDescription.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t process your payment.\nPlease try again.'**
  String get paymentFailedDescription;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @useAnotherPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Use Another Payment Method'**
  String get useAnotherPaymentMethod;

  /// No description provided for @networkIssueDetected.
  ///
  /// In en, this message translates to:
  /// **'Network issue detected'**
  String get networkIssueDetected;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection\nand try again.'**
  String get checkInternetConnection;

  /// No description provided for @financialHub.
  ///
  /// In en, this message translates to:
  /// **'FINANCIAL HUB'**
  String get financialHub;

  /// No description provided for @consultationCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Consultation Credits'**
  String get consultationCreditsTitle;

  /// No description provided for @buyTime.
  ///
  /// In en, this message translates to:
  /// **'Buy Time'**
  String get buyTime;

  /// No description provided for @uploadReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'Upload Receipt'**
  String get uploadReceiptAction;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction history will appear here after your first credit purchase'**
  String get transactionHistory;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get guide;

  /// No description provided for @noCreditsYet.
  ///
  /// In en, this message translates to:
  /// **'No credits yet'**
  String get noCreditsYet;

  /// No description provided for @purchaseCreditsDescription.
  ///
  /// In en, this message translates to:
  /// **'Purchase time credits to consult with your doctors'**
  String get purchaseCreditsDescription;

  /// No description provided for @buyCredits.
  ///
  /// In en, this message translates to:
  /// **'Buy Credits'**
  String get buyCredits;

  /// No description provided for @totalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Total Remaining'**
  String get totalRemaining;

  /// No description provided for @acrossActiveDoctors.
  ///
  /// In en, this message translates to:
  /// **'Across {count} Active Doctors'**
  String acrossActiveDoctors(Object count);

  /// No description provided for @activeCredits.
  ///
  /// In en, this message translates to:
  /// **'Active Credits'**
  String get activeCredits;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @buyMore.
  ///
  /// In en, this message translates to:
  /// **'Buy More'**
  String get buyMore;

  /// No description provided for @consult.
  ///
  /// In en, this message translates to:
  /// **'Consult'**
  String get consult;

  /// No description provided for @creditsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Credits are doctor-specific. Time credits can only be used to consult with the doctor who credited them. Unused time never expires.'**
  String get creditsDisclaimer;

  /// No description provided for @myDoctorCredits.
  ///
  /// In en, this message translates to:
  /// **'MY DOCTOR CREDITS'**
  String get myDoctorCredits;

  /// No description provided for @manageSharingAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage Sharing Access'**
  String get manageSharingAccess;

  /// No description provided for @noVerifiedDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No verified doctors found.'**
  String get noVerifiedDoctorsFound;

  /// No description provided for @openExternalViewer.
  ///
  /// In en, this message translates to:
  /// **'Open External Viewer'**
  String get openExternalViewer;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @couldNotOpenViewer.
  ///
  /// In en, this message translates to:
  /// **'Could not open external viewer'**
  String get couldNotOpenViewer;

  /// No description provided for @phoneCallFeature.
  ///
  /// In en, this message translates to:
  /// **'Phone call feature - start a consultation to use this.'**
  String get phoneCallFeature;

  /// No description provided for @videoCallFeature.
  ///
  /// In en, this message translates to:
  /// **'Video call feature - start a consultation to use this.'**
  String get videoCallFeature;

  /// No description provided for @replyPosted.
  ///
  /// In en, this message translates to:
  /// **'Reply posted'**
  String get replyPosted;

  /// No description provided for @failedToReply.
  ///
  /// In en, this message translates to:
  /// **'Failed to reply: {error}'**
  String failedToReply(Object error);

  /// No description provided for @postSaved.
  ///
  /// In en, this message translates to:
  /// **'Post saved'**
  String get postSaved;

  /// No description provided for @followToggled.
  ///
  /// In en, this message translates to:
  /// **'Follow toggled'**
  String get followToggled;

  /// No description provided for @markedAsHelpful.
  ///
  /// In en, this message translates to:
  /// **'Marked as helpful'**
  String get markedAsHelpful;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share Post'**
  String get sharePost;

  /// No description provided for @postLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Post link copied to clipboard'**
  String get postLinkCopied;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @postReported.
  ///
  /// In en, this message translates to:
  /// **'Post reported'**
  String get postReported;

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No posts found.'**
  String get noPostsFound;

  /// No description provided for @savePost.
  ///
  /// In en, this message translates to:
  /// **'Save Post'**
  String get savePost;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseDescribeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Please describe your question'**
  String get pleaseDescribeQuestion;

  /// No description provided for @postSubmittedForReview.
  ///
  /// In en, this message translates to:
  /// **'Post submitted for review'**
  String get postSubmittedForReview;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'{label}: Coming soon'**
  String comingSoon(Object label);

  /// No description provided for @askFirstQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask the First Question'**
  String get askFirstQuestion;

  /// No description provided for @searchTopics.
  ///
  /// In en, this message translates to:
  /// **'Search topics, questions or keywords...'**
  String get searchTopics;

  /// No description provided for @searchHealthQuestions.
  ///
  /// In en, this message translates to:
  /// **'Search health questions...'**
  String get searchHealthQuestions;

  /// No description provided for @writeReply.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get writeReply;

  /// No description provided for @whyReportingPost.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this post?'**
  String get whyReportingPost;

  /// No description provided for @writePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a clear and short title for your post'**
  String get writePostTitle;

  /// No description provided for @provideMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide more details about your question or topic.'**
  String get provideMoreDetails;

  /// No description provided for @enterLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter license number'**
  String get enterLicenseNumber;

  /// No description provided for @enterTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dr., Prof.'**
  String get enterTitleHint;

  /// No description provided for @enterSpecialtyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. General Practitioner'**
  String get enterSpecialtyHint;

  /// No description provided for @enterExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5'**
  String get enterExperienceHint;

  /// No description provided for @licenseNumberHint.
  ///
  /// In en, this message translates to:
  /// **'MD-XXXXX'**
  String get licenseNumberHint;

  /// No description provided for @uploadIdCard.
  ///
  /// In en, this message translates to:
  /// **'Upload ID Card'**
  String get uploadIdCard;

  /// No description provided for @captureSelfie.
  ///
  /// In en, this message translates to:
  /// **'Capture Selfie'**
  String get captureSelfie;

  /// No description provided for @searchByNameEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email or phone...'**
  String get searchByNameEmailPhone;

  /// No description provided for @addCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)...'**
  String get addCommentOptional;

  /// No description provided for @explainFollowUpNecessary.
  ///
  /// In en, this message translates to:
  /// **'Explain why this follow-up is necessary...'**
  String get explainFollowUpNecessary;

  /// No description provided for @searchPatients.
  ///
  /// In en, this message translates to:
  /// **'Search patients...'**
  String get searchPatients;

  /// No description provided for @searchByPatientName.
  ///
  /// In en, this message translates to:
  /// **'Search by patient name...'**
  String get searchByPatientName;

  /// No description provided for @addResolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'Add resolution notes (optional)'**
  String get addResolutionNotes;

  /// No description provided for @searchDoctorNameEmail.
  ///
  /// In en, this message translates to:
  /// **'Search doctor by name, email or plan...'**
  String get searchDoctorNameEmail;

  /// No description provided for @reasonForRejection.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection...'**
  String get reasonForRejection;

  /// No description provided for @searchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByNameOrEmail;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)...'**
  String get addNoteOptional;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification title'**
  String get notificationTitle;

  /// No description provided for @notificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification message'**
  String get notificationMessage;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @deleteRecordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"? This cannot be undone.'**
  String deleteRecordConfirmation(Object title);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'{title} deleted'**
  String recordDeleted(Object title);

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDelete(Object error);

  /// No description provided for @accessRevoked.
  ///
  /// In en, this message translates to:
  /// **'Access revoked'**
  String get accessRevoked;

  /// No description provided for @failedToUpdateAccess.
  ///
  /// In en, this message translates to:
  /// **'Failed to update access: {error}'**
  String failedToUpdateAccess(Object error);

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(Object error);

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String failedToUpdateProfile(Object error);

  /// No description provided for @pauseSubscription.
  ///
  /// In en, this message translates to:
  /// **'Pause Subscription'**
  String get pauseSubscription;

  /// No description provided for @subscriptionPaused.
  ///
  /// In en, this message translates to:
  /// **'Subscription paused. Resume anytime from settings.'**
  String get subscriptionPaused;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled. Access continues until end of billing period.'**
  String get subscriptionCancelled;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @emailAdminForSubscription.
  ///
  /// In en, this message translates to:
  /// **'Email admin@premoncare.com for subscription support'**
  String get emailAdminForSubscription;

  /// No description provided for @contactSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact support@premoncare.com'**
  String get contactSupportEmail;

  /// No description provided for @planSelected.
  ///
  /// In en, this message translates to:
  /// **'Plan selected! Contact support@premoncare.com to complete your upgrade.'**
  String get planSelected;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @workingHoursDescription.
  ///
  /// In en, this message translates to:
  /// **'Working hours management is being developed. Edit your available slots in the schedule table above.'**
  String get workingHoursDescription;

  /// No description provided for @unavailableDays.
  ///
  /// In en, this message translates to:
  /// **'Unavailable Days'**
  String get unavailableDays;

  /// No description provided for @unavailableDaysDescription.
  ///
  /// In en, this message translates to:
  /// **'Date blocking is being developed. Remove individual time slots from the schedule to block specific dates.'**
  String get unavailableDaysDescription;

  /// No description provided for @breakTimes.
  ///
  /// In en, this message translates to:
  /// **'Break Times'**
  String get breakTimes;

  /// No description provided for @breakTimesDescription.
  ///
  /// In en, this message translates to:
  /// **'Break scheduling is being developed. Remove time slots from the table to create breaks between appointments.'**
  String get breakTimesDescription;

  /// No description provided for @failedToSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Failed to update emergency availability. Please try again.'**
  String get failedToSaveSchedule;

  /// No description provided for @scheduleCopiedToAllDays.
  ///
  /// In en, this message translates to:
  /// **'Schedule hours copied to all days'**
  String get scheduleCopiedToAllDays;

  /// No description provided for @breakTimeAdded.
  ///
  /// In en, this message translates to:
  /// **'Break time added'**
  String get breakTimeAdded;

  /// No description provided for @scheduleSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved successfully âœ“'**
  String get scheduleSavedSuccessfully;

  /// No description provided for @rateDoctor.
  ///
  /// In en, this message translates to:
  /// **'Rate Dr. {doctorName}'**
  String rateDoctor(Object doctorName);

  /// No description provided for @howWasConsultation.
  ///
  /// In en, this message translates to:
  /// **'How was your consultation experience?'**
  String get howWasConsultation;

  /// No description provided for @sessionRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Session rescheduled successfully'**
  String get sessionRescheduled;

  /// No description provided for @failedToJoinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Failed to join meeting: {error}'**
  String failedToJoinMeeting(Object error);

  /// No description provided for @retryingConnection.
  ///
  /// In en, this message translates to:
  /// **'Retrying connection...'**
  String get retryingConnection;

  /// No description provided for @emergencyLine.
  ///
  /// In en, this message translates to:
  /// **'Emergency line: +234-XXX-XXXX'**
  String get emergencyLine;

  /// No description provided for @contactSupportEmergency.
  ///
  /// In en, this message translates to:
  /// **'Support: support@premoncare.com'**
  String get contactSupportEmergency;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {email}'**
  String otpSentTo(Object email);

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get verificationFailed;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCode;

  /// No description provided for @failedToSendOtp.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Please try again.'**
  String get failedToSendOtp;

  /// No description provided for @guestEmergencySessionDetected.
  ///
  /// In en, this message translates to:
  /// **'Guest Emergency Session\nDetected'**
  String get guestEmergencySessionDetected;

  /// No description provided for @guestEmergencyDescription.
  ///
  /// In en, this message translates to:
  /// **'This user accessed emergency care as a guest.\nComplete a few quick steps to create an account.'**
  String get guestEmergencyDescription;

  /// No description provided for @sessionId.
  ///
  /// In en, this message translates to:
  /// **'Session ID'**
  String get sessionId;

  /// No description provided for @accessTime.
  ///
  /// In en, this message translates to:
  /// **'Access Time'**
  String get accessTime;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @criticalCondition.
  ///
  /// In en, this message translates to:
  /// **'Critical Condition'**
  String get criticalCondition;

  /// No description provided for @continueCare.
  ///
  /// In en, this message translates to:
  /// **'Continue Care'**
  String get continueCare;

  /// No description provided for @accessMedicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Access your medical history anytime'**
  String get accessMedicalHistory;

  /// No description provided for @secureAndPrivate.
  ///
  /// In en, this message translates to:
  /// **'Secure & Private'**
  String get secureAndPrivate;

  /// No description provided for @dataEncryptedProtected.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted and protected'**
  String get dataEncryptedProtected;

  /// No description provided for @fasterNextTime.
  ///
  /// In en, this message translates to:
  /// **'Faster Next Time'**
  String get fasterNextTime;

  /// No description provided for @skipLongForms.
  ///
  /// In en, this message translates to:
  /// **'Skip long forms and get help quicker'**
  String get skipLongForms;

  /// No description provided for @betterSupport.
  ///
  /// In en, this message translates to:
  /// **'Better Support'**
  String get betterSupport;

  /// No description provided for @supportEfficiently.
  ///
  /// In en, this message translates to:
  /// **'We can support you more efficiently'**
  String get supportEfficiently;

  /// No description provided for @continueToCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue to Create Account'**
  String get continueToCreateAccount;

  /// No description provided for @emergencySessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Emergency Session Completed Successfully'**
  String get emergencySessionCompleted;

  /// No description provided for @continueCreatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue creating your secure healthcare account to get the best care experience.'**
  String get continueCreatingAccount;

  /// No description provided for @checkEmailVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the verification code'**
  String get checkEmailVerificationCode;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @whyVerifyNumber.
  ///
  /// In en, this message translates to:
  /// **'Why verify your number?'**
  String get whyVerifyNumber;

  /// No description provided for @continueCareDescription.
  ///
  /// In en, this message translates to:
  /// **'Access your emergency consultation history.'**
  String get continueCareDescription;

  /// No description provided for @followUpUpdates.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Updates'**
  String get followUpUpdates;

  /// No description provided for @receiveDoctorUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive doctor updates and appointment alerts.'**
  String get receiveDoctorUpdates;

  /// No description provided for @secureRecords.
  ///
  /// In en, this message translates to:
  /// **'Secure Records'**
  String get secureRecords;

  /// No description provided for @protectMedicalInfo.
  ///
  /// In en, this message translates to:
  /// **'Protect your medical information.'**
  String get protectMedicalInfo;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip For Now'**
  String get skipForNow;

  /// No description provided for @skippingVerificationWarning.
  ///
  /// In en, this message translates to:
  /// **'Skipping verification may limit access to your consultation records and future healthcare services.'**
  String get skippingVerificationWarning;

  /// No description provided for @informationEncryptedProtected.
  ///
  /// In en, this message translates to:
  /// **'Your information is encrypted and protected under healthcare privacy standards.'**
  String get informationEncryptedProtected;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost there!'**
  String get almostThere;

  /// No description provided for @fewMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Just a few more details to create your secure account.'**
  String get fewMoreDetails;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @emailAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Email Address (Optional)'**
  String get emailAddressOptional;

  /// No description provided for @importantUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this for important updates and notifications.'**
  String get importantUpdatesDescription;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @emergencyContactOptional.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact (Optional)'**
  String get emergencyContactOptional;

  /// No description provided for @yourHealthDataProtected.
  ///
  /// In en, this message translates to:
  /// **'Your health data is protected'**
  String get yourHealthDataProtected;

  /// No description provided for @advancedEncryptionDescription.
  ///
  /// In en, this message translates to:
  /// **'We use advanced encryption to keep your information safe and private.'**
  String get advancedEncryptionDescription;

  /// No description provided for @youCanUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'You can update this information anytime in your profile settings.'**
  String get youCanUpdateLater;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account Created\nSuccessfully!'**
  String get accountCreatedSuccessfully;

  /// No description provided for @welcomeToPremonCare.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premon Care. You can now access all features, track your health and manage your care.'**
  String get welcomeToPremonCare;

  /// No description provided for @yourAccountIsReady.
  ///
  /// In en, this message translates to:
  /// **'Your Account is Ready'**
  String get yourAccountIsReady;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @addedLabel.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get addedLabel;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @informationSecureEncryptedSmall.
  ///
  /// In en, this message translates to:
  /// **'Your information is\nsecure and encrypted.'**
  String get informationSecureEncryptedSmall;

  /// No description provided for @whatYouCanDoNext.
  ///
  /// In en, this message translates to:
  /// **'What you can do next'**
  String get whatYouCanDoNext;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats...'**
  String get searchChats;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @searchAppointments.
  ///
  /// In en, this message translates to:
  /// **'Search Appointments'**
  String get searchAppointments;

  /// No description provided for @clinicalTimeline.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL TIMELINE'**
  String get clinicalTimeline;

  /// No description provided for @contactSupportPremoncare.
  ///
  /// In en, this message translates to:
  /// **'Contact support: support@premoncare.com'**
  String get contactSupportPremoncare;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @areYouSureLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureLogOut;

  /// No description provided for @errorLoadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard: {error}'**
  String errorLoadingDashboard(Object error);

  /// No description provided for @failedToLoadStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load stats'**
  String get failedToLoadStats;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @titleReportDeveloped.
  ///
  /// In en, this message translates to:
  /// **'{title} report is being developed.'**
  String titleReportDeveloped(Object title);

  /// No description provided for @reviewRefunds.
  ///
  /// In en, this message translates to:
  /// **'Review Refunds'**
  String get reviewRefunds;

  /// No description provided for @refundReviewUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Refund review is under development.'**
  String get refundReviewUnderDevelopment;

  /// No description provided for @payoutSettingsUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Payout settings are under development.'**
  String get payoutSettingsUnderDevelopment;

  /// No description provided for @payoutsApproved.
  ///
  /// In en, this message translates to:
  /// **'Payouts approved successfully!'**
  String get payoutsApproved;

  /// No description provided for @selectDoctorsReminders.
  ///
  /// In en, this message translates to:
  /// **'Select doctors to send reminders.'**
  String get selectDoctorsReminders;

  /// No description provided for @selectDoctorsExtend.
  ///
  /// In en, this message translates to:
  /// **'Select doctors to extend subscriptions.'**
  String get selectDoctorsExtend;

  /// No description provided for @selectDoctorsSuspend.
  ///
  /// In en, this message translates to:
  /// **'Select doctors to suspend.'**
  String get selectDoctorsSuspend;

  /// No description provided for @exportBeingPrepared.
  ///
  /// In en, this message translates to:
  /// **'Export is being prepared.'**
  String get exportBeingPrepared;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @selectDoctorsFirst.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Disputes from the sidebar menu.'**
  String get selectDoctorsFirst;

  /// No description provided for @selectUserFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a user first to block them.'**
  String get selectUserFirst;

  /// No description provided for @riskSettingsUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Risk settings panel is under development.'**
  String get riskSettingsUnderDevelopment;

  /// No description provided for @dismissReportAction.
  ///
  /// In en, this message translates to:
  /// **'Report dismissed'**
  String get dismissReportAction;

  /// No description provided for @postRemovedAndReportResolved.
  ///
  /// In en, this message translates to:
  /// **'Post removed and report resolved'**
  String get postRemovedAndReportResolved;

  /// No description provided for @categoryManagementComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Category management coming soon'**
  String get categoryManagementComingSoon;

  /// No description provided for @flaggedPostsViewComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Flagged posts view coming soon'**
  String get flaggedPostsViewComingSoon;

  /// No description provided for @doctorVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Doctor verified successfully!'**
  String get doctorVerifiedSuccessfully;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application rejected.'**
  String get applicationRejected;

  /// No description provided for @failedToLoadDoctors.
  ///
  /// In en, this message translates to:
  /// **'Failed to load doctors: {error}'**
  String failedToLoadDoctors(Object error);

  /// No description provided for @failedToLoadCounts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load counts: {error}'**
  String failedToLoadCounts(Object error);

  /// No description provided for @notificationSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully'**
  String get notificationSentSuccessfully;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @failedToSendNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String failedToSendNotification(Object error);

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @patientsOnly.
  ///
  /// In en, this message translates to:
  /// **'Patients Only'**
  String get patientsOnly;

  /// No description provided for @doctorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Doctors Only'**
  String get doctorsOnly;

  /// No description provided for @failedToUpdateChannel.
  ///
  /// In en, this message translates to:
  /// **'Failed to update channel: {error}'**
  String failedToUpdateChannel(Object error);

  /// No description provided for @notificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get notificationCenter;

  /// No description provided for @appointmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Appointment not found'**
  String get appointmentNotFound;

  /// No description provided for @downloadSummary.
  ///
  /// In en, this message translates to:
  /// **'Download Summary'**
  String get downloadSummary;

  /// No description provided for @shareDetails.
  ///
  /// In en, this message translates to:
  /// **'Share Details'**
  String get shareDetails;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get accountSettings;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get yourProfile;

  /// No description provided for @verifiedDoctor.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED DOCTOR'**
  String get verifiedDoctor;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'PENDING VERIFICATION'**
  String get pendingVerification;

  /// No description provided for @unverifiedPatient.
  ///
  /// In en, this message translates to:
  /// **'UNVERIFIED PATIENT'**
  String get unverifiedPatient;

  /// No description provided for @patientMode.
  ///
  /// In en, this message translates to:
  /// **'Patient Mode'**
  String get patientMode;

  /// No description provided for @doctorMode.
  ///
  /// In en, this message translates to:
  /// **'Doctor Mode'**
  String get doctorMode;

  /// No description provided for @unifiedAccount.
  ///
  /// In en, this message translates to:
  /// **'UNIFIED ACCOUNT'**
  String get unifiedAccount;

  /// No description provided for @completeVerificationPractitioner.
  ///
  /// In en, this message translates to:
  /// **'Complete verification to unlock Practitioner features'**
  String get completeVerificationPractitioner;

  /// No description provided for @personalInformationMenu.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationMenu;

  /// No description provided for @practitionerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Practitioner Registration'**
  String get practitionerRegistration;

  /// No description provided for @medicalRecords.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get medicalRecords;

  /// No description provided for @myCreditsAndBilling.
  ///
  /// In en, this message translates to:
  /// **'My Credits & Billing'**
  String get myCreditsAndBilling;

  /// No description provided for @notificationsMenu.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsMenu;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @supportContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Support: support@premoncare.com | WhatsApp: +234 800 000 0000'**
  String get supportContactInfo;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Dedicated and compassionate healthcare professional committed to delivering quality patient care.'**
  String get aboutText;

  /// No description provided for @followUpIn7Days.
  ///
  /// In en, this message translates to:
  /// **'Scheduled in 7 days to monitor clinical trajectory.'**
  String get followUpIn7Days;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(Object error);

  /// No description provided for @notAuthenticatedPleaseLogIn.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated. Please log in again.'**
  String get notAuthenticatedPleaseLogIn;

  /// No description provided for @onlineStatusDisabledInPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Online status is disabled in privacy settings'**
  String get onlineStatusDisabledInPrivacy;

  /// No description provided for @nowActiveForEmergencyConsult.
  ///
  /// In en, this message translates to:
  /// **'You are now active for emergency consult requests.'**
  String get nowActiveForEmergencyConsult;

  /// No description provided for @emergencyPresenceTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Emergency presence turned off.'**
  String get emergencyPresenceTurnedOff;

  /// No description provided for @permissionDeniedProfileSetup.
  ///
  /// In en, this message translates to:
  /// **'Permission denied. Please ensure your profile is fully set up.'**
  String get permissionDeniedProfileSetup;

  /// No description provided for @failedToUpdatePresence.
  ///
  /// In en, this message translates to:
  /// **'Failed to update presence: {error}'**
  String failedToUpdatePresence(Object error);

  /// No description provided for @practitionerHub.
  ///
  /// In en, this message translates to:
  /// **'PRACTITIONER HUB'**
  String get practitionerHub;

  /// No description provided for @emergencyRequest.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY REQUEST'**
  String get emergencyRequest;

  /// No description provided for @emergencyGuest.
  ///
  /// In en, this message translates to:
  /// **'Emergency Guest'**
  String get emergencyGuest;

  /// No description provided for @patientIdDisplay.
  ///
  /// In en, this message translates to:
  /// **'Patient Â·Â·Â·{id}'**
  String patientIdDisplay(Object id);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get view;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @totalClinicalRevenue.
  ///
  /// In en, this message translates to:
  /// **'TOTAL CLINICAL REVENUE'**
  String get totalClinicalRevenue;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY'**
  String get monthly;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE METRICS'**
  String get performanceMetrics;

  /// No description provided for @clinicalWorkflow.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL WORKFLOW'**
  String get clinicalWorkflow;

  /// No description provided for @upcomingSessions.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING SESSIONS'**
  String get upcomingSessions;

  /// No description provided for @totalPatients.
  ///
  /// In en, this message translates to:
  /// **'Total Patients'**
  String get totalPatients;

  /// No description provided for @todaySessions.
  ///
  /// In en, this message translates to:
  /// **'Today Sessions'**
  String get todaySessions;

  /// No description provided for @clinicalRating.
  ///
  /// In en, this message translates to:
  /// **'Clinical Rating'**
  String get clinicalRating;

  /// No description provided for @avgSession.
  ///
  /// In en, this message translates to:
  /// **'Avg. Session'**
  String get avgSession;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get followUp;

  /// No description provided for @prescribe.
  ///
  /// In en, this message translates to:
  /// **'Prescribe'**
  String get prescribe;

  /// No description provided for @compliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get compliance;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @noUpcomingSessions.
  ///
  /// In en, this message translates to:
  /// **'No upcoming sessions.'**
  String get noUpcomingSessions;

  /// No description provided for @consultation.
  ///
  /// In en, this message translates to:
  /// **'CONSULTATION'**
  String get consultation;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get confirmed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pending;

  /// No description provided for @scheduleNavigation.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE NAVIGATION'**
  String get scheduleNavigation;

  /// No description provided for @clinicalOperations.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL OPERATIONS'**
  String get clinicalOperations;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get today;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get upcoming;

  /// No description provided for @pendingTab.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingTab;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'PAST'**
  String get past;

  /// No description provided for @noAppointmentsForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No appointments for this day'**
  String get noAppointmentsForThisDay;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'DAILY PROGRESS'**
  String get dailyProgress;

  /// No description provided for @pctCompleted.
  ///
  /// In en, this message translates to:
  /// **'{pct}% Completed'**
  String pctCompleted(Object pct);

  /// No description provided for @keepGoingMoreSessions.
  ///
  /// In en, this message translates to:
  /// **'Keep going! You have {remaining} more clinical sessions today.'**
  String keepGoingMoreSessions(Object remaining);

  /// No description provided for @allSessionsCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'All sessions completed for today!'**
  String get allSessionsCompletedToday;

  /// No description provided for @patientCancelledEmergency.
  ///
  /// In en, this message translates to:
  /// **'Patient has cancelled this emergency request.'**
  String get patientCancelledEmergency;

  /// No description provided for @timeRemainingToRespond.
  ///
  /// In en, this message translates to:
  /// **'Time remaining to respond'**
  String get timeRemainingToRespond;

  /// No description provided for @minuteEmergencyConsultation.
  ///
  /// In en, this message translates to:
  /// **'{minutes}-minute emergency consultation'**
  String minuteEmergencyConsultation(Object minutes);

  /// No description provided for @ifYouAcceptPatientWillProceed.
  ///
  /// In en, this message translates to:
  /// **'If you accept, the patient will proceed with payment and you will be connected immediately.'**
  String get ifYouAcceptPatientWillProceed;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @acceptEmergency.
  ///
  /// In en, this message translates to:
  /// **'Accept Emergency'**
  String get acceptEmergency;

  /// No description provided for @emergencyRequestAcceptedProceedPayment.
  ///
  /// In en, this message translates to:
  /// **'Emergency request accepted. Patient will proceed with payment.'**
  String get emergencyRequestAcceptedProceedPayment;

  /// No description provided for @doctorMenu.
  ///
  /// In en, this message translates to:
  /// **'Doctor Menu'**
  String get doctorMenu;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @paymentApprovals.
  ///
  /// In en, this message translates to:
  /// **'Payment Approvals'**
  String get paymentApprovals;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @completeVerificationToAccessFinancial.
  ///
  /// In en, this message translates to:
  /// **'Complete verification to access financial hub'**
  String get completeVerificationToAccessFinancial;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatients;

  /// No description provided for @failedToLoadPatients.
  ///
  /// In en, this message translates to:
  /// **'Failed to load patients'**
  String get failedToLoadPatients;

  /// No description provided for @noPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No patients yet'**
  String get noPatientsYet;

  /// No description provided for @patientsWhoBookWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Patients who book consultations with you\nwill appear here.'**
  String get patientsWhoBookWillAppear;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @noPendingPayments.
  ///
  /// In en, this message translates to:
  /// **'No pending payments'**
  String get noPendingPayments;

  /// No description provided for @paymentsSentWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Payments sent to you will appear here.'**
  String get paymentsSentWillAppearHere;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @earningsAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Analytics'**
  String get earningsAndAnalytics;

  /// No description provided for @dateRangeFilteringBeingDeveloped.
  ///
  /// In en, this message translates to:
  /// **'Date range filtering is being developed. Currently showing all-time earnings.'**
  String get dateRangeFilteringBeingDeveloped;

  /// No description provided for @trackEarningsPerformance.
  ///
  /// In en, this message translates to:
  /// **'Track your earnings and performance\nall in one place.'**
  String get trackEarningsPerformance;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @vsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get vsLastWeek;

  /// No description provided for @consultations.
  ///
  /// In en, this message translates to:
  /// **'Consultations'**
  String get consultations;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @earningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsLabel;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingLabel;

  /// No description provided for @earningsOverview.
  ///
  /// In en, this message translates to:
  /// **'Earnings Overview'**
  String get earningsOverview;

  /// No description provided for @earningsNaira.
  ///
  /// In en, this message translates to:
  /// **'Earnings (â‚¦)'**
  String get earningsNaira;

  /// No description provided for @earningsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Earnings Breakdown'**
  String get earningsBreakdown;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @detailedBreakdownBeingDeveloped.
  ///
  /// In en, this message translates to:
  /// **'Detailed breakdown is being developed. The summary above shows your current earnings overview.'**
  String get detailedBreakdownBeingDeveloped;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @greatProgress.
  ///
  /// In en, this message translates to:
  /// **'Great progress!'**
  String get greatProgress;

  /// No description provided for @greatProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'re making great progress.\nKeep up the excellent work!'**
  String get greatProgressDescription;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get patientDetails;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @blockPatient.
  ///
  /// In en, this message translates to:
  /// **'Block Patient'**
  String get blockPatient;

  /// No description provided for @areYouSureBlockPatient.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this patient? They won\'t be able to book consultations with you.'**
  String get areYouSureBlockPatient;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @patientBlocked.
  ///
  /// In en, this message translates to:
  /// **'Patient blocked'**
  String get patientBlocked;

  /// No description provided for @failedToBlock.
  ///
  /// In en, this message translates to:
  /// **'Failed to block: {error}'**
  String failedToBlock(Object error);

  /// No description provided for @privacyProtected.
  ///
  /// In en, this message translates to:
  /// **'Privacy Protected'**
  String get privacyProtected;

  /// No description provided for @patientIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient ID: {id}...'**
  String patientIdLabel(Object id);

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overview;

  /// No description provided for @consultationsTab.
  ///
  /// In en, this message translates to:
  /// **'CONSULTATIONS'**
  String get consultationsTab;

  /// No description provided for @appointmentSummary.
  ///
  /// In en, this message translates to:
  /// **'Appointment Summary'**
  String get appointmentSummary;

  /// No description provided for @couldNotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get couldNotLoadData;

  /// No description provided for @totalAppointments.
  ///
  /// In en, this message translates to:
  /// **'Total Appointments'**
  String get totalAppointments;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabel;

  /// No description provided for @noConsultationsYet.
  ///
  /// In en, this message translates to:
  /// **'No consultations yet'**
  String get noConsultationsYet;

  /// No description provided for @couldNotLoadConsultations.
  ///
  /// In en, this message translates to:
  /// **'Could not load consultations'**
  String get couldNotLoadConsultations;

  /// No description provided for @noSharedRecords.
  ///
  /// In en, this message translates to:
  /// **'No shared records'**
  String get noSharedRecords;

  /// No description provided for @recordsSharedWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Records shared by the patient will appear here.'**
  String get recordsSharedWillAppearHere;

  /// No description provided for @couldNotLoadRecords.
  ///
  /// In en, this message translates to:
  /// **'Could not load records'**
  String get couldNotLoadRecords;

  /// No description provided for @openingRecord.
  ///
  /// In en, this message translates to:
  /// **'Opening record...'**
  String get openingRecord;

  /// No description provided for @doctorAvailabilityAndSchedule.
  ///
  /// In en, this message translates to:
  /// **'Doctor Availability & Schedule'**
  String get doctorAvailabilityAndSchedule;

  /// No description provided for @manageWorkingHoursPreferences.
  ///
  /// In en, this message translates to:
  /// **'Manage your working hours, availability and preferences'**
  String get manageWorkingHoursPreferences;

  /// No description provided for @availabilityStatus.
  ///
  /// In en, this message translates to:
  /// **'Availability Status'**
  String get availabilityStatus;

  /// No description provided for @availableLabel2.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel2;

  /// No description provided for @youAreOpenForBookings.
  ///
  /// In en, this message translates to:
  /// **'You are open for bookings'**
  String get youAreOpenForBookings;

  /// No description provided for @vacationMode.
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode'**
  String get vacationMode;

  /// No description provided for @turnOnToPauseBookings.
  ///
  /// In en, this message translates to:
  /// **'Turn on to pause bookings'**
  String get turnOnToPauseBookings;

  /// No description provided for @emergencyAvailability.
  ///
  /// In en, this message translates to:
  /// **'Emergency Availability'**
  String get emergencyAvailability;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// No description provided for @weeklyWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly Working Hours'**
  String get weeklyWorkingHours;

  /// No description provided for @copyToAll.
  ///
  /// In en, this message translates to:
  /// **'Copy to all'**
  String get copyToAll;

  /// No description provided for @breakTimesDaily.
  ///
  /// In en, this message translates to:
  /// **'Break Times (Daily)'**
  String get breakTimesDaily;

  /// No description provided for @addBreak.
  ///
  /// In en, this message translates to:
  /// **'Add Break'**
  String get addBreak;

  /// No description provided for @allowEmergencyBookingsOutside.
  ///
  /// In en, this message translates to:
  /// **'Allow emergency bookings outside regular hours'**
  String get allowEmergencyBookingsOutside;

  /// No description provided for @emergencyRate5xNormal.
  ///
  /// In en, this message translates to:
  /// **'Emergency rate: 5x normal rate'**
  String get emergencyRate5xNormal;

  /// No description provided for @autoAcceptBookings.
  ///
  /// In en, this message translates to:
  /// **'Auto-Accept Bookings'**
  String get autoAcceptBookings;

  /// No description provided for @autoAcceptDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically accept new bookings within your working hours'**
  String get autoAcceptDescription;

  /// No description provided for @notifiedOfAllNewBookings.
  ///
  /// In en, this message translates to:
  /// **'You will be notified of all new bookings'**
  String get notifiedOfAllNewBookings;

  /// No description provided for @saveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save Schedule'**
  String get saveSchedule;

  /// No description provided for @emergencyAvailabilityEnabled.
  ///
  /// In en, this message translates to:
  /// **'Emergency availability enabled. Patients can now book emergency consultations.'**
  String get emergencyAvailabilityEnabled;

  /// No description provided for @emergencyAvailabilityDisabled.
  ///
  /// In en, this message translates to:
  /// **'Emergency availability disabled. You will no longer receive emergency consultation requests.'**
  String get emergencyAvailabilityDisabled;

  /// No description provided for @subscriptionManagement.
  ///
  /// In en, this message translates to:
  /// **'Subscription Management'**
  String get subscriptionManagement;

  /// No description provided for @managePlanBillingBenefits.
  ///
  /// In en, this message translates to:
  /// **'Manage your plan, billing and benefits'**
  String get managePlanBillingBenefits;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get premiumPlan;

  /// No description provided for @allInOnePremiumHealthcare.
  ///
  /// In en, this message translates to:
  /// **'All-in-one access to premium\nhealthcare features.'**
  String get allInOnePremiumHealthcare;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'â‚¦15,000 / month'**
  String get pricePerMonth;

  /// No description provided for @nextBillingDate.
  ///
  /// In en, this message translates to:
  /// **'Next billing date: 15 June 2025'**
  String get nextBillingDate;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @secureHealthData.
  ///
  /// In en, this message translates to:
  /// **'Secure Health Data'**
  String get secureHealthData;

  /// No description provided for @exclusiveDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Discounts'**
  String get exclusiveDiscounts;

  /// No description provided for @billingAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Billing & Payment'**
  String get billingAndPayment;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @billingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing Cycle'**
  String get billingCycle;

  /// No description provided for @monthly2.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly2;

  /// No description provided for @default2.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get default2;

  /// No description provided for @yourPlanUsage.
  ///
  /// In en, this message translates to:
  /// **'Your Plan Usage'**
  String get yourPlanUsage;

  /// No description provided for @resetsOn15June2025.
  ///
  /// In en, this message translates to:
  /// **'Resets on 15 June 2025'**
  String get resetsOn15June2025;

  /// No description provided for @videoConsults.
  ///
  /// In en, this message translates to:
  /// **'Video Consults'**
  String get videoConsults;

  /// No description provided for @chatConsults.
  ///
  /// In en, this message translates to:
  /// **'Chat Consults'**
  String get chatConsults;

  /// No description provided for @healthRecords.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get healthRecords;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @getMoreBenefitsFeatures.
  ///
  /// In en, this message translates to:
  /// **'Get more benefits and features'**
  String get getMoreBenefitsFeatures;

  /// No description provided for @pauseYourPlanForAWhile.
  ///
  /// In en, this message translates to:
  /// **'Pause your plan for a while'**
  String get pauseYourPlanForAWhile;

  /// No description provided for @areYouSurePauseSubscription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to pause your subscription? You won\'t be charged during the pause period.'**
  String get areYouSurePauseSubscription;

  /// No description provided for @areYouSureCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel? You\'ll lose access to premium features at the end of your billing period.'**
  String get areYouSureCancelSubscription;

  /// No description provided for @supportTeamHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here to help you.'**
  String get supportTeamHereToHelp;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact Admin'**
  String get contactAdmin;

  /// No description provided for @choosePlanWorksBest.
  ///
  /// In en, this message translates to:
  /// **'Choose the plan that works best for you\nand manage your subscription.'**
  String get choosePlanWorksBest;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a Plan'**
  String get choosePlan;

  /// No description provided for @secureAndHassleFree.
  ///
  /// In en, this message translates to:
  /// **'Secure & Hassle-free'**
  String get secureAndHassleFree;

  /// No description provided for @paymentEncryptedDataProtected.
  ///
  /// In en, this message translates to:
  /// **'Your payment is encrypted and your data is always protected.'**
  String get paymentEncryptedDataProtected;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @currentPlan2.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan2;

  /// No description provided for @choosePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlanButton;

  /// No description provided for @planSelectedContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Plan selected! Contact support@premoncare.com to complete your upgrade.'**
  String get planSelectedContactSupport;

  /// No description provided for @proposeFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Propose Follow-up'**
  String get proposeFollowUp;

  /// No description provided for @patientRetentionAndCare.
  ///
  /// In en, this message translates to:
  /// **'Patient Retention & Care'**
  String get patientRetentionAndCare;

  /// No description provided for @selectPatient.
  ///
  /// In en, this message translates to:
  /// **'Select Patient'**
  String get selectPatient;

  /// No description provided for @sarahJohnsonToday.
  ///
  /// In en, this message translates to:
  /// **'Sarah Johnson (Today)'**
  String get sarahJohnsonToday;

  /// No description provided for @proposedDate.
  ///
  /// In en, this message translates to:
  /// **'Proposed Date'**
  String get proposedDate;

  /// No description provided for @preferredTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred Time'**
  String get preferredTime;

  /// No description provided for @clinicalReasonInstructions.
  ///
  /// In en, this message translates to:
  /// **'Clinical Reason / Instructions'**
  String get clinicalReasonInstructions;

  /// No description provided for @sendProposalToPatient.
  ///
  /// In en, this message translates to:
  /// **'SEND PROPOSAL TO PATIENT'**
  String get sendProposalToPatient;

  /// No description provided for @patientWillBeNotified.
  ///
  /// In en, this message translates to:
  /// **'* Patient will be notified to confirm and pay.'**
  String get patientWillBeNotified;

  /// No description provided for @pleaseProvideClinicalReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a clinical reason'**
  String get pleaseProvideClinicalReason;

  /// No description provided for @followUpProposalSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Follow-up proposal sent successfully'**
  String get followUpProposalSentSuccessfully;

  /// No description provided for @howWasConsultationExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your consultation experience?'**
  String get howWasConsultationExperience;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @thankYouForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouForFeedback;

  /// No description provided for @aboutPremonCareTitle.
  ///
  /// In en, this message translates to:
  /// **'About Premon Care'**
  String get aboutPremonCareTitle;

  /// No description provided for @builtWith.
  ///
  /// In en, this message translates to:
  /// **'Built With'**
  String get builtWith;

  /// No description provided for @builtWithDescription.
  ///
  /// In en, this message translates to:
  /// **'Flutter, Supabase, Firebase'**
  String get builtWithDescription;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @ourMissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To make quality healthcare accessible to everyone, everywhere through technology.'**
  String get ourMissionDescription;

  /// No description provided for @websiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websiteLabel;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// No description provided for @madeWithCareInNigeria.
  ///
  /// In en, this message translates to:
  /// **'Made with care in Nigeria'**
  String get madeWithCareInNigeria;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Premoncare is a telemedicine platform connecting patients with licensed healthcare providers across Nigeria and Africa.'**
  String get aboutDescription;

  /// No description provided for @textSizeSection.
  ///
  /// In en, this message translates to:
  /// **'TEXT SIZE'**
  String get textSizeSection;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @previewDescription.
  ///
  /// In en, this message translates to:
  /// **'This is how text will appear.'**
  String get previewDescription;

  /// No description provided for @displaySection.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY'**
  String get displaySection;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High Contrast'**
  String get highContrast;

  /// No description provided for @highContrastDescription.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast for better visibility'**
  String get highContrastDescription;

  /// No description provided for @reduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Reduce Animations'**
  String get reduceAnimations;

  /// No description provided for @reduceAnimationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Minimize motion effects'**
  String get reduceAnimationsDescription;

  /// No description provided for @screenReaderHints.
  ///
  /// In en, this message translates to:
  /// **'Screen Reader Hints'**
  String get screenReaderHints;

  /// No description provided for @screenReaderHintsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add extra labels for screen readers'**
  String get screenReaderHintsDescription;

  /// No description provided for @themeSection.
  ///
  /// In en, this message translates to:
  /// **'THEME'**
  String get themeSection;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @lightModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get lightModeDescription;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get darkModeDescription;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @systemDefaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Match your device settings'**
  String get systemDefaultDescription;

  /// No description provided for @darkModeRefinementNotice.
  ///
  /// In en, this message translates to:
  /// **'Dark mode is being refined. Some screens may still appear in light mode until fully migrated.'**
  String get darkModeRefinementNotice;

  /// No description provided for @securitySection.
  ///
  /// In en, this message translates to:
  /// **'SECURITY'**
  String get securitySection;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLock;

  /// No description provided for @biometricLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Require fingerprint or face to open app'**
  String get biometricLockDescription;

  /// No description provided for @biometricsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics not available on this device'**
  String get biometricsNotAvailable;

  /// No description provided for @visibilitySection.
  ///
  /// In en, this message translates to:
  /// **'VISIBILITY'**
  String get visibilitySection;

  /// No description provided for @profileVisibility.
  ///
  /// In en, this message translates to:
  /// **'Profile Visibility'**
  String get profileVisibility;

  /// No description provided for @profileVisibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow doctors to see your profile'**
  String get profileVisibilityDescription;

  /// No description provided for @onlineStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Online Status'**
  String get onlineStatusSection;

  /// No description provided for @onlineStatusDescription.
  ///
  /// In en, this message translates to:
  /// **'Show when you are online'**
  String get onlineStatusDescription;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get dataSection;

  /// No description provided for @researchDataSharing.
  ///
  /// In en, this message translates to:
  /// **'Research Data Sharing'**
  String get researchDataSharing;

  /// No description provided for @researchDataSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Share anonymized data for medical research'**
  String get researchDataSharingDescription;

  /// No description provided for @crashReporting.
  ///
  /// In en, this message translates to:
  /// **'Crash Reporting'**
  String get crashReporting;

  /// No description provided for @crashReportingDescription.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app by sending crash reports'**
  String get crashReportingDescription;

  /// No description provided for @activeSessionsSection.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE SESSIONS'**
  String get activeSessionsSection;

  /// No description provided for @securityTipsSection.
  ///
  /// In en, this message translates to:
  /// **'SECURITY TIPS'**
  String get securityTipsSection;

  /// No description provided for @securityTipsDescription.
  ///
  /// In en, this message translates to:
  /// **'If you see a session you don\'t recognize, log out of all sessions immediately.'**
  String get securityTipsDescription;

  /// No description provided for @logOutAllSessions.
  ///
  /// In en, this message translates to:
  /// **'Log Out of All Sessions'**
  String get logOutAllSessions;

  /// No description provided for @dataExportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Exported'**
  String get dataExportedTitle;

  /// No description provided for @dataExportedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your data has been copied to the clipboard as JSON. You can paste it into a secure document.'**
  String get dataExportedDescription;

  /// No description provided for @exportAgain.
  ///
  /// In en, this message translates to:
  /// **'Export Again'**
  String get exportAgain;

  /// No description provided for @exportYourDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Your Data'**
  String get exportYourDataTitle;

  /// No description provided for @exportDescription.
  ///
  /// In en, this message translates to:
  /// **'Get a copy of all your health data, consultation history, and account information.'**
  String get exportDescription;

  /// No description provided for @whatsIncludedSection.
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S INCLUDED'**
  String get whatsIncludedSection;

  /// No description provided for @appointmentHistory.
  ///
  /// In en, this message translates to:
  /// **'Appointment History'**
  String get appointmentHistory;

  /// No description provided for @messagesAndConsultations.
  ///
  /// In en, this message translates to:
  /// **'Messages & Consultations'**
  String get messagesAndConsultations;

  /// No description provided for @forumPostsAndReplies.
  ///
  /// In en, this message translates to:
  /// **'Forum Posts & Replies'**
  String get forumPostsAndReplies;

  /// No description provided for @exportMyDataButton.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportMyDataButton;

  /// No description provided for @measurementUnitsSection.
  ///
  /// In en, this message translates to:
  /// **'MEASUREMENT UNITS'**
  String get measurementUnitsSection;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLabel;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// No description provided for @formatSection.
  ///
  /// In en, this message translates to:
  /// **'FORMAT'**
  String get formatSection;

  /// No description provided for @dateFormatLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormatLabel;

  /// No description provided for @faqSection.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqSection;

  /// No description provided for @howDoIBookConsultation.
  ///
  /// In en, this message translates to:
  /// **'How do I book a consultation?'**
  String get howDoIBookConsultation;

  /// No description provided for @howDoIBookConsultationAnswer.
  ///
  /// In en, this message translates to:
  /// **'Navigate to the Search tab, find a doctor, select a time slot, and confirm your booking. Payment is handled via P2P receipt upload.'**
  String get howDoIBookConsultationAnswer;

  /// No description provided for @howDoIUploadPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'How do I upload a payment receipt?'**
  String get howDoIUploadPaymentReceipt;

  /// No description provided for @howDoIUploadPaymentReceiptAnswer.
  ///
  /// In en, this message translates to:
  /// **'After booking, go to Appointments > Pending > Upload Receipt. Take a photo of your bank transfer confirmation.'**
  String get howDoIUploadPaymentReceiptAnswer;

  /// No description provided for @howDoIBecomeVerifiedDoctor.
  ///
  /// In en, this message translates to:
  /// **'How do I become a verified doctor?'**
  String get howDoIBecomeVerifiedDoctor;

  /// No description provided for @howDoIBecomeVerifiedDoctorAnswer.
  ///
  /// In en, this message translates to:
  /// **'Register as a patient first, then go to Profile > Verification Wizard to submit your professional credentials.'**
  String get howDoIBecomeVerifiedDoctorAnswer;

  /// No description provided for @whatIsEmergencyCare.
  ///
  /// In en, this message translates to:
  /// **'What is Emergency Care?'**
  String get whatIsEmergencyCare;

  /// No description provided for @whatIsEmergencyCareAnswer.
  ///
  /// In en, this message translates to:
  /// **'Emergency Care connects you with available doctors immediately. The cost is 5x the doctor\'s standard rate.'**
  String get whatIsEmergencyCareAnswer;

  /// No description provided for @contactUsSection.
  ///
  /// In en, this message translates to:
  /// **'CONTACT US'**
  String get contactUsSection;

  /// No description provided for @emailSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupportLabel;

  /// No description provided for @phoneSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupportLabel;

  /// No description provided for @liveChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChatLabel;

  /// No description provided for @liveChatAvailability.
  ///
  /// In en, this message translates to:
  /// **'Available Mon-Fri, 9am-5pm WAT'**
  String get liveChatAvailability;

  /// No description provided for @liveChatNotice.
  ///
  /// In en, this message translates to:
  /// **'Live chat is available Monday–Friday, 9am–5pm WAT. Email support@premoncare.com for immediate assistance.'**
  String get liveChatNotice;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageSection;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguageLabel;

  /// No description provided for @regionSection.
  ///
  /// In en, this message translates to:
  /// **'REGION'**
  String get regionSection;

  /// No description provided for @regionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get regionLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSection;

  /// No description provided for @verifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedStatus;

  /// No description provided for @otpInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Premoncare uses email verification codes (OTP) for secure sign-in. No password is required.'**
  String get otpInfoDescription;

  /// No description provided for @noPermissionsGranted.
  ///
  /// In en, this message translates to:
  /// **'No permissions granted'**
  String get noPermissionsGranted;

  /// No description provided for @doctorsRequestAccess.
  ///
  /// In en, this message translates to:
  /// **'Doctors will request access to your medical records when needed.'**
  String get doctorsRequestAccess;

  /// No description provided for @revokeLabel.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeLabel;

  /// No description provided for @channelsSection.
  ///
  /// In en, this message translates to:
  /// **'CHANNELS'**
  String get channelsSection;

  /// No description provided for @pushNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsLabel;

  /// No description provided for @receiveAlertsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts on your device'**
  String get receiveAlertsOnDevice;

  /// No description provided for @emailNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotificationsLabel;

  /// No description provided for @receiveAlertsViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts via email'**
  String get receiveAlertsViaEmail;

  /// No description provided for @categoriesSection.
  ///
  /// In en, this message translates to:
  /// **'CATEGORIES'**
  String get categoriesSection;

  /// No description provided for @appointmentAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointment Alerts'**
  String get appointmentAlertsLabel;

  /// No description provided for @remindersForConsultations.
  ///
  /// In en, this message translates to:
  /// **'Reminders for upcoming consultations'**
  String get remindersForConsultations;

  /// No description provided for @paymentAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Alerts'**
  String get paymentAlertsLabel;

  /// No description provided for @transactionConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Transaction confirmations and receipts'**
  String get transactionConfirmations;

  /// No description provided for @clinicalUpdatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinical Updates'**
  String get clinicalUpdatesLabel;

  /// No description provided for @prescriptionUpdatesAndRecords.
  ///
  /// In en, this message translates to:
  /// **'Prescription updates and health records'**
  String get prescriptionUpdatesAndRecords;

  /// No description provided for @forumUpdatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Forum Updates'**
  String get forumUpdatesLabel;

  /// No description provided for @repliesAndMentions.
  ///
  /// In en, this message translates to:
  /// **'Replies and mentions in the community'**
  String get repliesAndMentions;

  /// No description provided for @emergencyAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alerts'**
  String get emergencyAlertsLabel;

  /// No description provided for @criticalEmergencyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Critical emergency notifications'**
  String get criticalEmergencyNotifications;

  /// No description provided for @marketingEmailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Marketing Emails'**
  String get marketingEmailsLabel;

  /// No description provided for @productUpdatesAndHealthTips.
  ///
  /// In en, this message translates to:
  /// **'Product updates and health tips'**
  String get productUpdatesAndHealthTips;

  /// No description provided for @changeProfilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhotoTitle;

  /// No description provided for @takePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhotoLabel;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @changePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhotoLabel;

  /// No description provided for @changeSelectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Change selection'**
  String get changeSelectionLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @emailAddressField.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressField;

  /// No description provided for @phoneNumberField.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberField;

  /// No description provided for @dateOfBirthField.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthField;

  /// No description provided for @genderField.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderField;

  /// No description provided for @addressField.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressField;

  /// No description provided for @bloodGroupField.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroupField;

  /// No description provided for @nextOfKinNameField.
  ///
  /// In en, this message translates to:
  /// **'Next of Kin Name'**
  String get nextOfKinNameField;

  /// No description provided for @nextOfKinPhoneField.
  ///
  /// In en, this message translates to:
  /// **'Next of Kin Phone'**
  String get nextOfKinPhoneField;

  /// No description provided for @emergencyContactNameField.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Name'**
  String get emergencyContactNameField;

  /// No description provided for @emergencyContactPhoneField.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Phone'**
  String get emergencyContactPhoneField;

  /// No description provided for @paymentInstructionsField.
  ///
  /// In en, this message translates to:
  /// **'Payment Instructions (Bank Details)'**
  String get paymentInstructionsField;

  /// No description provided for @emailNotificationsField.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotificationsField;

  /// No description provided for @emailNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive updates for payments and account status'**
  String get emailNotificationsDescription;

  /// No description provided for @identityVerificationField.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerificationField;

  /// No description provided for @idUploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'ID uploaded'**
  String get idUploadedLabel;

  /// No description provided for @selectGenderTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGenderTitle;

  /// No description provided for @privacyPolicyScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyScreenTitle;

  /// No description provided for @lastUpdatedJune2026.
  ///
  /// In en, this message translates to:
  /// **'Last updated: June 2026'**
  String get lastUpdatedJune2026;

  /// No description provided for @accountSettingsHeader.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettingsHeader;

  /// No description provided for @privacyAndDataHeader.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyAndDataHeader;

  /// No description provided for @preferencesHeader.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesHeader;

  /// No description provided for @supportAndLegalHeader.
  ///
  /// In en, this message translates to:
  /// **'Support & Legal'**
  String get supportAndLegalHeader;

  /// No description provided for @manageYourAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and preferences'**
  String get manageYourAccountSubtitle;

  /// No description provided for @personalInformationTile.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationTile;

  /// No description provided for @updateYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your details'**
  String get updateYourDetails;

  /// No description provided for @loginAndSecurityTile.
  ///
  /// In en, this message translates to:
  /// **'Login & Security'**
  String get loginAndSecurityTile;

  /// No description provided for @passwordAndSecuritySettings.
  ///
  /// In en, this message translates to:
  /// **'Password and security settings'**
  String get passwordAndSecuritySettings;

  /// No description provided for @notificationPreferencesTile.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferencesTile;

  /// No description provided for @chooseNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what notifications to receive'**
  String get chooseNotificationsSubtitle;

  /// No description provided for @languageAndRegionTile.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get languageAndRegionTile;

  /// No description provided for @languageAndRegionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language and region'**
  String get languageAndRegionSubtitle;

  /// No description provided for @biometricAndPrivacyTile.
  ///
  /// In en, this message translates to:
  /// **'Biometric & Privacy'**
  String get biometricAndPrivacyTile;

  /// No description provided for @privacyAndBiometricControls.
  ///
  /// In en, this message translates to:
  /// **'Privacy and biometric controls'**
  String get privacyAndBiometricControls;

  /// No description provided for @recordPermissionsTile.
  ///
  /// In en, this message translates to:
  /// **'Record Permissions'**
  String get recordPermissionsTile;

  /// No description provided for @manageDoctorAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage doctor record access'**
  String get manageDoctorAccess;

  /// No description provided for @deviceSessionsTile.
  ///
  /// In en, this message translates to:
  /// **'Device Sessions'**
  String get deviceSessionsTile;

  /// No description provided for @activeSessionsAndActivity.
  ///
  /// In en, this message translates to:
  /// **'Active sessions and activity'**
  String get activeSessionsAndActivity;

  /// No description provided for @downloadMyDataTile.
  ///
  /// In en, this message translates to:
  /// **'Download My Data'**
  String get downloadMyDataTile;

  /// No description provided for @exportYourHealthData.
  ///
  /// In en, this message translates to:
  /// **'Export your health data'**
  String get exportYourHealthData;

  /// No description provided for @deleteAccountTile.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTile;

  /// No description provided for @permanentlyDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteAccount;

  /// No description provided for @appearanceTile.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTile;

  /// No description provided for @chooseLightOrDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Choose light or dark mode'**
  String get chooseLightOrDarkMode;

  /// No description provided for @accessibilityTile.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilityTile;

  /// No description provided for @textSizeAndDisplayOptions.
  ///
  /// In en, this message translates to:
  /// **'Text size and display options'**
  String get textSizeAndDisplayOptions;

  /// No description provided for @healthPreferencesTile.
  ///
  /// In en, this message translates to:
  /// **'Health Preferences'**
  String get healthPreferencesTile;

  /// No description provided for @unitsAndHealthSettings.
  ///
  /// In en, this message translates to:
  /// **'Units and health settings'**
  String get unitsAndHealthSettings;

  /// No description provided for @helpSupportTile.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTile;

  /// No description provided for @faqsAndContactSupport.
  ///
  /// In en, this message translates to:
  /// **'FAQs and contact support'**
  String get faqsAndContactSupport;

  /// No description provided for @termsOfServiceTile.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTile;

  /// No description provided for @readOurTerms.
  ///
  /// In en, this message translates to:
  /// **'Read our terms'**
  String get readOurTerms;

  /// No description provided for @privacyPolicyTile.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTile;

  /// No description provided for @howWeProtectData.
  ///
  /// In en, this message translates to:
  /// **'How we protect your data'**
  String get howWeProtectData;

  /// No description provided for @aboutPremonCareTile.
  ///
  /// In en, this message translates to:
  /// **'About Premon Care'**
  String get aboutPremonCareTile;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version 2.4.1'**
  String get appVersionLabel;

  /// No description provided for @privacyIsPriority.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is our priority'**
  String get privacyIsPriority;

  /// No description provided for @industryStandardEncryption.
  ///
  /// In en, this message translates to:
  /// **'We use industry-standard encryption to protect your data.'**
  String get industryStandardEncryption;

  /// No description provided for @deleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountDialogTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'You are about to permanently delete your account. This action is irreversible and all data will be lost.'**
  String get deleteAccountWarning;

  /// No description provided for @willPermanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get willPermanentlyDelete;

  /// No description provided for @profileAndPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Your profile and personal information'**
  String get profileAndPersonalInfo;

  /// No description provided for @allAppointmentsHistory.
  ///
  /// In en, this message translates to:
  /// **'All appointments and consultation history'**
  String get allAppointmentsHistory;

  /// No description provided for @medicalRecordsAndDocuments.
  ///
  /// In en, this message translates to:
  /// **'Medical records and uploaded documents'**
  String get medicalRecordsAndDocuments;

  /// No description provided for @allMessagesAndChatHistory.
  ///
  /// In en, this message translates to:
  /// **'All messages and chat history'**
  String get allMessagesAndChatHistory;

  /// No description provided for @paymentRecordsAndHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment records and transaction history'**
  String get paymentRecordsAndHistory;

  /// No description provided for @reviewsAndRatingsGiven.
  ///
  /// In en, this message translates to:
  /// **'Reviews and ratings you\'ve given'**
  String get reviewsAndRatingsGiven;

  /// No description provided for @typeEmailToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type your email to confirm:'**
  String get typeEmailToConfirm;

  /// No description provided for @emailDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Email does not match'**
  String get emailDoesNotMatch;

  /// No description provided for @deleteMyAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccountButton;

  /// No description provided for @accountScheduledForDeletion.
  ///
  /// In en, this message translates to:
  /// **'Account scheduled for deletion in 30 days.'**
  String get accountScheduledForDeletion;

  /// No description provided for @termsOfServiceScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceScreenTitle;

  /// No description provided for @acceptanceOfTerms.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get acceptanceOfTerms;

  /// No description provided for @acceptanceOfTermsDescription.
  ///
  /// In en, this message translates to:
  /// **'By accessing and using Premon Care (\"the App\"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.'**
  String get acceptanceOfTermsDescription;

  /// No description provided for @descriptionOfService.
  ///
  /// In en, this message translates to:
  /// **'2. Description of Service'**
  String get descriptionOfService;

  /// No description provided for @descriptionOfServiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Premon Care is a telemedicine platform that connects patients with licensed healthcare providers for virtual consultations. We facilitate appointments, secure messaging, and medical record management.'**
  String get descriptionOfServiceDescription;

  /// No description provided for @userAccounts.
  ///
  /// In en, this message translates to:
  /// **'3. User Accounts'**
  String get userAccounts;

  /// No description provided for @userAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'You must register an account to use the App. You are responsible for maintaining the confidentiality of your account credentials. You must provide accurate and complete information during registration.'**
  String get userAccountsDescription;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'4. Medical Disclaimer'**
  String get medicalDisclaimer;

  /// No description provided for @medicalDisclaimerDescription.
  ///
  /// In en, this message translates to:
  /// **'Premon Care does not provide medical advice. The App facilitates communication between patients and licensed healthcare providers. All medical decisions are made solely by the treating physician.'**
  String get medicalDisclaimerDescription;

  /// No description provided for @paymentTermsSection.
  ///
  /// In en, this message translates to:
  /// **'5. Payment Terms'**
  String get paymentTermsSection;

  /// No description provided for @paymentTermsDescription.
  ///
  /// In en, this message translates to:
  /// **'Consultation fees are set by individual practitioners. Payment is processed through peer-to-peer transfers. Receipts must be uploaded for verification. Premon Care charges no additional platform fees for patients.'**
  String get paymentTermsDescription;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'6. Privacy'**
  String get privacySection;

  /// No description provided for @privacyDescription.
  ///
  /// In en, this message translates to:
  /// **'Your use of the App is also governed by our Privacy Policy. We are committed to protecting your personal and medical data in compliance with applicable data protection laws.'**
  String get privacyDescription;

  /// No description provided for @limitationOfLiability.
  ///
  /// In en, this message translates to:
  /// **'7. Limitation of Liability'**
  String get limitationOfLiability;

  /// No description provided for @limitationOfLiabilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Premon Care shall not be liable for any indirect, incidental, special, or consequential damages arising out of or in connection with your use of the App.'**
  String get limitationOfLiabilityDescription;

  /// No description provided for @changesToTerms.
  ///
  /// In en, this message translates to:
  /// **'8. Changes to Terms'**
  String get changesToTerms;

  /// No description provided for @changesToTermsDescription.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these terms at any time. Changes will be effective upon posting. Continued use of the App constitutes acceptance of modified terms.'**
  String get changesToTermsDescription;

  /// No description provided for @contactLegalForQuestions.
  ///
  /// In en, this message translates to:
  /// **'Contact us at legal@premoncare.com for questions about these terms.'**
  String get contactLegalForQuestions;

  /// No description provided for @clinicalSessionsHeader.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL SESSIONS'**
  String get clinicalSessionsHeader;

  /// No description provided for @upcomingTab.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTab;

  /// No description provided for @completedTab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTab;

  /// No description provided for @emptyUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your health schedule is clear'**
  String get emptyUpcomingTitle;

  /// No description provided for @emptyPastTitle.
  ///
  /// In en, this message translates to:
  /// **'No past history found'**
  String get emptyPastTitle;

  /// No description provided for @emptyUpcomingDescription.
  ///
  /// In en, this message translates to:
  /// **'Schedule a consultation with our verified specialists to begin your care journey.'**
  String get emptyUpcomingDescription;

  /// No description provided for @emptyPastDescription.
  ///
  /// In en, this message translates to:
  /// **'Your completed clinical records and summaries will appear here.'**
  String get emptyPastDescription;

  /// No description provided for @verifiedSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Verified Specialist'**
  String get verifiedSpecialist;

  /// No description provided for @confirmedStatus.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get confirmedStatus;

  /// No description provided for @scheduledStatus.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED'**
  String get scheduledStatus;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get cancelledStatus;

  /// No description provided for @ongoingStatus.
  ///
  /// In en, this message translates to:
  /// **'ONGOING'**
  String get ongoingStatus;

  /// No description provided for @emergencyStatus.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY'**
  String get emergencyStatus;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get acceptedStatus;

  /// No description provided for @declinedStatus.
  ///
  /// In en, this message translates to:
  /// **'DECLINED'**
  String get declinedStatus;

  /// No description provided for @rescheduledStatus.
  ///
  /// In en, this message translates to:
  /// **'RESCHEDULED'**
  String get rescheduledStatus;

  /// No description provided for @startsInLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts in '**
  String get startsInLabel;

  /// No description provided for @rescheduleButton.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get rescheduleButton;

  /// No description provided for @joinConsultationButton.
  ///
  /// In en, this message translates to:
  /// **'Join Consultation'**
  String get joinConsultationButton;

  /// No description provided for @viewSummaryButton.
  ///
  /// In en, this message translates to:
  /// **'View Summary'**
  String get viewSummaryButton;

  /// No description provided for @sessionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetailsTitle;

  /// No description provided for @sessionArchitectureTitle.
  ///
  /// In en, this message translates to:
  /// **'SESSION ARCHITECTURE'**
  String get sessionArchitectureTitle;

  /// No description provided for @clinicalActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL ACTIONS'**
  String get clinicalActionsTitle;

  /// No description provided for @sessionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'SESSION DATE'**
  String get sessionDateLabel;

  /// No description provided for @sessionTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'SESSION TIME'**
  String get sessionTimeLabel;

  /// No description provided for @durationTitle.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get durationTitle;

  /// No description provided for @consultationTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'CONSULTATION'**
  String get consultationTypeTitle;

  /// No description provided for @joinClinicalSessionButton.
  ///
  /// In en, this message translates to:
  /// **'JOIN CLINICAL SESSION'**
  String get joinClinicalSessionButton;

  /// No description provided for @rescheduleSessionButton.
  ///
  /// In en, this message translates to:
  /// **'RESCHEDULE SESSION'**
  String get rescheduleSessionButton;

  /// No description provided for @cancelSessionButton.
  ///
  /// In en, this message translates to:
  /// **'CANCEL SESSION'**
  String get cancelSessionButton;

  /// No description provided for @confirmRescheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reschedule'**
  String get confirmRescheduleTitle;

  /// No description provided for @rescheduleConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Reschedule this session to {date} at {time}? The other party will be notified.'**
  String rescheduleConfirmationMessage(Object date, Object time);

  /// No description provided for @keepSessionButton.
  ///
  /// In en, this message translates to:
  /// **'KEEP SESSION'**
  String get keepSessionButton;

  /// No description provided for @confirmCancelButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM CANCEL'**
  String get confirmCancelButton;

  /// No description provided for @confirmCancellationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellationTitle;

  /// No description provided for @cancelConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this session? This action is permanent and the specialist will be notified.'**
  String get cancelConfirmationMessage;

  /// No description provided for @connectingToConsultation.
  ///
  /// In en, this message translates to:
  /// **'Connecting to consultation...'**
  String get connectingToConsultation;

  /// No description provided for @settingUpSecureRoom.
  ///
  /// In en, this message translates to:
  /// **'Setting up your secure video room'**
  String get settingUpSecureRoom;

  /// No description provided for @endCallButton.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get endCallButton;

  /// No description provided for @unmuteButton.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteButton;

  /// No description provided for @muteButton.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteButton;

  /// No description provided for @cameraOffButton.
  ///
  /// In en, this message translates to:
  /// **'Camera Off'**
  String get cameraOffButton;

  /// No description provided for @cameraOnButton.
  ///
  /// In en, this message translates to:
  /// **'Camera On'**
  String get cameraOnButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @couldNotConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not connect'**
  String get couldNotConnectTitle;

  /// No description provided for @checkConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again'**
  String get checkConnectionRetry;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @goBackButton.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBackButton;

  /// No description provided for @unableToConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect\nright now'**
  String get unableToConnectTitle;

  /// No description provided for @reconnectingDescription.
  ///
  /// In en, this message translates to:
  /// **'Please hold on while we try to reconnect you\nto an available doctor.'**
  String get reconnectingDescription;

  /// No description provided for @highDemandTitle.
  ///
  /// In en, this message translates to:
  /// **'High demand right now'**
  String get highDemandTitle;

  /// No description provided for @heavyTrafficDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'re experiencing heavy traffic. You\'re in the queue and we\'ll connect you as soon as a doctor is available.'**
  String get heavyTrafficDescription;

  /// No description provided for @yourPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get yourPositionLabel;

  /// No description provided for @estimatedWaitLabel.
  ///
  /// In en, this message translates to:
  /// **'Est. wait: 2-3 min'**
  String get estimatedWaitLabel;

  /// No description provided for @stillTryingToConnect.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry, we\'re still trying to connect you.\nPlease keep this screen open.'**
  String get stillTryingToConnect;

  /// No description provided for @retryConnectionButton.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnectionButton;

  /// No description provided for @callEmergencyLineButton.
  ///
  /// In en, this message translates to:
  /// **'Call Emergency Line'**
  String get callEmergencyLineButton;

  /// No description provided for @speakToEmergencySupport.
  ///
  /// In en, this message translates to:
  /// **'Speak to our emergency support team'**
  String get speakToEmergencySupport;

  /// No description provided for @thisIsAnEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'This is an emergency?'**
  String get thisIsAnEmergencyTitle;

  /// No description provided for @criticalConditionCall911.
  ///
  /// In en, this message translates to:
  /// **'If your condition is critical, please call your local emergency service immediately.'**
  String get criticalConditionCall911;

  /// No description provided for @needHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelpTitle;

  /// No description provided for @supportAvailable247.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here for you 24/7.'**
  String get supportAvailable247;

  /// No description provided for @chatWithSupportButton.
  ///
  /// In en, this message translates to:
  /// **'Chat with Support'**
  String get chatWithSupportButton;

  /// No description provided for @infoSafeWithUs.
  ///
  /// In en, this message translates to:
  /// **'Your info is safe with us'**
  String get infoSafeWithUs;

  /// No description provided for @callsAndDataSecure.
  ///
  /// In en, this message translates to:
  /// **'All calls and data are secure and encrypted.'**
  String get callsAndDataSecure;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @errorLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorLabelShort;

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String unreadCount(Object count);

  /// No description provided for @markAllReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllReadButton;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see appointment, payment and clinical updates here.'**
  String get notificationsEmptyDescription;

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Account Menu'**
  String get accountMenu;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// No description provided for @exploreLabel.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreLabel;

  /// No description provided for @appointmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointmentsLabel;

  /// No description provided for @communityLabel.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityLabel;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @apptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Appts'**
  String get apptsLabel;

  /// No description provided for @reportsLabelNew.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsLabelNew;

  /// No description provided for @reviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get reviewing;

  /// No description provided for @registerLabel.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerLabel;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get perHour;

  /// No description provided for @noBankDetailsProvided.
  ///
  /// In en, this message translates to:
  /// **'No bank details provided. Please request payment details from the doctor via chat before transferring.'**
  String get noBankDetailsProvided;

  /// No description provided for @paymentInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Instructions'**
  String get paymentInstructionsLabel;

  /// No description provided for @defaultPatientName.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get defaultPatientName;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @minsUnit.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get minsUnit;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(Object error);

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @medicalSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Medical Specialist'**
  String get medicalSpecialist;

  /// No description provided for @sessionDetailsHeader.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetailsHeader;

  /// No description provided for @sessionArchitecture.
  ///
  /// In en, this message translates to:
  /// **'SESSION ARCHITECTURE'**
  String get sessionArchitecture;

  /// No description provided for @clinicalActionsHeader.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL ACTIONS'**
  String get clinicalActionsHeader;

  /// No description provided for @downloadSummaryButton.
  ///
  /// In en, this message translates to:
  /// **'Download Summary'**
  String get downloadSummaryButton;

  /// No description provided for @shareDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'Share Details'**
  String get shareDetailsButton;

  /// No description provided for @reportIssueButton.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssueButton;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get durationLabel;

  /// No description provided for @consultationLabel.
  ///
  /// In en, this message translates to:
  /// **'CONSULTATION'**
  String get consultationLabel;

  /// No description provided for @rescheduleSessionTo.
  ///
  /// In en, this message translates to:
  /// **'Reschedule this session to {date} at {time}? The other party will be notified.'**
  String rescheduleSessionTo(Object date, Object time);

  /// No description provided for @sessionRescheduledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Session rescheduled successfully'**
  String get sessionRescheduledSuccess;

  /// No description provided for @cancelSessionWarning.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this session? This action is permanent and the specialist will be notified.'**
  String get cancelSessionWarning;

  /// No description provided for @consultationDefault.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultationDefault;

  /// No description provided for @shareButtonShort.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButtonShort;

  /// No description provided for @retryButtonShort.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButtonShort;

  /// No description provided for @goBackButtonShort.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBackButtonShort;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyTitle;

  /// No description provided for @sosLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// No description provided for @emergencyLineLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency line: +234-XXX-XXXX'**
  String get emergencyLineLabel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationDefault.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDefault;

  /// No description provided for @justNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNowLabel;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(Object hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(Object days);

  /// No description provided for @dashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardLabel;

  /// No description provided for @patientsNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsNavLabel;

  /// No description provided for @doctorBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'DOCTOR'**
  String get doctorBadgeLabel;

  /// No description provided for @guestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestLabel;

  /// No description provided for @patientHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient (Hidden)'**
  String get patientHiddenLabel;

  /// No description provided for @searchButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButtonLabel;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLabel;

  /// No description provided for @couldNotLoadPatient.
  ///
  /// In en, this message translates to:
  /// **'Could not load patient'**
  String get couldNotLoadPatient;

  /// No description provided for @lunchBreak.
  ///
  /// In en, this message translates to:
  /// **'Lunch Break'**
  String get lunchBreak;

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// No description provided for @personalTime.
  ///
  /// In en, this message translates to:
  /// **'Personal Time'**
  String get personalTime;

  /// No description provided for @timeConnector.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get timeConnector;

  /// No description provided for @emergencyAcceptedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Request Accepted'**
  String get emergencyAcceptedNotificationTitle;

  /// No description provided for @emergencyDeclinedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Request Declined'**
  String get emergencyDeclinedNotificationTitle;

  /// No description provided for @emergencyAcceptedNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'{doctorName} has accepted your emergency consultation request. Please proceed with payment.'**
  String emergencyAcceptedNotificationMessage(Object doctorName);

  /// No description provided for @emergencyDeclinedNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, {doctorName} is unable to take your case right now.'**
  String emergencyDeclinedNotificationMessage(Object doctorName);

  /// No description provided for @askDoctorTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask a Doctor'**
  String get askDoctorTitle;

  /// No description provided for @askDoctorDescription.
  ///
  /// In en, this message translates to:
  /// **'Get answers from verified healthcare professionals.'**
  String get askDoctorDescription;

  /// No description provided for @needUrgentAdvice.
  ///
  /// In en, this message translates to:
  /// **'Need urgent advice?'**
  String get needUrgentAdvice;

  /// No description provided for @askVerifiedDoctor.
  ///
  /// In en, this message translates to:
  /// **'Ask a verified doctor and receive professional responses.'**
  String get askVerifiedDoctor;

  /// No description provided for @askQuestionButton.
  ///
  /// In en, this message translates to:
  /// **'Ask Question'**
  String get askQuestionButton;

  /// No description provided for @noQuestionsForDoctorsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions for doctors yet'**
  String get noQuestionsForDoctorsYet;

  /// No description provided for @forumDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Forum responses are for educational purposes and do not replace professional consultations.'**
  String get forumDisclaimer;

  /// No description provided for @categoryHeartHealth.
  ///
  /// In en, this message translates to:
  /// **'Heart Health'**
  String get categoryHeartHealth;

  /// No description provided for @categoryMentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get categoryMentalHealth;

  /// No description provided for @categoryNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get categoryNutrition;

  /// No description provided for @categoryPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy'**
  String get categoryPregnancy;

  /// No description provided for @categoryGeneralHealth.
  ///
  /// In en, this message translates to:
  /// **'General Health'**
  String get categoryGeneralHealth;

  /// No description provided for @repliesCountLower.
  ///
  /// In en, this message translates to:
  /// **'replies'**
  String get repliesCountLower;

  /// No description provided for @likesCountLower.
  ///
  /// In en, this message translates to:
  /// **'likes'**
  String get likesCountLower;

  /// No description provided for @createPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPostTitle;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @createAPost.
  ///
  /// In en, this message translates to:
  /// **'Create a Post'**
  String get createAPost;

  /// No description provided for @createPostDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask a question, share your experience or start a discussion.'**
  String get createPostDescription;

  /// No description provided for @selectCategoryStep.
  ///
  /// In en, this message translates to:
  /// **'1. Select Category'**
  String get selectCategoryStep;

  /// No description provided for @postTitleStep.
  ///
  /// In en, this message translates to:
  /// **'2. Post Title'**
  String get postTitleStep;

  /// No description provided for @describeQuestionStep.
  ///
  /// In en, this message translates to:
  /// **'3. Describe Your Question or Topic'**
  String get describeQuestionStep;

  /// No description provided for @addAttachmentsStep.
  ///
  /// In en, this message translates to:
  /// **'4. Add Attachments'**
  String get addAttachmentsStep;

  /// No description provided for @optionalParen.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optionalParen;

  /// No description provided for @tipMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Tip: The more details you provide, the better and more helpful the responses you\'ll receive.'**
  String get tipMoreDetails;

  /// No description provided for @uploadImagesOrDocuments.
  ///
  /// In en, this message translates to:
  /// **'You can upload images or documents to provide more context.'**
  String get uploadImagesOrDocuments;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @addLabResult.
  ///
  /// In en, this message translates to:
  /// **'Add Lab Result'**
  String get addLabResult;

  /// No description provided for @addOther.
  ///
  /// In en, this message translates to:
  /// **'Add Other'**
  String get addOther;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: JPG, PNG, PDF, DOC â€¢ Max size: 10MB per file'**
  String get supportedFormats;

  /// No description provided for @postAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Post Anonymously'**
  String get postAnonymously;

  /// No description provided for @nameHiddenFromMembers.
  ///
  /// In en, this message translates to:
  /// **'Your name will be hidden from other members.'**
  String get nameHiddenFromMembers;

  /// No description provided for @postQuestionButton.
  ///
  /// In en, this message translates to:
  /// **'Post Question'**
  String get postQuestionButton;

  /// No description provided for @failedToPostError.
  ///
  /// In en, this message translates to:
  /// **'Failed to post: {error}'**
  String failedToPostError(Object error);

  /// No description provided for @communityForum.
  ///
  /// In en, this message translates to:
  /// **'Community Forum'**
  String get communityForum;

  /// No description provided for @askShareLearn.
  ///
  /// In en, this message translates to:
  /// **'Ask questions, share experiences and learn from others'**
  String get askShareLearn;

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortByLabel;

  /// No description provided for @latestLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestLabel;

  /// No description provided for @mostAnsweredLabel.
  ///
  /// In en, this message translates to:
  /// **'Most Answered'**
  String get mostAnsweredLabel;

  /// No description provided for @mostLikedLabel.
  ///
  /// In en, this message translates to:
  /// **'Most Liked'**
  String get mostLikedLabel;

  /// No description provided for @latestDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Latest Discussions'**
  String get latestDiscussions;

  /// No description provided for @trendingDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Trending Discussions'**
  String get trendingDiscussions;

  /// No description provided for @trendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trendingLabel;

  /// No description provided for @popularLabel.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularLabel;

  /// No description provided for @allTopics.
  ///
  /// In en, this message translates to:
  /// **'All Topics'**
  String get allTopics;

  /// No description provided for @failedToLoadCategoriesError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories: {error}'**
  String failedToLoadCategoriesError(Object error);

  /// No description provided for @askAQuestionFAB.
  ///
  /// In en, this message translates to:
  /// **'Ask a Question'**
  String get askAQuestionFAB;

  /// No description provided for @myActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'My Activity'**
  String get myActivityTitle;

  /// No description provided for @myPostsTab.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPostsTab;

  /// No description provided for @savedTab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTab;

  /// No description provided for @followingTab.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingTab;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @yourPostsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your posts will appear here'**
  String get yourPostsWillAppearHere;

  /// No description provided for @noSavedPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved posts'**
  String get noSavedPostsTitle;

  /// No description provided for @postsYouSaveWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Posts you save will appear here'**
  String get postsYouSaveWillAppearHere;

  /// No description provided for @notFollowingAnything.
  ///
  /// In en, this message translates to:
  /// **'Not following anything'**
  String get notFollowingAnything;

  /// No description provided for @postsYouFollowWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Posts you follow will appear here'**
  String get postsYouFollowWillAppearHere;

  /// No description provided for @notFollowingAnyPosts.
  ///
  /// In en, this message translates to:
  /// **'Not following any posts'**
  String get notFollowingAnyPosts;

  /// No description provided for @postDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Post Detail'**
  String get postDetailTitle;

  /// No description provided for @forumBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get forumBreadcrumb;

  /// No description provided for @postDetailsBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Post Details'**
  String get postDetailsBreadcrumb;

  /// No description provided for @doctorRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorRoleLabel;

  /// No description provided for @communityMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Community Member'**
  String get communityMemberLabel;

  /// No description provided for @postedInLabel.
  ///
  /// In en, this message translates to:
  /// **'â€¢ Posted in '**
  String get postedInLabel;

  /// No description provided for @viewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewsLabel;

  /// No description provided for @repliesLabel.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get repliesLabel;

  /// No description provided for @likesLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesLabel;

  /// No description provided for @followLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followLabel;

  /// No description provided for @topRepliesLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Replies'**
  String get topRepliesLabel;

  /// No description provided for @allRepliesLabel.
  ///
  /// In en, this message translates to:
  /// **'All Replies'**
  String get allRepliesLabel;

  /// No description provided for @doctorAnswersLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor Answers'**
  String get doctorAnswersLabel;

  /// No description provided for @verifiedDoctorBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified Doctor'**
  String get verifiedDoctorBadge;

  /// No description provided for @helpfulCount.
  ///
  /// In en, this message translates to:
  /// **'Helpful ({count})'**
  String helpfulCount(Object count);

  /// No description provided for @replyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyButtonLabel;

  /// No description provided for @writeReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get writeReplyHint;

  /// No description provided for @savedAndFollowedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved & Followed'**
  String get savedAndFollowedTitle;

  /// No description provided for @savedPostsTab.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get savedPostsTab;

  /// No description provided for @tapBookmarkToSave.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on any post to save it here'**
  String get tapBookmarkToSave;

  /// No description provided for @tapFollowToTrack.
  ///
  /// In en, this message translates to:
  /// **'Tap Follow on any post or category to track it here'**
  String get tapFollowToTrack;

  /// No description provided for @followedCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Followed Categories'**
  String get followedCategoriesLabel;

  /// No description provided for @followedPostsLabel.
  ///
  /// In en, this message translates to:
  /// **'Followed Posts'**
  String get followedPostsLabel;

  /// No description provided for @unfollowLabel.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollowLabel;

  /// No description provided for @sharedPatientRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared Patient Records'**
  String get sharedPatientRecordsTitle;

  /// No description provided for @noSharedRecordsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Shared Records'**
  String get noSharedRecordsEmptyTitle;

  /// No description provided for @patientsMustShareDesc.
  ///
  /// In en, this message translates to:
  /// **'Patients must explicitly share their vault documents with you for them to appear here.'**
  String get patientsMustShareDesc;

  /// No description provided for @viewRecordButton.
  ///
  /// In en, this message translates to:
  /// **'View Record'**
  String get viewRecordButton;

  /// No description provided for @secureMedicalStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'SECURE MEDICAL STORAGE'**
  String get secureMedicalStorageTitle;

  /// No description provided for @yourVaultIsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vault is empty'**
  String get yourVaultIsEmptyTitle;

  /// No description provided for @securelyStoreManageDesc.
  ///
  /// In en, this message translates to:
  /// **'Securely store and manage your clinical reports, prescriptions, and medical history in one encrypted location.'**
  String get securelyStoreManageDesc;

  /// No description provided for @uploadHealthRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Health Record'**
  String get uploadHealthRecordButton;

  /// No description provided for @scheduleConsultationButton.
  ///
  /// In en, this message translates to:
  /// **'Schedule Consultation'**
  String get scheduleConsultationButton;

  /// No description provided for @endToEndEncryptionTitle.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encryption'**
  String get endToEndEncryptionTitle;

  /// No description provided for @clinicalDataConfidentialDesc.
  ///
  /// In en, this message translates to:
  /// **'Your clinical data is strictly confidential and accessible only by you and your authorized specialists.'**
  String get clinicalDataConfidentialDesc;

  /// No description provided for @shareWithDoctorOption.
  ///
  /// In en, this message translates to:
  /// **'Share with Doctor'**
  String get shareWithDoctorOption;

  /// No description provided for @onlyAuthorizedDoctorsDesc.
  ///
  /// In en, this message translates to:
  /// **'Only authorized doctors can view and decrypt this record.'**
  String get onlyAuthorizedDoctorsDesc;

  /// No description provided for @secureVaultUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Vault Upload'**
  String get secureVaultUploadTitle;

  /// No description provided for @filesEncryptedBucketDesc.
  ///
  /// In en, this message translates to:
  /// **'Your files are stored in an encrypted private bucket.'**
  String get filesEncryptedBucketDesc;

  /// No description provided for @recordTitleField.
  ///
  /// In en, this message translates to:
  /// **'Record Title'**
  String get recordTitleField;

  /// No description provided for @recordCategoryField.
  ///
  /// In en, this message translates to:
  /// **'Record Category'**
  String get recordCategoryField;

  /// No description provided for @encryptAndUploadButton.
  ///
  /// In en, this message translates to:
  /// **'Encrypt & Upload to Vault'**
  String get encryptAndUploadButton;

  /// No description provided for @provideTitleAndFileError.
  ///
  /// In en, this message translates to:
  /// **'Please provide a title and select a file'**
  String get provideTitleAndFileError;

  /// No description provided for @fileSizeMustBeUnder5MB.
  ///
  /// In en, this message translates to:
  /// **'File size must be under 5MB'**
  String get fileSizeMustBeUnder5MB;

  /// No description provided for @selectPdfOrMedicalImage.
  ///
  /// In en, this message translates to:
  /// **'Select PDF or Medical Image'**
  String get selectPdfOrMedicalImage;

  /// No description provided for @encryptedTLS.
  ///
  /// In en, this message translates to:
  /// **'Encrypted TLS'**
  String get encryptedTLS;

  /// No description provided for @messagesEncryptedTLS.
  ///
  /// In en, this message translates to:
  /// **'Messages are encrypted in transit via TLS.'**
  String get messagesEncryptedTLS;

  /// No description provided for @unreadMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'1 Unread Message'**
  String get unreadMessageLabel;

  /// No description provided for @startYourConsultationTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your consultation'**
  String get startYourConsultationTitle;

  /// No description provided for @feelFreeToAskDesc.
  ///
  /// In en, this message translates to:
  /// **'Feel free to ask questions or share symptoms with your specialist.'**
  String get feelFreeToAskDesc;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @toStartConversationDesc.
  ///
  /// In en, this message translates to:
  /// **'To start a conversation, go to a doctor\'s profile and tap Send Message'**
  String get toStartConversationDesc;

  /// No description provided for @noConversationsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYetTitle;

  /// No description provided for @startChatSpecialistDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a chat with a specialist to see it here.'**
  String get startChatSpecialistDesc;

  /// No description provided for @noMatchesForSearch.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String noMatchesForSearch(Object query);

  /// No description provided for @professionalCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Professional Credentials'**
  String get professionalCredentialsTitle;

  /// No description provided for @helpVerifyExpertiseDesc.
  ///
  /// In en, this message translates to:
  /// **'Help us verify your medical expertise and practice history.'**
  String get helpVerifyExpertiseDesc;

  /// No description provided for @professionalTitleField.
  ///
  /// In en, this message translates to:
  /// **'Professional Title'**
  String get professionalTitleField;

  /// No description provided for @medicalSpecialtyField.
  ///
  /// In en, this message translates to:
  /// **'Medical Specialty'**
  String get medicalSpecialtyField;

  /// No description provided for @experienceYearsField.
  ///
  /// In en, this message translates to:
  /// **'Experience (Years)'**
  String get experienceYearsField;

  /// No description provided for @uploadMedicalLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Medical License'**
  String get uploadMedicalLicenseLabel;

  /// No description provided for @pdfJpgPng5MB.
  ///
  /// In en, this message translates to:
  /// **'PDF, JPG or PNG (Max 5MB)'**
  String get pdfJpgPng5MB;

  /// No description provided for @identityVerificationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerificationScreenTitle;

  /// No description provided for @secureUploadGovtIdDesc.
  ///
  /// In en, this message translates to:
  /// **'Securely upload your government-issued identification.'**
  String get secureUploadGovtIdDesc;

  /// No description provided for @governmentIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Government ID'**
  String get governmentIdLabel;

  /// No description provided for @intlPassportOrNationalId.
  ///
  /// In en, this message translates to:
  /// **'International Passport or National ID'**
  String get intlPassportOrNationalId;

  /// No description provided for @proofOfAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Proof of Address'**
  String get proofOfAddressLabel;

  /// No description provided for @utilityBillOrBankStatement.
  ///
  /// In en, this message translates to:
  /// **'Utility Bill or Bank Statement'**
  String get utilityBillOrBankStatement;

  /// No description provided for @faceRecognitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition'**
  String get faceRecognitionTitle;

  /// No description provided for @verifyIdentityDocumentDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify that you are the person on the identity document.'**
  String get verifyIdentityDocumentDesc;

  /// No description provided for @reviewSubmissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Submission'**
  String get reviewSubmissionTitle;

  /// No description provided for @confirmDetailsBeforeDesc.
  ///
  /// In en, this message translates to:
  /// **'Confirm your details before submitting for official review.'**
  String get confirmDetailsBeforeDesc;

  /// No description provided for @docsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Docs Status'**
  String get docsStatusLabel;

  /// No description provided for @verificationReadyLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification Ready'**
  String get verificationReadyLabel;

  /// No description provided for @certifyInfoAccurate.
  ///
  /// In en, this message translates to:
  /// **'I certify that the provided information is accurate and comply with Premon Care Professional Terms.'**
  String get certifyInfoAccurate;

  /// No description provided for @submitApplicationButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplicationButton;

  /// No description provided for @selectSpecialtyError.
  ///
  /// In en, this message translates to:
  /// **'Select your specialty'**
  String get selectSpecialtyError;

  /// No description provided for @uploadMedicalLicenseError.
  ///
  /// In en, this message translates to:
  /// **'Upload medical license'**
  String get uploadMedicalLicenseError;

  /// No description provided for @uploadIdDocumentError.
  ///
  /// In en, this message translates to:
  /// **'Upload ID document'**
  String get uploadIdDocumentError;

  /// No description provided for @uploadProofOfAddressError.
  ///
  /// In en, this message translates to:
  /// **'Upload proof of address'**
  String get uploadProofOfAddressError;

  /// No description provided for @captureLiveSelfieError.
  ///
  /// In en, this message translates to:
  /// **'Capture live selfie'**
  String get captureLiveSelfieError;

  /// No description provided for @verificationWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Wizard'**
  String get verificationWizardTitle;

  /// No description provided for @professionalProfileStep.
  ///
  /// In en, this message translates to:
  /// **'Professional Profile'**
  String get professionalProfileStep;

  /// No description provided for @identityDocumentsStep.
  ///
  /// In en, this message translates to:
  /// **'Identity Documents'**
  String get identityDocumentsStep;

  /// No description provided for @facialBiometricsStep.
  ///
  /// In en, this message translates to:
  /// **'Facial Biometrics'**
  String get facialBiometricsStep;

  /// No description provided for @reviewAndSubmitStep.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewAndSubmitStep;

  /// No description provided for @submitForReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get submitForReviewButton;

  /// No description provided for @applicationSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted!'**
  String get applicationSubmittedTitle;

  /// No description provided for @credentialsUnderReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Your professional credentials are now under review. This typically takes 24-48 hours. We will notify you once your account has been verified.'**
  String get credentialsUnderReviewDesc;

  /// No description provided for @returnToDashboardButton.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get returnToDashboardButton;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @verifyYourNumber.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Number'**
  String get verifyYourNumber;

  /// No description provided for @verifyPhoneNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone number to continue and secure your emergency care.'**
  String get verifyPhoneNumberDescription;

  /// No description provided for @createYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Your Profile'**
  String get createYourProfile;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself to personalize your healthcare experience.'**
  String get tellUsAboutYourself;

  /// No description provided for @emergencyGuestConversionFlow.
  ///
  /// In en, this message translates to:
  /// **'Emergency Guest\nConversion Flow'**
  String get emergencyGuestConversionFlow;

  /// No description provided for @convertGuestUsersDescription.
  ///
  /// In en, this message translates to:
  /// **'Convert emergency guest users to verified accounts for continuity of care and better support.'**
  String get convertGuestUsersDescription;

  /// No description provided for @yourHealthMatters.
  ///
  /// In en, this message translates to:
  /// **'Your Health Matters'**
  String get yourHealthMatters;

  /// No description provided for @healthJourneySupportMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to support you on your health journey. Thank you for choosing Premon Care.'**
  String get healthJourneySupportMessage;

  /// No description provided for @viewHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'View Health\nRecords'**
  String get viewHealthRecords;

  /// No description provided for @viewHealthRecordsDescription.
  ///
  /// In en, this message translates to:
  /// **'Access your emergency consultation and health history.'**
  String get viewHealthRecordsDescription;

  /// No description provided for @bookAppointments.
  ///
  /// In en, this message translates to:
  /// **'Book\nAppointments'**
  String get bookAppointments;

  /// No description provided for @bookAppointmentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Schedule consultations with trusted doctors.'**
  String get bookAppointmentsDescription;

  /// No description provided for @getHealthReminders.
  ///
  /// In en, this message translates to:
  /// **'Get Health\nReminders'**
  String get getHealthReminders;

  /// No description provided for @getHealthRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive medication reminders and follow-ups.'**
  String get getHealthRemindersDescription;

  /// No description provided for @chatWithDoctors.
  ///
  /// In en, this message translates to:
  /// **'Chat with\nDoctors'**
  String get chatWithDoctors;

  /// No description provided for @chatWithDoctorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect with doctors anytime for follow-up care.'**
  String get chatWithDoctorsDescription;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @viewMyHealthRecord.
  ///
  /// In en, this message translates to:
  /// **'View My Health Record'**
  String get viewMyHealthRecord;

  /// No description provided for @healthDataAlwaysProtected.
  ///
  /// In en, this message translates to:
  /// **'Your health. Your data. Always protected.'**
  String get healthDataAlwaysProtected;

  /// No description provided for @iIllDoThisLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll Do This Later'**
  String get iIllDoThisLater;

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get codeExpired;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code?'**
  String get didntReceiveCode;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Book verified\ndoctors instantly'**
  String get onboardingTitle1;

  /// No description provided for @onboardingText1.
  ///
  /// In en, this message translates to:
  /// **'Find and book trusted doctors in just a few taps.'**
  String get onboardingText1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Secure video\nconsultations'**
  String get onboardingTitle2;

  /// No description provided for @onboardingText2.
  ///
  /// In en, this message translates to:
  /// **'Talk to your doctor securely from the comfort of your home.'**
  String get onboardingText2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Pay with\ntime credits'**
  String get onboardingTitle3;

  /// No description provided for @onboardingText3.
  ///
  /// In en, this message translates to:
  /// **'Use time credits for consultations - simple, transparent, and fair.'**
  String get onboardingText3;

  /// No description provided for @skipLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipLabel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @loginLabel.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLabel;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @totalEarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarningsLabel;

  /// No description provided for @consultationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Consultations'**
  String get consultationsLabel;

  /// No description provided for @patientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsLabel;

  /// No description provided for @earningsLabelDisplay.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsLabelDisplay;

  /// No description provided for @availabilityStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability Status'**
  String get availabilityStatusLabel;

  /// No description provided for @availableStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableStatusLabel;

  /// No description provided for @emergencyAvailabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Availability'**
  String get emergencyAvailabilityLabel;

  /// No description provided for @timezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezoneLabel;

  /// No description provided for @unlimitedConsultations.
  ///
  /// In en, this message translates to:
  /// **'Unlimited consultations'**
  String get unlimitedConsultations;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get prioritySupport;

  /// No description provided for @timeCreditsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Time credits included'**
  String get timeCreditsIncluded;

  /// No description provided for @familyAccountUpTo5.
  ///
  /// In en, this message translates to:
  /// **'Family account (up to 5)'**
  String get familyAccountUpTo5;

  /// No description provided for @standardSupport.
  ///
  /// In en, this message translates to:
  /// **'Standard support'**
  String get standardSupport;

  /// No description provided for @timeCreditsNaira2000.
  ///
  /// In en, this message translates to:
  /// **'Time credits (â‚¦2,000)'**
  String get timeCreditsNaira2000;

  /// No description provided for @familyAccountNA.
  ///
  /// In en, this message translates to:
  /// **'Family account (N/A)'**
  String get familyAccountNA;

  /// No description provided for @vipSupport.
  ///
  /// In en, this message translates to:
  /// **'VIP support'**
  String get vipSupport;

  /// No description provided for @timeCreditsNaira7500.
  ///
  /// In en, this message translates to:
  /// **'Time credits (â‚¦7,500)'**
  String get timeCreditsNaira7500;

  /// No description provided for @familyAccountUpTo10.
  ///
  /// In en, this message translates to:
  /// **'Family account (up to 10)'**
  String get familyAccountUpTo10;

  /// No description provided for @timeCreditsNaira20000.
  ///
  /// In en, this message translates to:
  /// **'Time credits (â‚¦20,000)'**
  String get timeCreditsNaira20000;

  /// No description provided for @tenConsultationsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'10 consultations / month'**
  String get tenConsultationsPerMonth;

  /// No description provided for @renewsOnMay25.
  ///
  /// In en, this message translates to:
  /// **'Renews on May 25, 2025'**
  String get renewsOnMay25;

  /// No description provided for @fortyPercentUsed.
  ///
  /// In en, this message translates to:
  /// **'40% used'**
  String get fortyPercentUsed;

  /// No description provided for @thirtyPercentUsed.
  ///
  /// In en, this message translates to:
  /// **'30% used'**
  String get thirtyPercentUsed;

  /// No description provided for @basicPlan.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basicPlan;

  /// No description provided for @proPlan.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proPlan;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientLabel;

  /// No description provided for @recordLabel.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordLabel;

  /// No description provided for @otherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherLabel;

  /// No description provided for @doctorAvailabilitySchedule.
  ///
  /// In en, this message translates to:
  /// **'Doctor Availability & Schedule'**
  String get doctorAvailabilitySchedule;

  /// No description provided for @manageWorkingHoursDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your working hours, availability and preferences'**
  String get manageWorkingHoursDescription;

  /// No description provided for @openForBookings.
  ///
  /// In en, this message translates to:
  /// **'You are open for bookings'**
  String get openForBookings;

  /// No description provided for @pauseBookingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on to pause bookings'**
  String get pauseBookingsDescription;

  /// No description provided for @premonCareSupport.
  ///
  /// In en, this message translates to:
  /// **'Premon Care Support'**
  String get premonCareSupport;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @specialistLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialist'**
  String get specialistLabel;

  /// No description provided for @statusOnlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnlineLabel;

  /// No description provided for @statusOfflineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOfflineLabel;

  /// No description provided for @startConsultationTitle.
  ///
  /// In en, this message translates to:
  /// **'Start your consultation'**
  String get startConsultationTitle;

  /// No description provided for @feelFreeToAskDesc2.
  ///
  /// In en, this message translates to:
  /// **'Feel free to ask questions or share symptoms with your specialist.'**
  String get feelFreeToAskDesc2;

  /// No description provided for @prescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescriptionLabel;

  /// No description provided for @reportsLabel2.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsLabel2;

  /// No description provided for @imagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagesLabel;

  /// No description provided for @locationLabel2.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel2;

  /// No description provided for @practitionerVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Practitioner Verification'**
  String get practitionerVerificationTitle;

  /// No description provided for @actionRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequiredLabel;

  /// No description provided for @specialtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialtyLabel;

  /// No description provided for @experienceYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience (Years)'**
  String get experienceYearsLabel;

  /// No description provided for @licenseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumberLabel;

  /// No description provided for @uploadIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Government ID'**
  String get uploadIdLabel;

  /// No description provided for @proofOfAddressLabel2.
  ///
  /// In en, this message translates to:
  /// **'Proof of Address'**
  String get proofOfAddressLabel2;

  /// No description provided for @submitLabel.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitLabel;

  /// No description provided for @noRepliesYet.
  ///
  /// In en, this message translates to:
  /// **'No replies yet'**
  String get noRepliesYet;

  /// No description provided for @beFirstToReply.
  ///
  /// In en, this message translates to:
  /// **'Be the first to reply'**
  String get beFirstToReply;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @saveDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraftLabel;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @consultationFallback.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultationFallback;

  /// No description provided for @durationMinUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get durationMinUnit;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @userManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View, manage and take actions on all platform users'**
  String get userManagementSubtitle;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @addUserDescription.
  ///
  /// In en, this message translates to:
  /// **'New users register through the patient portal. Send them the registration link.'**
  String get addUserDescription;

  /// No description provided for @bulkActions.
  ///
  /// In en, this message translates to:
  /// **'Bulk Actions'**
  String get bulkActions;

  /// No description provided for @bulkActionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Bulk actions are being developed. Manage users individually through the list above.'**
  String get bulkActionsDescription;

  /// No description provided for @exportUsers.
  ///
  /// In en, this message translates to:
  /// **'Export Users'**
  String get exportUsers;

  /// No description provided for @exportUsersDescription.
  ///
  /// In en, this message translates to:
  /// **'Export is being developed. Use your device\'s screenshot feature to save user data.'**
  String get exportUsersDescription;

  /// No description provided for @inviteUser.
  ///
  /// In en, this message translates to:
  /// **'Invite User'**
  String get inviteUser;

  /// No description provided for @inviteUserDescription.
  ///
  /// In en, this message translates to:
  /// **'Invitations are sent automatically when users register. Direct them to the signup page.'**
  String get inviteUserDescription;

  /// No description provided for @userLogs.
  ///
  /// In en, this message translates to:
  /// **'User Logs'**
  String get userLogs;

  /// No description provided for @userLogsDescription.
  ///
  /// In en, this message translates to:
  /// **'Audit logs are being developed. All admin actions are tracked in the system for compliance.'**
  String get userLogsDescription;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @doctorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctorsLabel;

  /// No description provided for @patientsLabelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsLabelAdmin;

  /// No description provided for @pendingLabelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingLabelAdmin;

  /// No description provided for @suspendedLabel.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspendedLabel;

  /// No description provided for @adminsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminsTabLabel;

  /// No description provided for @userNameFallback.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userNameFallback;

  /// No description provided for @emailFallback.
  ///
  /// In en, this message translates to:
  /// **'email@example.com'**
  String get emailFallback;

  /// No description provided for @userActions.
  ///
  /// In en, this message translates to:
  /// **'User Actions'**
  String get userActions;

  /// No description provided for @activateAccount.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activateAccount;

  /// No description provided for @suspendAccount.
  ///
  /// In en, this message translates to:
  /// **'Suspend Account'**
  String get suspendAccount;

  /// No description provided for @banAccountPermanent.
  ///
  /// In en, this message translates to:
  /// **'Ban Account (Permanent)'**
  String get banAccountPermanent;

  /// No description provided for @editProfileInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Information'**
  String get editProfileInformation;

  /// No description provided for @resetVerificationState.
  ///
  /// In en, this message translates to:
  /// **'Reset Verification State'**
  String get resetVerificationState;

  /// No description provided for @impersonateSupportView.
  ///
  /// In en, this message translates to:
  /// **'Impersonate / Support View'**
  String get impersonateSupportView;

  /// No description provided for @emergencyIntervention.
  ///
  /// In en, this message translates to:
  /// **'Emergency Intervention'**
  String get emergencyIntervention;

  /// No description provided for @approveDoctorQuestion.
  ///
  /// In en, this message translates to:
  /// **'Approve Doctor?'**
  String get approveDoctorQuestion;

  /// No description provided for @approveDoctorDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve {name}? This will immediately grant them practitioner access and operational scheduling capabilities.'**
  String approveDoctorDescription(Object name);

  /// No description provided for @rejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject Application'**
  String get rejectApplication;

  /// No description provided for @rejectApplicationDescription.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejecting this application. This will be sent to the user.'**
  String get rejectApplicationDescription;

  /// No description provided for @requestInformation.
  ///
  /// In en, this message translates to:
  /// **'Request Information'**
  String get requestInformation;

  /// No description provided for @requestInformationDescription.
  ///
  /// In en, this message translates to:
  /// **'What additional information do you need from the applicant?'**
  String get requestInformationDescription;

  /// No description provided for @requestInformationHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Please upload a clearer copy of your Medical License.'**
  String get requestInformationHint;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @infoRequestSentStatus.
  ///
  /// In en, this message translates to:
  /// **'Information request sent. Status set to Under Review.'**
  String get infoRequestSentStatus;

  /// No description provided for @underReviewTab.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReviewTab;

  /// No description provided for @verifiedTab.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedTab;

  /// No description provided for @rejectedTab.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedTab;

  /// No description provided for @unsubmittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unsubmitted'**
  String get unsubmittedLabel;

  /// No description provided for @allCaughtUpCategory.
  ///
  /// In en, this message translates to:
  /// **'All caught up for this category!'**
  String get allCaughtUpCategory;

  /// No description provided for @backToQueue.
  ///
  /// In en, this message translates to:
  /// **'Back to Queue'**
  String get backToQueue;

  /// No description provided for @submittedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Submitted Documents'**
  String get submittedDocuments;

  /// No description provided for @applicationDetails.
  ///
  /// In en, this message translates to:
  /// **'Application Details'**
  String get applicationDetails;

  /// No description provided for @adminNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get adminNotesLabel;

  /// No description provided for @requestMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Request More Info'**
  String get requestMoreInfo;

  /// No description provided for @approveAndVerify.
  ///
  /// In en, this message translates to:
  /// **'Approve & Verify'**
  String get approveAndVerify;

  /// No description provided for @doctorVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'This doctor has been verified'**
  String get doctorVerifiedMessage;

  /// No description provided for @applicationRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'This application was rejected'**
  String get applicationRejectedMessage;

  /// No description provided for @revokeVerification.
  ///
  /// In en, this message translates to:
  /// **'Revoke Verification'**
  String get revokeVerification;

  /// No description provided for @revokeVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke Verification?'**
  String get revokeVerificationTitle;

  /// No description provided for @revokeVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to revoke {name}\'s verification? This will immediately remove their practitioner access and they will need to re-submit their credentials.'**
  String revokeVerificationDescription(Object name);

  /// No description provided for @revokeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for revocation (optional)'**
  String get revokeReasonHint;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @verificationRevokedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Verification revoked successfully'**
  String get verificationRevokedSuccessfully;

  /// No description provided for @identityComparison.
  ///
  /// In en, this message translates to:
  /// **'Identity Comparison'**
  String get identityComparison;

  /// No description provided for @governmentId.
  ///
  /// In en, this message translates to:
  /// **'Government ID'**
  String get governmentId;

  /// No description provided for @liveSelfie.
  ///
  /// In en, this message translates to:
  /// **'Live Selfie'**
  String get liveSelfie;

  /// No description provided for @viewBtn.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewBtn;

  /// No description provided for @userIdLabel.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userIdLabel;

  /// No description provided for @yearsOfExperience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get yearsOfExperience;

  /// No description provided for @specializationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specializationLabel;

  /// No description provided for @idType.
  ///
  /// In en, this message translates to:
  /// **'ID Type'**
  String get idType;

  /// No description provided for @medicalLicense.
  ///
  /// In en, this message translates to:
  /// **'Medical License'**
  String get medicalLicense;

  /// No description provided for @idDocumentFront.
  ///
  /// In en, this message translates to:
  /// **'ID Document (Front)'**
  String get idDocumentFront;

  /// No description provided for @idDocumentBack.
  ///
  /// In en, this message translates to:
  /// **'ID Document (Back)'**
  String get idDocumentBack;

  /// No description provided for @addressDocument.
  ///
  /// In en, this message translates to:
  /// **'Address Document'**
  String get addressDocument;

  /// No description provided for @noDocumentsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'No documents submitted'**
  String get noDocumentsSubmitted;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'The applicant has not uploaded any documents yet.'**
  String get noDocumentsYet;

  /// No description provided for @applicationDateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Application date unknown'**
  String get applicationDateUnknown;

  /// No description provided for @inReviewStat.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get inReviewStat;

  /// No description provided for @approvedStat.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedStat;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All Transactions'**
  String get allTransactions;

  /// No description provided for @financialAlerts.
  ///
  /// In en, this message translates to:
  /// **'Financial Alerts'**
  String get financialAlerts;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @totalPayouts.
  ///
  /// In en, this message translates to:
  /// **'Total Payouts'**
  String get totalPayouts;

  /// No description provided for @pendingPayoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending Payouts'**
  String get pendingPayoutsLabel;

  /// No description provided for @refundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refundsLabel;

  /// No description provided for @searchByTransaction.
  ///
  /// In en, this message translates to:
  /// **'Search by name, transaction ID...'**
  String get searchByTransaction;

  /// No description provided for @exportBtn.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportBtn;

  /// No description provided for @paymentDisputes.
  ///
  /// In en, this message translates to:
  /// **'Payment Disputes'**
  String get paymentDisputes;

  /// No description provided for @requireAttention.
  ///
  /// In en, this message translates to:
  /// **'Require attention'**
  String get requireAttention;

  /// No description provided for @reviewNow.
  ///
  /// In en, this message translates to:
  /// **'Review Now'**
  String get reviewNow;

  /// No description provided for @awaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get awaitingApproval;

  /// No description provided for @viewNow.
  ///
  /// In en, this message translates to:
  /// **'View Now'**
  String get viewNow;

  /// No description provided for @refundRequests.
  ///
  /// In en, this message translates to:
  /// **'Refund Requests'**
  String get refundRequests;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get pendingReview;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @revenueOverview.
  ///
  /// In en, this message translates to:
  /// **'Revenue Overview'**
  String get revenueOverview;

  /// No description provided for @revenueBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Revenue Breakdown'**
  String get revenueBreakdown;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @approvedBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedBreakdown;

  /// No description provided for @pendingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingBreakdown;

  /// No description provided for @otherBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherBreakdown;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get vsLastMonth;

  /// No description provided for @recentDisputes.
  ///
  /// In en, this message translates to:
  /// **'Recent Disputes'**
  String get recentDisputes;

  /// No description provided for @noDisputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes'**
  String get noDisputes;

  /// No description provided for @noOpenDisputes.
  ///
  /// In en, this message translates to:
  /// **'No open disputes to review'**
  String get noOpenDisputes;

  /// No description provided for @noPendingPayouts.
  ///
  /// In en, this message translates to:
  /// **'No pending payouts'**
  String get noPendingPayouts;

  /// No description provided for @allPayoutsProcessed.
  ///
  /// In en, this message translates to:
  /// **'All payouts have been processed'**
  String get allPayoutsProcessed;

  /// No description provided for @approvePayouts.
  ///
  /// In en, this message translates to:
  /// **'Approve Payouts'**
  String get approvePayouts;

  /// No description provided for @resolveDisputes.
  ///
  /// In en, this message translates to:
  /// **'Resolve Disputes'**
  String get resolveDisputes;

  /// No description provided for @transactionReports.
  ///
  /// In en, this message translates to:
  /// **'Transaction Reports'**
  String get transactionReports;

  /// No description provided for @payoutSettings.
  ///
  /// In en, this message translates to:
  /// **'Payout Settings'**
  String get payoutSettings;

  /// No description provided for @approvePayoutsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Approve Payouts?'**
  String get approvePayoutsQuestion;

  /// No description provided for @approvePayoutsDescription.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve all pending payouts? This will process {amount} across {count} transactions.'**
  String approvePayoutsDescription(Object amount, Object count);

  /// No description provided for @approveAll.
  ///
  /// In en, this message translates to:
  /// **'Approve All'**
  String get approveAll;

  /// No description provided for @refundType.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundType;

  /// No description provided for @awaitingApprovalType.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Approval'**
  String get awaitingApprovalType;

  /// No description provided for @disputedPayment.
  ///
  /// In en, this message translates to:
  /// **'Disputed Payment'**
  String get disputedPayment;

  /// No description provided for @consultationPayment.
  ///
  /// In en, this message translates to:
  /// **'Consultation Payment'**
  String get consultationPayment;

  /// No description provided for @disputeResolutionCenter.
  ///
  /// In en, this message translates to:
  /// **'Dispute Resolution Center'**
  String get disputeResolutionCenter;

  /// No description provided for @disputeResolutionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage, review and resolve disputes fairly and efficiently.'**
  String get disputeResolutionSubtitle;

  /// No description provided for @openDisputes.
  ///
  /// In en, this message translates to:
  /// **'Open Disputes'**
  String get openDisputes;

  /// No description provided for @inReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get inReview;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get filterPayment;

  /// No description provided for @filterConsultation.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get filterConsultation;

  /// No description provided for @filterRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get filterRefund;

  /// No description provided for @filterFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud'**
  String get filterFraud;

  /// No description provided for @filterBehavior.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get filterBehavior;

  /// No description provided for @filterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterOther;

  /// No description provided for @noDisputesFound.
  ///
  /// In en, this message translates to:
  /// **'No disputes found'**
  String get noDisputesFound;

  /// No description provided for @noDisputesMatch.
  ///
  /// In en, this message translates to:
  /// **'No disputes match the current filter.'**
  String get noDisputesMatch;

  /// No description provided for @disputeDetails.
  ///
  /// In en, this message translates to:
  /// **'Dispute Details'**
  String get disputeDetails;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @riskLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Risk Level'**
  String get riskLevelLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @disputeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Dispute ID'**
  String get disputeIdLabel;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdLabel;

  /// No description provided for @patientLabelDetail.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientLabelDetail;

  /// No description provided for @patientEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient Email'**
  String get patientEmailLabel;

  /// No description provided for @doctorLabelDetail.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorLabelDetail;

  /// No description provided for @doctorEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor Email'**
  String get doctorEmailLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @resolutionNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution Notes'**
  String get resolutionNotesLabel;

  /// No description provided for @resolutionActionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolution Actions'**
  String get resolutionActionsLabel;

  /// No description provided for @markAsInReview.
  ///
  /// In en, this message translates to:
  /// **'Mark as In Review'**
  String get markAsInReview;

  /// No description provided for @resolveLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolveLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @disputeInsights.
  ///
  /// In en, this message translates to:
  /// **'Dispute Insights'**
  String get disputeInsights;

  /// No description provided for @thisMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthLabel;

  /// No description provided for @openStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatusLabel;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @fairResolutionText.
  ///
  /// In en, this message translates to:
  /// **'We ensure fair, secure and transparent resolution for all parties involved.'**
  String get fairResolutionText;

  /// No description provided for @markAsUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Mark as Under Review'**
  String get markAsUnderReview;

  /// No description provided for @resolveDisputeAction.
  ///
  /// In en, this message translates to:
  /// **'Resolve Dispute'**
  String get resolveDisputeAction;

  /// No description provided for @closeDisputeAction.
  ///
  /// In en, this message translates to:
  /// **'Close Dispute'**
  String get closeDisputeAction;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @unknownDoctor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Doctor'**
  String get unknownDoctor;

  /// No description provided for @healthcareProvider.
  ///
  /// In en, this message translates to:
  /// **'Healthcare Provider'**
  String get healthcareProvider;

  /// No description provided for @recordTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. June Blood Test'**
  String get recordTitleHint;

  /// No description provided for @fileSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'File Selected: {fileName}'**
  String fileSelectedLabel(Object fileName);

  /// No description provided for @priorityAlerts.
  ///
  /// In en, this message translates to:
  /// **'Priority Alerts'**
  String get priorityAlerts;

  /// No description provided for @analyticsOverview.
  ///
  /// In en, this message translates to:
  /// **'Analytics Overview'**
  String get analyticsOverview;

  /// No description provided for @recentDoctorApplications.
  ///
  /// In en, this message translates to:
  /// **'Recent Doctor Applications'**
  String get recentDoctorApplications;

  /// No description provided for @systemsOnline.
  ///
  /// In en, this message translates to:
  /// **'Systems Online'**
  String get systemsOnline;

  /// No description provided for @totalPlatformRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Platform Revenue'**
  String get totalPlatformRevenue;

  /// No description provided for @appointmentsTodayCount.
  ///
  /// In en, this message translates to:
  /// **'{count} appointments today'**
  String appointmentsTodayCount(Object count);

  /// No description provided for @verifiedDoctorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verified doctors'**
  String verifiedDoctorsCount(Object count);

  /// No description provided for @verifiedDoctors.
  ///
  /// In en, this message translates to:
  /// **'Verified Doctors'**
  String get verifiedDoctors;

  /// No description provided for @appointmentsToday.
  ///
  /// In en, this message translates to:
  /// **'Appointments Today'**
  String get appointmentsToday;

  /// No description provided for @doctorVerifications.
  ///
  /// In en, this message translates to:
  /// **'Doctor Verifications'**
  String get doctorVerifications;

  /// No description provided for @needsResolution.
  ///
  /// In en, this message translates to:
  /// **'Needs resolution'**
  String get needsResolution;

  /// No description provided for @emergencyQueueLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Queue'**
  String get emergencyQueueLabel;

  /// No description provided for @liveMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Live monitoring'**
  String get liveMonitoring;

  /// No description provided for @openQueue.
  ///
  /// In en, this message translates to:
  /// **'Open Queue'**
  String get openQueue;

  /// No description provided for @appointmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} appointments'**
  String appointmentsCount(Object count);

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @cancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledLabel;

  /// No description provided for @noPendingApplications.
  ///
  /// In en, this message translates to:
  /// **'No pending applications'**
  String get noPendingApplications;

  /// No description provided for @allApplicationsReviewed.
  ///
  /// In en, this message translates to:
  /// **'All doctor applications have been reviewed.'**
  String get allApplicationsReviewed;

  /// No description provided for @failedToLoadApplications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load applications'**
  String get failedToLoadApplications;

  /// No description provided for @noRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get noRecentTransactions;

  /// No description provided for @transactionsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Transactions will appear here once payments are processed.'**
  String get transactionsWillAppear;

  /// No description provided for @refundedLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refundedLabel;

  /// No description provided for @failedToLoadTransactions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transactions'**
  String get failedToLoadTransactions;

  /// No description provided for @verifyDoctors.
  ///
  /// In en, this message translates to:
  /// **'Verify Doctors'**
  String get verifyDoctors;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @auditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogs;

  /// No description provided for @disputesLabel.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get disputesLabel;

  /// No description provided for @forumMod.
  ///
  /// In en, this message translates to:
  /// **'Forum Mod'**
  String get forumMod;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @reviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewLabel;

  /// No description provided for @accountSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Section'**
  String get accountSectionLabel;

  /// No description provided for @adminProfile.
  ///
  /// In en, this message translates to:
  /// **'Admin Profile'**
  String get adminProfile;

  /// No description provided for @adminProfileDeveloped.
  ///
  /// In en, this message translates to:
  /// **'Admin profile settings are being developed. Your account is managed by the platform owner.'**
  String get adminProfileDeveloped;

  /// No description provided for @permissionsRole.
  ///
  /// In en, this message translates to:
  /// **'Permissions / Role'**
  String get permissionsRole;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @operationalModules.
  ///
  /// In en, this message translates to:
  /// **'Operational Modules'**
  String get operationalModules;

  /// No description provided for @reportsAndInsights.
  ///
  /// In en, this message translates to:
  /// **'Reports & Insights'**
  String get reportsAndInsights;

  /// No description provided for @p2pMonitoring.
  ///
  /// In en, this message translates to:
  /// **'P2P Monitoring'**
  String get p2pMonitoring;

  /// No description provided for @notificationControl.
  ///
  /// In en, this message translates to:
  /// **'Notification Control'**
  String get notificationControl;

  /// No description provided for @doctorSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Doctor Subscriptions'**
  String get doctorSubscriptions;

  /// No description provided for @premonCareAdmin.
  ///
  /// In en, this message translates to:
  /// **'Premon Care Admin'**
  String get premonCareAdmin;

  /// No description provided for @adminPortal.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get adminPortal;

  /// No description provided for @doctorVerification.
  ///
  /// In en, this message translates to:
  /// **'Doctor Verification'**
  String get doctorVerification;

  /// No description provided for @financialModeration.
  ///
  /// In en, this message translates to:
  /// **'Financial Moderation'**
  String get financialModeration;

  /// No description provided for @forumModeration.
  ///
  /// In en, this message translates to:
  /// **'Forum Moderation'**
  String get forumModeration;

  /// No description provided for @auditTimeline.
  ///
  /// In en, this message translates to:
  /// **'Audit Timeline'**
  String get auditTimeline;

  /// No description provided for @subscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlans;

  /// No description provided for @disputeResolution.
  ///
  /// In en, this message translates to:
  /// **'Dispute Resolution'**
  String get disputeResolution;

  /// No description provided for @platformSettings.
  ///
  /// In en, this message translates to:
  /// **'Platform Settings'**
  String get platformSettings;

  /// No description provided for @usersLabel.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersLabel;

  /// No description provided for @forumLabel.
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get forumLabel;

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreLabel;

  /// No description provided for @loadingReports.
  ///
  /// In en, this message translates to:
  /// **'Loading reports...'**
  String get loadingReports;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @reportsInsightsCenter.
  ///
  /// In en, this message translates to:
  /// **'Reports & Insights Center'**
  String get reportsInsightsCenter;

  /// No description provided for @trackPerformanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Track performance, usage and key metrics in real-time'**
  String get trackPerformanceDescription;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @activeDoctors.
  ///
  /// In en, this message translates to:
  /// **'Active Doctors'**
  String get activeDoctors;

  /// No description provided for @appointmentsOverview.
  ///
  /// In en, this message translates to:
  /// **'Appointments Overview'**
  String get appointmentsOverview;

  /// No description provided for @noAppointmentsThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No appointments in this period'**
  String get noAppointmentsThisPeriod;

  /// No description provided for @completedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String completedCountLabel(Object count);

  /// No description provided for @cancelledCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled ({count})'**
  String cancelledCountLabel(Object count);

  /// No description provided for @rescheduledCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled ({count})'**
  String rescheduledCountLabel(Object count);

  /// No description provided for @rescheduledLabel.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get rescheduledLabel;

  /// No description provided for @topPerformingDoctors.
  ///
  /// In en, this message translates to:
  /// **'Top Performing Doctors'**
  String get topPerformingDoctors;

  /// No description provided for @noDoctorAppointmentsPeriod.
  ///
  /// In en, this message translates to:
  /// **'No doctor appointments in this period'**
  String get noDoctorAppointmentsPeriod;

  /// No description provided for @doctorColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorColumnHeader;

  /// No description provided for @appointmentsLowercase.
  ///
  /// In en, this message translates to:
  /// **'appointments'**
  String get appointmentsLowercase;

  /// No description provided for @platformActivity.
  ///
  /// In en, this message translates to:
  /// **'Platform Activity'**
  String get platformActivity;

  /// No description provided for @forumPosts.
  ///
  /// In en, this message translates to:
  /// **'Forum Posts'**
  String get forumPosts;

  /// No description provided for @reportsShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Reports Shortcuts'**
  String get reportsShortcuts;

  /// No description provided for @userAnalytics.
  ///
  /// In en, this message translates to:
  /// **'User Analytics'**
  String get userAnalytics;

  /// No description provided for @detailedUserInsights.
  ///
  /// In en, this message translates to:
  /// **'Detailed user insights'**
  String get detailedUserInsights;

  /// No description provided for @doctorPerformance.
  ///
  /// In en, this message translates to:
  /// **'Doctor Performance'**
  String get doctorPerformance;

  /// No description provided for @trackDoctorMetrics.
  ///
  /// In en, this message translates to:
  /// **'Track doctor metrics'**
  String get trackDoctorMetrics;

  /// No description provided for @financialReports.
  ///
  /// In en, this message translates to:
  /// **'Financial Reports'**
  String get financialReports;

  /// No description provided for @revenueTransactions.
  ///
  /// In en, this message translates to:
  /// **'Revenue & transactions'**
  String get revenueTransactions;

  /// No description provided for @appointmentReports.
  ///
  /// In en, this message translates to:
  /// **'Appointment Reports'**
  String get appointmentReports;

  /// No description provided for @bookingTrends.
  ///
  /// In en, this message translates to:
  /// **'Booking & trends'**
  String get bookingTrends;

  /// No description provided for @systemReports.
  ///
  /// In en, this message translates to:
  /// **'System Reports'**
  String get systemReports;

  /// No description provided for @systemAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'System & audit logs'**
  String get systemAuditLogs;

  /// No description provided for @reportsRealTimeEncrypted.
  ///
  /// In en, this message translates to:
  /// **'All reports are updated in real-time and data is securely encrypted.'**
  String get reportsRealTimeEncrypted;

  /// No description provided for @failedToLoadEmergencyQueue.
  ///
  /// In en, this message translates to:
  /// **'Failed to load emergency queue'**
  String get failedToLoadEmergencyQueue;

  /// No description provided for @emergencyQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{pending} pending • {accepted} accepted today'**
  String emergencyQueueSubtitle(Object accepted, Object pending);

  /// No description provided for @acceptedStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCEPTED'**
  String get acceptedStatusLabel;

  /// No description provided for @watchingLabel.
  ///
  /// In en, this message translates to:
  /// **'WATCHING'**
  String get watchingLabel;

  /// No description provided for @noEmergencyConsultsWaiting.
  ///
  /// In en, this message translates to:
  /// **'No emergency consults waiting'**
  String get noEmergencyConsultsWaiting;

  /// No description provided for @guestEmergencyBookingsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'New guest emergency bookings will appear here for immediate operational review.'**
  String get guestEmergencyBookingsWillAppear;

  /// No description provided for @responseChecklist.
  ///
  /// In en, this message translates to:
  /// **'Response Checklist'**
  String get responseChecklist;

  /// No description provided for @confirmDoctorAvailability.
  ///
  /// In en, this message translates to:
  /// **'Confirm doctor availability'**
  String get confirmDoctorAvailability;

  /// No description provided for @ensureSpecialistOnline.
  ///
  /// In en, this message translates to:
  /// **'Ensure the selected specialist is online and responsive.'**
  String get ensureSpecialistOnline;

  /// No description provided for @validateEmergencyPayment.
  ///
  /// In en, this message translates to:
  /// **'Validate emergency payment'**
  String get validateEmergencyPayment;

  /// No description provided for @checkP2pEvidence.
  ///
  /// In en, this message translates to:
  /// **'Check P2P evidence before session activation.'**
  String get checkP2pEvidence;

  /// No description provided for @monitorConversionFollowup.
  ///
  /// In en, this message translates to:
  /// **'Monitor conversion follow-up'**
  String get monitorConversionFollowup;

  /// No description provided for @guideGuestsRecords.
  ///
  /// In en, this message translates to:
  /// **'Guide guests to secure their records after consultation.'**
  String get guideGuestsRecords;

  /// No description provided for @guestPatient.
  ///
  /// In en, this message translates to:
  /// **'Guest Patient'**
  String get guestPatient;

  /// No description provided for @unassignedDoctor.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedDoctor;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment {status}'**
  String paymentStatus(Object status);

  /// No description provided for @agoLabel.
  ///
  /// In en, this message translates to:
  /// **'ago'**
  String get agoLabel;

  /// No description provided for @allClearMessage.
  ///
  /// In en, this message translates to:
  /// **'All clear! No emergency consultations currently waiting. New guest emergency bookings will appear here for immediate operational review.'**
  String get allClearMessage;

  /// No description provided for @chooseCaseFromQueue.
  ///
  /// In en, this message translates to:
  /// **'Choose a case from the queue to view details and respond.'**
  String get chooseCaseFromQueue;

  /// No description provided for @clinicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Clinical Details'**
  String get clinicalDetails;

  /// No description provided for @connectionIssue.
  ///
  /// In en, this message translates to:
  /// **'There was a connection issue. Please try again.'**
  String get connectionIssue;

  /// No description provided for @consultationInProgress.
  ///
  /// In en, this message translates to:
  /// **'Consultation in progress'**
  String get consultationInProgress;

  /// No description provided for @doctorAcceptedRequest.
  ///
  /// In en, this message translates to:
  /// **'Doctor accepted request'**
  String get doctorAcceptedRequest;

  /// No description provided for @emergencyRequestChecklist.
  ///
  /// In en, this message translates to:
  /// **'Response Checklist'**
  String get emergencyRequestChecklist;

  /// No description provided for @emergencyRequestReceived.
  ///
  /// In en, this message translates to:
  /// **'Emergency request received'**
  String get emergencyRequestReceived;

  /// No description provided for @failedToLoadQueue.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Queue'**
  String get failedToLoadQueue;

  /// No description provided for @loadingEmergencies.
  ///
  /// In en, this message translates to:
  /// **'Loading emergency cases...'**
  String get loadingEmergencies;

  /// No description provided for @noSpecialty.
  ///
  /// In en, this message translates to:
  /// **'No specialty'**
  String get noSpecialty;

  /// No description provided for @noSpecialtyAssigned.
  ///
  /// In en, this message translates to:
  /// **'No specialty assigned'**
  String get noSpecialtyAssigned;

  /// No description provided for @notifyAvailableDoctors.
  ///
  /// In en, this message translates to:
  /// **'Notify available doctors'**
  String get notifyAvailableDoctors;

  /// No description provided for @selectAnEmergencyCase.
  ///
  /// In en, this message translates to:
  /// **'Select an Emergency Case'**
  String get selectAnEmergencyCase;

  /// No description provided for @symptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsLabel;

  /// No description provided for @timeOfRequest.
  ///
  /// In en, this message translates to:
  /// **'Time of Request'**
  String get timeOfRequest;

  /// No description provided for @unknownPatient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Patient'**
  String get unknownPatient;

  /// No description provided for @infoRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Information request sent. Status set to Under Review.'**
  String get infoRequestSent;

  /// No description provided for @addAdminNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)...'**
  String get addAdminNotesHint;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addComment;

  /// No description provided for @approvedLabel.
  ///
  /// In en, this message translates to:
  /// **'APPROVED'**
  String get approvedLabel;

  /// No description provided for @approveLabel.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveLabel;

  /// No description provided for @availabilityLabel2.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityLabel2;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @baseConsultationFee.
  ///
  /// In en, this message translates to:
  /// **'Base consultation fee'**
  String get baseConsultationFee;

  /// No description provided for @blockLabel.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockLabel;

  /// No description provided for @blockPatientLabel.
  ///
  /// In en, this message translates to:
  /// **'Block patient'**
  String get blockPatientLabel;

  /// No description provided for @bookLabel.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get bookLabel;

  /// No description provided for @cancelYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Cancel your plan'**
  String get cancelYourPlan;

  /// No description provided for @choosePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlanLabel;

  /// No description provided for @clinicalRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinical rating'**
  String get clinicalRatingLabel;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @completedStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get completedStatusLabel;

  /// No description provided for @connectionProgress.
  ///
  /// In en, this message translates to:
  /// **'Connection progress'**
  String get connectionProgress;

  /// No description provided for @consultationComplete.
  ///
  /// In en, this message translates to:
  /// **'Consultation complete'**
  String get consultationComplete;

  /// No description provided for @consultationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Consultation successful'**
  String get consultationSuccessful;

  /// No description provided for @contactSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupportLabel;

  /// No description provided for @currentPlanButton.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlanButton;

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlanLabel;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @digitalReceipt.
  ///
  /// In en, this message translates to:
  /// **'Digital receipt'**
  String get digitalReceipt;

  /// No description provided for @disputedLabel.
  ///
  /// In en, this message translates to:
  /// **'DISPUTED'**
  String get disputedLabel;

  /// No description provided for @doctorConsultation.
  ///
  /// In en, this message translates to:
  /// **'Doctor consultation'**
  String get doctorConsultation;

  /// No description provided for @doctorProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor profile'**
  String get doctorProfileLabel;

  /// No description provided for @doctorRespondTime.
  ///
  /// In en, this message translates to:
  /// **'Doctor response time'**
  String get doctorRespondTime;

  /// No description provided for @emergencyMode.
  ///
  /// In en, this message translates to:
  /// **'Emergency mode'**
  String get emergencyMode;

  /// No description provided for @emergencyPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Emergency payment note'**
  String get emergencyPaymentNote;

  /// No description provided for @emergencyQueue.
  ///
  /// In en, this message translates to:
  /// **'Emergency Queue'**
  String get emergencyQueue;

  /// No description provided for @feeBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Fee breakdown'**
  String get feeBreakdown;

  /// No description provided for @freeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @logOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOutLabel;

  /// No description provided for @medicalRecordsMenu.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get medicalRecordsMenu;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @minutesReview.
  ///
  /// In en, this message translates to:
  /// **'Minutes review'**
  String get minutesReview;

  /// No description provided for @monthlyValue.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyValue;

  /// No description provided for @mostPopularLabel.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopularLabel;

  /// No description provided for @needHelpLabel.
  ///
  /// In en, this message translates to:
  /// **'Need help?'**
  String get needHelpLabel;

  /// No description provided for @noEmergencyConsults.
  ///
  /// In en, this message translates to:
  /// **'No emergency consultations'**
  String get noEmergencyConsults;

  /// No description provided for @offlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineLabel;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatus;

  /// No description provided for @onlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineLabel;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLabel;

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @patientDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient details'**
  String get patientDetailsLabel;

  /// No description provided for @pauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseLabel;

  /// No description provided for @paymentApprovalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment approvals'**
  String get paymentApprovalsLabel;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmed;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodLabel;

  /// No description provided for @pendingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatusLabel;

  /// No description provided for @premiumPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get premiumPlanLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @rateExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateExperience;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @recordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsLabel;

  /// No description provided for @recordsTab.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTab;

  /// No description provided for @rejectLabel.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectLabel;

  /// No description provided for @reportsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsLabel;

  /// No description provided for @requestExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Request expired'**
  String get requestExpiredMessage;

  /// No description provided for @resolveNow.
  ///
  /// In en, this message translates to:
  /// **'Resolve now'**
  String get resolveNow;

  /// No description provided for @reviewSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get reviewSubmitted;

  /// No description provided for @searchingDoctors.
  ///
  /// In en, this message translates to:
  /// **'Searching doctors'**
  String get searchingDoctors;

  /// No description provided for @searchingDoctorsMessage.
  ///
  /// In en, this message translates to:
  /// **'Searching for available doctors near you...'**
  String get searchingDoctorsMessage;

  /// No description provided for @sendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get sendAgain;

  /// No description provided for @sendMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessageLabel;

  /// No description provided for @sessionCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has been completed successfully.'**
  String get sessionCompletedMessage;

  /// No description provided for @settingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// No description provided for @subscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionLabel;

  /// No description provided for @subscriptionManagementLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription Management'**
  String get subscriptionManagementLabel;

  /// No description provided for @supportLabel.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportLabel;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @tipConnection.
  ///
  /// In en, this message translates to:
  /// **'Tip: Check your internet connection.'**
  String get tipConnection;

  /// No description provided for @tipRelax.
  ///
  /// In en, this message translates to:
  /// **'Tip: Relax while we find a doctor.'**
  String get tipRelax;

  /// No description provided for @tipSecure.
  ///
  /// In en, this message translates to:
  /// **'Tip: Your session is secure and encrypted.'**
  String get tipSecure;

  /// No description provided for @tipSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Tip: Prepare your symptoms for the doctor.'**
  String get tipSymptoms;

  /// No description provided for @totalEstimated.
  ///
  /// In en, this message translates to:
  /// **'Total estimated'**
  String get totalEstimated;

  /// No description provided for @unlimitedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimitedLabel;

  /// No description provided for @verificationStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get verificationStatusLabel;

  /// No description provided for @verifiedLabelCustom.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabelCustom;

  /// No description provided for @viewDoctor.
  ///
  /// In en, this message translates to:
  /// **'View Doctor'**
  String get viewDoctor;

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// No description provided for @whileYouWait.
  ///
  /// In en, this message translates to:
  /// **'While you wait'**
  String get whileYouWait;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
