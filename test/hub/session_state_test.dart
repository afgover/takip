import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sözleşme 1.20: aynı anda yalnız bir oturum açık olabilir, o da en yeni
/// tarihli olan.
///
/// Kural bir oturumun dokuz gün `open` kalmasından sonra kondu (L-042).
/// Kapanış listesi "bu oturumu kapat" diye soruyordu; kimse "açık kalan var mı"
/// diye sormuyordu. Cevabı repoda duran bir soruyu insana bırakmak, L-041'in
/// tarif ettiği hata: yalnız belgede duran kural, onu yazanın hafızasına bağlı.
void main() {
  test('en fazla bir oturum açık, o da en yenisi', () {
    final sessions = Directory('hub/sessions')
        .listSync()
        .whereType<Directory>()
        .map((d) => File('${d.path}/session.md'))
        .where((f) => f.existsSync())
        .toList();

    expect(sessions, isNotEmpty, reason: 'hub/sessions okunamadı');

    String dateOf(File f) => f.parent.path.split('/').last.substring(0, 10);

    final open = sessions
        .where((f) => RegExp(r'^status:\s*open\s*$', multiLine: true)
            .hasMatch(f.readAsStringSync()))
        .toList();

    expect(
      open.map((f) => f.parent.path.split('/').last).toList(),
      hasLength(lessThanOrEqualTo(1)),
      reason: 'Birden fazla oturum açık. Eskisini kapat: özetini kendi '
          'kaydından türet ve türetildiğini yaz (sözleşme 1.20, L-042).',
    );

    if (open.isEmpty) return;

    final newest =
        sessions.map(dateOf).reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    expect(
      dateOf(open.single),
      newest,
      reason: 'Açık oturum en yeni tarihli olmalı — daha yeni bir oturum '
          'varken eski bir oturumun açık kalması, kapanışta atlandığı '
          'anlamına gelir (L-042).',
    );
  });
}
