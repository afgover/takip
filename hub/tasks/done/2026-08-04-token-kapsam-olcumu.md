---
id: T-006
title: "Fine-grained token'ın repo genişliği ölçülebiliyor mu?"
created_by: agent
created: 2026-08-04T15:45:00Z
updated: "2026-08-06T01:30:00Z"
priority: normal
category: arastirma
tags: [guvenlik, token]
session: S-2026-08-04-guvenlik-taramasi
result: "Ölçüldü 2026-08-06: token 1 repo görüyor. GET /user/repos fine-grained token'la kapsamı yansıtıyor — yani ölçüm mümkün (SEC-012)"
options: ["Sayı hesaptaki toplam repo sayısına eşit", "Sayı token'a verdiğim repo sayısı kadar", "Komutu çalıştıramadım"]
multi: false
---

# Fine-grained token'ın repo genişliği ölçülebiliyor mu?

## İstek

B-092 ile uygulama artık **klasik** (`ghp_`) token'ları yakalayıp uyarıyor.
Yakalayamadığı durum: fine-grained bir token "Only select repositories" yerine
**"All repositories"** ile üretilmişse. O da hesabın tamamını kapsar ama
dışarıdan dar bir token'dan ayırt edilemiyor (SEC-012).

Ayırt edilebilir mi, bilmiyoruz: `GET /user/repos`'un fine-grained bir
token'la yalnız **seçili** repoları mı yoksa hesabın hepsini mi döndürdüğü
belgelenmemiş. Uygulamaya belgelenmemiş bir davranışa dayanan tahmin
koymuyoruz — B-026'da tam olarak bu hata yapılmıştı (L-009).

Ölçümü **sen** yapmalısın, çünkü token agent'a verilmez (SEC-001).

## Notlar

- 2026-08-04 · Beklenen: elindeki `takip` token'ıyla (yalnız seçili repolara
  scope'lu olan) şu komutu çalıştır ve dönen **sayıyı** söyle:

  ```
  curl -s -H "Authorization: Bearer <token>" \
    "https://api.github.com/user/repos?per_page=100" | grep -c '"full_name"'
  ```

  - Sayı **hesabındaki toplam repo sayısına eşitse** → uç nokta kapsamı
    yansıtmıyor, bu yol kapalı; SEC-012 "ölçülemiyor" olarak kapanır.
  - Sayı **token'a verdiğin repo sayısı kadarsa** → kapsam ölçülebiliyor
    demektir; uygulama "bu token N repoyu kapsıyor, ihtiyacı 1" diye
    uyarabilir. B-103 uygulanabilir hâle gelir.

  **Token'ı buraya, sohbete ya da herhangi bir dosyaya yazma** — yalnız çıkan
  sayıyı söylemen yeterli. Komutu kendi terminalinde çalıştır.

- 2026-08-06 · **Ölçüldü: 1.** Hesapta en az iki repo var (`takip`,
  `financer_takip`), token bir tanesini görüyor → uç nokta **kapsamı
  yansıtıyor**, hepsini değil. Belgelenmemiş olan davranış böylece ölçülmüş
  oldu: fine-grained bir token'ın kapsadığı repo sayısı okunabilir.
  Yan bulgu: kullanıcının token'ı gerçekten dar (yalnız `takip`).
  **Doğrulama notu:** tek veri noktası. Ölçülen şey "dar token az repo görür";
  "All repositories token'ı hepsini görür" doğrudan ölçülmedi, filtrelemenin
  varlığından çıkarıldı. Yorum bu yüzden tek yönlü kurulmalı (B-103).
