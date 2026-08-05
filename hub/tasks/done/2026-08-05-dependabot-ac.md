---
id: T-009
title: "Repoda Dependabot uyarılarını aç"
created_by: agent
created: "2026-08-05T21:00:00Z"
updated: "2026-08-06T01:00:00Z"
priority: normal
category: gorev
tags: [guvenlik, dependabot]
session: S-2026-08-05-tarama-tekrari
result: "Dependency graph, Dependabot alerts ve security updates açıldı (kullanıcı bildirdi 2026-08-06) — B-102'nin sürekli izleme ayağı devrede"
options: ["Açtım", "Ayarı bulamadım", "Açmak istemiyorum"]
multi: false
---

# Repoda Dependabot uyarılarını aç

## İstek

B-102'nin karar verdiği katmanlı taramanın **sürekli** ayağı bu. Dependabot,
`pub` ekosistemini destekliyor ve `pubspec.lock`'u aynı danışmanlık
veritabanına karşı sürekli izliyor — bizim aylık taramamızın aksine, yeni bir
danışmanlık yayımlandığı **gün** haber veriyor. Bedava ve bakım istemiyor, ama
repo ayarlarından açılması gerekiyor; bunu benim yapmam mümkün değil.

Kapsadığı tek şey **bilinen zafiyetler**. Sır taraması, Android yapılandırması
ve sürüm güncelliği `tool/scan.sh`'ta kalıyor (30 günde bir).

## Notlar

- 2026-08-05 · Beklenen: GitHub'da `afgover/takip` → **Settings → Advanced
  Security** (eski adıyla Code security and analysis) altında sırasıyla:

  1. **Dependency graph** → Enable *(private repoda kapalı gelir; Dependabot
     bunun üstünde çalışıyor, önce bu açılmalı)*
  2. **Dependabot alerts** → Enable
  3. *(isteğe bağlı)* **Dependabot security updates** → Enable — açık bulunan
     paket için otomatik PR açar. Kapalı bırakırsan yalnız uyarı gelir,
     yükseltmeyi biz yaparız.

  Üçüncüsünü açman şart değil; ilk ikisi bu görevin asıl istediği.

- Ayar adları GitHub arayüzünde zaman zaman değişiyor. "Dependency graph"
  ya da "Dependabot" diye aratman yeterli; bulamazsan "Ayarı bulamadım" de,
  yerini birlikte bakarız.

- **Dependabot version updates açmıyoruz** (bu ayrı bir şey, `.github/
  dependabot.yml` gerektiriyor): her sürüm farkı için PR açar ve tek kişilik
  bir projede gürültüden başka bir şey üretmez. Sürüm güncelliği zaten aylık
  taramada raporlanıyor.

- 2026-08-06 · **Yapıldı.** Kullanıcı üç ayarı da açtı ("hepsi enabled"), yani
  security updates de dahil: açık bulunan bir paket için Dependabot artık
  kendiliğinden PR açacak.
  **Doğrulama notu:** bu makinede `gh` kurulu değil ve agent'ta token yok, yani
  ayarın açık olduğu bağımsız olarak ölçülmedi — kayıt kullanıcının
  bildirimine dayanıyor. İlk gerçek sinyal, bir danışmanlık çıktığında gelecek
  uyarı olacak.
