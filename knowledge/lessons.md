# Çıkarılan Dersler (lessons)

Yapılan hatalar ve öğrenilenler; tekrarlanmaması için tek tek kayıt altında.
Biçim: `SYSTEM.md` §5.

---

## L-001 — Altyapı işletmek ürünün önüne geçebilir
- **Tarih:** 2026-07-30
- **Kaynak:** İlk taskr deneyimi (Expo + özel backend)
- **Açıklama:** Auth, offline senkron, deploy ve güvenlik yamaları; görev
  yönetimi ürününün kendisinden daha fazla emek tüketti. Yönetilen bir omurga
  (GitHub) üzerine kurulmak bu yükü sıfıra yaklaştırır. Yeni bileşen eklerken
  ölçüt: "Bunu biz mi işletmek zorundayız?"

## L-002 — Paylaşılan tek dosya, eşzamanlı yazmada çakışır
- **Tarih:** 2026-07-30
- **Kaynak:** Aşama 0 tasarımı (K-004)
- **Açıklama:** Tüm görevleri tek `todos.json`'da tutmak iki yazarın sürekli
  çakışmasına yol açar. Kayıt-başına-dosya modelinde ekleme hiçbir zaman
  çakışmaz; güncellemede de çakışma tek göreve izole kalır.
