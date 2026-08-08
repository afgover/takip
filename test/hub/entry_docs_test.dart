import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Giriş belgeleri ve yöntem belgeleri iki dilde de var mı? (B-118, B-116)
///
/// Kısır döngü şuydu: "İngilizce kurulum nasıl yapılır"ı anlatan belge Türkçe
/// olduğu için İngilizce konuşan biri **başlayamıyordu**. Dil seçeneği ancak
/// giriş noktası okunabilirse ulaşılabilir.
///
/// Bu test o girişin sessizce kaybolmamasını sağlıyor: dosya silinir ya da
/// yeniden adlandırılırsa kırılır. İçeriğin **güncelliğini** ölçmez — onu
/// ölçmek çeviri denkliği demek olurdu ve elle tutulan bir listeye dönerdi;
/// bunun yerine her iki belge de hangi sürümden türediğini yazıyor.
void main() {
  const entries = {
    'README.md': 'README.en.md',
    'hub/artifacts/reference/agent-kurulum-talimati.md':
        'hub/artifacts/reference/setup-instruction.en.md',
    // B-116: yöntemin kendisi de iki dilde. Bunlar giriş değil **referans**
    // belgeleri, ama aynı ayrışma riskini taşıyorlar.
    'hub/SYSTEM.md': 'hub/SYSTEM.en.md',
    'hub/AGENT_PROTOCOL.md': 'hub/AGENT_PROTOCOL.en.md',
  };

  test('her giriş belgesinin İngilizce karşılığı var', () {
    for (final entry in entries.entries) {
      expect(File(entry.key).existsSync(), isTrue, reason: entry.key);
      expect(File(entry.value).existsSync(), isTrue, reason: entry.value);
    }
  });

  test('iki sürüm birbirine bağlı — biri diğerinden bulunabiliyor', () {
    for (final entry in entries.entries) {
      final tr = File(entry.key).readAsStringSync();
      final en = File(entry.value).readAsStringSync();
      final enName = entry.value.split('/').last;
      final trName = entry.key.split('/').last;

      expect(tr, contains(enName),
          reason: '${entry.key} İngilizce sürümüne link vermiyor');
      expect(en, contains(trName),
          reason: '${entry.value} Türkçe ana kopyaya link vermiyor');
    }
  });

  test('İngilizce yöntem belgeleri kanonik kopyayı açıkça söylüyor', () {
    // "Türkçe olan geçerlidir" cümlesi belgenin **içinde** duruyor. Dışarıda
    // bir yerde dursa, belgeyi tek başına okuyan biri iki eşit otorite görür
    // ve çeliştiklerinde hangisine uyacağını bilemez (L-022).
    for (final path in ['hub/SYSTEM.en.md', 'hub/AGENT_PROTOCOL.en.md']) {
      final text = File(path).readAsStringSync();
      expect(text.toLowerCase(), contains('canonical'), reason: path);
    }
  });

  test('iki sözleşme aynı sürümü söylüyor', () {
    // Sürüm ayrışması burada özellikle sinsi: §10 sürüm karşılaştırmasıyla
    // çalışıyor, yani İngilizce varyant geride kalırsa İngilizce hub'lar
    // güncellemeyi **hiç** görmez.
    String versionOf(String path) => RegExp(
          r'\*\*(?:Sözleşme sürümü|Contract version):\*\*\s*([0-9.]+)',
        ).firstMatch(File(path).readAsStringSync())!.group(1)!;

    expect(versionOf('hub/SYSTEM.en.md'), versionOf('hub/SYSTEM.md'));
  });

  test('İngilizce sözleşme hub dilini en olarak ilan ediyor', () {
    final en = File('hub/SYSTEM.en.md').readAsStringSync();
    expect(RegExp(r'\*\*Hub language:\*\*\s*en').hasMatch(en), isTrue);
  });

  test('İngilizce sürüm hangi ana kopyadan türediğini söylüyor', () {
    // İki **bağlayıcı** kopya ayrışır (L-022). Türetilmiş olan bunu yazmalı ki
    // çeliştiklerinde hangisinin geçerli olduğu tartışma konusu olmasın.
    final setup =
        File('hub/artifacts/reference/setup-instruction.en.md').readAsStringSync();
    expect(setup, contains('translated_from:'));
    expect(setup, contains('language: en'));
    expect(setup, contains('contract:'));
  });
}
