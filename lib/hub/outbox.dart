import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors.dart';
import 'hub_connections.dart';
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

  /// Taslağı kuyruğa alır; **damgasızsa** o anki aktif repoyu damgalar (T-003).
  /// Damga burada basılır çünkü "hangi repoya gidecek" sorusunun cevabı,
  /// görevin yazıldığı andaki bağlamdır — gönderildiği andaki değil.
  ///
  /// **Damgalı taslağın damgası ezilmez.** Bekleyen-görev bildirimleri ekranda
  /// görevin kendi reposuyla damgalanıp geliyor; burada koşulsuz yeniden
  /// damgalamak, ağ hatasında kuyruğa giren her bildirimi aktif repoya
  /// yönlendiriyordu — üç bildirim bu yüzden financer_takip'e düştü
  /// (S-2026-08-12, L-045). T-003'ün damgası yanlış yönlendirmeyi önlemek
  /// içindi; aynı alana dokunan bu ikinci yol düzeltmeyi geri alıyordu.
  Future<void> add(TaskDraft draft) async {
    // Senkron okuma bilinçli: kabuk (`app.dart`) yalnızca aktif bağlantı
    // çözüldükten sonra çiziliyor, dolayısıyla kullanıcı görev ekleyebildiği
    // anda değer zaten elde. `.future` beklemek buraya bir platform kanalı
    // bağımlılığı sokardı — yazma yolu, güvenli depo cevap vermezse
    // askıda kalmamalı.
    final active = ref.read(hubConnectionsProvider).valueOrNull?.active;
    final stamped = draft.repoSlug != null
        ? draft
        : active == null
            ? draft
            : draft.forRepo(active.slug);
    final current = [...(state.valueOrNull ?? const <TaskDraft>[]), stamped];
    await _persist(current);
  }

  /// Hedef reposu kaldırılmış taslakları kuyruktan düşürür (B-140).
  ///
  /// **Yalnız kullanıcı çağırır.** `flush` hedefi bulamadığında taslağı
  /// kuyrukta bırakıyor ve bu bilinçli: kullanıcının yazdığı iş kendiliğinden
  /// atılmaz. Ama sonsuza kadar saklamak da bir cevap değildi — saklandığını
  /// gösteremeyen bir koruma, sessiz kayıptır. Karar artık kullanıcının ve
  /// **görünür** bir yerden veriliyor (Ayarlar → Veri).
  ///
  /// Silme repo bazında: kullanıcının ekranda gördüğü şey "şu repoya ait N
  /// görev". Taslak kimliğiyle silmek, listeyi gördüğü an ile düğmeye bastığı
  /// an arasında kuyruk değişirse yanlış kaydı silebilirdi.
  Future<void> discardForRepos(Set<String> slugs) async {
    if (slugs.isEmpty) return;
    final current = (state.valueOrNull ?? const <TaskDraft>[])
        .where((d) => d.repoSlug == null || !slugs.contains(d.repoSlug))
        .toList();
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
      // Tek doğru kaynak bağlantı listesi. `hubConfigProvider` buradan
      // **asenkron** türediği için repo değiştikten hemen sonra bayat kalır;
      // ona bakan bir boşaltma, geçişin hemen ardından yanlış repoya yazabilir.
      final connections = ref.read(hubConnectionsProvider).valueOrNull ??
          const HubConnectionsState();
      var offline = false;

      for (final draft in queued) {
        if (offline) {
          remaining.add(draft);
          continue;
        }

        // Damgalı taslak **her zaman** kendi bağlantısına, açıkça gönderilir —
        // aktif repoya ait olsa bile. Paylaşılan depoyu (`taskRepoProvider`)
        // kullanmak, onun da `hubConfigProvider` üzerinden bayat kalabilmesi
        // yüzünden hedefi tahmine bağlardı; hedefi tahmin etmenin bedeli
        // görevin yanlış projeye düşmesi.
        //
        // Damgasız taslak (T-003 öncesi kuyruğa girmiş) için elimizde hedef
        // yok; tek makul yer paylaşılan depodur.
        final slug = draft.repoSlug;
        final target = slug == null ? null : connections.bySlug(slug);

        if (slug != null && target == null) {
          // Bağlantı kaldırılmış: gönderilecek yer yok. Taslak kuyrukta kalır;
          // kullanıcı repoyu geri eklerse kendiliğinden gider. Sessizce
          // atmıyoruz — kullanıcının yazdığı iş kaybolmamalı.
          remaining.add(draft);
          continue;
        }

        try {
          if (target == null) {
            // Taslak kendi hedefini taşıyor (görev → inbox, not → notes).
            await ref.read(taskRepoProvider).sendDraft(draft);
          } else {
            await ref.read(draftSenderProvider)(target, draft);
          }
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
