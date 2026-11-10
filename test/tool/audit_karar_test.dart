@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `tool/audit.sh --karar` — sözleşme 1.42 §4 karar kaydı biçim denetimi.
/// Ajan commit'ten önce koşar; çıkış kodu 1 ise karar commit'lenmez.
Future<(int, String, Directory)> _run(Map<String, String> files) async {
  final dir = await Directory.systemTemp.createTemp('audit-karar-test-');
  final paths = <String>[];
  files.forEach((name, body) {
    final f = File('${dir.path}/$name')..writeAsStringSync(body);
    paths.add(f.path);
  });
  final result = await Process.run(
    'bash',
    ['tool/audit.sh', '--karar', ...paths],
    environment: {'PATH': Platform.environment['PATH'] ?? '/usr/bin:/bin'},
  );
  return (result.exitCode, '${result.stdout}${result.stderr}', dir);
}

String _karar({
  String options = '["Resend", "Postmark"]',
  String recommended = 'Resend',
  String importance = 'yuksek',
  String priority = 'high',
  String blocks = '[T-12, merkez#B-40]',
  String extra = '',
  String body = '''
## Soru
Hangi sağlayıcı?

## Bağlam
Kısa bağlam.

## Seçenekler

### Resend
- **Ne olur:** x

### Postmark
- **Ne olur:** y

## Öneri
Resend: ucuz.
''',
}) =>
    '''
---
id: T-020
title: "Bildirim sağlayıcısı"
created_by: agent
created: "2026-11-10T12:00:00Z"
priority: $priority
category: karar
options: $options
recommended: $recommended
importance: $importance
blocks: $blocks
reversible: zor
for: afgover
asked_by: ajan:takip
$extra
---

# Bildirim sağlayıcısı

$body''';

void main() {
  test('biçime uyan karar geçer (olağan yol)', () async {
    final (code, out, dir) = await _run({
      'iyi.md': _karar(extra: 'supersedes: [T-5]\neffort: 5dk'),
      'proje.md': _karar(blocks: 'proje'),
    });
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(code, 0, reason: out);
    expect(out, contains('Karar biçimi tamam'));
  });

  test('İngilizce gövde başlıkları da kabul edilir', () async {
    final (code, out, dir) = await _run({
      'en.md': _karar(body: '''
## Question
Which one?

## Context
Short.

## Options

### Resend
- **What happens:** x

### Postmark
- **What happens:** y

## Recommendation
Resend: cheap.
'''),
    });
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(code, 0, reason: out);
  });

  test('önerilen seçenek listede yoksa ve kart eksikse düşer', () async {
    final (code, out, dir) = await _run({
      'kotu.md': _karar(recommended: 'SES', body: '''
## Soru
?

## Bağlam
x

### Resend

## Öneri
SES
'''),
    });
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(code, 1, reason: out);
    expect(out, contains('`recommended` `options`\'ta yok'));
    expect(out, contains('seçenek kartı yok: `### Postmark`'));
  });

  test('tanımsız önem, uyuşmayan priority ve serbest blocks düşer', () async {
    final (code, out, dir) = await _run({
      'kotu.md': _karar(importance: 'kritik', priority: 'normal', blocks: 'bir sey'),
      'kotu2.md': _karar(importance: 'acil'),
    });
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(code, 1, reason: out);
    expect(out, contains('`priority: normal` `importance: kritik` ile uyuşmuyor'));
    expect(out, contains('`blocks: bir sey`'));
    expect(out, contains('`importance: acil` tanımsız'));
    expect(out, contains('2 karar biçim dışı'));
  });
}
