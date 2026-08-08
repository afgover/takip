import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'all_tasks.dart';
import 'frontmatter.dart';
import 'hub_config.dart';
import 'hub_language.dart';
import 'hub_connections.dart';
import 'hub_sync.dart';
import 'models/task.dart';
import 'models/task_draft.dart';
import 'offline_store.dart';

/// Bir belgede işaretlenecek tek kayıt (sözleşme 1.5).
class Annotation {
  const Annotation({
    required this.quote,
    required this.mark,
    required this.title,
    required this.category,
    required this.path,
    this.sourcePath = '',
    this.repoSlug,
    this.note,
    this.author,
  });

  final String quote;
  final TaskMark mark;
  final String title;
  final String category;

  /// Kaydın kendi dosyasının yolu — silerken gerekiyor.
  final String path;

  /// İşaretin bulunduğu belge; yerel katmandan kaldırırken anahtar.
  final String sourcePath;

  /// Kaydın hangi repoda olduğu — silerken doğru hub'a gitmek için.
  final String? repoSlug;

  /// Kullanıcının kendi yazdığı metin. İşarete dokununca açılan kartta bunu
  /// görmek gerekiyor: alıntı zaten belgede duruyor, kartın asıl taşıdığı şey
  /// kullanıcının o alıntı hakkında yazdığıdır.
  final String? note;

  /// Kaydı açan kişi (sözleşme 1.15). Notlarda hep "ben"im — orada
  /// gösterilmesi gereksiz; **görevlerde** anlamlı, çünkü `tasks/` ortak.
  final String? author;
}

/// Kayıt gövdesinden kullanıcının yazdığı metni çıkarır.
///
/// İki gövde biçimi var: notlarda metin başlığın hemen altındadır (§11),
/// görevlerde istek başlığı altındadır (§4). Elle düzenlenmiş ya da tanınmayan
/// bir gövdede null döner — kart yine açılır, yalnız not satırı görünmez.
///
/// **Bütün dillerin başlıkları tanınır** (sözleşme 1.19). Hub'ın ilan ettiği
/// dille sınırlamak cazip ama yanlış: dil alanı eklenmeden önce yazılmış
/// kayıtlar, elle düzenlenmiş dosyalar ve dili sonradan değiştirilmiş hub'lar
/// var. Geniş kabulün maliyeti yok; dar kabulün maliyeti okunamayan kayıt.
String? noteTextFrom(String body) {
  final headings = HubLanguage.allRequestHeadings.join('|');
  final istek =
      RegExp('^##\\s+($headings)\\s*\$', multiLine: true).firstMatch(body);
  final String region;
  if (istek != null) {
    region = body.substring(istek.end);
  } else {
    // Başlıktan sonrası; ilk `#` satırını atla.
    final title = RegExp(r'^#\s+.*$', multiLine: true).firstMatch(body);
    region = title == null ? body : body.substring(title.end);
  }

  // Bir sonraki bölüm başlığına kadar olan kısım kullanıcının metnidir.
  final next = RegExp(r'^##\s+', multiLine: true).firstMatch(region);
  final text = (next == null ? region : region.substring(0, next.start)).trim();

  if (text.isEmpty || text == '(not girilmedi)' || text == '(açıklama girilmedi)') {
    return null;
  }
  return text;
}

/// Verilen belgeyi `source` alan kayıtlar (aktif repodan).
///
/// İşaret ayrıca saklanmıyor; kayıtlardan türüyor (K-023). Bu yüzden liste
/// **yerel kopyadan** okunuyor: senkron zaten bütün görev dosyalarını
/// indirmiş durumda, ayrı bir istek gerekmiyor.
final annotationsForProvider =
    FutureProvider.family<List<Annotation>, String>((ref, sourcePath) async {
  ref.watch(hubSyncProvider.select((s) => s.version));

  final connections = ref.watch(hubConnectionsProvider).valueOrNull;
  final active = connections?.active ?? ref.watch(hubConfigProvider).value;
  if (active == null) return const [];

  return annotationsFrom(active, sourcePath);
});

/// [annotationsForProvider]'ın saf çekirdeği — testten doğrudan çağrılabilir.
Future<List<Annotation>> annotationsFrom(
  HubConfig connection,
  String sourcePath,
) async {
  final store = OfflineStore(connection.slug);
  final tree = await store.readTree();
  if (tree == null) return const [];

  final found = <Annotation>[];
  for (final entry in tree) {
    if (!entry.isFile) continue;
    // Görevler **ve** notlar işaret taşır (sözleşme 1.9). Notlar bilinçli
    // olarak `isTaskPath` dışında: iş kuyruğuna girmemeleri gerekiyor, ama
    // belgede görünmeleri gerekiyor.
    if (!isTaskPath(entry.path) && !isNotePath(entry.path)) continue;
    if (!isMyNote(entry.path, connection.login)) continue;

    final doc = await store.readDoc(entry.path);
    if (doc == null) continue;

    final fm = Frontmatter.parse(doc.content);
    if (fm.str('source') != sourcePath) continue;

    final quote = fm.str('quote');
    final mark = TaskMark.parse(fm.str('mark'));
    // Üçü birlikte anlamlı: eksikse işaret çizilmez, kayıt yine listede kalır.
    if (quote == null || quote.isEmpty || mark == null) continue;

    found.add(Annotation(
      quote: quote,
      mark: mark,
      title: fm.str('title') ?? '',
      category: fm.str('category') ?? (isNotePath(entry.path) ? 'not' : 'gorev'),
      path: entry.path,
      sourcePath: sourcePath,
      repoSlug: connection.slug,
      note: noteTextFrom(fm.body),
      author: fm.str('author'),
    ));
  }
  return found;
}

