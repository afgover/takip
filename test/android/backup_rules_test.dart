import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Android yedekleme kuralları (SEC-009) yerinde mi?
///
/// Bu ayarlar Dart tarafından hiç çalıştırılmıyor, dolayısıyla hiçbir çalışma
/// zamanı testi onlara değmez. Kaybolmaları da sessizdir: `AndroidManifest.xml`
/// bir kez `flutter create` ile yeniden üretilirse öznitelikler gider ve
/// uygulama çalışmaya devam eder — yalnız cihazdaki şifresiz hub kopyası
/// yeniden buluta çıkmaya başlar. L-010 tam olarak bu şekilde yaşandı
/// (release manifestinde INTERNET izninin eksik olması).
///
/// Bu yüzden kontrol dosyaları okuyor: derleyicinin göremediği şeyi test görür.
void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  group('AndroidManifest', () {
    test('iki yedekleme kuralı da bağlı', () {
      // Yalnız biri bağlıysa açık, cihazların bir kısmında açık kalır:
      // dataExtractionRules API 31+, fullBackupContent 24-30.
      expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));
      expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));
    });
  });

  group('data_extraction_rules.xml (API 31+)', () {
    final rules =
        File('android/app/src/main/res/xml/data_extraction_rules.xml')
            .readAsStringSync();
    final cloud = _section(rules, 'cloud-backup');
    final transfer = _section(rules, 'device-transfer');

    test('buluta hiçbir veri çıkmıyor', () {
      for (final domain in const [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
      ]) {
        expect(cloud, contains('<exclude domain="$domain" />'),
            reason: '$domain buluta çıkmamalı');
      }
      expect(cloud, isNot(contains('<include')),
          reason: 'tek bir include, kuralın tamamını delerdi');
    });

    test('cihaz aktarımı çalışmaya devam ediyor', () {
      // Gizlilik gerekçesi cihaz aktarımı için geçerli değil: veri kullanıcının
      // kendi yeni telefonuna gidiyor. Kapatmak yeni telefonu boş bırakırdı.
      expect(transfer, isNot(contains('domain="root"')));
      expect(transfer, isNot(contains('domain="file"')));
    });

    test('token dosyaları aktarımdan çıkarılmış', () {
      // Anahtar Keystore'da ve dışa aktarılamaz; taşınan şifreli metin yeni
      // cihazda çözülemez. Bırakılsaydı uygulama okuyamadığı bir token'la
      // açılırdı — sessiz bozulma.
      expect(transfer,
          contains('<exclude domain="sharedpref" path="FlutterSecureStorage.xml" />'));
      expect(
          transfer,
          contains(
              '<exclude domain="sharedpref" path="FlutterSecureKeyStorage.xml" />'));
    });
  });

  group('backup_rules.xml (API 24-30)', () {
    final rules =
        File('android/app/src/main/res/xml/backup_rules.xml').readAsStringSync();

    test('eski sürümlerde de hiçbir veri buluta çıkmıyor', () {
      for (final domain in const [
        'root',
        'file',
        'database',
        'sharedpref',
        'external',
      ]) {
        expect(rules, contains('<exclude domain="$domain" />'), reason: domain);
      }
      expect(rules, isNot(contains('<include')));
    });
  });
}

/// `<ad> … </ad>` arasındaki metin. Kural dosyaları küçük ve sabit biçimli;
/// bir XML ayrıştırıcısı eklemek testin kendisini bağımlılığa bağlardı.
///
/// `expect` değil `StateError`: bu fonksiyon grup **kurulurken** çağrılıyor,
/// yani bir testin gövdesinde değil — orada `expect` çalışmaz.
String _section(String xml, String name) {
  final start = xml.indexOf('<$name>');
  final end = xml.indexOf('</$name>');
  if (start < 0 || end <= start) {
    throw StateError('<$name> bölümü bulunamadı ya da kapanışı yok');
  }
  return xml.substring(start, end);
}
