import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Görev kategorileri (K-010): 5 sabit varsayılan + kullanıcı tanımlı serbest
/// değerler.
///
/// Sözleşme ek bir kayıt dosyası öngörmüyor; liste "varsayılanlar + mevcut
/// görevlerde geçen kategoriler"den türetilir. Bunun için bütün görev
/// dosyalarını indirmek gerekirdi (her görev bir istek) — bunun yerine app,
/// **gördüğü** kategorileri cihazda biriktirir: kendi oluşturduklarını ve
/// detayını açtığı görevlerinkini. Liste eksik kalsa bile serbest giriş her
/// zaman açık olduğu için kullanıcı kısıtlanmaz.
class TaskCategories extends AsyncNotifier<List<String>> {
  static const _key = 'seen_categories';

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _merge(prefs.getStringList(_key) ?? const []);
  }

  /// Yeni bir kategori görüldüğünde çağrılır (görev oluşturma, detay açma).
  Future<void> remember(String category) async {
    final value = category.trim();
    if (value.isEmpty || Hub.defaultCategories.contains(value)) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_key) ?? <String>[];
    if (seen.contains(value)) return;

    final updated = [...seen, value];
    await prefs.setStringList(_key, updated);
    state = AsyncData(_merge(updated));
  }

  static List<String> _merge(List<String> seen) => [
        ...Hub.defaultCategories,
        ...seen.where((c) => !Hub.defaultCategories.contains(c)),
      ];
}

final taskCategoriesProvider =
    AsyncNotifierProvider<TaskCategories, List<String>>(TaskCategories.new);
