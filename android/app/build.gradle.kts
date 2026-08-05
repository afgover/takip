import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release imzasi (SEC-010, B-101).
//
// Sir repoya girmez: `key.properties` .gitignore'da ve keystore dosyasinin
// kendisi deponun tamamen disinda durur — yolu asagidaki dosyada mutlak
// verilir. Anahtari repo icinde tutup .gitignore'a guvenmek, tek bir yanlis
// `git add -f`'e ya da .gitignore'u sifirlayan bir arac'a bagli kalmak demek.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

// Dosya yoksa release derlemesi **hata verir** — sessizce debug anahtarina
// dusmez. Sessiz dusus B-101'in kendisiydi: herkeste ayni olan bilinen bir
// anahtarla imzalanmis APK, ucuncu birinin "guncelleme" diye kurulabilecek
// paket uretmesine izin verir. Bir guvenlik ayarinin unutuldugunda calismaya
// devam etmesi, o ayarin yoklugu demektir.
//
// Yalnizca release isteniyorsa kontrol edilir; debug derlemeleri etkilenmez.
val requestedTasks = gradle.startParameter.taskNames.joinToString(" ")
val buildingRelease = requestedTasks.contains("Release") || requestedTasks.contains("release")
if (buildingRelease && !keystorePropertiesFile.exists()) {
    throw GradleException(
        """
        Release derlemesi icin imza yapilandirmasi yok: android/key.properties bulunamadi.

        Kendi anahtarinla imzalamadan release APK uretilemez (SEC-010, B-101).
        Kurulum adimlari: hub/tasks/waiting/2026-08-06-release-imza-anahtari.md

        Ozet:
          keytool -genkeypair -v -keystore ~/keys/takip-release.jks \
            -keyalg RSA -keysize 4096 -validity 10000 -alias takip
          # sonra android/key.properties:
          #   storeFile=/Users/<sen>/keys/takip-release.jks
          #   storePassword=...
          #   keyAlias=takip
          #   keyPassword=...

        Debug derlemesi etkilenmedi: flutter run / flutter build apk --debug calisir.
        """.trimIndent()
    )
}

android {
    namespace = "us.gover.takip"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "us.gover.takip"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Blok, key.properties yokken de olusur (debug derlemeleri
            // yapilandirmayi okumadan gecebilsin diye); yokluk yukarida
            // release istendiginde zaten hataya cevriliyor.
            if (keystorePropertiesFile.exists()) {
                val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
                val missing = required.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
                if (missing.isNotEmpty()) {
                    throw GradleException(
                        "android/key.properties eksik alan(lar) iceriyor: ${missing.joinToString(", ")}"
                    )
                }
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
