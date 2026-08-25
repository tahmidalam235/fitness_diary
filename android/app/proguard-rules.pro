# Release-build R8 keep rules.
#
# flutter_local_notifications loads its Android implementation and
# Gson-serialised payload classes reflectively, and references its
# receivers by FQCN from AndroidManifest.xml. Without these keep rules
# R8 renames / strips them, the platform channel can't bind, and
# scheduled reminders + test notifications silently fail to fire on
# the Firebase-distributed release APK (the in-app toggle appears to
# do nothing).
#
# Scoped strictly to the notification / Firebase plumbing so the rest
# of the app keeps the default R8 behaviour.

# flutter_local_notifications — parent package subsumes sub-packages.
-keep class com.dexterous.** { *; }

# Gson reflection for scheduled-notification payloads stored in
# AlarmManager extras. Without these, deserialisation fails at fire time
# and the alarm goes off without a notification.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# flutter_timezone — package is net.wolverinebeach.flutter_timezone
# (NOT dev.fluttercommunity.plus.timezone; that's a different plugin).
-keep class net.wolverinebeach.flutter_timezone.** { *; }

# timezone — pure Dart but kept just in case of any odd reflection issues.
# (Though R8 usually only affects Java/Kotlin code).

# Firebase — FirebaseInitProvider is the only Firebase class the OS
# instantiates by name (declared in the Firebase core library manifest
# merged into ours). Keep just that entry point; everything else is
# pulled in by the Firebase plugins' own consumer-rules.
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }
-dontwarn com.google.firebase.**

# AndroidX Core — required for notification support in some release builds.
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }
-keep class androidx.core.app.RemoteInput { *; }
