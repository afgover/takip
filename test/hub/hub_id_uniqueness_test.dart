import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hub'daki ID'ler tekil mi? (sözleşme 1.15, çoklu kullanıcı — Katman 2)
///
/// **Neden bir test:** bütün ID'ler tekil sayaç — "son numarayı bul, bir artır".
/// İki agent aynı anda çalışırsa ikisi de aynı numarayı seçer ve dosyalar
/// **farklı** olduğu için git bunu çakışma saymaz: push reddedilmez, hiçbir şey
/// hata vermez. İki farklı kayıt aynı ID'yi taşır ve ona atıf yapan her satır
/// belirsizleşir.
///
/// Bu, sistemin en sinsi kırılması olurdu — her şey çalışmaya devam eder.
/// Amaç çakışmayı imkânsız kılmak değil (bkz. artifact: ID biçimini değiştirmek
/// yüzlerce mevcut atfı ikinci sınıfa düşürürdü), **görünür** kılmak: çakışma
/// bir sonraki test koşumunda yakalanır ve düzeltmesi tek satırdır.
void main() {
  test('hub genelinde tekrarlı ID tanımı yok', () {
    final defs = <String, List<String>>{};

    void scan(String path, RegExp pattern) {
      final file = File(path);
      if (!file.existsSync()) return;
      for (final m in pattern.allMatches(_stripFences(file.readAsStringSync()))) {
        defs.putIfAbsent(m.group(1)!, () => []).add(path);
      }
    }

    // Görev ve artifact ID'leri frontmatter'da; her dosya kendi ID'sini taşır.
    for (final dir in ['hub/tasks', 'hub/artifacts']) {
      for (final f in _markdownUnder(dir)) {
        scan(f, RegExp(r'^id:\s*((?:T|A)-[\d-]+)\s*$', multiLine: true));
      }
    }

    // Küratörlü listeler: her kayıt kendi başlığında/satırında tanımlanır.
    scan('hub/BACKLOG.md', RegExp(r'^- \[[ x]\] ~?~?(B-\d+)', multiLine: true));
    scan('hub/knowledge/rules.md', RegExp(r'^## (R-\d+)', multiLine: true));
    scan('hub/knowledge/skills.md', RegExp(r'^## (SK-\d+)', multiLine: true));
    scan('hub/knowledge/lessons.md', RegExp(r'^## (L-\d+)', multiLine: true));
    scan('hub/SECURITY.md', RegExp(r'^## (SEC-\d+)', multiLine: true));
    scan('hub/EVOLUTION.md', RegExp(r'^- \*\*(K-\d+):\*\*', multiLine: true));

    final duplicates = <String, List<String>>{
      for (final e in defs.entries)
        if (e.value.length > 1) e.key: e.value,
    };

    expect(
      duplicates,
      isEmpty,
      reason: 'Aynı ID birden çok yerde tanımlanmış. Muhtemel sebep: iki oturum '
          'aynı numarayı almış. Birini yeniden numaralandır ve ona yapılan '
          'atıfları güncelle.\n$duplicates',
    );

    // Tarayıcının gerçekten bir şey bulduğunu doğrula: desenlerden biri
    // bozulursa (başlık biçimi değişir, dosya taşınır) test sessizce "temiz"
    // demeye başlardı — doğrulanmamış boş sonuç, olmayan bir güvencedir (L-035).
    expect(defs.length, greaterThan(200),
        reason: 'çok az tanım bulundu — tarayıcı bozulmuş olabilir');
  });
}

List<String> _markdownUnder(String dir) {
  final root = Directory(dir);
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path)
      .where((p) => p.endsWith('.md'))
      .toList();
}

/// Kod bloklarını boşaltır. `BACKLOG.md`'nin başındaki biçim örneği gerçek
/// `B-001`/`B-002` maddeleriyle aynı satır desenine sahip; ayıklanmazsa test
/// olmayan bir çakışma bildirirdi.
String _stripFences(String text) {
  var inFence = false;
  return text.split('\n').map((line) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      return '';
    }
    return inFence ? '' : line;
  }).join('\n');
}
