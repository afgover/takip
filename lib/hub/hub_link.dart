import '../core/constants.dart';

/// Hub içi bir bağlantının çözülmüş hâli (sözleşme 1.25 §15).
class HubLink {
  const HubLink({required this.path, this.anchor});

  /// Repo köküne göre tam yol (`hub/SECURITY.md`) — belge açıcıların beklediği
  /// biçim.
  final String path;

  /// Kaydın ID'si (`SEC-010`). Yoksa belge baştan açılır.
  final String? anchor;

  @override
  bool operator ==(Object other) =>
      other is HubLink && other.path == path && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(path, anchor);

  @override
  String toString() => anchor == null ? path : '$path#$anchor';
}

/// Markdown bağlantısını hub içindeki bir hedefe çevirir; hub dışıysa `null`.
///
/// **Dışarısı bilerek çözülmüyor.** `http(s)`, `mailto` ve şema taşıyan her
/// bağlantı `null` döner: uygulamanın işi hub'ı gezdirmek, tarayıcı açmak
/// değil. Sessizce yutmak yerine çağıran tarafın kullanıcıya "bu bağlantı hub
/// dışında" diyebilmesi için ayrım burada net tutuluyor.
///
/// [fromPath] bağlantının **içinde bulunduğu** belgenin tam yolu; göreli
/// bağlantılar ona göre çözülür.
HubLink? resolveHubLink(String? href, {required String fromPath}) {
  if (href == null) return null;
  final raw = href.trim();
  if (raw.isEmpty) return null;

  // Şema taşıyan her şey dışarısı sayılır (`http:`, `mailto:`, `tel:`…).
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(raw)) return null;

  final hash = raw.indexOf('#');
  final rawPath = hash < 0 ? raw : raw.substring(0, hash);
  final anchor = hash < 0 ? null : raw.substring(hash + 1).trim();

  // Yalnız çapa (`#SEC-010`) — hedef, bağlantının bulunduğu belgenin kendisi.
  if (rawPath.isEmpty) {
    if (anchor == null || anchor.isEmpty) return null;
    return HubLink(path: fromPath, anchor: anchor);
  }

  // Markdown dosyası olmayan hedefler (klasör, resim, kod dosyası) açılmıyor:
  // belge görüntüleyici yalnız markdown çiziyor ve bir `.dart` dosyasını ham
  // metin olarak açmak, bağlantının bozuk olduğunu düşündürmekten kötü.
  if (!rawPath.toLowerCase().endsWith('.md')) return null;

  final resolved = rawPath.startsWith('.')
      // Göreli yol: bağlantının bulunduğu belgenin klasörüne göre.
      ? _normalize('${_dirOf(fromPath)}/$rawPath')
      // Sözleşmenin normali: yol hub köküne göre yazılır (§15).
      : _normalize('${Hub.basePath}/$rawPath');

  if (resolved == null) return null;
  return HubLink(
    path: resolved,
    anchor: (anchor?.isEmpty ?? true) ? null : anchor,
  );
}

String _dirOf(String path) {
  final slash = path.lastIndexOf('/');
  return slash < 0 ? '' : path.substring(0, slash);
}

/// `.` ve `..` parçalarını düzleştirir. Kökün üstüne çıkan bir yol `null`
/// döner: hub dışına işaret eden bağlantı, hub içi bağlantı değildir.
String? _normalize(String path) {
  final out = <String>[];
  for (final part in path.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (out.isEmpty) return null;
      out.removeLast();
      continue;
    }
    out.add(part);
  }
  if (out.isEmpty) return null;
  return out.join('/');
}

/// Çapanın belgedeki satır numarası — bulunamazsa `null`.
///
/// Çapa bir **ID**dir (§15) ve ID'ler belgede iki biçimde geçer: başlık olarak
/// (`## SEC-010 — …`) ve liste maddesi olarak (`- [ ] B-097 · …`). Bu yüzden
/// başlık aranmıyor, **ID'nin kendisi** aranıyor; ilk geçtiği satır kazanır.
///
/// Yalnız **satır başındaki** yapılarda aranır: girintili bir satıra kaydırmak,
/// belgeyi ikiye bölen çizim yolunda (bkz. `DocumentScreen`) listenin ortasını
/// koparırdı. Girintili bir ID bulunduğunda kaydırma yapılmaz, belge baştan
/// açılır — sessiz ama zararsız bir davranış.
int? anchorLineOf(String source, String anchor) {
  final id = RegExp.escape(anchor);
  // ID'nin **tam** eşleşmesi: `B-09` çapası `B-097`ye çarpmasın. Sonrasında
  // rakam ya da harf gelmemeli; nokta ise alt adım demek (`P-001.2`), o da
  // ayrı bir ID.
  final pattern = RegExp('(?<![A-Za-z0-9-])$id(?![A-Za-z0-9.-])');
  final lines = source.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.isEmpty || line.startsWith(' ') || line.startsWith('\t')) continue;
    if (pattern.hasMatch(line)) return i;
  }
  return null;
}
