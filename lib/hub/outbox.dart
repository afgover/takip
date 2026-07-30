import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors.dart';
import 'models/task_draft.dart';
import 'task_repo.dart';

/// Gönderilemeyen görevlerin cihazdaki kuyruğu (B-032).
///
/// Amaç dar tutuldu: tek cihaz, tek kullanıcı. Görev metroda yazılıp
/// gönderilemezse kaybolmasın, bağlantı gelince kendiliğinden gitsin.
/// Kuyrukta taslağın **üretildiği andaki hâli** durur (dosya adı, tarih,
/// frontmatter) — sonradan yeniden üretilse tarih kayar ve kullanıcının
/// gördüğü görev başka bir dosya olurdu.
///
/// Yalnız [HubNetworkError] kuyruğa alma sebebidir: geçersiz token ya da
/// bozuk istek beklemekle düzelmez, kullanıcıya hemen söylenir.
class Outbox extends AsyncNotifier<List<TaskDraft>> {
  static const _key = 'outbox';

  bool _flushing = false;

  @override
  Future<List<TaskDraft>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((s) {
          try {
            return TaskDraft.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null; // bozuk kayıt kuyruğu kilitlemesin
          }
        })
        .whereType<TaskDraft>()
        .toList();
  }

  Future<void> add(TaskDraft draft) async {
    final current = [...(state.valueOrNull ?? const <TaskDraft>[]), draft];
    await _persist(current);
  }

  Future<void> remove(String fileName) async {
    final current = (state.valueOrNull ?? const <TaskDraft>[])
        .where((d) => d.fileName != fileName)
        .toList();
    await _persist(current);
  }

  /// Kuyruğu boşaltmayı dener. Ağ hâlâ yoksa sessizce vazgeçer; kalan
  /// taslaklar bir sonraki denemeye kalır.
  ///
  /// Bağlantının geldiğini yoklama servisi söylüyor (B-024): başarılı bir
  /// kontrol, "çevrimiçiyiz" demektir. Ayrı bir bağlantı dinleyicisi
  /// eklemeye gerek kalmıyor.
  Future<void> flush() async {
    if (_flushing) return;
    final queued = state.valueOrNull ?? const <TaskDraft>[];
    if (queued.isEmpty) return;

    _flushing = true;
    final remaining = <TaskDraft>[];
    try {
      final repo = ref.read(taskRepoProvider);
      var offline = false;

      for (final draft in queued) {
        if (offline) {
          remaining.add(draft);
          continue;
        }
        try {
          await repo.send(draft);
        } on HubNetworkError {
          offline = true; // hâlâ ağ yok; kalanları deneme
          remaining.add(draft);
        } on HubError {
          // Kalıcı bir sorun (yetki, biçim): kuyrukta kalsın ama diğerlerini
          // engellemesin. Kullanıcı ayarlardan düzeltince yeniden denenir.
          remaining.add(draft);
        }
      }

      await _persist(remaining);
      if (remaining.length != queued.length) {
        ref.invalidate(pendingTasksProvider);
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _persist(List<TaskDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      drafts.map((d) => jsonEncode(d.toJson())).toList(),
    );
    state = AsyncData(drafts);
  }
}

final outboxProvider =
    AsyncNotifierProvider<Outbox, List<TaskDraft>>(Outbox.new);
