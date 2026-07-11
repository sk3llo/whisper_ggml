# whisper_ggml consumer rules — merged into the R8 configuration of every
# app that depends on this plugin.
#
# whisper_ggml depends on a forked ffmpeg-kit (com.antonkarpenko.ffmpegkit)
# that is loaded partly via reflection and JNI. R8 in release builds can
# strip or rename its classes; the resulting exception during plugin
# registration aborts GeneratedPluginRegistrant and leaves later plugins
# (path_provider, record, ...) unregistered, surfacing as
# "Unable to establish connection on channel" errors. See issue #16.

-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**

# Keep native method names for JNI registration.
-keepclasseswithmembernames class * {
    native <methods>;
}

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
