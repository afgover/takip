import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../github/contents_api.dart';
import '../github/trees_api.dart';
import 'frontmatter.dart';
import 'hub_sync.dart';
import 'hub_watcher.dart';
import 'models/hub_doc.dart';
import 'offline_store.dart';

/// Hub tarayıcısının veri katmanı (Faz 4) — SYSTEM.md §9 kategorileri.
///
/// Listeler tek bir özyinelemeli ağaç isteğinden çıkarılır; klasör klasör
/// gezilmez. İçerik ancak bir belge açılınca indirilir.
class BrowseRepo {
  BrowseRepo(this._trees, this._contents, [this._store]);

  final TreesApi _trees;
  final ContentsApi _contents;

  /// Cihazdaki kopya (B-057). Varsa ağ hiç kullanılmaz — tarayıcı
  /// çevrimdışıyken de, hiç açılmamış belgeler dahil, tam çalışır.
  final OfflineStore? _store;

  /// Yerel kopya güncel tutuluyor (senkron `headSha` değişince koşuyor), bu
  /// yüzden önce oraya bakılır. Kopya yoksa (ilk açılış, senkron bitmeden)
  /// ağa düşülür — davranış eskisi gibi.
  Future<List<TreeEntry>> _tree() async {
    final stored = await _store?.readTree();
    if (stored != null && stored.isNotEmpty) return stored;
    return _trees.recursive();
  }

  /// `sessions/<tarih>-<slug>/session.md`
  Future<List<HubDoc>> sessions() async {
    final docs = (await _tree())
        .where((e) => e.isFile)
        .where((e) =>
            e.path.startsWith('${Hub.sessionsDir}/') &&
            e.path.endsWith('/session.md'))
        .map((e) => HubDoc.fromDatedPath(e.path, sha: e.sha))
        .toList();
    return _newestFirst(docs);
  }

  /// `artifacts/**.md` — `reference/` altındakiler oturuma bağlı değildir.
  Future<List<HubDoc>> artifacts() async {
    final docs = (await _tree())
        .where((e) => e.isFile)
        .where((e) =>
            e.path.startsWith('${Hub.artifactsDir}/') &&
            e.path.endsWith('.md') &&
            !e.path.endsWith('/README.md'))
        .map((e) => HubDoc.fromDatedPath(e.path, sha: e.sha))
        .toList();
    return _newestFirst(docs);
  }

  /// Artifact'ın türü ve gerçek başlığı frontmatter'dadır; liste ağaçtan
  /// çizildikten sonra bunlar tek tek okunur (B-042).
  ///
  /// Sınırın gerekçesi başta "kayıt sayısı kadar **istek**"ti. B-057'den beri
  /// hub'ın tamamı cihazda duruyor ve bu okumalar yerelden geliyor — yani
  /// maliyet ağ değil, yalnız ayrıştırma. Sınır bu yüzden yükseltildi:
  /// arşiv taşımaları (örn. project-taskr'ın 35 belgesi) listeyi bir anda
  /// büyütebiliyor ve 40'ta kalsaydı yeni artifact'lar başlıksız listelenirdi.
  /// Sıfır yapılmadı: ilk senkron bitmeden liste açılırsa okumalar yine ağa
  /// gider, o durumda bir üst sınır gerekiyor.
  static const artifactMetadataLimit = 150;

  Future<List<HubDoc>> artifactsWithMetadata() async {
    final docs = await artifacts();
    final detailed = <HubDoc>[];

    for (var i = 0; i < docs.length; i++) {
      if (i >= artifactMetadataLimit) {
        detailed.add(docs[i]);
        continue;
      }
      try {
        final fm = Frontmatter.parse(await readDoc(docs[i].path));
        detailed.add(docs[i].copyWith(
          title: fm.str('title'),
          subtitle: fm.str('type'),
        ));
      } catch (_) {
        detailed.add(docs[i]); // okunamayan artifact listeden düşmesin
      }
    }
    return detailed;
  }

  Future<List<KnowledgeEntry>> knowledge(KnowledgeFile file) async =>
      KnowledgeEntry.parseFile(await readDoc(file.path));

  Future<List<KnowledgeEntry>> security() async =>
      KnowledgeEntry.parseFile(await readDoc(Hub.securityFile));

  Future<String> readDoc(String path) async {
    final stored = await _store?.readDoc(path);
    if (stored != null) return stored.content;
    return (await _contents.getFile(path)).content;
  }
}

/// Bilgi tabanındaki üç canlı dosya (SYSTEM.md §5).
enum KnowledgeFile {
  rules('Kurallar', 'rules.md'),
  skills('Skiller', 'skills.md'),
  lessons('Dersler', 'lessons.md');

  const KnowledgeFile(this.label, this.fileName);

  final String label;
  final String fileName;

  String get path => '${Hub.knowledgeDir}/$fileName';
}

List<HubDoc> _newestFirst(List<HubDoc> docs) {
  docs.sort((a, b) {
    if (a.date == null && b.date == null) return a.path.compareTo(b.path);
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    final byDate = b.date!.compareTo(a.date!);
    return byDate != 0 ? byDate : a.path.compareTo(b.path);
  });
  return docs;
}

final browseRepoProvider = Provider<BrowseRepo>(
  (ref) => BrowseRepo(
    ref.watch(treesApiProvider),
    ref.watch(contentsApiProvider),
    ref.watch(offlineStoreProvider),
  ),
);

/// Tarayıcı sağlayıcılarının ortak tazelenme sinyali.
///
/// İki şeyi birlikte izler: yoklamanın gördüğü hub sürümü (`headSha`) ve
/// senkronun tamamlanma sayacı (`version`). İkincisi olmadan, değişiklik
/// görüldüğü anda okunan yerel kopya henüz eski olurdu ve ekran senkron
/// bitince kendiliğinden tazelenmezdi.
void _watchHubVersion(Ref ref) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  ref.watch(hubSyncProvider.select((s) => s.version));
}

final sessionsProvider = FutureProvider<List<HubDoc>>((ref) {
  _watchHubVersion(ref);
  return ref.watch(browseRepoProvider).sessions();
});

final artifactsProvider = FutureProvider<List<HubDoc>>((ref) {
  _watchHubVersion(ref);
  return ref.watch(browseRepoProvider).artifactsWithMetadata();
});

/// Güvenlik logundaki kayıtlar (sözleşme 1.10 §12).
///
/// Ayrıştırıcı `knowledge/` ile ortak: ikisi de "`## ID — başlık` + alan
/// satırları" biçiminde canlı dosyalar. Ayrı bir çözümleyici yazmak aynı
/// biçimin iki yerde ayrışmasına yol açardı.
final securityProvider = FutureProvider<List<KnowledgeEntry>>((ref) {
  _watchHubVersion(ref);
  return ref.watch(browseRepoProvider).security();
});

final knowledgeProvider =
    FutureProvider.family<List<KnowledgeEntry>, KnowledgeFile>((ref, file) {
  _watchHubVersion(ref);
  return ref.watch(browseRepoProvider).knowledge(file);
});

/// Tek belgenin ham içeriği (markdown görüntüleyici).
final docContentProvider =
    FutureProvider.autoDispose.family<String, String>((ref, path) {
  _watchHubVersion(ref);
  return ref.watch(browseRepoProvider).readDoc(path);
});
