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

/// Oturum kaydı ve BACKLOG'u verilen tarihlerde commit'lenmiş hub kurar.
Future<(String, Directory)> _runFark(String oturum, String backlog) async {
  final dir = await Directory.systemTemp.createTemp('acilis-fark-');
  Future<void> git(List<String> a, [String? tarih]) async {
    final r = await Process.run('git', a, workingDirectory: dir.path, environment: {
      'GIT_AUTHOR_NAME': 'x', 'GIT_AUTHOR_EMAIL': 'x@x',
      'GIT_COMMITTER_NAME': 'x', 'GIT_COMMITTER_EMAIL': 'x@x',
      if (tarih != null) 'GIT_AUTHOR_DATE': tarih,
      if (tarih != null) 'GIT_COMMITTER_DATE': tarih,
    });
    if (r.exitCode != 0) throw StateError('git $a: ${r.stderr}');
  }

  Directory('${dir.path}/hub/sessions/2026-11-20-x').createSync(recursive: true);
  File('${dir.path}/hub/SYSTEM.md').writeAsStringSync('**Sözleşme sürümü:** 1.41\n');
  await git(['init', '-q', '.']);
  File('${dir.path}/hub/sessions/2026-11-20-x/session.md')
      .writeAsStringSync('---\nstatus: open\n---\n');
  await git(['add', 'hub/sessions']);
  await git(['commit', '-q', '-m', 'oturum'], oturum);
  File('${dir.path}/hub/BACKLOG.md').writeAsStringSync('# B\n');
  await git(['add', 'hub/BACKLOG.md']);
  await git(['commit', '-q', '-m', 'backlog'], backlog);
  final r = await Process.run(
    'bash',
    ['tool/acilis.sh', '--hub', '${dir.path}/hub'],
    environment: {'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin'},
  );
  return ('${r.stdout}${r.stderr}', dir);
}

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

  test('oturum kaydı BACKLOG\'dan bir günden eskiyse uyarır', () async {
    final (out, dir) =
        await _runFark('2026-11-21T21:00:00Z', '2026-11-24T17:00:00Z');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(out, contains('OTURUM KAYDI GERİDE: BACKLOG son oturum kaydından 68 saat yeni'));
  });

  test('bir günlük farkın içinde uyarmaz', () async {
    final (out, dir) =
        await _runFark('2026-11-23T18:00:00Z', '2026-11-24T17:00:00Z');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(out, isNot(contains('OTURUM KAYDI GERİDE')));
    expect(out, contains("oturum kaydı BACKLOG'un gerisinde değil"));
  });
}
