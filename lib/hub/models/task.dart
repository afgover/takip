import '../../core/constants.dart';
import '../../core/utils.dart';
import '../frontmatter.dart';

/// Görev durumu — sözleşmede durum = klasör (SYSTEM.md §4).
enum TaskStatus {
  inbox('Yeni'),
  active('Ele alınıyor'),

  /// Top kullanıcıda: agent somut bir şey bekliyor (sözleşme 1.4).
  waiting('Seni bekliyor'),
  done('Tamamlandı');

  const TaskStatus(this.label);

  /// Ekranda gösterilen Türkçe karşılık.
  final String label;

  /// Kullanıcının bir şey yapması gereken durum — listede öne alınır.
  bool get needsUser => this == TaskStatus.waiting;

  static TaskStatus? fromPath(String path) {
    if (path.startsWith(Hub.inboxDir)) return TaskStatus.inbox;
    if (path.startsWith(Hub.activeDir)) return TaskStatus.active;
    if (path.startsWith(Hub.waitingDir)) return TaskStatus.waiting;
    if (path.startsWith(Hub.doneDir)) return TaskStatus.done;
    return null;
  }
}

/// Listede gösterilen özet — **dosya indirilmeden** klasör listesinden
/// üretilir (SYSTEM.md §4: durum klasördür, ad tarih+slug'dır). Böylece
/// bekleyenler ekranı iki istekte çizilir; içerik ancak detaya girilince
/// indirilir.
class TaskSummary {
  const TaskSummary({
    required this.path,
    required this.fileName,
    required this.sha,
    required this.status,
    required this.date,
    required this.title,
  });

  /// Klasör listesindeki kayıttan üretir; görev dosyası değilse null
  /// (README.md, `_template.md` gibi yardımcı dosyalar elenir).
  static TaskSummary? fromEntry({
    required String path,
    required String name,
    required String sha,
    required TaskStatus status,
  }) {
    if (!name.endsWith('.md')) return null;
    if (name == 'README.md' || name.startsWith('_')) return null;

    final stem = name.substring(0, name.length - 3);
    final match = _namePattern.firstMatch(stem);
    if (match == null) return null;

    return TaskSummary(
      path: path,
      fileName: name,
      sha: sha,
      status: status,
      date: DateTime.tryParse(match.group(1)!),
      title: titleFromSlug(match.group(2)!),
    );
  }

  final String path;
  final String fileName;
  final String sha;
  final TaskStatus status;

  /// Dosya adındaki tarih (`<YYYY-MM-DD>-<slug>.md`).
  final DateTime? date;

  /// Slug'dan türetilen okunabilir başlık. Gerçek başlık frontmatter'dadır ve
  /// detay açılınca görünür; liste için dosya adı yeterlidir.
  final String title;

  // Detay provider'ı bu nesneyi anahtar olarak kullanıyor: liste her
  // tazelendiğinde yeni örnek üretiliyor, değer eşitliği olmazsa aynı görev
  // için yeni bir provider açılırdı.
  @override
  bool operator ==(Object other) =>
      other is TaskSummary && other.path == path && other.sha == sha;

  @override
  int get hashCode => Object.hash(path, sha);

  static final _namePattern = RegExp(r'^(\d{4}-\d{2}-\d{2})-(.+)$');
}

/// Sözleşmedeki görev dosyasının modeli (frontmatter + gövde).
class HubTask {
  const HubTask({
    required this.id,
    required this.title,
    required this.createdBy,
    required this.created,
    required this.updated,
    required this.priority,
    required this.category,
    required this.tags,
    required this.session,
    required this.result,
    required this.status,
    required this.path,
    this.body = '',
    this.sha,
  });

  /// Hub'dan gelen dosyayı sözleşme şemasına göre okur. Eksik alanlar
  /// sözleşmedeki varsayılanlara düşer; elle düzenlenmiş bir dosya yüzünden
  /// ekran çökmez.
  factory HubTask.parse({
    required String path,
    required String content,
    required TaskStatus status,
    String? sha,
  }) {
    final fm = Frontmatter.parse(content);
    return HubTask(
      id: fm.strOr('id', 'pending'),
      title: fm.strOr('title', ''),
      createdBy: fm.strOr('created_by', 'user'),
      created: fm.strOr('created', ''),
      updated: fm.strOr('updated', ''),
      priority: fm.strOr('priority', 'normal'),
      category: fm.strOr('category', Hub.defaultCategories.first),
      tags: fm.list('tags'),
      session: fm.strOr('session', 'none'),
      result: fm.strOr('result', 'none'),
      status: status,
      path: path,
      body: fm.body,
      sha: sha,
    );
  }

  final String id; // "pending" → agent henüz ID atamadı
  final String title;
  final String createdBy; // user | agent
  final String created;
  final String updated;
  final String priority;
  final String category;
  final List<String> tags;
  final String session;
  final String result;
  final TaskStatus status;
  final String path; // hub içindeki tam yol
  final String body;

  /// Dosyanın o anki sha'sı — güncelleme yaparken gerekir (B-033).
  final String? sha;

  bool get isPending => id == 'pending';
  bool get hasResult => result.isNotEmpty && result != 'none';

  Map<String, dynamic> toFrontmatter() => {
        'id': id,
        'title': title,
        'created_by': createdBy,
        'created': created,
        'updated': updated,
        'priority': priority,
        'category': category,
        'tags': tags,
        'session': session,
        'result': result,
      };

  /// Sözleşmeye uygun dosya içeriği (frontmatter + gövde).
  String toFileContent() =>
      Frontmatter.of(toFrontmatter(), body: body).serialize();
}
