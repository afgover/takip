---
id: S-2026-09-12-sozlesme-analizi
date: 2026-09-12
status: open
reconstructed: false
author: afgover
topics: [olcum, sozlesme, analiz, coklu-hub]
artifacts:
  - artifacts/S-2026-09-12-sozlesme-analizi/sozlesme-yuku-ve-getirisi.md
tasks_touched: []
---

# Oturum: sözleşmenin yükü ve getirisi, 365 oturumun kaydından

## Özet

*(oturum açık — kapanışta yazılacak)*

## Kayıt

### [09:50] Kullanıcı

> sözleşmenin session'lara olan yükünü/getirisini ölçen bir simülasyon
> çalıştırmıştık, geçmiş session'ları da inceleyerek (tüm repolar) bir analiz
> çalıştırmanı istiyorum

### [10:10] Agent

Önceki çalışma ([A-2026-08-30-001](../../artifacts/S-2026-08-30-uc-gorev/token-maliyeti.md))
kontrollü bir simülasyondu; bu analiz gerçek kayıtlara bakıyor. Deterministik
taban ana ajan tarafından çıkarıldı: 10 hub, 366 oturum, 2.289 commit, 196
artifact, 499 ders.

### [10:30] Agent

Ölçüm workflow'u koştu: 10 hub ajanı + 4 kesit ajanı (sürüm yayılımı, getiri
envanteri, yük eğrisi, denetim bulguları). 740 araç çağrısı. 70 iddia çıktı.

### [11:20] Agent

Yedi manşet iddia ikişer bağımsız çürütücüye verildi (14 ajan). İki iddia
düştü, dördü daraltıldı, biri ayakta kaldı. En önemli düzeltme ana ajanın
kendi ölçümüne geldi: "artifact'ların %86'sı atıf almış" sayısı sözleşmenin
zorunlu kıldığı doğum-indeksi satırını sayıyormuş; gerçek oran %33-50.

### [11:40] Agent

Rapor yazıldı ve 1.29 biçim kurallarından geçti:
[A-2026-09-12-001](../../artifacts/S-2026-09-12-sozlesme-analizi/sozlesme-yuku-ve-getirisi.md).

## Notlar

- Açılış: dünkü oturum (S-2026-09-11-artifact-bicimi) sözleşme §2 gereği bu
  oturum açılmadan kapatıldı; özeti kendi kaydından türetildi.
- Ölçüm maliyeti kayda geçsin: 28 ajan, ~4,1M token, 1.258 araç çağrısı.
  Bu çalışmanın kendisi, ölçtüğü yükün mertebesini gösteriyor.
- Ölçülemeyenler raporun başında duruyor; en önemlisi tur sayısı — hub'lar
  araç çağrısı tutmadığı için 1.28 tipi tedbirlerin etkisi bugün ölçülemiyor.
