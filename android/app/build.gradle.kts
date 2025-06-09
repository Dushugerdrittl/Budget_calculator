import java.util.*          // Import all classes from java.util

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties() // Use Properties directly
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { reader ->
        localProperties.load(reader)
    }
}

var flutterVersionCode = localProperties.getProperty("flutter.versionCode")
if (flutterVersionCode == null) {
    flutterVersionCode = "1"
}

var flutterVersionName = localProperties.getProperty("flutter.versionName")
if (flutterVersionName == null) {
    flutterVersionName = "1.0"
}

android {
    namespace = "com.fxkittyexpense.appkit" // Ensure this matches your package name
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11" // Match Java version
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fxkittyexpense.appkit"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/deployment/android#reviewing-the-gradle-build-configuration.
        minSdk = 23 // Required by firebase_auth and other plugins
        targetSdk = 35 // Match compileSdk
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug") // Correct access
        }
    }
}

flutter {
    source = "../.." // Path should be a String
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7") // Version often managed by Kotlin Gradle Plugin
    // Add the desugaring library
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Check for the latest version
    // Example of Firebase BoM, uncomment and use specific Firebase SDKs if needed
    // implementation(platform("com.google.firebase:firebase-bom:33.1.1"))
    // implementation("com.google.firebase:firebase-analytics")
}
