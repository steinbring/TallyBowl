import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Keep credentials outside version control. CI can point to a protected file;
// local release builds use android/key.properties. Debug needs neither.
val releasePropertiesFile = providers.environmentVariable("TALLYBOWL_ANDROID_SIGNING_PROPERTIES")
    .orNull?.let { rootProject.file(it) } ?: rootProject.file("key.properties")
val releaseProperties = Properties().apply {
    if (releasePropertiesFile.isFile) {
        releasePropertiesFile.inputStream().use { load(it) }
    }
}
val signingFields = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val missingSigningFields = signingFields.filter { releaseProperties.getProperty(it).isNullOrBlank() }
val releaseKeystore = releaseProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }?.let { rootProject.file(it) }
val checkReleaseSigning = tasks.register("checkTallyBowlReleaseSigning") {
    group = "verification"
    description = "Require explicit signing before building an Android release."
    doLast {
        if (missingSigningFields.isNotEmpty() || releaseKeystore?.isFile != true) {
            throw GradleException(
                "Android release signing is not configured. Supply a protected android/key.properties " +
                    "or TALLYBOWL_ANDROID_SIGNING_PROPERTIES file with storeFile, storePassword, keyAlias " +
                    "and keyPassword, pointing to an existing upload keystore. See docs/ANDROID_SIGNING.md. " +
                    "For owner testing, use flutter build apk --debug. No unsigned or debug-key release is produced."
            )
        }
    }
}

android {
    namespace = "app.jws.tallybowl"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.jws.tallybowl"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (missingSigningFields.isEmpty()) {
                storeFile = releaseKeystore
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Cover APK/AAB packaging and fail before Flutter's release compilation too.
tasks.matching {
    it.name in setOf("preReleaseBuild", "validateSigningRelease", "compileFlutterBuildRelease")
}.configureEach { dependsOn(checkReleaseSigning) }

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Bundled model: recognition is available without downloading a model.
dependencies {
    implementation("com.google.mlkit:text-recognition:16.0.1")
    implementation("androidx.exifinterface:exifinterface:1.4.2")
}
