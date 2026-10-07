plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val atenaAndroidDemo = System.getenv("ATENA_ANDROID_DEMO") == "1"
val atenaAndroidMultiuser = System.getenv("ATENA_ANDROID_MULTIUSER") == "1"

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = if (atenaAndroidMultiuser) {
            "org.atena.evaluation.multiuser"
        } else if (atenaAndroidDemo) {
            "org.atena.demo.municipio"
        } else {
            "com.example.flutter_application_1"
        }
        manifestPlaceholders["atenaAppLabel"] = if (atenaAndroidMultiuser) {
            "Atena Multiusuario"
        } else if (atenaAndroidDemo) {
            "Atena Demo"
        } else {
            "flutter_application_1"
        }
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
