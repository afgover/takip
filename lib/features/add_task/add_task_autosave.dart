import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Ekleme ekranının yarım kalmış taslağı — diskte.
///
/// Sekme geçişini `IndexedStack` çözüyor; bu katman ise sürecin kendisinin
/// ölmesine karşı: Android, kullanıcı başka uygulamaya bakarken süreci
/// öldürebilir ve bellekteki her şey gider (T-022 — "klavye başka app'e
/// bakıp dönünce kapanıyor, yazılar kayboluyor"). Kayıp tam da çevrimdışı
/// uzun metin yazarken en acı olduğu için taslak **her değişiklikte**
/// yazılır; başarılı gönderimde silinir.
///
/// `SharedPreferences` bilinçli: taslak sır değil (göreve dönüşüp hub'a
/// gidecek metin) ve `Outbox` da aynı yerde duruyor — iki taslak katmanının
/// iki ayrı depoda yaşaması, yedekleme/temizlik kurallarını ayrıştırırdı.
class AddTaskAutosave {
  static const _key = 'add_task_draft_v1';

  const AddTaskAutosave();

  Future<void> save({
    required String title,
    required String description,
    required String priority,
    required String category,
    String? newCategory,
    String? targetSlug,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (title.trim().isEmpty && description.trim().isEmpty) {
      // Boş form taslak değildir; eski taslağı da bırakmak, kullanıcı her
      // şeyi bilerek sildiğinde silineni geri getirirdi.
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(
      _key,
      jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        if (newCategory != null && newCategory.isNotEmpty)
          'newCategory': newCategory,
        if (targetSlug != null) 'targetSlug': targetSlug,
      }),
    );
  }

  Future<Map<String, dynamic>?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Bozuk taslak sessizce atılır: ekranı açamamak, taslağı kaybetmekten
      // daha kötü bir kayıptır.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
