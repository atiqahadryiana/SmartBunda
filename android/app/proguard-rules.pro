# SmartBunda — R8/ProGuard keep rules for the release build.
# R8 shrinking is enabled so the desugared baseline ART profile compiles
# (required by core library desugaring for flutter_local_notifications).

# ── Flutter engine / embedding ───────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ── flutter_local_notifications (Gson type tokens + receivers) ────────────────
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*
# Gson uses generic type information stored in class signatures.
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# ── Firebase / Google Play services ──────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Play Core (Flutter deferred components — unused here) ─────────────────────
# Flutter's embedding references these split-install classes even though the
# app doesn't use deferred components; suppress the missing-class errors.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ── TensorFlow Lite (tflite_flutter / on-device food classifier) ─────────────
# TFLite references its optional GPU delegate via reflection; the GPU delegate
# classes aren't always present and R8 errors on them. Keep the TFLite API and
# suppress the missing GPU-delegate classes (CPU fallback is used when absent).
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# ── Keep annotations referenced by desugared libs ────────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
