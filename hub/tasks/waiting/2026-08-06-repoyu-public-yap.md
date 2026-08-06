---
id: T-011
title: "takip reposunu public yap"
created_by: agent
created: "2026-08-06T03:00:00Z"
updated: "2026-08-06T03:00:00Z"
priority: normal
category: gorev
tags: [dagitim, karar]
session: S-2026-08-06-public-hazirlik
author: afgover
result: none
options: ["Public yaptım", "Vazgeçtim, private kalsın", "Önce şunu konuşalım"]
multi: false
---

# takip reposunu public yap

## İstek

B-097 kapanıyor: repo public olacak ve §10 zinciri (diğer hub'ların sözleşmeyi
ana kopyadan kontrol etmesi) böylece **gerçekten** çalışmaya başlayacak.

Ayarı ben değiştiremem — GitHub hesabının repo ayarı ve bende o hesaba erişim
yok.

## Notlar

- 2026-08-06 · **Ön hazırlık bitti:**
  - Sır taraması temiz (çalışma ağacı + git geçmişinin tamamı, `tool/scan.sh`).
  - `git config user.email` noreply adresine çevrildi — bundan sonraki
    commit'lerde gerçek e-posta görünmeyecek. **Geçmişteki 172 commit'te
    `afgover@gmail.com` görünmeye devam edecek** (kullanıcı kararı: geçmiş
    yeniden yazılmadı, SHA'lara yapılan hub atıfları ölmesin diye).
  - Sözleşme 1.17: §10'un kontrolü tek komuta indirildi ve "istek başarısız
    olursa kontrol koşmamıştır" kuralı yazıldı.

- **Yapılacak:** `https://github.com/afgover/takip/settings` → en altta
  **Danger Zone** → *Change repository visibility* → **Make public**.

- **Geri dönüşü yok sayılmalı.** Private'a çevirmek mümkün ama public geçen
  süre içinde fork'lanan, klonlanan ve arama motorlarınca indekslenen içerik
  geri gelmez.

- **Public olduğunda ne görünür:**
  42 oturum kaydı (senin mesajların dâhil), 43 artifact, 282 commit, bütün
  kararlar ve `SECURITY.md`'deki üç **açık** güvenlik kaydı (SEC-007, SEC-010,
  SEC-012). Açıkları yayımlamak bilinçli: bu proje kendi açıklarını dürüstçe
  listelediği için değerli (K-032), ve hiçbiri uzaktan sömürülebilir bir şey
  değil.

- **Public olduktan sonra değişen kural:** sözleşmede kırıcı değişiklik yapma
  özgürlüğü biter (B-097). Bugüne kadar bir günde 1.11 → 1.17 yapıldı; bunu
  yapabilmenin sebebi kimsenin bağlı olmamasıydı.

- **Sen yaptıktan sonra ben doğrularım:** `curl` ile ana kopyanın 200 döndüğünü
  ölçüp B-097'yi kapatacağım. Ölçmeden "çalışıyor" yazmayacağım.
