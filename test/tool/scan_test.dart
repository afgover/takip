@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `tool/scan.sh` git geçmişini sır desenine karşı tarar. Testler geçici bir
/// depo kurup betiğin kopyasını orada koşar (betik kendi deposunu tarar).
Future<String> _scanRepo({required bool withSecret, int padCommits = 400}) async {
  final dir = await Directory.systemTemp.createTemp('scan-test-');
  addTearDown(() => dir.deleteSync(recursive: true));
  Future<void> git(List<String> args) async {
    final r = await Process.run('git', args, workingDirectory: dir.path);
    if (r.exitCode != 0) throw StateError('git ${args.join(' ')}: ${r.stderr}');
  }

  await git(['init', '-q']);
  await git(['config', 'user.email', 't@t']);
  await git(['config', 'user.name', 't']);
  Directory('${dir.path}/tool').createSync();
  File('tool/scan.sh').copySync('${dir.path}/tool/scan.sh');
  final f = File('${dir.path}/veri.txt');
  // Sırdan ÖNCE uzun bir geçmiş: `git log -p` en yeni commit'ten başlar, sır
  // çıktının başında görünür. Erken çıkan `grep -q` kalan büyük çıktıyı
  // okumaz, yazan taraf SIGPIPE ile ölür. Geçmiş kısa olsaydı çıktı boru
  // tamponuna sığar ve hata yeniden üretilmezdi.
  for (var i = 0; i < padCommits; i++) {
    f.writeAsStringSync('${'x' * 200} $i\n');
    await git(['add', '.']);
    await git(['commit', '-q', '-m', 'dolgu $i']);
  }
  if (withSecret) {
    // Sentetik desen: gerçek bir belirteç değil, yalnız biçimi eşleşir.
    f.writeAsStringSync('ghp_${'A' * 36}\n');
    await git(['add', '.']);
    await git(['commit', '-q', '-m', 'sir']);
    f.writeAsStringSync('temiz\n');
    await git(['commit', '-q', '-am', 'sil']);
  }
  // --quick: ağ gerektiren OSV adımını atlar; geçmiş taraması yine koşar.
  final r = await Process.run('bash', ['tool/scan.sh', '--quick'], workingDirectory: dir.path);
  return '${r.stdout}${r.stderr}';
}

void main() {
  test('geçmişteki sır, uzun geçmişte de bulunur', () async {
    final out = await _scanRepo(withSecret: true);
    expect(out, contains('git GEÇMİŞİNDE sır deseni eşleşti'));
    expect(out, isNot(contains('git geçmişi temiz')));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('sırsız geçmiş temiz raporlanır', () async {
    final out = await _scanRepo(withSecret: false, padCommits: 5);
    expect(out, contains('git geçmişi temiz'));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
