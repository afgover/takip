---
id: T-017
title: "Aşama 4 kapansın mı? Sıradaki aşamanın hedefi ne?"
created_by: agent
created: "2026-08-15T22:10:00Z"
updated: "2026-08-21T12:00:00Z"
priority: normal
category: karar
tags: [evrim, asama, yon]
session: S-2026-08-21-asama-4-kapanisi
result: "Aşama 4 kapatıldı; Aşama 5 = bakım ve sağlamlaştırma (2026-08-21)"
options: ["Aşama 4'ü kapat, Aşama 5'i birlikte tanımlayalım", "Aşama 4 açık kalsın — kullanım sürüyor", "Şimdilik karar verme, sonra bakarım"]
multi: false
---

# Aşama 4 kapansın mı? Sıradaki aşamanın hedefi ne?

## İstek

`EVOLUTION.md`'deki **Aşama 4 — Günlük Kullanım** aşamasının kendi yazdığı
hedef bugün karşılandı:

> "Sistemi bir hafta gerçek işle kullanmak ve sürtünme noktalarını uygulamanın
> kendi kanalından (inbox) toplamak. (Backlog: B-052 → B-053.)"

B-052 ve B-053 2026-08-15'te kapandı. Yani aşamanın tarif ettiği iş bitti ve
sözleşme gereği (`AGENT_PROTOCOL.md` madde 10) tamamlanan aşama kapatılıp
yenisi açılır.

**Kapatılmadı, çünkü karar senin:** yeni aşamanın hedefini agent kendiliğinden
uyduramaz. Bu, L-049'un aynı hatasını aşama seviyesinde tekrarlamak olurdu —
kapanma koşulu olmayan bir hedef, kalıcı bir bekleme demek.

## Notlar

- 2026-08-15 · Karar için elde olan veri:

  Backlog'da **8 açık madde** kaldı ve **hiçbirinin tetikleyicisi oluşmadı**:
  B-098 (gerçek talep yok), B-101/T-010 (senin ertelemene bağlı), B-110 (ikinci
  kişi yok), B-060…B-064 (Faz 6, beklemede). Yani "sıradaki iş" backlog'dan
  kendiliğinden çıkmıyor — aşamanın hedefi bir **karar** olmak zorunda.

  Bugün ölçülen iki şey yön için veri: B-063'ün ön koşulu (ayrı repo modelinin
  yetersiz kalması) **karşılanmadı**, B-064'ün dört tetikleyicisi de
  **çıkmadı**. İkisi de "mevcut yolda devam" diyor.

- 2026-08-15 · Seçenekler ne anlama geliyor:

  - **Kapat + Aşama 5'i tanımla:** bir sonraki oturumda hedefi birlikte
    yazarız. Aday konular: APK'yı Releases'tan yayımlanabilir hâle getirmek
    (B-101 → B-097'nin kalan ayağı), ya da bakım/sağlamlaştırma aşaması.
  - **Açık kalsın:** kullanım fiilen sürüyor ve yeni sürtünmeler hâlâ inbox'a
    düşüyor. Bu durumda aşamanın hedef cümlesi güncellenmeli — bugünkü hâliyle
    tamamlanmış bir işi tarif ediyor.
  - **Sonra bakarım:** kayıt açık kalır; bir sonraki oturum açılışında yine
    görürsün.

- 2026-08-21 · **Karar (kullanıcı): Aşama 4 kapandı, Aşama 5 = "Bakım ve
  Sağlamlaştırma".** Karar verilmeden önce notlardaki veri tazelendi (6
  günlüktü): aradaki sürede üç madde doğup kapandı ve biri
  ([B-135](../../BACKLOG.md#B-135)) **uygulamanın kendi inbox'ından** geldi.
  Yani aşamanın mekanizması, hedefinin karşılandığı ilan edildikten sonra da
  iş üretiyordu. Kapanma gerekçesi bu yüzden "kullanım bitti" değil: kullanım
  artık aşama değil, **zemin**.

- 2026-08-21 · **Kapanma koşulu birlikte yazıldı** — bu, seçeneğin kendi
  şartıydı: koşulsuz bir hedef, L-049'un hatasını aşama seviyesinde
  tekrarlardı. Üç koşul, hepsi ölçülebilir: (1) doğrudan bağımlılıklarda
  geride kalan her satır ya güncel ya gerekçeli, (2) kapanmış işe işaret eden
  işaretçi kalmamış, (3) 30 günlük tarama süresi içinde koşulmuş.
  Kullanımdan gelen sürtünme bilerek **koşula konmadı**: o aşamanın sürekli
  işi, bitiş çizgisi değil — bitiş çizgisi olsaydı aşama hiç kapanmazdı.

- 2026-08-21 · **İkinci karar (kullanıcı): major geçişler ertelendi.** Minor
  yükseltmeler bugün yapıldı ([B-136](../../BACKLOG.md#B-136)); Riverpod 2→3
  ve secure_storage 9→11 kırıcı geçiş olduğu için
  [B-138](../../BACKLOG.md#B-138)'e ayrıldı ve **üç tetikleyicisi yazıldı**.
  Erteleme kayıtlı ve çıkışı tanımlı olduğu sürece borç sessiz değildir.

- 2026-08-21 · Koşulların 1 ve 2'si aynı gün karşılandı; geriye tarama
  (~3 Eylül) kaldı. Aşamanın kısa olacağı görünüyor ve **uydurma maddelerle
  uzatılmadı** — ölçülmüş borç gerçekten küçüktü.
  → [EVOLUTION.md → Aşama 5](../../EVOLUTION.md)
