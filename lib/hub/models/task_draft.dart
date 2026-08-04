import '../../core/constants.dart';
import '../../core/utils.dart';
import '../frontmatter.dart';
import 'task.dart';

/// Taslağın hub'da hangi klasöre gideceği.
///
/// App'in yazabildiği **tek iki** klasör (R-001, sözleşme 1.9). Serbest yol
/// yerine kapalı bir küme olması bilinçli: app'in başka bir klasöre yazması
/// tip düzeyinde imkânsız kalıyor.
enum HubFolder {
  inbox(Hub.inboxDir),
  notes(Hub.notesDir);

  const HubFolder(this.dir);
  final String dir;

  static HubFolder parse(String? name) =>
      name == notes.name ? notes : inbox;
}

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
    this.target = HubFolder.inbox,
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
    String? section,
    String? repoSlug,
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
      // Kaydın **nereden geldiği** gövdede açıkça yazıyor: repo, dosya yolu ve
      // alıntının altında bulunduğu başlık. Agent bunları okuyup doğrudan o
      // yere gidebilsin diye — yoksa alıntıyı bütün hub'da aramak zorunda
      // kalır.
      body: '# $title\n\n'
          '## İstek\n'
          '${trimmedNote.isEmpty ? '(not girilmedi)' : trimmedNote}\n\n'
          '## Nerede\n'
          '${repoSlug == null ? '' : '- **Repo:** `$repoSlug`\n'}'
          '- **Dosya:** `$sourcePath`\n'
          '${section == null || section.isEmpty ? '' : '- **Bölüm:** $section\n'}'
          '\n## Alıntı\n\n'
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

  /// Kullanıcının **kendisi için** aldığı not (sözleşme 1.9, §11).
  ///
  /// Görev değil: `notes/`a yazılır, ID almaz, bekleyen işlerde görünmez.
  /// Ayrım kullanıcının niyeti — görev "sen şunu yap", not "ben bunu
  /// hatırlayayım". İkisi aynı klasöre konunca kullanıcının kendine yazdığı
  /// her satır agent'ın iş kuyruğuna düşüyordu.
  factory TaskDraft.note({
    required String quote,
    required String sourcePath,
    String note = '',
    TaskMark mark = TaskMark.comment,
    String? section,
    String? repoSlug,
    DateTime? now,
  }) {
    final at = now ?? DateTime.parse(isoNow());
    final trimmedNote = note.trim();
    final title = _titleFromQuote(quote);

    // Notun frontmatter'ı görev şemasının **alt kümesi**: durum, öncelik,
    // sonuç gibi alanlar yok çünkü notun bir işleyişi yok. `mark` parametreli:
    // notsuz bir hızlı işaret (sarı/kırmızı) göreve DEĞİL nota düştüğünde kendi
    // rengini korusun diye — varsayılan yeşil (comment), "Not ekle" yolundan gelen.
    final fields = {
      'title': title,
      'created_by': 'user',
      'created': isoNow(),
      'updated': isoNow(),
      'source': sourcePath,
      'quote': quote,
      'mark': mark.name,
    };

    final body = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln(trimmedNote.isEmpty ? '(not girilmedi)' : trimmedNote)
      ..writeln()
      ..writeln('## Nerede')
      ..writeln('${repoSlug == null ? '' : '- **Repo:** `$repoSlug`\n'}'
          '- **Dosya:** `$sourcePath`'
          '${section == null || section.isEmpty ? '' : '\n- **Bölüm:** $section'}')
      ..writeln()
      ..writeln('## Alıntı')
      ..writeln()
      ..writeln('> ${quote.replaceAll('\n', '\n> ')}');

    return TaskDraft(
      fileName: taskFileName(at, title),
      content: Frontmatter.of(fields, body: body.toString()).serialize(),
      commitMessage: 'note: eklendi (app)',
      title: title,
      createdAt: at,
      repoSlug: repoSlug,
      target: HubFolder.notes,
    );
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
        target: HubFolder.parse(json['target'] as String?),
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

  /// Hedef klasör. Kuyrukta da saklanıyor: çevrimdışı alınan bir not, bağlantı
  /// gelince yine `notes/`a gitmeli — göreve dönüşmemeli.
  final HubFolder target;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'content': content,
        'commitMessage': commitMessage,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        if (repoSlug != null) 'repoSlug': repoSlug,
        if (target != HubFolder.inbox) 'target': target.name,
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
        target: target,
      );

  /// Kuyruğa alınırken hedef repoyu damgalar.
  TaskDraft forRepo(String slug) => TaskDraft(
        fileName: fileName,
        content: content,
        commitMessage: commitMessage,
        title: title,
        createdAt: createdAt,
        repoSlug: slug,
        target: target,
      );

  static String _body(String title, String description) => '# $title\n\n'
      '## İstek\n'
      '${description.isEmpty ? '(açıklama girilmedi)' : description}\n\n'
      '## Notlar\n';
}
