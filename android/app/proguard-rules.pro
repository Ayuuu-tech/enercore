# R8 strips unused code from the release bundle. Flutter's engine is reached
# from native code, so R8 can't see those references and would remove them.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter's engine references Play Core's deferred-component APIs. We don't ship
# deferred components, so those classes aren't on the classpath and R8 rightly
# can't resolve them — the code paths are never reached.
-dontwarn com.google.android.play.core.**

# Keep annotations R8 uses to reason about nullability/keep rules.
-keepattributes *Annotation*

# Line numbers make Play Console's crash reports readable while still
# obfuscating names.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
