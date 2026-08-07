import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'annotations.dart' show contractVersionOf;
import 'hub_config.dart';
import 'hub_connections.dart';
import 'hub_sync.dart';
import 'offline_store.dart';

/// Bir hub'ın dili (sözleşme 1.19).
///
/// Dil, cihazın tercihi **değil**, hub'ın özelliğidir: kurulurken seçilir ve üç
/// şey birden onu izler — sözleşme (agent referansı oradan alır), uygulama
/// arayüzü, ve o andan sonra üretilen kayıtlar. Bir hub'da tek dil bulunduğu
/// için gövde başlıkları tutarlı kalır; tutarlılığı şemayı tek bir dile
/// sabitleyerek sağlamak gerekmez (1.18'in geçersiz kılınan kuralı).
enum HubLanguage {
  tr('tr'),
  en('en');

  const HubLanguage(this.code);
  final String code;

  /// Gövde başlıkları (sözleşme 1.19 tablosu). Frontmatter **alan adları**
  /// buna dâhil değil: onlar her zaman İngilizce.
  String get requestHeading => this == tr ? 'İstek' : 'Request';
  String get notesHeading => this == tr ? 'Notlar' : 'Notes';
  String get whereHeading => this == tr ? 'Nerede' : 'Where';
  String get quoteHeading => this == tr ? 'Alıntı' : 'Quote';

  /// Gövde içi alan adları (`- **Ad:** değer`). Başlıklarla aynı kural: bunlar
  /// **kayıt içeriği**, frontmatter anahtarı değil, dolayısıyla hub dilinde.
  String get choiceField => this == tr ? 'Seçim' : 'Choice';
  String get explanationField => this == tr ? 'Açıklama' : 'Explanation';

  /// Güvenlik kaydının alanları (sözleşme §12).
  String get typeField => this == tr ? 'Tür' : 'Type';
  String get statusField => this == tr ? 'Durum' : 'Status';

  /// `Durum` alanının "kapanmamış" değeri. Dosyada Türkçe karaktersiz yazılır
  /// (dosya adı kuralıyla aynı gerekçe).
  String get openValue => this == tr ? 'acik' : 'open';

  /// `waiting/` bildirimlerinin gövdesi — kullanıcı bir soruyu cevaplayınca ya
  /// da bekleneni yapınca `inbox/`a düşen kayıt.
  String waitingDoneTitle(String label) =>
      this == tr ? '$label — yapıldı' : '$label — done';
  String waitingAnsweredTitle(String label) =>
      this == tr ? '$label — cevaplandı' : '$label — answered';
  String waitingDoneBody(String ref) => this == tr
      ? '`$ref` görevinde beklenen iş yapıldı. Asıl görevi `waiting/`ten '
          'çıkarabilirsin.'
      : 'The work awaited in `$ref` is done. You can move the original task '
          'out of `waiting/`.';
  String waitingAnsweredBody(String ref) => this == tr
      ? '`$ref` görevindeki soru cevaplandı.'
      : 'The question in `$ref` has been answered.';
  String get noChoiceMade => this == tr ? '(seçim yapılmadı)' : '(no choice)';

  /// İşaret/not kaydının "nerede" alanları.
  String get fileField => this == tr ? 'Dosya' : 'File';
  String get sectionField => this == tr ? 'Bölüm' : 'Section';

  /// Kullanıcının boş bıraktığı alanlar. Boş bırakmak bir bilgi: "yazacak bir
  /// şey yoktu" ile "alan hiç yoktu" farklı şeyler, o yüzden yazılıyor.
  String get noNoteGiven =>
      this == tr ? '(not girilmedi)' : '(no note given)';
  String get noDescriptionGiven =>
      this == tr ? '(açıklama girilmedi)' : '(no description given)';

