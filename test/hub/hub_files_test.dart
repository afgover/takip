import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:takip/hub/frontmatter.dart';

/// Sözleşme uyum testi: app'in parser'ı, agent'ın **gerçekten yazdığı**
/// dosyaları okuyabiliyor mu?
///
/// Uydurma örneklerle değil, repodaki hub içeriğiyle çalışır; sözleşme ile
/// uygulama arasında sessiz bir kayma olursa (L-004) burada yakalanır.
void main() {
  List<File> markdownFiles(String dir) {
    final d = Directory(dir);
    if (!d.existsSync()) return [];
    return d
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .where((f) => !f.path.endsWith('README.md'))
        .toList();
  }

  test('hub dosyaları frontmatter\'ıyla okunuyor', () {
    final files = [
      ...markdownFiles('hub/sessions'),
      ...markdownFiles('hub/tasks'),
      ...markdownFiles('hub/artifacts'),
    ];

    expect(files, isNotEmpty, reason: 'hub içeriği bulunamadı');

    for (final file in files) {
      final fm = Frontmatter.parse(file.readAsStringSync());
      final where = 'reason: ${file.path}';

      expect(fm.isMalformed, isFalse, reason: '$where — YAML bozuk');
      expect(fm.hasFrontmatter, isTrue, reason: '$where — frontmatter yok');
      expect(fm.str('id'), isNotNull, reason: '$where — id alanı yok');
      expect(fm.body.trim(), isNotEmpty, reason: '$where — gövde boş');
    }
  });

  test('oturum kayıtları şema alanlarını taşıyor (SYSTEM.md §2)', () {
    for (final file in markdownFiles('hub/sessions')) {
      final fm = Frontmatter.parse(file.readAsStringSync());

      expect(fm.str('id'), startsWith('S-'), reason: file.path);
      expect(fm.dateTime('date'), isNotNull, reason: file.path);
      expect(fm.str('status'), anyOf('open', 'closed'), reason: file.path);
    }
  });

  test('görev şablonu app\'in yazacağı alanları içeriyor (SYSTEM.md §4)', () {
    final fm =
        Frontmatter.parse(File('hub/tasks/_template.md').readAsStringSync());

    expect(
      fm.fields.keys,
      containsAll([
        'id',
        'title',
        'created_by',
        'created',
        'updated',
        'priority',
        'category',
        'tags',
        'session',
        'result',
      ]),
    );
    expect(fm.str('id'), 'pending', reason: 'app id atamaz, agent atar');
  });
}
