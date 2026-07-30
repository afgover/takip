import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../github/contents_api.dart';
import '../github/trees_api.dart';
import 'frontmatter.dart';
import 'hub_watcher.dart';
import 'models/hub_doc.dart';

/// Hub tarayıcısının veri katmanı (Faz 4) — SYSTEM.md §9 kategorileri.
///
/// Listeler tek bir özyinelemeli ağaç isteğinden çıkarılır; klasör klasör
/// gezilmez. İçerik ancak bir belge açılınca indirilir.
class BrowseRepo {
  BrowseRepo(this._trees, this._contents);

  final TreesApi _trees;
  final ContentsApi _contents;

  Future<List<TreeEntry>> _tree() => _trees.recursive();

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
  /// Bu, kayıt sayısı kadar istek demek. Artifact'lar yavaş biriktiği ve
  /// ETag'li önbellek ikinci ziyareti bedava yaptığı için kabul edildi;
  /// yine de üst sınır konuldu, ötesi türsüz listelenir.
  static const artifactMetadataLimit = 40;

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

  Future<String> readDoc(String path) async =>
      (await _contents.getFile(path)).content;
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
  ),
);

/// Aşağıdaki listeler yoklamanın sürümünü izler: hub değişince tazelenir.
final sessionsProvider = FutureProvider<List<HubDoc>>((ref) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  return ref.watch(browseRepoProvider).sessions();
});

final artifactsProvider = FutureProvider<List<HubDoc>>((ref) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  return ref.watch(browseRepoProvider).artifactsWithMetadata();
});

final knowledgeProvider =
    FutureProvider.family<List<KnowledgeEntry>, KnowledgeFile>((ref, file) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  return ref.watch(browseRepoProvider).knowledge(file);
});

/// Tek belgenin ham içeriği (markdown görüntüleyici).
final docContentProvider =
    FutureProvider.autoDispose.family<String, String>((ref, path) {
  ref.watch(hubWatcherProvider.select((s) => s.headSha));
  return ref.watch(browseRepoProvider).readDoc(path);
});
