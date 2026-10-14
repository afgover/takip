import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Android paylaş menüsünden gelen metin (P-031).
///
/// Sohbet istenen uygulamada sürer; karar ya da iş doğduğunda mesaj tek
/// dokunuşla Ekle formuna düşer ve hub'a girer (A-2026-10-14-001 §3). Metin
/// yalnız formu doldurur — gönderim her zaman kullanıcıda.
class SharedText {
  SharedText({required this.text, this.subject}) : seq = ++_counter;

  final String text;
  final String? subject;

  /// Her paylaşım ayrı: aynı metin iki kez paylaşılırsa da ikinci kez işlenir.
  /// Dinleyiciler (kabuk ve form) metni "tüketip sıfırlamak" yerine buna
  /// bakar; sıfırlama iki dinleyici arasında sıra yarışı doğururdu.
  final int seq;

  static int _counter = 0;
}

/// Platform kanalı `MainActivity.kt` ile eşleşir.
const shareChannel = MethodChannel('us.gover.takip/share');

class SharedTextNotifier extends Notifier<SharedText?> {
  @override
  SharedText? build() {
    shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'sharedTextAvailable') await _take();
    });
    // Uygulama paylaşımla açıldıysa metin zaten bekliyor.
    unawaited(_take());
    return null;
  }

  Future<void> _take() async {
    try {
      final m = await shareChannel.invokeMapMethod<String, String>('takeSharedText');
      final text = m?['text'];
      if (text == null || text.trim().isEmpty) return;
      state = SharedText(text: text, subject: m?['subject']);
    } on MissingPluginException {
      // Kanal yalnız Android'de var (testler, başka platformlar).
    } on PlatformException {
      // Alınamayan paylaşım sessizce düşer; uygulama normal açılır.
    }
  }
}

final sharedTextProvider =
    NotifierProvider<SharedTextNotifier, SharedText?>(SharedTextNotifier.new);

/// Başlığın en çok bu kadarı paylaşılan metnin ilk satırından alınır.
const sharedTitleMax = 80;

/// Paylaşılan metni forma yerleştirir.
///
/// Form boşsa: başlık konu satırından ya da metnin ilk dolu satırından,
/// açıklama metnin tamamı (başlıkla aynıysa boş). Formda yazılmış bir şey
/// varsa **silinmez**: metin açıklamanın sonuna eklenir ve [appended] döner.
({String title, String description, bool appended}) mergeShared({
  required String title,
  required String description,
  required SharedText shared,
}) {
  final text = shared.text.trim();
  if (title.trim().isNotEmpty || description.trim().isNotEmpty) {
    final desc = description.trimRight();
    return (
      title: title,
      description: desc.isEmpty ? text : '$desc\n\n$text',
      appended: true,
    );
  }

  final subject = shared.subject?.trim();
  final firstLine = text
      .split('\n')
      .map((l) => l.trim())
      .firstWhere((l) => l.isNotEmpty, orElse: () => text);
  var head = (subject != null && subject.isNotEmpty) ? subject : firstLine;
  final cut = head.length > sharedTitleMax;
  if (cut) head = '${head.substring(0, sharedTitleMax - 1).trimRight()}…';

  return (
    title: head,
    description: (!cut && text == head) ? '' : text,
    appended: false,
  );
}
