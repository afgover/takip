---
id: S-2026-07-30-b023-github-istemci
date: 2026-07-30
status: closed
topics: [gelistirme, github-api, flutter]
artifacts: []
tasks_touched: []
---

# Oturum: B-023 — GitHub istemci katmanı

## Özet
B-023 tamamlandı: Contents API sarmalayıcısı (listDir/getFile/putFile/
deleteFile), base64 kodlama-çözme, SHA'lı iyimser kilit ve HTTP durum →
`HubError` eşlemesi yazıldı. Hata modeline `HubNotFoundError` ve
`HubUnexpectedError` eklendi; 403 yetki mi limit mi ayrımı header'dan
(`x-ratelimit-remaining`) yapılıyor, 422/"sha" da çakışma sayılıyor ki B-033
tek tip hata yakalasın. Token artık Dio örneğine gömülmüyor, istek anında
interceptor'dan okunuyor (B-051'de token değişince eski token elde kalmaz).

Katman ihlali düzeltildi: R-001'i `github/contents_api.dart` yorumu iddia
ediyordu ama github katmanı sözleşmeyi bilmemeli. Kısıt hub katmanına,
`TaskRepo.writeToInbox`'a taşındı — yol değil *dosya adı* alıp önüne hep
`hub/tasks/inbox/` eklediği için app'in başka klasöre yazması runtime
kontrolüyle değil **yapısal olarak** engellenmiş oldu.

Ortamda Flutter yoktu; SDK kuruldu ve iskelet ilk kez derlendi. B-021'de 2
gerçek derleme hatası çıktı (`DropdownButtonFormField.initialValue` → `value`)
— düzeltildi. Sonuç: `flutter analyze` temiz, 27 test geçiyor (ağsız sahte
Dio adaptörüyle). Dersler L-005 (Contents API'de boş dizin 404'tür), L-006
(doğrulanmamış kod birikir), skill SK-003 (Dio'yu ağsız test etmek).

## Kayıt

## Kayıt

### Kullanıcı
> evet B-023 ile başla, eski commit geçmişi daha sonra, taskrın hubunı da daha
> sonra ben halledeceğim, bendeki iki iş de daha sonra, sen faz2den devam et

### Agent
İnbox boş, Faz 2 kaldığı yerden sürüyor. B-023 (Contents API + hata modeli)
uygulanıyor. Ortamda Dart/Flutter olmadığı için önce SDK indirildi; amaç
B-020'yi (kullanıcının işi) devralmak değil, yazılan kodun `flutter analyze`
ve `flutter test` ile **doğrulanabilmesi** — önceki oturumda işaret edilen
"doğrulanmamış kod birikmesi" riskini kapatmak.
