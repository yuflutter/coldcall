# Keep MLKit optional language model classes referenced by google_mlkit_text_recognition
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

-dontwarn java.awt.**
-dontnote java.awt.**
-dontwarn com.sun.jna.**

-keep class com.sun.jna.* { *; }
-keepclassmembers class * extends com.sun.jna.* { public *; }
