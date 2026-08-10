---
id: S-2026-08-11-otuz-dakika-ritmi
date: 2026-08-11
status: closed
reconstructed: false
author: afgover
topics: [sozlesme, protokol]
artifacts: []
tasks_touched: []
---

# Oturum: Sözleşme 1.23 — 30 dakika ritmi

## Özet
Kullanıcının isteğiyle sözleşmeye ara kayıt kuralı eklendi (1.22 → 1.23).
Tek ritim: **30 dakika**. İş yapılırken en geç 30 dakikada bir kayıtlar
güncellenip push'lanır (oturum `open` kalır, özet kapanışta) ve aynı ritimde
`tasks/inbox/` kontrol edilir. Ek tetikleyici: kullanıcı 30 dakikadan uzun
aradan sonra döndüğünde ya da oturum sıkıştırma sonrası devam ediyorsa inbox
kontrolü tekrarlanır.
Aralık kararı bana bırakılmıştı; üç ayrı sayaç yerine tek sayı seçildi.
Gerekçe zaten sözleşmede yaşıyordu: `reconstructed: true` (v1.6) tam bu
boşluktan doğmuştu — ara kayıt boşluğu 30 dakikaya indirir ve geriye dönük
yazma ihtiyacını azaltır. İki dil varyantı birlikte güncellendi.

## Kayıt

### Kullanıcı
> sozlesmeye bir ekleme yapalim, agentin session sirasindaki hubda bulunan
> gorevleri check etmesi(yada session baslangisinda(session 0dan baslamadiysa
> bir sure sonraki userin ilk mesaji da buna dahil))
> belirli periyotlarla da kayitlari guncelleyip push etmesini saglayalim,
> bu araliklara sen karar ver, ornegin 30dk is yapiladiysa session kapatilmis
> gibi kayitlar guncellenip push edilsin, eger daha sonra devam edilirse,
> kayitlar session kapanisinda guncellensin

### Agent
Sözleşme 1.23: §2'ye ara kayıt kuralı, protokole "30 dakika ritmi" bloğu;
`SYSTEM.en.md` ve `AGENT_PROTOCOL.en.md` aynı anda güncellendi (sürüm eşitliği
testi bunu zaten zorluyor). analyze temiz, sözleşme testleri geçiyor.
