---
id: S-2026-08-11-filtre-menuleri
date: 2026-08-11
status: closed
reconstructed: false
author: afgover
topics: [bekleyenler, filtre, kalicilik]
artifacts: []
tasks_touched: [T-016]
---

# Oturum: Filtre menüleri ve kalıcılık

## Özet
T-016: çip şeridi yerine üç açılır filtre menüsü (repo/kategori/öncelik) +
sıralama + sıfırla, hepsi tek şeritte. Seçimler kalıcı, menü seçimde
kapanmıyor (çoklu seçim), kapalı menü seçili sayıyı gösteriyor.
Sıfırla yalnız bir şey seçiliyken var ve filtre+sıralamayı birlikte temizliyor.
Kalıcılık `AppSettings` deseniyle; bozuk tercih filtresiz açar — yanlış filtre
görevleri sessizce gizlerdi.
**Yan bulgu:** lifecycle testi baştan beri yarışlıydı (`pumpAndSettle` gerçek
async işi sürmüyor); yeni disk okumaları bunu görünür kıldı, test
belirlenimci yapıldı. Cihaza kuruldu.

## Kayıt

### Kullanıcı
> yanyana siralanan repo ve kategorileri, siralama tusunun yaninda tiklayinca
> asagi acilan, repo, kategori ve oncelik olarak 3 farkli buton ile
> goruntuleyelim, secimler kalici olsun, rset tusu olsun, birden fazla secenek
> secilebilsin

### Agent
Çip şeridi yerine üç açılır menü + sıralama + sıfırlama.

**Bir tasarım kararı:** dört seçici `AppBar`'a sığmıyor (başlık + yenile zaten
orada), o yüzden sıralama düğmesi de çip şeridinin bulunduğu satıra indi.
"Sıralamanın yanında" isteği böylece karşılanıyor ve dördü bir arada duruyor.

### Agent — T-016 ✅
Menüler eklendi, kalıcılık bağlandı, eski `TaskFilterBar` silindi
(`TaskTagRow` yanlışlıkla birlikte silinmişti, git'ten geri alındı).
Lifecycle testindeki yarış düzeltildi. Cihaza kuruldu.
