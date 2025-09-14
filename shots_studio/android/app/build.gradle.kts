plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ansah.shots_studio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Flag to enable support for the new language APIs
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString() // Modified this line
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ansah.shots_studio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // version 24 for flutter_gemma to work.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "source"
    productFlavors {
        create("fdroid") {
            dimension = "source"
            buildConfigField("String", "BUILD_SOURCE", "\"fdroid\"")
            manifestPlaceholders["appNameSuffix"] = ""
        }
        create("github") {
            dimension = "source"
            buildConfigField("String", "BUILD_SOURCE", "\"github\"")
            manifestPlaceholders["appNameSuffix"] = ""
        }
        create("playstore") {
            dimension = "source"
            buildConfigField("String", "BUILD_SOURCE", "\"playstore\"")
            manifestPlaceholders["appNameSuffix"] = ""
        }
    }

    sourceSets {
        getByName("github") {
            manifest.srcFile("src/github/AndroidManifest.xml")
        }
        getByName("fdroid") {
            manifest.srcFile("src/fdroid/AndroidManifest.xml")
        }
        getByName("playstore") {
            manifest.srcFile("src/playstore/AndroidManifest.xml")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            applicationIdSuffix = ".test"
        }
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs.
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles.
        includeInBundle = false
    }

    // Configure APK output file names
    applicationVariants.all {
        outputs.all {
            val outputImpl = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            val versionName = defaultConfig.versionName
            val flavorName = productFlavors[0].name
            val buildTypeName = buildType.name
            outputImpl.outputFileName = "shots_studio-${flavorName}-${buildTypeName}-${versionName}.apk"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // Added this line
}
