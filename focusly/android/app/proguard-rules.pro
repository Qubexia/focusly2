# flutter_local_notifications serialises every scheduled notification to JSON
# with Gson and rebuilds it in ScheduledNotificationReceiver when the alarm
# fires. The plugin ships no consumer ProGuard rules, so without these keeps
# R8 renames/strips the model classes and scheduled reminders silently fail
# in release builds (debug builds don't minify, which is why they work there).
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# Gson reads generic type parameters from class signatures at runtime.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# permission_handler + flutter_timezone
-keep class com.baseflow.permissionhandler.** { *; }
-keep class net.wolverinebeach.flutter_timezone.** { *; }

# Paymob native SDK (AAR ships an empty proguard.txt). Release minify/R8 can
# strip SDK classes/resources so Paymob.pay works in debug but fails on Play.
-keep class com.paymob.** { *; }
-keep class com.gyoussef55.paymob.** { *; }
-keepclassmembers class com.paymob.** { *; }
-dontwarn com.paymob.**
-dontwarn kotlinx.parcelize.**
-dontwarn kotlinx.android.parcel.**
