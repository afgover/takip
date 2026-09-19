---
id: S-2026-09-19-id-karsisi-karari
date: 2026-09-19
status: closed
reconstructed: false
author: afgover
topics: [sozlesme, id, cakisma, coklu-hub, karar]
artifacts: []
tasks_touched: [T-024]
---

# Oturum: T-024 kararı — ID çakışması sözleşme eki

## Özet

Vault hub'ından gelen T-024 kararı verildi: ID atarken "en büyük" komşu
giriş değil dosyanın tamamı olarak tanımlandı (`AGENT_PROTOCOL.md` v1.31),
`SYSTEM.md` sözleşme sürümü 1.30→1.31, `L-058` yazıldı. Karar Seçenek 1
(ana kopyaya ekle + sürüm artır + senkron gündeme al) — Seçenek 2 ve 3
gerekçeli olarak elendi. `T-024` `done/`'a taşındı, sonuç frontmatter'da.
vault_takip senkronu bu oturumun kapsamı dışında; Vault'a ayrı bir
cross-session mesajla bildirilecek.

## Kayıt

### [22:50] Agent

Açılış: `tool/acilis.sh` koştu, sözleşme 1.30 ana kopyayla aynı, inbox'ta
T-024 vardı. Önceki oturum (S-2026-09-12-sozlesme-analizi) 7 gündür `open`
kalmıştı — madde 1 gereği bu oturum açılmadan önce kapatıldı, özeti kendi
kaydından türetildi.

### [22:52] Diğer oturum (Vault)

Vault hub'ından (`local_e2793cb1-a503-4342-8faa-fbf89906fc96`) cross-session
mesajla T-024'ün özeti ve kararı etkileyen iki ek bulgu geldi: (1) vault_takip
sözleşmesi 1.28'de kalmış (1.29/1.30 hiç inmemiş), (2) öneri önce
`vault_takip/hub/AGENT_PROTOCOL.md`'ye yerel olarak yazılmış (`89a3360`,
L-020/L-022'deki sessiz ayrışma örneği), kalıcı olması ana kopya kararına
bağlı.

### [22:55] Kullanıcı

> onerileri incele ve yorumunu soyle ona gore devam edelim

### [22:58] Agent

Üç seçenek `SYSTEM.md` §5-6 ölçütüyle ("sözleşme değişiklikleri sürüm
artırır") değerlendirildi:
- Seçenek 3 (kuralı reddet) elendi — B-111 (2026-08-06) ve şimdiki B-123/124
  aynı kuralın iki kez ihlalini gösteriyor, mevcut metin kanıtlı yetersiz.
- Seçenek 2 (ekle, sürüm artırma) elendi — önerilen metin yalnız açıklama
  değil, iki yeni zorunlu komut ekliyor (en büyüğü bul + çakışma denetle);
  v1.29/v1.30 emsaliyle aynı ölçekte bir prosedür değişikliği.
- Seçenek 1 (v1.31, SYSTEM.md 1.30→1.31, vault senkronu) önerildi — sürüm
  artışı ayrıca vault'un tam da bu yüzden (§10 diff koşulmadı) 2 sürüm geri
  kalmasına karşı erken uyarı sinyali taşıyor.

### [23:00] Kullanıcı

> devam et, onaylıyorum

### [23:02] Agent

Uygulandı: `AGENT_PROTOCOL.md` v1.31 eki, `SYSTEM.md` sürüm 1.30→1.31,
`EVOLUTION.md` notu, `knowledge/lessons.md` L-058, T-024 `done/`'a taşındı.
Detaylar bu kaydın devamında.

## Notlar

- Karar kaynağı: [T-024](../../tasks/done/2026-09-19-id-numarasi-cakismasi-sozlesme.md).
- Vault senkronu bu oturumun kapanışından sonra ayrı bir cross-session
  mesajla bildirilecek; senkronun kendisi vault_takip hub'ının işi.
