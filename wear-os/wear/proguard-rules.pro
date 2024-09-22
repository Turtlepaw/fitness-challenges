# Keep all classes in the application package
-keep class com.turtlepaw.fitness_challenges.** { *; }

# Keep all classes in Android Wear Compose library
-keep class androidx.wear.compose.** { *; }

# Keep all classes in AndroidX Compose library
-keep class androidx.compose.** { *; }

# Keep utils
-keep class com.turtlepaw.fitness_challenges.utils.** { *; }

# Keep services
-keep class com.turtlepaw.fitness_challenges.services.SyncWorker  { *; }
-keep class androidx.health.services.client.** { *; }

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn org.slf4j.impl.StaticLoggerBinder