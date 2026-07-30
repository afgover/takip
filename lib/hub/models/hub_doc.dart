import '../../core/utils.dart';
import '../frontmatter.dart';

/// Tarayıcıda listelenen bir hub belgesi.
///
/// Liste görünümleri bunu **dosya indirmeden** üretir: sözleşme dosya ve klasör
/// adlarını `<YYYY-MM-DD>-<slug>` biçiminde tanımladığı için tarih ve okunabilir
/// başlık yoldan çıkarılabilir (SYSTEM.md §2, §4).
class HubDoc {
  const HubDoc({
    required this.path,
    required this.title,
    this.date,
    this.sha,
    this.subtitle,
  });

  /// `sessions/2026-07-30-hub-tasima/session.md` gibi bir yoldan üretir:
  /// tarih ve başlık, klasör adından okunur.
  factory HubDoc.fromDatedPath(String path, {String? sha, String? subtitle}) {
    final segments = path.split('/');
    // Oturumlarda anlamlı ad klasörde, artifact'larda dosyadadır.
    final stem = segments.last == 'session.md'
        ? segments[segments.length - 2]
        : _withoutExtension(segments.last);

    final match = _datedName.firstMatch(stem);
    return HubDoc(
      path: path,
      sha: sha,
      subtitle: subtitle,
      date: match == null ? null : DateTime.tryParse(match.group(1)!),
      title: titleFromSlug(match == null ? stem : match.group(2)!),
    );
  }

  final String path;
  final String title;
  final DateTime? date;
  final String? sha;

  /// Listede ikinci satır (oturum durumu, artifact türü gibi).
  final String? subtitle;

  HubDoc copyWith({String? title, String? subtitle}) => HubDoc(
        path: path,
        title: title ?? this.title,
        date: date,
        sha: sha,
        subtitle: subtitle ?? this.subtitle,
      );

  @override
  bool operator ==(Object other) =>
      other is HubDoc && other.path == path && other.sha == sha;

  @override
  int get hashCode => Object.hash(path, sha);

  static final _datedName = RegExp(r'^(\d{4}-\d{2}-\d{2})-(.+)$');

  static String _withoutExtension(String name) =>
      name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
}

/// `knowledge/` dosyalarındaki tek kayıt (`R-001`, `SK-002`, `L-003`…).
///
/// Sözleşme (SYSTEM.md §5) her kaydı `## <ID> — <başlık>` bloğu olarak
/// tanımlar; geçersizleşen kayıt silinmez, başlığı `~~üstü çizilir~~` (R-004).
/// Liste bu ayrımı göstermek zorunda: aksi hâlde geçersiz bir kural geçerliymiş
/// gibi okunur.
class KnowledgeEntry {
  const KnowledgeEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.isInvalidated,
    this.date,
    this.source,
  });

  final String id;
  final String title;

  /// Kaydın markdown gövdesi (tarih/kaynak satırları dahil).
  final String body;

  /// Başlığı üstü çizili → geçersiz kayıt (R-004).
  final bool isInvalidated;

  final String? date;
  final String? source;

  /// Bir knowledge dosyasını kayıtlara ayırır.
  static List<KnowledgeEntry> parseFile(String content) {
    final body = Frontmatter.parse(content).body;
    final entries = <KnowledgeEntry>[];

    // `## ` ile başlayan her blok bir kayıt; ilk blok öncesi dosya girişidir.
    final blocks = body.split(RegExp(r'^## ', multiLine: true));
    for (final block in blocks.skip(1)) {
      final newline = block.indexOf('\n');
      final heading = (newline == -1 ? block : block.substring(0, newline)).trim();
      final rest = newline == -1 ? '' : block.substring(newline + 1).trim();

      final stripped = heading.replaceAll('~~', '');
      final match = _heading.firstMatch(stripped);

      entries.add(KnowledgeEntry(
        id: match?.group(1) ?? stripped,
        title: match?.group(2)?.trim() ?? stripped,
        body: rest,
        isInvalidated: heading.contains('~~'),
        date: _field(rest, 'Tarih'),
        source: _field(rest, 'Kaynak'),
      ));
    }
    return entries;
  }

  static final _heading = RegExp(r'^([A-Z]{1,2}-\d+)\s*—\s*(.*)$');

  static String? _field(String body, String label) {
    final match = RegExp(
      '^- \\*\\*$label:\\*\\* (.*)\$',
      multiLine: true,
    ).firstMatch(body);
    return match?.group(1)?.trim();
  }
}
