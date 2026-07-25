# ProGuard rules for Apex Legends Android build

# Keep LÖVE classes
-keep class org.love2d.** { *; }
-keep class org.libsdl.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application classes
-keep class com.apex.legends.** { *; }

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}
