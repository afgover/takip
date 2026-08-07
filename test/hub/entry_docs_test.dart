import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Giriş belgeleri iki dilde de var mı? (B-118)
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
