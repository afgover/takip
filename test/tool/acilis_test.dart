@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `tool/acilis.sh` hub dosyalarını okur; bu dosyalar başka birinin yazdığı
/// veridir. Testler geçici bir hub kurar, betiği gerçekten koşar.
Future<(String, Directory)> _run(String securityMd) async {
  final dir = await Directory.systemTemp.createTemp('acilis-test-');
  final hub = Directory('${dir.path}/hub')..createSync();
  File('${hub.path}/SYSTEM.md').writeAsStringSync('**Sözleşme sürümü:** 1.41\n');
  File('${hub.path}/SECURITY.md').writeAsStringSync(securityMd);
  final result = await Process.run(
    'bash',
    ['tool/acilis.sh', '--hub', hub.path],
    environment: {'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin'},
  );
  return ('${result.stdout}${result.stderr}', dir);
}

String _scan(String date) =>
    '## SEC-001 — x\n- **Tarih:** $date\n- **Tür:** tarama\n- **Durum:** kapali\n';

void main() {
  test('SECURITY.md tarihi kod olarak çalışmaz', () async {
    final marker = File('${Directory.systemTemp.path}/acilis-enjeksiyon-$pid');
    if (marker.existsSync()) marker.deleteSync();
    final payload =
        "2026-01-01'));open('${marker.path}','w').write('x');print(('";
    final (out, dir) = await _run(_scan(payload));
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(marker.existsSync(), isFalse, reason: out);
    expect(out, contains('son tarama tarihi okunamadı'));
  });

  test('geçerli tarih eskisi gibi yaşla raporlanır', () async {
    final today = DateTime.now();
    final d = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final (out, dir) = await _run(_scan(d));
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(out, matches(RegExp('son tarama $d \\([01] gün\\)')));
  });

  test('eski tarih 30 günü aştı uyarısı verir', () async {
    final (out, dir) = await _run(_scan('2020-01-01'));
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(out, contains('30 günü aştı'));
  });
}
