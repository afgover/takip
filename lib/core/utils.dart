import 'package:clock/clock.dart';

/// Türkçe karakterleri sadeleştirip sözleşmeye uygun slug üretir
/// (SYSTEM.md: küçük harf, tire, Türkçe karakter yok).
String slugify(String input) {
  const map = {
    'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
    'Ç': 'c', 'Ğ': 'g', 'İ': 'i', 'I': 'i', 'Ö': 'o', 'Ş': 's', 'Ü': 'u',
  };
  final normalized =
      input.split('').map((ch) => map[ch] ?? ch).join().toLowerCase();
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

/// Başlıktan geçerli bir slug çıkmıyor mu? (yalnız noktalama/emoji girilmişse)
bool slugIsEmpty(String input) => slugify(input).isEmpty;

/// Sözleşmedeki görev dosya adı: `<YYYY-MM-DD>-<slug>.md`
String taskFileName(DateTime date, String title) {
  final d = date.toUtc().toIso8601String().substring(0, 10);
  return '$d-${slugify(title)}.md';
}

/// ISO 8601 UTC, saniye hassasiyetinde (sözleşme zaman biçimi).
String isoNow() {
  final now = clock.now().toUtc();
  return '${now.toIso8601String().split('.').first}Z';
}
