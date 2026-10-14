import '../frontmatter.dart';

/// Yorum ve atama olayı (sözleşme 1.37 §4): inbox'a yazılan ama **görev
/// olmayan** kayıt. Listede görünmez; hedef görevin üstüne bindirilir, ajan
/// onu hedefe işleyip `tasks/events/`e arşivler.
enum TaskEventKind {
  comment,
  assign;

  /// Türü taşıyan etiket — bekleyen soru cevabının `waiting-answer`
  /// etiketiyle aynı desen.
  String get tag => name;

  static TaskEventKind? fromTags(List<String> tags) {
    for (final kind in values) {
      if (tags.contains(kind.tag)) return kind;
    }
    return null;
  }
}

class TaskEvent {
  const TaskEvent({
    required this.kind,
    required this.target,
    required this.path,
    this.author,
    this.created = '',
    this.assignee,
    this.text = '',
  });

  final TaskEventKind kind;

  /// Hedef görevin dosya adı (klasörden bağımsız).
  final String target;
  final String path;
  final String? author;

  /// ISO 8601, UTC. Aynı göreve birden çok atama varsa en yenisi geçerli.
  final String created;

  /// Atama olayında işin verildiği kişi.
  final String? assignee;

  /// Yorum metni.
  final String text;

  /// Dosya bir olaysa onu döndürür; değilse ya da hedefi yazılmamışsa null
  /// (hedefsiz olayı hiçbir göreve bağlayamayız — sıradan inbox kaydı kalır).
  static TaskEvent? parse(String path, String content) {
    final fm = Frontmatter.parse(content);
    final kind = TaskEventKind.fromTags(fm.list('tags'));
    final target = fm.str('target');
    if (kind == null || target == null || target.trim().isEmpty) return null;
    return TaskEvent(
      kind: kind,
      target: target.trim(),
      path: path,
      author: fm.str('author'),
      created: fm.strOr('created', ''),
      assignee: fm.str('assignee'),
      text: kind == TaskEventKind.comment ? sectionText(fm.body, _commentHeadings) : '',
    );
  }
}

/// Bir görevin yorum akışındaki tek giriş.
class TaskComment {
  const TaskComment({
    required this.at,
    required this.text,
    this.author,
    this.pending = false,
  });

  /// UTC zaman (sözleşmenin zaman kuralı: hub'da her saat UTC).
  final DateTime? at;
  final String? author;
  final String text;

  /// Ajan henüz hedef dosyaya işlemedi; inbox'taki olaydan okunuyor.
  final bool pending;

  factory TaskComment.fromEvent(TaskEvent e) => TaskComment(
        at: DateTime.tryParse(e.created)?.toUtc(),
        author: e.author,
        text: e.text,
        pending: true,
      );
}

const _commentHeadings = {'Yorum', 'Comment'};
const _commentsHeadings = {'Yorumlar', 'Comments'};

/// `## <başlık>` bölümünün metni (bir sonraki `## `e kadar). Bölüm yoksa
/// gövdenin `#` başlığı dışındaki kısmı — elle yazılmış olay da okunsun.
String sectionText(String body, Set<String> headings) {
  final lines = body.split('\n');
  final start = lines.indexWhere(
      (l) => l.startsWith('## ') && headings.contains(l.substring(3).trim()));
  if (start < 0) {
    return lines.where((l) => !l.startsWith('# ')).join('\n').trim();
  }
  final out = <String>[];
  for (final l in lines.skip(start + 1)) {
    if (l.startsWith('## ')) break;
    out.add(l);
  }
  return out.join('\n').trim();
}

final _entryHeading = RegExp(r'^### \[(\d{4}-\d{2}-\d{2}) (\d{2}):(\d{2})Z?\]\s*(?:@(\S+))?');

/// Görev gövdesindeki işlenmiş yorumlar (`## Yorumlar` / `## Comments`,
/// girişler `### [YYYY-MM-DD HH:MM] @kişi`). Saat UTC okunur.
List<TaskComment> parseComments(String body) {
  final lines = body.split('\n');
  final start = lines.indexWhere(
      (l) => l.startsWith('## ') && _commentsHeadings.contains(l.substring(3).trim()));
  if (start < 0) return const [];

  final comments = <TaskComment>[];
  DateTime? at;
  String? author;
  var buffer = <String>[];
  var open = false;

  void flush() {
    if (!open) return;
    final text = buffer.join('\n').trim();
    if (text.isNotEmpty) {
      comments.add(TaskComment(at: at, author: author, text: text));
    }
  }

  for (final l in lines.skip(start + 1)) {
    if (l.startsWith('## ')) break;
    final m = _entryHeading.firstMatch(l);
    if (m != null) {
      flush();
      at = DateTime.tryParse('${m[1]}T${m[2]}:${m[3]}:00Z');
      author = m[4];
      buffer = [];
      open = true;
    } else if (open) {
      buffer.add(l);
    }
  }
  flush();
  return comments;
}

/// Bir görev dosyasında kaç işlenmiş yorum var — liste satırı için ucuz sayım.
int countComments(String body) => parseComments(body).length;
