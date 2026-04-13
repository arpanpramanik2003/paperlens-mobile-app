# Keep Flutter and plugin classes to avoid runtime stripping issues.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Kotlin metadata and annotations used by reflection.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Keep line numbers for better crash traces in release logs.
-keepattributes SourceFile,LineNumberTable
