import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Çeviri kapsamı — kalan iş **ölçülür**, tahmin edilmez (sözleşme 1.18).
///
/// 337 metnin tamamını tek seferde taşımak mümkün değil; taşınmayanlar
/// Türkçe kalıyor ve bu **sessiz** bir eksiklik: uygulama çalışır, testler
/// geçer, yalnız İngilizce seçen kullanıcı yer yer Türkçe görür.
///
/// Bu dosya o eksikliği repoda görünür tutuyor:
///  - Taşınmış dosyalarda Türkçe metin **kalmamalı** (geri kayma olmasın).
///  - Taşınmamış dosyalar aşağıda **listeli**; sayıları azaldıkça liste küçülür.
///    Liste ile gerçek durum uyuşmazsa test kırılır — yani "bitti sandım"
///    diye bir durum oluşamaz.
void main() {
  /// Arayüz metni **artık** buradan gelmeli.
  const migrated = <String>[
    'lib/app.dart',
    'lib/features/browse/activity_screen.dart',
    'lib/features/browse/annotations_screen.dart',
    'lib/features/browse/browse_screen.dart',
    'lib/features/browse/doc_list_screen.dart',
    'lib/features/browse/document_screen.dart',
    'lib/features/browse/knowledge_screen.dart',
    'lib/features/browse/roadmap_screen.dart',
    'lib/features/common/hub_markdown.dart',
    'lib/features/common/hub_status_banner.dart',
    'lib/features/common/hub_watcher_scope.dart',
    'lib/features/common/repo_switcher.dart',
    'lib/features/common/token_scope_warning_dialog.dart',
    'lib/features/onboarding/onboarding_screen.dart',
    'lib/features/pending/done_screen.dart',
    'lib/features/pending/pending_screen.dart',
    'lib/features/settings/settings_screen.dart',
    'lib/features/shell.dart',
  ];

  /// Henüz taşınmamış ekranlar (B-115). Her taşımada buradan bir satır silinir.
  const pending = <String>[
    'lib/features/add_task/add_task_screen.dart',
    'lib/features/browse/security_screen.dart',
    'lib/features/common/annotated_document.dart',
    'lib/features/common/hub_error_view.dart',
    'lib/features/common/selection_record.dart',
    'lib/features/pending/task_detail_screen.dart',
    'lib/features/settings/backup_screen.dart',
    'lib/features/settings/connection_screen.dart',
    'lib/features/settings/connections_screen.dart',
  ];

  test('taşınmış dosyalarda Türkçe arayüz metni kalmadı', () {
    for (final path in migrated) {
      expect(
        _turkishLiterals(File(path).readAsStringSync()),
        isEmpty,
        reason: '$path taşınmış sayılıyor ama Türkçe metin içeriyor',
      );
    }
  });

  test('bekleyen listesi gerçek durumla uyuşuyor', () {
    // Liste elle tutuluyor; gerçekle ayrışırsa kalan iş yanlış görünür.
    final actual = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => p.endsWith('.dart'))
        .where((p) => _turkishLiterals(File(p).readAsStringSync()).isNotEmpty)
        .toList()
      ..sort();

    expect(actual, pending, reason: 'çeviri bekleyen dosya listesi güncellenmeli');
  });

  test('iki dil aynı anahtarları taşıyor', () {
    // Eksik anahtar sessizdir: gen_l10n eksik olanı şablondan doldurur, yani
    // İngilizce seçen kullanıcı o satırda Türkçe görür ve hiçbir şey hata
    // vermez.
    final tr = (jsonDecode(File('lib/l10n/app_tr.arb').readAsStringSync())
            as Map<String, dynamic>)
        .keys
        .where((k) => !k.startsWith('@'))
        .toSet();
    final en = (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>)
        .keys
        .where((k) => !k.startsWith('@'))
        .toSet();

    expect(en.difference(tr), isEmpty, reason: 'İngilizce\'de fazla anahtar');
    expect(tr.difference(en), isEmpty, reason: 'İngilizce\'de eksik anahtar');
    expect(tr, isNotEmpty);
  });
}

/// Türkçe'ye özgü harf içeren string sabitleri. Kaba ama bu iş için yeterli:
/// arayüz metinlerinin neredeyse tamamı bu harflerden birini içeriyor.
/// Yorum satırları sayılmaz — onlar kullanıcıya görünmüyor.
List<String> _turkishLiterals(String source) {
  final withoutComments = source
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  return RegExp(r"'[^'\n]*[çğıöşüÇĞİÖŞÜ][^'\n]*'")
      .allMatches(withoutComments)
      .map((m) => m.group(0)!)
      .toList();
}