/// **Aktif** repodaki bütün işaretler, tek listede (sözleşme 1.13).
///
/// Yer iminin işe yaraması bu listeye bağlı: "burayı sonra bulayım" ancak
/// sonradan bulunabiliyorsa anlamlıdır. Yalnız yer imlerini değil her işareti
/// topluyor — kullanıcı hangi renkle işaretlediğini hatırlamak zorunda kalmasın.
///
/// **Neden aktif repo, bütün repolar değil (1.12 → 1.13):** ilk hâlinde liste
/// bütün bağlantıları birleştiriyordu ve kullanımın ilk saatinde ters teptiği
/// görüldü — işaret bir belgedeki *yeri* hatırlatır, belge de bir projeye
/// aittir; hepsi tek listede olunca ekran bağlam yığınına dönüşüyor. Uygulamanın
/// geri kalanı zaten aktif repoyla çalışıyor (üstteki repo şeridi); işaretler
/// bunun dışında kalmıştı. Başka projenin işaretlerine bakmak için repo
/// değiştirilir — liste kendiliğinden tazelenir.
///
/// Bekleyenler bilinçli olarak istisna: orada iş "hangi projede olursa olsun
/// bende bekleyen ne var" sorusuna cevap verir (B-067).
///
/// Yerel kopyadan okunuyor (ağ yok): senkron zaten bütün repoların
/// `hub/**.md`'sini indiriyor.
final repoAnnotationsProvider = FutureProvider<List<Annotation>>((ref) async {
  ref.watch(hubSyncProvider.select((s) => s.version));

  final state = ref.watch(hubConnectionsProvider).valueOrNull;
  // Bağlantı listesi henüz yüklenmediyse aktif yapılandırmaya düşülür.
  final active = state?.active ?? ref.watch(hubConfigProvider).value;
  if (active == null) return const [];

  final found = await annotationsIn(active);
  // En yeni üstte: dosya adı `<YYYY-MM-DD>-<slug>.md`, yani ada göre tersten
  // sıralamak tarihe göre sıralamak demek (sözleşme §4).
  found.sort((a, b) => b.path.compareTo(a.path));
  return found;
});

/// Bir bağlantıdaki bütün işaret kayıtları — [repoAnnotationsProvider]'ın
/// çekirdeği.
///
/// `annotationsFrom` tek bir **belgeye** bağlı kayıtları verir; bu ise repodaki
/// hepsini, her biri kendi `source`'uyla. Listede kaydın hangi belgeye ait
/// olduğu satır başına değişir, o yüzden `sourcePath` dışarıdan verilemez.
Future<List<Annotation>> annotationsIn(HubConfig connection) async {
  final store = OfflineStore(connection.slug);
  final tree = await store.readTree();
  if (tree == null) return [];

  final found = <Annotation>[];
  for (final entry in tree) {
    if (!entry.isFile) continue;
    if (!isTaskPath(entry.path) && !isNotePath(entry.path)) continue;
    if (!isMyNote(entry.path, connection.login)) continue;

    final doc = await store.readDoc(entry.path);
    if (doc == null) continue;

    final fm = Frontmatter.parse(doc.content);
    final source = fm.str('source');
    final quote = fm.str('quote');
    final mark = TaskMark.parse(fm.str('mark'));
    // Üçü birlikte anlamlı (§4): biri eksikse bu bir işaret kaydı değildir.
    if (source == null || quote == null || quote.isEmpty || mark == null) {
      continue;
    }

    found.add(Annotation(
      quote: quote,
      mark: mark,
      title: fm.str('title') ?? '',
      category: fm.str('category') ?? (isNotePath(entry.path) ? 'not' : 'gorev'),
      path: entry.path,
      sourcePath: source,
      repoSlug: connection.slug,
      note: noteTextFrom(fm.body),
      author: fm.str('author'),
    ));
  }
  return found;
}

