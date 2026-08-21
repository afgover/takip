import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils.dart';

/// Bildirimi **gönderilmiş** `waiting/` görevlerinin cihazdaki kaydı (B-135).
///
/// Sözleşme zaten "app aynı görev için ikinci bir cevap göndermez" diyor
/// (§4, 1.12). Uygulama bunu yalnız detay ekranı açıkken tutuyordu: bilgi
/// widget durumundaydı ve ekrandan çıkınca ölüyordu. Görev `waiting/`ten
/// ancak **agent** işleyince çıktığı için (app dosyayı taşıyamaz, R-001)
/// liste onu göstermeye devam ediyor; ikinci "Yaptım" ikinci bir bildirim
/// üretiyordu (T-018).
///
/// Kayıt **gönderim yolundan bağımsız**: doğrudan giden bildirim de kuyruğa
/// düşen de (B-032) aynı kaydı yazar. Kusur tekti — bilginin kalıcı olmaması —
/// ve iki katmanda ayrı ayrı çözülseydi ikisi zamanla ayrışırdı.
///
/// Kuyruktaki taslak ayrıca "hangi beklemeyi cevaplıyorum" bilgisini
/// **taşımıyor**: aynı olgu iki yerde tutulmasın diye tek kaynak burası.
class ReportedWaiting extends AsyncNotifier<Map<String, String>> {
  static const _key = 'reported-waiting';

  /// Anahtar repoyu **içerir**. Yol hub-göreli, yani tek başına görevi
  /// tanımlamıyor: aynı `tasks/waiting/2026-08-06-x.md` iki hub'da birden
  /// bulunabilir ve biri diğerinin düğmesini kilitlerdi. Bildirimin yanlış
  /// hub'a bağlanması bu depoda gerçekten yaşandı (L-045).
  static String keyFor(String? repoSlug, String path) =>
      '${repoSlug ?? ''}|$path';

  @override
  Future<Map<String, String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries)
          if (e.value is String) e.key: e.value as String,
      };
    } catch (_) {
      return const {}; // bozuk kayıt düğmeyi kilitlemesin
    }
  }

  /// Bildirimin gönderildiğini (ya da kuyruğa alındığını) işaretler.
  ///
  /// Zaman değeri kaydın kendisi için değil, **okunabilirliği** için: bir
  /// sorun çıktığında "ne zaman bildirilmişti" sorusunun cevabı burada durur.
  Future<void> mark(String? repoSlug, String path) async {
    final current = {...(state.valueOrNull ?? const <String, String>{})};
    current[keyFor(repoSlug, path)] = isoNow();
    await _persist(current);
  }

  /// Hub'da artık bulunmayan görevlerin kaydını düşürür.
  ///
  /// Tetikleyici senkronun ölçtüğü ağaçtır: görev `waiting/`ten çıktıysa agent
  /// bildirimi işlemiş demektir ve kayıt anlamını yitirir. [livePaths] o
  /// reponun hub'ında **gerçekten duran** dosyaların kümesidir; eksik ya da
  /// yarım bir kümeyle çağrılırsa kayıt haksız yere silinir ve mükerrer
  /// bildirim yolu yeniden açılır.
  Future<void> pruneMissing(String repoSlug, Set<String> livePaths) async {
    final current = state.valueOrNull ?? const <String, String>{};
    if (current.isEmpty) return;

    final prefix = '$repoSlug|';
    final kept = <String, String>{
      for (final e in current.entries)
        // Başka reponun kaydına dokunulmaz: bu çağrı yalnız **bu** reponun
        // ağacını ölçtü, diğerleri hakkında hiçbir şey bilmiyor.
        if (!e.key.startsWith(prefix) ||
            livePaths.contains(e.key.substring(prefix.length)))
          e.key: e.value,
    };
    if (kept.length == current.length) return;
    await _persist(kept);
  }

  Future<void> _persist(Map<String, String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(value));
    state = AsyncData(value);
  }
}

final reportedWaitingProvider =
    AsyncNotifierProvider<ReportedWaiting, Map<String, String>>(
        ReportedWaiting.new);

/// Bir bekleyen görevin bildirilip bildirilmediği — üç ayrı cevap.
///
/// "Bilmiyorum" ile "hayır" ayrı tutuluyor: kayıt daha yüklenmemişken düğmeyi
/// açık bırakmak, tam olarak önlenmek istenen mükerrer bildirimi davet ederdi.
/// Kayıt **okunamadıysa** (hata) düğme açılır — bozuk bir yerel kayıt yüzünden
/// kullanıcının işini bildirememesi, mükerrer bildirimden ağır bir kusur.
enum ReportedState { yes, no, unknown }

ReportedState reportedStateOf(
  AsyncValue<Map<String, String>> record,
  String? repoSlug,
  String path,
) =>
    switch (record) {
      AsyncData(:final value) =>
        value.containsKey(ReportedWaiting.keyFor(repoSlug, path))
            ? ReportedState.yes
            : ReportedState.no,
      AsyncError() => ReportedState.no,
      _ => ReportedState.unknown,
    };
