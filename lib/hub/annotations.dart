import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'all_tasks.dart';
import 'frontmatter.dart';
import 'hub_config.dart';
import 'hub_connections.dart';
import 'hub_sync.dart';
import 'models/task.dart';
import 'offline_store.dart';

/// Bir belgede işaretlenecek tek kayıt (sözleşme 1.5).
class Annotation {
  const Annotation({
    required this.quote,
    required this.mark,
    required this.title,
    required this.category,
    required this.path,
  });

  final String quote;
  final TaskMark mark;
  final String title;
  final String category;

  /// Kaydın kendi dosyasının yolu — detayına gitmek için.
  final String path;
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
    if (!isTaskPath(entry.path)) continue;

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
      category: fm.str('category') ?? 'gorev',
      path: entry.path,
    ));
  }
  return found;
}

/// Bir bağlantının hub'ındaki sözleşme sürümü (§10).
///
/// Yerel kopyadan okunuyor; ayrı istek gerekmiyor çünkü `SYSTEM.md` zaten
/// senkronun indirdiği dosyalardan biri.
Future<String?> contractVersionOf(HubConfig connection) async {
  final doc = await OfflineStore(connection.slug).readDoc(Hub.systemFile);
  if (doc == null) return null;
  final match = RegExp(r'\*\*Sözleşme sürümü:\*\*\s*([0-9]+\.[0-9]+)')
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
bool isContractStale(String version) {
  int major(String v) => int.tryParse(v.split('.').first) ?? 0;
  int minor(String v) =>
      int.tryParse(v.split('.').skip(1).firstOrNull ?? '0') ?? 0;

  const current = Hub.contractVersion;
  if (major(version) != major(current)) return major(version) < major(current);
  return minor(version) < minor(current);
}
