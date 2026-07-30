import 'package:yaml/yaml.dart';

/// `---` bloklu markdown frontmatter ayrıştırma/yazma (SYSTEM.md şemaları).
class Frontmatter {
  const Frontmatter(this.fields, this.body);

  final Map<String, dynamic> fields;
  final String body;

  static Frontmatter parse(String content) {
    final match =
        RegExp(r'^---\n(.*?)\n---\n?(.*)$', dotAll: true).firstMatch(content);
    if (match == null) return Frontmatter(const {}, content);
    final yaml = loadYaml(match.group(1)!);
    final fields = yaml is YamlMap
        ? yaml.map((k, v) => MapEntry(k.toString(), _plain(v)))
        : <String, dynamic>{};
    return Frontmatter(fields, match.group(2) ?? '');
  }

  static dynamic _plain(dynamic v) {
    if (v is YamlMap) {
      return v.map((k, val) => MapEntry(k.toString(), _plain(val)));
    }
    if (v is YamlList) return v.map(_plain).toList();
    return v;
  }

  String serialize() {
    final buf = StringBuffer('---\n');
    fields.forEach((key, value) {
      if (value is List) {
        buf.writeln('$key: [${value.join(', ')}]');
      } else {
        final s = value.toString();
        // İki nokta / özel karakter içeren değerleri tırnakla.
        buf.writeln(s.contains(':') ? '$key: "$s"' : '$key: $s');
      }
    });
    buf
      ..writeln('---')
      ..writeln()
      ..write(body);
    return buf.toString();
  }
}