  static HubLanguage parse(String? code) {
    for (final l in HubLanguage.values) {
      if (l.code == code) return l;
    }
    // Alan yoksa ya da tanınmıyorsa `tr`: alan eklenmeden önceki bütün
    // hub'ların gerçek durumu bu. "Bilinmiyor"u İngilizce saymak, mevcut
    // Türkçe hub'ları bir anda yanlış dile geçirirdi.
    return tr;
  }

  /// Her dilin başlıkları — **ayrıştırıcı hepsini tanır**.
  ///
  /// Hub'ın ilan ettiği dille sınırlamak cazip ama yanlış: dil alanı eklenmeden
  /// önce yazılmış kayıtlar, elle düzenlenmiş dosyalar ve dili sonradan
  /// değiştirilmiş hub'lar var. Geniş kabulün maliyeti yok; dar kabulün
  /// maliyeti okunamayan kayıt.
  static List<String> get allRequestHeadings =>
      HubLanguage.values.map((l) => l.requestHeading).toList();

  /// Ayrıştırma tarafı — [allRequestHeadings] ile aynı gerekçe: okurken geniş,
  /// yazarken hub dilinde.
  static List<String> get allTypeFields =>
      HubLanguage.values.map((l) => l.typeField).toList();
  static List<String> get allStatusFields =>
      HubLanguage.values.map((l) => l.statusField).toList();
  static List<String> get allOpenValues =>
      HubLanguage.values.map((l) => l.openValue).toList();
}

/// Hub'ın `SYSTEM.md`'sinde ilan edilen dil.
///
/// Yerel kopyadan okunuyor; `SYSTEM.md` zaten senkronun indirdiği dosyalardan
/// biri, ayrı istek gerekmiyor (bkz. [contractVersionOf], aynı yol).
Future<HubLanguage> hubLanguageOf(HubConfig connection) async {
  final doc = await OfflineStore(connection.slug).readDoc(Hub.systemFile);
  if (doc == null) return HubLanguage.tr;
  return HubLanguage.parse(languageCodeIn(doc.content));
}

/// `**Hub dili:** tr` satırından kodu çıkarır. Bulunamazsa null.
String? languageCodeIn(String systemMd) => RegExp(
      r'\*\*Hub dili:\*\*\s*([A-Za-z-]+)',
    ).firstMatch(systemMd)?.group(1);

/// **Aktif** hub'ın dili — arayüz bunu izler.
///
/// Repo değiştirmek arayüz dilini de değiştirir; "dil hub'ın özelliğidir"
/// ilkesinin doğrudan sonucu. Bağlantı yokken (onboarding) sistem diline
/// bırakılır: henüz bir hub yok, dolayısıyla hub dili de yok.
final activeHubLanguageProvider = FutureProvider<HubLanguage?>((ref) async {
  ref.watch(hubSyncProvider.select((s) => s.version));

  final state = ref.watch(hubConnectionsProvider).valueOrNull;
  final active = state?.active ?? ref.watch(hubConfigProvider).value;
  if (active == null) return null;

  return hubLanguageOf(active);
});

/// Belirli bir repoya **yazarken** kullanılacak dil.
///
/// Kimlikle aynı gerekçe (L-019): yazma hedefi hangi repoysa dil de onun.
/// Bekleyen bir soruya cevap başka repoya gidebiliyor ve o repo başka dilde
/// olabilir.
///
/// Değer henüz yüklenmemişse çağıran `tr`'ye düşer — hub dili yerel kopyadan
/// okunuyor, yani ilk okuma bir mikro görev sürüyor. Yanlış dilde yazılmış tek
/// bir kayıt, ayrıştırıcı bütün dilleri tanıdığı için okunabilir kalır.
final languageForRepoProvider =
    FutureProvider.family<HubLanguage, String?>((ref, slug) async {
  final connections = ref.watch(hubConnectionsProvider).valueOrNull;
  final match = slug == null ? null : connections?.bySlug(slug);
  final target = match ?? ref.watch(hubConfigProvider).value;
  if (target == null) return HubLanguage.tr;
  return hubLanguageOf(target);
});
