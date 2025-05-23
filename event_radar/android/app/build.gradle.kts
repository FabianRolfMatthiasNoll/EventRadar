import java.io.FileInputStream
import java.util.Properties

val dotenvFile = rootProject.file("../.env")
val dotenvProps = Properties().apply {
    if (dotenvFile.exists()) {
        load(FileInputStream(dotenvFile))
    } else {
        logger.warn(".env file not found at ${dotenvFile.absolutePath}")
    }
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "cc.eventradar.event_radar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // ← Hier unbedingt aktivieren, sonst beschwert sich
        // das plugin flutter_local_notifications über fehlendes Desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "cc.eventradar.event_radar"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["MAPS_API_KEY"] =
            dotenvProps.getProperty("GOOGLE_MAPS_API_KEY", "")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.8.10")
    implementation("androidx.core:core-ktx:1.12.0")

    implementation("com.google.firebase:firebase-messaging-ktx:23.1.0")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
