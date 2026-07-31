---
id: S-2026-07-30-b026-yazma-izni
date: 2026-07-30
status: closed
topics: [gelistirme, github-api, arastirma]
artifacts: []
tasks_touched: []
---

# Oturum: B-026 — onboarding'de yazma izni doğrulaması

## Özet
B-026 tamamlandı. 191 test, `flutter analyze` temiz. **Agent tarafında açık iş
kalmadı.**

**Araştırma, önerilen çözümü eledi.** Backlog "fine-grained token'da
`GET /repos/{o}/{r}` yanıtı `permissions.push`'u güvenilir veriyor mu?" diye
sormuştu. Cevap hayır: bu alan token'ın kapsamını değil **kullanıcının repo
rolünü** yansıtıyor, üstelik token'larla hatalı (hepsi `false`) döndüğü
bildirilmiş. GitHub'ın token izinlerini sorgulayacak belgelenmiş bir uç
noktası da yok (L-009). Bu alana bakmak, yazabilen bir token'a "yazamıyorsun"
demek anlamına gelirdi — kontrol yokluğundan kötü.

**Yerine yan etkisiz bir yoklama kondu (SK-006).** Contents API'de `content`
zorunlu bir alan; dolayısıyla `content` içermeyen bir PUT, izin olsa bile
hiçbir dosya oluşturamaz veya değiştiremez. Ama yetkilendirme reddi yine de
döner. Yani sinyal alınıyor, repoda hiçbir şey olmuyor.

Yorumu bilinçli olarak tek yönlü tuttum: **403 "izin yok" demektir; 403
gelmemesi "izin var" demek değildir.** GitHub'ın yetkilendirmeyi gövde
doğrulamasından önce yaptığını belgeden teyit edemedim, o yüzden 422'yi
"sonuçsuz" sayıyorum. Böylece kontrol yanlış alarm veremiyor — en kötü
ihtimalle bugünkü durumu koruyor, en iyi ihtimalle sorunu ilk ekranda
yakalıyor. Rate limit kaynaklı 403 de izin sorunu sayılmıyor.

Eksik iznin adı `X-Accepted-GitHub-Permissions` başlığından okunup mesaja
konuyor, yani kullanıcı "hangi izni açmam gerek" sorusunu ekranda görüyor.

Hatırlatma: bu kontrol onboarding'e bir istek ekliyor (okuma + yoklama = iki
istek).

## Kayıt

### Kullanıcı
> b026 yı da hallet, sonra bana kalan işleri halledeceğim

### Agent
Önce backlog'un işaret ettiği araştırma yapıldı: `GET /repos/{o}/{r}` yanıtındaki
`permissions` alanı token'ın kapsamını değil kullanıcının rolünü yansıtıyor ve
token'larla hatalı (hepsi `false`) değerler döndüğü bildirilmiş; GitHub'ın token
izinlerini sorgulamak için belgelenmiş bir yolu yok. Öneri bu hâliyle
uygulanamaz. Alternatif olarak "kesin olumsuz" sinyali veren, repoyu
değiştirmesi yapısal olarak imkânsız bir yoklama tasarlandı.
