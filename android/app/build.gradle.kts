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

// key.properties yoksa ne olur? Su an: uyarip debug anahtarina duser.
//
// Ilk hali hata veriyordu ("kapali dusme"), cunku sessizce debug'a dusmek
// B-101'in kendisiydi. Karar **bilerek** gevsetildi (2026-08-06): anahtar
// uretimi ertelendi ve kural, gunluk kurulumu engelleyecek hale gelmisti.
//
// Gevsetmenin bedeli kabul edilebilir, cunku hatirlatici derleme ciktisinda
// degil kalici bir yerde duruyor: `tool/scan.sh` uretilmis APK'nin
// **sertifikasina** bakip debug imzasini bulgu olarak raporluyor. Derleme
// uyarisi scrollback'te kaybolur, tarama kaydi kaybolmaz (K-035'in ayni
// ilkesi).
//
// **Sinir:** APK bu makineden cikacaksa (GitHub Releases — B-097) once B-101
// kapanmalidir. Debug anahtari herkeste ayni oldugu icin ucuncu biri ayni
// paket adiyla "guncelleme" diye kurulabilecek bir APK uretebilir.
//
// Burada `logger.warn` denendi ve **ise yaramadi**: `flutter build apk`
// Gradle'in uyari ciktisini yutuyor, yani kullanici hicbir sey gormuyor.
// Gorunmeyen bir uyari, olmayan bir uyaridir. Hatirlatici bu yuzden iki
// gercekten gorulen yere kondu:
//   - `tool/install.sh` — her kurulumda ekrana yazar
//   - `tool/scan.sh`    — uretilmis APK'nin SERTIFIKASINA bakar, iddiaya degil

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
            // Yapilandirma hazir bekliyor: key.properties konuldugu an release
            // kendi anahtariyla imzalanir, baska bir degisiklik gerekmez.
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
            // Anahtar varsa kendi imzasi, yoksa debug (yukaridaki uyari).
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
