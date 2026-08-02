import '../../core/utils.dart';
import 'task.dart';

/// Gönderilmeye hazır görev — dosya adı, içerik ve commit mesajı birlikte.
///
/// Ayrı bir tip olmasının nedeni B-032: ağ yokken görev **taslak olarak**
/// saklanıp sonra gönderilecek. O yüzden taslak, üretildiği andaki hâliyle
/// (tarih, slug, frontmatter) diske yazılabilir olmalı; sonradan yeniden
/// üretilirse tarih kayar ve kullanıcının gördüğü görev başka bir dosya olur.
class TaskDraft {
  const TaskDraft({
    required this.fileName,
    required this.content,
    required this.commitMessage,
    required this.title,
    required this.createdAt,
    this.repoSlug,
  });

  /// Kullanıcı girdisinden sözleşmeye uygun taslak üretir (SYSTEM.md §4, §8).
  factory TaskDraft.create({
    required String title,
    String description = '',
    String priority = 'normal',
    String category = 'gorev',
    List<String> tags = const [],
    DateTime? now,
  }) {
    final at = now ?? DateTime.parse(isoNow());
    final trimmed = title.trim();
    final task = HubTask(
      // ID'yi agent atar (SYSTEM.md §4); app numara uydurmaz.
      id: 'pending',
      title: trimmed,
      createdBy: 'user',
      created: isoNow(),
      updated: isoNow(),
      priority: priority,
      category: category.trim(),
      tags: tags,
      session: 'none',
      result: 'none',
      status: TaskStatus.inbox,
      path: '',
      body: _body(trimmed, description.trim()),
    );

    return TaskDraft(
      fileName: taskFileName(at, trimmed),
      content: task.toFileContent(),
      commitMessage: "task(pending): inbox'a eklendi (app)",
      title: trimmed,
      createdAt: at,
    );
  }

  /// Bir belgeden seçilen metinden üretilen kayıt (sözleşme 1.5).
  ///
  /// Görev, yorum, düzeltme, tartışma — hepsi aynı yoldan gider ve `category`
  /// ile ayrılır. `source`/`quote`/`mark` alanları sayesinde uygulama belgeyi
  /// bir daha açtığında işareti bu kayıttan çizer; işaret ayrıca saklanmaz.
  factory TaskDraft.fromSelection({
    required String quote,
    required String sourcePath,
    required String kind,
    required TaskMark mark,
    String note = '',
    String priority = 'normal',
    DateTime? now,
  }) {
    final at = now ?? DateTime.parse(isoNow());
    final trimmedNote = note.trim();
    // Başlık alıntıdan türer: kullanıcı ayrıca başlık yazmak zorunda kalmasın,
    // ama liste okunur olsun diye kısaltılır.
    final title = _titleFromQuote(quote);

    final task = HubTask(
      id: 'pending',
      title: title,
      createdBy: 'user',
      created: isoNow(),
      updated: isoNow(),
      priority: priority,
      category: kind,
      tags: const ['secim'],
      session: 'none',
      result: 'none',
      status: TaskStatus.inbox,
      path: '',
      source: sourcePath,
      quote: quote,
      mark: mark,
      body: '# $title\n\n'
          '## İstek\n'
          '${trimmedNote.isEmpty ? '(not girilmedi)' : trimmedNote}\n\n'
          '## Alıntı\n'
          '`$sourcePath` belgesinden:\n\n'
          '> ${quote.replaceAll('\n', '\n> ')}\n\n'
          '## Notlar\n',
    );

    return TaskDraft(
      fileName: taskFileName(at, title),
      content: task.toFileContent(),
      commitMessage: "task(pending): inbox'a eklendi (app)",
      title: title,
      createdAt: at,
    );
  }

  /// Alıntının ilk anlamlı parçası — dosya adı ve liste başlığı için.
  static String _titleFromQuote(String quote) {
    final flat = quote.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= 60) return flat;
    final cut = flat.substring(0, 60);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > 20 ? cut.substring(0, lastSpace) : cut}…';
  }

  /// `waiting/`teki bir görev için "kullanıcı yaptı" bildirimi (sözleşme 1.4).
  ///
  /// Ayrı bir görev olarak gider çünkü app asıl dosyayı taşıyamaz (R-001).
  /// Agent bunu görünce asıl görevi `waiting/`ten çıkarır ve bildirimi kapatır.
  factory TaskDraft.waitingDone(HubTask task, {DateTime? now}) {
    final at = now ?? DateTime.parse(isoNow());
    final label = task.title.trim().isEmpty ? task.id : task.title.trim();
    final title = '$label — yapıldı';

    final draft = HubTask(
      id: 'pending',
      title: title,
      createdBy: 'user',
      created: isoNow(),
      updated: isoNow(),
      priority: task.priority,
      category: task.category,
      tags: const ['waiting-done'],
      session: 'none',
      result: 'none',
      status: TaskStatus.inbox,
      path: '',
      body: '# $title\n\n'
          '## İstek\n'
          '`${task.path}`${task.isPending ? '' : ' (${task.id})'} görevinde '
          'beklenen iş yapıldı. Asıl görevi `waiting/`ten çıkarabilirsin.\n\n'
          '## Notlar\n',
    );

    return TaskDraft(
      fileName: taskFileName(at, title),
      content: draft.toFileContent(),
      commitMessage: "task(pending): inbox'a eklendi (app)",
      title: title,
      createdAt: at,
    );
  }

  factory TaskDraft.fromJson(Map<String, dynamic> json) => TaskDraft(
        fileName: json['fileName'] as String,
        content: json['content'] as String,
        commitMessage: json['commitMessage'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        repoSlug: json['repoSlug'] as String?,
      );

  final String fileName;
  final String content;
  final String commitMessage;

  /// Kuyrukta beklerken listede göstermek için.
  final String title;
  final DateTime createdAt;

  /// Taslağın **hangi repoya** ait olduğu (`owner/ad`), kuyruğa alınırken
  /// damgalanır (T-003).
  ///
  /// Çoklu repoda bu alan olmadan kuyruk yanlış hedefe boşalırdı: çevrimdışıyken
  /// A reposuna yazılan görev, kullanıcı B'ye geçtikten sonra bağlantı gelince
  /// B'ye giderdi. Görevin yanlış projeye düşmesi sessiz bir veri hatasıdır —
  /// kullanıcı kaybolduğunu bile fark etmez, yalnızca "eklemiştim ama yok" der.
  ///
  /// T-003 öncesi kuyruğa girmiş taslaklarda null olabilir; o kayıtlar aktif
  /// repoya ait sayılır (tek repo varken kuyruğa girmişlerdir).
  final String? repoSlug;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'content': content,
        'commitMessage': commitMessage,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        if (repoSlug != null) 'repoSlug': repoSlug,
      };

  /// Aynı taslağın farklı dosya adıyla kopyası — ad çakışmasında kullanılır
  /// (B-033).
  TaskDraft withFileName(String name) => TaskDraft(
        fileName: name,
        content: content,
        commitMessage: commitMessage,
        title: title,
        createdAt: createdAt,
        repoSlug: repoSlug,
      );

  /// Kuyruğa alınırken hedef repoyu damgalar.
  TaskDraft forRepo(String slug) => TaskDraft(
        fileName: fileName,
        content: content,
        commitMessage: commitMessage,
        title: title,
        createdAt: createdAt,
        repoSlug: slug,
      );

  static String _body(String title, String description) => '# $title\n\n'
      '## İstek\n'
      '${description.isEmpty ? '(açıklama girilmedi)' : description}\n\n'
      '## Notlar\n';
}
