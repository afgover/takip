import 'package:yaml/yaml.dart';

/// `---` bloklu markdown frontmatter ayrıştırma/yazma (SYSTEM.md şemaları).
///
/// Hub'daki her kayıt (görev, oturum, artifact) bu biçimdedir. Sınıf iki yönde
/// de kullanılır: agent'ın yazdığını **okumak** ve app'in görev dosyasını
/// **yazmak** (B-030). Yazma yönü sözleşmeyi bozmamak zorunda olduğundan
/// üretilen çıktı her durumda geçerli YAML'dır — bkz. [serialize].
class Frontmatter {
  const Frontmatter(this.fields, this.body, {this.isMalformed = false});

  /// Alanları verilen sırayla tutar (sözleşmedeki alan sırası korunur).
  factory Frontmatter.of(Map<String, dynamic> fields, {String body = ''}) =>
      Frontmatter(fields, body);

  /// Frontmatter alanları. Blok yoksa ya da bozuksa boştur.
  final Map<String, dynamic> fields;

  /// `---` bloğundan sonraki markdown gövde (baştaki boş satırlar atılmış).
  final String body;

  /// YAML bloğu vardı ama ayrıştırılamadı. Bu durumda [body] dosyanın
  /// tamamıdır: içerik gizlenmez, kullanıcı ham hâliyle görebilir.
  final bool isMalformed;

  bool get hasFrontmatter => fields.isNotEmpty;

  static final _fence = RegExp(r'^---\s*$');

  static Frontmatter parse(String content) {
    // BOM ve CRLF, GitHub'dan gelen dosyalarda karşımıza çıkabilir.
    final text =
        content.startsWith('﻿') ? content.substring(1) : content;
    final normalized = text.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');

    if (lines.isEmpty || !_fence.hasMatch(lines.first)) {
      return Frontmatter(const {}, normalized);
    }

    final end = lines.indexWhere(_fence.hasMatch, 1);
    if (end == -1) return Frontmatter(const {}, normalized);

    final yamlText = lines.sublist(1, end).join('\n');
    final body = _stripLeadingBlanks(lines.sublist(end + 1).join('\n'));

    if (yamlText.trim().isEmpty) return Frontmatter(const {}, body);

    try {
      final yaml = loadYaml(yamlText);
      final fields = yaml is YamlMap
          ? yaml.map((k, v) => MapEntry(k.toString(), _plain(v)))
          : <String, dynamic>{};
      return Frontmatter(fields, body);
    } on YamlException {
      // Elle düzenlenmiş bozuk bir dosya listeyi çökertmesin.
      return Frontmatter(const {}, normalized, isMalformed: true);
    }
  }

  static String _stripLeadingBlanks(String s) =>
      s.replaceFirst(RegExp(r'^\n+'), '');

  static dynamic _plain(dynamic v) {
    if (v is YamlMap) {
      return v.map((k, val) => MapEntry(k.toString(), _plain(val)));
    }
    if (v is YamlList) return v.map(_plain).toList();
    return v;
  }

  // --- Tipli erişim -------------------------------------------------------
  // YAML'dan hangi tipin geleceği dosyayı yazana bağlıdır (sayı, bool,
  // string...). Modeller bu erişimcileri kullanır, tip kontrolünü tekrarlamaz.

  /// Metin değer; alan yoksa ya da boşsa null.
  String? str(String key) {
    final v = fields[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String strOr(String key, String fallback) => str(key) ?? fallback;

  /// Liste değer. Tek bir skaler yazılmışsa tek elemanlı listeye çevirir;
  /// alan yoksa boş liste döner (`tags:` boş bırakılmış olabilir).
  List<String> list(String key) {
    final v = fields[key];
    if (v == null) return const [];
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final s = v.toString().trim();
    return s.isEmpty ? const [] : [s];
  }

  /// ISO 8601 tarih; biçim tutmuyorsa null (sözleşme UTC ister ama hub'a elle
  /// yazılmış bir kayıt bozuk olabilir).
  DateTime? dateTime(String key) {
    final s = str(key);
    if (s == null) return null;
    return DateTime.tryParse(s)?.toUtc();
  }

  // --- Yazma --------------------------------------------------------------

  /// `---` bloğu + gövde. Çıktı daima geçerli YAML'dır: özel karakter içeren
  /// ya da bool/sayı gibi görünen değerler tırnaklanır, tırnak ve satır sonu
  /// kaçışlanır. `parse(serialize())` alanları geri verir.
  String serialize() {
    final buf = StringBuffer('---\n');
    fields.forEach((key, value) => buf.writeln('$key: ${_yamlValue(value)}'));
    buf
      ..writeln('---')
      ..writeln()
      ..write(body);
    return buf.toString();
  }

  static String _yamlValue(Object? value) {
    if (value == null) return 'null';
    if (value is bool || value is num) return value.toString();
    if (value is List) return '[${value.map(_yamlValue).join(', ')}]';
    return _scalar(value.toString());
  }

  /// Tırnaksız yazılabilecek "sade" skaler kalıbı. Türkçe harfler dahildir
  /// (YAML sade skalerde unicode harf kabul eder); `:` `#` gibi karakterler,
  /// `-` ile başlayanlar ve baş/son boşluklular kalıp dışıdır.
  static final _plainSafe =
      RegExp(r'^[\p{L}\p{N}][\p{L}\p{N} _./-]*$', unicode: true);

  /// Tırnaksız yazılırsa string olmaktan çıkacak değerler.
  static const _reserved = {
    'true',
    'false',
    'yes',
    'no',
    'on',
    'off',
    'null',
    '~',
  };

  static String _scalar(String s) {
    final plain = s.isNotEmpty &&
        s == s.trim() &&
        !_reserved.contains(s.toLowerCase()) &&
        num.tryParse(s) == null &&
        _plainSafe.hasMatch(s);
    if (plain) return s;

    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }
}
