# google_mlkit_text_recognition references the optional Chinese, Devanagari,
# Japanese and Korean recognisers. The app only bundles the Latin one, so
# these classes are absent on purpose; without these rules R8 fails the
# release build with "Missing class ...TextRecognizerOptions".
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
