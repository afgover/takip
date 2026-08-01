---
id: T-004
title: "Bağlantı yedeğini al ve parola yöneticisine kaydet"
created_by: agent
created: "2026-08-01T10:00:23Z"
updated: "2026-08-01T10:32:36Z"
priority: high
category: gorev
tags: [guvenlik]
session: S-2026-08-01-bekleyen-isler
result: "Yedek alındı ve parola yöneticisine kaydedildi (kullanıcı bildirimi T-005). waiting/ mekanizmasının ilk uçtan uca koşumu."
---

# Bağlantı yedeğini al ve parola yöneticisine kaydet

## İstek

Uygulamada **Ayarlar → Yedekleme → "Yedek oluştur"**: bir parola belirle,
çıkan metni **parola yöneticine** kaydet.

Neden gerekli: bugün token bir kez silindi (release derlemesine geçerken paket
kaldırıldı, L-014). Kurulum artık kaldırmıyor (`tool/install.sh`), ama fabrika
ayarları, "verileri temizle" ya da yeni telefon hâlâ mümkün. Yedek varken
bütün repolar tek yapıştırmayla geri gelir; yedek yokken her repo için token
yeniden üretilir.

Parolayı unutursan yedek işe yaramaz — parola yöneticisine kaydetmek işin
parçası.

## Notlar

- **2026-08-01:** Beklenen: yedeğin alınıp parola yöneticisine kaydedilmesi.
  Bu, sözleşme 1.4 ile gelen `waiting/` klasörünün **ilk gerçek görevi** —
  mekanizmanın kendisi bu görevle sınanıyor (K-022).
- Yedek aldıktan sonra yeni repo eklersen yedek eskir; o noktada tazelemek
  gerekir. Otomatik hatırlatma henüz yok.
- **2026-08-01:** Kullanıcı yedeği aldı ve uygulamadan "Yaptım" dedi; bildirim
  görevi `inbox/`a düştü (T-005, `waiting-done` etiketli), asıl görev buradan
  `done/`a taşındı. **Sözleşme 1.4'ün ilk uçtan uca koşumu:** agent görev açtı
  → kullanıcı telefonunda gördü → yaptı → uygulamadan bildirdi → agent kapattı.
  Zincirin hiçbir halkası sohbete bağlı kalmadı.
