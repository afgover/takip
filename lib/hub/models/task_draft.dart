import '../../core/constants.dart';
import '../../core/utils.dart';
import '../frontmatter.dart';
import '../hub_language.dart';
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

  /// Yazılacak tam yol. Kullanıcı adı **burada** temizleniyor.
  ///
  /// R-001'in garantisi korunuyor: app hâlâ yol vermiyor: klasörü kapalı bir
  /// kümeden seçiyor ve kullanıcı adını bir **ad** olarak veriyor. Addaki
  /// `/`, `.` gibi karakterler yol dışına çıkmaya yarayabilirdi, o yüzden
  /// yalnız GitHub login'lerinde geçerli karakterler bırakılıyor; geriye bir
  /// şey kalmazsa alt klasör hiç kullanılmıyor.
  String pathFor(String fileName, {String? login}) {
    final safe = sanitizeLogin(login);
    return safe == null ? '$dir/$fileName' : '$dir/$safe/$fileName';
  }
}

/// GitHub login'i yol parçası olarak güvenli hâle getirir (sözleşme 1.15).
/// Geçerli login'ler zaten yalnız harf, rakam ve tire içerir; başka her şey
/// atılır. Geriye bir şey kalmazsa null — çağıran alt klasörsüz yazar.
String? sanitizeLogin(String? login) {
  if (login == null) return null;
  final cleaned = login.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '');
  return cleaned.isEmpty ? null : cleaned;
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
    this.authorLogin,
  });

  /// Kullanıcı girdisinden sözleşmeye uygun taslak üretir (SYSTEM.md §4, §8).
  factory TaskDraft.create({
    required String title,
    String description = '',
    String priority = 'normal',
    String category = 'gorev',
    List<String> tags = const [],
    String? author,
    String? repoSlug,
    HubLanguage lang = HubLanguage.tr,
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
      author: author,
      body: _body(lang, trimmed, description.trim(), repoSlug),
    );

    return TaskDraft(
      fileName: taskFileName(at, trimmed),
      content: task.toFileContent(),
      commitMessage: "task(pending): inbox'a eklendi (app)",
      title: trimmed,
      createdAt: at,
      // Damga gövdedeki satırla **aynı kaynaktan** basılıyor: ikisi ayrı
      // yerden gelseydi zamanla ayrışırlardı ve gövde bir hub'ı, kuyruk
      // başka bir hub'ı gösterebilirdi.
      repoSlug: repoSlug,
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
    String? author,
    HubLanguage lang = HubLanguage.tr,
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
      author: author,
      // Kaydın **nereden geldiği** gövdede açıkça yazıyor: repo, dosya yolu ve
      // alıntının altında bulunduğu başlık. Agent bunları okuyup doğrudan o
      // yere gidebilsin diye — yoksa alıntıyı bütün hub'da aramak zorunda
      // kalır.
      body: '# $title\n\n'
          '## ${lang.requestHeading}\n'
          '${trimmedNote.isEmpty ? lang.noNoteGiven : trimmedNote}\n\n'
          '## ${lang.whereHeading}\n'
          '${repoSlug == null ? '' : '- **Repo:** `$repoSlug`\n'}'
          '- **${lang.fileField}:** `$sourcePath`\n'
          '${section == null || section.isEmpty ? '' : '- **${lang.sectionField}:** $section\n'}'
          '\n## ${lang.quoteHeading}\n\n'
          '> ${quote.replaceAll('\n', '\n> ')}\n\n'
          '## ${lang.notesHeading}\n',
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
    String? author,
    HubLanguage lang = HubLanguage.tr,
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
      if (author != null) 'author': author,
      'created': isoNow(),
      'updated': isoNow(),
      'source': sourcePath,
      'quote': quote,
      'mark': mark.name,
    };

    final body = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln(trimmedNote.isEmpty ? lang.noNoteGiven : trimmedNote)
      ..writeln()
      ..writeln('## ${lang.whereHeading}')
      ..writeln('${repoSlug == null ? '' : '- **Repo:** `$repoSlug`\n'}'
          '- **${lang.fileField}:** `$sourcePath`'
          '${section == null || section.isEmpty ? '' : '\n- **${lang.sectionField}:** $section'}')
      ..writeln()
      ..writeln('## ${lang.quoteHeading}')
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
      authorLogin: author,
    );
  }

  /// `waiting/`teki bir görev için "kullanıcı yaptı" bildirimi (sözleşme 1.4).
  ///
  /// Ayrı bir görev olarak gider çünkü app asıl dosyayı taşıyamaz (R-001).
  /// Agent bunu görünce asıl görevi `waiting/`ten çıkarır ve bildirimi kapatır.
  factory TaskDraft.waitingDone(
    HubTask task, {
    String note = '',
    HubLanguage lang = HubLanguage.tr,
    String? repoSlug,
    String? author,
    DateTime? now,
  }) {
    final at = now ?? DateTime.parse(isoNow());
    final label = task.title.trim().isEmpty ? task.id : task.title.trim();
    final title = lang.waitingDoneTitle(label);
    final trimmedNote = note.trim();

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
      author: author,
      // Kullanıcının açıklaması **`## Notlar`a** yazılıyor, isteğe değil:
      // istek "beklenen iş yapıldı" olgusu, not ise kullanıcının o iş hakkında
      // söylediği şey. İkisini birleştirmek, agent'ın makinece okuduğu cümleyi
      // serbest metinle karıştırırdı (T-014).
      // Bildirim hangi hub'a ait olduğunu **kendisi** söylüyor (sözleşme
      // 1.24): yol hub-göreli, ID hub başına — ikisi de hub'ı tanımlamıyor.
      // Yanlış yere düşen bildirim ancak bu satırla teşhis edilebilir; üçü
      // gerçekten düştü (L-009 goverco, L-045).
      body: '# $title\n\n'
          '## ${lang.requestHeading}\n'
          '${lang.waitingDoneBody(task.path)}'
          '${task.isPending ? '' : ' (${task.id})'}\n\n'
          '${repoSlug == null ? '' : '- **Repo:** `$repoSlug`\n\n'}'
          '## ${lang.notesHeading}\n'
          '${trimmedNote.isEmpty ? '' : '$trimmedNote\n'}',
    );

    return TaskDraft(
      fileName: taskFileName(at, title),
      content: draft.toFileContent(),
      commitMessage: "task(pending): inbox'a eklendi (app)",
      title: title,
      createdAt: at,
      repoSlug: repoSlug,
    );
  }

  /// Seçenekli bir `waiting/` sorusuna verilen cevap (sözleşme 1.12).
  ///
  /// [TaskDraft.waitingDone] ile aynı yoldan gider — app asıl dosyayı
  /// taşıyamaz (R-001), cevap da `inbox/`a bildirim olarak düşer. Farkı
  /// gövdesi: seçim ve varsa açıklama. İkisi birden yazılır çünkü seçenek
  /// listesi cevabı makinece okunur kılar, serbest metin ise listede olmayan
  /// durumu söyleyebilmek içindir; biri diğerinin yerine geçmez.
  factory TaskDraft.waitingAnswer(
    HubTask task, {
    required List<String> selected,
    String note = '',
    HubLanguage lang = HubLanguage.tr,
    String? repoSlug,
    String? author,
    DateTime? now,
  }) {
    final at = now ?? DateTime.parse(isoNow());
    final label = task.title.trim().isEmpty ? task.id : task.title.trim();
    final title = lang.waitingAnsweredTitle(label);
    final trimmedNote = note.trim();

    final draft = HubTask(
      id: 'pending',
      title: title,
      createdBy: 'user',
      created: isoNow(),
      updated: isoNow(),
      priority: task.priority,
      category: task.category,
      tags: const ['waiting-answer'],
      session: 'none',
      result: 'none',
      status: TaskStatus.inbox,
      path: '',
      author: author,
      body: '# $title\n\n'
          '## ${lang.requestHeading}\n'
          '${lang.waitingAnsweredBody(task.path)}'
          '${task.isPending ? '' : ' (${task.id})'}\n\n'
          '${repoSlug == null ? '' : '- **Repo:** `$repoSlug`\n'}'
          '- **${lang.choiceField}:** '
          '${selected.isEmpty ? lang.noChoiceMade : selected.join(' · ')}\n'
          '${trimmedNote.isEmpty ? '' : '- **${lang.explanationField}:** $trimmedNote\n'}'
          '\n## ${lang.notesHeading}\n',
    );

    return TaskDraft(
      fileName: taskFileName(at, title),
      content: draft.toFileContent(),
      commitMessage: "task(pending): inbox'a eklendi (app)",
      title: title,
      createdAt: at,
      repoSlug: repoSlug,
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
        authorLogin: json['authorLogin'] as String?,
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

  /// Notun sahibi (sözleşme 1.15) — `notes/<login>/` alt klasörünü belirler.
  /// Kuyrukta saklanıyor ki çevrimdışı alınmış bir not, bağlantı gelince yine
  /// **kendi** sahibinin klasörüne gitsin. Görevlerde kullanılmaz: `inbox/`
  /// ortak iş kuyruğudur, bölünmesi işi gizlerdi.
  final String? authorLogin;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'content': content,
        'commitMessage': commitMessage,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        if (repoSlug != null) 'repoSlug': repoSlug,
        if (target != HubFolder.inbox) 'target': target.name,
        if (authorLogin != null) 'authorLogin': authorLogin,
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
        authorLogin: authorLogin,
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
        authorLogin: authorLogin,
      );

  /// Gövde. `Repo` satırı **normal görevde de** yazılıyor (B-139): sözleşme
  /// 1.24 bunu bildirimler için kuralmış, ama gerekçesi türe bağlı değil —
  /// yol hub-göreli, ID hub başına, ikisi de hub'ı tanımlamıyor. Yanlış hub'a
  /// düşen bir görev, bildirimlerle **tam olarak aynı sebepten** teşhis
  /// edilemiyordu (L-045).
  ///
  /// Satır kullanıcının metninden **boş satırla ayrılıyor** ve ondan sonra
  /// geliyor: `## İstek` kullanıcının yazdığı şeydir, makine okunur olgu
  /// onun içine karışmamalı (T-014'ün ayrımı).
  static String _body(
    HubLanguage lang,
    String title,
    String description,
    String? repoSlug,
  ) =>
      '# $title\n\n'
      '## ${lang.requestHeading}\n'
      '${description.isEmpty ? lang.noDescriptionGiven : description}\n'
      '${repoSlug == null ? '' : '\n- **Repo:** `$repoSlug`\n'}'
      '\n## ${lang.notesHeading}\n';
}