/// Bu not **bana mı ait**? (sözleşme 1.16)
///
/// Notlar kişiseldir: paylaşmak isteyen görev açar. Takımda herkesin notunu
/// herkesin belgesinde işaretli görmek, notu "kendine yazılan şey" olmaktan
/// çıkarır — 1.9'da tam da bunun için `notes/` ayrılmıştı (K-029).
///
/// Görev yolları her zaman geçer: `tasks/` ortak iş alanıdır.
///
/// İki durumda **gizleme yapılmaz**, ikisi de bilerek:
/// - Kimliğimiz bilinmiyorsa (login null): süzmek her şeyi gizlerdi.
/// - Not düz `notes/` altındaysa (1.15 öncesi): o dosyalar ayrım yokken
///   yazıldı, sahibi bilinmiyor. Gizlemek, var olan notları sessizce yok
///   ederdi — yanlış tarafta hata yapmak bu.
bool isMyNote(String path, String? login) {
  if (!isNotePath(path)) return true;
  final safe = sanitizeLogin(login);
  if (safe == null) return true;

  final rest = path.substring('${Hub.notesDir}/'.length);
  final slash = rest.indexOf('/');
  if (slash < 0) return true; // düz yerleşim — 1.15 öncesi
  return rest.substring(0, slash) == safe;
}

/// Bir bağlantının hub'ındaki sözleşme sürümü (§10).
///
/// Yerel kopyadan okunuyor; ayrı istek gerekmiyor çünkü `SYSTEM.md` zaten
/// senkronun indirdiği dosyalardan biri.
Future<String?> contractVersionOf(HubConfig connection) async {
  final doc = await OfflineStore(connection.slug).readDoc(Hub.systemFile);
  if (doc == null) return null;
  // İki yazım da tanınır (v1.21): İngilizce hub'ın kopyası
  // `**Contract version:**` yazar. Bkz. [languageCodeIn], aynı gerekçe.
  final match =
      RegExp(r'\*\*(?:Sözleşme sürümü|Contract version):\*\*\s*([0-9]+\.[0-9]+)')
          .firstMatch(doc.content);
  return match?.group(1);
}

/// slug → sözleşme sürümü. Okunamayanlar listede yer almaz.
final contractVersionsProvider =
    FutureProvider<Map<String, String>>((ref) async {
  ref.watch(hubSyncProvider.select((s) => s.version));
  final state = ref.watch(hubConnectionsProvider).valueOrNull;
  if (state == null) return const {};

  final versions = <String, String>{};
  for (final connection in state.connections) {
    final version = await contractVersionOf(connection);
    if (version != null) versions[connection.slug] = version;
  }
  return versions;
});

/// Sürüm ana kopyadan geride mi? Karşılaştırma sayısal (1.10 > 1.9).
/// [current] yalnız test için: karşılaştırma mantığı, uygulamanın o anki
/// sürümünden bağımsız olarak sınanabilsin diye. Üretimde hep varsayılan
/// kullanılır.
bool isContractStale(String version, {String current = Hub.contractVersion}) {
  int major(String v) => int.tryParse(v.split('.').first) ?? 0;
  int minor(String v) =>
      int.tryParse(v.split('.').skip(1).firstOrNull ?? '0') ?? 0;

  if (major(version) != major(current)) return major(version) < major(current);
  return minor(version) < minor(current);
}

/// Henüz senkronlanmamış, **az önce oluşturulmuş** işaretler.
///
/// Kayıt hub'a gidiyor ama yerel kopya onu ancak bir sonraki senkronda
/// görüyor; o ana kadar işaret çizilmiyordu ve kullanıcı "işaretledim ama
/// görünmedi" diyordu (L-024). Bu katman aradaki boşluğu dolduruyor: kayıt
/// başarıyla gönderildiği anda işaret ekranda beliriyor, senkron yetişince
/// aynı işaret depodan gelmeye başlıyor.
///
/// Çift çizim olmuyor: `markAnnotations` çakışan aralıkları eliyor.
class FreshAnnotations extends Notifier<Map<String, List<Annotation>>> {
  @override
  Map<String, List<Annotation>> build() {
    // Senkron tamamlandığında bu katmana gerek kalmaz; depodan gelen kayıt
    // artık aynı işareti taşıyor.
    ref.listen<int>(hubSyncProvider.select((s) => s.version), (previous, next) {
      if (previous != null && previous != next && state.isNotEmpty) {
        state = const {};
      }
    });
    return const {};
  }

  void add(String sourcePath, Annotation annotation) {
    state = {
      ...state,
      sourcePath: [...(state[sourcePath] ?? const []), annotation],
    };
  }

  /// Gönderim kalıcı olarak başarısız olduysa iyimser işareti geri alır.
  void remove(String sourcePath, Annotation annotation) {
    final current = state[sourcePath];
    if (current == null) return;
    state = {
      ...state,
      sourcePath: current.where((a) => a.quote != annotation.quote).toList(),
    };
  }
}

final freshAnnotationsProvider =
    NotifierProvider<FreshAnnotations, Map<String, List<Annotation>>>(
  FreshAnnotations.new,
);
