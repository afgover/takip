---
id: S-2026-07-30-b022-onboarding
date: 2026-07-30
status: closed
topics: [gelistirme, flutter, guvenlik]
artifacts: []
tasks_touched: []
---

# Oturum: B-022 — Onboarding ekranı

## Özet
B-022 tamamlandı. Onboarding artık token'ı **kaydetmeden önce** doğruluyor:
hub kökü (`hub/`) için tek GET atılıyor; geçerse token geçerli, repo
erişilebilir ve repo gerçekten bir hub demektir. Yanlış token'la kurulumu
"başarılı" sayıp kullanıcıyı boş listelerle baş başa bırakma ihtimali kapandı.

Doğrulamanın kaydedilmemiş bir token'la yapılabilmesi için `client.dart`
ayrıldı: `buildGithubDio(readToken)` token'ı her istekte okuyor, provider bu
fabrikanın bir sarmalayıcısı. Doğrulama çekirdeği (`checkHubAccess`) ağ
kurulumundan bağımsız, dolayısıyla test edilebilir.

Hata mesajı L-007'ye dayanıyor: GitHub 404'ü "repo yok", "token bu repoyu
kapsamıyor" ve "klasör yok" için ortak kullanıyor (fine-grained token
görmediği repoyu yok sayar). Üçü ayırt edilemediği için mesaj üçünü birlikte
söylüyor. Yetki hatası (401/403) ise ayrı tutuluyor — `pathExists` yalnızca
404'ü `false`'a çeviriyor.

Kullanım ayrıntıları: token göster/gizle düğmesi, doğrulama sürerken kilitli
buton (çift gönderim yok), hata kutusu yeniden denemede temizleniyor, repo
alanı yapıştırılan GitHub adresini de kabul ediyor (`https://github.com/…`,
`.git` uzantısı), ve "token nasıl alınır" bölümü R-005'teki izinleri
birebir yazıyor — B-015'i yapacağın adımlar.

**Bilinen sınır:** bu kontrol yazma iznini sınamıyor; salt okunur bir token
onboarding'i geçer, sorun ilk görev gönderiminde 403 olarak çıkar. Backlog'a
B-026 olarak eklendi (önce fine-grained token'ın `permissions.push`
döndürüp döndürmediği araştırılacak).

Sonuç: 71 test geçiyor, `flutter analyze` temiz.

## Kayıt

### Kullanıcı
> b022 ile devam

### Agent
B-022 uygulanıyor: repo + token girişi, kaydetmeden önce tek GET ile doğrulama,
token'ın secure storage'a yazılması. Doğrulama `hub/` yolu üzerinden yapılıyor;
böylece tek istekte hem token geçerliliği hem reponun doğru repo olduğu
sınanıyor. Token'ın yazma izni bu istekle sınanamıyor (ayrıntı özet bölümünde).
