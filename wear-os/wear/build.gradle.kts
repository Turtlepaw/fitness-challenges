import java.util.Properties

val isCI = System.getenv("CI")?.toBoolean() ?: false

// Load key.properties only if not running in CI
val keyProperties = if (!isCI) {
    Properties().apply {
        file("../key.properties").inputStream().use { load(it) }
    }
} else {
    Properties()
}

@Suppress("DSL_SCOPE_VIOLATION") // TODO: Remove once KTIJ-19369 is fixed
plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.kotlinAndroid)
    kotlin("plugin.serialization") version "1.9.22"
    id("com.google.devtools.ksp")
    alias(libs.plugins.compose.compiler)
}

android {
    namespace = "com.turtlepaw.fitness_challenges"
    compileSdk = 34

    signingConfigs {
        create("release") {
            if (!isCI) {
                // Ensure properties are not null before casting
                keyAlias = keyProperties["keyAlias"]?.toString() ?: throw IllegalStateException("keyAlias not found in key.properties")
                keyPassword = keyProperties["keyPassword"]?.toString() ?: throw IllegalStateException("keyPassword not found in key.properties")
                storeFile = file(keyProperties["storeFile"]?.toString() ?: throw IllegalStateException("storeFile not found in key.properties"))
                storePassword = keyProperties["storePassword"]?.toString() ?: throw IllegalStateException("storePassword not found in key.properties")
            } else {
                // Use default values or ensure that environment variables are set
                storeFile = file("keystore.jks") // Ensure this file is available
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: throw IllegalStateException("KEYSTORE_PASSWORD environment variable not set")
                keyAlias = System.getenv("KEY_ALIAS") ?: throw IllegalStateException("KEY_ALIAS environment variable not set")
                keyPassword = System.getenv("KEY_PASSWORD") ?: throw IllegalStateException("KEY_PASSWORD environment variable not set")
            }
        }
        create("ciRelease"){
                storeFile = file("keystore.jks")
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    defaultConfig {
        applicationId = "com.turtlepaw.fitness_challenges"
        minSdk = 30
        targetSdk = 33
        versionCode = 4
        versionName = "1.0.0"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
        create("ciRelease") {
            initWith(getByName("release")) // Inherit configurations from release
            //isDebuggable = false
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("ciRelease")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            ndk {
                debugSymbolLevel = "FULL"
            }
            // Add any specific configurations for CI builds if needed
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.12"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation(libs.androidx.health.services.client)

    implementation("com.google.guava:guava:33.2.1-android")

    // To use CallbackToFutureAdapter
    implementation("androidx.concurrent:concurrent-futures:1.2.0")

    // Kotlin
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-guava:1.8.1")
    implementation(libs.androidx.core.i18n)

    // Room
    ksp(libs.androidx.room.compiler)
    implementation(libs.androidx.room.ktx)

    implementation(libs.play.services.wearable)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.compose.material)
    implementation(libs.androidx.compose.foundation)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.splashscreen)
    implementation(libs.androidx.tiles)
    implementation(libs.androidx.tiles.material)
    implementation(libs.horologist.compose.tools)
    implementation(libs.horologist.tiles)
    implementation(libs.androidx.watchface.complications.data.source.ktx)
    implementation(libs.horologist.compose.layout)
    implementation(libs.androidx.compose.navigation)
    implementation(libs.horologist.composables)
    implementation(libs.play.services.pal)
    implementation(libs.androidx.wear.tooling.preview)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.wear)
    implementation(libs.coil.compose)
    implementation(libs.coil)
    implementation(libs.coil.gif)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.androidx.work.runtime.ktx)
    implementation(libs.compose.shimmer)
    implementation(libs.androidx.material.icons.extended)
    implementation(libs.androidx.runtime.livedata)
    implementation(libs.accompanist.permissions)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.ui.test.junit4)
    debugImplementation(libs.androidx.ui.tooling)
    debugImplementation(libs.androidx.ui.test.manifest)
    coreLibraryDesugaring(libs.desugar.jdk.libs)

    // Lottie
    implementation(libs.lottie.compose)

    //wearApp(project(":wear"))
}
