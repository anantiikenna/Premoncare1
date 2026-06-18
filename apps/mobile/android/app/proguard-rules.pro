# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Jitsi Meet
-keep class org.jitsi.** { *; }
-keep class org.webrtc.** { *; }
-keep class com.facebook.react.** { *; }
-keep class com.facebook.react.bridge.** { *; }
-keepclassmembers class * {
    @com.facebook.proguard.annotations.DoNotStrip *;
    @com.facebook.common.internal.DoNotStrip *;
    native <methods>;
}

# Firebase
-keep class com.google.firebase.** { *; }

# Google Play Core (Flutter Deferred Components)
-dontwarn com.google.android.play.core.**
