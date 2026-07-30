/// Görev durumu — sözleşmede durum = klasör (SYSTEM.md §4).
enum TaskStatus { inbox, active, done }

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
  });

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
}
